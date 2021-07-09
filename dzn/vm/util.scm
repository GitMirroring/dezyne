;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018, 2019, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2021 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (dzn vm util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn serialize)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm runtime)
  #:export (%debug
            %debug?
            %queue-size
            append-port-trace
            action->trigger
            assign
            async-event?
            dequeue
            dequeue-external
            enqueue
            enqueue-external
            flush
            get-handling?
            get-state
            get-variables
            in-event?
            is-status?
            label?
            labels
            make-pc
            make-system-state
            modeling-names
            out-event?
            pc->hash
            pc->string
            pop-locals
            port-event?
            provides-trigger?
            push-local
            q-empty?
            pc:eq?
            pop-deferred
            pop-pc
            push-pc
            read-input
            requires-trigger?
            rewrite-trace-head
            rtc-program-counter-equal?
            rtc-port
            rtc-trigger
            serialize
            serialize-header
            set-deferred
            set-handling?
            set-state
            set-variables
            string->q-trigger
            string->trail
            string->trail+model
            string->trigger
            string->value
            trace-head:eq?
            trigger->component-trigger
            trigger->port-trigger
            trigger->string
            update-state)
  #:re-export (eval-expression))

(cond-expand
 (guile-3
  (use-modules (ice-9 copy-tree)))
 (else
  #t))

;;;
;;; Commentary:
;;;
;;; Utility functions for the Dezyne VM.
;;;
;;; Code:

;;; Debug facility
(define %debug? #f)

(define-syntax-rule (%debug fmt arg ...)
  (when %debug?
    (format (current-error-port) fmt arg ...)))

;;; The size of the component queues and external queues.
(define %queue-size (make-parameter 3))


;;;
;;; Input, labels
;;;

(define (read-input-file)
  (define (helper x)
    (if (eof-object? x) '()
        (cons x (helper (read)))))
  (helper (read)))

(define (string->trail trail)
  (define (->string o)
    (if (symbol? o) (symbol->string o) o))
  (let* ((trail (string-join (string-split trail #\,) " "))
         (trail (with-input-from-string trail read-input-file))
         (trail (map ->string trail))
         (trail (filter (negate (conjoin string? (cute string-prefix? "<" <>))) trail)))
    trail))

(define (string->trail+model trail)
  (let* ((model-match (string-match "(^[ \n]*model: ?([^ \n,]+))" trail))
         (trail (if model-match
                    (substring trail (match:end model-match))
                    trail))
         (trail (string->trail trail))
         (model (and model-match (match:substring model-match 2))))
    (values trail model)))

(define-method (read-input pc)
  (when (isatty? (current-input-port))
    (format #t "input: "))
  (let* ((input (read))
         (input (match input
                  ((? symbol?) (symbol->string input))
                  ((? eof-object?) #f)
                  (#f #f))))
    (values input pc)))

(define-method (labels)
  (if (is-a? (%sut) <runtime:port>)
      (let* ((interface ((compose .type .ast %sut)))
             (modeling-names (modeling-names interface)))
        (append (map .name (ast:in-event* interface))
                modeling-names))
      (append-map
       (lambda (p)
         (map (compose (cute string-append (runtime:dotted-name p) "." <>) .name)
              (filter (if (or (ast:provides? (.ast p))) ast:in? ast:out?)
                      (ast:event* (.ast p)))))
       (filter runtime:boundary-port? (%instances)))))

(define-method (label? (o <string>))
  (and (member o (labels)) o))

(define-method (label? (o <boolean>))
  #f)

(define-method (trigger->string o)
  (let* ((event (.event.name o))
         (event (if (equal? event "void") "return" event)))
    (if (.port.name o) (format #f "~a.~a" (.port.name o) event)
        (format #f "~a" event))))

(define-method (trigger->string (o <q-out>))
  (trigger->string (.trigger o)))

(define-method (trigger->string (o <illegal>))
  "illegal")

(define-method (string->value (type <bool>) (o <string>))
  (let ((value (string-split o #\.)))
    (match value
      ((path ... "true") (make <literal> #:value "true"))
      ((path ... "false") (make <literal> #:value "false")))))

(define-method (string->value (type <int>) (o <string>))
  (let ((value (string-split o #\.)))
    (match value
      ((path ... number) (make <literal> #:value (string->number number))))))

(define-method (string->value (type <enum>) (o <string>))
  (let* ((value (last (string-split o #\.)))
         (enum (string-split value #\:)))
    (match enum
      ((name field) (or (and (equal? (ast:name type) name)
                             (member field (ast:field* type))
                             (make <enum-literal> #:type.name (.name type) #:field field))
                        (let ((message (format #f "invalid enum value: ~s [~s]\n" o (map (cut string-append (ast:name type) ":" <>) (ast:field* type)))))
                          (display message (current-error-port))
                          (throw 'invalid-input message)))))))

(define (modeling-names-unmemoized o)
  (let ((modeling (tree-collect (conjoin (is? <trigger>) ast:modeling?) o)))
    (delete-duplicates (sort (map .event.name modeling) string=?))))

(define-method (modeling-names (o <interface>))
  ((ast:pure-funcq modeling-names-unmemoized) o))

(define-method (modeling-names (o <runtime:port>))
  (modeling-names ((compose .type .ast) o)))

(define-method (modeling-names)
  (modeling-names (%sut)))



;;;
;;; Trigger conversion
;;;

(define-method (action->trigger (o <runtime:port>) (action <action>))
  (clone (make <trigger>
           #:port.name (and (not (.boundary? o)) (.name (.ast o)))
           #:event.name (.event.name action)
           #:location (.location action))
         #:parent (.type (.ast (if (runtime:boundary-port? o) o
                                   (.container o))))))

(define-method (trigger->component-trigger (o <runtime:port>) (trigger <trigger>))
  (let* ((port (.ast o))
         (trigger (clone trigger #:port.name (.name port))))
    (let* ((instance (or (.container o) (%sut))) ;injected
           (model (.type (.ast instance)))
           (location (ast:location model))
           (trigger (clone trigger #:location location)))
      (clone trigger #:parent model))))

(define-method (trigger->component-trigger (trigger <trigger>))
  (let* ((port-name (.port.name trigger))
         (r:port (runtime:port-name->instance port-name))
         (r:component-port (runtime:other-port r:port)))
    (trigger->component-trigger r:component-port trigger)))

(define-method (trigger->port-trigger (o <runtime:port>) (trigger <trigger>))
  (let* ((interface ((compose .type .ast) o))
         (location (.location interface))
         (trigger (clone trigger #:port.name #f #:location location)))
    (clone trigger #:parent interface)))

(define-method (string->trigger (class <class>) (o <string>))
  "Return (class [PORT-NAME] EVENT-NAME) from O of form [PORT.]EVENT."
  (let* ((model ((compose .type .ast %sut)))
         (location (ast:location model))
         (trigger (match (string-split o #\.)
                    ((event) (make class #:event.name event))
                    ((port event) (make class #:port.name port #:event.name event))
                    ((path ... port event) (make <trigger>
                                             #:port.name (string-join (append path (list port)) ".")
                                             #:event.name event))))
         (trigger (clone trigger #:location location))
         (trigger (clone trigger #:parent model)))
    trigger))

(define-method (string->trigger (o <string>))
  "Return (trigger [PORT-NAME] EVENT-NAME) from O of form [PORT.]EVENT."
  (string->trigger <trigger> o))

(define-method (string->q-trigger (o <string>))
  "Return (q-trigger [PORT-NAME] EVENT-NAME) from O of form [PORT.]EVENT."
  (string->trigger <q-trigger> o))



;;;
;;; Program counter stack
;;;

(define-method (pop-pc (pc <program-counter>))
  (let ((previous (.previous pc)))
    (clone pc
           #:trigger (.trigger previous)
           #:instance (.instance previous)
           #:previous (.previous previous)
           #:statement (.statement previous))))

(define-method (push-pc (pc <program-counter>))
  (clone pc #:previous pc #:statement #f))

(define-method (push-pc (pc <program-counter>) (trigger <trigger>) (instance <runtime:instance>) (statement <statement>))
  (clone pc #:previous pc #:trigger trigger #:instance instance #:statement statement))

(define-method (push-pc (pc <program-counter>) (statement <statement>))
  (clone pc #:previous pc #:statement statement))

(define-method (push-pc (pc <program-counter>) (trigger <trigger>) (instance <runtime:instance>))
  (push-pc pc trigger instance (ast:statement instance)))

(define-method (push-pc (pc <program-counter>) (instance <runtime:instance>) (statement <statement>))
  (clone pc #:previous pc #:instance instance #:statement statement))

(define-method (rtc-trigger (pc <program-counter>))
  (let ((triggers (unfold (negate (cute .previous <>)) .trigger .previous pc)))
    (last triggers)))

(define-method (rtc-port (pc <program-counter>))
  (and=> (rtc-trigger pc) .port))


;;;
;;; Q and flush
;;;

(define-method (enqueue (pc <program-counter>)  (ast <ast>) (instance <runtime:component>) (trigger <trigger>))
  (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<enqueue>" (trigger->string trigger))
  (let* ((state (get-state pc instance))
         (q (.q state)))
    (if (= (length q) (%queue-size))
        (clone pc #:status (make <queue-full-error> #:ast ast #:message "queue-full" #:instance instance))
     (set-deferred (set-state pc (clone state #:q (append q (list trigger)))) instance))))

(define-method (dequeue (pc <program-counter>))
  (let* ((state (get-state pc))
         (q (.q state))
         (pc (set-state pc (clone state #:q (cdr q))))
         (trigger (car q)))
    (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<dequeue>" (trigger->string trigger))
    (values pc trigger)))

(define-method (enqueue-external (pc <program-counter>) (ast <ast>) (trigger <trigger>))
  (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<enqueue-external>" (trigger->string trigger))
  (let* ((external-q (.external-q pc))
         (instance (.instance pc))
         (q (or (assoc-ref external-q instance) '())))
    (if (= (length q) (%queue-size))
        (clone pc #:status (make <queue-full-error> #:ast ast #:message "queue-full" #:instance instance))
        (let* ((external-q (alist-delete instance external-q))
               (external-q (acons instance (append q (list trigger)) external-q))
               (external-q (sort external-q
                                 (match-lambda*
                                   (((port-a q-a ...) (port-b q-b ...))
                                    (string< (name port-a) (name port-b)))))))
          (clone pc #:external-q external-q)))))

(define-method (dequeue-external (pc <program-counter>) (instance <runtime:port>))
  (let* ((external-q (.external-q pc))
         (q (assoc-ref external-q instance)))
    (if (null? q) (values pc #f)
        (let* ((tail (cdr q))
               (external-q (alist-delete instance external-q))
               (external-q (if (null? tail) external-q
                               (acons instance (cdr q) external-q)))
               (pc (clone pc #:external-q external-q))
               (trigger (car q)))
          (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<dequeue-external>" (trigger->string trigger))
          (values pc trigger)))))

(define-method (get-handling? (pc <program-counter>) (instance <runtime:instance>))
  (.handling? (get-state pc instance)))

(define-method (set-handling? (pc <program-counter>) handling?)
  (set-state pc (clone (get-state pc) #:handling? handling?)))

(define-method (pop-deferred (pc <program-counter>))
  (values (set-deferred pc #f) (.deferred (get-state pc))))

(define-method (set-deferred (pc <program-counter>) deferred)
  (set-state pc (clone (get-state pc) #:deferred deferred)))

(define-method (flush (pc <program-counter>) instance)
  (let* ((flush-return (make <flush-return>))
         (pc (push-pc pc flush-return))
         (pc (clone pc #:instance instance)))
    (if (null? (.q (get-state pc))) (let ((pc deferred (pop-deferred pc)))
                                      (%debug "  flush deferred: ~s\n" deferred)
                                      (if (not deferred) pc
                                          (if (get-handling? pc deferred) (throw 'handling "already handling event" pc)
                                              (flush pc deferred))))
        (let ((pc trigger (dequeue pc)))
          (let* ((q-out (make <q-out> #:trigger trigger))
                 (q-out (clone q-out #:location (.location trigger))))
            (push-pc pc trigger instance q-out))))))

(define-method (flush (pc <program-counter>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<flush>")
  (flush pc (.instance pc)))


;;;
;;; State / locals / assign
;;;

(define-method (get-state (o <system-state>) (instance <runtime:instance>))
  (find (compose (cute eq? <> instance) .instance) (.state-list o)))

(define-method (get-state (o <program-counter>) (instance <runtime:instance>))
  (get-state (.state o) instance))

(define-method (get-state (o <program-counter>))
  (get-state o (.instance o)))

(define-method (set-state (pc <program-counter>) (o <state>))
  (clone pc #:state (clone (.state pc) #:state-list (map (lambda (x) (if (eq? (.instance o) (.instance x)) o x)) ((compose .state-list .state) pc)))))

(define-method (set-state (pc <program-counter>) (state <list>))
  (fold (cut update-state state <> <>) pc ((compose .state-list .state) pc)))

(define-method (get-variables (pc <program-counter>))
  ((compose .variables get-state) pc))

(define-method (set-variables (pc <program-counter>) (o <list>))
  (set-state pc (clone (get-state pc) #:variables o)))

(define-method (push-local (o <formal>) (e <expression>) (pc <program-counter>))
  (or (and=> (range-error o e) (cut clone pc #:status <>))
      (set-variables pc (acons (.name o) e (get-variables pc)))))

(define-method (push-local (pc <program-counter>) (o <variable>))
  (set-variables pc (acons (.name o) (.expression o) (get-variables pc))))

(define-method (pop-locals (pc <program-counter>) (o <list>))
  (set-variables pc (drop (get-variables pc) (length o))))

(define-method (eval-expression (o <state>) (e <expression>))
  (eval-expression (.variables o) e))

(define-method (eval-expression (pc <program-counter>) (e <expression>))
  (eval-expression (get-state pc) e))

(define-method (range-error o (value <expression>))
  (unless (or (is-a? o <formal>) (is-a? o <variable>))
    (error "range-error" o))
  (let ((type (.type o)))
    (and (is-a? type <int>)
         (let ((range (.range type))
               (value (.value value)))
           (and (or (< value (.from range))
                    (> value (.to range)))
                (make <range-error> #:ast o #:variable o #:value value
                      #:message "range-error"))))))

(define-method (assign (state <state>) (variable <variable>) expression)
  (let ((name (.name variable))
        (value (eval-expression state expression)))
    (or (range-error variable value)
        (clone state #:variables (assoc-set! (copy-tree (.variables state)) name value)))))

(define-method (assign (pc <program-counter>) (variable <variable>) (e <expression>))
  (let ((result (assign (get-state pc) variable e)))
    (if (is-a? result <error>)
        (clone pc #:status result)
        (set-state pc result))))

(define-method (assign (pc <program-counter>) (variable <variable>) (e <action>))
  (assign (clone pc #:reply #f) variable (.reply pc)))

(define-method (assign (pc <program-counter>) (variable <variable>) (e <call>))
  (assign (clone pc #:reply #f) variable (.return pc)))

(define-method (assign (pc <program-counter>) (variable <variable>) (e <variable>))
  (assign (clone pc #:reply #f) variable (.reply pc)))

(define (rewrite-trace-head rewriter trace)
  (match trace
    ((pc tail ...)
     (cons (rewriter pc) tail))))

(define-method (append-port-trace (pc <program-counter>) trace (port-instance <runtime:port>) port-trace)
  (let* ((ipc (car port-trace))
         (pc (set-state pc (get-state ipc port-instance))))
    (cons pc (cdr trace))))


;;;
;;; Serialise / Deserialise state
;;;

(define-method (serialize (o <system-state>))
  (with-output-to-string
    (lambda _ (cons 'state (serialize o (current-output-port))))))

(define-method (serialize (o <state>))
  (with-output-to-string
    (lambda _
      ;; TODO c&p serialize <state>
      (let ((port (current-output-port)))
        (display "(" port)
        (display ((compose runtime:instance->path .instance) o) port)
        (for-each (match-lambda ((x . y)
                                 (display " " port)
                                 (display (cons x (->sexp y)) port)))
                  (.variables o))
        (display ")" port)))))

(define-method (serialize (o <system-state>) port)
  (display "(state " port)
  (for-each (lambda (x) (unless (eq? x ((compose car .state-list) o))
                          (display " " port))
                    (serialize x port))
            (.state-list o))
  (display ")" port))

(define-method (serialize (o <state>) port)
  (display "(" port)
  (display ((compose runtime:instance->path .instance) o) port)
  (for-each (match-lambda ((x . y)
                           (display " " port)
                           (display (cons x (->sexp y)) port)))
            (.variables o))
  (display ")" port))

(define-method (serialize-header (o <system-state>))
  (with-output-to-string
    (lambda _ (cons 'header (serialize-header o (current-output-port))))))

(define-method (serialize-header (o <system-state>) port)
  (display "(header " port)
  (for-each (lambda (x)
              (unless (eq? x ((compose car %instances)))
                (display " " port))
              (serialize-header x port))
            (filter (disjoin (negate (is? <runtime:port>))
                             runtime:boundary-port?)
                    (%instances)))
  (display ")" port))

(define-method (serialize-header (o <runtime:instance>) port)
  (display "(" port)
  (let* ((model (.ast o))
         (name (ast:dotted-name (.type model)))
         (kind (runtime:kind o))
         (path (runtime:instance->path o)))
    (display path port)
    (display " " port)
    (display name port)
    (display " " port)
    (display kind port))
  (display ")" port))

(define (sexp->value v)
  (match v
    ('true (make <literal> #:value "true"))
    ('false (make <literal> #:value "false"))
    ((? number?) (make <literal> #:value v))
    (_ (let ((enum (string-split (symbol->string v) #\:)))
         (match enum
           ((ids ... field)
            (make <enum-literal> #:type.name (make <scope.name> #:ids ids) #:field field))))) ;; FIXME: what about resolving
    ))

(define (update-variable update-list variable state)
  (let ((name (string->symbol (.name variable))))
    (or (and=> (assoc-ref update-list name) (compose (cut assign state variable <>) sexp->value))
        state)))

(define (update-state event state pc)
  (let* ((instance (.instance state))
         (path (map string->symbol (runtime:instance->path instance)))
         (update-list (assoc-ref event path))
         (result (fold (cut update-variable update-list <> <>) state ((compose ast:variable* .type .ast) instance))))
    (if (is-a? result <error>) (clone pc #:status result)
        (set-state pc result))))


;;;
;;; Hashing state
;;;

(define-method (state->string (o <state>))
  (let* ((path (runtime:instance->path (.instance o)))
         (path (match path
                 (("sut" path ...) path)
                 (_ path)))
         (variables (map (match-lambda ((x . y)
                                        (format #f "~a=~a" x (->sexp y))))
                         (.variables o)))
         (q (.q o)))
    (and (or (pair? variables) (pair? q))
         (string-append
          (string-join path ".")
          (if (pair? path) "=" "")
          "["
          (string-join variables ",\n")
          (if (null? q) ""
              (string-append "q=" (string-join (map trigger->string q) ",")))
          "]"))))

(define-method (state->string (o <system-state>))
  (let* ((state-list (.state-list o))
         (state-list (if (is-a? (%sut) <runtime:port>) state-list
                         (filter (disjoin (compose (is? <runtime:component>) .instance)
                                          (compose ast:requires? .ast .instance))
                                 state-list))))
    (string-join (filter-map state->string state-list) "\n")))

(define-method (pc->string (o <program-counter>))
  (match (.status o)
    ((or ($ <illegal-error>) ($ <implicit-illegal-error>))
     "<illegal>")
    ((? identity)
     "<deadlock>")
    (_
     (string-join
      (cons (state->string (.state o))
            (append (map (compose runtime:dotted-name car) (.blocked o))
                    (if (null? (.external-q o)) '()
                        (list (external-q->string (.external-q o))))
                    (map (match-lambda ((timeout port . proc)
                                        (runtime:dotted-name port)))
                         (.async o))))
      "\n"))))

(define-method (pc->hash (o <program-counter>))
  (string-hash (pc->string o)))


;;;
;;; Predicates
;;;

(define-method (is-status? (type <class>))
  (lambda (pc) (is-a? (.status pc) type)))

(define (provides/requires-trigger? string ast:provides/requires? ast:in/out?)
  (let* ((trigger (string->trigger string))
         (event (.event.name trigger)))
    (if (is-a? (.type (.ast (%sut))) <interface>)
        (member event (map .name (filter ast:in/out? (ast:event* (.type (.ast (%sut)))))))
        (let* ((port-name (.port.name trigger))
               (ports (filter runtime:boundary-port? (%instances)))
               (ports (filter (compose ast:provides/requires? .ast) ports))
               (port (find (compose (cute equal? <> port-name)
                                    runtime:dotted-name)
                           ports))
               (port (and port (.ast port))))
          (and port
               (ast:dotted-name (.type port))
               (let* ((events (filter ast:in/out? (ast:event* port)))
                      (event-names (map .name events)))
                 (member event event-names)))))))

(define (provides-trigger? string)
  (and (string? string) (provides/requires-trigger? string ast:provides? ast:in?)))

(define (requires-trigger? string)
  (and (string? string) (provides/requires-trigger? string ast:requires? ast:out?)))

(define-method (in-event? (o <interface>) (event <string>))
  (let* ((events (ast:in-event* o))
         (event-names (map .name events)))
    (member event event-names)))

(define-method (in-event? (o <runtime:port>) (event <string>))
  (in-event? ((compose .type .ast) o) event))

(define-method (in-event? (event <string>))
  (in-event? (%sut) event))

(define-method (out-event? (o <interface>) (event <string>))
  (let* ((events (ast:out-event* o))
         (event-names (map .name events)))
    (member event event-names)))

(define-method (out-event? (o <runtime:port>) (event <string>))
  (out-event? ((compose .type .ast) o) event))

(define-method (out-event? (event <string>))
  (out-event? (%sut) event))

(define (port-event? port-name e)
  (and (string? e)
       (match (string-split e #\.)
         (('state state) #f)
         ((port event) (and (equal? port port-name) event))
         (_ #f))))

(define-method (q-empty? (pc <program-counter>))
  (or (not (.instance pc))
      (null? (.q (get-state pc)))))

(define-method (rtc-program-counter-equal? (a <program-counter>) (b <program-counter>))
  (and (ast:eq? (.status a) (.status b))
       (ast:eq? (.statement a) (.statement b))
       (equal? (serialize (.state a)) (serialize (.state b)))
       (equal? (.trail a) (.trail b))))

(define-method (pc:eq? (pc0 <program-counter>) (pc1 <program-counter>))
  (and (equal? (pc->string pc0) (pc->string pc1))
       (equal? (and=> (.instance pc0) runtime:instance->path) (and=> (.instance pc1) runtime:instance->path))
       (pc:ast:eq? (.statement pc0) (.statement pc1))
       (pc:eq? (.previous pc0) (.previous pc1))))

(define-method (pc:eq? (pc0 <top>) (pc1 <top>))
  (eq? pc0 pc1))

(define (trace-head:eq? a b)
  (pc:eq? (car a) (car b)))

(define-method (pc:ast:eq? (a <flush-return>) (b <flush-return>))
  #t)

(define-method (pc:ast:eq? (a <trigger-return>) (b <trigger-return>))
  #t)

(define-method (pc:ast:eq? (a <top>) (b <top>))
  (ast:eq? a b))

(define-method (async-event? (pc <program-counter>) event)
  (and (string? event) (not (member event (labels))) (pair? (.async pc))))


;;;
;;; Initialization
;;;

(define-method (init (o <variable>))
  (let ((value (eval-expression '() (.expression o))))
    (or (range-error o value)
        (cons (.name o) (eval-expression '() (.expression o))))))

(define-method (make-state (o <runtime:instance>))
  (let* ((variables (map init ((compose ast:variable* .type .ast) o)))
         (errors (filter (is? <error>) variables)))
    (if (pair? errors) errors
        (make <state> #:instance o #:variables variables))))

(define-method (make-system-state instances)
  (make <system-state> #:state-list (map make-state (filter (disjoin runtime:boundary-port? (is? <runtime:component>)) instances))))

(define* (make-pc #:key (instances (%instances)) (trail '()))
  (let* ((system-state (make-system-state instances))
         (errors (apply append (filter list? (.state-list system-state))))
         (system-state (if (null? errors) system-state (make-system-state '())))
         (pc (make <program-counter> #:state system-state #:trail trail))
         (pc (if (null? errors) pc (clone pc #:status (car errors)))))
  pc))
