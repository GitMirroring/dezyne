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
                  (simulate (car c-i)))
        "")))

(define (simulate:import name)
  (om:import name simulate:om))

(define (simulate:om ast)
  ((compose ;;ast:wfc
    ast:resolve ast->om) ast))

(define i 0)
(define *state-space* '(()))

(define (simulate model)
  (stderr "\n\n>>>simulating: ~a ~a --> ~a\n" (ast-name model) (.name model) (map ->string (om:find-triggers model)))
  (and-let* ((((is? <component>) model))
             (interfaces (map simulate:import
                              (map .type ((compose .elements .ports) model))))))
  (let* ((trail (option-ref (parse-opts (command-line)) 'trail #f))
         (trace (if trail
                    (walk-trail model (with-input-from-string trail read))
                    (explore-space model)))
         (foo (stderr "RESULT:\n"))
         ;;(foo (pretty-print trace (current-error-port)))
         (trace (filter (lambda (tp) (pair? (cddr tp))) trace)))
    (pretty-print (mangle-trace model trace)))
  (newline)
  (stderr "state space: ~a\n" (length *state-space*))
  "")

(define (explore-space model)
  (simulate-model model))

(define (walk-trail model trail)
  (simulate-model model (next-todo-trail-walker) (map event->ast trail)))

(define* (simulate-model model :optional (next-todo next-todo-space-explorer) (trail '()))
  (set! *state-space* '(()))
  (set! i 0)
  (let* ((ast ((compose .statement .behaviour) model))
         (info (make <info> :trail trail :ast ast :state 'initial)))
    (let loop ((info info) (path '()))
      (stderr "SIM0: ~a\n" (.trail info))
      (let* ((state-todo (next-todo model info))
             (state (car state-todo)) ;; FIXME? What about state-alist?
             (todo (cdr state-todo)))
        (stderr "SIM[~a]: ~a\n" todo (.trail info))
        (if (null? todo)
            (reverse path)
            (let* ((event (car todo))
                   (infos (process-event model event (clone <info> info :ast ast :state state)))
                   (infos (if (null? (prune infos)) (list (clone <info> info :trail '())) infos))
                   (foo (stderr "TRACES: ~a\n" (length infos)))
                   (infos (stable-sort infos (lambda (a b) (< (length (.trace a))
                                                              (length (.trace b))))))
                   (infos (delete-duplicates infos equal?))
                   (foo (stderr "UNIQUE: ~a\n" (length infos)))
                   (foo (map
                            (lambda (info count)
                              (stderr "R ~a:\n" count)
                              (map trace-location (.trace (car infos))) (current-error-port))
                            infos (iota (length infos)))))
              (apply append
                     (map
                      (lambda (info)
                        (loop info
                              (cons
                               (cons (->symbol event) (cons state (.trace info)))
                               path)))
                      infos))))))))

(define* (process-event model event info :optional (reverse identity))
  (stderr "process-event[~a ~a] " (.name model) (state->string (.state info)))
  (stderr "event: ~a\n" (->string event))
  (seen! model (.state info) (.ast info) event)
  (map
   (lambda (info)
     (let* ((trace (.trace info))
            (trace (match trace
                     (($ <error>) trace)
                     (()
                      (stderr "EMPTY\n")
                      (list 'error (->string "invalid event: " event)))
                     (_ (reverse trace))))
            (info (if (not (eq? reverse identity))
                      (set-state info model (.state info))
                      info)))
       (clone <info> info :trace trace)))
   (process model event info)))

(define ((variable? model) identifier) (om:variable model identifier))
(define ((extern? model) var) (om:extern model (.type var)))

(define (om:member-names model)
  (map .name (filter (negate (extern? model)) (om:variables model))))

(define (eval-function-expression model event info)
  (let* ((members (om:member-names model))
         (expression (.ast info)))
    (match expression
      (($ <call> function ('arguments arguments ...))
       (let* ((f (om:function model function))
              (formals (map .name ((compose .elements .formals .signature) f)))
              (statement (.statement f))
              (pairs (zip formals arguments))
              (state (let loop ((pairs pairs) (state (.state info)))
                       (if (null? pairs)
                           state
                           (loop (cdr pairs) (acons (caar pairs)
                                                    (eval-expression model state (cadar pairs)) state)))))
              (info (clone <info> info :trace (list f)))
              (infos (process model event info))
              (infos (prune infos)))
         infos))
      (($ <action> ($ <trigger> port event))
       (let* ((info (next-value info event))
              (return (eval-expression model (.state info) (.return info))))
         (list (clone <info> info :ast #f :return return))))
      (_ (let ((return (eval-expression model (.state info) expression)))
           (list (clone <info> info :ast #f :return return)))))))

;;(define (trace? info) ((negate (is? <error>)) (null-is-#f (.trace info))))
(define (trace? info) (null-is-#f (.trace info)))
(define (prune infos) (filter trace? infos))

(define (sort-infos infos)
  (let ((infos (stable-sort infos (lambda (a b)
                                    (cond
                                     ((and (not (.error a)) (.error b)) #t)
                                     ((not (.error b)) #f)
                                     (else (> (length (.trace a))
                                              (length (.trace b)))))))))
    (if (null? infos) '()  (car infos))))

(define (process model event info)
  (stderr "PROCESS[~a]: ~a ~a\n" (.name model) (ast-name (.ast info)) (map ->symbol (.trail info)))
  ;;(pretty-print (map trace-location (.trace info)) (current-error-port))  
  (set! i (1+ i))
  (if (> i MAX-ITERATIONS)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*))))
  (let ((ast (.ast info))
        (state (.state info))
        (trace (.trace info)))
    (match (.ast info)
      (#f '())
      (($ <on> ('triggers t ...) statement)
       (if (member event t equal?)
           (let* ((port (.port event))
                  (o-info (clone <info> info :ast statement :trace '()))
                  (infos
                   (if (and port
                            (eq? (.name (om:port model)) port))
                       (let*
                           ((interface (simulate:import (.type (om:port model))))
                            (i-ast (.statement (.behaviour interface)))
                            (i-trigger (make <trigger> :port #f :event (.event event)))
                            (i-state (get-state o-info interface))
                            (i-info (clone <info> o-info :ast i-ast :state i-state :trace '()))
                            (i-infos (process-event interface i-trigger i-info reverse))
                            (i-infos (prune i-infos))
                            (infos (map
                                    (lambda (i-info)
                                      (let ((i-info (set-state i-info interface (.state i-info))))
                                        (clone <info> o-info :state-alist (.state-alist i-info))))
                                    i-infos))
                            (infos (apply append
                                          (map (lambda (info)
                                                 (process model event info))
                                               infos)))
                            (infos (map (lambda (info)
                                          (let loop ((i info))
                                            (stderr "q: ~a\n" (.q info))
                                            (if (not (peeq i))
                                                i
                                                (begin
                                                  (stderr "flushing: ~a\n" (peeq i))
                                                  ;; TODO: run trigger
                                                  (loop (deq i)))
                                                )))
                                        infos)))
                         infos)
                       (process model event o-info)))
                  (infos (prune infos))
                  (infos (if (and port
                                  (not (eq? port (.name (om:port model)))))
                             (map (lambda (info) (clone <info> info :trace (cons ast (.trace info)))) infos)
                             (map
                              (lambda (info count)
                                (let* ((info (next-reply model info (.port event)))
                                       (reply (.reply info))
                                       (info (clone <info> info :reply 'return))
                                       (trace (.trace info))
                                       (return (rsp ast (make <return> :expression reply)))
                                       (trace (if (or (null? trace)
                                                      (eq? (ast-name trace) 'error))
                                                  trace
                                                  (append (cons ast trace) (list return)))))
                                  (clone <info> info :trace trace)))
                              infos (iota (length infos))))))
             infos)
           '()))
      (($ <guard> expression statement)
       (if (eval-expression model state expression)
           (let* ((g-info (clone <info> info :ast statement :trace '()))
                  (infos (process model event g-info))
                  (infos (prune infos))
                  (infos (map
                          (lambda (info)
                            (let* ((trace
                                    (append (cons ast trace) (.trace info))))
                              (clone <info> info :trace trace)))
                          infos)))
             infos)
           '()))
      (($ <illegal>) (list (clone <info> info :ast #f :trace (cons ast trace))))
      (($ <action> trigger)
       (let ((port (.port trigger))
             (o-info (clone <info> info)))
         (if (and port
                  (not (eq? port (.name (om:port model)))))
             (let* ((interface (simulate:import (.type (om:port model port))))
                    (i-ast (.statement (.behaviour interface)))
                    (i-trigger (make <trigger> :port #f :event (.event trigger)))
                    (i-state (get-state info interface))
                    (i-info (clone <info> o-info :ast i-ast :state i-state :trace '()))
                    (i-infos (process-event interface i-trigger i-info reverse))
                    (i-infos (filter trace? i-infos))
                    (i-infos (map
                              (lambda (i-info)
                                (let* ((port (.port trigger))
                                       (return (car (.trace i-info)))
                                       (i-info (set-state i-info interface (.state i-info))))
                                  (set-source-property! return 'port port)
                                  (clone <info> info :trail (.trail i-info) :ast #f :state-alist (.state-alist i-info) :trace (append (cons ast trace) (reverse (.trace i-info))))))
                              i-infos))
                    (i-infos (filter trace? i-infos)))
               i-infos)
             (let ((info (clone <info> info :trace (cons ast trace))))
               (if port ;; <action>: required out
                   (list (enq info trigger))
                   (list (next-action model info trigger)))))))
      ;; no cycle interface
      (($ <action> trigger)
       (let* ((info (clone <info> info :trace (cons ast trace)))
              (info (next-action model info trigger)))
         (list (clone <info> info :ast #f))))
      (($ <assign> identifier expression)
       (let* ((info (clone <info> info :ast expression :trace (cons ast trace)))
              (infos (eval-function-expression model event info)))
         (map
          (lambda (info)
            (clone <info> info :ast #f :state (var! (.state info) identifier (.return info))))
          infos)))
      (($ <call> function ('arguments arguments ...))
       (let* ((info (clone <info> info (cons ast trace))))
         (eval-function-expression model event info)))
      (($ <variable> type identifier expression)
       (let* ((info (clone <info> info :ast expression :trace (cons ast trace)))
              (infos (eval-function-expression model event info)))
         (map
          (lambda (info)
            (clone <info> info :ast #f :state (var! (.state info) identifier (.return info))))
          infos)))
      (($ <if> expression then #f)
       (if (eval-expression model state expression)
           (process model event (clone <info> info :ast then :trace (cons ast trace)))
           (clone <info> info :ast #f :trace (cons ast trace))))
      (($ <if> expression then else)
       (if (eval-expression model state expression)
           (process model event (clone <info> info :ast then :trace (cons ast trace)))
           (process model event (clone <info> info :ast else :trace (cons ast trace)))))
      (('compound) (list (clone <info> info :ast #f)))
      ((and ('compound statements ...) (? om:declarative?))
       (let loop ((statements statements) (loop-infos '()))
         (if (null? statements)
             (let* ((loop-infos (prune loop-infos)))
               loop-infos)
             (let* ((statement (car statements))
                    (info (clone <info> info :ast statement :trace '()))
                    (infos (process model event info))
                    (infos (prune infos)))
               (if (pair? infos)
                   (apply append
                          (map (lambda (info) (loop (cdr statements) (cons info loop-infos))) infos))
                   (loop (cdr statements) loop-infos))))))
      (('compound statements ...)
       (let loop ((statements statements) (loop-info (clone <info> info :trace (cons ast trace))) (frame 0))
         (if (null? statements)
             (list (clone <info> loop-info :ast '() :state (drop (.state loop-info) frame)))
             (let ((statement (car statements)))
               (let* ((state (if (is-a? statement <variable>)
                                 (acons (.name statement)
                                        #f (.state loop-info)) (.state loop-info)))
                      (frame (if (is-a? statement <variable>)
                                 (1+ frame) frame))
                      (info (clone <info> loop-info :ast statement :trace '()))
                      (infos (process model event info))
                      (infos (prune infos))
                      (infos (map
                              (lambda (info)
                                (clone <info> info :trace (append (.trace loop-info) (.trace info))))
                              infos)))
                 (apply append (map (lambda (info) (loop (cdr statements) info frame)) infos)))))))
      (($ <return> expression)
       (let ((return (eval-expression model state expression)))
         (list (clone <info> info :ast #f :return return :trace (cons ast trace)))))
      (($ <reply> expression)
       (let ((reply (eval-expression model state expression)))
         (list (clone <info> info :reply reply :trace (cons ast trace))))))))

(define (mangle-trace model trace)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        (append
         (list
          (json-init model)
          (json-state model (state-vector model)))
         (apply append (map (json-trace model) trace)))
        (map (demo-trace model) trace))))

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
           (list 'state (map (lambda (x) (list (car x) (cdr x))) state))
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

(define (next-action model info trigger)
  (let ((trail (.trail info)))
    (stderr "ACTION[~a ~a]: ~a\n" (.name model) trigger trail)
    (if (null? trail)
        info
        (let* ((action (car trail)))
          (stderr "ACTION: ~a\n" action)
          (stderr "TRIGGER: ~a\n" trigger)
          (if (or (equal? action trigger)
                  (and (is-a? trigger <trigger>)
                       (is-a? action <trigger>)
                       (not (.port trigger))
                       (eq? (.event trigger) (.event action))))
              (clone <info> info :trail (cdr (.trail info)))
              (begin
                (stderr "REJECT-TRACE: ACTION[~a ~a]: ~a\n" (.name model) action trigger)
                (clone <info> info :trail (cdr (.trail info)) :error #t)))))))

(define (next-value info action)
  (lambda (info action)
    (let ((trail (.trail info)))
      (if (null? trail)
          info
          (let* ((trigger (car trail))
                 (value (make <literal>
                          :type (.port trigger)
                          :field (.event trigger))))
            (clone <info> info :trail (cdr (.trail info)) :return value))))))

(define (next-reply model info port)
  (let* ((trail (.trail info))
         (reply (.reply info))
         (foo (stderr "REPLY[~a ~a.~a]: ~a\n" (.name model) port reply trail))
         (next (let loop () ;; WIP/FIXME: skip from trail if port does not match
                 ;; Alarm: enable has sensor.enable
                 ;; Alarm: IConsole: enable must skip SENSOR.enable
                 (stderr "REPLY-LOOP: ~a\n" trail)
                 (let ((event (and (pair? trail) (car trail))))
                   (if (or (is-a? model <component>)
                           (not (is-a? event <trigger>))
                           (not (.port event))
                           (eq? port (.port event)))
                       event
                       (begin
                         (set! trail (cdr trail)) ;; URG
                         (loop)))))))
    (stderr "RN: ~a\n" next)
    (if (null? trail)
        (clone <info> info :reply #f)
        (let* ((next (if (or (pair? next) port) next (last (symbol-split next #\.))))
               (reply (if port (symbol-append port '. reply) reply))
               (matches? (lambda (x) (eq? x reply))))
          (match next
            ((? matches?)
             (clone <info> info :trail (cdr trail) :reply reply))
            (_
             (stderr "REJECT-TRACE: REPLY[~a ~a]: ~a\n" (.name model) reply next)
             (clone <info> info :reply #f :error #t)))))))

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
  (lambda (model info)
    (let ((trail (.trail info))
          (state (.state info)))
      (if (null? trail)
          (cons #f '())
          (let ((event (car trail)))
            (list-set! info 1 (cdr trail)) ;; FIXME
            (cons (if (eq? state 'initial) (state-vector model) state)
                  (list event)))))))


(define (get-state info o)
  (or (assoc-ref (.state-alist info) (.name o))
      (state-vector o)))

(define (set-state info o state)
  (clone <info> info :state-alist (assoc-set! (.state-alist info) (.name o) state)))

(define (state->string state)
  (comma-space-join (map (lambda (s) (->string (list (car s) "=" (cdr s)))) state)))

(define (clone <info> o . args)
  (let-keywords
   args #f
   ((trail (.trail o))
    (ast (.ast o))
    (state (.state o))
    (q (.q o))
    (reply (.reply o))
    (return (.return o))
    (state-alist (.state-alist o))
    (trace (.trace o))
    (error (.error o)))
   (make <info> :trail trail :ast ast :state state :q q :reply reply :return return :state-alist state-alist :trace trace :error error)))

(define (enq info trigger)
  (if (and (pair? (.trail info))
           (equal? trigger (car (.trail info))))
      (clone <info> info :trail (cdr (.trail info)) :q (append (.q info) (list trigger)))
      (begin
        (stderr "REJECT-ENQ[~a]: ~a\n" trigger (and (pair? (.trail info)) (car (.trail info))))
        (clone <info> info :q (append (.q info) (list trigger)) :error #t))))

(define (deq info)
  (clone <info> info :q (cdr (.q info))))

(define (peeq info)
  (and (pair? (.q info)) (car (.q info))))

(define (->string h . t)
  (let ((src (if (pair? t) (cons h t) h)))
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
      (_ ((@ (gaiag misc) ->string) src)))))

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
