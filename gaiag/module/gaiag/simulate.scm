;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (language dezyne location)

  :use-module (gaiag gaiag)
  :use-module (gaiag json-trace)
  :use-module (gaiag misc)
  :use-module (gaiag evaluate)

  :use-module (gaiag pretty-print)
  :use-module (gaiag reader)

  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (gaiag om)

  :export (ast->
           explore-space
           mangle-trace
           walk-trail
           event->ast
           ->symbol
           simulate:om))

(cond-expand
 (goops-om
  (use-modules (oop goops)))
 (else #t))

(define debug? #f)
;;(define debug? #t)
(define (debug . x) #t)
(if debug?
    (set! debug stderr))

(define (ast-> ast)
  (or (and-let* ((om ((om:register simulate:om) ast #t))
                 (models (filter (lambda (x) (or (is-a? x <interface>)
                                                 (is-a? x <component>)))
                                 (.elements om)))
                 (models (null-is-#f (filter .behaviour models)))
                 (components (filter (is? <component>) models)))
                (simulate (car (if (pair? components) components models))))
      ""))

(define (simulate:import name)
  (om:import name simulate:om))

(define (simulate:om ast)
  ((compose ;;ast:wfc
            ast:resolve ast->om) ast))

(define *state-alist* '())
(define (get-state o)
  (or (assoc-ref *state-alist* (.name o))
      (state-vector o)))

(define (set-state! o state)
  (set! *state-alist* (assoc-set! *state-alist* (.name o) state)))

(define i 0)
(define *state-space* '(()))

(define (simulate-model model)
  (stderr "\n\n>>>simulating: ~a ~a --> ~a\n" (ast-name model) (.name model) (map ->string (om:find-triggers model)))
  (and-let* ((((is? <component>) model))
             (interfaces (map simulate:import
                              (map .type ((compose .elements .ports) model))))))
  (let* ((trail (option-ref (parse-opts (command-line)) 'trail #f))
         (trace (if trail
                    (walk-trail model (with-input-from-string trail read))
                    (explore-space model))))
    (pretty-print (mangle-trace model trace)))
  (newline)
  (stderr "state space: ~a\n" (length *state-space*))
  "")

(define (mangle-trace model trace)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        (append
         (list
          (json-init model)
          (json-state model (state-vector model)))
         (apply append (map (json-trace model) trace)))
        (map (demo-trace model) trace))))

(define (explore-space ast)
  (simulate ast))

(define (walk-trail model trail)
  (simulate model (next-todo-trail-walker model (map event->ast trail))))

(define (trace-location ast)
  (or (and-let* ((loc (source-location ast))
                 (properties (source-location->user-source-properties loc)))
                (format #f "~a:~a:~a"
                        (assoc-ref properties 'filename)
                        (assoc-ref properties 'line)
                        (assoc-ref properties 'column)))
      ast))

(define ((demo-trace model) tracepoint)
  (let ((event (car tracepoint))
        (state (cadr tracepoint))
        (steps (cddr tracepoint))
        (model (.name model)))
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

(define (seen-key model state ast)
  (when (not (equal? (om->list ast) (om->list (.statement (.behaviour model)))))
    ;; it's a bug -for now- if we store a 'seen' state with a non-top
    ;; AST: only actions return mid-statements and they are continued
    ;; we alway continue until the end
    (stderr "AST:~a\n" ast)
    (throw 'barf-seen-about-non-top-ast))
  (list state ast))

(define (seen-key-state key) (caar key))
(define (seen-key-ast key) (cadar key))

(define (seen model state ast)
  (set! i (1+ i))
  (if (> i 1000)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*))))
  (let* ((key (seen-key model state ast))
         (events (f-is-null (assoc-ref *state-space* key))))
    events))

(define (seen? model state ast event)
  (find (lambda (x) (equal? x event)) (seen model state ast)))

(define (seen! model state ast event)
  (when (not (equal? (om->list ast) (om->list (.statement (.behaviour model)))))
    (stderr "seen! --> AST:~a\n" ast)
    (throw 'seen!-with-non-top-ast))

  (let* ((key (seen-key model state ast))
         (events (seen model state ast)))
    (if (not (seen? model state ast event))
        (let ((value (delete-duplicates (sort (cons event events) <))))
          (set! *state-space* (assoc-set! *state-space* key value))))))

(define (state-ast-todo model state ast events)
  (let ((done (seen model state ast)))
    (filter (negate (lambda (x) (member x done equal?))) events)))

(define (next-value action) #t)

;; FIXME: TODO: implement next-value for state explorer
(define (next-todo-space-explorer model state ast)
  (let ((events (om:find-triggers model)))
    (if (or (null? *state-space*)
            (null? (car *state-space*)))
        (cons (state-vector model) events)
        (let ((todo (state-ast-todo model state ast events)))
          (if (pair? todo)
              (cons state todo)
              (let loop ((entries *state-space*))
                (if (or (null? entries)
                        (null? (car entries)))
                    (cons #f '())
                    (let* ((key-events (car entries))
                           (state (seen-key-state key-events))
                           (ast (seen-key-ast key-events))
                           (todo (state-ast-todo model state ast events)))
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

(define* (simulate model :optional (next-todo next-todo-space-explorer) (ast ((compose .statement .behaviour) model)))
  (set! *state-space* '(()))
  (set! i 0)
  (let loop ((state-todo (next-todo model 'initial ast)))
    (let* ((state (car state-todo))
           (todo (null-is-#f (cdr state-todo))))
      (if (or (not state) (not todo))
          '()
          (let* ((event (car todo)))
            (receive (new-state trace)
                (process-event model ast state event)
              (cons (cons (->symbol event) (cons state trace)) (loop (next-todo model new-state ast)))))))))

(define (process-event model ast state event)
  (stderr "[~a] " (comma-space-join (map ->string state)))
  (stderr "event: ~a\n" (->string event))
  (seen! model state ast event)
  (let continue ((state state) (ast ast) (action 'first) (trace '()))
    (if (not action)
        (begin
          (stderr "\n")
          (values state (reverse trace)))
        (begin
          (if (not (eq? action 'first))
              (stderr "  continued...\n"))
          (receive (state ast action return t)
              (process model ast state event trace)
            (if (not t) (car t))
            (continue state ast action t))))))

(define ((variable? model) identifier) (om:variable model identifier))

;; FIMXE: c&p from csp.csm
(define ((valued-action? port?) src)
  (match src
    (($ <variable> name type ($ <action>)) #t)
    (($ <assign> identifier ($ <action>)) #t)
    (_ #f)))

(define (eval-function-expression model ast state event trace expression)
  ;; FIMXE: c&p from csp.csm:ast-transform
  (let* ((members (om:member-names model))
         (port? (lambda (port) (member port (map .name ((compose .elements .ports) model)))))
         (valued-action? (valued-action? port?)))
    (match expression
      (($ <call> function ($ <arguments> arguments))
       (receive (new-state new-ast new-action return new-trace)
           (let* ((f (om:function model function))
                  (parameters (map .name ((compose .elements .parameters .signature) f)))
                  (statement (.statement f))
                  (pairs (zip parameters arguments))
                  (state (let loop ((pairs pairs) (state state))
                           (if (null? pairs)
                               state
                               (loop (cdr pairs) (acons (caar pairs)
                                                        (eval-expression model state (cadar pairs)) state))))))
             (process model statement state event (cons f '())))
         (values (drop new-state (length arguments)) new-ast new-action return new-trace)))
      (($ <action> ($ <trigger> port event))
       (values state ast #f (eval-expression model state (next-value event)) trace))
      (_ (values state ast #f (eval-expression model state expression) trace)))))

(define (process model ast state event trace)
  ;; (stderr "PROCESS: [~a] ~a\n" (->string event) ast)
  (set! i (1+ i))
  (if (> i 2000)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*)))
  (and state
       (match ast
         (($ <on> ($ <triggers> t) statement)
          (debug "on: t=~a, event=~a --> ~a\n" t event (member event t equal?))
          (if (member event t equal?)
              (process model statement state event (cons ast trace))
              (values state #f #f #f trace)))
         (($ <guard> expression statement)
          (debug "guard: ~a? --> ~a =====> ~a\n" expression (eval-expression model state expression) statement)
          (if (eval-expression model state expression)
              (process model statement state event (cons ast trace))
              (values state #f #f #f trace)))
         (($ <illegal>) (values state #f #f #f (cons ast trace)))
         (($ <action> trigger)
          (stderr "****action: ~a\n" (->string trigger))
          (let* ((trace (cons ast trace))
                 (port (.port trigger)))
            (if port
                (let* ((interface (simulate:import (.type (om:port model port))))
                       (i-ast (.statement (.behaviour interface)))
                       (event (.event trigger))
                       (i-trigger (make <trigger> :port #f :event event))
                       (i-state (get-state interface)))
                  (receive (i-state i-trace)
                      (process-event interface i-ast i-state i-trigger)
                    (set-state! interface i-state) ;; TODO: keep with trace
                   (values state #f ast #f (append i-trace trace))))
                (values state #f ast #f trace))))
         (($ <assign> identifier expression)
          (stderr "****assign: ~a := ~a\n" (->string identifier) (->string expression))
          (receive (new-state new-ast new-action return new-trace)
              (eval-function-expression model ast state event (cons ast trace) expression)
            (values (var! new-state identifier return) #f #f return new-trace)))
         (($ <variable> type identifier expression)
          (receive (new-state new-ast new-action return new-trace)
              (eval-function-expression model ast state event (cons ast trace) expression)
            (stderr "****init: ~a := ~a ==> ~a\n" (->string identifier) (->string expression) (->string return))
            (values (var! new-state identifier return) #f #f return new-trace)))
         (($ <if> expression statement else)
          (if (eval-expression model state expression)
              (process model statement state event (cons ast trace))
              (process model else state event (cons ast trace))))
         (($ <if> expression statement)
          (if (eval-expression model state expression)
              (process model statement state event (cons ast trace))
              (values state #f #f #f (cons ast trace))))
         (($ <compound> '()) (values state '() #f #f trace))
         (#f (values state '() #f #f trace))
         (($ <compound> elements)
          (let ((declarative? (om:declarative? (car elements))))
            (let loop ((statements elements) (loop-state state) (loop-return #f) (loop-trace (cons ast trace)) (frame 0))
              (if (null? statements)
                  (values (drop loop-state frame) statements #f loop-return loop-trace)
                  (let ((statement (car statements)))
                    (if declarative?
                        (receive (new-state new-ast new-action new-return new-trace)
                            (process model statement state event '())
                          (if (pair? new-trace)
                              (loop (cdr statements) new-state new-return (append new-trace trace) frame)
                              (loop (cdr statements) loop-state new-return loop-trace frame)))
                        (let ((loop-state (if (is-a? statement <variable>)
                                              (acons (.name statement)
                                                     #f loop-state) loop-state))
                              (frame (if (is-a? statement <variable>)
                                         (1+ frame) frame)))
                          (receive (new-state new-ast new-action new-return new-trace)
                            (process model statement loop-state event '())
                            (loop (cdr statements) new-state new-return (append new-trace loop-trace) frame)))))))))
         (($ <return> expression)
          (let ((return (eval-expression model state expression)))
            (values state #f #f return (cons ast trace))))
         (($ <reply> expression)
          (stderr "****reply: ~a\n" (->string expression))
          (let ((reply (eval-expression model state expression)))
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
