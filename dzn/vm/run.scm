;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:export (%next-input
            %strict?
            filter-error
            filter-match-error
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
  (let ((pcs (filter (negate .status) pcs)))
    (and (not (is-a? ((compose .type .ast %sut)) <interface>))
         (not (equal? pcs
                      (delete-duplicates pcs
                                         (lambda (a b)
                                           (equal? (serialize (.state a)) (serialize (.state b)))))))
         (let* ((statements (map .statement pcs))
                (imperative (filter ast:imperative? statements)))
           (> (length imperative) 1))
         (let* ((instances (filter-map .instance pcs))
                (types (map (compose .type .ast) instances))
                (components (filter (is? <component>) types)))
           ;; TODO: the *same* component (tests have only 1 component anyway...)
           (> (length components) 1)))))

(define (mark-determinism-error trace)
  (let* ((pc (car trace))
         (error (make <determinism-error> #:ast (.statement pc) #:message "determinism"))
         (pc (clone pc #:status error)))
    (cons pc (cdr trace))))

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
           (clone pc #:status (make <end-of-trail> #:ast o #:input input #:labels (list o))))))

  (define (matching? pc input stapje)
    (cond ((%strict?)
           (or (not (or input (is-a? (%sut) <runtime:port>)))
               (equal? stapje input)))
          (else
           #t)))

  (let ((pc (car trace)))
    (if (rtc? pc) (list trace)
        (let* ((o (.statement pc))
               (pcs (step pc o))
               (string-stapje (and=> (trace->trail pc) cdr))
               (observable? (or (is-a? o <action>)
                                (is-a? o <q-out>)
                                (is-a? o <trigger-return>)))
               (string-stapje (and observable? string-stapje))

               (input pc (if string-stapje ((%next-input) pc) (values #f pc)))
               (pcs (if string-stapje (map (cute clone <> #:trail (.trail pc)) pcs)
                        pcs))

               (pcs (cond ((or (not string-stapje)
                               (matching? pc input string-stapje)) pcs)
                          (else (map (mark-pc input o) pcs)))))
          (map (cut cons <> trace) pcs)))))

(define-method (run-to-completion (pc <program-counter>))
  "Return a list of traces produced by taking steps, starting from PC
until RTC?."
  (let loop ((traces (list (list pc))))
    (let* ((traces (filter-illegal traces))
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

(define-method (run-to-completion (pc <program-counter>) event)
  "Return a list of traces produced by taking steps, starting from PC
with EVENT as first step, until RTC?."
  (let ((pc (begin-step pc event)))
    (run-to-completion pc)))

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
    (run-to-completion pc)))

(define-method (run-flush (trace <list>))
  "Return a list of traces produced by RUN-FLUSH, extending TRACE."
  (extend-trace trace run-flush))

(define-method (run-flush (pc <program-counter>))
  "Return a list of traces produced by taking steps, starting by flushing (%SUT),
until RTC?."
  (let* ((pc (flush pc))
         (traces (run-to-completion pc))
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
               (traces (parameterize ((%sut port))
                         (append-map (cut run-to-completion pc <>) modeling-names)))
               (traces (filter (conjoin (compose null? trace->trail)
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

(define (run-provides-port pc event)
  (%debug "run-provides-port... ~s\n" event)
  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (clone (string->trigger event) #:parent component))
         (port-name (.port.name trigger))
         (port-instance (runtime:port-name->instance port-name))
         (port-event (.event.name trigger))
         (port-trail (filter-map (cut port-event? port-name <>) (.trail pc)))
         (port-pc (clone pc #:trail port-trail))
         (port-trace (list port-pc))
         (traces (cons port-trace (run-silent port-pc port-instance)))
         (traces (parameterize ((%sut port-instance))
                   (append-map (cut run-to-completion <> port-event) traces))))
    (filter-match-error traces)))

(define (run-provides pc event)
  (%debug "run-provides... ~s\n" event)
  (let* ((port-traces (run-provides-port pc event))
         (port-traces (filter-error port-traces))
         (instance (.instance pc))
         (trail (.trail pc))
         (traces (map (lambda (trace)
                        (if (null? trace) trace
                            (let* ((pc (car trace))
                                   (instance (%sut))
                                   (pc (clone pc
                                              #:instance (and (.status pc) instance)
                                              #:reply #f
                                              #:status #f
                                              #:trail trail)))
                              (cons pc
                                    (filter (compose (is? <initial-compound>) .statement) trace)))))
                      port-traces))
         (traces (if (find (compose (is-status? <error>) car) traces) traces
                     (append-map (cut run-to-completion <> event) traces))))
    traces))

(define (run-requires pc event)
  (define (silent-or-event-in-trace? trace)
    (let ((trail (map cdr (trace->trail trace))))
      (or (null? trail)
          (member event trail))))
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

(define-method (run-to-completion* (pc <program-counter>) event)
  (let ((pc (clone pc #:instance #f #:reply #f)))
    (cond
     ((is-a? (%sut) <runtime:port>)
      (run-interface pc event))
     ((requires-trigger? event)
      (run-requires pc event))
     ((provides-trigger? event)
      (run-provides pc event))
     (else
      '()))))
