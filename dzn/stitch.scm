;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn stitch)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn ast)
  #:use-module (dzn ast ast)
  #:use-module (dzn code language makreel)
  #:use-module (dzn command-line) ;dzn:debugity
  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:use-module (dzn verify pipeline)

  #:export (model->lts))

(define* (compose-par instance blob lts #:key alphabet verbose?)
  (when (> (dzn:debugity) 1)
    (display "blob:\n" (current-error-port))
    (display-lts-rtc blob #:port (current-error-port))
    (display #\newline (current-error-port))
    (display "lts:\n" (current-error-port))
    (display-lts-rtc lts #:port (current-error-port))
    (display #\newline (current-error-port)))
  (when verbose?
    (format (current-error-port)
            "Stitching ~a as ~a to the blob...\n"
            (makreel:unticked-dotted-name (.type instance))
            (makreel:unticked-dotted-name instance)))
  (let* ((result (compose-parallel
                  (mark-common blob #:alphabet alphabet)
                  (mark-common lts #:alphabet alphabet))))
    (when verbose?
      (format (current-error-port) "...done\n"))
    (when (> (dzn:debugity) 1)
      (display "par:\n" (current-error-port))
      (display-lts-rtc result #:port (current-error-port))
      (display #\newline (current-error-port)))
    (when (> (dzn:debugity) 0)
      (write-lts-tmp (mark-common result #:alphabet alphabet)))
    result))

(define-method (instance-name (instance <instance>) port-name)
  (string-append (makreel:unticked-dotted-name instance)
                 "."
                 (makreel:unticked-name port-name)))

(define-method (instance-name (end-point <end-point>))
  (instance-name (.instance end-point) (.port.name end-point)))

(define (sutify label instance)
  (let* ((system (tree:ancestor instance <system>))
         (name (makreel:unticked-dotted-name system))
         (prefix (1+ (string-length name)))
         (label (substring label prefix)))
   (string-append "sut." label)))

(define* (add-instance-name lts #:key instance)
  (let ((name (makreel:unticked-dotted-name instance)))
    (define (transform-label label)
      (cond
       ((string-prefix? "sut." label)
        (let* ((label (substring label (string-length "sut.")))
               (label (string-append name "." label)))
          (make-shared-string (sutify label instance))))
       ((string-index label #\.)
        (make-shared-string (string-append name "." label)))
       (else
        label)))
    (transform-labels transform-label lts)))

(define* (port-events port #:key (predicate identity))
  (let* ((interface (.type port))
         (port-name (makreel:unticked-name port))
         (events (ast:event* interface))
         (events (filter predicate events))
         (event-names (map .name events)))
    (map (cute string-append port-name "." <>) event-names)))

(define (port-modeling-triggers port)
  (let ((port-name (makreel:unticked-name port)))
    (map (cute string-append port-name "." <>) (list "optional" "inevitable"))))

(define* (stitch root ports instances bindings #:key verbose?)
  (define (requires-bindings instance)
    (let ((bindings (filter (compose (cute ast:equal? <> instance)
                                     .instance .left)
                            bindings)))
      (filter (compose (disjoin not
                                (compose  not (is? <foreign>) .type))
                       .instance .right)
              bindings)))
  (define (rename-ports lts)
    (define (transform-binding binding)
      (cond
       ((not (.instance (.right binding)))
        (rename-label
         (instance-name (.left binding))
         (makreel:unticked-name (.port.name (.right binding)))))
       ((not (.instance (.left binding)))
        (rename-label
         (instance-name (.right binding))
         (makreel:unticked-name (.port.name (.left binding)))))
       ((is-a? (.type (.instance (.right binding))) <foreign>)
        (rename-label
         (instance-name (.left binding))
         (sutify (instance-name (.right binding))
                 (.instance (.right binding)))))
       (else identity)))
    (define transform-label
      (let ((transformations (map transform-binding bindings)))
        (apply compose transformations)))
    (transform-labels transform-label lts))
  (define (hide-binding binding lts)
    (hide lts #:hide-prefix (instance-name (.right binding))))
  (define (hide-bindings bindings lts)
    (fold hide-binding lts bindings))
  (define (rename-binding binding lts)
    (let ((from (instance-name (.left binding)))
          (to (instance-name (.right binding))))
      (rename lts #:from from #:to to)))
  (define (rename-bindings bindings lts)
    (fold rename-binding lts bindings))
  (define* (instance->lts instance #:key ports)
    (let* ((events (append-map (cut port-events <> #:predicate ast:out?)
                               ports))
           (lts (model->lts root (.type instance) verbose?))
           (lts (annotate-collateral-blocked-out
                 lts #:provides-out-events events)))
      (add-instance-name lts #:instance instance)))
  (define* (stitch-instance instance blob #:key todo)
    (let* ((instance-node instance)
           (instance-todo (and=> (assoc instance todo ast:node-eq?)
                                 cdr))
           (todo (acons instance (1- instance-todo)
                        (alist-delete instance todo ast:node-eq?))))
      (if (> instance-todo 1) (values blob todo)
          (let* ((requires (requires-bindings instance))
                 (requires (filter (compose .instance .right) requires))
                 (internal (filter (conjoin (compose .instance .left)
                                            (compose .instance .right))
                                   bindings))
                 (provides (filter (compose (cute ast:equal? <> instance)
                                            .instance .right)
                                   internal))
                 (alphabet (map (compose instance-name .right) requires))
                 (provide-ports (map (compose .port .right) provides))
                 (lts (instance->lts instance #:ports provide-ports))
                 (requires-ports (map (compose instance-name .left) requires))
                 (lts (remove-modeling lts #:ports requires-ports))
                 (lts (rename-bindings requires lts))
                 (blob (compose-par instance blob lts #:alphabet alphabet
                                    #:verbose? verbose?))
                 (blob (hide-bindings requires blob))
                 (provides (map (compose .instance .left) provides)))
            (stitch blob provides #:todo todo)))))
  (define* (stitch blob instances #:key todo)
    (let loop ((blob blob) (instances instances) (todo todo))
      (match instances
        (() (values blob todo))
        ((instance instances ...)
         (let ((blob todo (stitch-instance instance blob #:todo todo)))
           (loop blob instances todo))))))

  (let* ((bottom-bindings (filter (compose not .instance .right) bindings))
         (bottom-instances (filter (compose null? requires-bindings)
                                   instances))
         (bottom-instances (filter (compose not (is? <foreign>) .type)
                                   bottom-instances))
         (bottom-instances (append
                            (map (compose .instance .left) bottom-bindings)
                            bottom-instances))
         (todo (map cons instances
                    (map (compose length requires-bindings) instances)))
         (blob (stitch #() bottom-instances #:todo todo)))
    (rename-ports blob)))


;;;
;;; Entry point.
;;;
(define-method (model->lts root (model <interface>) verbose?)
  (let ((lts (verify-pipeline "aut-weak-trace" root model)))
    (when (string-null? (string-trim-right lts))
      (error "failed to create LTS for interface ~a\n"
             (makreel:unticked-dotted-name model)))
    (aut-text->lts lts)))

(define-method (model->lts root (model <component>) verbose?)
  (define (remove-qout label)
    (if (string-contains label ".qout.") %tau label))
  (when verbose?
    (format (current-error-port) "Generating LTS for component type ~a...\n"
            (makreel:unticked-dotted-name model)))
  (let ((lts (verify-pipeline "aut-weak-trace" root model
                              #:init "component_blocked")))
    (when (string-null? (string-trim-right lts))
      (error "failed to create LTS for component ~a\n"
             (makreel:unticked-dotted-name model)))
    (when verbose? (format (current-error-port) "...done\n"))
    (let* ((lts (transform-labels remove-qout (aut-text->lts lts)))
           (provides (ast:provides-port* model))
           (triggers (append-map (cut port-events <> #:predicate ast:in?)
                                 provides))
           (requires (ast:requires-port* model))
           (modeling (append-map port-modeling-triggers requires))
           (events (append triggers modeling))
           (lts (annotate-node-rtc lts #:incoming-events events)))
      (when #t ;; debug?
        (let* ((model-name (makreel:unticked-dotted-name model))
               (file-name (string-append model-name ".aut")))
          (with-output-to-file file-name
            (cut display-lts lts))))
      lts)))

(define-method (model->lts root (model <foreign>) verbose?) ;; HACK; TODO FIXME
  (let ((lts (verify-pipeline "aut-weak-trace" root (.type (ast:provides-port model)))))
    (when (string-null? (string-trim-right lts))
      (error "failed to create LTS for foreign ~a\n"
             (makreel:unticked-dotted-name model)))
    (aut-text->lts lts)))

(define-method (model->lts root (system <system>) verbose?)
  (let* ((instances (ast:instance* system))
         (ports (ast:port* system))
         (bindings (map ast:normalize (ast:binding* system)))
         (stitch? (and (pair? ports)
                       (pair? instances))))
    (if (not stitch?) #()
        (stitch root ports instances bindings #:verbose? verbose?))))
