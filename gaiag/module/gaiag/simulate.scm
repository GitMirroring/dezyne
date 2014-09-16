;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag simulate)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (language asd parse)

  :use-module (gaiag gaiag)
  :use-module (gaiag json-trace)
  :use-module (gaiag misc)

  :use-module (gaiag pretty-print)
  :use-module (gaiag reader)

  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast->a
           explore-space
           mangle-trace
           walk-trail
           event->ast
           ->symbol
           simulate:gom
           var))

(define debug? #f)
;;(define debug? #t)
(define (debug . x) #t)
(if debug?
    (set! debug stderr))

(define *ast* #f)
(define *model* #f)

(define (ast-> ast)
  (let ((gom ((gom:register simulate:gom) ast #t)))
    (set! *ast* gom)
    (pretty-print (gom->list *ast*) (current-error-port))
    (and=> (gom:model-with-behaviour gom) simulate-model)
    ""))

(define (simulate:import name)
  (gom:import name simulate:gom))

(define (simulate:gom ast)
  ((compose ast:resolve ast->gom) ast))

(define (variable-state variable . value)
  (cons (.name variable)
        (eval-expression '() '()
                          (if (pair? value)
                              (car value)
                              (.expression variable)))))

(define (state-vector model)
  (map variable-state (gom:variables model)))

(define (var state identifier) (assoc-ref state identifier))

(define (var! state identifier value)
  (assoc-set!
   (map (lambda (x) (if (eq? identifier (car x)) (cons (car x) (cdr x)) x)) state)
   identifier value))

(define i 0)
(define *state-space* '(()))

(define (simulate-model model)
  (stderr "\n\n>>>simulating: ~a ~a --> ~a\n" (ast-name model) (.name model) (map ->string (gom:find-events model)))
  (and-let* ((((is? <component>) model))
             (interfaces (map simulate:import
                              (map .type ((compose .elements .ports) model))))))
  (let* ((trail (option-ref (parse-opts (command-line)) 'trail #f))
         (trace (if trail
                    (walk-trail model (with-input-from-string trail read))
                    (explore-space model))))
    (pretty-print (mangle-trace trace)))
  (newline)
  (stderr "state space: ~a\n" (length *state-space*))
  "")

(define (mangle-trace trace)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        (append
         (list
          (json-init *model*)
          (json-state (state-vector *model*)))
         (apply append (map json-trace trace)))
        (map demo-trace trace))))

(define (explore-space ast)
  (simulate ast))

(define (walk-trail ast trail)
  (simulate ast (next-todo-trail-walker ast (map event->ast trail))))

(define (trace-location ast)
  (or (and-let* ((loc (source-location ast))
                 (properties (source-location->source-properties loc)))
                (format #f "~a:~a:~a"
                        (assoc-ref properties 'filename)
                        (assoc-ref properties 'line)
                        (assoc-ref properties 'column)))
      ast))

(define (demo-trace tracepoint)
  (let ((event (car tracepoint))
        (state (cadr tracepoint))
        (steps (cddr tracepoint))
        (model (.name *model*)))
    ;; (stderr "\ndemo-trace: ~a, ~a\n" event (class-of (car steps)))
    (cons (->symbol event)
          (list
           (list 'state (map (lambda (x) (list (car x) (cdr x)))  state))
           (list 'trace (map trace-location steps))))))

(define (event->ast event)
  "if EVENT is of form INTERFACE.TRIGGER, produce (trigger PORT EVENT)"
  (or (and-let* ((string (symbol->string event))
                 (port-event (string-split string #\.))
                 ((=2 (length port-event))))
               (make <trigger>
                 :port (string->symbol (car port-event))
                 :event (string->symbol (cadr port-event))))
      (make <trigger> :port #f :event event)))

(define *if-exp* #f) ;; component's interfaces simulate experiment
(define (seen-key state ast)
  (when (and *if-exp* (not (equal? ast (.statement (.behaviour *model*)))))
    ;; it's a bug if we store a 'seen' state with a non-top AST:
    ;; only actions return mid-statements and they are continued
    ;; we alway continue until the end
    (stderr "AST:~a\n" ast)
    (throw 'barf-seen-about-non-top-ast))
  (list state ast))

(define (seen-key-state key) (caar key))
(define (seen-key-ast key) (cadar key))

(define (seen state ast)
  (set! i (1+ i))
  (if (> i 1000)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*))))
  (let* ((key (seen-key state ast))
         (events (f-is-null (assoc-ref *state-space* key))))
    events))

(define (seen? state ast event)
  (find (lambda (x) (equal? x event)) (seen state ast)))

(define (seen! state ast event)
  (when (and *if-exp* (not (equal? ast (.statement (.behaviour *model*)))))
    (stderr "seen! --> AST:~a\n" ast)
    (throw 'seen!-with-non-top-ast))

  (let* ((key (seen-key state ast))
         (events (seen state ast)))
    (if (not (seen? state ast event))
        (let ((value (delete-duplicates (sort (cons event events) event<))))
          (set! *state-space* (assoc-set! *state-space* key value))))))

(define (state-ast-todo state ast events)
  (let ((done (seen state ast)))
    (filter (negate (lambda (x) (member x done equal?))) events)))

(define (next-value action) #t)

;; FIXME: TODO: implement next-value for state explorer
(define (next-todo-space-explorer model state ast)
  (let ((events (gom:find-events model)))
    (if (or (null? *state-space*)
            (null? (car *state-space*)))
        (cons (state-vector model) events)
        (let ((todo (state-ast-todo state ast events)))
          (if (pair? todo)
              (cons state todo)
              (let loop ((entries *state-space*))
                (if (or (null? entries)
                        (null? (car entries)))
                    (cons #f '())
                    (let* ((key-events (car entries))
                           (state (seen-key-state key-events))
                           (ast (seen-key-ast key-events))
                           (todo (state-ast-todo state ast events)))
                      (if (pair? todo)
                          (cons state todo)
                          (loop (cdr entries)))))))))))

(define (next-todo-trail-walker model trail)
  (let ((trail trail))
    (set! next-value
          (lambda (action)
            (if (null? trail)
                #f
                (let* ((trigger (car trail))
                       (value (make <literal>
                                :type (.port trigger)
                                :field (.event trigger))))
                  (stderr "****value := ~a\n" (->string value))
                  (set! trail (cdr trail))
                  value))))
    (lambda (model state ast-dont-care)
      (if (null? trail)
          (cons #f '())
          (let ((event (car trail)))
            (set! trail (cdr trail))
            (cons (if (eq? state 'initial) (state-vector model) state)
                  (list event)))))))

(define* (simulate model :optional
                   (next-todo next-todo-space-explorer)
                   (ast (.statement (.behaviour model))))
  (set! *model* model)
  (set! *state-space* '(()))
  (set! i 0)
  (let loop ((state-todo (next-todo model 'initial ast)))
    (let* ((state (car state-todo))
           (todo (null-is-#f (cdr state-todo))))
      (if (or (not state) (not todo))
          '()
          (let* ((event (car todo)))
            (receive (new-state trace)
                (process-event ast state event)
              (cons (cons (->symbol event) (cons state trace)) (loop (next-todo model new-state ast)))))))))

(define* (process-event ast state event)
  (stderr "[~a] " (comma-space-join (map ->string state)))
  (stderr "event: ~a\n" (->string event))
  (seen! state ast event)
  (let continue ((state state) (ast ast) (action 'first) (trace '()))
    (if (not action)
        (begin
          (stderr "\n")
          (values state (reverse trace)))
        (begin
          (if (not (eq? action 'first))
              (stderr "  continued...\n"))
          (receive (state ast action return t)
              (process ast state event trace)
            (if (not t) (car t))
            (continue state ast action t))))))

;; AST: curry me
(define ((variable? model) identifier) (gom:variable model identifier))

(define (eval-expression ast state expression)
  (match expression
    (($ <expression> expression) (eval-expression ast state expression))
    (#f #f)
    (#t #t)
    ('false #f)
    ('true #t)
    (($ <var> identifier) (var state identifier))
    (($ <field> (and (? (variable? *model*)) (get! identifier)) field)
     (eq? (.field (var state (identifier))) field))
    (($ <literal> scope type value) expression)
    (('! expr) (not (eval-expression ast state expr)))
    (('and x y) (and (eval-expression ast state x)
                     (eval-expression ast state y)))
    (('or x y) (or (eval-expression ast state x)
                   (eval-expression ast state y)))
    ((== x y)
     (let* ((lhs (eval-expression ast state x))
            (rhs (eval-expression ast state y))
            (r (equal? lhs rhs)))
     r))
    (($ <otherwise>)
     (let* ((parent (gom:parent *model* ast))
            (guards ((gom:statements-of-type 'guard) parent))
            (expressions (map .expression guards)))
       (receive (otherwise rest)
           (partition (lambda (x) (is-a? x <otherwise>)) expressions)
         (if (not (and (=1 (length otherwise))
                       (eq? (car otherwise) expression)))
             (throw 'programming-error "parent missing otherwise"))
         ;; otherwise is true if none of the other guards is
         (not (any identity (map (lambda (x) (eval-expression ast state x)) rest))))))
    ((? symbol?) (eval-expression ast state (var state expression)))
    (_ (throw 'match-error (format #f "~a:expression no match: ~a\n" (current-source-location) expression)))))

;; FIMXE: c&p from csp.csm
(define ((valued-action? port?) src)
  (match src
    (($ <variable> name type ($ <action>)) #t)
    (($ <assign> identifier ($ <action>)) #t)
    (_ #f)))

(define (eval-function-expression ast state event trace expression)
  ;; FIMXE: c&p from csp.csm:ast-transform
  (let* ((model *model*)
	 (members (gom:member-names model))
         (port? (lambda (port) (member port (map .name ((compose .elements .ports) model)))))
         (valued-action? (valued-action? port?)))
    (match expression
      (($ <call> function ($ <arguments> arguments))
       (receive (new-state new-ast new-action return new-trace)
           (let* ((f (gom:function *model* function)) ;; FIXME
                  (parameters (map .identifier ((compose .elements .parameters .signature) f)))
                  (statement (.statement f))
                  (pairs (zip parameters arguments))
                  (state (let loop ((pairs pairs) (state state))
                           (if (null? pairs)
                               state
                               (loop (cdr pairs) (acons (caar pairs)
                                                        (eval-expression ast state (cadar pairs)) state))))))
             (process statement state event (cons f '())))
         (values (drop new-state (length arguments)) new-ast new-action return new-trace)))
      ;; FIXME transform AST so that this reads 'action or 'valued-action
      ;; SEE csp.scm
      (($ <action> ($ <trigger> port event))
       (values state ast #f (eval-expression ast state (next-value event)) trace))
      (_ (values state ast #f (eval-expression ast state expression) trace)))))

(define* (process ast state event trace)
  ;; (stderr "PROCESS: [~a] ~a\n" (->string event) ast)
  (set! i (1+ i))
  (if (> i 2000)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*)))
  (and state
       (match ast
         (($ <on> ($ <triggers> t) statement)
          (debug "on: t=~a, event=~a --> ~a\n" t event (member event t trigger-equal?))
          (if (member event t trigger-equal?)
              (process statement state event (cons ast trace))
              (values state #f #f #f trace)))
         (($ <guard> expression statement)
          (debug "guard: ~a? --> ~a =====> ~a\n" expression (eval-expression ast state expression) statement)
          (if (eval-expression ast state expression)
              (process statement state event (cons ast trace))
              (values state #f #f #f trace)))
         (($ <illegal>) (values state #f #f #f (cons ast trace)))
         (($ <action> trigger)
          (stderr "****action: ~a\n" (->string trigger))
          (let* ((trace (cons ast trace))
                 (port (.port trigger)))
            (if port
                (let* ((interface (simulate:import (.type (gom:port *model* port))))
                       (i-ast (.statement (.behaviour interface)))
                       (event (.event trigger))
                       (i-trigger (make <trigger> :port #f :event event))
                       (i-state (state-vector interface))) ;; FIXME: store!
                  (receive (i-state i-trace)
                      (process-event i-ast i-state i-trigger)
                   (values state #f ast #f (append i-trace trace))))
                (values state #f ast #f trace))))
         (($ <assign> identifier expression)
          (stderr "****assign: ~a := ~a\n" (->string identifier) (->string expression))
          (receive (new-state new-ast new-action return new-trace)
              (eval-function-expression ast state event (cons ast trace) expression)
            (values (var! new-state identifier return) #f #f return new-trace)))
         (($ <variable> type identifier expression)
          (receive (new-state new-ast new-action return new-trace)
              (eval-function-expression ast state event (cons ast trace) expression)
            (stderr "****init: ~a := ~a ==> ~a\n" (->string identifier) (->string expression) (->string return))
            (values (var! new-state identifier return) #f #f return new-trace)))
         (($ <if> expression statement else)
          (if (eval-expression ast state expression)
              (process statement state event (cons ast trace))
              (process else state event (cons ast trace))))
         (($ <if> expression statement)
          (if (eval-expression ast state expression)
              (process statement state event (cons ast trace))
              (values state #f #f #f (cons ast trace))))
         (($ <compound> '()) (values state '() #f #f trace))
         (#f (values state '() #f #f trace))
         (($ <compound> elements)
          (let ((declarative? (gom:declarative? (car elements))))
            (let loop ((statements elements) (loop-state state) (loop-return #f) (loop-trace (cons ast trace)) (frame 0))
              (if (null? statements)
                  (values (drop loop-state frame) statements #f loop-return loop-trace)
                  (let ((statement (car statements)))
                    (if declarative?
                        (receive (new-state new-ast new-action new-return new-trace)
                            (process statement state event '())
                          (if (pair? new-trace)
                              (loop (cdr statements) new-state new-return (append new-trace trace) frame)
                              (loop (cdr statements) loop-state new-return loop-trace frame)))
                        (let ((loop-state (if (is-a? statement <variable>)
                                              (acons (.name statement)
                                                     #f loop-state) loop-state))
                              (frame (if (is-a? statement <variable>)
                                         (1+ frame) frame)))
                          (receive (new-state new-ast new-action new-return new-trace)
                            (process statement loop-state event '())
                            (loop (cdr statements) new-state new-return (append new-trace loop-trace) frame)))))))))
         (($ <return> expression)
          (let ((return (eval-expression ast state expression)))
            (values state #f #f return (cons ast trace))))
         (($ <reply> expression)
          (stderr "****reply: ~a\n" (->string expression))
          (let ((reply (eval-expression ast state expression)))
            (values state ast #f #f (cons ast trace))))
         (_ (throw 'match-error  (format #f "~a: process: no match: ~a\n"  (current-source-location) ast)))))))

(define (->string src)
  (match src
    (#f "false")
    (#t "true")
    (($ <expression> expression) (->string expression))
    (($ <var> identifier) (symbol->string identifier))
    (($ <field> type field) (->string (list (->string type) "." field)))
    ((identifier ($ <field> type field)) (->string (list (->string identifier) " = " (->string type) "." field)))
    ((identifier ($ <literal> scope type field)) (->string (list (->string identifier) " = " (->string type) "." (->string field))))
    (($ <literal> scope type field) (->string (list (->string type) "." (->string field))))
    (($ <trigger> #f event) (->string event))
    (($ <trigger> port event) (->string (list port "." event)))
    (('type name) (->string name))
    (($ <call> function ($ <arguments> arguments)) (->string (list function "("  (comma-join arguments) ")" )))
    ((h ... t) (apply string-append (map ->string src)))
    ((h . t) (string-join (list (->string h) "=" (->string t))))
    (((h ... t)) (->string (car src)))
    (_ ((@ (gaiag misc) ->string) src))))

(define (->symbol src)
  (match src
    (#f 'false)
    (#t 'true)
    (($ <expression> expression) (->symbol expression))
    (($ <var> identifier) identifier)
    (($ <field> type field) (->symbol (list (->symbol type) "." field)))
    ((identifier ($ <field> type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." field)))
    ((identifier ($ <literal> scope type field)) (->symbol (list (->symbol identifier) " = " (->symbol type) "." (->symbol field))))
    (($ <literal> scope type field) (->symbol (list (->symbol type) "." (->symbol field))))
    (($ <trigger> #f event) (->symbol event))
    (($ <trigger> port event) (->symbol (list port "." event)))

    ((h ... t) (apply symbol-append (map ->symbol src)))
    ((h . t) (list (->symbol h) '= (->symbol t)))
    (((h ... t)) (->symbol (car src)))
    ((? string?) (string->symbol src))
    ((? symbol?) src)
    (_ (throw 'match-error  (format #f "~a: ->symbol match: ~a\n"  (current-source-location) src)))))

(define (event< a b)
  (list< (list (.port a) (.event a)) (list (.port b) (.event b))))

(define (trigger-equal? a b)
  (and (eq? (.port a) (.port b))
       (eq? (.event a ) (.event b))))
