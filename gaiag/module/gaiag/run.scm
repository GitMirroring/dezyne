;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define MAX-ITERATIONS 400000)
(define (debug . x) #t)
(define (debug-pretty . x) #t)
(define (debug-state . x) #t)

(define (ast-> ast)
  (let ((name (and=> (option-ref (parse-opts (command-line)) 'model #f)
                     string->symbol))
        (json? (option-ref (parse-opts (command-line)) 'json #f)))
    (or (and-let* ((om ((om:register run:om) ast #t))
                   (models (filter (lambda (x) (or (is-a? x <interface>)
                                                   (is-a? x <component>)))
                                   (.elements om)))
                   (models (null-is-#f (filter .behaviour models)))
                   (models (if name (filter (om:named name) models) models))
                   (c-i (append (filter (is? <component>) models) models))
                   ((pair? c-i)))
                  (run-top (car c-i)))
        (if json?
            '()
            ""))))

(define (run:import name)
  (om:import name run:om))

(define (run:om ast)
  ((compose ;;ast:wfc
    ast:resolve ast->om) ast))

(define i 0)
(define *state-space* '(()))
(define *component* #f)  ;; FIXME

(define (run-top model)
  (stderr "\n\n>>>running: ~a ~a {~a}\n" (ast-name model) (.name model) (map ->string (om:find-triggers model)))
  (and-let* ((((is? <component>) model))
             (interfaces (map run:import
                              (map .type ((compose .elements .ports) model))))))
  (set! *component* ((is? <component>) model))
  (let* ((trail (option-ref (parse-opts (command-line)) 'trail #f))
         (traces (if trail
                     (walk-trail model (with-input-from-string trail read))
                     (explore-space model)))
         (traces (sort-traces traces))
         (trace (if (pair? traces) (car traces) '())))
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
  (let* ((ports (if (is-a? model <interface>) '() ((compose .elements .ports) model)))
         (state-alist (map (lambda (port) (cons (.name port) (state-vector (run:import (.type port))))) ports))
         (info (make <info> :trail trail :state (state-vector model) :state-alist state-alist)))
    (let loop ((info info) (trace '()))
      (debug "trail: <-- ~a\n" (.trail info))
      (debug-state model info)
      (if (or (null? (.trail info))
              (.error info))
          (let ((eligible (if (.error info) '((eligible))
                              (list (eligible model info))
                              ;;'((eligible))
                              ))
                (error (if (not (.error info)) '()
                           (list (cons 'error (.trail info))))))
            (list (append trace error eligible)))
          (let* ((info (next-info model info))
                 (trail (.trail info)))
            (let* ((infos (run-trigger model info #f #t))
                   (infos (prune infos))
                   (infos (sort-infos infos))
                   (infos (delete-duplicates infos equal?)))
              (append-map
               (lambda (info)
                 (let ((trail (list (cons 'trail (.trail info)))))
                   (loop info (append trace (.trace info) trail)))) infos)))))))

(define (print-state model info)
  (stderr "state[~a]\n    ~a\n" (.name model) (string-sub ", " "\n     " (state->string (.state info))))
  (if (is-a? model <component>)
      (for-each (lambda (s) (stderr "  [~a]: ~a\n" (car s) (state->string (cdr s)))) (.state-alist info))))

(define (modeling? trigger) (member (.event trigger) '(inevitable optional)))

(define (action? model trigger)
  (let* ((interface (if (is-a? model <interface>) model
                        (run:import (.type (om:port model)))))
         (triggers (map .event (om:find-triggers interface))))
    (not (member (.event trigger) triggers))))

(define (modeling-or-action? model trigger)
  (or (modeling? trigger)
      (action? model trigger)))

(define (action-triggers o)
  (map .trigger ((collect (is? <action>)) o)))

(define (triggers-for-action model action)
  (let* ((ons ((collect (is? <on>)) model))
         (event (.event action))
         (on-actions (map (lambda (on) (cons ((compose car .elements .triggers) on) (map (compose .event .trigger) ((collect (is? <action>)) on)))) ons))
         (on-actions (filter (lambda (x) (member event (cdr x))) on-actions)))
    (map car on-actions)))

(define* (run-trigger model info :optional (flushing? #f) (top? #f))
  (define (run-trigger-from-trail info)
    (let* ((info (next-trigger model info))
           (trigger (.return info))
           (info (clone info :return 'return)))
      (if (or (and (is-a? model <interface>) (not (modeling-or-action? model trigger))) (is-a? model <component>)) ((run model trigger flushing? top?) info)
          (let ((triggers (map (lambda (e) (make <trigger> :port (.port trigger) :event e)) '(inevitable optional)))
                (action-triggers (triggers-for-action model trigger)))
            (if (not (modeling? trigger)) (append-map (lambda (t) (prune ((run model t flushing? top?) info))) action-triggers)
                (let ((info (clone info :trail (cons (->symbol trigger) (.trail info)))))
                  (append-map (lambda (t) (prune ((run model t flushing? top?) info) info)) triggers)))))))

  (debug "\n\nrun-trigger[~a, ~a]:~a\n" (.name model) (->symbol (car (.trail info))) top?)
  (debug-state model info)
  (debug "trigger: ~a\n" (->string (car (.trail info))))
  (let* ((ast ((compose .statement .behaviour) model))
         (info (clone info :ast ast)))
    (let* ((trigger (symbol->trigger (car (.trail info))))
           (port (.port trigger))
           (infos (if (is-a? model <component>) (run-trigger-from-trail info)
                      (let* ((triggers (map .event (om:find-triggers model)))
                             (insert-modeling? (and top? (or (not *component*) (eq? (.direction (om:port *component* (.port trigger))) 'requires))
                                                    ))
                             (insert-inevitable? (and insert-modeling? (member 'inevitable triggers)))
                             (inevitable (if (not insert-inevitable?) '()
                                             (prune ((run model (make <trigger> :port port :event 'inevitable) flushing? top?) info) info)))
                             (insert-optional? (and insert-modeling? (member 'optional triggers)))
                             (optional (if (not insert-optional?) '()
                                           (prune ((run model (make <trigger> :port port :event 'optional) flushing? top?) info) info)))
                             (modelling (append inevitable optional))
                             (infos (run-trigger-from-trail info)))
                        (append infos modelling)))))
      infos)))

(define ((variable? model) identifier) (om:variable model identifier))
(define ((extern? model) var) (om:extern model (.type var)))

(define (om:member-names model)
  (map .name (filter (negate (extern? model)) (om:variables model))))

(define (eval-function-expression model trigger info)
  (let* ((members (om:member-names model))
         (expression (.ast info)))
    (match expression
      (($ <call>) (=> failure)
       (if (or (pair? (.trail info)) (eq? next-trail-empty next-trail-empty-reject)) (failure)
           (and (debug "BAIL RECURSION\n") (list info))))
      (($ <call> function ('arguments arguments ...))
       (debug "valued call[~a, ~a]: ~a\n" (.name model) function (.trail info))
       (let* ((f (om:function model function))
              (formals (map .name ((compose .elements .formals .signature) f)))
              (statement (.statement f))
              (pairs (zip formals arguments))
              (state (.state info))
              (state (let loop ((pairs pairs) (state state))
                       (if (null? pairs) state
                               (loop (cdr pairs) (acons (caar pairs)
                                                        (eval-expression model state (cadar pairs)) state)))))
              (info (cons-state info))
              (info ((cons-trace f) info))
              (info (clone info :ast statement :state state))
              (infos ((run model trigger) info))
              (infos (prune infos))
              (drop-formals (lambda (info) (clone info :state (drop (.state info) (length formals)))))
              (infos (map drop-formals infos)))
         infos))
      (($ <action> action)
       (map (modify-field :return .reply) ((run model trigger) info)))
      (_ (let ((return (eval-expression model (.state info) expression)))
           (list (clone info :return return)))))))

(define ((append-trace trace) info)
  (clone info :trace (append trace (.trace info))))
(define ((set-trace trace) info)
  (clone info :trace trace))
(define ((cons-trace trace) info)
  (clone info :trace (cons trace (.trace info))))
(define (cons-state info)
  ((cons-trace `(state ,(.state info))) info))
(define ((modify-trace modify) info)
  (clone info :trace (modify (.trace info))))
(define ((modify-field field modify) info)
  (clone info field (modify info)))
(define ((set-fields . args) info)
  (apply clone (cons info args)))
(define (trace? info) (null-is-#f (.trace info)))
(define (success? info) (not (.error info)))
(define* (prune infos :optional (info #f))
  (define (progress? i)
    (or (< (length (.trail i)) (length (.trail info)))
        (not (equal? (.state i) (.state info)))
        (if (is-a? info <interface>) #f
            (not (equal? (.state-alist i) (.state-alist info))))))
  (let* ((infos (filter trace? infos))
         (infos (if (not info) infos
                    (filter progress? infos)))
         (success (filter success? infos)))
    (if (pair? success) success infos)))

(define (sort-infos infos)
  (define (optimist< a b) ;; non-error trace found: that's GREAT!
    (cond ((and (not (.error a)) (.error b)) #t)
          ((not (.error b)) #f)
          (else (< (length (.trail a)) (length (.trail b))))))
  (define (pessimist< a b) ;; amongst best-matches error trace found: oh no!
    (cond
     ((not (eq? (.error a) (.error b))) (.error b))
     ((= (length (.trail a)) (length (.trail b)))
      (< (length (.trace a)) (length (.trace b))))
     ((!= (length (.trail a)) (length (.trail b)))
      (< (length (.trail a)) (length (.trail b))))
     (else (cond ((.error a) #t)
                 ((.error b) #f)))))
  (let* ((infos (stable-sort infos
                             pessimist<
                             ;;optimist<
                             )))
    (if (and (pair? infos) (not (.error (car infos))))
        (filter success? infos)
        infos)))

(define (sort-traces traces)
  (define (.error o) (assq 'error o))
  (define (error? o) (assoc-ref o 'error))
  (define (.trail o) (or (assq-ref o 'error) '()))
  (define (.trace o) o)
  (define success? (negate .error))
  (define (pessimist< a b)
  (cond
     ((not (eq? (and (error? a) #t) (and (error? b) #t)))
      (error? b))
     ((= (length (.trail a)) (length (.trail b)))
      (< (length (.trace a)) (length (.trace b))))
     ((!= (length (.trail a)) (length (.trail b)))
      (< (length (.trail a)) (length (.trail b))))
     (else
      (cond ((error? a) #t)
                 ((error? b) #f)))))
  (let* ((traces (stable-sort traces pessimist<)))
    (if (or (null? traces) (error? (car traces))) traces
        (filter success? traces))))

(define* ((run model trigger :optional (flushing? #f) (top? #f)) info)
  (let* ((ast (.ast info))
         (r ((run- model trigger flushing? top?) info)))
    (debug "   RUN DONE\n")
    (and (pair? r) (eq? (ast-name r) 'info) (debug "INFO: ~a\n" r) BARF-SINGLE-INFO)
    (debug "   ==> infos: ~a\n" (length r))
    ;;;(debug "   ==> done[~a, ~a]: ~a (car infos): ~a\n" (.name model) (->symbol trigger) (ast-name ast) (and (pair? r) (car r)))
    (debug "   ==> trail[~a, ~a]: ~a ~a\n" (.name model) (->symbol trigger) (ast-name ast) (and (pair? r) (.trail (car r))))
    (debug "   ==> ") (if (pair? r) (debug-state model (car r)) '())
    r))

(define* ((run- model trigger :optional (flushing? #f) (top? #f)) info)
  (define (trigger-matches? t)
    (debug "MATCH?: ~a == ~a ==> ~a\n" (->symbol t) (->symbol trigger) (if (is-a? model <component>) (equal? t trigger) (eq? (.event t) (.event trigger))))
    (if (is-a? model <component>) (equal? t trigger) (eq? (.event t) (.event trigger))))
  (debug "\nrun[~a, ~a]: ~a trail:~a\n" (.name model) (->symbol trigger) (ast-name (.ast info)) (map ->symbol (.trail info)))
  (debug-state model info)
  (debug-pretty (map trace-location (.trace info)) (current-error-port))
  (set! i (1+ i))
  (if (> i MAX-ITERATIONS)
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*))))
  (let* ((ast (.ast info))
         (info+ast ((cons-trace ast) info))
         (orig-states (copy-tree (.state-alist info)))
         (state (.state info))
         (trace (.trace info)))
          (match (.ast info)
            (#f '())
            (() (debug "NULL AST?!") '())
            (($ <on> ('triggers triggers ...) statement)
             (debug "on[~a, ~a]: ~a, ~a\n" (.name model) (->symbol (car triggers)) (->symbol trigger) (.trail info))
             (if (not (find trigger-matches? triggers)) '()
                 (let* ((info+ast (if flushing? info
                                      ((cons-trace trigger) info)))
                        (info+ast (if flushing? info
                                      ((cons-trace ast) info+ast)))
                        (on-info (clone info :ast statement :trace '()))
                        (infos
                   (if (is-a? model <interface>) ((run model trigger flushing? top?) on-info)
                             (let* ((port (.port trigger))
                                    (infos
                               (if (and flushing? (eq? (.direction (om:port model port)) 'requires))
                                   (list info)
                                   (run-interface model trigger on-info flushing? top?)))
                                    (i-infos (filter success? infos))
                                    (infos (if (pair? i-infos) i-infos
                                               ;; if no interface trace succeeds
                                               ;; clear error for component trace
                                               (map (set-fields :error #f) infos)))
                                    (infos (map (set-fields :ast statement) infos))
                              (infos (append-map (run model trigger flushing? top?) infos))
                                    (infos (if (pair? i-infos) infos
                                               (map (set-fields :error #t) infos))))
                               (append-map (flush model ast) infos))))
                        (infos (prune infos))
                        (foo (debug "trigger: ~a\n" (->symbol trigger)))
                        (foo (debug "flushing: ~a\n" flushing?))
                        (foo (debug "infos: ~a\n" (length infos)))
                        (foo (debug "q: ~a\n" (and (pair? infos) (map ->symbol (.q (car infos))))))
                        (infos (map (handle-return model trigger trigger ast flushing?) infos)))
                   (map
                    (lambda (info)
                      ((set-trace (reverse (append (reverse (.trace info))
                                                   (.trace info+ast)))) info))
                    infos))))
            (($ <guard> expression statement)
             (if (eval-expression model state expression)
                 (let* ((g-info (clone info :ast statement :trace '()))
                        (infos ((run model trigger flushing? top?) g-info))
                        (infos (prune infos))
                        (infos (map (append-trace (cons ast trace)) infos)))
                   infos)
                 '()))
            (($ <illegal>)
             (let ((info (clone (next-illegal model info+ast))))
               (list info)))
            (($ <action> action)
             (debug "action[~a, ~a]: ~a\n" (.name model) (->symbol action) (.trail info))
             (let* ((port (.port action))
              ;; FIXME: FIRST-IN-Q?? See also: below and run-interface
              (info+ast (if (and flushing?
                                 (is-a? model <component>)
                                 (pair? (.trail info))
                                 (pair? (.q info))
                                 (eq? (.direction (om:port model (.port trigger)))
                                      (.direction (om:port model port))
                                      'requires))
                            ((cons-trace '((queue in))) info)
                            info+ast))
                    (q-info #f)
                    (infos
                     (cond
                      ((and (is-a? model <interface>)
                            (.port trigger) ;;; *component*
                            (or (modeling? trigger) (eq? (.direction (om:port *component* (.port trigger))) 'requires))
                            (let* ((info (next-queue? model info trigger action)))
                              (and (not (.error info))
                                   (set! q-info info))))
                       (let* ((info (enq model q-info (.return q-info)))
                              (q-trigger (.return info))
                              (synth-ast (rsp ast (make <action> :trigger q-trigger)))
                        (q (.q info))
                        (info ((cons-trace `((q ,q-trigger))) info))
                        ;; FIXME: FIRST-IN-Q?? See also: above and run-interface
                        (info (if (and (modeling? trigger) (=1 (length q))) info
                                  ((cons-trace synth-ast) info))))
                         (list info)))
                      ((and (is-a? model <interface>)
                            *component*)
                       (let* ((info
                               (if (or (not (.port trigger))
                                       (eq? (.direction (om:port *component* (.port trigger))) 'requires)) info
                                       (next-action model info trigger action)))
                              (port (or (.port trigger) (.name (om:port *component*))))
                              (info (skip-trail info port)))
                         (list info)))
                      ((is-a? model <interface>)
                       (let* ((info (next-action model info trigger action))
                        (info ((handle-return model trigger action ast flushing?) info)))
                         (list info)))
                      (else
                       (let* ((info (if (and flushing?
                                       (pair? (.q info))
                                       (eq? (.direction (om:port model (.port trigger)))
                                            (.direction (om:port model port))
                                            'requires)) info
                                            (next-action model info trigger action)))
                              (action-info (clone info :trace '()))
                              ;; FIXME: should skip simple provided on e: f<<--
                              (infos (if (or flushing?
                                             (and (eq? (.direction (om:port model (.port trigger))) 'provides)
                                                  (eq? (.direction (om:port model port)) 'provides))) (list info)
                                            (run-interface model action action-info flushing?)))
                        (infos (map (handle-return model trigger action ast flushing?) infos)))
                   infos)))))
               (map
                (lambda (info)
                  ((set-trace (reverse (append (reverse (.trace info))
                                               (.trace info+ast)))) info))
                infos)))
            (($ <assign> identifier expression)
             (debug "assign[~a, ~a]: ~a\n" (.name model) identifier (.trail info))
             (let* ((infos (eval-function-expression model trigger (clone info :ast expression)))
                    (set-var (lambda (info)
                               (debug "  assign var[~a]: ~a := ~a\n" (.name model) identifier (.return info))
                               (var! (.state info) identifier (.return info))))
                    (infos (map (modify-field :state set-var) infos))
                    (infos (map cons-state infos))
              (infos (map (cons-trace ast) infos)))
               infos))
            (($ <call> function ('arguments arguments ...))
             (debug "void call[~a, ~a]: ~a\n" (.name model) function (.trail info))
             (let ((infos (eval-function-expression model trigger info+ast)))
               infos))
            (($ <variable> identifier type expression)
             (debug "variable[~a, ~a]: ~a\n" (.name model) identifier (.trail info))
             (let* ((infos (eval-function-expression model trigger (clone info :ast expression)))
                    (set-var (lambda (info)
                               (debug "  init var[~a]: ~a := ~a\n" (.name model) identifier (.return info))
                               (var! (.state info) identifier (.return info))))
                    (infos (map (modify-field :state set-var) infos))
                    (infos (map cons-state infos))
                    (infos (map (cons-trace ast) infos)))
               infos))
            (($ <if> expression then #f)
             (let ((info info+ast)
                   (value (eval-expression model state expression)))
               (debug "<if>[~a] at: ~a\n" (.name model) (trace-location ast))
               (debug "expr ~a ==> ~a\n" expression value)
               (if value ;;(eval-expression model state expression)
                   ((run model trigger flushing?) (clone info :ast then))
                   (list info))))
            (($ <if> expression then else)
             (let ((info info+ast)
                   (value (eval-expression model state expression)))
               (debug "<if>[~a] at: ~a\n" (.name model) (trace-location ast))
               (debug "expr ~a ==> ~a\n" expression value)
               (if value ;;(eval-expression model state expression)
                   ((run model trigger flushing?) (clone info :ast then))
                   ((run model trigger flushing?) (clone info :ast else)))))
            (('compound) (list info+ast))
            ((and ('compound statements ...) (? om:declarative?))
             (let loop ((statements statements) (loop-infos '()))
               (if (null? statements)
                   (let* ((loop-infos (prune loop-infos)))
                     loop-infos)
                   (let* ((statement (car statements))
                          (info (clone info :ast statement :trace '()))
                    (infos ((run model trigger flushing? top?) info))
                          (infos (prune infos)))
                     (if (pair? infos)
                         (append-map (lambda (info) (loop (cdr statements) (cons info loop-infos))) infos)
                         (loop (cdr statements) loop-infos))))))
            (('compound statements ...)
             (debug "ENTER IMPERATIVE[~a, ~a]: ~a\n" (.name model) (length statements) (and (pair? statements) (ast-name (car statements))))
             (let loop ((statements statements) (loop-info info+ast) (frame 0))
               (if (or (null? statements)
                       (and
                        (.error loop-info)
                        (debug "BAILING COMPOUND[~a]: ~a\n" (.name model) (if (null? statements) '()  (car statements)))))
                   (list (clone loop-info :ast '() :state (drop (.state loop-info) frame)))
                   (let ((statement (car statements)))
                     (let* ((foo (debug "IMPERATIVE[~a, ~a]: ~a\n" (.name model) (length statements) (ast-name statement)))
                            (state (if (is-a? statement <variable>)
                                       (acons (.name statement)
                                              #f (.state loop-info)) (.state loop-info)))
                            (frame (if (is-a? statement <variable>)
                                       (1+ frame) frame))
                            (info (clone loop-info :ast statement :state state :trace '()))
                            (infos ((run model trigger flushing?) info))
                            (infos (prune infos))
                            (infos (map (append-trace (.trace loop-info)) infos)))
                       (append-map (lambda (info) (loop (cdr statements) info frame)) infos))))))
            (($ <return> expression)

             (let ((return (eval-expression model state expression)))
               (debug "return[~a, ~a]: ~a\n" (.name model) expression (.trail info))
               (list (clone info+ast :return return))))
            (($ <reply> expression)
             (let* ((reply (eval-expression model state expression)))
               (debug "reply[~a]: ~a\n" (.name model) reply)
               (list (clone info+ast :reply reply)))))))

(define* (run-interface model trigger component-info flushing? :optional (top? #f))
  (debug "run-interface[~a, ~a]\n" (.name model) (->symbol trigger))
  (let*
      ((port (.port trigger))
       (scope (.type (om:port model port)))
       (interface (run:import scope))
       (trace (.trace component-info))
       (i-state (get-state component-info port))
       (i-info (clone component-info :q '() :state i-state :trace '()))
       (i-info (if (modeling-or-action? interface trigger) i-info
                   (skip-trail i-info port)))
       (i-info (clone i-info :trail (cons (->symbol trigger) (.trail i-info))))
       (i-infos (run-trigger interface i-info flushing? top?))
       (i-infos (map (modify-trace reverse) i-infos))
       (infos (map (transfer-interface-info model trigger component-info) i-infos))
       (infos (prune infos)))
    infos))

(define ((transfer-interface-info model trigger component-info) i-info)
  (let* ((port (.port trigger))
         (scope (.type (om:port model port)))
         (q (.q i-info))
         (trail (.trail component-info))

         ;; FIXME: FIRST-IN-Q?  See also <action> in (run-)
         ;; any events in Q must be stripped from component trail.
         ;; That can be done fairly easily by cdr'ing through both and
         ;; stripping from trail anything that matches Q.

         ;; "Sometimes", however (eg: TauEmitMultiple), the head of the Q
         ;; has an event that is not present in the trail.  If that is
         ;; the case, we must not attempt to strip it from the trail,

         ;; Question is: WHEN is this the case, this if feels just wrong.

         (foo (debug "\nQQQ FLUSH before trail: ~a\n" trail))
         (foo (debug "QQQ FLUSH before q: ~a\n" q))
         (q (if (or (null? q) (null? trail) (eq? (->symbol (car q)) (car trail))) q
                (cdr q)))
         (trail (let loop ((q q) (trail trail))
                  (if (or (null? q) (null? trail)) trail
                      (let ((a (->symbol (car q)))
                            (t (car trail)))
                        (if (eq? a t) (loop (cdr q) (cdr trail))
                            (cons t (loop q (cdr trail))))))))
         (foo (debug "QQQ FLUSH after trail: ~a\n" trail))
         (component-info (clone component-info :trail trail))
         (q (append (.q component-info) (.q i-info)))
         (reply (.reply i-info))
         (reply (if (is-a? reply <literal>) reply
                    (make <literal> :field 'return)))
         (trace (.trace component-info))
         (trace (append trace (reverse (.trace i-info))))
         (info (clone component-info :trail trail :q q :reply (make <literal> :scope scope :type (.type reply) :field (.field reply)) :trace trace :error (.error i-info))))
    (set-state info port (.state i-info))))

(define ((flush model ast) component-info)
  (debug "flush: component-info: q: ~a\n" (.q component-info))
  (debug "flush: component-info: trail: ~a\n" (.trail component-info))
  (let loop ((info component-info))
    (debug "q: ~a\n" (.q info))
    ;; (debug "q info: ~a\n" info)
    (if (not (peeq info))
        (list info)
        (let* ((trigger (peeq info))
               (info (deq info))
               (port (.port trigger))
               (info (clone info :trail (cons (->symbol trigger) (.trail info)) :trace '()))
               (info (clone info :trace '()))
               (foo (debug "flush feeding: ~a\n" (.trail info)))
               (info (clone info :trace '() ))
               (infos (run-trigger model info #t))
               (infos (prune infos))
               (complete-trace (lambda (t) (append (.trace component-info) t)))
               (infos (map (modify-trace complete-trace) infos)))
          (append-map loop infos)))))

(define ((handle-return model trigger action ast flushing?) info)
  (let* ((port (.port action))
         (interface (if (is-a? model <interface>) model
                        (run:import (.type (om:port model port))))))
    (if (or (and *component* (modeling-or-action? interface action))
            (and (not *component*) (modeling-or-action? interface action))
            (and flushing?
                 (or (is-a? model <interface>)
                     (pair? (.q info)))
                 (eq? (.direction (om:port model (.port trigger)))
                      (.direction (om:port model port))
                      'requires)))
        info
        (let* ((info (if (om:typed? model action)
                         (next-reply model info action)
                         (next-return model info action)))
               (return (->symbol (.return info)))
               (return (rsp ast (make <return> :expression return))))
          (if (or (.error info)
                  (and (.port action) (is-a? model <interface>)))
              ((set-trace (.trace info)) info)
              ((set-trace (append (.trace info) (list return))) info))))))

(define (eligible model info)
  (set! next-trail-empty next-trail-empty-allow)
  (let ((eligible
         (cons
          'eligible
          (if (.error info)
              '()
              (filter identity
                      (map
                       (lambda (trigger)
                         (let* ((infos (run-trigger model (clone info :trail (list (->symbol trigger)))))
                                (infos (prune infos info)))
                           (and (pair? infos) (->symbol trigger))))
                       (om:find-triggers model)))))))
    (set! next-trail-empty next-trail-empty-reject)
    eligible))

(define (mangle-traces model traces)
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f)))
    (if json?
        (append
         (list
          (json-init model)
          (json-state model (state-vector model)))
         (let ((trace (if (null? traces) '() (car traces)))) ;; FIXME JSON
           (json-trace model trace)))
        (if (null? traces)
            (debug "ERROR: no matching trace\n")
            (map demo-trace traces (iota (length traces)))))))

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
  (pretty-print trace (current-error-port))
  (pretty-print (map demo-tracepoint trace) (current-error-port))
  (stderr "END RESULT[~a]\n" count))

(define (demo-tracepoint step)
  (match step
    (($ <state> state ...) (state->string state))
    (($ <trigger>) (->symbol step))
    (_ (trace-location step))))

(define (symbol->trigger event)
  "if EVENT is of form [PORT.]TRIGGER, produce (trigger [PORT] EVENT)"
  (match (symbol-split event #\.)
    ((event) (make <trigger> :event event))
    ((#f event) (make <trigger> :event event))
    ((port event) (make <trigger> :port port :event event))
    (_ ;;(throw 'runtime-error (format #f "not a trigger: ~a\n" event))
     (debug "not a trigger: ~a\n" event)
     #f)))

(define (next-trigger model info)
  (let* ((trail (.trail info)))
    (if (null? trail)
        info
        (let ((return (symbol->trigger (car trail))))
          (clone info :trail (cdr (.trail info)) :return return :trace (cons return (.trace info)))))))

(define (next-action model info trigger action)
  (let ((trail (.trail info)))
    (debug "next-action[~a ~a]: ~a\n" (.name model) action trail)
    (cond
     ((null? trail) (next-trail-empty model info 'action (->symbol action)))
     ((and *component* (modeling? trigger)) info)
     (else
      (let* ((next (symbol->trigger (car trail))))
        (debug "NEXT: ~a\n" next)
        (debug "EXPECT ACTION: ~a\n" action)
        (if (or (trigger-equal? next action)
                (and (is-a? action <trigger>)
                     (is-a? next <trigger>)
                     (not (.port action))
                     (eq? (.event action) (.event next))))
            (clone info :trail (cdr (.trail info)))
            (and
             (debug "REJECT-TRACE: ACTION[~a expect:~a]: next:~a\n" (.name model) action next)
             ((cons-trace
               (list 'reject 'action (.name model) 'next next 'expected action))
              (clone info :error #t)))))))))

(define (next-illegal model info)
  (let* ((trail (.trail info)))
    (debug "next-illegal[~a]: ~a\n" (.name model) trail)
    (if (null? trail)
        (next-trail-empty model info 'illegal 'illegal)
        (let* ((next (car trail)))
          (if (eq? next 'illegal)
              (clone info :trail (cdr trail) :return next :error #t) ;; FIXME: illegal was matched, is that an error?
              (and
               (debug "REJECT-TRACE: ILLEGAL[~a expect:~a]: next:~a\n" (.name model) 'illegal next)
               ((cons-trace
                 (list 'reject 'illegal (.name model) 'next next 'expected 'illegal))
                (clone info :error #t))))))))

(define (trigger-equal? a b)
  (and (eq? (.port a) (.port b)) (eq? (.event a) (.event b))))

(define (next-queue? model info trigger action)
  (let ((trail (.trail info))
        (port (.port action))
        (event (.event action)))
    (debug "next-queue?[~a ~a]: ~a trail: ~a\n" (.name model) port (->symbol action) trail)
    (if (null? trail)
        (clone info :error #t)
        (let* ((next (symbol->trigger (car trail)))
               (n-port (.port next)))
          (cond ((and (is-a? model <interface>)
                      (eq? (.event next) event)
                      n-port
                      *component*
                      (eq? (.direction (om:port *component* n-port)) 'requires)
                      ;;(eq? (.direction (om:event model event)) 'out)
                      )
                 (clone info :trail (cdr trail) :return next))
                ((is-a? model <component>)
                 (if (not (eq? n-port port)) info
                     (clone info :trail (cdr trail))))
                (else
                 ;; asymmetry: next-* must be called if we expect it to succeed
                 (debug "NOT-Q-ABLE: QUEUE[~a expect:~a]: next:~a\n" (.name model) "??" next)
                 (clone info :error #t)))))))

(define (next-reply model info trigger)
  "eat a 'RETURN or PORT.'RETURN from trail, or error"
  (debug "next-reply[~a]: ~a\n" (.name model) (.reply info))
  (debug "trail: ~a\n" (.trail info))
  (let* ((port (.port trigger))
         (trail (.trail info)))
    (if (null? trail)
        (next-trail-empty model info 'reply (->symbol trigger))
        (let* ((reply (.reply info))
               (next (symbol->literal model (car trail)))
               (port (and (is-a? model <component>) (.scope next)))
               (scope (and port (is-a? model <component>) (.type (om:port model port))))
               (reply (make <literal> :scope scope :type (.type reply) :field (.field reply)))
               (next-reply (make <literal> :scope scope :type (.type next) :field (.field next))))
          (if (and (is-a? model <component>) (not port))
              (throw 'runtime-error "component-reply-without-port"))
          (if (equal? next-reply reply)
              (clone info :trail (cdr trail) :return next :reply reply)
              (and
               (debug "REJECT-TRACE: REPLY[~a expect:~a]: next:~a\n" (.name model) reply next-reply)
               (debug "trace: ~a\n" (map trace-location (.trace info)))
               ((cons-trace
                 (list 'reject 'reply (.name model) 'next next-reply 'expected reply))
                (clone info :error #t))))))))

(define (next-return model info trigger)
  "eat a 'RETURN or PORT.'RETURN from trail, or error"
  (debug "next-return[~a]: ~a\n" (.name model) (.trail info))
  (let* ((event (.event trigger)))
    (if (modeling? trigger) info
        (let* ((port (.port trigger))
               (trail (.trail info))
               (port (and (is-a? model <component>) (.port trigger)))
               (return (make <trigger> :port port :event 'return))
               (port (.port trigger))
               (port (if (modeling? trigger) event port))
               (reply (make <trigger> :port port :event 'return)))
          (debug "next-return: trigger: ~a\n" (->symbol trigger))
          (if (null? trail)
              (next-trail-empty model info 'return (->symbol trigger))
              (let ((next (symbol->trigger (car trail))))
                (cond ((or (trigger-equal? next reply)
                           (and (not (.port reply))
                                (eq? (.event next) (.event reply))))
                       (clone info :trail (cdr trail) :return return))
                      (else
                       (debug "REJECT-TRACE: RETURN[~a expect:~a] next: ~a\n" (.name model) reply next)
                       (debug "trail: ~a\n" (.trail info))
                       (debug "AT: ~a\n" (trace-location (.ast info)))
                       ((cons-trace
                         (list 'reject 'return (.name model) 'next next 'expected reply))
                        (clone info :reply (make <literal>) :error #t))))))))))

(define (next-value model info trigger action)
  "eat a ENUM_FIELD or PORT.ENUM_FIELD from trail, or error"
  (let* ((info (next-action model info trigger action))
         (trail (.trail info)))
    (debug "next-value[~a ~a]: ~a\n" (.name model) action trail)
    (if (null? trail)
        (next-trail-empty model info 'value (->symbol action))
        (let* ((value (car trail))
               (return (symbol->literal model value))
               (reply (if (and #f (is-a? model <interface>)) return
                          (let* ((port (.port action))
                                 (scope (.type (om:port model port))))
                            (make <literal> :scope scope :type (.type return) :field (.field return)))))
               (return (make <return> :expression return)))
          (debug "SETTING reply[~a]: ~a\n" (.name model) reply)
          (clone info :trail (cdr (.trail info)) :reply reply)))))

(define (next-trail-empty-reject model info name o)
  (debug "REJECT-TRACE ~a[~a]: ~a NULL\n" (.name model) name o)
  (clone info :error #t))
(define (next-trail-empty-allow model info name o) info)
(define next-trail-empty next-trail-empty-reject)
;;(define next-trail-empty next-trail-empty-allow)

(define (symbol->literal model literal)
  (let* ((port-value (symbol-split literal #\.))
         (port (and (=2 (length port-value)) (car port-value)))
         (value (if (=2 (length port-value)) (cadr port-value) (car port-value)))
         (type-field (symbol-split value #\_))
         (type (and (=2 (length type-field)) (car type-field)))
         (field (if (=1 (length type-field)) (car type-field) (cadr type-field)))
         (port-def (and port (is-a? model <component>) (om:port model port)))
         (scope (or (and port-def (.name port-def)) port)))
    (make <literal> :scope scope :type type :field field)))

(define (skip-trail info port)
  (if (not port) barf-no-port)
  (let loop ((info info))
    (debug "SKIP-LOOP[~a]: ~a\n" port (.trail info))
    (let ((trail (.trail info)))
      (if (or (null? trail)
              (let ((trigger (symbol->trigger (car trail))))
                (or (not trigger)
                    (not (.port trigger))
                    ;;;(and (not port) (eq? (.event trigger) 'return))
                    (eq? (.port trigger) port))))
          info
          (loop (clone info :trail (cdr trail)))))))

(define (next-info-trail-walker)
  (lambda (model info)
    info))

(define (get-state info name)
  (assoc-ref (.state-alist info) name))

(define (set-state info name state)
  (clone info :state-alist (acons name state (filter (lambda (x) (not (eq? (car x) name))) (.state-alist info)))))

(define (state->string state)
  (comma-space-join (map (lambda (s) (->string (list (car s) "=" (cdr s)))) state)))

(define (clone o . args)
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
  (debug "ENQ!: ~a\n" trigger)
  (clone info :q (append (.q info) (list trigger))))

(define (deq info)
  (clone info :q (cdr (.q info))))

(define (peeq info)
  (and (pair? (.q info)) (car (.q info))))

(define (appendq info add)
  (clone info :q (append (.q info) (.q add))))

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

(define (unspecified? x) (eq? x *unspecified*))
(define (->symbol src)
  (match src
    (#f 'false)
    (#t 'true)
    (($ <expression> expression) (->symbol expression))
    (($ <var> identifier) identifier)
    (($ <field> type field) (->symbol (list (->symbol type) "." field)))
    (($ <literal> #f type field) (->symbol (list (->symbol type) "_" (->symbol field))))
    (($ <literal> scope type field) (->symbol (list scope '. type '_  field)))
    (($ <trigger> #f event) (->symbol event))
    (($ <trigger> port event) (->symbol (list port "." event)))
    ((h ... t) (apply symbol-append (map ->symbol src)))
    (((h ... t)) (->symbol (car src)))
    ((? string?) (string->symbol src))
    ((? number?) (number->symbol src))
    ((? symbol?) src)
    ((h . t) (->symbol (list (->symbol h) '. (->symbol t))))
    ((h . t) 'URG-CONS-BUG)
    (() 'URG-NULL-BUG)
    ((? unspecified?) '*unspecfied*)
    ))

;; model checker...broken for now -- keep interface
(define (next-info-space-explorer model info)
  (lambda (model info)
    info))

;;(define debug-pretty pretty-print)
;;(define debug stderr)
;;(define debug-state print-state)
