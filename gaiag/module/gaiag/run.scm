;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag run)
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
           mangle-traces
           walk-trail
           symbol->trigger
           ->symbol
           run:om))

(define MAX-ITERATIONS 10000)
(define (debug . x) #t)
;;(define debug stderr)

(define (ast-> ast)
  (let ((name (and=> (option-ref (parse-opts (command-line)) 'model #f)
                     string->symbol)))
    (or (and-let* ((om ((om:register run:om) ast #t))
                   (models (filter (lambda (x) (or (is-a? x <interface>)
                                                   (is-a? x <component>)))
                                   (.elements om)))
                   (models (null-is-#f (filter .behaviour models)))
                   (models (if name (filter (om:named name) models) models))
                   (c-i (append (filter (is? <component>) models) models)))
                  (run-top (car c-i)))
        "")))

(define (run:import name)
  (om:import name run:om))

(define (run:om ast)
  ((compose ;;ast:wfc
    ast:resolve ast->om) ast))

(define i 0)
(define *state-space* '(()))

(define (run-top model)
  (stderr "\n\n>>>running: ~a ~a {~a}\n" (ast-name model) (.name model) (map ->string (om:find-triggers model)))
  (and-let* ((((is? <component>) model))
             (interfaces (map run:import
                              (map .type ((compose .elements .ports) model))))))
  (let* ((trail (option-ref (parse-opts (command-line)) 'trail #f))
         (traces (if trail
                     (walk-trail model (with-input-from-string trail read))
                     (explore-space model)))
         ;;(foo (stderr "RESULT:\n"))
         ;;(foo (pretty-print trace (current-error-port)))
         (trace (if (pair? traces) (car traces) '()))
         )
    (pretty-print (mangle-traces model traces)))
  (newline)
  (stderr "state space: ~a\n" (length *state-space*))
  "")

(define (explore-space model)
  (run-trail model))

(define (walk-trail model trail)
  (run-trail model (next-info-trail-walker) trail))

(define* (run-trail model :optional (next-info next-info-space-explorer) (trail '()))
  (set! *state-space* '(()))
  (set! i 0)
  (let* ((info (make <info> :trail trail :state (state-vector model))))
    (let loop ((info info) (trace '()))
      (stderr "trail: <-- ~a\n" (.trail info))
      ;;(stderr "TRACE: ~a\n\n\n" (map trace-location (.trace info)) (current-error-port))
      (let* ((info (next-info model info))
             (trail (.trail info)))
        (if (null? trail)
            trace
            (let* ((info (next-trigger model info))
                   (trigger (.reply info))
                   (info (clone <info> info :reply 'return));; FIXME reset
                   (infos (run-trigger model trigger info))
                   (infos (if (null? (prune infos)) (list (clone <info> info :trail '())) infos))
                   ;;(foo (stderr "TRACES: ~a\n" (length infos)))
                   (infos (sort-infos infos))
                   (infos (delete-duplicates infos equal?))
                   ;;(foo (stderr "UNIQUE: ~a\n" (length infos)))
                   (foo (map
                            (lambda (info count)
                              (stderr "R ~a:\n" count)
                              (map trace-location (.trace (car infos))) (current-error-port))
                            infos (iota (length infos)))))
               (append-map (lambda (info) (loop info (list (append trace (.trace info))))) infos)
              ))))))

(define* (run-trigger model trigger info :optional (reverse identity))
  (stderr "run-trigger[~a ~a] " (.name model) (state->string (.state info)))
  (stderr "trigger: ~a\n" (->string trigger))
  (let* ((ast ((compose .statement .behaviour) model))
         (info (clone <info> info :ast ast)))
    (seen! model (.state info) (.ast info) trigger)
    (map
     (lambda (info)
       (let* ((trace (.trace info))
              (trace (reverse trace))
              (info (if (not (eq? reverse identity))
                        (set-state info model (.state info))
                        info)))
         (clone <info> info :trace trace)))
     (run model trigger info))))

(define ((variable? model) identifier) (om:variable model identifier))
(define ((extern? model) var) (om:extern model (.type var)))

(define (om:member-names model)
  (map .name (filter (negate (extern? model)) (om:variables model))))

(define (eval-function-expression model trigger info)
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
              (info ((cons-trace f) info))
              (infos (run model trigger info))
              (infos (prune infos)))
         infos))
      (($ <action> trigger)
       (stderr "INFO0: ~a\n" info)
       (let* ((info (next-value model info trigger)) ;; FIXME: trace interface too!
              (info ((cons-trace expression) info))
              (reply (.reply info)))
         (stderr "R: ~a\n" reply)
         (list (clone <info> info :return reply))))
      (_ (let ((return (eval-expression model (.state info) expression)))
           (list (clone <info> info :ast #f :return return)))))))

(define ((append-trace trace) info)
  (clone <info> info :trace (append trace (.trace info))))
(define ((set-trace trace) info)
  (clone <info> info :trace trace))
(define ((cons-trace trace) info)
  (clone <info> info :trace (cons trace (.trace info))))
(define (trace? info) (null-is-#f (.trace info)))
(define (error? info) (not (.error info)))
(define (prune infos) (filter trace? infos))

(define (sort-infos infos)
  (stable-sort infos (lambda (a b)
                       (cond
                        ((and (not (.error a)) (.error b)) #t)
                        ((not (.error b)) #f)
                        (else (> (length (.trace a))
                                 (length (.trace b))))))))

(define (run model trigger info)
  (define (trigger-matches? t)
    (if (is-a? model <component>) (equal? t trigger) (eq? (.event t) (.event trigger))))
  (stderr "run[~a]: ~a ~a\n" (.name model) (ast-name (.ast info)) (map ->symbol (.trail info)))
  (pretty-print (map trace-location (.trace info)) (current-error-port))  
  (set! i (1+ i))
  (if (> i MAX-ITERATIONS)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*))))
  (let* ((ast (.ast info))
         (info+ast ((cons-trace ast) info))
         (state (.state info))
         (trace (.trace info)))
    (match (.ast info)
      (#f '())
      (($ <on> ('triggers triggers ...) statement)
       (if (find trigger-matches? triggers)
           (let* ((port (.port trigger))
                  (o-info (clone <info> info :ast statement :trace (list trigger)))
                  (infos
                   (if (and (is-a? model <component>)
                            (eq? (.name (om:port model)) port))
                       (let*
                           ((interface (run:import (.type (om:port model))))
                            (i-state (get-state o-info interface))
                            (i-info (clone <info> o-info :state i-state :trace '()))
                            (i-infos (run-trigger interface trigger i-info reverse))
                            (i-infos (prune i-infos))
                            (infos (map
                                    (lambda (i-info)
                                      (let ((i-info (set-state i-info interface (.state i-info))))
                                        (clone <info> o-info :state-alist (.state-alist i-info))))
                                    i-infos))
                            (infos (apply append
                                          (map (lambda (info)
                                                 (run model trigger info))
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
                                        infos))
                            (foobar-infos (map (lambda (info)
                                          (let* ((reply (.reply info))
                                                 (return (rsp ast (make <return> :expression reply))))
                                            (set-source-property! return 'port (.port trigger))
                                            ((cons-trace return) info)))
                                        infos)))
                         infos)
                       (run model trigger o-info)))
                  (infos (prune infos))
                  (infos (if (and (is-a? model <component>)
                                  (not (eq? port (.name (om:port model)))))
                             (map (cons-trace ast) infos)
                             (map
                              (lambda (info count)
                                (let* ((foo (stderr "TYPED[~a]: ~a\n" trigger (om:typed? model trigger)))
                                       (info
                                        (if (om:typed? model trigger)
                                            (next-reply model info (.port trigger))
                                            (next-return model info (.port trigger))))
                                       (reply (->symbol (.reply info)))
                                       (info (clone <info> info :reply 'return))
                                       (trace (.trace info))
                                       (return (rsp ast (make <return> :expression reply)))
                                       (x (set-source-property! return 'port (.port trigger)))
                                       (trace (if (or (null? trace)
                                                      (.error info))
                                                  trace
                                                  (append (cons ast trace) (list return)))))
                                  ((set-trace trace) info)))
                              infos (iota (length infos))))))
             infos)
           '()))
      (($ <guard> expression statement)
       (if (eval-expression model state expression)
           (let* ((g-info (clone <info> info :ast statement :trace '()))
                  (infos (run model trigger g-info))
                  (infos (prune infos))
                  (infos (map (append-trace (cons ast trace)) infos)))
             infos)
           '()))
      (($ <illegal>) (list info+ast))
      (($ <action> trigger)
       (let ((port (.port trigger))
             (o-info (clone <info> info)))
         (if (and (is-a? model <component>)
                  (not (eq? port (.name (om:port model)))))
             (let* ((interface (run:import (.type (om:port model port))))
                    (i-state (get-state info interface))
                    (trail (.trail o-info))
                    (i-trail (if (pair? trail) (cdr trail) '()))
                    (i-info (clone <info> o-info :trail i-trail :state i-state :trace '()))
                    (i-infos (run-trigger interface trigger i-info reverse))
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
               (stderr "FIXME: trigger???: ~a\n" trigger)
               i-infos)
             (let ((info info+ast))
               (if (is-a? model <component>)
                   (list (enq model info trigger))
                   (list (next-action model info trigger)))))))
      (($ <assign> identifier expression)
       (let* ((info info+ast)
              (infos (eval-function-expression model trigger (clone <info> info :ast expression))))
         (map
          (lambda (info)
            (clone <info> info :state (var! (.state info) identifier (.return info))))
          infos)))
      (($ <call> function ('arguments arguments ...))
       (let* ((info (clone <info> info (cons ast trace))))
         (eval-function-expression model trigger info)))
      (($ <variable> identifier type expression)
       (let* ((info info+ast)
              (infos (eval-function-expression model trigger (clone <info> info :ast expression))))
         (map
          (lambda (info)
            (stderr "VAR ~a = ~a => ~a\n" identifier expression (.return info))
            (clone <info> info :state (var! (.state info) identifier (.return info))))
          infos)))
      (($ <if> expression then #f)
       (let ((info info+ast))
         (if (eval-expression model state expression)
             (run model trigger (clone <info> info :ast then))
             (list info))))
      (($ <if> expression then else)
       (let ((info info+ast)
             (value (eval-expression model state expression)))
         (stderr "<if> at: ~a\n" (trace-location ast))
         (stderr "var s: ~a\n" (var (.state info) 's))
         (stderr "expr ~a ==> ~a\n" expression value)
         (if value ;;(eval-expression model state expression)
             (run model trigger (clone <info> info :ast then))
             (run model trigger (clone <info> info :ast else)))))
      (('compound) (list (clone <info> info :ast #f)))
      ((and ('compound statements ...) (? om:declarative?))
       (let loop ((statements statements) (loop-infos '()))
         (if (null? statements)
             (let* ((loop-infos (prune loop-infos)))
               loop-infos)
             (let* ((statement (car statements))
                    (info (clone <info> info :ast statement :trace '()))
                    (infos (run model trigger info))
                    (infos (prune infos)))
               (if (pair? infos)
                   (apply append
                          (map (lambda (info) (loop (cdr statements) (cons info loop-infos))) infos))
                   (loop (cdr statements) loop-infos))))))
      (('compound statements ...)
       (let loop ((statements statements) (loop-info info+ast) (frame 0))
         (if (null? statements)
             (list (clone <info> loop-info :ast '() :state (drop (.state loop-info) frame)))
             (let ((statement (car statements)))
               (let* ((state (if (is-a? statement <variable>)
                                 (acons (.name statement)
                                        #f (.state loop-info)) (.state loop-info)))
                      (frame (if (is-a? statement <variable>)
                                 (1+ frame) frame))
                      (info (clone <info> loop-info :ast statement :trace '()))
                      (infos (run model trigger info))
                      (infos (prune infos))
                      (infos (map (append-trace (.trace loop-info)) infos)))
                 (apply append (map (lambda (info) (loop (cdr statements) info frame)) infos)))))))
      (($ <return> expression)
       (let ((return (eval-expression model state expression)))
         (list (clone <info> info+ast :return return))))
      (($ <reply> expression)
       (let* ((reply (eval-expression model state expression)))
         (list (clone <info> info+ast :reply reply)))))))

(define (mangle-traces model traces)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        (append
         (list
          (json-init model)
          (json-state model (state-vector model)))
         (let ((trace (if (null? traces) '() (car traces)))) ;; FIXME JSON
           (json-trace model trace)))
        (map demo-trace traces (iota (length traces))))))

(define (trace-location ast)
  (or (and-let* ((loc (source-location ast))
                 (properties (source-location->user-source-properties loc)))
                (format #f "~a:~a:~a"
                        (assoc-ref properties 'filename)
                        (assoc-ref properties 'line)
                        (assoc-ref properties 'column)))
      ast))

(define <state> 'state)
(define (demo-trace trace count)
  (stderr "\n\nRESULT: ~a\n" count)
  ;;(pretty-print trace (current-error-port))
  (pretty-print (map demo-tracepoint trace) (current-error-port))
  (stderr "END RESULT[~a]\n" count))

(define (demo-tracepoint step)
  (match step
    (($ <state> state ...) (state->string step))
    (($ <trigger>) (->symbol step))
    (_ (trace-location step))))

(define (symbol->trigger event)
  "if EVENT is of form [PORT.]TRIGGER, produce (trigger [PORT] EVENT)"
  (match (symbol-split event #\.)
    ((event) (make <trigger> :event event))
    ((#f event) (make <trigger> :event event))
    ((port event) (make <trigger> :port port :event event))
    (_ ;;(throw 'runtime-error (format #f "not a trigger: ~a\n" event))
     (stderr "not a trigger: ~a\n" event)
     #f)))

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

(define (next-trigger model info)
  (let* ((trail (.trail info)))
    (if (null? trail)
        info
        (let ((reply (symbol->trigger (car trail))))
          (clone <info> info :trail (cdr (.trail info)) :reply reply :trace (cons reply (.trace info)))))))

(define (next-action model info action)
  (let ((trail (.trail info)))
    (stderr "ACTION[~a ~a]: ~a\n" (.name model) action trail)
    (if (null? trail)
        info
        (let* ((next (symbol->trigger (car trail))))
          (stderr "NEXT: ~a\n" next)
          (stderr "EXPECT ACTION: ~a\n" action)
          (if (or (equal? next action)
                  (and (is-a? action <trigger>)
                       (is-a? next <trigger>)
                       (not (.port action))
                       (eq? (.event action) (.event next))))
              (clone <info> info :trail (cdr (.trail info)))
              (and
               (stderr "REJECT-TRACE: ACTION[~a expect:~a]: next:~a\n" (.name model) action next)
               ;;(map trace-location (.trace info))
               (clone <info> info :error #t)))))))

(define (next-value model info action)
  "eat a ENUM_FIELD or PORT.ENUM_FIELD from trail, or error"
  (let* ((info (next-action model info action))
         (trail (.trail info)))
    (stderr "VALUE[~a]: ~a\n" action trail)
    (if (null? trail)
        info
        (let* ((value (car trail))
               (reply (symbol->literal model value))
               (return (make <return> :expression value))
               (info ((cons-trace return) info)))
          (if (is-a? model <component>)
              (set-source-property! return 'port (.name (om:port model))))
          (clone <info> info :trail (cdr (.trail info)) :reply reply)))))

(define (next-return model info port)
  "eat a 'RETURN or PORT.'RETURN from trail, or error"
  (stderr "next-return[~a]: ~a\n" (.name model) (.trail info))
  (let* ((trail (.trail info))
         (info (skip-trail model info port))
         (return (make <trigger> :port port :event 'return)))
    (if (null? (.trail info))
        (clone <info> info :reply return) ;; FIMXE: no trail -->OKAY
        (let ((next (symbol->trigger (car (.trail info)))))
          (if (equal? next return)
              (clone <info> info :trail (cdr trail) :reply return)
              (and (stderr "REJECT-TRACE: RETURN[~a expect:~a] next: ~a\n" (.name model) return next)
                   (clone <info> info :reply #f :error #t)))))))

(define (next-reply model info port)
  "eat a 'RETURN or PORT.'RETURN from trail, or error"
  (stderr "next-reply[~a]: ~a\n" (.name model) (.reply info))
  (let* ((info (skip-trail model info port))
         (trail (.trail info)))
    (if (null? trail)
        info
        (let* ((next (symbol->literal model (car trail)))
               (reply (.reply info)))
          (stderr "NEXT: ~a\n" next)
          (stderr "EXPECT REPLY: ~a\n" reply)
          ;; FIXME TODO: reject
          (if (equal? next reply)
              (clone <info> info :trail (cdr trail) ;; :reply reply
                     )
              (and
               (stderr "REJECT-TRACE: REPLY[~a expect:~a]: next:~a\n" (.name model) reply next)
               (stderr "trace: ~a\n" (map trace-location (.trace info)))
               (clone <info> info :error #t)))))))

(define (symbol->literal model literal)
  (let* ((port-value (symbol-split literal #\.))
         (port (and (=2 (length port-value)) (car port-value)))
         (value (if (=2 (length port-value)) (cadr port-value) (car port-value)))
         (type-field (symbol-split value #\_))
         (port (and port (is-a? model <component>) (om:port model port)))
         (scope (and port (.type port))))
    (make <literal>
      :scope scope
      :type (car type-field)
      :field (cadr type-field))))

(define (skip-trail model info port)
  (let loop ((info info))
    ;; WIP/FIXME: skip from trail if port does not match
    ;; Alarm: enable has sensor.enable
    ;; Alarm: IConsole: enable must skip SENSOR.enable
    (stderr "SKIP-LOOP[~a]: ~a\n" port (.trail info))
    (let ((trail (.trail info)))
      (if (or (null? trail)
              (is-a? model <component>)
              (let ((trigger (symbol->trigger (car trail))))
                (or (not trigger)
                    (not (.port trigger))
                    (eq? (.port trigger) port))))
         info
         (loop (clone <info> info :trail (cdr trail)))))))

;; model checker...broken for now
(define (next-info-space-explorer model info)
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

(define (next-info-trail-walker)
  (lambda (model info)
    info))

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

(define (enq model info trigger)
  (let* ((trail (.trail info))
         (next (and (pair? trail) (symbol->trigger (car (.trail info))))))
    (if (equal? trigger next)
        (clone <info> info :trail (cdr trail) :q (append (.q info) (list trigger)))
        (and
          (stderr "REJECT-ENQ[~a expect:~a]: ~a\n" (.name model) trigger next)
          (clone <info> info :q (append (.q info) (list trigger)) :error #t)))))

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
