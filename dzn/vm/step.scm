;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn vm step)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm util)
  #:export (%liveness?
            begin-step
            step))

;;; Commentary:
;;;
;;; ’step’ implements single stepping the Dezyne vm.
;;;
;;; Code:

;; Are we running the "liveness" check?
(define %liveness? (make-parameter #f))

;;;
;;; A ’step’ run starts by inserting an EVENT (’coin’) in BEGIN-STEP.
;;; On the resulting PCs, 'step' is called until run to completion.
;;;

(define-method (begin-step (pc <program-counter>) (event <string>)) ; -> (list <program-counter>)
  "Return a <program-counter> by seting-up PC for taking the first
'step' for EVENT."
  (begin-step pc (string->trigger event)))

(define-method (begin-step (pc <program-counter>) (trigger <trigger>))
  (begin-step pc (.instance pc) trigger))

(define-method (begin-step (pc <program-counter>) (instance <boolean>) (trigger <trigger>))
  (define (component-instance+trigger)
    (let* ((r:port (runtime:port-name->instance (.port.name trigger)))
           (r:component-port (runtime:other-port r:port))
           (event (.event.name trigger))
           (modeling? (member event '("optional" "inevitable")))
           (trigger (if modeling? (trigger->port-trigger r:port trigger)
                        (trigger->component-trigger r:component-port trigger)))
           (instance (if modeling? r:port
                         (.container r:component-port))))
      (values instance trigger)))
  (let ((instance trigger (if (is-a? (%sut) <runtime:port>)
                              (values (%sut) trigger)
                              (component-instance+trigger))))
    (begin-step pc instance trigger)))

(define-method (begin-step (pc <program-counter>) (o <runtime:system>) (trigger <trigger>))
  (let* ((port-name (.port.name trigger))
         (r:port (runtime:port-name->instance port-name))
         (r:component-port (runtime:other-port r:port))
         (component-trigger (trigger->component-trigger trigger)))
    (begin-step pc (.container r:component-port) component-trigger)))

(define-method (begin-step (pc <program-counter>) (instance <runtime:instance>) (trigger <trigger>))
  (define (trigger-runtime-port pc)
    (runtime:port (.instance pc) (.port (.trigger pc))))
  (let* ((pc (push-pc pc trigger instance))
         (port (.port trigger))
         (instance (.instance pc))
         (port-name (or (.port.name trigger)
                        (.name (.ast instance))))
         (pc (if (and port (ast:provides? port)) (reset-reply pc port-name)
                 pc))
         (r:port (and port (runtime:port instance port))))
    (unless r:port
      (throw 'programming-error (format #f "trigger without port ~a" trigger)))
    (cond
     ((and (is-a? instance <runtime:component>)
           (or (get-handling pc instance)
               (assq r:port (.blocked pc)))
           (blocked-port pc instance))
      (%debug (current-source-location) "<blocked-error> collateral ~a ~a" (name instance) (trigger->string trigger))
      (let ((message (format #f "port `~a' is collaterally blocked"
                             (.name port))))
        (clone pc #:status (make <blocked-error>
                             #:ast (.statement pc)
                             #:message message))))
     ((let* ((r:other-port (runtime:other-port r:port))
             (blocked (append (.blocked pc) (.collateral pc)))
             (blocked (map (compose rtc-block-pc cdr) blocked))
             (blocked (filter .instance blocked))
             (ports (map (compose runtime:other-port
                                  trigger-runtime-port)
                         blocked)))
        (or (assq r:port (.blocked pc))
            (and (ast:provides? trigger)
                 (member r:other-port ports ast:equal?))))
      (%debug (current-source-location) "<blocked-error> blocked ~a ~a" (name instance) (trigger->string trigger))
      (let ((message (format #f "port `~a' is blocked" (.name port))))
        (clone pc #:status (make <blocked-error>
                             #:ast (.statement pc)
                             #:message message))))
     (else
      (let ((pc (set-handling! pc)))
        pc)))))

(define-method (begin-step (pc <program-counter>) (instance <runtime:foreign>) (trigger <trigger>))
  (let* ((port (.port trigger))
         (r:port (runtime:port instance port))
         (r:other-port (runtime:other-port r:port))
         (trigger (clone trigger #:port.name #f))
         (trigger (clone trigger #:parent (.type (.ast r:other-port)))))
    (begin-step pc r:other-port trigger)))

(define-method (begin-step (pc <program-counter>) (instance <runtime:port>) (trigger <trigger>))
  (let* ((pc (push-pc pc trigger instance))
         (port-name (.name (.ast instance)))
         (pc (reset-reply pc port-name)))
    pc))


;;;
;;; Step
;;;

;;; ’step’ executes the program counter's current statement and then
;;; uses ’continuation’ (see below) to return a list of program counters
;;; that pointing to the next statement.

(define-method (step (pc <program-counter>) (statement <boolean>))
  (step (pop-pc pc))) ;; .previous == #f => RTC

(define-method (step (pc <program-counter>) (o <statement>))
  (throw 'programming-error
         (format #f "statement not implemented: ~a" (ast-name o))))

(define-method (step (pc <program-counter>) (o <defer>))
  (let* ((defer (.defer pc)))
    (if (= (length defer) (%queue-size-defer))
        (let ((error (make <queue-full-error>
                       #:ast o
                       #:instance (.instance pc)
                       #:message "queue-full")))
          (list (clone pc #:status error)))
        (let ((pc (clone pc #:defer (append defer (list pc)))))
          (list (statement-continuation pc o))))))

(define-method (step (pc <program-counter>) (o <defer-qout>))
  (list (clone pc #:statement (.statement o))))

(define-method (step (pc <program-counter>) (o <initial-compound>))
  (append
   (next-method pc o)
   (if (ast:modeling? (.trigger pc)) '()
       (list (make-implicit-illegal pc o)))))

(define-method (step (pc <program-counter>) (o <declarative-compound>))
  (map (cut clone pc #:statement <>) (ast:statement* o)))

(define (mark-liveness? pc statement)
  (and (%liveness?)
       (or (and (eq? (%liveness?) 'component)
                (is-a? (.instance pc) <runtime:component>))
           (and (eq? (%liveness?) 'port)
                (is-a? (.instance pc) <runtime:port>)))
       (not (is-a? statement <compound>))
       (not (is-a? statement <illegal>))
       (ast:imperative? statement)
       (let ((pc (clone pc #:status (make <end-of-trail>))))
         (list pc))))

(define-method (step (pc <program-counter>) (o <guard>))
  (let* ((statement (.statement o))
         (continuation (continuation pc (list statement)))
         (statement (.statement continuation)))
    (cond ((not (true? (eval-expression pc (.expression o))))
           '())
          ((mark-liveness? pc statement))
          (else
           (list continuation)))))

(define-method (step (pc <program-counter>) (o <on>))
  (let ((statement (.statement o))
        (trigger (.trigger pc)))
    (cond ((not (find (cute ast:trigger-equal? <> trigger) (ast:trigger* o)))
           (%debug (current-source-location) pc
                   (format #f "on does not match trigger: ~a"
                           (trigger->string trigger)))
           '())
          ((mark-liveness? pc statement))
          (else
           (list (clone pc #:statement statement))))))

(define-method (step (pc <program-counter>) (o <illegal>))
  (let ((error (make <illegal-error> #:message "illegal" #:ast o)))
    (list (clone pc #:status error))))

(define-method (step (pc <program-counter>) (o <compound>))
  (let* ((continuation (continuation pc o))
         (statement (.statement continuation)))
    (cond ((mark-liveness? pc statement))
          (else
           (list continuation)))))

(define-method (step (pc <program-counter>) (o <skip>))
  (let* ((continuation (continuation pc o))
         (statement (.statement continuation)))
    (cond ((mark-liveness? pc statement))
          (else
           (list continuation)))))

(define-method (step (pc <program-counter>) (o <if>))
  (if (true? (eval-expression pc (.expression o))) (list (continuation pc ((compose list .then) o)))
      (if (.else o) (list (continuation pc ((compose list .else) o)))
          (list (statement-continuation pc o)))))

(define-method (step (pc <program-counter>) (o <call>))
  (let* ((function (.function o))
         (args (map (cute eval-expression pc <>) (ast:argument* o)))
         (continuation-pc (continuation pc o))
         (next (.statement continuation-pc))
         (pc (if (and (is-a? next <return>)
                      (is-a? (ast:type next) <void>))
                 ;; tail call: call/return elimination
                 (continuation continuation-pc (.statement continuation-pc))
                 continuation-pc))
         (pc (push-pc pc (.statement function)))
         (pc (fold (cute push-local <> <> <>) pc (ast:formal* function) args))
         (status (.status pc)))
    (if (is-a? status <error>) (list (clone pc #:status (clone status #:ast o)))
        (list pc))))

(define-method (step (pc <program-counter>) (o <return>))
  (let ((pc (clone pc #:return (eval-expression pc (.expression o)))))
    (list (continuation pc o))))

(define-method (step (pc <program-counter>) (o <action>))
  (cond ((ast:out? o)
         (step-action-up pc o))
        (else
         (step-action-down pc o))))

(define-method (step-action-down (pc <program-counter>) (o <action>))
  (let* ((instance (.instance pc))
         (port (.port o))
         (r:port (runtime:port instance port))
         (other-instance other-port (runtime:other-instance+port instance r:port))
         (trigger (action->trigger other-port o))
         (orig-pc pc)
         (pc (continuation pc o)))
    (cond
     ((and (runtime:boundary-port? other-port)
           (ast:requires? other-port)
           (ast:external? other-port))
      (let* ((run-external-modeling (@ (dzn vm run) run-external-modeling))
             (silent-traces (run-external-modeling pc other-instance))
             (silent-pcs (map car silent-traces))
             (pcs (cons pc silent-pcs)))
        (map (cute begin-step <> other-instance trigger) pcs)))
     ((runtime:boundary-port? other-port)
      (list (begin-step pc other-instance trigger)))
     ((and (is-a? other-instance <runtime:component>)
           (or (get-handling pc other-instance)
               (or (assoc-ref (.blocked pc) other-port)
                   (assoc-ref (.blocked pc) r:port)))
           (or (blocked-port pc other-instance)
               (and=> (.previous pc) blocked-on-boundary?)))
      (let ((pc (collateral-block orig-pc other-instance)))
        (list pc)))
     ((is-a? other-instance <runtime:component>)
      (list (begin-step pc other-instance trigger)))
     (else
      (list pc)))))

(define-method (step-action-up (pc <program-counter>) (o <action>))
  (let* ((instance (.instance pc))
         (port (.port o))
         (r:port (runtime:port instance (.port o)))
         (other-instance other-port (runtime:other-instance+port instance r:port))
         (orig-pc pc)
         (pc (continuation pc o)))

    (define (q-trigger)
      (let* ((port-name (.name (.ast other-port)))
             (trigger (.trigger pc))
             (q-trigger (make <q-trigger>
                          #:event.name (.event.name o)
                          #:port.name port-name
                          #:modeling? (or (ast:modeling? trigger)
                                          (and=> (as trigger <q-trigger>)
                                                 .modeling?))
                          #:location (.location o))))
        (clone q-trigger #:parent (.type (.ast other-instance)))))

    (cond
     ((and (is-a? instance <runtime:port>)
           (ast:requires? (.ast instance))
           (ast:external? (.ast instance)))
      (list (enqueue-external pc o (q-trigger))))
     ((is-a? (%sut) <runtime:port>)
      (list pc))
     ((and (is-a? instance <runtime:port>)
           (ast:provides? (.ast instance)))
      (list pc))
     ((and (is-a? instance <runtime:port>)
           (ast:requires? (.ast instance))
           other-instance)
      (list (enqueue pc o other-instance (q-trigger))))
     ((is-a? other-instance <runtime:component>)
      (list (enqueue pc o other-instance (q-trigger))))
     ((runtime:boundary-port? other-port)
      (list pc)))))

(define-method (step (pc <program-counter>) (o <assign>))
  (let* ((pc (assign pc (.variable o) (.expression o)))
         (status (.status pc)))
    (if (is-a? status <range-error>)
        (list (clone pc #:status (clone status #:ast o)))
        (list (continuation pc o)))))

(define-method (step (pc <program-counter>) (o <variable>))
  (let* ((pc (assign (push-local pc o) o (.expression o)))
         (pc (if (is-a? (.parent o) <compound>) pc
                 (pop-locals pc (list o)))))
    (list (continuation pc o))))

(define-method (step (pc <program-counter>) (o <reply>))
  (let* ((instance (.instance pc))
         (port-name (or (.port.name o)
                        (.port.name (.trigger pc))
                        (.name (.ast instance))))
         (previous (get-reply pc port-name))
         (value (eval-expression pc (.expression o)))
         (pc (cond (previous
                    (let ((error (make <second-reply-error>
                                   #:ast o
                                   #:previous (.parent previous)
                                   #:message "second-reply")))
                      (%debug (current-source-location) "second reply, previous=~a" (ast:location->string previous))
                      (clone pc #:status error)))
                   ((is-a? value <void>)
                    (continuation pc o))
                   (else
                    (continuation (set-reply pc port-name value) o))))
         (reply-port (.port o))
         (trigger (.trigger pc)))
    (cond ((let* ((trigger-port (.port trigger))
                  (stack (pc->stack pc))
                  (instance-stack (filter
                                   (compose (cute eq? <> instance) .instance)
                                   stack))
                  (statements (map .statement instance-stack))
                  (blocking? (or (pair? (.blocked pc))
                                 (any (cute ast:parent <> <blocking>)
                                      statements)))
                  (ports-eq? (ast:eq? reply-port trigger-port)))
             (and reply-port
                  (or blocking?
                      (and (or (ast:eq? (and=> (rtc-trigger pc) .port) reply-port)
                               (not (and=> (as trigger <q-trigger>) .modeling?)))
                           (or (ast:provides? (rtc-trigger pc))
                               (not (is-a? (ast:type value) <void>)))))
                  (or (ast:requires? trigger)
                      (not ports-eq?)
                      (and ports-eq? blocking?))))
           (let* ((r:port (runtime:port instance reply-port))
                  (released (.released pc))
                  (released (if (memq r:port released) released
                                (append released (list r:port))))
                  (pc (clone pc #:released released)))
             (list pc)))
          ((or (ast:modeling? trigger)
               (and=> (as trigger <q-trigger>) .modeling?)
               (and reply-port
                    (null? (.blocked pc))
                    (not (ast:provides? (rtc-trigger pc)))
                    (is-a? (ast:type value) <void>)
                    (or (ast:eq? (.port (rtc-trigger pc)) reply-port)
                        (not (and=> (as trigger <q-trigger>) .modeling?)))))
           (let* ((error (make <deadlock-error> #:ast o #:message "deadlock"))
                  (pc (clone pc #:status error)))
             (list pc)))
          (else
           (list pc)))))

(define-method (step (pc <program-counter>) (o <flush-return>))
  (let ((pc (pop-pc pc)))
    (list pc)))

(define-method (step (pc <program-counter>) (o <q-out>))
  (let* ((q-trigger (.trigger o))
         (instance (.instance pc))
         (pc (pop-pc pc))
         (other-instance
          other-port
          (if (is-a? instance <runtime:port>)
              (runtime:other-instance+port instance)
              (runtime:other-instance+port
               instance (runtime:port instance (.port q-trigger))))))
    (cond
     ((and (is-a? other-instance <runtime:port>)
           (ast:requires? (.ast other-instance)))
      (list (begin-step pc q-trigger)))
     ((and (is-a? other-instance <runtime:port>)
           (ast:provides? (.ast other-instance)))
      (list pc))
     ((is-a? other-instance <runtime:component>)
      (list (begin-step pc q-trigger)))
     ((is-a? instance <runtime:component>)
      (let* ((pc (clone pc #:instance instance))
             (pc (begin-step pc instance q-trigger)))
        (list pc))))))

(define-method (step (pc <program-counter>) (o <blocking>))
  (list (continuation pc o)))

(define-method (step (pc <program-counter>) (o <block>))
  (if (not (q-empty? pc)) (let ((pc (set-handling! pc)))
                            (list (flush pc)))
      (let ((pc (continuation pc o))
            (trigger (.trigger pc)))
        (if (ast:requires? trigger) (list pc)
            (let* ((locals (filter (is? <variable>) (ast:statement* (.parent o))))
                   (pc (pop-locals pc locals))
                   (instance (.instance pc))
                   (r:port (runtime:port instance (.port trigger))))
              (cond
               ((memq r:port (.released pc))
                (let ((pc (clone pc #:released (delete r:port (.released pc)))))
                  (list pc)))
               (else
                (let ((pc (block pc r:port)))
                  (list pc)))))))))

(define-method (step (pc <program-counter>) (o <tag>))
  (list (continuation pc o)))

(define-method (step (pc <program-counter>) (o <the-end>))
  (list (continuation pc o)))

(define-method (step (pc <program-counter>) (o <end-of-on>))
  (let* ((deferred (pop-deferred pc))
         (pc (reset-handling! pc))
         (trigger (.trigger pc))
         (previous (.previous pc))
         (instance (.instance pc))
         (stack (pc->stack pc))
         (stack (drop-right stack 1))
         (queue-lengths (map (compose length .q (cute get-state <> instance))
                             stack))
         (livelock? (not (apply <= queue-lengths))))
    (cond
     ((and (is-a? instance <runtime:component>)
           (or (and (not (q-empty? pc))
                    (not livelock?))
               (and (not (q-empty? pc deferred))
                    (not (get-handling pc deferred)))))
      (list (flush pc)))
     ((.status pc)
      (list (pop-pc pc)))
     ((ast:out? trigger)
      (let* ((locals (filter (is? <variable>) (ast:statement* (.parent o))))
             (pc (pop-locals pc locals)))
        (list (pop-pc pc))))
     (else
      (let* ((port-name (or (.port.name (.trigger pc))
                            (.name (.ast instance))))
             (value (->sexp (get-reply pc port-name)))
             (value (or (and (not (equal? value "void")) value) "return"))
             (return (make <trigger-return>
                       #:location (.location o)
                       #:port.name (.port.name (.trigger pc))
                       #:event.name value))
             (return (clone return #:parent (.parent o)))
             (pc (clone pc #:statement return)))
        (list pc))))))

(define-method (step (pc <program-counter>) (o <trigger-return>))
  (define (typed-reply? pc o)
    ;;FIXME: simplify
    (let ((instance (.instance pc))
          (port (.port (.trigger pc))))
      (and (not (and (is-a? instance <runtime:port>)
                     (is-a? (.event (.trigger pc)) <modeling-event>)))
           (not (and (is-a? instance <runtime:component>) (not port)))
           (or (is-a? (.instance pc) <runtime:port>)
               (let* ((r:port (runtime:port instance port))
                      (other-port (runtime:other-port r:port)))
                 (and (is-a? (.instance pc) <runtime:component>)
                      (runtime:boundary-port? other-port)
                      (ast:provides? (.ast other-port)))))
           (let* ((trigger (.trigger pc))
                  (type (ast:type trigger))
                  (typed? (ast:typed? type))
                  (port-name (or (.port.name o)
                                 (.port.name (.trigger pc))
                                 (.name (.ast instance))))
                  (value (get-reply pc port-name)))
             (and typed? (not value))))))

  (cond
   ((typed-reply? pc o)
    (let* ((trigger (.trigger pc))
           (type (ast:type trigger))
           (typed? (ast:typed? type))
           (error (make <missing-reply-error> #:ast o #:type type
                        #:message "missing-reply")))
      (%debug (current-source-location) "missing reply")
      (list (clone pc #:status error))))
   (else
    (let* ((trigger (.trigger pc))
           (blocking? (and (ast:provides? trigger)
                           (ast:parent o <blocking>)))
           (pc (if (or blocking? (.status pc)) pc
                   (let ((locals (filter (is? <variable>)
                                         (ast:statement* (.parent o)))))
                     (pop-locals pc locals))))
           (port (.port o))
           (instance (.instance pc))
           (value (and port (get-reply pc (.name port))))
           (pc (if (not blocking?) pc
                   (let* ((r:port (runtime:port instance port))
                          (blocked (.blocked pc))
                          (blocked? (assq-ref blocked r:port))
                          (blocked (if (not blocked?) blocked
                                       (alist-delete r:port blocked)))
                          (collateral (.collateral pc))
                          (collateral-released (.collateral-released pc))
                          (collateral? (assq-ref collateral r:port))
                          (collateral-released
                           (if (not collateral?) collateral-released
                               (append collateral-released (list r:port))))
                          (released (.released pc))
                          (released (delete r:port released)))
                     (clone pc
                            #:blocked blocked
                            #:released released
                            #:collateral-released collateral-released))))
           (reset-blocked-on-boundary?
            (and (blocked-on-boundary? pc)
                 (eq? instance (blocked-on-boundary? pc))))
           (pc (if reset-blocked-on-boundary? (blocked-on-boundary-reset pc)
                   pc)))
      (list (pop-pc pc))))))


;;;
;;; Continuation
;;;

(define-method (continuation (pc <program-counter>) (o <blocking>))
  (clone pc #:statement (.statement o)))

(define-method (continuation (pc <program-counter>) (o <compound>))
  (let ((list (ast:statement* o)))
    (if (null? list) (statement-continuation pc o)
        (continuation pc (ast:statement* o)))))

(define-method (continuation (pc <program-counter>) (o <list>))
  (clone pc #:statement (if (null? o) '()
                            (let ((statement (car o)))
                              (match statement
                                ((and (or ($ <assign>) ($ <variable>))
                                      (and (or (= .expression ($ <action>))
                                               (= .expression ($ <call>)))
                                           (= .expression action))) action)
                                (_ statement))))))

(define-method (continuation (pc <program-counter>) (o <statement>))
  (let ((parent (.parent o)))
    (match parent
      (($ <compound>) (statement-continuation pc o))
      (($ <if>) (statement-continuation pc parent))
      (($ <defer>)
       (clone pc #:statement #f))
      (($ <defer-qout>)
       (clone pc #:statement #f))
      (_
       '()))))

(define-method (statement-continuation (pc <program-counter>) (o <statement>))
  (let ((p (.parent o)))
    (match p
      (($ <compound>)
       (let ((next (and=> (member o (ast:statement* p) ast:eq?) cdr)))
         (if (pair? next) (continuation pc next)
             (let ((pc (pop-locals pc (filter (is? <variable>) (ast:statement* p)))))
               (statement-continuation pc p)))))
      (($ <if>)
       (statement-continuation pc p))
      (($ <function>)
       (pop-pc pc))
      (($ <defer>)
       (clone pc #:statement #f))
      (($ <defer-qout>)
       (let* ((p (ast:parent p <compound>))
              (pc (if (not p) pc
                      (let* ((variables (get-variables pc))
                             (model (ast:parent o <model>))
                             (members (ast:member* model))
                             (locals (drop-right variables (length members))))
                        (pop-locals pc locals)))))
         (clone pc #:statement #f)))
      (_
       '()))))

(define-method (continuation (pc <program-counter>) (o <action>))
  (match (.parent o)
    ((and (or ($ <assign>) ($ <variable>)) assign) (clone pc #:statement assign))
    (_ (next-method))))

(define-method (continuation (pc <program-counter>) (o <call>))
  (match (.parent o)
    ((and (or ($ <assign>) ($ <variable>)) assign) (clone pc #:statement assign))
    (_ (next-method))))

(define-method (function-return (pc <program-counter>) (o <statement>))
  (let ((parent (.parent o)))
    (match parent
      (($ <compound>)
       (let* ((statements (member o (reverse (ast:statement* parent)) ast:eq?))
              (pc (pop-locals pc (filter (is? <variable>) statements))))
         (function-return pc parent)))
      (($ <function>)
       (let* ((formals (ast:formal* parent))
              (pc (pop-locals pc formals)))
         (pop-pc pc)))
      (_
       (function-return pc parent)))))

(define-method (continuation (pc <program-counter>) (o <return>))
  (function-return pc o))
