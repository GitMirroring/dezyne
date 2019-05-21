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

;; nondet: done
;; trace reconstruction: done
;; refactor: use records
;; [refactor: fold blaat into microstep]: done
;; multiple components: done
;; queue (missing flush): done, except valued return, multiple queues,
;; async calls: done.
;; replace ast with gaiag ast: done
;; replace <node> with goops: done
;; system abstraction (aka plumbing): done
;; runtime semantics: done
;; gdzn interface: done
;; testing: done
;; all trails: matching of external triggers and returns + discard: done
;; .parent: done
;; required ports (interfaces): done
;; member variables & expressions: done
;; full trail matching (eg internal events): --strict done
;; sparse trail: kwartjes only (default: --strict off): done
;; local variables: done
;; provided port (interface): compliance check, including illegals: done
;; instance encoding/plumbing: finish interface, remove plumbing work on AST?: done
;; functions: done
;; eval-expression: return <literal> i.s.o. raw values
;; lts
;; foreign component
;; single interface simulation

;; remove shortcuts, refactor mercilessly

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
  #:use-module (system foreign)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (json)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag evaluate)
  #:use-module (gaiag ast)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag command-line)
  #:use-module (gaiag runtime)
  #:use-module (gaiag normalize)

  #:use-module (gaiag commands parse)

  #:use-module (gaiag step-serialize)
  #:use-module (gaiag serialize)

  #:export (step:ast-> dot go lts->))

(define debug-pretty pretty-print)
(define debug stderr)
(define (debug-disable . _) (last _))

(define (ast-> ast)
  (step:ast-> ast)
  "")

(define (step:ast-> ast)
  (let ((root (step:om ast)))
    ;;(debug-pretty (om->list root))
    (step:root-> root)))

(define (step:om ast)
  ((compose
    step:transform
    purge-data)
   ast))


(define-class <step> ())
(define-method (clone (o <step>) . setters)
  (apply clone-base (cons o setters)))

(define-class <step:end-point> (<step>)
  (instance #:getter .instance #:init-form #f #:init-keyword #:instance)
  (port #:getter .port #:init-form #f #:init-keyword #:port))

(define-class <state> (<step>)
  (deferred #:getter .deferred #:init-form #f #:init-keyword #:deferred)
  (handling? #:getter .handling? #:init-form #f #:init-keyword #:handling?)
  (reply #:getter .reply #:init-form #f #:init-keyword #:reply)
  (return #:getter .return #:init-form #f #:init-keyword #:return)
  (q #:getter .q #:init-form (list) #:init-keyword #:q)
  (vars #:getter .vars #:init-form (list) #:init-keyword #:vars)) ; alist of scoped var name and value

(define-class <node> (<step>)
  (stack #:getter .stack #:init-form (list) #:init-keyword #:stack) ; <frame>
  (state-alist #:getter .state-alist #:init-form (list) #:init-keyword #:state-alist) ; '((sut b) . <state>) (sut c) . <state>))
  (steps #:getter .steps #:init-form (list) #:init-keyword #:steps)
  (trail #:getter .trail #:init-form (list) #:init-keyword #:trail)
  (status #:getter .status #:init-value #f #:init-keyword #:status))

(define-method (set-status (node <node>) (status <status>))
  (clone node #:status status))

(define-class <frame> (<step>)
  (pc #:getter .pc #:init-form (list) #:init-keyword #:pc) ; <behaviour>, <statement>
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance) ; '(sut b)
  (trigger #:getter .trigger #:init-value #f #:init-keyword #:trigger)) ; <trigger>

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; transform

(define (step:transform root)
  ((compose
    transform-return
    (transform-action)
    (annotate-otherwise)
    ) root))

(define* ((annotate-otherwise #:optional (statements '())) o) ;; FIXME *unspecified*
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*)))
  (match o
    ((and ($ <guard>) (= .expression (and ($ <otherwise>) (= .value value)))) (=> failure)
     (if (or (not (virgin-otherwise? value)) (null? statements)) (failure)
         (clone o #:expression ((annotate-otherwise statements) (.expression o)))))
    (($ <otherwise>)
     (or (let* ((guards (filter (is? <guard>) statements))
                (value (guards-not-or guards)))
           (and value (clone o #:value value)))
         o))
    ((and ($ <compound>) (= .elements (statements ...)))
     (clone o #:elements (map (annotate-otherwise statements) statements)))
    (($ <skip>) o)
    ((? (is? <ast>)) (tree-map (annotate-otherwise statements) o))
    (_ o)))

(define (guards-not-or o)
  (let* ((expressions (map .expression o))
         (others (remove (is? <otherwise>) expressions))
         (expression (reduce (lambda (g0 g1)
                               (if (ast:equal? g0 g1) g0 (make <or> #:left g0 #:right g1)))
                             '() others)))
    (match expression
      ((and ($ <not>) (= .expression expression)) expression)
      (_ (make <not> #:expression expression)))))

(define* ((transform-action #:optional model) o)
  (define (component? x) (is-a? model <component>))

  (define (system-port-event? trigger)
    ;; instance-path
    ;; port-name

    (and (ast:provides? (.port trigger))
         (ast:out? (.event trigger))))

  (define (add-flush o f)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (clone o #:elements (append (ast:statement* o) (list f))))
      ((? ast:imperative?)
       (make <compound> #:elements (list o f) #:location (.location o)))
      (($ <compound>)
       (clone o #:elements (map (cut add-flush <> f) (ast:statement* o))))
      (($ <guard>) (clone o #:statement (add-flush (.statement o) f)))))

  (match o
    ((and ($ <on>) (= ast:trigger* triggers) (= .statement statement))
     (let* ((statement ((transform-action model) statement))
            (action-out? (tree-collect (is? <action-out>) statement))
            (action? (tree-collect (lambda (o) (or (and (is-a? o <action>)
                                                        (not (is-a? o <action-out>)))
                                                   (match o ((and ($ <variable>) (= .expression ($ <action>))) #t) (_ #f)))) statement))
            (trigger (car triggers))
            (action-trigger (tree-collect (is? <action>) statement))
            ;; (event (om:event model trigger))
            ;; (typed? (om:typed? event))
            (typed? #t)
            (port-name (and (pair? action?) (let ((o (car action?)))
                                              (match o
                                                (($ <action>) (.port.name o))
                                                (($ <variable>) ((compose .port.name .expression) o))))))
            (statement (if (or (and (null? action?)
                                    (null? action-out?))) statement
                                    (add-flush statement (clone (make <flush> #:location (.location o)) #:parent statement)))))
       (clone o #:statement statement)))

    ((and ($ <action>) (? component?) (? system-port-event?))
     (clone (make <action-out> #:port.name (.port.name o) #:event.name (.event.name o) #:arguments (.arguments o) #:location (.location o)) #:parent o))

    ((and ($ <action>) (? (negate component?)))
     (clone (make <action-out> #:event.name (.event.name o) #:arguments (.arguments o) #:location (.location o)) #:parent o))

    (($ <interface>)
     (clone o #:behaviour ((transform-action o) (.behaviour o))))

    (($ <component>)
     (clone o #:behaviour ((transform-action o) (.behaviour o))))

    ((? (is? <ast>)) (tree-map (transform-action model) o))
    (_ o)))

(define (transform-return o)
  (define (add-return o r)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (clone o #:elements (append (ast:statement* o) (list r))))
      ((? ast:imperative?)
       (make <compound> #:elements (list o r) #:location (.location o)))
      (($ <compound>)
       (clone o #:elements (map (cut add-return <> r) (ast:statement* o))))
      (($ <guard>) (clone o #:statement (add-return (.statement o) r)))))

  (match o
    (($ <on>)
     (let* ((trigger ((compose car ast:trigger*) o))
            (statement (add-return (.statement o) (clone (make (if (or (ast:out? (.event trigger))
                                                                       (is-a? (.event trigger) <modeling-event>)) <trigger-out-return> <trigger-return>) #:port.name (.port.name trigger) #:location (.location o)) #:parent (.statement o)))))
       (clone o #:statement statement)))

    (($ <behaviour>)
     (clone o #:statement (transform-return (.statement o))))

    (($ <interface>)
     (clone o #:behaviour (transform-return (.behaviour o))))

    (($ <component>)
     (clone o #:behaviour (transform-return (.behaviour o))))

    ((? (is? <ast>)) (tree-map transform-return o))
    (_ o)))

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

(define (step->tracepoint o)
  (let* ((debug? (gdzn:command-line:get 'debug #f))
         (statement (cdr o))
         (statement (format #f "~a" (if (or debug? (pair? statement)) statement ((compose symbol->string ast-name) statement)))))
    (string-append
     (or (and=> (step->location (cdr o)) (cut string-append <> (runtime:instance->string (car o)) ": "))
         "")
     statement)))

;; transform
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
             (let ((runtime-port (runtime:port (pke 'instance instance) (pke 'port (.port statement)))))
               (let ((other-runtime-port (runtime:other-port runtime-port)))
                 (runtime:boundary-port? other-runtime-port)))))))

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

(define skip-count 0)

(define-method (skip (node <node>) (instance <runtime:instance>) (action <action-out>))
  ;;  (set! skip-count (warn 'skip: (1+ skip-count)))
  (let* ((port (.port action))
         (runtime-port (runtime:port instance port))
         (other-instance (runtime:other-port runtime-port))
         (node (record-step node other-instance (make <action-out> #:event.name (.event.name action)))))
    (list node)))

(define-method (skip (node <node>) (instance <runtime:instance>) (action <action>))
;;  (set! skip-count (warn 'skip: (1+ skip-count)))
  (let* ((port (.port action))
         (runtime-port (runtime:port instance port))
         (other-instance (runtime:other-port runtime-port))

         (return-values (ast:return-values (.event action)))
         (return-values (if (null? return-values) (list (make <literal>)) return-values))
         (replies (map (compose (cut clone <> #:parent (.type (.instance other-instance)))
                                (cut make <reply> #:expression <>)) return-values))
         (node (record-step node other-instance (make <trigger> #:event.name (.event.name action)))))
    (map (lambda (reply) (record-step (set-reply node other-instance reply) other-instance reply)) replies)))

(define walk-count 0)

(define-method (walk (node <node>) (instance <runtime:instance>) (trigger <trigger>) (statement <statement>) trigger? silent)
  ;; (if (.location statement) (stderr "~a:~s:~s: WALK: ~a ~a\n" (.file-name (.location statement)) (.line (.location statement)) (.column (.location statement)) (->symbol trigger) (ast-name statement))
  ;;     (stderr "WALK: ~a ~a\n" (->symbol trigger) (ast-name statement)))
;;  (set! walk-count (warn 'walk: (1+ walk-count)))
  (debug "walk: statement:~a\n" statement)
  (match statement
    ((and ($ <compound>) (? ast:declarative?) (= ast:statement* statements))
     (append-map (cut walk node instance trigger <> trigger? silent) statements))
    (($ <guard>) (if (not (true? (eval-expression (get-vars node instance) (.expression statement)))) '()
                     (walk node instance trigger (.statement statement) trigger? silent)))
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
                            (clone statement #:expression (get-reply node instance) #:location (.location ((compose .trigger get-frame) node)))))
             (node (record-step node instance statement)))
        (match statement
          (($ <illegal>) (list (set-status node (make <error> #:message "illegal" #:ast statement))))
          (($ <trigger-return>) (return node instance statement))
          (($ <trigger-out-return>) (return node instance statement))
          (($ <action>)
           (append-map (cut call <> instance statement) (run-silent-filtered node instance)))
          (($ <action-out>)
           (if silent (list (set-status node (make <no-match> #:ast statement #:input 'silent)))
               (append-map (cut call <> instance statement) (run-silent-filtered node instance))))
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
          (($ <reply>) (let ((value (eval-expression (get-vars node instance) (.expression statement))))
                         (list (set-reply node instance (clone statement #:expression value)))))
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

(define-method (call (node <node>) (instance <runtime:component>) (action <action>))
  (debug "CALL <component> <action> [~a]: ~a\n" instance action)
  (receive (other-instance other-port)
      (runtime:other-instance+port instance (runtime:port instance (.port action)))
    (if (and #f (%lts) (runtime:boundary-port? other-instance)) (skip node instance action)
        (let ((trigger (action->trigger other-port action)))
          (match other-instance
            (($ <runtime:port>)
             (let ((input (get-next-trail node)))
               (cond ((eq? input null-symbol) (run-action node instance other-instance action trigger))
                     ((match? other-instance trigger input) (run-action (drop-next-trail node) instance other-instance action trigger))
                     (else (list (set-status node (make <no-match> #:ast trigger #:input input)))))))
            (($ <runtime:component>) (run-action node instance other-instance action trigger)))))))

(define-method (call (node <node>) (instance <runtime:port>) (action <action-out>))
  (debug "CALL <port> <action-out>[~a]: ~a\n" instance action)
  (receive (other-instance other-port)
      (runtime:other-instance+port instance)
    (if (and #f (%lts) (runtime:boundary-port? other-instance)) (skip node instance action)
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
    (if (and #f (%lts) (runtime:boundary-port? other-instance)) (skip node instance action)
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
              (list (enqueue (set-deferred node instance other-instance) other-instance trigger)))))))

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
    (list (if (or (ast:modeling? (.trigger frame))
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
    (list (if (or (ast:modeling? (.trigger frame)) ;;TODO: PLZ remove if not required
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
                  (list (set-status node (make <compliance-error> #:message "compliance"))))
                (begin
                  (debug "COMPLIANCE ERROR!: port:~a\n" (map cdar non-compliances))
                  (debug "              component:~a\n" (cddar non-compliances))
                  (list (set-status node (make <compliance-error> #:message "compliance" #:component-acceptance (cddar non-compliances) #:port-acceptance (make <acceptances> #:elements (map cdar non-compliances)))))))))))

    (let* ((foo (debug "run-provides-in: start running component-instance\n"))
           (nodes (run node component-instance trigger))
           (foo (debug "-----------------------number of comp nodes: ~a\n" (length nodes)))
           (nodes (append-map
                   (lambda (node)
                     (let ((matching-port-nodes (filter (lambda (port-node) (not (first-non-match port-node node))) port-nodes)))
                       (cond ((pair? matching-port-nodes)
                              (map (lambda (matching-port-node) (set-state node port-instance (get-state matching-port-node port-instance))) matching-port-nodes))
                             ((is-a? (.status node) <error>) (list node))
                             (else (compliance-error node port-nodes)))))
                   nodes)))
      (map (cut record-state <> component-instance) nodes))))

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

(define-class <vertex> (<step>)
  (state #:getter .state #:init-form (list) #:init-keyword #:state))

(define-class <edge> (<step>)
  (from #:getter .from #:init-value #f #:init-keyword #:from)
  (to #:getter .to #:init-value #f #:init-keyword #:to)
  (label #:getter .label #:init-value #f  #:init-keyword #:label))

(define-method (vertex->node (o <vertex>))
  (let ((node (json:create-initial-node (make <step:transition-list>))))
    (fold (lambda (i n)
            (set-state n i (make <state> #:vars (assoc-ref (.state o) i))))
          node
          (filter (disjoin runtime:boundary-port? runtime:component-instance?) (%instances)))))

(define-method (vertex-equal? (a <vertex>) (b <vertex>))
  (equal? (vertex->string a) (vertex->string b)))

(define-method (node->vertex (o <node>) instances)
  (make <vertex> #:state
        (map (lambda (i)
               (cons i (.vars (assoc-ref (.state-alist o) i))))
             instances)))

(define (go edges)
  (define (->string instances-state)
    (scm->json-string
     (map (lambda (instance-state)
            (cons (string->symbol
                   (string-join (map (compose symbol->string .name .instance)
                                     (reverse (runtime:container-path (car instance-state)))) "."))
                  (map (lambda (s)
		         (cons (car s) (->symbol (cdr s))))
                       (cdr instance-state))))
          instances-state)))

  (let* ((edges ((compose (if (command-line:get 'remove-duplicate-transitions) remove-duplicates identity)
                          (if (command-line:get 'remove-self-transitions) remove-self identity)
                          (remove-vars (map string->symbol (string-split (command-line:get 'remove-vars "") #\space))))
                 edges))
	 (vertices (delete-duplicates (append (map .from edges) (map .to edges)) vertex-equal?))
	 (vertex-strings (map (compose ->string .state) vertices)))
    (define (id vertex)
      (number->string (list-index (cute equal? (->string (.state vertex)) <>) vertex-strings)))
    (define (vertex->string vertex)
      (string-append "{\"id\": \""
                     (id vertex)
                     "\", \"text\": \"\", \"state\": "
                     (->string (.state vertex))
                     "}\n"))
    (define (edge->string edge)
      (string-append "{\"from\": \""
                     (id (.from edge))
                     "\", \"to\": \""
                     (id (.to edge))
                     "\", \"text\": \""
                     (string-join (map step->label (.label edge)) "\\n")
                     "\"}\n"))
    (display "{ \"nodeKeyProperty\": \"id\",\n")
    (display "\"nodeDataArray\": [\n")
    (display "{\"id\": \"*\", \"text\": \"\", \"state\": {}},\n")
    (display (string-join (map vertex->string vertices) ",\n" 'infix))
    (display "],\n\"linkDataArray\": [\n")
    (display (string-append "{\"from\": \"*\", \"to\": \"" (id (.from (car edges))) "\", \"text\": \"\"},\n"))
    (display (string-join (map edge->string edges) ",\n"))
    (display "]\n}\n")))

(define (state->pair state)
  (cons (car state) (format #f "~a" (ast:value (cdr state)))))
(define (type o)
  ((compose (cut symbol-join <> ".") ast:full-name .type .instance) o))
(define (goopify edges)
  (define (->string instances-state)
    (scm->json-string
     (map (lambda (instance-state)
            (cons (string->symbol
                   (string-join (map (compose symbol->string .name .instance)
                                     (reverse (runtime:container-path (car instance-state)))) "."))
                  (map (lambda (s)
		         (cons (car s) (->symbol (cdr s))))
                       (cdr instance-state))))
          instances-state)))

  (let* ((edges ((compose (if (command-line:get 'remove-duplicate-transitions) remove-duplicates identity)
                          (if (command-line:get 'remove-self-transitions) remove-self identity)
                          (remove-vars (map string->symbol (string-split (command-line:get 'remove-vars "") #\space))))
                 edges))
	 (vertex-pairs (map (lambda (vertex) (cons ((compose ->string .state) vertex) vertex))
                            (append (map .from edges) (map .to edges))))
         (vertex-pairs (delete-duplicates vertex-pairs (lambda (a b) (string=? (car a) (car b))))))

    (define (id vertex-string)
      (list-index (lambda (vp) (equal? vertex-string (car vp))) vertex-pairs))
    (define (vertex->instance vertex)
      (make <step:instance+state-alist> #:alist
            (map (lambda (p)
                   (cons (symbol-join (runtime:instance->path (car p)) ".")
                         (make <step:instance+state>
                           #:type (type (car p))
                           #:kind (kind (car p))
                           #:state (make <step:state-alist>
                                     #:alist
                                     (map state->pair (cdr p))))))
                 (.state vertex))))
    (define (vertex->lts:node vertex-pair)
      (cons (id (car vertex-pair)) (vertex->instance (cdr vertex-pair))))
    (define (edge->lts:link edge)
      (let* ((steps (.label edge))
             (events (steps->events steps)))

        (make <step:lts-link> #:from (id ((compose ->string .state .from) edge)) #:to (id ((compose ->string .state .to) edge)) #:event (make <step:event-list> #:list events))))

    ((@@ (gaiag step-serialize) step:serialize)
     (make <step:lts>
       #:node (make <step:node-alist> #:alist (map vertex->lts:node vertex-pairs))
       #:link (make <step:list> #:list (map edge->lts:link edges)))
     (current-output-port))
    (newline)

    ;; (serialize (make <step:lts>
    ;;              #:node (make <step:node-alist> #:alist (map vertex->lts:node vertices))
    ;;              #:link (make <step:list> #:list (map edge->lts:link edges))))
    ;; (newline)

    ;; (serialize `((node . ,(map vertex->lts:node vertices))
    ;;              (link . ,(map edge->lts:link edges))))
    ))

(define (dot edges)
  (define (->string instances-state)
    (string-join
     (map
      (lambda (instance-state)
        (string-append (string-join (map (compose symbol->string .name .instance) (reverse (runtime:container-path (car instance-state)))) ".") " : ["
         (string-join (map
                       (lambda (s)
		         (string-append
                          (symbol->string (car s)) "="
			  (symbol->string (->symbol (cdr s))))) (cdr instance-state)) ", ")
         "]\\l"))
      instances-state) ""))
  (let ((edges ((compose (if (command-line:get 'remove-duplicate-transitions) remove-duplicates identity)
                         (if (command-line:get 'remove-self-transitions) remove-self identity)
                         (remove-vars (map string->symbol (string-split (command-line:get 'remove-vars "") #\space)))) edges)))
    (display "digraph G {\n")
    (display "begin[shape=\"circle\" width=0.3 fillcolor=\"black\" style=\"filled\" label=\"\"]\n")
    (display "node[shape=\"rectangle\" style=\"rounded\"]\n")
    (when (pair? edges)
      (display "begin -> \"") (display (->string (.state (.from (car edges))))) (display "\"\n"))
    (for-each (lambda (edge)
                (display "\"")
	        (display (->string (.state (.from edge))))
                (display "\" -> \"")
                (display (->string (.state (.to edge))))
                (display "\" [label=\"") (display (string-join (map step->label (.label edge)) "\n")) (display "\"]\n"))
              edges)
    (display "}\n")))

(define-method (vertex->string (o <vertex>))
  (map (lambda (instance-state)
         (let ((instance (car instance-state))
               (state (cdr instance-state)))
           (string-append (string-join (map symbol->string (runtime:instance->path instance)))
                          (string-join (append-map (lambda (s) (list (symbol->string (car s)) (symbol->string (->symbol (cdr s))))) state)))))
       (.state o)))

(define ((remove-vars vars) edges)
  (let ((erase (lambda (vertex vars)
                 (let ((state (map (lambda (instance-state)
                                     (cons (car instance-state)
                                           (filter (lambda (var)
                                                     (not (find (cut equal? (car var) <>) vars)))
                                                   (cdr instance-state))))
                                   (.state vertex))))
                   (make <vertex> #:state state)))))
    (map (lambda (edge)
           (make <edge>
             #:from (erase (.from edge) vars)
             #:to (erase (.to edge) vars)
             #:label (.label edge)))
         edges)))

(define (remove-self edges)
  (filter (lambda (edge)
            (not (equal? (vertex->string (.from edge))
                         (vertex->string (.to edge))))) edges))

(define (remove-duplicates edges)
  (delete-duplicates edges (lambda (a b)
                             (and (equal? (.label a) (.label b))
                                  (equal? (vertex->string (.from a)) (vertex->string (.from b)))
                                  (equal? (vertex->string (.to a)) (vertex->string (.to b)))))))

(define-method (labels (o <runtime:component>))
  (ast:in-triggers (.type (.instance o))))


(define-method (labels (o <runtime:system>))
  (let* ((system (.type (.instance o)))
         (bindings (ast:binding* system))
         ;;(ports (map runtime:other-port (filter .boundary? (%instances))))
         (ports (filter (conjoin .boundary? (compose ast:provides? .instance)) (%instances))))
    (append-map (lambda (port)
                  (map (lambda (e)
                         (make <runtime:trigger> #:instance port #:event.name (.name e)))
                       (if (ast:provides? (.instance port)) (filter ast:in? (ast:event* (.type (.instance port))))
                           (filter ast:out? (ast:event* (.type (.instance port))))))) ;;FIXME simplify
                ports)))

(define-method (run-label (node <node>) (label <trigger>)) ;;FIXME: finish refactor <trigger> -> <runtime:trigger> or ???
  (run node (%sut) label))

(define-method (run-label (node <node>) (label <runtime:trigger>))
  (let ((trigger (make <trigger> #:port.name ((compose .name .instance .instance) label) #:event.name (.event.name label)))
        (instance (.container (.instance label))))
    (if (is-a? (%sut) <runtime:system>)
        (let* ((port (runtime:other-port (.instance label)))
               (record-trigger (make <trigger> #:event.name (.event.name label)))
               (component-port (runtime:find-instance (.port.name trigger) instance #f)))
          (if component-port (let* ((system-port (runtime:other-port component-port)))
                               (run (record-step node port record-trigger) instance trigger))
              (list (set-status node (make <no-match>)))))
        (run node instance trigger))))

(define-method (run-label (node <node>) (label <runtime:trigger>))
  (let ((trigger (make <trigger> #:port.name ((compose .name .instance .instance) label) #:event.name (.event.name label))))
    (run-trigger node trigger)))

(define (step->label s)
  (let ((instance (car s))
        (statement (cdr s)))
    (string-join
     (map symbol->string
          (append (if
                   (or (is-a? statement <reply>) (is-a? statement <trigger-return>)
                       (is-a? (.container instance) <runtime:foreign>))
                   (runtime:instance->path instance)
                   (runtime:instance->path instance))
                  (list (->symbol statement))))  ".")))

(define-method (lts (node <node>))
  (define (make-edges instances from to)
    (let* (;;(steps (drop (.steps to) (length (.steps from))))
           (steps (.steps to))
           (steps (map (lambda (step)
                         (let ((instance (car step))
                               (statement (cdr step)))
                           (if (and (is-a? instance <runtime:foreign>) ;; CHECKME
                                (is-a? statement <action>)
                                    (not (is-a? statement <action-out>))
                                    (let* ((instance-port (runtime:find-instance (.port.name statement) instance #f))
                                           (other-port (runtime:other-port instance-port)))
                                      (runtime:boundary-port? other-port)))
                               (let* ((instance-port (runtime:find-instance (.port.name statement) instance #f))
                                      (other-port (runtime:other-port instance-port)))
                                 (cons (%sut) (action->trigger other-port statement)))
                               step)))
                       steps))
           (steps (filter (conjoin (negate state-step?) all-relevant-steps-for-now) steps)))
      (make <edge>
        #:from from
        #:to (node->vertex to instances)
        #:label steps))) ;;FIX go & dot by mapping step->label over steps
  (let* ((labels (labels (%sut)))
         (hes (lambda (vertex-string size) (hash vertex-string size)))
         (hes-tebel (make-hash-table 1024))
         (instances (filter (disjoin (negate (is? <runtime:port>)) runtime:boundary-port?) (%instances)))
         (requires-instances (filter runtime:requires-instance? (%instances)))
         (initial (node->vertex node instances))
         (foo (hashx-set! hes assoc hes-tebel (vertex->string initial) #t)))
    (let loop ((frontier (list initial)) (edges '()) (horizon (and=> (command-line:get 'horizon #f) string->number)))
      (let* ((new-edges (append-map
                         (lambda (vertex)
                           (let ((node (vertex->node vertex)))
                             (map (cut make-edges instances vertex <>)
                                   (filter (negate .status)
                                           (append
                                            (append-map (cut run node <> (make <trigger> #:event.name 'optional)) requires-instances)
                                            (append-map (cut run node <> (make <trigger> #:event.name 'inevitable)) requires-instances)
                                            (append-map (cut run-label node <>) labels))))))
                         frontier))
             (frontier (filter (lambda (vertex)
                                 (let* ((vertex-hash (vertex->string vertex))
                                        (r (not (hashx-ref hes assoc hes-tebel vertex-hash))))
                                   (when r (hashx-set! hes assoc hes-tebel vertex-hash #t))
                                   r))
                               (map .to new-edges)))
             (edges (append edges new-edges)))
        (if (or (and horizon (= 0 horizon)) (null? frontier)) edges
            (loop frontier edges (and horizon (1- horizon))))))))

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

(define (symbol-join symbol-list separator)
  (string->symbol (string-join (map symbol->string symbol-list) (->string separator))))

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

(define all-relevant-steps-for-now (conjoin (negate eligible-step?)
                                   (disjoin state-step? (trigger-step? #f))))

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

(define (group pred elements)
  "Returns a list of lists from ELEMENTS split by PRED"
  (if (null? elements) '()
      (let ((groups (let loop ((elements (cdr elements)) (groups '()) (group (list (car elements))))
                      (if (null? elements) (cons group groups)
                          (let ((element (car elements)))
                            (if (pred element)
                                (loop (cdr elements) (cons group groups) (list element))
                                (loop (cdr elements) groups (cons element group))))))))
        (map reverse (reverse groups)))))

(define (steps->events steps)
  (let* ((events
          (fold
           (lambda (step result)
             (if (or (null? result) (is-a? (car result) <step:event>))
                 (cons step result)
                 (let* ((from-strings (string-split (side->string (car result)) #\.))
                        (from (string-join (drop-right from-strings (if (equal? "<q>" (last from-strings)) 0 1)) "."))
                        (from-location (and (command-line:get 'locations #f) (step->location (cdr (car result)))))
                        (to-strings (string-split (side->string step) #\.))
                        (to (string-join (drop-right to-strings (if (equal? "<q>" (last to-strings)) 0 1)) "."))
                        (to-location (and (command-line:get 'locations #f) (step->location (cdr step))))
                        (name (if (equal? (last from-strings) "<q>") (last to-strings) (last from-strings)))
                        (result (cdr result)))
                   (cons (make <step:event>
                           #:from-location from-location
                           #:from from
                           #:to-location to-location
                           #:to to
                           #:name name) result)))) '() steps))
         (events (if (or (null? events) (is-a? (car events) <step:event>)) events (cdr events))))
    (reverse events)))

(define* (json:print-trace nodes)
  (if (= 1 (length nodes))
      (let* ((instances (filter (disjoin (negate (is? <runtime:port>)) runtime:boundary-port?) (%instances)))
             (node (car nodes))
             (steps (.steps node))
             (steps (filter all-relevant-steps-for-now steps))
             (blocks (group state-step? steps))
             (step->state (lambda (step)
                            (let ((instance+state (filter (compose (disjoin (negate (is? <runtime:port>)) runtime:boundary-port?) car) (cdr step))))
                              (make <step:instance+state-alist> #:alist
                                    (map (lambda (i) (cons (symbol-join (runtime:instance->path i) ".")
                                                           (make <step:instance+state>
                                                             #:type (type i)
                                                             #:kind (kind i)
                                                             #:state (make <step:state-alist> #:alist (map state->pair (.vars (assoc-ref instance+state i)))))))
                                         instances))))))

        ((@@ (gaiag step-serialize) step:serialize)
         (make <step:list>
           #:list (map (lambda (block)
                         (make <step:transition>
                           #:instance+state (step->state (car block))
                           #:event (make <step:event-list> #:list (steps->events (cdr block)))))
                       blocks))
         (current-output-port)))
      (map print-trace nodes (iota (length nodes)))))

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

(define-method (symbol->value v)
  (match v
    ('true (make <literal> #:value 'true))
    ('false (make <literal> #:value 'false))
    ((? number?) (make <literal> #:value v))
    (_ (let* ((enum (reverse (symbol-split v #\.)))
              (scope (reverse (cddr enum)))
              (type.name (second enum))
              (field (first enum)))
         (make <enum-literal> #:type.name (make <scope.name> #:scope scope #:name type.name) #:field field))) ;; FIXME: what about resolving
    ))

(define-method (kind (o <runtime:instance>))
  (match o
    (($ <runtime:port>) (if (runtime:provides-instance? o) 'provides 'requires))
    (($ <runtime:component>) 'component)
    (($ <runtime:foreign>) 'foreign)
    (($ <runtime:system>) 'system)
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
                (kind (kind o)))
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

(define-method (json:get-initial-state (o <step:instance+state-alist>))
  (let ((initial-state (fold create-initial-state '() (%instances))))
    (map (lambda (inst)
           (let* ((state (assoc-ref (step:.alist o) (symbol-join (runtime:instance->path inst) '.)))
                  (initial-inst-state (assoc-ref initial-state inst))
                  (state (if state (map (lambda (s)
                                          (cons (car s)
                                                (clone (symbol->value (cdr s))
                                                       #:parent (.parent (assoc-ref initial-inst-state (car s))))))
                                        (step:.alist (step:.state state)))
                             initial-inst-state)))
             (cons inst state)))
         (%instances))))

(define (read-input-file)
  (define (helper x)
    (if (eof-object? x) '()
        (cons x (helper (read)))))
  (helper (read)))

(define (string->trail o)
  (with-input-from-string (string-join (string-split o #\,) " ") read-input-file))

(define (json->trail o)
  (let ((str (string-trim-both o)))
    (if (string-null? str) (make <step:list>) (step:goopify (step:deserialize str)))))

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

(define-method (json:create-initial-node (o <step:transition-list>))
  (define (external-event s n)
    (let ((lst (string-split (symbol->string s) #\.)))
      (and (pair? lst)
           (equal? "<external>" (car lst))
           (string->symbol (string-join (append (cdr lst) (list (symbol->string n))) ".")))))

  (let* ((transitions (step:.list o))
         (transition? (and (pair? transitions) (last transitions)))
         (initial-state (if transition? (json:get-initial-state (step:.instance+state transition?))
                            (get-initial-state '())))
         (node (make-initial-node (%instances) initial-state))
         (node (record-state node (%sut)))
         (trail (if (not transition?) '()
                    (filter-map (lambda (event)
                                  (or (external-event (step:.from event) (step:.name event))
                                      (external-event (step:.to event) (step:.name event))))
                                (step:.list (step:.event transition?))))))
    (clone node #:trail trail)))


(define %lts (make-parameter #f))

(define (step:root-> root)
  (debug-disable 'backtrace)
  (setup-debug-printing!)
  (let ((sut (runtime:get-sut root)))
;;    (debug "root:\n")
    ;;(debug-pretty (om->list root))
    (parameterize ((%sut sut))
      (parameterize ((%instances (runtime:get-system-instances sut))
                     (%lts (command-line:get 'lts #f)))
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

(define (measure-perf label thunk)
  (let ((t1 (get-internal-run-time))
        (result (thunk))
        (t2 (get-internal-run-time)))
    (stderr "~a: ~a\n" (/ (- t2 t1) 1000000.0) label)
    result))

(define (measure-perf-inc sum thunk)
  (let ((t1 (get-internal-run-time))
        (result (thunk))
        (t2 (get-internal-run-time)))
    (set! sum (+ sum (- t2 t1)))
    result))

(define (measure-perf-result label sum)
  (stderr "~a: ~a\n" (/ sum 1000000.0) label))

(define (lts-> -> ast)
  (setup-debug-printing!)
  (let* ((root (step:om ast))
         (sut (runtime:get-sut root)))
    (parameterize ((%sut sut))
      (parameterize ((%instances (runtime:get-system-instances sut))
                     (%lts #t))
        (if (member -> (list dot go goopify)) (-> (lts (json:create-initial-node (or (and=> (command-line:get 'initial #f) json->trail) (make <step:transition-list>)))))
            (let* ((instance (.instance sut))
                   (model (.type instance))
                   (name (.name (.name model))) ;; FIXME: namespace
                   (type (ast-name model))
                   (state (with-output-to-string (cut -> (lts (json:create-initial-node (make <step:transition-list>))))))
                   (model-names (map (compose .name .name) (ast:model* root)))
                   (other-names (filter (negate (cut eq? name <>)) model-names))
                   (others-alist (map (compose list (cut cons 'name <>)) other-names))
                   (json (scm->json-string `((models . (((name . ,name) (type . ,type) (state . ,state))
                                                        ,@others-alist))))))
              (format (current-error-port) "json:~s\n" json)
              (display json)
              (newline))))))
  "")

#!
;; Start Geiser: C-c C-a

(chdir "../..")
(setenv "PATH" (string-append (canonicalize-path "bin") ":" (getenv "PATH")))

(define ast (parse-file "test/step/helloworld/helloworld.dzn" #:behaviour? #t))
(define root (step:om ast))
(define model (ast:get-model root 'helloworld))

(define ast (parse-file "test/step/system_hello/system_hello.dzn" #:behaviour? #t))
(define root (step:om ast))
(define model (ast:get-model root 'system_hello))

(%sut (rutime:get-sut root model))
(%instances (runtime:get-system-instances (%sut)))
(define input-trail '(h.hello))
(define node (create-initial-node input-trail))

!#
