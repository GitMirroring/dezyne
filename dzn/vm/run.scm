;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn vm run)
  #:use-module (ice-9 match)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

  #:use-module (dzn ast)
  #:use-module (dzn display)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm report)
  #:use-module (dzn vm step)
  #:use-module (dzn vm util)
  #:export (%exploring?
            %next-input
            %strict?
            did-provides-out?
            filter-error
            filter-match-error
            flush-async
            flush-async-trace
            livelock?
            mark-livelock-error
            run-async
            run-async-event
            run-external
            run-external-q
            run-requires
            run-silent
            run-to-completion
            run-to-completion*))

;;; Commentary:
;;;
;;; ’run’ implements run-to-completion for the Dezyne vm: the level
;;; above 'step'.
;;;
;;; Code:

;; Is the input trail to be matched exactly?
(define %strict? (make-parameter #f))

(define %next-input (make-parameter (lambda (pc) (values #f pc))))

;; Are we running "explore"?
(define %exploring? (make-parameter #f))


;;;
;;; Run
;;;

;;; ’run’ loops over ’step’ until ’rtc?’ (run to completion done) and
;;; collects a trace (of program counters).

(define (filter-error traces)
  (let ((error rest (partition
                     (compose (conjoin (is? <error>)
                                       (negate (is-status? <match-error>)))
                              car) traces)))
    (if (pair? rest) rest
        error)))

(define (filter-illegal traces)
  (let ((illegal rest (partition
                       (compose (is-status? <illegal-error>) car)
                       traces)))
    (if (pair? illegal) illegal
        rest)))

(define (filter-implicit-illegal traces)
  (let ((illegal rest (partition
                       (compose (is-status? <implicit-illegal-error>) car)
                       traces)))
    (if (pair? rest) rest
        illegal)))

(define (filter-match-error traces)
  (let* ((match-error rest (partition
                            (compose (is-status? <match-error>) car)
                            traces))
         (valid? (find (compose (negate .status) car) rest)))
    (if (or valid? (null? match-error)) rest
        match-error)))

(define (non-deterministic? pcs)
  "Return #t when PCs are a nondeterministic set, i.e.: at least two
valid PCS have the same state and are executing an imperative statement
in the same component."
  (if (%exploring?) #f
      (let ((pcs (filter (negate .status) pcs)))
        (and (not (is-a? ((compose .type .ast %sut)) <interface>))
             (not (equal? pcs
                          (delete-duplicates pcs
                                             (lambda (a b)
                                               (equal? (pc->string a) (pc->string b))))))
             (let* ((statements (map .statement pcs))
                    (imperative (filter ast:imperative? statements)))
               (> (length imperative) 1))
             (let* ((instances (filter-map .instance pcs))
                    (types (map (compose .type .ast) instances))
                    (components (filter (is? <component>) types)))
               ;; TODO: the *same* component (tests have only 1 component anyway...)
               (> (length components) 1))))))

(define (mark-determinism-error trace)
  "Truncate TRACE up to including the component <initial-compound> and
mark it with <determinism-error>."
  (let* ((index (list-index (conjoin (compose (is? <runtime:component>) .instance)
                                     (compose (is? <initial-compound>) .statement))
                            trace))
         (pc (list-ref trace index))
         (trace (drop trace index))
         (error (make <determinism-error> #:ast (.statement pc) #:message "determinism"))
         (pc (clone pc #:status error)))
    (cons pc trace)))

(define (mark-livelock-error trace)
  (let* ((pc (car trace))
         (error (make <livelock-error> #:ast (.statement pc) #:message "livelock"))
         (pc (clone pc #:status error)))
    (cons pc (cdr trace))))

(define %livelock-trace-threshold (make-parameter 42))
(define livelock?
  (lambda (trace)
    (define* (livelock-check trace)
      (let ((trace (filter (lambda (pc) (and (is-a? (.instance pc) <runtime:component>)
                                             (not (is-a? (.statement pc) <initial-compound>)))) trace)))
        (and (pair? trace)
             (member (car trace) (cdr trace) pc:eq?))))
    (define (suffixes trace)
      (let loop ((res '()) (trace trace))
        (if (null? trace) res
            (loop (cons trace res) (cdr trace)))))
    (if (< (length trace) (%livelock-trace-threshold)) #f
        (let ((lifelock-trace (find livelock-check (suffixes trace))))
          (when (not lifelock-trace)
            (%livelock-trace-threshold (* 2 (%livelock-trace-threshold))))
          lifelock-trace))))

(define-method (extend-trace (trace <list>))
  "Return a list of traces, produced by appending TRACE to each of the
program-counters produced by taking a step."

  (define* ((mark-pc input o) pc)
    (%debug "match fail, ast ~s, input ~s\n" (name o) input)
    (cond ((.status pc)
           pc)
          (input
           (clone pc #:status (make <match-error> #:ast o #:input input #:message "match")))
          (else
           (clone pc #:status (make <end-of-trail> #:ast o #:input input #:labels (make <labels> #:elements (list o)))))))

  (define (matching? pc input step-string)
    (cond ((%strict?)
           (or (not (or input (is-a? (%sut) <runtime:port>)))
               (equal? step-string input)))
          (else
           #t)))

  (let ((pc (car trace))
        (livelock-trace (livelock? trace)))
    (cond (livelock-trace (list (mark-livelock-error livelock-trace)))
          ((rtc? pc) (list trace))
          (else
           (let* ((o (.statement pc))
                  (pcs (step pc o))
                  (step-string (and=> (trace->trail pc) cdr))
                  (observable? (or (is-a? o <action>)
                                   (is-a? o <q-out>)
                                   (is-a? o <trigger-return>)))
                  (step-string (and observable? step-string))

                  (input pc (if step-string ((%next-input) pc) (values #f pc)))
                  (pcs (if step-string (map (cute clone <> #:trail (.trail pc)) pcs)
                           pcs))

                  (pcs (cond ((or (not step-string)
                                  (matching? pc input step-string)) pcs)
                             (else (map (mark-pc input o) pcs)))))
             (map (cut cons <> trace) pcs))))))

(define-method (run-to-completion-unmemoized (pc <program-counter>))
  "Return a list of traces produced by taking steps, starting from
PC until RTC?."
  (let loop ((traces (list (list pc))))
    (let* ((traces (if (%exploring?) traces (filter-illegal traces)))
           (traces (filter-match-error traces))
           (pcs (map car traces)))
      (cond
       ((null? pcs)
        '())
       ((every (disjoin rtc? (is-status? <match-error>)) pcs)
        (filter-implicit-illegal traces))
       ((non-deterministic? pcs)
        (let ((traces (filter-implicit-illegal traces)))
          (map mark-determinism-error traces)))
       (else
        (loop (append-map extend-trace traces)))))))

(define-method (run-to-completion-unmemoized (pc <program-counter>) event)
  "Return a list of traces produced by taking steps, starting from PC
with EVENT as first step, until RTC?."
  (let ((pc (begin-step pc event)))
    (run-to-completion-unmemoized pc)))

(define run-to-completion
  (let ((cache (make-hash-table 512)))
    (lambda (pc event)
      "Memoizing version of RUN-TO-COMPLETION-UNMEMOIZED."
      (let* ((event-string (if (string? event) event (trigger->string event)))
             (key (string-append "pc:" (pc->string pc) " event: " event-string)))
        (or (hash-ref cache key)
            (let ((result (run-to-completion-unmemoized pc event)))
              (when (%exploring?)
                (hash-set! cache key result))
              result))))))
(define-generic run-to-completion)

(define-method (extend-trace (trace <list>) producer)
  "Return a list of traces produced running PRODUCER or the PC (head
of) TRACE, extending TRACE."
  (let* ((pc (car trace))
         (pc (clone pc #:reply #f))
         (traces (producer pc)))
    (map (cut append <> trace) traces)))

(define-method (run-to-completion (trace <list>) event)
  "Return a list of traces produced by RUN-TO-COMPLETION, extending TRACE."
  (extend-trace trace (cute run-to-completion <> event)))

(define-method (run-flush (pc <program-counter>))
  "Return a list of traces produced by taking steps, starting by flushing (%SUT),
until RTC?."
  (let ((pc (flush pc)))
    (run-to-completion-unmemoized pc)))

(define-method (run-flush (trace <list>))
  "Return a list of traces produced by RUN-FLUSH, extending TRACE."
  (extend-trace trace run-flush))

(define-method (run-flush (pc <program-counter>))
  "Return a list of traces produced by taking steps, starting by flushing (%SUT),
until RTC?."
  (let* ((pc (flush pc))
         (traces (run-to-completion-unmemoized pc))
         (pcs (map car traces)))
  (if (every q-empty? pcs) traces
      (append-map run-flush traces))))

(define-method (run-silent (pc <program-counter>) (port <runtime:port>))
  (%debug "run-silent... ~s\n" (name port))
  (let ((modeling-names (modeling-names port)))
    (if (null? modeling-names) '()
        (let* ((previous (.previous pc))
               (instance (.instance pc))
               (trail (.trail pc))
               (pc (clone pc #:previous #f #:instance port #:trail '()))
               (r:other-port (runtime:other-port port))
               (external? (ast:external? (.ast r:other-port)))
               (traces (parameterize ((%sut port)
                                      (%strict? (not external?)))
                         (append-map (cut run-to-completion pc <>) modeling-names)))
               (traces (filter (conjoin (disjoin (const external?)
                                                 (compose null? trace->trail))
                                        (compose (negate .status) car))
                               traces))
               (traces (map (cut rewrite-trace-head (cut clone <> #:trail trail) <>) traces)))
          (map (compose (cut clone <> #:previous previous #:instance instance) car) traces)))))

(define-method (run-interface (pc <program-counter>) event)
  (let* ((pc (clone pc #:reply #f))
         (interface ((compose .type .ast %sut)))
         (modeling-names (modeling-names interface))
         (xpc (clone pc #:trail (cons event (.trail pc))))
         (traces (append-map (cut run-to-completion xpc <>) modeling-names)))
    (match event
      ((? (cute in-event? interface <>))
       (append-map (cut run-to-completion <> event) (cons (list pc) traces)))
      (else
       traces))))

(define (run-requires pc event)
  (define (silent-or-event-in-trace? trace)
    (let ((trail (map cdr (trace->trail trace))))
      (or (null? trail)
          (equal? event (car trail)))))
  (%debug "run-requires... ~s\n" event)
  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (clone (string->trigger event) #:parent component))
         (port-name (.port.name trigger))
         (port-instance (runtime:port-name->instance port-name))
         (interface ((compose .type .ast) port-instance))
         (modeling-names (modeling-names interface))
         (trail (cons event (.trail pc)))
         (pc (clone pc #:trail trail #:status #f))
         (modeling-events (map (cut string-append port-name "." <>) modeling-names))
         (traces (append-map (cut run-to-completion pc <>) modeling-events))
         (traces (filter silent-or-event-in-trace? traces))
         (illegals (filter (compose (is-status? <illegal-error>) car) traces))
         (traces (filter (compose (negate .status) car) traces)))

    (if (pair? illegals) illegals
        (let* ((component-port (runtime:other-port port-instance))
               (component-trigger (trigger->component-trigger component-port trigger))
               (instance (.container component-port))
               (traces (map (cut rewrite-trace-head (cut clone <> #:instance instance) <>) traces))
               (traces (append-map run-flush traces)))
          traces))))

(define-method (run-async-event (pc <program-counter>))
  (let ((trace (step pc (make <flush-async>))))
    (extend-trace trace run-to-completion-unmemoized)))

(define-method (run-async (pc <program-counter>) event)
  (let* ((trail (.trail pc))
         (pc (clone pc #:trail (cons event trail)))
         (traces (run-async-event pc)))
    traces))

(define-method (flush-async-trace (trace <list>) previous-trace)
  (let ((trace (append trace previous-trace)))
    (cond ((.status (car trace))
           (list trace))
          ((livelock? trace)
           =>
           (compose list mark-livelock-error))
          (else
           (let* ((pc (car trace))
                  (traces (flush-async pc trace)))
             (map (cut append <> trace) traces))))))

(define-method (flush-async (pc <program-counter>))
  (flush-async pc '()))

(define (did-provides-out? trace)
  (let* ((trail (map cdr (trace->trail trace)))
         (r:ports (filter runtime:boundary-port? (%instances)))
         (ports (map .ast r:ports))
         (provide-ports (filter ast:provides? ports))
         (provide-names (map .name provide-ports)))
    (find (lambda (event)
            (match (string-split event #\.)
              ((port event) (member port provide-names))))
          trail)))

(define-method (flush-async (pc <program-counter>) previous-trace)
  (if (null? (.async pc)) '()
      (let ((traces (run-async-event pc)))
        (cond
         ((null? traces) traces)
         (else
          (let* ((stop flush (partition
                              (disjoin (compose null? .async car)
                                       did-provides-out?
                                       (compose .status car))
                              traces))
                 (traces (append-map (cute flush-async-trace <> previous-trace) flush))
                 (livelock traces (partition livelock? traces))
                 (livelock (map (compose mark-livelock-error livelock?) livelock)))
            (append stop
                    livelock
                    traces)))))))

(define-method (external-event? (pc <program-counter>) event)
  (and (requires-trigger? event)
       (find (match-lambda
               ((port trigger tail ...)
                (equal? (trigger->string trigger) event)))
             (.external-q pc))))

(define-method (run-external-q (pc <program-counter>) (instance <runtime:port>))
  (let* ((pc trigger (dequeue-external pc instance))
         (q-out (make <q-out> #:trigger trigger))
         (q-out (clone q-out #:location (.location trigger)))
         (q-out-pc (clone pc #:instance (%sut) #:statement q-out))
         (traces (run-to-completion pc trigger)))
    (map (lambda (t) (append t (list q-out-pc))) traces)))

(define-method (run-external (pc <program-counter>) event)
  (%debug "run-external pc: ~s\n" pc)
  (let ((queues (.external-q pc)))
    (if (or (null? queues)
            (pair? (.async pc))) '()
            (match (external-event? pc event)
              ((port q ...) (run-external-q pc (or port (%sut))))))))

(define-method (run-to-completion* (pc <program-counter>) event)
  (let ((pc (clone pc #:instance #f #:reply #f)))
    (cond
     ((is-a? (%sut) <runtime:port>)
      (run-interface pc event))
     ((external-event? pc event)
      (run-external pc event))
     ((requires-trigger? event)
      (let ((async-traces (if (null? (.async pc)) '()
                              (run-async pc event))))
        (if (pair? async-traces) async-traces
            (run-requires pc event))))
     ((provides-trigger? event)
      (run-to-completion pc event))
     ((async-event? pc event)
      (run-async pc event))
     ((and (eq? event #f) (pair? (.async pc)))
      (run-async pc #f))
     (else
      '()))))
