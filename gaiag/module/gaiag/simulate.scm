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
  :use-module (ice-9 optargs)  
  :use-module (ice-9 and-let-star)
  :use-module (srfi srfi-1)

  :use-module (gaiag list match)
  :use-module (language dezyne location)

  :use-module (gaiag gaiag)
  :use-module (gaiag json-trace)
  :use-module (gaiag misc)
  :use-module (gaiag evaluate)

  :use-module (gaiag pretty-print)
  :use-module (gaiag reader)

  :use-module (gaiag resolve)
  ;;  :use-module (gaiag wfc)

  :use-module (gaiag ast)

  :export (ast->
           explore-space
           mangle-trace
           walk-trail
           event->ast
           ->symbol
           simulate:om))

(define MAX-ITERATIONS 10000)
(define (debug . x) #t)
;;(define debug stderr)

(define (ast-> ast)
  (let ((name (and=> (option-ref (parse-opts (command-line)) 'model #f)
                     string->symbol)))
    (or (and-let* ((om ((om:register simulate:om) ast #t))
                   (models (filter (lambda (x) (or (is-a? x <interface>)
                                                   (is-a? x <component>)))
                                   (.elements om)))
                   (models (null-is-#f (filter .behaviour models)))
                   (models (if name (filter (om:named name) models) models))
                   (c-i (append (filter (is? <component>) models) models)))
                  (simulate-model (car c-i)))
        "")))

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
    (pretty-print (mangle-trace model trace))
    )
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
  (simulate model (next-todo-trail-walker) (map event->ast trail)))

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
                 (port-event (map string->symbol port-event))
                 ((=2 (length port-event))))
                (if (or (eq? (car port-event) 'return)
                        (eq? (cadr port-event) 'return))
                    event
                    (make <trigger>
                      :port (car port-event)
                      :event (cadr port-event))))
      (if (or (eq? event 'return)
              (=2 (length (string-split (symbol->string event) #\_))))
          event
          (make <trigger> :port #f :event event))))

(define (seen-key model state ast)
  (when (not (equal? (om->list ast) (om->list (.statement (.behaviour model))))
             )
    ;; it's a bug -for now- if we store a 'seen' state with a non-top
    ;; AST: only actions return mid-statements and they are continued
    ;; we alway continue until the end
    ;;(stderr "AST:~a\n" ast)
    (stderr "NOT EQUAL\n")
    (stderr "ast:\n")
    (pretty-print (om->list ast))
    (stderr "statement\n")
    (pretty-print (om->list (.statement (.behaviour model))))
    (throw 'barf-seen-about-non-top-ast))
  (list state ast))

(define (seen-key-state key) (caar key))
(define (seen-key-ast key) (cadar key))

(define (seen model state ast)
  (set! i (1+ i))
  (if (> i MAX-ITERATIONS)
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
        (let ((value (delete-duplicates (sort (cons event events) om:<))))
          (set! *state-space* (assoc-set! *state-space* key value))))))

(define (state-ast-todo model state ast events)
  (let ((done (seen model state ast)))
    (filter (negate (lambda (x) (member x done equal?))) events)))

(define (next-value info action) #t)
(define (next-return info port) #t)
(define (set-return! info value) #t)

;; FIXME: TODO: implement next-value for state explorer
(define (next-todo-space-explorer model info)
  (let ((events (om:find-triggers model))
        (state (.state info))
        (ast (.ast info)))
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

(define (next-todo-trail-walker)
  (set! next-value
        (lambda (info action)
          (let ((trail (.trail info)))
           (if (null? trail)
               #f
               (let* ((trigger (car trail))
                      (value (make <literal>
                               :type (.port trigger)
                               :field (.event trigger))))
                 ;;;(stderr "****value := ~a\n" (->string value))
                 ;;(set! (.trail info) (cdr trail))
                 (list-set! info 1 (cdr trail)) ;; FIXME
                 value)))))
  (set! next-return
        (lambda (info port)
          (let ((trail (.trail info))
                (reply (.reply info)))
            ;;;(stderr "RETURN[~a.~a]: ~a\n" port reply trail)
            (if (null? trail)
                #f
                (let* ((next (car trail))
                       (return (if port (symbol-append port '. reply) reply))
                       (matches? (lambda (x) (eq? x return))))
                  ;;;(stderr "NEXT RETURN: ~a\n" next)
                  ;;(set! reply 'return)
                  (list-set! info 4 'return) ;; FIXME
                  ;;(stderr "return: ~a\n" return)
                  (match next
                    ((? matches?)
                     ;;;(stderr "****return := ~a\n" (->string return))
                     ;;(set! trail (cdr trail))
                     (list-set! info 1 (cdr trail)) ;; FIXME
                     return)
                    (_ #f)))))))
  (set! set-return!
        (lambda (info value)
          ;;;(stderr "SETTING: ~a\n" (->symbol value))
          ;; (set! (.reply info) (->symbol value))
          (list-set! info 4 (->symbol value)) ;; FIXME
          ))
  (lambda (model info)
    (let ((trail (.trail info))
          (state (.state info)))
      (if (null? trail)
          (cons #f '())
          (let ((event (car trail)))
            ;;(set! trail (cdr trail))
            (list-set! info 1 (cdr trail)) ;; FIXME
            ;;(stderr "NEXT TODO[~a]: ~a\n" event info)
            (cons (if (eq? state 'initial) (state-vector model) state)
                  (list event)))))))

(define* (simulate model :optional (next-todo next-todo-space-explorer) (trail '()))
  (set! *state-space* '(()))
  (set! i 0)
  (let* ((ast ((compose .statement .behaviour) model))
         (info (make <info> :trail trail :ast ast :state 'initial :reply 'return :return #f :trace '())))
    (let loop ((info info))
      (let* ((state-todo (next-todo model info))
             (state (car state-todo))
             (todo (null-is-#f (cdr state-todo))))
        (if (or (not state) (not todo))
            '()
            (let* ((event (car todo))
                   (infos (process-event model event (make <info> :trail (.trail info) :ast ast :state state)))
                   (info (if (and infos (=1 (length infos))) (car infos) (make <info>))))
              (cons
               (cons (->symbol event) (cons state (.trace info)))
               (loop info))))))))

(define (state->string state)
  (comma-space-join (map (lambda (s) (->string (list (car s) "=" (cdr s)))) state)))

;; (define-class <info> ()
;;   (trail :accessor .trail :init-form (list) :init-keyword :trail)
;;   (ast :accessor .ast :init-form (list) :init-keyword :ast)
;;   (state :accessor .state :init-form (list) :init-keyword :state)
;;   (reply :accessor .reply :init-form (list) :init-keyword :reply)
;;   (return :accessor .return :init-form (list) :init-keyword :return)
;;   (trace :accessor .trace :init-form (list) :init-keyword :trace)))

(define <info> 'info)
(define (make-<info> . args)
  (let-keywords
   args #f
   ((trail '())
    (ast '())
    (state '())
    (reply 'return)
    (return #f)
    (trace '()))
   (cons <info> (list trail ast state reply return trace))))

(define (.trail o)
  (match o
    (('info trail ast state reply return trace) trail)))

(define (.ast o)
  (match o
    (('error ast message) ast)
    (('info trail ast state reply return trace) ast)))

(define (.state o)
  (match o
    (('info trail ast state reply return trace) state)))

(define (.reply o)
  (match o
    (('info trail ast state reply return trace) reply)))

(define (.return o)
  (match o
    (('info trail ast state reply return trace) return)))

(define (.trace o)
  (match o
    (('info trail ast state reply return trace) trace)))

(define (process-event model event info)
  ;;(stderr "process-event[~a] " (state->string (.state info)))
  ;;(stderr "event: ~a\n" (->string event))
  (seen! model (.state info) (.ast info) event)
  (map
   (lambda (info)
     (make <info> :trail (.trail info) :state (.state info) :reply (.reply info) :trace (reverse (.trace info))))
   (process model event info)))

(define ((variable? model) identifier) (om:variable model identifier))
(define ((extern? model) var) (om:extern model (.type var)))

(define (om:member-names model)
  (map .name (filter (negate (extern? model)) (om:variables model))))

(define (eval-function-expression model event info)
  (let* ((members (om:member-names model))
         (state (.state info))
         (ast #f)
         (expression (.ast info))
         (reply (.reply info))
         (trace (.trace info)))
    (match expression
      (($ <call> function ('arguments arguments ...))
       (let* ((f (om:function model function))
              (formals (map .name ((compose .elements .formals .signature) f)))
              (statement (.statement f))
              (pairs (zip formals arguments))
              (state (let loop ((pairs pairs) (state state))
                       (if (null? pairs)
                           state
                           (loop (cdr pairs) (acons (caar pairs)
                                                    (eval-expression model state (cadar pairs)) state)))))
              (info (make <info> :trail (.trail info) :state (.state info) :ast (.ast info) :return #f :reply (.reply info) :trace (list f)))
              (infos (process model event info))
              (info (if (and infos (=1 (length infos))) (car infos) (make <info>))))
         info))
      (($ <action> ($ <trigger> port event))
       (let ((return (eval-expression model state (next-value info event))))
         (make <info> :trail (.trail info) :ast ast :state state :reply reply :return return :trace trace)))
      (_ (let ((return (eval-expression model state expression)))
           (make <info> :trail (.trail info) :ast ast :state (.state info) :reply (.reply info) :return return :trace (.trace info)))))))

(define (process model event info)
  ;;(stderr "PROCESS on ~a: ~a\n" (->string event) info)
  (set! i (1+ i))
  (if (> i MAX-ITERATIONS)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*))))
  (let ((trail (.trail info))
        (state (.state info))
        (reply (.reply info))
        (trace (.trace info)))
    (and-let*
     ((ast (.ast info)))
     (match ast
       (($ <on> ('triggers t ...) statement)
        (if (member event t equal?)
            (let* ((info (make <info> :trail trail :ast statement :state state :reply reply :return #f :trace '()))
                   (infos (process model event info))
                   (info (if (and infos (=1 (length infos))) (car infos) (make <info>))))
              (if (pair? (.trace info))
                  (let ((return (next-return info (.port event))))
                    (list (make <info> :trail (.trail info) :ast (.ast info) :state (.state info) :reply (.reply info) :return #f :trace (append (list (list 'return return)) (.trace info) (cons ast trace)))))
                  (list (make <info> :trail (.trail info) :ast #f :state (.state info) :reply (.reply info) :return #f :trace '()))))
            (list (make <info> :trail trail :ast #f :state state :reply (.reply info) :return #f :trace '()))))
       (($ <guard> expression statement)
        (if (eval-expression model state expression)
            (let* ((info (make <info> :trail trail :ast statement :state state :reply reply :return #f :trace '()))
                   (infos (process model event info))
                   (info (if (and infos (=1 (length infos))) (car infos) (make <info>))))
              (if (pair? (.trace info))
                  (list (make <info> :trail (.trail info) :ast (.ast info) :state (.state info) :reply (.reply info) :return #f :trace (append (.trace info) (cons ast trace))))
                  (list (make <info> :trail (.trail info) :ast #f :state (.state info) :reply (.reply info) :return #f :trace '()))))
            (list (make <info> :trail trail :ast #f :state state :reply reply :return #f :trace '()))))
       (($ <illegal>)
        (list (make <info> :trail trail :ast #f :state state :reply reply :return #f :trace (cons ast trace))))
       (($ <action> trigger)
        (let* ((trace (cons ast trace))
               (port (.port trigger)))
          (if port
              (let* ((interface (simulate:import (.type (om:port model port))))
                     (i-ast (.statement (.behaviour interface)))
                     (event (.event trigger))
                     (i-trigger (make <trigger> :port #f :event event))
                     (i-state (get-state interface))
                     (i-info (make <info> :trail trail :ast i-ast :state i-state :reply reply :return #f :trace '()))
                     (i-infos (process-event interface i-trigger i-info))
                     (i-info (if (and i-infos (=1 (length i-infos))) (car i-infos) (make <info>))))
                (set-state! interface (.state i-info)) ;; FIXME: keep with trace
                (next-value i-info trigger)
                (list (make <info> :trail (.trail i-info) :ast #f :state state :reply reply :return #f :trace (append (reverse (.trace i-info)) trace))))
              (list (make <info> :trail trail :ast #f :state state :reply reply :return #f :trace trace)))))
       (($ <assign> identifier expression)
        (let* ((info (make <info> :trail trail :ast expression :state state :reply  reply :return #f :trace (cons ast trace)))
               (info (eval-function-expression model event info)))
          ;; FIXME: doorgeefluik
          (list (make <info> :trail (.trail info) :ast #f :state (var! (.state info) identifier (.return info)) :reply (.reply info) :return #f :trace (.trace info)))))
       (($ <call> function ('arguments arguments ...))
        (let* ((info (make <info> :trail trail :ast ast :state state :reply reply :return #f :trace (cons ast trace)))
               (info (eval-function-expression model event info)))
          ;; FIXME: doorgeefluik
          (list (make <info> :trail (.trail info) :ast #f :state (.state info) :reply (.reply info) :return (.return info) :trace (.trace info)))))
       (($ <variable> type identifier expression)
        (let* ((info (make <info> :trail trail :ast expression :state state :reply  reply :return #f :trace (cons ast trace)))
               (info (eval-function-expression model event info)))
          ;; FIXME: doorgeefluik
          (list (make <info> :trail (.trail info) :ast #f :state (var! (.state info) identifier (.return info)) :reply (.reply info) :return #f :trace (.trace info)))))
       (($ <if> expression then #f)
        (if (eval-expression model state expression)
            (process model event (make <info> :trail trail :ast then :state state :reply reply :return #f :trace (cons ast trace)))
            (make <info> :trail trail :ast #f :state state :reply reply :return #f :trace (cons ast trace))))
       (($ <if> expression then else)
        (if (eval-expression model state expression)
            (process model event (make <info> :trail trail :ast then :state state :reply reply :return #f :trace (cons ast trace)))
            (process model event (make <info> :trail trail :ast else :state state :reply reply :return #f :trace (cons ast trace)))))
       (('compound) (list (make <info> :trail trail :ast '() :state state :reply reply :return #f :trace trace)))
       (#f (list (make <info> :trail trail :ast '() :state state :reply reply :return #f :trace trace)))
       ((and ('compound statements ...) (? om:declarative?))
        (let loop ((statements statements) (loop-infos '()))
          ;;(stderr "DLOOP: ~a\n" loop-infos)
          (if (null? statements)
              (let* ((loop-info (if (pair? loop-infos) (car loop-infos) info))
                     (trace (if (pair? loop-infos)
                                (if (=1 (length loop-infos))
                                    (append (.trace loop-info) (cons ast trace))
                                    (and (stderr "traces:\n")
                                         (pretty-print (map reverse loop-info) (current-error-port))
                                         (throw 'non-det "TODO")))
                               '())))
                (list (make <info> :trail (.trail loop-info) :ast '() :state (.state loop-info) :reply (.reply loop-info) :return #f :trace trace)))
              (let* ((statement (car statements))
                     (info (make <info> :trail trail :ast statement :state state :reply reply :return #f :trace '()))
                     (infos (process model event info))
                     (info (if (and infos (=1 (length infos))) (car infos) (make <info>))))
                (if (pair? (.trace info))
                    (loop (cdr statements) (cons info loop-infos))
                    (loop (cdr statements) loop-infos))))))
       (('compound statements ...)
        (let loop ((statements statements) (loop-info (make <info> :trail trail :ast ast :state state :reply reply :return #f :trace (cons ast trace))) (frame 0))
          ;;(stderr "LOOP: ~a\n" loop-info)
          (if (null? statements)
              (list (make <info> :trail (.trail loop-info) :ast '() :state (drop (.state loop-info) frame) :reply (.reply loop-info) :return #f :trace (.trace loop-info)))
              (let ((statement (car statements)))
                (let* ((state (if (is-a? statement <variable>)
                                  (acons (.name statement)
                                         #f (.state loop-info)) (.state loop-info)))
                       (frame (if (is-a? statement <variable>)
                                  (1+ frame) frame))
                       (info (make <info> :trail (.trail loop-info) :ast statement :state (.state loop-info) :reply (.reply loop-info) :return #f :trace '()))
                       (infos (process model event info))
                       (info (if (and infos (=1 (length infos))) (car infos) (make <info>)))
                       (info (make <info>
                               :trail (.trail info)
                               :state (.state info)
                               :ast (.ast info)
                               :reply (.reply info)
                               :return #f
                               :trace (append (.trace info) (.trace loop-info)))))
                  (loop (cdr statements) info frame))))))
       (($ <return> expression)
        (let ((return (eval-expression model state expression)))
          (list (make <info> :trail trail :ast #f :state state :reply reply :return return :trace (cons ast trace)))))
       (($ <reply> expression)
        (let ((return (eval-expression model state expression)))
          (set-return! info return)
          (list (make <info> :trail trail :ast ast :state state :reply reply :return #f :trace (cons ast trace)))))))))

(define (->string src)
  (match src
    (#f "false")
    (#t "true")
    (($ <expression> expression) (->string expression))
    (($ <var> identifier) (symbol->string identifier))
    (($ <field> type field) (->string (list (->string type) "." field)))
    (($ <literal> scope type field) (->string (list (->string type) "_" (->string field))))
    (($ <trigger> #f event) (->string event))
    (($ <trigger> port event) (->string (list port "." event)))
    (('type name) (->string name))
    (($ <call> function ('arguments arguments ...)) (->string (list function "("  (comma-join arguments) ")" )))
    ((h ... t) (apply string-append (map ->string src)))
    (((h ... t)) (->string (car src)))
    (_ ((@ (gaiag misc) ->string) src))))

(define (->symbol src)
  (match src
    (#f 'false)
    (#t 'true)
    (($ <expression> expression) (->symbol expression))
    (($ <var> identifier) identifier)
    (($ <field> type field) (->symbol (list (->symbol type) "." field)))
    (($ <literal> scope type field) (->symbol (list (->symbol type) "_" (->symbol field))))
    (($ <trigger> #f event) (->symbol event))
    (($ <trigger> port event) (->symbol (list port "." event)))

    ((h ... t) (apply symbol-append (map ->symbol src)))
    (((h ... t)) (->symbol (car src)))
    ((? string?) (string->symbol src))
    ((? symbol?) src)))
