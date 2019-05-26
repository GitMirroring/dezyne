;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; TODO
;; error handling: meaningful messages
;; nonstrict and error path: handle output trail pruning
;; replace seqdiag
;; livelock detection
;; eligible events
;; return values when kwartjes only/not --strict: multiple traces vs user input?
;; favour illegal => pessimism
;; blocking
;; async
;; sub machines

(define-module (gaiag step)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <frame> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag evaluate)
  #:use-module (gaiag ast)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag command-line)
  #:use-module (gaiag runtime)
  #:use-module (gaiag normalize)
  #:use-module (gaiag step goops)
  #:use-module (gaiag step json)
  #:use-module (gaiag step normalize)
  #:use-module (gaiag state)
  #:use-module (gaiag serialize)

  #:export (step:ast->
            ->symbol
            action->trigger
            create-initial-state
            eligible-step?
            trigger-step?
            get-initial-state
            make-initial-node
            record-state
            record-step
            run
            run-trigger
            set-reply
            set-state
            set-status
            setup-debug-printing!
            side->string
            state-step?
            step->location
            ))

(define debug-pretty pretty-print)
(define debug stderr)
(define (debug-disable . _) (last _))

(define-class <frame> (<step>)
  (pc #:getter .pc #:init-form (list) #:init-keyword #:pc) ; <behaviour>, <statement>
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance) ; '(sut b)
  (trigger #:getter .trigger #:init-value #f #:init-keyword #:trigger)) ; <trigger>

(define-method (set-status (node <node>) (status <status>))
  (clone node #:status status))

(define-method (get-q (node <node>) (instance <runtime:instance>))
  (.q (get-state node instance)))

(define ((car-instance? instance) o)
  (eq? (car o) instance))

(define-method (set-state (node <node>) (instance <runtime:instance>) (state <state>))
  (clone node #:state-alist (acons instance state
                                   (filter (negate (car-instance? instance)) (.state-alist node)))))

(define-method (get-state (node <node>) (instance <runtime:instance>))
  (and=> (assoc instance (.state-alist node) eq?) cdr))

(define-method (get-vars (node <node>) (instance <runtime:instance>))
  (.vars (get-state node instance)))

(define-method (set-vars (node <node>) (instance <runtime:instance>) vars)
  (set-state node instance (clone (get-state node instance) #:vars vars)))

(define-method (push-variable (variable <ast>) expression (node <node>) (instance <runtime:instance>))
  (if (.status node) node
      (set-vars node instance (acons (.name variable) (eval-expression (get-vars node instance) expression)
                                     (get-vars node instance)))))

(define-method (push-local (variable <ast>) (node <node>) (instance <runtime:instance>))
  (push-variable variable (.expression variable) node instance))

(define-method (pop-locals nrlocals (node <node>) (instance <runtime:instance>))
  (if (.status node) node
      (set-vars node instance (list-tail (get-vars node instance) nrlocals))))

(define-method (assign (node <node>) (instance <runtime:instance>) (name <symbol>) value)
  (let ((vars (get-vars node instance)))
    (set-vars node instance (assq-set! (copy-tree vars) name value))))

(define-method (get-pc (node <node>))
  ((compose .pc car .stack) node))

(define-method (initial-statement (instance <runtime:instance>))
  (.behaviour (instance-ast instance)))

(define-method (push-frame (node <node>) (instance <runtime:instance>) (pc <ast>) (trigger <trigger>))
  (clone node #:stack (cons (make <frame> #:pc pc #:instance instance #:trigger trigger) (.stack node))))

;; FIXME: block?
(define-method (push-frame (node <node>) (instance <runtime:instance>) (pc <ast>) (symbol <symbol>))
  (clone node #:stack (cons (make <frame> #:pc pc #:instance instance #:trigger symbol) (.stack node))))

(define-method (pop-frame (node <node>))
  (clone node #:stack (cdr (.stack node))))

(define-method (get-frame (node <node>))
  ((compose car .stack) node))

(define-method (drop-next-trail (node <node>))
  (clone node #:trail (cdr (.trail node))))

(define-method (add-to-trail (node <node>) (o <symbol>))
  (clone node #:trail (cons o (.trail node))))

(define-method (get-next-trail (node <node>))
  (if (null? (.trail node)) null-symbol
      ((compose car .trail) node)))

(define-method (get-handling? (node <node>) (instance <runtime:instance>))
  (.handling? (get-state node instance)))

(define-method (set-handling? (node <node>) (instance <runtime:instance>) handling?)
  (set-state node instance (clone (get-state node instance) #:handling? handling?)))

(define-method (pop-deferred (node <node>) (instance <runtime:instance>))
  (values (set-deferred node instance #f) (.deferred (get-state node instance))))

(define-method (set-deferred (node <node>) (instance <runtime:instance>) deferred)
  (set-state node instance (clone (get-state node instance) #:deferred deferred)))

(define-method (get-reply (node <node>) (instance <runtime:instance>))
  (.reply (get-state node instance)))

(define-method (set-reply (node <node>) (instance <runtime:instance>) (reply <reply>))
  (set-state node instance (clone (get-state node instance) #:reply reply)))

(define-method (get-return (node <node>) (instance <runtime:instance>))
  (.return (get-state node instance)))

(define-method (set-return (node <node>) (instance <runtime:instance>) return)
  (set-state node instance (clone (get-state node instance) #:return return)))

(define-method (enqueue (node <node>) (instance <runtime:instance>) (trigger <trigger>))
  (let ((state (get-state node instance))
        (node (record-step node instance (make <q-in> #:trigger trigger))))
    (set-state node instance (clone state #:q (cons trigger (.q state))))))

(define-method (dequeue (node <node>) (instance <runtime:instance>))
  (let* ((state (get-state node instance))
         (q (.q state))
         (node (set-state node instance (clone state #:q (cdr q))))
         (node (record-step node instance (make <q-out> #:trigger (car q)))))
    (values node (car q))))

(define-method (edge:equal? (a <trigger>) (b <trigger>))
  (eq? (trigger->symbol a) (trigger->symbol b)))

(define-method (event-equal? (a <trigger>) (b <trigger>))
  (eq? (.event.name a) (.event.name b)))

(define-method (variable-init (o <variable>))
  (cons (.name o) (eval-expression '() (.expression o))))

(define-method (set-initial-state (node <node>) (instance <runtime:instance>) states-alist)
  (set-state node instance (make <state> #:vars (or (and=> (assoc instance states-alist eq?) cdr) '()))))

(define-method (create-initial-state (instance <runtime:instance>) states-alist)
  (acons instance
         (if (or (runtime:system-instance? instance) (runtime:foreign-instance? instance)) '()
             (map variable-init (ast:variable* (instance-ast instance))))
         states-alist))

(define (make-initial-node instances states-alist)
  (let loop ((instances instances))
    (if (null? instances) (make <node>)
        (set-initial-state (loop (cdr instances)) (car instances) states-alist))))

(define-method (instance-ast (instance <runtime:instance>))
  (.type (.instance instance)))

(define-method (record-step (node <node>) (instance <runtime:instance>) step)
  (debug "recording step ~a\n    instance ~a\n" step instance)
  (clone node #:steps (append (.steps node) (list (cons instance step)))))

(define-method (record-state (node <node>) (instance <runtime:instance>))
  (record-step node instance (.state-alist node)))

(define (trigger->symbol o)
  (if (.port.name o) (symbol-append (.port.name o) '. (.event.name o))
      (.event.name o)))

(define (trigger->string o)
  ((compose symbol->string trigger->symbol) o))

(define (->string o)
  (match o
    (($ <action>) (trigger->string o))
    (($ <action-out>) (trigger->string o))
    (($ <trigger>) (trigger->string o))
    (($ <illegal>) "illegal")
    (($ <q-in>) "<q>")
    (($ <q-out>) "<q>")
    (($ <q-trigger>) (->string (.trigger o)))
     ((and ($ <trigger-return>) (= .expression #f) (= .port.name #f))
      "return")
    ((and ($ <trigger-return>) (= .expression #f) (= .port.name port))
     (string-append (->string port) ".return"))
    ((and ($ <trigger-return>) (= .expression expression) (= .port.name #f))
     (->string expression))
    ((and ($ <trigger-return>) (= .expression expression) (= .port.name port))
     (string-append (->string port) "." (->string expression)))
    ((and ($ <trigger-return>) (= .expression #f)) "return")
    ((? number?) (number->string o))
    ((? string?) o)
    ((? symbol?) (symbol->string o))
    (($ <enum-literal>)
     (string-append (->string (.name (.type.name o))) "_" (->string (.field o))))
    (($ <literal>) (->string (.value o)))
    ((and ($ <reply>) (= .expression (? (is? <literal>))) (= (compose .value .expression) 'void)) "return")
    (($ <reply>) ((compose ->string .expression) o))
    (#f "false")
    (#t "true")
    ((? (is? <ast>)) (->string (ast-name o)))))

(define (->symbol o)
  ((compose string->symbol ->string) o))

(define* (symbol->trigger o #:optional instance)
  "If O is of form [PORT.]TRIGGER, produce (trigger [PORT] EVENT)"
  (let* ((o-list (symbol-split o #\.))
         (o-list (if (and instance (runtime:boundary-port? instance) (pair? (cdr o-list))) (cdr o-list) o-list)))
    (match o-list
      ((event) (make <trigger> #:event.name event))
      ((#f event) (make <trigger> #:event.name event))
      ((port event) (make <trigger> #:port.name port #:event.name event))
      ((outer-instance ... inner-instance port event) (make <trigger> #:port.name port #:event.name event)))))

(define (step->location o)
  (let ((location (ast:location o)))
    (and location
         (format #f "~a:~a:~a: "
                 (.file-name location)
                 (.line location)
                 (.column location)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-method (action->trigger (o <runtime:port>) (action <action>))
  (clone (make <trigger> #:port.name (.name (.instance o)) #:event.name (.event.name action)
               #:location (.location action))
         #:parent (.type (.instance (if (runtime:boundary-port? o) o
                                        (.container o))))))

(define-method (return->other-return (o <runtime:instance>) (return <trigger-return->))
  (let ((parent (.type (.instance (if (runtime:boundary-port? o) o
                                      (.container o))))))
    (clone (clone return #:port.name (.name (.instance o)) #:expression (ast:rescope (.expression return) parent))
           #:parent parent)))

(define-method (action->trigger (o <runtime:port>) (action <trigger>))
  (clone (clone action #:port.name (.name (.instance o)))
         #:parent (.type (.instance o))))

(define (boundary-step? step)
  ;;  (debug "\nboundary-step? step=~s\n" step)
  (let ((instance (car step))
        (statement (cdr step)))
    (and (is-a? statement <ast>)
         (or (is-a? statement <illegal>)
             (not (.port.name statement))
             (runtime:boundary-port? instance)
             (and (.port statement)
                  (let ((runtime-port (runtime:port (pke 'instance instance) (pke 'port (.port statement)))))
                    (and runtime-port
                         (let ((other-runtime-port (runtime:other-port runtime-port)))
                           (runtime:boundary-port? other-runtime-port)))))))))

(define (steps->boundary-steps steps)
  (filter boundary-step? (steps->trail steps #t)))

(define run-count 0)

(define-method (run (node <node>) (instance <runtime:instance>) (trigger <trigger>))
  (run node instance trigger #f))

(define-method (run (node <node>) (instance <runtime:instance>) (trigger <trigger>) silent) ; -> list of <node>, #list > 1 => non-determinism
;;  (set! run-count (warn 'run: (1+ run-count)))

  (debug "run[~a]: ~a\n" instance trigger)
  (debug "run: state[~a]: ~a\n" instance (get-state node instance))
  (debug "run: start walking\n")
  (walk node instance trigger (.statement (initial-statement instance)) #f silent))

(define walk-count 0)

(define-method (walk (node <node>) (instance <runtime:instance>) (trigger <trigger>) (statement <statement>) trigger? silent)
  ;; (if (.location statement) (stderr "~a:~s:~s: WALK: ~a ~a\n" (.file-name (.location statement)) (.line (.location statement)) (.column (.location statement)) (->symbol trigger) (ast-name statement))
  ;;     (stderr "WALK: ~a ~a\n" (->symbol trigger) (ast-name statement)))
;;  (set! walk-count (warn 'walk: (1+ walk-count)))
  (debug "walk: statement:~a\n" statement)
  (match statement
    ((and ($ <compound>) (? ast:declarative?) (= ast:statement* statements))
     (let ((nodes (append-map (cut walk node instance trigger <> trigger? silent) statements)))
       (if (or #t (is-a? instance <runtime:port>) (not (is-a? (.parent statement) <behaviour>)) (pair? nodes)) nodes
           (let* ((model ((compose .type .instance) instance))
                  (implicit-illegal (clone (make <illegal> #:incomplete #t #:location ((compose .location .behaviour) model)) #:parent model))
                  (node (record-step node instance trigger)))
             (step node instance implicit-illegal silent)))))
    (($ <guard>) (if (not (true? (eval-expression (get-vars node instance) (.expression statement)))) '()
                     (walk node instance trigger (.statement statement) trigger? silent)))
    (($ <blocking>) (walk node instance trigger (.statement statement) trigger? silent))
    (($ <on>) (let* ((component? (is-a? (instance-ast instance) <component>))
                     (trigger? (find (cut (if component? edge:equal? event-equal?) trigger <>)
                                     (ast:trigger* statement)))
                     (trigger? (and trigger? (clone trigger? #:location (.location statement))))
                     (required-out? (and trigger? component? (ast:requires? (.port trigger?))))
                     (node (record-step node instance statement)))
                (if (not trigger?) '()
                    (walk node instance trigger (.statement statement) trigger? silent))))
    ((? ast:imperative?)
     (let* ((component? (not (runtime:boundary-port? instance)))
            (handling? (get-handling? node instance)))
       (map (cut set-handling? <> instance #f)
            (let* ((node (set-handling? node instance #t))
                   (component? (is-a? (instance-ast instance) <component>))
                   (required-out? (and trigger? component? (ast:requires? (.port trigger?))))
                   (node (record-step node instance (if required-out? (make <q-trigger> #:trigger trigger?)
                                                        trigger?))))
             (debug "walk: start stepping\n")
              (step (push-frame node instance statement trigger?) instance statement silent)))))))

(define step-count 0)

(define-method (step (node <node>) (instance <runtime:instance>) (statement <statement>) silent)
  ;; (if (.location statement) (stderr "~a:~s:~s: STEP: ~a\n" (.file-name (.location statement)) (.line (.location statement)) (.column (.location statement)) (ast-name statement))
  ;;     (stderr "STEP: ~a\n" (ast-name statement)))
  ;;  (set! step-count (warn 'step: (1+ step-count)))

  (debug "\nstep ~a\n" statement)
  (if (.status node)
      (begin
        (debug "step: skipped\n")
        (list node))
      (let* ((statement (if (not (is-a? statement <trigger-return->)) statement
                            (clone statement #:expression (get-reply node instance) #:location (if (eq? ((compose .trigger get-frame) node) 'block) #f (.location ((compose .trigger get-frame) node))))))
             (node (record-step node instance statement)))
        (match statement
          (($ <illegal>) (list (set-status node (make <error> #:message "illegal" #:ast statement))))
          (($ <trigger-return>) (return node instance statement))
          (($ <trigger-out-return>) (return node instance statement))
          ((and ($ <action>) (? ast:async?))
           (call-async node instance statement))
          (($ <action>)
           (append-map (cut call <> instance statement) (run-silent-filtered node instance)))
          (($ <action-out>)
           (if silent (list (set-status node (make <no-match> #:ast statement #:input 'silent)))
               (append-map (cut call <> instance statement) (run-silent-filtered node instance))))
          (($ <block>) (block node instance))
          (($ <flush>) (flush node instance))
          ((and ($ <if>) (= .else #f))
           (if (true? (eval-expression (get-vars node instance) (.expression statement))) (step node instance (.then statement) silent)
               (list node)))
          (($ <if>) (if (true? (eval-expression (get-vars node instance) (.expression statement))) (step node instance (.then statement) silent)
                        (step node instance (.else statement) silent)))
          ((and (or (and ($ <assign>) (= .variable variable))
                    (and ($ <variable>) variable))
                (or (= .expression (? (is? <action>)))
                    (= .expression (? (is? <call>)))))
           (let ()
             (define (assign-re node)
               (pke 'assign-re 'status= (.status node))
               (if (.status node) node
                   (let* ((re (if (is-a? (.expression statement) <action>)
                                  (let* ((port (.port (.expression statement)))
                                         (runtime-port (runtime:port instance port))
                                         (other-runtime-port (runtime:other-port runtime-port))
                                         (other (if (runtime:boundary-port? other-runtime-port) other-runtime-port
                                                    (.container other-runtime-port))))
                                    (ast:rescope (get-reply node other) (instance-ast instance)))
                                  (get-return node instance)))
                          (e (pke "expression re:" (.expression re)))
                          (node (assign node instance (.name variable) e)))
                     (set-return node instance #f))))
             (map assign-re (step node instance (.expression statement) silent))))
          ((and ($ <assign>) (= .variable variable) (= .expression expression))
           (let* ((e (eval-expression (get-vars node instance) expression)))
             (list (assign node instance (.name variable) e))))
          ((and ($ <variable>) (= .name name) (= .expression expression))
           (let ((val (eval-expression (get-vars node instance) expression)))
             (list (assign node instance name val))))
          ((and ($ <reply>) (= .port.name #f))
           (let ((value (eval-expression (get-vars node instance) (.expression statement))))
             (list (set-reply node instance (clone statement #:expression value)))))
          ((and ($ <reply>) (= .port.name port-name))
           (let* ((value (eval-expression (get-vars node instance) (.expression statement)))
                  (node (set-reply node instance (clone statement #:expression value))))
             (release node instance (find (compose (cut eq? <> port-name) .name) ((compose ast:port* .type .instance) instance)))))
          ((and ($ <call>) (= .function func) (= ast:argument* args) (= .last? last))
           (let* ((formals (ast:formal* func))
                  (node (fold (cut push-variable <> <> <> instance) node formals args))
                  (nodes (map (cut pop-locals (length formals) <> instance) (step node instance (.statement func) silent))))
             (if (not (is-a? (ast:type func) <void>)) nodes
                 (map (cut set-return <> instance #f) nodes))))
          ((and ($ <return>) (= .expression #f))
           (list (set-return node instance (clone statement #:expression (make <literal> #:value 'void)))))
          ((and ($ <return>) (= .expression expression))
           (let ((value (eval-expression (get-vars node instance) (.expression statement))))
             (list (set-return node instance (clone statement #:expression value)))))
          ((and ($ <compound>) (= ast:statement* (statement* ...)))
           (let loop ((statement* statement*) (locals 0) (nodes (list node)))
             (if (null? statement*) (map (cut pop-locals locals <> instance) nodes)
                 (receive (exhausted nodes)
                     (partition (disjoin (cut get-return <> instance) (compose (is? <eot>) .status)) nodes)
                   (append
                    (map (cut pop-locals locals <> instance) exhausted)
                    (let* ((statement (car statement*))
                           (locals (if (is-a? statement <variable>) (1+ locals) locals))
                           (nodes (if (is-a? statement <variable>) (map (cut push-local statement <> instance) nodes)
                                      nodes)))
                      (loop (cdr statement*) locals (append-map (cut step <> instance statement silent) nodes))))))))))))

(define-method (flush (node <node>) (instance <runtime:instance>))    ; -> list of <node>
  (let loop ((node node))
    (if (null? (.q (get-state node instance))) (receive (node deferred)
                                                   (pop-deferred node instance)
                                                 (if (not deferred) (list node)
                                                     (if (get-handling? node deferred) (list node)
                                                         (flush node deferred))))
        (receive (node trigger)
            (dequeue node instance)
          (pke "trigger ~a; instance ~a\n" trigger instance)
          (debug "flush: start running\n")
          (append-map loop
                      (map pop-frame
                           (map (cut set-handling? <> instance #f)
                                (run (set-handling? (push-frame node instance (get-pc node) trigger) instance #t) instance trigger))))))))

(define-method (block (node <node>) (instance <runtime:component>))
  (let* ((trigger ((compose .trigger get-frame) node))
         (port ((compose .port .trigger get-frame) node))
         (foo (debug "dzn:block: port: ~a\n" (.name port)))
         (nodes (flush (set-handling? node instance #f) instance)))
    (define (run-coroutine node)
      (if (.release node) (list (clone node #:release #f))
          (simulate (push-frame (clone node #:block port) instance (get-pc node) 'block))))
    (append-map run-coroutine nodes)))

(define-method (release (node <node>) (instance <runtime:component>) (port <port>))
  (debug "dzn:release: port: ~a\n" (.name port))
  (let* ((node (if (.block node) (pop-frame (drop-next-trail (clone node #:block #f))) node))
         (node (clone node #:release #t))
         (nodes (flush node instance))
         (nodes (append-map run-async nodes)))
    nodes))

(define-method (call (node <node>) (instance <runtime:component>) (action <action>))
  (debug "CALL <component> <action> [~a]: ~a\n" instance action)
  (receive (other-instance other-port)
      (runtime:other-instance+port instance (runtime:port instance  (.port action)))
    (let ((trigger (action->trigger other-port action)))
      (match other-instance
        (($ <runtime:port>)
         (let ((input (get-next-trail node)))
           (cond ((eq? input null-symbol) (run-action node instance other-instance action trigger))
                 ((match? other-instance trigger input) (run-action (drop-next-trail node) instance other-instance action trigger))
                 (else (list (set-status node (make <no-match> #:ast trigger #:input input)))))))
        (($ <runtime:component>) (run-action node instance other-instance action trigger))))))

(define-method (ast:async? (o <action>))
  (symbol-prefix? 'dzn.async (symbol-join (ast:full-name (.type (.port o))) '.)))

(define-method (call-async (node <node>) (instance <runtime:component>) (action <action>))
  (list
   (case (.event.name action)
     ((req)
      (let* ((trigger (clone (make <trigger> #:port.name (.port.name action) #:event.name 'ack)
                             #:parent ((compose .type .instance) instance)))
             (ack (lambda (node) (run node instance trigger)))
             (rank (.rank instance)))
        (clone node #:async (acons rank (cons (.port action) ack) (.async node)))))
     ((clr)
      (clone node #:canceled (cons (.port action) (.canceled node))))
     (else (throw 'step "no such async trigger" action)))))

(define-method (call (node <node>) (instance <runtime:port>) (action <action-out>))
  (debug "CALL <port> <action-out>[~a]: ~a\n" instance action)
  (if (not (.event (.trigger (get-frame node)))) (list (drop-next-trail node)) ;; FIXME: blocking
      (receive (other-instance other-port)
          (runtime:other-instance+port instance)
        (let* ((trigger (action->trigger other-port action))
               (input (get-next-trail node))
               (match? (and (not (eq? input null-symbol)) (match? instance trigger input))))
          (debug "input=~a; match?=~a\n" input match?)
          (list (if (or match? (and %lts (eq? input null-symbol)))
                    (let ((node (if (or (%lts) (eq? input null-symbol)) node (drop-next-trail node))))
                      (if (runtime:provides-instance? instance) node
                          (enqueue (set-deferred node instance other-instance) other-instance trigger)))
                    (if (eq? input null-symbol)
                        (set-status node (make <eot> #:runtime-instance instance #:trigger trigger))
                        (set-status node (make <no-match> #:ast trigger #:input input)))))))))

(define-method (call (node <node>) (instance <runtime:component>) (action <action-out>))
  (debug "CALL <component> <action-out>[~a]: ~a\n" node action)
  (receive (other-instance other-port)
      (runtime:other-instance+port instance (runtime:port instance (.port action)))
    (let* ((trigger (action->trigger other-port action))
           (input (get-next-trail node)))
      (if (runtime:provides-instance? other-instance)
          (cond ((or (%lts) (match? other-port trigger input))
                 (let* ((node (if (%lts) (add-to-trail node (->symbol trigger)) node))
                        (nodes (append (run node other-instance (make <trigger> #:event.name 'optional) #f)
                                       (run node other-instance (make <trigger> #:event.name 'inevitable) #f))))
                   (receive (nodes solutions errors no-match inputs) (sort-nodes nodes)
                     (let ((nodes (append nodes solutions inputs))
                           (errors (append errors no-match))
                           (other-trigger (clone trigger #:port.name #f)))
                       (if (pair? nodes) (map (lambda (node) (record-step node other-instance other-trigger)) nodes)
                           (if (pair? errors) errors
                               (list (record-step (drop-next-trail node) other-instance other-trigger)))))))) ;;run-trigger compliance check??!!
                (else (list (set-status node (make <no-match> #:ast trigger #:input input)))))
          (list (enqueue (set-deferred node instance other-instance) other-instance trigger))))))

(define-method (run-action (node <node>) (instance <runtime:instance>) (other-instance <runtime:instance>) (action <action>) (trigger <trigger>))
  (debug "run-action: start running\n")
  (map (compose (cut record-return <> instance action) pop-frame)
       (run (push-frame node instance (get-pc node) trigger) other-instance trigger)))

(define-method (run-silent-filtered (node <node>) (instance <runtime:instance>))
  (if (.status node) node
      (filter (disjoin (compose (is? <eot>) .status) (negate .status)) (run-silent node instance))))

(define-method (run-silent (node <node>) (instance <runtime:component>))
  (debug "SILENT [~a]\n" instance)
  (list node))

(define-method (run-silent (node <node>) (instance <runtime:port>))
  (debug "RUN SILENT [~a]\n" instance)
  (if (.status node)
      (begin
        (debug "run-silent: skipped\n")
        (list node))
      (cons node
            (let ((optional (make <trigger> #:event.name 'optional))
                  (inevitable (make <trigger> #:event.name 'inevitable)))
              (debug "run-silent: start running (2x)\n")
              (map pop-frame
                   (append (run (push-frame node instance (get-pc node) optional) instance optional #t)
                           (run (push-frame node instance (get-pc node) inevitable) instance inevitable #t)))))))

(define-method (run-silent-boundary-filtered (node <node>) (instance <runtime:instance>))
  (if (.status node) node
      (filter (disjoin (compose (is? <eot>) .status) (negate .status)) (run-silent-boundary node instance))))

(define-method (run-silent-boundary (node <node>) (instance <runtime:port>))
  (debug "RUN SILENT BOUNDARY [~a]\n" instance)
  (if (.status node)
      (begin
        (debug "run-silent: skipped\n")
        (list node))
      (cons node
            (let ((optional (make <trigger> #:event.name 'optional))
                  (inevitable (make <trigger> #:event.name 'inevitable)))
              (debug "run-silent: start running (2x)\n")
              (append (run node instance optional #t)
                      (run node instance inevitable #t))))))

(define-method (return (node <node>) (instance <runtime:port>) (return <trigger-return->))
  (debug "RETURN <runtime:port> [~a]: ~a\n" instance return)
  (let* ((frame (get-frame node)))
    (list (if (or (eq? (.trigger frame) 'block) ;; FIXME: blocking
                  (ast:modeling? (.trigger frame))
                  (ast:out? (.trigger frame))) (pop-frame node) ;;TODO: PLZ remove if not required
                  (if (and (%lts)) (pop-frame node)
                      (let ((input (get-next-trail node)))
                        (cond ((and (eq? input null-symbol) (.expression return)) (set-status node (make <eot> #:runtime-instance instance #:trigger return)))
                              ((eq? input null-symbol) (pop-frame node))
                              ((match? instance return input) (pop-frame (drop-next-trail node)))
                              (else (set-status node (make <no-match> #:ast return #:input input))))))))))

(define-method (return (node <node>) (instance <runtime:component>) (return <trigger-return->))
  (debug "RETURN  <runtime:component> [~a]: ~a\n" instance return)
  (let ((frame (get-frame node)))
    (list (if (or (eq? (.trigger frame) 'block) ;; FIXME: blocking
                  (ast:modeling? (.trigger frame)) ;;TODO: PLZ remove if not required
                  (ast:out? (.trigger frame))) (pop-frame node)
                  (let* ((port (.port return))
                         (runtime-port (runtime:port instance port))
                         (other-port (runtime:other-port runtime-port))
                         (other-instance (if (runtime:boundary-port? other-port) other-port
                                             (.container other-port))))
                    (if (not (runtime:system-boundary? runtime-port)) (pop-frame node)
                        (let ((return (clone return #:port.name #f)))
                          (let ((input (get-next-trail node)))
                            (cond ((eq? input null-symbol) (pop-frame (record-step node other-instance return)))
                                  ((match? other-port return input) (pop-frame (record-step (drop-next-trail node) other-instance return)))
                                  (else (set-status node (make <no-match> #:ast return #:input input))))))))))))


(define-method (runtime:system-boundary? (o <runtime:port>))
  (or (runtime:boundary-port? o)
      (runtime:boundary-port? (runtime:other-port o))))

(define-method (input->list (o <symbol>))
  (map string->symbol (string-split (symbol->string o) #\.)))

(define-method (input->event (o <symbol>))
  (last (input->list o)))

(define-method (input->path (o <symbol>))
  (drop-right (input->list o) 1))

(define-method (match? (o <runtime:port>) (trigger <trigger>) (input <symbol>))
  (when (eq? input null-symbol) (pke  "END OF TRAIL " trigger))
  (match? o (.event.name trigger) input))

(define-method (match? (o <runtime:port>) (trigger <trigger-return->) (input <symbol>))
  (when (eq? input null-symbol) (pke  "END OF TRAIL " trigger))
  (or (eq? input null-symbol) (match? o (input->event (->symbol trigger)) input)))

(define-method (match? (o <runtime:port>) (event <symbol>) (input <symbol>))
  (let* ((input-event (input->event input))
         (input-path (input->path input))
         (path (runtime:instance->path o))
         (result (and (equal? path input-path)
                      (eq? event input-event))))
    (or result
        (and (debug "no match? ~a.~s ~s (input)\n" (string-join (map symbol->string path) ".") event input)
             #f))))

(define-method (record-return (node <node>) (instance <runtime:instance>) action)
  (if (is-a? (.status node) <eot>) node
      (let* ((step (last (.steps node)))
             (statement (cdr step))
             (statement (if (is-a? statement <illegal>) statement
                            (clone (clone statement #:port.name (.port.name action) #:location (.location action))
                                   #:parent action))))
        (record-step node instance statement))))

(define ((port-trigger? port) o)
  (or (eq? o 'illegal)
      (let ((p (get-port o))
            (i (get-instance o)))
        (and (not p) (eq? i port)))))

(define (get-instance o)
  (match (symbol-split o #\.)
   ((i p e) i)
   ((p e) p)
   (_ #f)))

(define (get-port o)
  (match (symbol-split o #\.)
   ((i p e) p)
   (_ #f)))

(define (non-matching-pair? a b)
  (and (not (eq? ((compose ->symbol cdr) a) ((compose last (cut symbol-split <> #\.) ->symbol cdr) b))) (cons a b)))

(define (port-node->boundary-trail node prefix-length)
  (let* ((trail (drop (steps->boundary-steps (.steps node)) prefix-length))
         (events (map (compose last (cut symbol-split <> #\.) ->symbol cdr) trail))
         (foo (debug "     port events         : ~a\n" events)))
    trail))

(define (node->boundary-trail node prefix-length port-name)
  (let* ((trail (drop (steps->boundary-steps (.steps node)) prefix-length))
         (foo (debug "     component boundary trail : ~a\n"  (map (compose ->symbol cdr) trail)))
         (trail (filter (compose (port-trigger? port-name) ->symbol cdr) trail))
         (foo (debug "     component provides trail : ~a\n" (map (compose ->symbol cdr) trail)))
         (events (map (compose last (cut symbol-split <> #\.) ->symbol cdr) trail))
         (foo (debug "     component events         : ~a\n" events)))
    trail))

(define-method (run-provides-in (node <node>))
  (debug "run-provides-in .trail node:~a\n" (.trail node))
  (debug "run-provides-in .status node:~a\n" (.status node))
  (let* ((sut-type (.type (.instance (%sut))))
         (port-trigger (clone (symbol->trigger (get-next-trail node)) #:parent sut-type))
         (node (drop-next-trail node)))
    (if (is-a? sut-type <interface>)
        (begin
          (debug "run-provides-in: start running interface\n")
          (map (cut record-state <> (%sut)) (run node (%sut) port-trigger)))
        (run-trigger node port-trigger))))

(define-method (run-trigger (node <node>) port-trigger)
  (debug "run-trigger .status node:~a\n" (.status node))
  (let* ((port-name (.port.name port-trigger))
         (port-instance (port-name->instance port-name))
         (port-trigger (clone port-trigger #:parent (.type (.instance port-instance))))

         (port-trail (filter (port-trigger? port-name) (.trail node)))
         (port-node (clone node #:trail port-trail))
         (port-prefix-length (length (steps->boundary-steps (.steps port-node))))

         (foo (debug "run-trigger: start running silent port-instance\n"))
         (port-nodes (run-silent-boundary-filtered port-node port-instance))

         (foo (debug "run-trigger: start running port-instance\n"))
         (port-nodes (append-map (cut run <> port-instance port-trigger) port-nodes))
         (foo (debug "-----------------------number of port nodes: ~a\n" (length port-nodes)))
         (port-nodes (filter (negate (compose (is? <no-match>) .status)) port-nodes))
         (foo (debug "             number of non-error port nodes: ~a\n" (length port-nodes)))

         (port (.instance port-instance))
         (runtime-port (runtime:port port-instance port))
         (component-port (runtime:other-port runtime-port))
         (component-instance (pke 'component-instance (if (runtime:boundary-port? component-port) component-port (.container component-port))))
         (model (.type (.instance component-instance)))
         (trigger (pke 'component-trigger (action->trigger component-port (pke 'port-trigger port-trigger))))
         (trigger (clone trigger #:parent model))

         (node (record-step node port-instance (clone port-trigger #:port.name #f)))
         (prefix-length (length (steps->boundary-steps (.steps node)))))

    (define (first-non-match port-node node)
      (let ((port-trail (port-node->boundary-trail port-node port-prefix-length))
            (trail (node->boundary-trail node prefix-length (.port.name trigger))))
        (any non-matching-pair? port-trail trail))) ;;TODO what about (.status node) and (.status port-node) => assuming non-det illegal which is not on the trail

    (define  (match-length port-node node)
      (let* ((port-trail (port-node->boundary-trail port-node port-prefix-length))
             (trail (node->boundary-trail node prefix-length (.port.name trigger)))
             (fail-index (list-index non-matching-pair? port-trail trail)))
        (or fail-index (length trail))))

    (define (compliance-error node port-nodes)
      (let* ((sorted-port-nodes (sort port-nodes (lambda (a b)
                                                   (> (match-length a node)
                                                      (match-length b node)))))
             (best-length (if (null? sorted-port-nodes) 0
                              (match-length (car sorted-port-nodes) node))))
        (receive (best rest)
            (partition (lambda (a) (= (match-length a node) best-length)) sorted-port-nodes)
          (let ((non-compliances (map (cut first-non-match <> node) best)))
            (if (null? non-compliances)
                (begin
                  (debug "UNKNOWN COMPLIANCE ERROR!:\n")
                  (list (set-status node (make <compliance-error> #:message "compliance" #:component-acceptance (cddr (first-non-match node node)) #:port-acceptance (make <acceptances> #:elements '())))))
                (begin
                  (debug "COMPLIANCE ERROR!: port:~a\n" (map cdar non-compliances))
                  (debug "              component:~a\n" (cddar non-compliances))
                  (list (set-status node (make <compliance-error> #:message "compliance" #:component-acceptance (cddar non-compliances) #:port-acceptance (make <acceptances> #:elements (map cdar non-compliances)))))))))))

    (let* ((foo (debug "run-provides-in: start running component-instance\n"))
           (nodes (run node component-instance trigger))
           (nodes (append-map run-async nodes))
           (foo (debug "-----------------------number of comp nodes: ~a\n" (length nodes)))
           (nodes (append-map
                   (lambda (node)
                     (let ((matching-port-nodes (filter (lambda (port-node) (not (first-non-match port-node node))) port-nodes)))
                       (cond ((pair? matching-port-nodes)
                              (map (lambda (matching-port-node) (set-state node port-instance (get-state matching-port-node port-instance))) matching-port-nodes))
                             ((is-a? (.status node) <error>) (list node))
                             (else (compliance-error node port-nodes)))))
                   nodes))
           (nodes (map (cut record-state <> component-instance) nodes)))
      nodes)))

(define-method (run-async (node <node>))
  (let ((timers (.async node)))
    (if (or (.status node) (null? timers)) (list node)
        (let* ((deadline (apply min (map car timers)))
               (x-e (assoc-ref (reverse timers) deadline))
               (e (cdr x-e))
               (timers (filter (negate (compose (cut equal? <> x-e) cdr)) timers))
               (node (clone node #:async timers)))
          (if (find (cut eq? <> (car x-e)) (.canceled node))
              (list (clone node #:canceled (filter (negate (cut eq? <> (car x-e))) (.canceled node))))
              (append-map run-async (e node)))))))

(define-method (status-equal? a b)
  (and (not a) (not b)))

(define-method (status-equal? (a <status>) (b <status>))
  #f)

(define-method (status-equal? (a <compliance-error>) (b <compliance-error>))
  #f) ;; FIXME: are you sure #f is OK??

(define-method (status-equal? (a <no-match>) (b <no-match>))
  (eq? (.input a) (.input b)))

(define-method (status-equal? (a <eot>) (b <eot>))
  (and (eq? (.runtime-instance a) (.runtime-instance b)) ;; FIXME: 'eq?' good enough?
       (ast:eq? (.trigger a) (.trigger b))))

(define-method (node-equal? (a <node>) (b <node>))
  (and (eq? (length (.trail a)) (length (.trail b)))
       (status-equal? (.status a) (.status b))
       (let ((instances (filter (disjoin runtime:boundary-port? runtime:component-instance?) (%instances))))
         (vertex-equal? (node->vertex a instances) (node->vertex b instances)))))

;; silent:
;; -- voor fire-tau: silent met zwakke pre-conditie
;; -- voor provides-in

(define-method (run-requires-out (node <node>))
  "Add silent non-determinism, and run requires-out."
  (define (fire-tau node optional inevitable instance)
    (if (.status node) (list node)
        ;;SI5
        (let* ((foo (debug "run-requires-out: fire-tau: start running silent\n"))
               (nodes (run-silent-boundary-filtered node instance)))
          (debug "run-requires-out: fire-tau: start running optional and inevitable\n")
          (debug "run-requires-out: nodes after run-silent-boundary-filtered: ~a\n" (length nodes))
          (append (append-map (cut run <> instance optional) nodes)
                  (append-map (cut run <> instance inevitable) nodes)))))
  (debug "run-requires-out\n")
  (let* ((optional (make <trigger> #:event.name 'optional))
         (inevitable (make <trigger> #:event.name 'inevitable))
         (requires-instances (filter runtime:requires-instance? (%instances))))
    (let loop ((nodes (list node)) (result '()))
      (when (any .status nodes) (throw 'invariant "status set for a node")) ;; FIXME: also throw when <eot> ??
      (debug "loop2\n")
      (debug "loop2 nodes=~a\n" (length nodes))
      (debug "loop2 result=~a\n" (length result))
      (if (null? nodes) result
          (let* ((node (car nodes))
                 (result1 (append-map (cut fire-tau node optional inevitable <>) requires-instances))
                 (result1 (map (cut record-state <> (%sut)) result1)))
            (receive (work solutions errors no-match inputs)
                (sort-nodes result1)
              (let* ((work (append work (cdr nodes)))
                     (nodes (if (null? (lset-difference node-equal? work nodes)) '()
                                work)))
                (loop nodes (cons node (append result solutions errors no-match inputs))))))))))

(define (provides-trigger-on-trail? node)
  (let ((trigger (symbol->trigger (get-next-trail node))))
    (if (is-a? (.type (.instance (%sut))) <interface>)
        (memq (.event.name trigger) (map .name (filter ast:in? (ast:event* (.type (.instance (%sut)))))))
     (let* ((port (.port.name trigger))
            (provides-ports (map .name (filter ast:provides? (runtime:port* (%sut))))))
       (memq port provides-ports)))))

(define (record-ls-eligible node)
  (record-step node (%sut) (cons 'eligible (map trigger->symbol (ast:in-triggers (.type (.instance (%sut))))))))

(define-method (simulate (o <node>))    ; -> list of <node>
  (let loop ((work (list o)) (solutions '()))
    (let* ((foo (debug "simulate:loop start run-requires-out (work length=~a)\n" (length work)))
           (nodes (append-map run-requires-out work)))
      (receive (nodes solutions errors no-match inputs)
          (sort-nodes (append nodes solutions))
        (or (done? nodes solutions errors no-match inputs)
            (receive (provides nodes)
                (partition provides-trigger-on-trail? nodes)
              (let ((foo (debug "simulate:loop start run-provides-in (work length=~a)\n" (length provides)))
                    (provides (append-map run-provides-in provides)))
                (receive (nodes solutions errors no-match inputs)
                    (sort-nodes (append provides nodes solutions errors no-match inputs))
                  (let ((nodes (lset-difference node-equal? nodes work)))
                    (or (done? nodes solutions errors no-match inputs)
                        (loop nodes solutions)))))))))))

(define (sort-nodes nodes)
  (receive (inputs nodes)
      (partition (compose (is? <eot>) .status) nodes)
    (receive (no-match nodes)
        (partition (compose (is? <no-match>) .status) nodes)
      (receive (errors nodes)
          (partition (compose (is? <error>) .status) nodes)
        (receive (solutions nodes)
            (partition (compose null? .trail) nodes)
          (values nodes solutions errors no-match inputs))))))

(define (done? nodes solutions errors no-match inputs)
  (let* ((done? (or (pair? errors) (null? nodes)))
         (done? (and done? (append errors solutions inputs)))
         (done? (and done? (if (pair? done?) done?
                               no-match))))
    (and done? (delete-duplicates done? node-equal?))))

(define-method (port-name->instance (o <symbol>))
  (find (compose (cut eq? o <>) .name .instance)
        (filter runtime:boundary-port? (%instances))))

(define-method (.port.name <illegal>) #f)

(define (state-step? step)
  (let ((instance (car step))
        (info (cdr step)))
    (pair? info)))

(define (eligible-step? step)
  (let ((instance (car step))
        (info (cdr step)))
    (and (is-a? instance <runtime:instance>)
         (pair? info)
         (eq? (car info) 'eligible))))

(define ((trigger-step? out) step)
  (let ((instance (car step))
        (statement (cdr step)))
    (and  instance
         (match statement
           ((and ($ <trigger>) (= .event.name 'error)) #t)
           ((and ($ <trigger>) (= .event.name (? empty-symbol?))) #f) ;; FIXME
           ((and ($ <trigger>) (= .event.name (? (cut member <> '(optional inevitable))))) #f)
           (($ <trigger>) #t)
           (($ <trigger-return>) #t)
           (($ <action-out>) (or out (not (and (runtime:boundary-port? instance)
                                               (runtime:provides-instance? instance)))))
           (($ <action>) #t)
           (($ <q-in>) #t)
           (($ <q-out>) #t)
           (($ <q-trigger>) #t)
           (_ #f)))))

(define (side->string o)
  (let ((instance (car o))
        (statement (cdr o)))
    (format #f "~a.~a"
            (runtime:instance->string instance)
            (->string statement))))

(define* (print-trace node #:optional count debug?)
  (let ((steps (.steps node))
        ;;(foo (stderr "---------------------------------------------\n"))
        (verbose? (gdzn:command-line:get 'verbose #f))
        (debug? (gdzn:command-line:get 'debug #f))
        (locations? (or debug? (command-line:get 'locations #f))))

    (when debug?
      (stderr "STEPS:\n")
      (pretty-print (om->list steps) (current-error-port)))

    (let ((status (.status node)))
      (match status
        (($ <compliance-error>)
         (let* ((component-acceptance (.component-acceptance status))
                (location (step->location component-acceptance)))
           (stderr "~aerror:non-compliance\n" location)))
        ((and ($ <error>) (= .ast ast) (= .message message))
         (let ((location (step->location ast)))
           (stderr "~aerror:~a\n" location message)))
        (($ <eot>) #f)
        (#f #f)
        (_ (stderr "ERROR:~a\n" status))))

    (when (> count 0)
      (stdout "code trail[~a]:\n" count))

    (let loop ((steps steps) (first? #f))
      (when (pair? steps)
        (let ((step (car steps)))
          (let* ((trigger-step? ((trigger-step? #f) step))
                 (first? (if trigger-step? (not first?) first?)))
            (cond ((eligible-step? step)
                   (let ((info (cdr step)))
                     (display info)
                     (newline)))
                  ((state-step? step)
                   (let ((info (cdr step)))
                     (display (instance-state->sexp-state info))
                     (newline)))
                  ((not trigger-step?)
                   (when (and locations? verbose?)
                     (let ((location (if locations? (or (step->location (cdr step))
                                                        "foo.dzn:1:0:")
                                         "")))
                       (stdout "~a~a\n" location (side->string step)))))
                  (else (let* ((statement (cdr step))
                               (swap? (or (is-a? statement <trigger-return>)
                                          (is-a? statement <action-out>)
                                          (and (is-a? statement <trigger>) (runtime:boundary-port? (car step)) (ast:out? (.event statement)))
                                          (is-a? statement <q-in>)
                                          (is-a? statement <q-out>)
                                          (is-a? statement <q-trigger>)
                                          ))
                               (location (if locations? (or (step->location statement)
                                                            "foo.dzn:1:0:")
                                             ""))
                               (arrow (if swap? " <- " " -> "))
                               (other-side (if (is-a? (.type (.instance (%sut))) <interface>) (symbol->string (->symbol statement))
                                               "..."))
                               (left-string (if (eq? first? swap?) other-side (side->string step)))
                               (right-string (if (eq? first? swap?) (side->string step) other-side)))
                          (stdout (string-append location left-string arrow right-string "\n")))))
            (loop (cdr steps) first?)))))

    (let ((status (.status node)))
      (match status
        (($ <compliance-error>)
         (let* ((component-acceptance (.component-acceptance status))
                (location (step->location component-acceptance)))
           (stderr "~acomponent accept: ~a\n" location (->symbol component-acceptance))
           (for-each
            (lambda (ast)
              (let ((location (step->location ast)))
                (stderr "~a     port accept: ~a\n" location (->symbol ast))))
            (ast:acceptance* status))))
        ((and ($ <error>) (= .message message))
         (stdout "~a\n" message))
        (($ <eot>)
         (stderr "end of trail. stopping here: ~a.~a\n" (runtime:instance->string (.runtime-instance status)) (->symbol (.trigger status))))
        (#f #f)
        (_ (stderr "ERROR:~a\n" status))))))

(define (empty-symbol? o)
  (string-null? (symbol->string o)))

(define (steps->trail steps out)
  (filter (trigger-step? out) steps))

(define-method (value->sexp (o <top>))
  o)
(define-method (value->sexp (o <enum-literal>))
  (->symbol o))
(define-method (value->sexp (o <literal>))
  (if (number? (.value o)) (.value o)
      (->symbol o)))

(define-method (sexp->value v)
  (match v
    ('true (make <literal> #:value 'true))
    ('false (make <literal> #:value 'false))
    ((? number?) (make <literal> #:value v))
    (_ (let* ((enum (symbol-split v #\_))
              (type.name (car enum))
              (field (cadr enum)))
         (make <enum-literal> #:type.name (make <scope.name> #:name type.name) #:field field))) ;; FIXME: what about resolving
    ))

(define (variable->sexp pair)
    (cons (car pair) (value->sexp (cdr pair))))

(define (instance-state->sexp-state a-list)
  (map (lambda (o)
         (let* ((instance-state (assoc o a-list eq?))
                (model (.type (.instance o)))
                (state (map variable->sexp (.vars (cdr instance-state))))
                (path (runtime:instance->path o))
                (path (cond ((and (runtime:boundary-port? o)
                                  (runtime:foreign-instance? (.container o))) path)
                            ((and (runtime:boundary-port? o) (null? path)) '(sut))
                            ((runtime:boundary-port? o) (car path))
                            (else path)))
                (kind (runtime:kind o)))
           (cons path (cons (.name (.name model)) (cons kind state)))))
       (filter (lambda (i)
                 (or (runtime:boundary-port? i)
                     (not (is-a? i <runtime:port>))))
               (%instances))))

(define* (get-initial-state #:optional input-trail)
  (define (instance-path+state-alist->runtime:instance+state-alist o)
    (let* ((instance-path (car o))
           (state-alist (cdr o))
           (state-alist (map (lambda (s) (cons (car s) (sexp->value (cdr s)))) state-alist)))
      (cons (runtime:path->instance instance-path) state-alist)))
  (define (sexp-instance+type+kind+state->instance-path+state-alist o)
    (let* ((instance (car o))
           (instance-path (if (symbol? instance) (list instance) instance))
           (state-alist (cdddr o)))
      (cons instance-path state-alist)))
  (let* ((initial-state (fold create-initial-state '() (%instances)))
         (state-from-trail (or (and (pair? input-trail) (pair? (car input-trail)) (car input-trail)) '()))
         (state-from-trail (map sexp-instance+type+kind+state->instance-path+state-alist state-from-trail))
         (state-from-trail (map instance-path+state-alist->runtime:instance+state-alist state-from-trail))
         (state-from-trail (filter car state-from-trail))
         ;; FIXME: MUST assoc using path; goops duplicate instances?
         (state-from-trail (map (lambda (x) (cons (runtime:instance->path (car x)) (cdr x))) state-from-trail)))
    (map (lambda (instance+state)
           (let* ((instance (car instance+state))
                  (instance-path (runtime:instance->path instance))
                  (state (cdr instance+state)))
             ;; FIXME: assoc instance-path
             ;; (or (warn 'found=> (assoc instance state-from-trail))
             ;;     instance+state)
             (cons instance (or (assoc-ref state-from-trail instance-path) state))))
         initial-state)))

(define (read-input-file)
  (define (helper x)
    (if (eof-object? x) '()
        (cons x (helper (read)))))
  (helper (read)))

(define (string->trail o)
  (with-input-from-string (string-join (string-split o #\,) " ") read-input-file))

(define* (get-input-trail)
  (let* ((trail (or (command-line:get 'trail)
                    (read-string))))
    (if (string-prefix? "[{" trail) (json->trail trail)
        (string->trail trail))))

(define* (setup-debug-printing! #:optional (debug? (gdzn:command-line:get 'debug #f)))
  (when (not debug?)
    (set! debug debug-disable)
    (set! debug-pretty debug-disable)
    (set! pke debug-disable)))

(define* (create-initial-node #:optional input-trail)
  (let* ((initial-state (get-initial-state input-trail))
         (node (make-initial-node (%instances) initial-state))
         (node (record-state node (%sut)))
         (input-trail (filter (negate pair?) input-trail)))
    (clone node #:trail input-trail)))

(define (step:ast-> root)
  (debug-disable 'backtrace)
  (setup-debug-printing!)
  (let* ((root (step:normalize root))
         (sut (runtime:get-sut root)))
    ;; (debug-pretty (om->list root))
    (parameterize ((%sut sut))
      (parameterize ((%instances (runtime:get-system-instances sut)))
        ;;        (debug "instances:\n")
        ;;        (debug-pretty (om->list (%instances)))
        (let* ((input-trail (get-input-trail))
               (node (if (is-a? input-trail <step:transition-list>) (json:create-initial-node input-trail)
                         (create-initial-node input-trail)))
               (nodes (if (null? (.trail node)) (list node) ;; FIXME: -t '' => initial state only
                          (simulate node)))
               (nodes (map record-ls-eligible nodes)))
          (if (gdzn:command-line:get 'json) (json:print-trace nodes)
              (map print-trace nodes (iota (length nodes))))))))
  "")

(define ast-> step:ast->)
