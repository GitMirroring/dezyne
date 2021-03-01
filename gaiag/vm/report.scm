;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag vm report)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag command-line)
  #:use-module (gaiag ast)
  #:use-module (gaiag wfc)
  #:use-module (gaiag vm ast)
  #:use-module (gaiag vm goops)
  #:use-module (gaiag vm runtime)
  #:use-module (gaiag vm util)
  #:export (display-trace-n
            display-trails
            step->location
            trace->trail
            report))

;;;
;;; Trail (a.k.a. events, named event trace)
;;;

(define (display-trails traces)
  (when (pair? traces)
    (display-trail-n (car traces) 0)))

(define (display-trail-n t i)
  (when (> i 0)
    (format (current-error-port) "\ntrace [~a]:\n" i))
  (display-trail t))

(define-method (display-trail (o <list>))
  (display (string-join (map cdr (trace->trail o)) "\n" 'suffix)))

(define-method (trace-name (o <runtime:instance>))
  (if (is-a? (%sut) <runtime:port>) #f
      (name* o)))

(define-method (trace->trail (o <list>))
  (filter-map trace->trail (reverse o)))

(define-method (trace->trail (o <error>))
  (cons #f (format #f "<~a>" (or (.message o) "error"))))

(define-method (trace->trail (o <blocked-error>))
  (cons #f "<deadlock>"))

(define-method (trace->trail (o <end-of-trail>))
  #f)

(define-method (trace->trail (o <match-error>))
  (cons #f "<match>"))

(define-method (trace->trail (o <program-counter>))
  (if (.status o) (trace->trail (.status o))
      (trace->trail o (.statement o))))

(define-method (trace->trail (pc <program-counter>) (o <statement>))
  (trace->trail (.instance pc) o))

(define-method (trace->trail (pc <program-counter>) (o <trigger-return>))
  (let* ((value (->sexp (.reply pc)))
         (value (and (not (equal? value "void")) value)))
    (and (not (is-a? (.event (.trigger pc)) <modeling-event>))
         (trace->trail (.instance pc) (clone o #:event.name (or value (format #f "~a" (.event.name o))))))))

(define-method (trace->trail (pc <program-counter>) (o <initial-compound>))
  (trace->trail (.instance pc) o (.trigger pc)))

(define-method (trace->trail (o <runtime:port>) (action <action>))
  (if (ast:out? action)
      (and (or (is-a? (%sut) <runtime:port>)
               (and (ast:requires? (.ast o))
                    (not (ast:external? (.ast o)))))
           (cons action (format #f "~a~a" (or (and=> (trace-name o) (cut format #f "~a." <>)) "") (trigger->string action))))
      (cons action (format #f "~a" (trigger->string action)))))

(define-method (trace->trail (o <runtime:component>) (action <action>))
  (and (not (ast:async? action))
       (let* ((port (.port action))
              (r:port (runtime:port o port))
              (r:other-port (runtime:other-port r:port)))
         (if (ast:injected? port)       ;injected
             (cons action (format #f "~a.~a" (.name (.ast r:other-port)) (.event.name action)))
             (and (runtime:boundary-port? r:other-port)
                  (let ((trigger (action->trigger r:other-port action)))
                    (cons action (format #f "~a.~a" (name r:other-port) (trigger->string trigger)))))))))

(define-method (trace->trail (o <runtime:component>) (q-out <q-out>))
  (let* ((trigger (.trigger q-out))
         (port (.port trigger)))
    (and (or (ast:provides? port)
             (ast:external? port))
         (cons q-out (trigger->string trigger)))))

(define-method (trace->trail (o <runtime:port>) (compound <initial-compound>) (trigger <trigger>))
  (and (or (eq? o (%sut)))
       (not (ast:modeling? trigger))
       (cons trigger (format #f "~a" (.event.name trigger)))))

(define-method (trace->trail (o <runtime:port>) (return <trigger-return>))
  (and (or (is-a? (%sut) <runtime:port>)
           (and (runtime:boundary-port? o)))
       (let ((value (or (.expression return) (.event.name return))))
         (cons return (if (or (eq? o (%sut)) (not (trace-name o))) (format #f "~a" value)
                          (format #f "~a.~a" (trace-name o) value))))))

(define-method (trace->trail (o <runtime:component>) (compound <initial-compound>) (trigger <q-trigger>))
  #f)

(define-method (trace->trail (o <runtime:component>) (compound <initial-compound>) (trigger <trigger>))
  (let ((port (.port trigger)))
    (and port
         (let ((r:other-port (runtime:other-port (runtime:port o port))))
           (and (runtime:boundary-port? r:other-port)
                (cons trigger (format #f "~a.~a" (trace-name r:other-port) (.event.name trigger))))))))

(define-method (trace->trail (o <runtime:component>) (return <trigger-return>))
  (let ((port (.port return)))
    (and port
         (not (ast:async? port))
         (let* ((r:port (runtime:port o port))
                (r:other-port (and r:port (runtime:other-port r:port))))
           (if (eq? r:port r:other-port) ;injected
               (cons return (format #f "~a.~a" (.name port) (.event.name return)))
               (and r:other-port
                    (runtime:boundary-port? r:other-port)
                    (ast:provides? (.ast r:other-port))
                    (cons return (let ((value (or (.expression return) (.event.name return))))
                                   (format #f "~a.~a" (trace-name r:other-port) value)))))))))

(define-method (trace->trail x y)
  #f)


;;;
;;; Trace (a.k.a. micro trace)
;;;

(define* (trace-step? pc)
  (let ((instance (.instance pc))
        (statement (.statement pc)))
    (match statement
      (#f (or (.trigger pc) (.reply pc)))
      (($ <initial-compound>)
       (let ((trigger (.trigger pc)))
         (not (member (.event.name trigger) '("optional" "inevitable")))))
      ((and ($ <trigger>) (= .event.name 'error)) #t)
      ((and ($ <trigger>) (= .event.name (? (cut member <> '("optional" "inevitable"))))) #f)
      (($ <trigger>) #t)
      (($ <trigger-return>)
       (and (not (is-a? (.event (.trigger pc)) <modeling-event>))
            (let ((port (.port statement)))
              (or (runtime:boundary-port? instance)
                  (is-a? (parent statement <model>) <interface>)
                  (and port
                       (not (ast:async? port))
                       (or (ast:provides? port)
                           (let ((r:other-port (runtime:other-port (runtime:port instance port))))
                             (and (runtime:boundary-port? r:other-port)
                                  (ast:provides? (.ast r:other-port))))))))))
      (($ <trigger-return-trace>) #t)
      (($ <action>) #t)
      (($ <q-in>) #t)
      (($ <q-out>) #t)
      (($ <q-trigger>) #t)
      (_ #f))))

(define* (display-trace o #:key locations? verbose?)
  (let ((interface? (is-a? ((compose .type .ast %sut)) <interface>)))
    (let loop ((steps (reverse o)) (first? #f) (port #f) (reply #f))
      (when (pair? steps)
        (let* ((pc (car steps))
               (instance (.instance pc))
               (trigger (.trigger pc))
               (statement (.statement pc))
               (port (or (and statement port) (and trigger (.port.name trigger))))
               (reply (or (.reply pc)
                          (and (is-a? statement <trigger-return>) "return")
                          (and (not (is-a? statement <initial-compound>)) reply))))
          (let* ((trace-step? (trace-step? pc))
                 (first? (if trace-step? (not first?) first?))
                 (location (if locations? (or (step->location statement)
                                              (step->location ((compose .type .ast %sut)))
                                              "<unknown-file>:")
                               "")))

            (define (step->string pc)
              (let* ((instance (or (.instance pc) instance))
                     (statement (.statement pc))
                     (trigger (.trigger pc))
                     (instance (cond (instance (runtime:instance->string instance))
                                     (else "<external>")))
                     (port (and (or (not (string-prefix? "<external>" instance))
                                    (equal? "<external>" instance))
                                port))
                     (event (statement->string (cond ((is-a? statement <initial-compound>) trigger)
                                                     ((and (is-a? statement <trigger-return>) reply)
                                                      (clone statement #:expression reply))
                                                     (statement)
                                                     (reply (make <trigger-return> #:port.name port #:expression reply))
                                                     (trigger)
                                                     (else #f)))))
                (and event (format #f "~a.~a" instance event))))

            (cond ((not trace-step?)
                   (when (and locations? verbose?)
                     (let ((string (step->string pc)))
                       (when string
                         (format #t "~a~a\n" location (step->string pc))))))
                  (else
                   (let* ((swap? (or (is-a? statement <trigger-return>)
                                     (and (is-a? statement <action>)
                                          (ast:out? statement))
                                     (and (not statement) reply)
                                     (and (is-a? statement <trigger>)
                                          (runtime:boundary-port? instance)
                                          (ast:out? statement)
                                          #t)
                                     (and (is-a? statement <initial-compound>)
                                          (is-a? trigger <q-trigger>))
                                     (is-a? statement <q-in>)
                                     (is-a? statement <q-out>)
                                     (is-a? statement <q-trigger>)))
                          (arrow (if swap? " <- " " -> "))
                          (other-side (if interface? (statement->string statement)
                                          "..."))
                          (left-string (if (eq? first? swap?) other-side (step->string pc)))
                          (right-string (if (eq? first? swap?) (step->string pc) other-side)))
                     (format #t "~a~a~a\n" left-string arrow right-string))))

            (cond
             ((and (is-a? statement <action>)
                   (ast:out? statement)
                   (runtime:boundary-port? instance)
                   (ast:requires? (.ast instance)))
              (let* ((q-trigger (make <q-trigger> #:event.name (.event.name statement)
                                      #:port.name port))
                     (q-in (make <q-in> #:trigger q-trigger))
                     (other-port (runtime:other-port (runtime:port instance port)))
                     (instance (.container other-port))
                     (pc (clone pc #:instance instance #:statement q-in)))
                (loop (cons pc (cdr steps)) first? port reply)))
             ((and (is-a? statement <action>)
                   instance
                   (ast:out? statement)
                   (not (runtime:boundary-port? instance))
                   (let* ((port (.port trigger))
                          (r:other-port (runtime:other-port (runtime:port instance port))))
                     (runtime:boundary-port? r:other-port)))
              (let* ((port (.port trigger))
                     (r:other-port (runtime:other-port (runtime:port instance port)))
                     (pc (clone pc #:instance #f #:statement statement)))
                (loop (cons pc (cdr steps)) first? port reply)))
             ((and (is-a? statement <trigger-return>)
                   (runtime:boundary-port? instance))
              (let* ((other-port (runtime:other-port (runtime:port instance port)))
                     (instance (.container other-port))
                     (name (.name (.ast other-port)))
                     (other-statement (clone statement #:port.name name))
                     (pc (clone pc #:instance instance #:statement other-statement)))
                (loop (cons pc (cdr steps)) first? port reply)))
             ((and (is-a? statement <trigger-return>)
                   (not (is-a? statement <trigger-return-trace>))
                   (not (is-a? instance <runtime:port>))
                   (let* ((trigger (clone statement #:port.name (.port.name statement)))
                          (trigger (clone trigger #:parent (.type (.ast instance))))
                          (port-name (.port.name statement))
                          (port (.port trigger)))
                     (and port
                          (let* ((r:port (runtime:port instance port))
                                 (r:other-port (runtime:other-port r:port)))
                            (not (and (runtime:boundary-port? r:other-port)
                                      (ast:requires? (.ast r:other-port))))))))
              (let* ((trigger (clone statement #:port.name (.port.name statement)))
                     (component (.type (.ast instance)))
                     (trigger (clone trigger #:parent component))
                     (port-name (.port.name statement))
                     (other-port (.port trigger))
                     (r:port (runtime:port instance other-port))
                     (r:other-port (runtime:other-port r:port))
                     (other-instance (.container r:other-port))
                     (name (.name (.ast r:other-port)))
                     (other-statement (make <trigger-return-trace>
                                        #:port.name name
                                        #:expression (.expression statement)))
                     (pc (clone pc #:instance other-instance #:statement other-statement)))
                (loop (cons pc (cdr steps)) first? port reply)))

             (else
              (loop (cdr steps) first? port reply)))))))))


;;;
;;; Report
;;;

(define (step->location o)
  (let ((location (ast:location o)))
    (and location
         (format #f "~a:~a:~a: "
                 (.file-name location)
                 (.line location)
                 (.column location)))))

(define (label->string o)
  (match o
    (($ <trigger>) (trigger->string o))
    (($ <enum-literal>)
     (string-append (label->string (ast:name (.type.name o))) "_" (label->string (.field o))))
    (($ <literal>) (label->string (.value o)))
    ;; FIXME!??!
    ;; labels from <end-of-trail> strip to .node?
    ;; (label->string (.labels (.status (.ast <end-of-trail>))))
    ((? (is? <ast-node>))
     (let ((root (make <root> #:elements (list o))))
       (label->string (car (.elements root)))))))

(define (statement->string o)
  (match o
    (($ <action>) (trigger->string o))
    (($ <trigger>) (trigger->string o))
    (($ <illegal>) "illegal")
    (($ <q-in>) "<q>")
    (($ <q-out>) "<q>")
    (($ <q-trigger>) (trigger->string o))
    ((and ($ <trigger-return>) (= .expression #f) (= .port.name #f))
     "return")
    ((and ($ <trigger-return>) (= .expression #f) (= .port.name port))
     (string-append (statement->string port) ".return"))
    ((and ($ <trigger-return>) (= .expression expression) (= .port.name #f))
     (statement->string expression))
    ((and ($ <trigger-return>) (= .expression expression) (= .port.name port))
     (string-append (statement->string port) "." (statement->string expression)))
    ((and ($ <trigger-return>) (= .expression #f)) "return")

    ;; trace completion
    ((and ($ <trigger-return-trace>) (= .expression #f) (= .port.name #f))
     "return")
    ((and ($ <trigger-return-trace>) (= .expression #f) (= .port.name port))
     (string-append (statement->string port) ".return"))
    ((and ($ <trigger-return-trace>) (= .expression expression) (= .port.name #f))
     (statement->string expression))
    ((and ($ <trigger-return-trace>) (= .expression expression) (= .port.name port))
     (string-append (statement->string port) "." (statement->string expression)))
    ((and ($ <trigger-return-trace>) (= .expression #f)) "return")


    ((? number?) (number->string o))
    ("void" "return")
    ((? string?) o)
    ((? symbol?) (symbol->string o))
    (($ <enum-literal>)
     (string-append (statement->string (ast:name (.type.name o))) "_" (statement->string (.field o))))
    (($ <literal>) (statement->string (.value o)))
    ((and ($ <reply>) (= .expression (? (is? <literal>))))
     ((compose statement->string .expression) o))
    (($ <reply>) ((compose statement->string .expression) o))
    (#f "false")
    (#t "true")
    ((? (is? <ast>)) (statement->string (ast-name o)))))

(define (initial-error-message traces)
  (let* ((pcs (map car traces))
         (status (.status (car pcs))))
    (match status
      (($ <compliance-error>)
       (let* ((component-acceptance (.component-acceptance status))
              (port-acceptances (.port-acceptance status))
              (port-acceptances (ast:acceptance* port-acceptances))
              (port-acceptance (and (pair? port-acceptances) (car port-acceptances)))
              (location (or (step->location (or component-acceptance
                                                port-acceptance))
                            "<unknown-file>:")))
         (format #f "~aerror: non-compliance\n" location)))
      ((and (? (is? <determinism-error>)))
       (let ((locations (map (lambda (pc)
                               (or (step->location (.ast (.status pc)))
                                   "<unknown-file>:"))
                             pcs)))
         (string-join (map (cut format #f "~aerror: non-deterministic\n" <>) locations) "\n")))
      (($ <queue-full-error>)
       (let* ((model ((compose  ast:dotted-name .type .ast .instance) status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: queue-full in component ~s\n" location model)))
      (($ <range-error>)
       (let* ((variable (.variable status))
              (name (.name variable))
              (type (.type variable))
              (value (.value status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: range-error: invalid value `~a' for variable `~a'\n" location value name)))
      ((and (? (is? <missing-reply-error>)))
       (let* ((type (.type status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: missing-reply: ~a reply expected\n" location (type-name type))))
      (($ <second-reply-error>)
       (let* ((previous (.previous status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: second-reply\n" location)))
      ((and (? (is? <error>)) (= .ast ast) (= .message message))
       (let ((location (or (step->location ast)
                           "<unknown-file>:")))
         (format #f "~aerror: ~a\n" location message)))
      ((and (? (is? <match-error>)) (= .ast ast))
       (let ((location (or (step->location ast)
                           "<unknown-file>:")))
         (format #f "~aerror: ~a\n" location (.input status))))
      ((and (? (is? <error>)) (= .ast ast) (= .message message))
       (let ((location (or (step->location ast)
                           "<unknown-file>:")))
         (format #f "~aerror: ~a\n" location message)))
      ((and (? (is? <error>)) (= .message message))
       (let* ((ast (.ast status))
              (location (or (and=> ast step->location)
                            "<unknown-file>:")))
         (format #f "~aerror: ~a\n" location message)))
      (($ <end-of-trail>) #f)
      (_ #f #f))))

(define (final-error-messages traces)
  (let* ((pcs (map car traces))
         (status (.status (car pcs))))
    (match status
      (($ <compliance-error>)
       (let* ((component-acceptance (.component-acceptance status))
              (port-acceptances (.port-acceptance status))
              (port-acceptances (ast:acceptance* port-acceptances))
              (port-acceptance (and (pair? port-acceptances) (car port-acceptances)))
              (location (or (step->location (or component-acceptance
                                                port-acceptance))
                            "<unknown-file>:"))
              (acceptance (if component-acceptance (trigger->string component-acceptance)
                              "-"))
              (port-name (string-join (runtime:instance->path (.port status)) "."))
              (component-name (string-join (runtime:instance->path (or (.instance (car pcs)) (%sut))) ".")))
         (string-join
          (cons*
           (format #f "~acomponent accept: ~a\n" location acceptance)
           (map
            (lambda (ast)
              (if ast
                  (format #f "~a     port accept: ~a\n" (step->location ast) (trigger->string ast))
                  (let* ((ast ((compose .statement .behaviour .type .ast .port) status))
                         (location (step->location ast)))
                    (format #f "~a     port accept: ~a\n"  location "none"))))
            (ast:acceptance* status)))
          "")))
      (($ <range-error>)
       (let* ((variable (.variable status))
              (name (.name variable))
              (type (.type variable))
              (value (.value status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (string-join
          (list
           (format #f "~ainfo: ~a `~a' defined here\n" (step->location variable) (ast-name variable) name)
           (format #f "~ainfo: of type `~a' defined here\n" (step->location type) (ast:name type)))
          "")))
      (($ <second-reply-error>)
       (let* ((previous (.previous status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~ainfo: reply previously set here\n" (step->location previous))))
      ((and (? (is? <match-error>)) (= .ast ast))
       (let ((location (or (step->location ast)
                           "<unknown-file>:")))
         (format #f "~aerror: no match; at ast `~s', got input `~s'\n"
                 location (statement->string ast) (.input status))))
      (($ <end-of-trail>)
       (let* ((instance (.instance (car pcs)))
              (ast (.ast status))
              (port-name (if instance (string-join (runtime:instance->path instance) ".")
                             (.port.name ast)))
              (instance (if instance (runtime:instance->string instance)
                            port-name))
              (location (or (step->location (.ast status))
                            "<unknown-file>:"))
              (ast (trigger->string (clone ast #:port.name #f))))
         (format #f "~aerror: end of trail; stopping here: ~a.~a\n" location instance ast)))
      (_ #f))))

(define (end-of-trail-labels pc)
  (let* ((status (.status pc))
         (instance (.instance pc))
         (ast (.ast status))
         (port-name (if instance (string-join (runtime:instance->path instance) ".")
                        (.port.name ast)))
         (instance (if instance (runtime:instance->string instance)
                       port-name))
         (location (or (step->location (.ast status))
                       "<unknown-file>:"))
         (ast (trigger->string (clone ast #:port.name #f)))
         (labels (.labels status))
         (labels (map (lambda (x) (if (is-a? x <trigger-node>) (clone x #:port.name #f) x)) labels))
         (labels (map statement->string labels))
         (labels (map (cut string-append port-name "." <>) labels)))
    labels))

(define* (report traces #:key eligible header (trace "event") locations? verbose?)
  (let* ((pcs (and (pair? traces) (map car traces)))
         (pc (and pcs (car pcs)))
         (status (and pc (.status pc)))
         (initial-message (and status (initial-error-message traces))))
    (when initial-message
      (display initial-message (current-error-port)))

    ;; XXX TODO: handle set of (non-deterministic) traces.
    ;;(for-each display-trace-n traces (iota (length traces)))
    (cond ((null? traces))
          ((equal? trace "event")
           (display-trails traces))
          ((equal? trace "trace")
           (display-trace (car traces)
                          #:locations? locations? #:verbose? verbose?)))

    (when pc
      (serialize (.state pc) (current-output-port))
      (newline))

    (when (and (equal? trace "trace") initial-message)
      (display initial-message))
    (when (pair? traces)
      (let ((final-messages (final-error-messages traces)))
        (when final-messages
          (display final-messages (current-error-port)))

        (when (equal? trace "trace")
          (let* ((trail (trace->trail (car traces)))
                 (trail (map cdr trail)))
            (when (pair? trail)
              (format #t "~s\n" (cons 'trail trail)))))))

    (when (and (equal? trace "trace")
               eligible)
      (let ((eligible (if (is-a? status <end-of-trail>) (end-of-trail-labels pc)
                          eligible)))
        (format #t "~s\n" (cons 'labels (labels)))
        (format #t "~s\n" (cons 'eligible eligible))))

    (when status
      (exit EXIT_FAILURE))))
