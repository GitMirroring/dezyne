;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021, 2022, 2023, 2024 Paul Hoogendijk <paul@dezyne.org>
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
  #:use-module (dzn pipe)
  #:use-module (dzn verify pipeline)

  #:export (model->lts))


(define (untick o)
  (if (string-suffix? "'" o) (string-drop-right o 1) o))

(define (unticked-dotted-name o)
  (string-join (map untick (ast:full-name o)) "."))

(define (remove-qout label)
  (if (string-contains label ".qout.") %tau label))

(define (fullname instance portname)
  (string-append (unticked-dotted-name instance) "." (untick portname)))

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


(define (model-name->model model-name models)
  (find (lambda (m) (equal? (makreel:unticked-dotted-name m) model-name)) models))

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

(define* (port-return-values port)
  (define (->string o)
    (cond
      ((is-a? o <literal>) (->string (.value o)))
      ((is-a? o <enum-literal>) (string-append (untick (tree:name (.type.name o))) ":" (.field o)))
      ((number? o) (number->string o))
      (else o)))
  (let ((port-name (makreel:unticked-name port)))
    (map (cute string-append port-name "." <>) (map ->string (ast:return-values port)))))

(define (log-debug msg thunk)
  (let ((debug? (dzn:command-line:get 'debug #f)))
    (when debug? (format (current-error-port) "~a...\n" msg))
    (let ((res (thunk)))
      (when debug? (format (current-error-port) "...done\n"))
      res)))

(define* (stitch root models model-name #:key verbose?)
  (let* ((model (or (and model-name (model-name->model model-name models))
                    (last (filter (cute is-a? <> <system>) models))
                    (last (filter (cute is-a? <> <component>) models)))))
    (model->lts root model verbose?)))

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
  (when (> (dzn:debugity) 0)
    (write-lts-tmp blob)
    (write-lts-tmp lts))
  (let* (;;(lts-text0 (warn 'lts0 (with-output-to-string (cut display-lts blob))))
         ;;(lts-text1 (warn 'lts1 (with-output-to-string (cut display-lts lts))))
         (result (if (dzn:command-line:get 'external)
                     (compose-parallel-external blob lts alphabet)
                     (compose-parallel
                       (mark-common blob #:alphabet alphabet)
                       (mark-common lts #:alphabet alphabet)))))
    (when (> (dzn:debugity) 0)
      (write-lts-tmp result))
    (when verbose?
      (format (current-error-port) "...done\n"))
    (when (> (dzn:debugity) 1)
      (display "par:\n" (current-error-port))
      (display-lts-rtc result #:port (current-error-port))
      (display #\newline (current-error-port)))
   ;; (when (> (dzn:debugity) 0)
   ;;   (write-lts-tmp (mark-common result #:alphabet alphabet)))
    result))

(define (compose-parallel-external lts0 lts1 common-events)
  (if (zero? (vector-length lts0))
    lts1
    (let* ((incoming-events0 (incoming-events-lts lts0))
           (incoming-events1 (incoming-events-lts lts1))
           (incoming-events2 (lset-difference equal? (append incoming-events0 incoming-events1) common-events))
           (option-incoming-events0 (string-append "--in-actions-first=" (string-join incoming-events0 ",")))
           (option-incoming-events1 (string-append "--in-actions-second=" (string-join incoming-events1 ",")))
           (option-common-events (string-append "--common-actions=" (string-join common-events ",")))
           (lts-text0 (with-output-to-string (cut display-lts lts0)))
           (lts-text1 (with-output-to-string (cut display-lts lts1)))
           (result status (pipeline->string
                            (warn 'command (list `("/home/paul/mCRL2-build/stage/bin/ltsparallel" "-d" "--in1=aut" "--in2=aut"
                             ,option-incoming-events0 ,option-incoming-events1 ,option-common-events
                             "-" "-" "-")))
                            #:input (string-append lts-text0 "\n\x04\n" lts-text1)))
           (lts (annotate-node-rtc (aut-text->lts result) #:incoming-events incoming-events2)))
        lts)))

;;;
;;; Entry point.
;;;
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
           (requires-blocking (filter ast:blocking? requires))

           (modeling (append-map port-modeling-triggers requires))
           (return-values (append-map port-return-values requires-blocking))
           (requires-out (append-map (cut port-events <> #:predicate ast:in?)
                                     requires-blocking))
           (events (append triggers modeling return-values requires-out))
           (lts (annotate-node-rtc lts #:incoming-events events)))
      (when #t ;; debug?
        (let* ((model-name (makreel:unticked-dotted-name model))
               (file-name (string-append model-name ".aut")))
          (with-output-to-file file-name
            (cut display-lts lts))))
      lts)))

(define-method (model->lts root (model <interface>) verbose?)
  (let ((lts (verify-pipeline "aut-weak-trace" root model)))
    (when (string-null? (string-trim-right lts))
      (error "failed to create LTS for interface ~a\n"
             (makreel:unticked-dotted-name model)))
    (aut-text->lts lts)))

(define-method (model->lts root (model <foreign>) verbose?) ;; HACK; TODO FIXME
  (let ((lts (verify-pipeline "aut-weak-trace" root (.type (ast:provides-port model)))))
    (when (string-null? (string-trim-right lts))
      (error "failed to create LTS for foreign ~a\n"
             (makreel:unticked-dotted-name model)))
    (aut-text->lts lts)))

(define-method (model->lts root (system <system>) verbose?)
  (let* ((instances (ast:instance* system))
         (bindings (map ast:normalize (ast:binding* system)))
         (instance-provides-binding-count (make-hash-table)))
    (define (get-top-bindings)
      (filter (lambda (b) (not (.instance (.left b)))) bindings))
    (define (get-provides-bindings instance)
      (filter (lambda (b) (ast:equal? (.instance (.right b)) instance))
              bindings))
    (define (get-requires-bindings instance)
      (filter (lambda (b) (and (ast:equal? (.instance (.left b)) instance)
                               (.instance (.right b))
                               (not (is-a? (.type (.instance (.right b))) <foreign>))))
              bindings))
    (define (rename-ports lts)
      (define (transform-binding binding)
        (cond
        ((not (.instance (.left binding)))
          (rename-label
          (instance-name (.right binding))
          (makreel:unticked-name (.port.name (.left binding)))))
        ((not (.instance (.right binding)))
          (rename-label
          (instance-name (.left binding))
          (makreel:unticked-name (.port.name (.right binding)))))
        ((is-a? (.type (.instance (.right binding))) <foreign>)
          (rename-label
          (instance-name (.left binding))
          (sutify (instance-name (.right binding))
                  (.instance (.right binding)))))
        (else identity)))
      (define transform-label
        (if (null? bindings) identity
            (let ((transformations (map transform-binding bindings)))
              (apply compose transformations))))
      (transform-labels transform-label lts))
    (define (hide-binding binding lts)
      (hide lts #:hide-prefix (instance-name (.left binding))))
    (define (hide-bindings bindings lts)
      (log-debug 'hide-bindings
        (cute fold hide-binding lts bindings)))
    (define (rename-binding binding lts)
      (let ((from (instance-name (.right binding)))
            (to (instance-name (.left binding))))
        (rename lts #:from from #:to to)))
    (define (rename-bindings bindings lts)
      (log-debug 'rename-bindings
        (cute fold rename-binding lts bindings)))
    (define* (instance->lts instance #:key ports)
      (let* ((lts (model->lts root (.type instance) verbose?)))
        (add-instance-name lts #:instance instance)))

    (define (stitch lts instance-bindings)
      (fold
        (lambda (binding lts)
          (let* ((subinstance (.instance (.right binding)))
                 (provides-binding-count (1- (hash-ref instance-provides-binding-count subinstance)))
                 (provides-bindings (get-provides-bindings subinstance))
                 (provides-internal-bindings (filter (compose .instance .left) provides-bindings)))
            (hash-set! instance-provides-binding-count subinstance provides-binding-count)
            (if (not (equal? provides-binding-count 0))
              lts
              (stitch
                (hide-bindings
                  provides-internal-bindings
                  (compose-par
                    subinstance
                    (log-debug 'Remove-modeling
                      (cute remove-modeling
                        lts
                        #:ports
                          (map
                            (lambda (binding)
                              (fullname (.instance (.left binding)) (.port.name (.left binding))))
                            provides-internal-bindings)))
                    (rename-bindings
                      provides-internal-bindings
                      (instance->lts subinstance))
                    #:alphabet
                      (map
                        (lambda (binding)
                          (string-append (fullname (.instance (.left binding)) (.port.name (.left binding))) "."))
                        provides-internal-bindings)
                    #:verbose? verbose?))
                (get-requires-bindings subinstance)))))
       lts
       instance-bindings))

    (for-each (lambda (i) (hash-set! instance-provides-binding-count i (length (get-provides-bindings i)))) instances)
    (log-debug 'Rename-ports
      (cute rename-ports
        (if (null? instances)
            (vector)
            (let* ((top-bindings (get-top-bindings)))
              (stitch (vector) top-bindings)))))))
