;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
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
  #:use-module (ice-9 match)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

  #:use-module (dzn ast)
  #:use-module (dzn misc)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm normalize)
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
  (%debug "* ~s ~s ~a\n" (name instance) (trigger->string trigger) "<begin-step>")
  (let* ((pc (push-pc pc trigger instance))
         (pc (set-handling? pc #t))
         (port (.port trigger))
         (pc (if (and port (ast:provides? port)) (set-reply pc #f)
                 pc))
         (r:port (and port (runtime:port instance port))))
    (if (not (assoc r:port (.blocked pc))) pc
        (clone pc #:status (make <blocked-error>
                             #:ast (.statement pc)
                             #:message (format #f "port `~a' is blocked" (.name port)))))))

(define-method (begin-step (pc <program-counter>) (instance <runtime:port>) (trigger <trigger>))
  (%debug "* ~s ~s ~a\n" (name instance) (trigger->string trigger) "<begin-step>")
  (let* ((pc (push-pc pc trigger instance))
         (pc (set-reply pc #f)))
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
  (%debug "MISSING: ~a ~a\n" ((compose name .instance) pc) (name o))
  '())

(define-method (step (pc <program-counter>) (o <initial-compound>))
  (append
   (next-method pc o)
   (if (ast:modeling? (.trigger pc)) '()
       (let ((illegal (make <implicit-illegal-error> #:ast o #:message "illegal")))
         (list (clone pc #:previous #f #:status illegal))))))

(define-method (step (pc <program-counter>) (o <declarative-compound>))
  (%debug "  ~s ~s |~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (map (cut clone pc #:statement <>) (ast:statement* o)))

(define (mark-liveness? pc statement)
  (and (%liveness?)
       (is-a? (.instance pc) <runtime:component>)
       (not (is-a? statement <compound>))
       (not (is-a? statement <illegal>))
       (ast:imperative? statement)
       (let* ((pc (clone pc #:status (make <end-of-trail>))))
         (list pc))))

(define-method (step (pc <program-counter>) (o <guard>))
  (%debug "  ~s ~s |~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let* ((statement (.statement o))
         (continuation (continuation pc (list statement)))
         (statement (.statement continuation)))
    (cond ((not (true? (eval-expression pc (.expression o))))
           '())
          ((mark-liveness? pc statement))
          (else
           (list continuation)))))

(define-method (step (pc <program-counter>) (o <on>))
  (%debug "  ~s ~s |~a ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o) ((compose trigger->string car ast:trigger*) o))
  (let ((statement (.statement o)))
    (cond ((not (find (cute ast:trigger-equal? <> (.trigger pc)) (ast:trigger* o)))
           '())
          ((mark-liveness? pc statement))
          (else
           (list (clone pc #:statement statement))))))

(define-method (step (pc <program-counter>) (o <illegal>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (list (clone pc #:previous #f #:status (make <illegal-error> #:message "illegal" #:ast o))))

(define-method (step (pc <program-counter>) (o <compound>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let* ((continuation (continuation pc o))
         (statement (.statement continuation)))
    (cond ((mark-liveness? pc statement))
          (else
           (list continuation)))))

(define-method (step (pc <program-counter>) (o <if>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (if (true? (eval-expression pc (.expression o))) (list (continuation pc ((compose list .then) o)))
      (if (.else o) (list (continuation pc ((compose list .else) o)))
          (list (statement-continuation pc o)))))

(define-method (step (pc <program-counter>) (o <call>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
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
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let ((pc (clone pc #:return (eval-expression pc (.expression o)))))
    (list (continuation pc o))))

(define-method (step (pc <program-counter>) (o <action>))
  (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o) (trigger->string o))
  (cond ((ast:out? o)
         (step-action-up pc o))
        ((ast:async? o)
         (step-async-action-down pc o))
        (else
         (step-action-down pc o))))

(define-method (step-action-down (pc <program-counter>) (o <action>))
  (let* ((instance (.instance pc))
         (port (.port o))
         (r:port (runtime:port instance port))
         (other-instance other-port (runtime:other-instance+port instance r:port))
         (trigger (action->trigger other-port o))
         (pc (continuation pc o)))
    (cond
     ((is-a? other-instance <runtime:component>)
      (list (begin-step pc other-instance trigger)))
     ((runtime:boundary-port? other-port)
      (let* ((silent-traces ((@ (dzn vm run) run-silent) pc other-instance))
             (silent-pcs (map car silent-traces))
             (pcs (cons pc silent-pcs)))
        (map (cute begin-step <> other-instance trigger) pcs)))
     (ast:injected? port
      (list pc)))))

(define (step-async-action-down pc o)
  (match (.event.name o)
    ("req"
     (let* ((instance (.instance pc))
            (trigger (clone (make <q-trigger> #:port.name (.port.name o) #:event.name "ack")
                            #:parent ((compose .behaviour .type .ast) instance)))
            (ack (lambda (pc) (list (begin-step pc instance trigger))))
            (rank (.rank instance))
            (r:port (runtime:port instance (.port o)))
            (req-pending? (find (compose (cute ast:eq? r:port <>) cadr) (.async pc))))
       (if req-pending?
           (list (clone pc #:status (make <illegal-error> #:message "illegal" #:ast o)))
           (let ((pc (clone pc #:async (acons rank (cons r:port ack) (.async pc)))))
             (list (continuation pc o))))))
    ("clr"
     (let* ((instance (.instance pc))
            (r:port (runtime:port instance (.port o)))
            (timers (.async pc))
            (canceled (find (compose (cut ast:eq? <> r:port) cadr) (reverse timers)))
            (timers (reverse (delete canceled timers eq?)))
            (pc (clone pc #:async timers)))
       (list (continuation pc o))))
    (_
     (throw 'debug "no such async trigger" o))))

(define-method (step-action-up (pc <program-counter>) (o <action>))
  (let* ((instance (.instance pc))
         (port (.port o))
         (r:port (runtime:port instance (.port o)))
         (other-instance other-port (runtime:other-instance+port instance r:port))
         (pc (continuation pc o)))

    (define (q-trigger)
      (let* ((port-name (.name (.ast other-port)))
             (q-trigger (make <q-trigger>
                         #:event.name (.event.name o)
                         #:port.name port-name
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
           (ast:requires? (.ast instance)))
      (list (enqueue pc o other-instance (q-trigger))))
     ((is-a? other-instance <runtime:component>)
      (list (enqueue pc o  other-instance (q-trigger))))
     ((runtime:boundary-port? other-port)
      (list pc)))))

(define-method (step (pc <program-counter>) (o <assign>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let* ((pc (assign pc (.variable o) (.expression o)))
         (status (.status pc)))
    (if (is-a? status <range-error>)
        (list (clone pc #:status (clone status #:ast o)))
        (list (continuation pc o)))))

(define-method (step (pc <program-counter>) (o <variable>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let* ((pc (assign (push-local pc o) o (.expression o)))
         (pc (if (is-a? (.parent o) <compound>) pc
                 (pop-locals pc (list o)))))
    (list (continuation pc o))))

(define-method (step (pc <program-counter>) (o <reply>))
  (%debug "  ~s ~s ~a => ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o) (.expression o))
  (let* ((value (get-reply pc))
         (pc (if value
                 (let ((error (make <second-reply-error> #:ast o #:previous (.parent value) #:message "second-reply")))
                   (%debug "second reply, previous=~a\n" ((@@ (dzn vm report) step->location) value))
                   (clone pc #:status error))
                 (let ((value (eval-expression pc (.expression o))))
                   (continuation (set-reply pc value) o))))
         (reply-port (.port o)))
    (cond ((ast:modeling? (.trigger pc))
           (let ((pc (clone pc #:status (make <deadlock-error> #:ast o #:message "deadlock"))))
             (list pc)))
          ((let* ((trigger (.trigger pc))
                  (trigger-port (.port trigger))
                  (blocking? (parent o <blocking>))
                  (ports-eq? (ast:eq? reply-port trigger-port)))
             (and reply-port
                  (or (ast:requires? trigger)
                      (and ports-eq? blocking?)
                      (and (not ports-eq?) (not blocking?)))))
           (let* ((r:port (runtime:port (.instance pc) reply-port))
                  (pc (clone pc #:released r:port)))
             (list pc)))
          (else
           (list pc)))))

(define-method (step (pc <program-counter>) (o <flush-return>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let ((pc (pop-pc pc)))
    (list pc)))

(define-method (step (pc <program-counter>) (o <q-out>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let* ((q-trigger (.trigger o))
         (instance (.instance pc))
         (pc (pop-pc pc))
         (other-instance
          other-port
          (if (is-a? instance <runtime:port> )
              (runtime:other-instance+port instance)
              (runtime:other-instance+port instance (runtime:port instance (.port q-trigger))))))
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
  (%debug "  ~s ~s |~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (list (continuation pc o)))

(define-method (step (pc <program-counter>) (o <block>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (if (not (q-empty? pc)) (let ((pc (set-handling? pc #f)))
                            (list (flush pc)))
      (let ((pc (continuation pc o))
            (trigger (.trigger pc)))
        (cond ((ast:requires? trigger)
               (list pc))
              ((.released pc)
               (let ((pc (clone pc #:released #f)))
                 (list pc)))
              (else
               (let* ((instance (.instance pc))
                      (r:port (runtime:port instance (.port trigger)))
                      (pc (make <program-counter>
                            #:async (.async pc)
                            #:blocked (acons r:port pc (.blocked pc))
                            #:external-q (.external-q pc)
                            #:state (.state pc)
                            #:trail (.trail pc))))
                 (list pc)))))))

(define-method (step (pc <program-counter>) (o <unblock>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let* ((blocked (.blocked pc))
         (r:port (.released pc))
         (released (assoc-ref blocked r:port))
         (instance (.instance pc))
         (pc (clone pc
                    #:blocked (alist-delete r:port blocked)
                    #:instance (.instance released)
                    #:released #f
                    #:previous (.previous released)
                    #:statement (.statement released)
                    #:trigger (.trigger released))))
    (list pc)))

(define-method (step (pc <program-counter>) (o <end-of-on>))
  ;; XXX FIXME: programmatical flush (vs: others are normalize+ast based).
  (define (flush-other pc)
    (let* ((instance (.instance pc))
           (other-instance
            (and (is-a? instance <runtime:component>)
                 (let* ((ports (runtime:port* instance))
                        (other-ports (filter ast:provides? ports))
                        (other-port-instances (map (cut runtime:port instance <>) other-ports))
                        (other-instances (map (cut runtime:other-instance+port instance <>) other-port-instances)))
                   (find (compose pair? .q (cut get-state pc <>)) other-instances)))))
      (and other-instance
           (not (get-handling? pc other-instance))
           (list (flush pc other-instance)))))

  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (or (flush-other pc)
      (and (not (q-empty? pc))
           (not (and (is-a? (and=> (.previous pc) .statement) <flush-return>)
                     (eq? (.instance pc) (.instance (.previous pc)))))
           (list (flush pc)))
      (and (.released pc) (pair? (.blocked pc)) (step pc (make <unblock>)))
      (let ((pc (set-handling? pc #f)))
        (if (and (ast:out? (.trigger pc)) )
            (let ((pc (if (.status pc) pc
                          (pop-locals pc (filter (is? <variable>) (ast:statement* (.parent o)))))))
              (list (pop-pc pc)))
            (let* ((value (->sexp (get-reply pc)))
                   (value (or (and (not (equal? value "void")) value) "return"))
                   (return (make <trigger-return>
                             #:location (.location o)
                             #:port.name (.port.name (.trigger pc))
                             #:event.name value))
                   (pc (clone pc #:statement (clone return #:parent (.parent o)))))
              (list pc))))))

(define-method (step (pc <program-counter>) (o <trigger-return>))
  (define (valued-reply? pc o)
    ;;FIXME: simplify
    (let ((instance (.instance pc))
          (port (.port (.trigger pc))))
      (and (not (and (is-a? instance <runtime:port>)
                     (is-a? (.event (.trigger pc)) <modeling-event>)))
           (not (and port (ast:async? port)))
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
                  (value (get-reply pc)))
             (and typed? (not value))))))

  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (cond
   ((valued-reply? pc o)
    (let* ((trigger (.trigger pc))
           (type (ast:type trigger))
           (typed? (ast:typed? type))
           (error (make <missing-reply-error> #:ast o #:type type #:message "missing-reply")))
      (%debug "missing reply\n")
      (list (clone pc #:status error))))
   (else
    (let* ((parent (.parent o))
           (pc (if (.status pc) pc
                   (pop-locals pc (filter (is? <variable>) (ast:statement* parent))))))
      (list (pop-pc pc))))))

(define-method (step (pc <program-counter>) (o <flush-async>))
  (%debug "  ~s ~s ~a\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) (name o))
  (let ((timers (.async pc)))
    (if (null? timers) (list pc)
        (let* ((pc (clone pc #:instance (%sut)))
               (deadline (apply min (map car timers)))
               (entry (assoc deadline (reverse timers))))
          (match entry
            ((timeout port . proc)
             (let* ((timers (reverse (delete entry (reverse timers) eq?)))
                    (pc (clone pc #:async timers)))
               (proc pc))))))))


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
      (_ '()))))

(define-method (statement-continuation (pc <program-counter>) (o <statement>))
  (let ((parent (.parent o)))
    (match parent
      (($ <compound>)
       (let ((next (and=> (member o (ast:statement* parent) ast:eq?) cdr)))
         (if (pair? next) (continuation pc next)
             (let ((pc (pop-locals pc (filter (is? <variable>) (ast:statement* parent)))))
               (statement-continuation pc parent)))))
      (($ <if>)
       (statement-continuation pc parent))
      (($ <function>)
       (pop-pc pc))
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
