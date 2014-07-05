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

(define-module (language asd simulate)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd gaiag)
  :use-module (language asd misc)
  :use-module (language asd parse)
  :use-module (language asd pretty-print)
  :use-module (language asd reader)

  :export (ast->a
           explore-space
           walk-trail))

(define debug? #f)
(define (debug . x) #t)
(if debug?
    (set! debug stderr))

(define *model* #f)

(define (ast-> ast)
  (and=> (ast:interface ast) simulate-model)
  (and=> (ast:component ast) simulate-model)
  "")

(define (variable-state variable . value) 
  (cons (ast:name variable)
        (eval-expression '() '()
                         (if (pair? value) 
                             (car value) 
                             (ast:expression variable)))))

(define (state-vector model)
  (map variable-state (ast:variables model)))

(define (var state identifier) (assoc-ref state identifier))

(define (var! state identifier value) 
  (assoc-set! 
   (filter (lambda (x) ((negate eq?) identifier (car x))) state) 
   identifier value))

(define i 0)
(define *state-space* '(()))

(define (simulate-model model)
   (stderr "\n\n>>>simulating: ~a ~a --> ~a\n" (ast:class model) (ast:name model) (map ->string ((ast:find-events ast:in?) model)))
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
        (apply append (map json-trace trace))
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
        (model (ast:name *model*)))
    (cons (->symbol event)
          (list
           (list 'state (map (lambda (x) (list (car x) (cdr x)))  state))
           (list 'trace (map trace-location steps))))))


;; JSON output mangling disaster area

;; FIXME: mangling the trace output into the current json format takes
;; about as much effort as producing it?
(define (from event statement)
  (if (ast:on? statement)
      (if (pair? event)
          (ast:port-name event)
          'in)
      (ast:name *model*)))

(define (to statement)
  (if (ast:on? statement)
      (ast:name *model*)
      (or (and-let* (((ast:action? statement))
                     (event (ast:event statement))     
                     ((pair? event)))
                    (ast:port-name event))
          'out)))

(define (event statement)
  (if (ast:on? statement)
      (ast:event-name (ast:event statement))
      (or (and-let* (((ast:action? statement))
                     (event (ast:event statement))     
                     ((pair? event)))
                    (ast:port-name event))
          'out)))

(define (json-location ast)
  (alist->hash-table
   (or (and-let* ((loc (source-location ast))
                  (properties (source-location->source-properties loc)))
                 `((file . ,(assoc-ref properties 'filename))
                   (line . ,(assoc-ref properties 'line))
                   (colum . ,(assoc-ref properties 'column))))
      '())))

(define (json-trace tracepoint)
  (let* ((event (car tracepoint))
         (state (cadr tracepoint))
         (steps (cddr tracepoint))
         (model (ast:name *model*)))
    (let loop ((statements steps))
      (let* ((statement (if (null? statements) #f (car statements)))
             (class (and=> statement ast:class))
             (type (if (eq? class 'assign) 'update 'transition))
             (message
              (alist->hash-table
               (if (eq? type 'update)
                   (let ((variable (ast:variable statement)))
                     `((type . update)
                       (comp . ,model)
                       (,variable . ,(->symbol (var state variable)))))
                   (let ((kind (assoc-ref '((#f . return) 
                                            (on . call)
                                            (action . call))
                                          (ast:class statement)))
                         (json-event (cond 
                                      ((ast:on? statement) (ast:event-name event))
                                      ((ast:action? statement) (ast:event-name (ast:event statement)))
                                      (else 'return))))
                     `((type . transition)
                       (kind . ,kind)
                       (from . ,(from event statement)) 
                       (to  . ,(to statement))
                       (event . ,json-event)
                       (location . 
                                 ,(alist->hash-table
                                   `((begin . ,(json-location statement))
                                     (end . ,(json-location statement)))))))))
              )) ;;TODO
        (if (not statement)
            (list message)
            (cons message (loop (cdr statements))))))))

(define (event->ast symbol)
  "if SYMBOL is of form INTERFACE.TRIGGER, produce (trigger PORT EVENT)"
  (or (and-let* ((string (symbol->string symbol))
                 (interface-trigger (string-split string #\.))
                 ((=2 (length interface-trigger))))
               (cons 'trigger (map string->symbol interface-trigger)))
      symbol))

(define (seen-key state ast)
  (when (not (equal? ast (ast:statement (ast:behaviour *model*))))
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
  (when (not (equal? ast (ast:statement (ast:behaviour *model*))))
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

(define (next-todo-space-explorer model state ast)
  (let ((events ((ast:find-events ast:in?) model)))
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
    (lambda (model state ast-dont-care)
      (if (null? trail)
          (cons #f '())
          (let ((event (car trail)))
            (set! trail (cdr trail))
            (cons (if (eq? state 'initial) (state-vector model) state)
                  (list event)))))))

(define* (simulate model :optional
                   (next-todo next-todo-space-explorer)
                   (ast (ast:statement (ast:behaviour model))))
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
              (cons (cons event (cons state trace)) (loop (next-todo model new-state ast)))))))))

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
          (receive (state ast action t)
              (process ast state event trace)
            (if (not t) (car t))
            (continue state ast action t))))))

(define (eval-expression ast state expression)
  (match expression
    (#f #f)
    (#t #t)
    ('false #f)
    ('true #t)
    (('value 'state field)
     (eq? (ast:field (var state 'state)) field)) ;;; FIXME name resolution
    (('value identifier value) expression)
    (('! expr) (not (eval-expression ast state expr)))
    ('otherwise 
     (let* ((parent (ast:parent *model* ast))
            (guards ((ast:statements-of-type 'guard) parent))
            (expressions (map ast:expression guards)))
       (receive (otherwise rest) (partition (lambda (x) (eq? x 'otherwise)) expressions)
         (if (not (equal? otherwise '(otherwise)))
             (throw 'programming-error "parent missing otherwise"))
         ;; otherwise is true if none of the other guards is
         (not (apply for (map (lambda (x) (eval-expression ast state x)) rest))))))
    ((? symbol?) (eval-expression ast state (var state expression)))
    (_ (throw 'match-error  (format #f "~a:expression no match: ~a\n" (current-source-location) expression)))))

(define* (process ast state event trace)
;;;  (stderr "PROCESS: [~a] ~a\n" event ast)
  (set! i (1+ i))
  (if (> i 2000) 
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*)))
  (and state
       (match ast
         (('on t statement) 
          (debug "[~a] on: ~a: ---> ~a\n" event t (member event t equal?))
          (if (member event t equal?)
              (process statement state event (cons ast trace))
              (values state #f #f trace)))
         (('guard expression statement)
          (debug "guard: ~a? --> ~a =====> ~a\n" expression (eval-expression ast state expression) statement)
          (if (eval-expression ast state expression) 
              (process statement state event (cons ast trace)) 
              (values state #f #f trace)))
         (('action 'illegal) (values state #f #f (cons ast trace)))
         (('action t ...) 
          (stderr "****action: ~a\n" (->string t))
          (values state #f ast (cons ast trace)))
         (('assign identifier expression)
          (stderr "****assign: ~a := ~a\n" (->string identifier) (->string expression))
          (values (var! state identifier (eval-expression ast state expression)) #f #f (cons ast trace)))
         (('if expression statement else) 
          (if (eval-expression ast state expression) 
              (process statement state event (cons ast trace)) 
              (process else state event (cons ast trace))))
         (('if expression statement)
          (if (eval-expression ast state expression) 
              (process statement state event (cons ast trace)) 
              (values state #f #f trace)))
         (('compound h t ... )
          (debug "\n\n******COMPOUND******\nh:~a\n" h)
          (debug "t:~a\n" t)
          (let ((declarative? (ast:declarative? h)))
            (debug "d:~a\n" declarative?)
            (let loop ((statements (cdr ast)) (loop-state state) (loop-trace trace))
              (debug "\n[~a] " (comma-space-join (map ->string state)))
              (if (null? statements)
                  (values loop-state statements #f loop-trace)
                  (receive (new-state new-ast new-action new-trace) 
                      (if declarative?
                          (process (car statements) state event '())
                          (process (car statements) loop-state event '()))

                    (debug "==> [~a]\n" (comma-space-join (map ->string new-state)))
                    (debug "==> ast:~a\n" new-ast)
                    (debug "==> ~a [~a]\n" new-trace (car (car statements)))
                    (if declarative?
                        (if (pair? new-trace)
                            (loop (cdr statements) new-state (append new-trace trace))
                            (loop (cdr statements) loop-state loop-trace))
                        (loop (cdr statements) new-state (append new-trace loop-trace))))))))
         (('compound) (values state '() #f trace))
         (_ (throw 'match-error  (format #f "~a: process: no match: ~a\n"  (current-source-location) ast)))))))

(define (->string src)
  (match src
    (#f "false")
    (#t "true")
    (('value type field) (->string (list (->string type) "." field)))
    ((identifier 'value type field) (->string (list (->string identifier) " = " (->string type) "." field)))
    (('trigger port event) (->string (list port "." event)))
    ((identifier 'field x y) (string-join (list (->string identifier)  "=" (->string (cdr src)))))
    ((h ... t) (apply string-append (map ->string src)))
    ((h . t) (string-join (list (->string h) "=" (->string t))))
    (((h ... t)) (->string (car src)))
    (_ ((@ (language asd misc) ->string) src))))

(define (->symbol src)
  (match src
    (#f 'false)
    (#t 'true)
    (('value type field) (->symbol (list (->string type) "." field)))
    (('trigger port event) (->symbol (list port "." event)))
    ((identifier 'value type field) (->symbol (list (->symbol identifier) " = "(->symbol type) "." field)))
    ((h ... t) (apply symbol-append (map ->symbol src)))
    ((h . t) (list (->symbol h) '= (->symbol t)))
    (((h ... t)) (->symbol (car src)))
    ((? string?) (string->symbol src))
    ((? symbol?) src)))

(define (event< a b)
  (match a
    ((? symbol?) (symbol< a b))
    ((h ... t) (list< a b))))
