;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2021 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
            %strict?
            did-provides-out?
            filter-error
            filter-match-error
            flush-async
            flush-async-trace
            interactive?
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

;; Are we running "explore"?
(define %exploring? (make-parameter #f))


;;;
;;; Run
;;;

;;; ’run’ loops over ’step’ until ’rtc?’ (run to completion done) and
;;; collects a trace (of program counters).

(define (trace-valid? trace)
  ((compose not .status car) trace))

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
  (let ((match-error rest (partition
                           (compose (is-status? <match-error>) car)
                           traces)))
    (if (pair? rest) rest
        match-error)))

(define (filter-postponed-match traces)
  (let* ((postponed-match rest (partition
                                (compose (is-status? <postponed-match>) car)
                                traces))
         (valid? (find trace-valid? rest)))
    (if (or valid? (null? postponed-match)) rest
        postponed-match)))

(define (non-deterministic? traces)
  "Return #t when TRACES are a nondeterministic set, i.e.: at least two
valid PCs that are executing an imperative statement."
  (let* ((pcs (map car traces))
         (pcs (filter (negate .status) pcs)))
    (and
     (every (compose (cute is-a? <> <runtime:component>) .instance) pcs)
     (let ((declarative imperative
                        (partition (compose ast:declarative? .statement)
                                   pcs)))
       (> (length imperative) 1)))))

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

(define %livelock-threshold (make-parameter 42))
(define (livelock? trace)
  (define* (trace-head-recurrence? trace)
    (let ((trace (filter
                  (conjoin (compose (is? <runtime:component>) .instance)
                           (negate (compose (is? <initial-compound>) .statement)))
                  trace)))
      (and (pair? trace)
           (find (cute pc:eq? (car trace) <>) (cdr trace)))))
  (and (>= (length trace) (%livelock-threshold))
       (let* ((suffixes (unfold null? identity cdr trace))
              (trace (find trace-head-recurrence? suffixes)))
         (when (not trace)
           (%livelock-threshold (* 2 (%livelock-threshold))))
         trace)))

(define (interactive?)
  (isatty? (current-input-port)))

(define-method (extend-trace (trace <list>))
  "Return a list of traces, produced by appending TRACE to each of the
program-counters produced by taking a step."

  (define* ((mark-pc input o) pc)
    (%debug "match fail, ast ~s, input ~s\n" (name o) input)
    (cond ((.status pc)
           pc)
          ((and (%strict?) input)
           (clone pc #:status (make <match-error> #:ast o #:input input #:message "match")))
          (else
           (clone pc #:status (make <postponed-match> #:ast o #:input input)))))

  (let loop ((trace trace))
    (let ((pc (car trace))
          (livelock-trace (livelock? trace)))
      (cond (livelock-trace (list (mark-livelock-error livelock-trace)))
            ((rtc? pc) (list trace))
            (else
             (let* ((o (.statement pc))
                    (observable? (or (is-a? o <action>)
                                     (is-a? o <q-out>)
                                     (is-a? o <trigger-return>)))
                    (observable (and observable? (and=> (trace->trail pc) cdr)))
                    (pcs (step pc o))
                    (input pc (if (and observable (not (interactive?))) ((%next-input) pc) (values #f pc)))
                    (pcs (cond ((%exploring?)
                                pcs)
                               ((not observable)
                                pcs)
                               ((equal? input observable)
                                (map (cute clone <> #:trail (.trail pc)) pcs))
                               (else
                                (map (mark-pc input o) pcs))))
                    (traces (map (cut cons <> trace) pcs)))
               (cond
                ((ast:declarative? o)
                 (let ((declarative imperative
                                    (partition (compose ast:declarative? .statement car)
                                               traces)))
                   (cond
                    ((pair? declarative)
                     (append imperative (append-map loop declarative)))
                    (else
                     traces))))
                (observable
                 traces)
                (else
                 (append-map loop traces)))))))))

(define-method (run-to-completion-unmemoized (pc <program-counter>))
  "Return a list of traces produced by taking steps, starting from
PC until RTC?."

  (define (postponed-match? traces)
    (and (not (find trace-valid? traces))
         (let* ((traces (filter (compose (is-status? <postponed-match>) car) traces))
                (pcs (map car traces)))
           (and (pair? traces)
                traces))))

  (define (observable pc)
    (and=> (trace->trail pc) cdr))

  (define (reset-posponed-match traces)
    (let* ((trace (car traces))
           (pc (car trace))
           (observe-pc (cadr trace))
           (trail (.trail pc))
           (input (.input (.status pc)))
           (drop-event? (equal? input (observable observe-pc)))
           (trail (if drop-event? (cdr trail) trail))
           (trace (rewrite-trace-head (cut clone <> #:status #f #:trail trail) trace)))
      (loop (append-map extend-trace (list trace)))))

  (define (choice-label trace)
    (match (trace->trail trace)
      ((label ... (($ <trigger-return>) . string) (#f . "<postponed-match>"))
       (or (.reply (car trace)) "return"))
      ((label ... (choice . string) (#f . "<postponed-match>")) choice)))

  (define (choice-labels traces)
    (let ((labels (map choice-label traces)))
      (delete-duplicates labels ast:equal?)))

  (define (choose-postponed-match traces)
    (define (label trace)
      (let* ((label (label->string (choice-label trace)))
             (pc (cadr trace))
             (instance (.instance pc))
             (port-name (string-join (runtime:instance->path instance) "."))
             (prefix (if (is-a? (%sut) <runtime:port>) ""
                         (string-append port-name "."))))
        (format #f "~a~a" prefix label)))
    (show-eligible (delete-duplicates (map label traces)) #:traces traces)
    (let* ((input pc ((%next-input) pc))
           (traces (map cdr traces))    ;drop <postponed-match> pc
           (traces (filter (compose (cute equal? input <>) observable car) traces)))
      (loop (append-map extend-trace traces))))

  (define (mark-end-of-trail traces)
    (define (set-end-of-trail labels pc)
      (let* ((statement (.statement pc))
             (labels (make <labels> #:elements labels))
             (status (make <end-of-trail> #:ast statement #:labels labels))
             (pc (clone pc #:statement #f)))
        (clone pc #:status status)))
    (let* ((labels (choice-labels traces))
           (traces (map cdr traces)))   ;drop <postponed-match> pc
      (map (cute rewrite-trace-head (cute set-end-of-trail labels <>) <>)
           traces)))

  (define (loop traces)
    (let* ((traces (if (%exploring?) traces (filter-illegal traces)))
           (traces (filter-match-error traces))
           (traces (filter-postponed-match traces))
           (pcs (map car traces)))
      (cond
       ((null? traces)
        '())
       ((every (conjoin (negate (is-status? <postponed-match>))
                        (disjoin rtc? (is-status? <match-error>)))
               pcs)
        (filter-implicit-illegal traces))
       ((postponed-match? traces)
        =>
        (lambda (traces)
          (cond
           ((or (= (length traces) 1)
                (= (length (choice-labels traces)) 1))
            (reset-posponed-match traces))
           ((and (not (%exploring?)) (interactive?))
            (choose-postponed-match traces))
           (else
            (mark-end-of-trail traces)))))
       (else
        (loop (append-map extend-trace traces))))))

  (let ((traces (extend-trace (list pc))))
    (cond
     ((and (not (%exploring?))
           (non-deterministic? traces))
      (let ((traces (filter-implicit-illegal traces)))
        (map mark-determinism-error traces)))
     (else
      (loop traces)))))

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
             (sut (%sut))
             (key (string-append "sut:" (parameterize ((%sut #f)) (runtime:dotted-name sut))
                                 " pc:" (pc->string pc)
                                 " event: " event-string)))
        (or (and (%exploring?) (hash-ref cache key))
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
  (define (update-state pc port-pc)
    (let ((pc (set-state pc (get-state port-pc port))))
      (clone pc #:external-q (.external-q port-pc))))
  (%debug "run-silent... ~s\n" (name port))
  (let ((modeling-names (modeling-names port)))
    (if (null? modeling-names) '()
        (let* ((previous (.previous pc))
               (ipc (clone pc #:trigger #f #:previous #f #:instance #f #:trail '() #:statement #f))
               (r:other-port (runtime:other-port port))
               (external? (ast:external? (.ast r:other-port)))
               (traces (parameterize ((%sut port)
                                      (%exploring? #t)
                                      (%strict? (not external?)))
                         (append-map (cut run-to-completion ipc <>) modeling-names)))
               (traces (filter (conjoin (disjoin (const external?)
                                                 (compose null? trace->trail))
                                        (compose (negate .status) car))
                               traces))
               (pcs (map car traces)))
          (map (cute update-state pc <>) pcs)))))

(define-method (run-interface (pc <program-counter>) (event <string>))
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
              ((port event) (member port provide-names))
              (_ #f)))
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
