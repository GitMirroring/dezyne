;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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
  #:use-module (ice-9 hcons)
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
            did-provides-out?
            filter-compliance-error
            filter-error
            filter-illegal+implicit-illegal
            filter-implicit-illegal
            filter-implicit-illegal-only
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
            run-external-modeling
            run-requires
            run-silent
            run-to-completion
            run-to-completion*
            run-to-completion*-context-switch))

;;; Commentary:
;;;
;;; ’run’ implements run-to-completion for the Dezyne vm: the level
;;; above 'step'.
;;;
;;; Code:

;; Are we running "explore"?
(define %exploring? (make-parameter #f))


;;;
;;; Run
;;;

;;; ’run’ loops over ’step’ until ’rtc?’ (run to completion done) and
;;; collects a trace (of program counters).

(define (trace-valid? trace)
  ((compose not .status car) trace))

(define (filter-compliance-error traces)
  (let ((non-compliance rest
                        (partition
                         (disjoin (compose (is-status? <compliance-error>) car)
                                  (compose (is-status? <match-error>) car))
                         traces)))
    (if (pair? rest) rest
        non-compliance)))

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

(define (filter-implicit-illegal-only traces)
  (let ((illegal
         rest (partition
               (conjoin (compose (is-status? <implicit-illegal-error>) car)
                        (compose (match-lambda
                                   ((trigger "<illegal>") #t)
                                   (_ #f))
                                 trace->string-trail))
               traces)))
    (if (pair? rest) rest
        illegal)))

(define (filter-illegal+implicit-illegal traces)
  (let ((illegal rest (partition
                       (compose
                        (disjoin (is-status? <illegal-error>)
                                 (is-status? <implicit-illegal-error>))
                        car)
                       traces)))
    (if (pair? illegal) illegal
        rest)))

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

(define-method (block-on-port trace)
  "Return TRACE blocked on port when trace head is an <action> or a
<trigger-return> on a blocking requires port, unless already blocked on
this statement.  Otherwise, return #f.

Blocking and resettiing the STATEMENT on the TRACE makes RTC?  true,
which creates an opening to accept new modeling events.  Continuation of
the <action> or <trigger-return> happens when revisiting this method
with a TRACE that has BLOCKED still set to this port."

  (define (modeling-traces pc instance)
    (let* ((port (.ast instance))
           (ipc (clone pc #:trigger #f #:previous #f #:instance
                       #f #:trail '() #:statement #f))
           (modeling (modeling-names (.type port)))
           (traces (parameterize ((%sut instance)
                                  (%liveness? 'port)
                                  (%exploring? #f)
                                  (%strict? #f))
                     (append-map (cut run-to-completion ipc <>) modeling)))
           (traces (filter (compose (negate (is-status? <error>)) car) traces)))
      traces))

  (define (requires-modeling-armed? pc)
    (let* ((instance (.instance pc))
           (requires-ports (filter
                            (conjoin runtime:boundary-port?
                                     ast:requires?
                                     (negate (cute eq? <> instance)))
                            (%instances)))
           (modeling (filter (compose pair? modeling-names .type .ast)
                             requires-ports))
           (ports (filter (compose pair?
                                   (cute modeling-traces pc <>))
                          modeling)))
      (pair? ports)))

  (let* ((pc (car trace))
         (instance (.instance pc))
         (statement (.statement pc))
         (blocked (.blocked pc)))
    (and
     (not (is-a? (%sut) <runtime:port>))
     (is-a? instance <runtime:port>)
     (ast:requires? instance)
     (ast:blocking? instance)
     (not (ast:modeling? (.trigger pc)))
     (or (is-a? statement <action>)
         (is-a? statement <trigger-return>))
     (let ((blocked-port (and (pair? blocked) (caar blocked)))
           (blocked-pc (and (pair? blocked) (cdar blocked))))
       (and
        (not (ast:eq? statement (and=>  blocked-pc .statement)))
        (or (and (is-a? (%sut) <runtime:system>)
                 (> (length (ast:provides-port* (runtime:%sut-model))) 1))
            (requires-modeling-armed? pc))
        (let* ((trace (cdr trace))
               (pc (blocked-on-boundary-reset pc))
               (pc (block pc instance))
               (trace (cons pc trace)))
          trace))))))

(define (mark-determinism-error trace)
  "Truncate TRACE up to including the component <initial-compound> and
mark it with <determinism-error>."
  (let* ((index (list-index (conjoin (compose (is? <runtime:component>) .instance)
                                     (compose ast:imperative? .statement))
                            trace))
         (pc (list-ref trace index))
         (trace (drop trace index))
         (error (make <determinism-error>
                  #:ast (.statement pc)
                  #:message "non-deterministic"))
         (pc (clone pc #:status error)))
    (cons pc trace)))

(define (mark-livelock-error trace index)
  (let* ((model (runtime:%sut-model))
         (ast-model (if (is-a? model <system>) model
                        (.behavior model)))
         (pc-loop (list-ref trace index))
         (ast-loop (or (.statement pc-loop) ast-model))
         (loop (make <livelock-error> #:ast ast-loop #:message "loop"))
         (pc-loop-error (clone pc-loop #:status loop))
         (trace-prefix trace-suffix (split-at trace index))
         (shorter-index (and=> (list-index
                                (cute pc-equal? <> pc-loop)
                                (reverse trace-prefix))
                               (cute - (length trace-prefix) <> 1)))
         (shorter-prefix (if (not shorter-index) trace-suffix
                             (drop trace-prefix shorter-index)))
         (pc (car shorter-prefix))
         (ast (or (.statement pc) ast-model))
         (error (make <livelock-error> #:ast ast #:message "livelock"))
         (pc (clone pc #:status error)))
    `(,pc
      ,@shorter-prefix
      ,pc-loop-error
      ,@trace-suffix)))

(define %livelock-threshold (make-parameter 42))
(define (livelock? trace)
  "Return the index of the start of the livelock loop, or false.  Use
%LIVELOCK-THRESHOLD for heuristics to avoid re-evaluating the same
prefix."
  (define* (trace-head-recurrence? trace)
    (let ((trace (filter
                  (conjoin
                   (disjoin (compose (cute eq? <> (%sut)) .instance)
                            (compose (is? <runtime:component>) .instance))
                   (negate (compose (is? <initial-compound>) .statement))
                   (negate (compose (is? <end-of-on>) .statement)))
                  trace)))
      (and (pair? trace)
           (find (cute pc-equal?
                       (car trace) <>) (reverse (cdr trace))))))

  (and (>= (length trace) (%livelock-threshold))
       (let* ((suffixes (reverse (unfold null? identity cdr trace)))
              (loop (find trace-head-recurrence? suffixes)))
         (match loop
           (#f
            (%livelock-threshold (* 2 (%livelock-threshold)))
            #f)
           ((pc tail ...)
            (%debug "  ~s ~s <livelock>\n"
                    ((compose name .instance) pc)
                    (and=> (.trigger pc) trigger->string))
            (let ((index (and=> (list-index (cute pc-equal? <> pc)
                                            (reverse trace))
                                (cute - (length trace) <> 1))))
              index))))))

(define (interactive?)
  (isatty? (current-input-port)))

(define-method (extend-trace (trace <list>))
  "Return a list of traces, produced by appending TRACE to each of the
program-counters produced by taking a step."

  (define* ((mark-pc input orig-pc) pc)
    (let ((statement (.statement orig-pc)))
      (%debug "match fail, ast ~s ~a, input ~s\n" (name statement)
              (and (is-a? statement  <action>)
                   (and=> (trace->trail orig-pc) cdr))
              input)
     (cond ((.status pc)
            pc)
           ((or (and (%strict?) input)
                (and input
                     (is-a? statement <trigger-return>)
                     (blocked-on-boundary? orig-pc)))
            (let ((error (make <match-error> #:ast statement #:input input
                               #:message "match")))
              (clone pc #:status error)))
           (else
            (clone pc #:status (make <postponed-match> #:ast statement
                                     #:input input))))))

  (define (blocked-collaterally? orig-pc pc)
    (match (.collateral pc)
      (((port . pc) t ...)
       (eq? pc orig-pc))
      (_ #f)))

  (let loop ((trace trace))
    (let ((pc (car trace)))
      (cond ((.status pc)
             (list trace))
            ((livelock? trace)
             =>
             (compose list (cute mark-livelock-error trace <>)))
            ((rtc? pc)
             (list trace))
            ((block-on-port trace)
             => list)
            (else
             (let* ((o (.statement pc))
                    (observable? (or (is-a? o <action>)
                                     (is-a? o <q-out>)
                                     (is-a? o <trigger-return>)))
                    (observable (and observable? (and=> (trace->trail pc) cdr)))
                    (pcs (step pc o))
                    (trace (if (any (disjoin
                                     (conjoin (is-status? <second-reply-error>)
                                              (const (is-a? (.statement pc)
                                                            <trigger-return>)))
                                     (cute blocked-collaterally? pc <>)) pcs)
                               (cdr trace)
                               trace))
                    (input pc (if (and observable (not (interactive?)))
                                  ((%next-input) pc)
                                  (values #f pc)))
                    (pcs (cond ((%exploring?)
                                pcs)
                               ((not observable)
                                pcs)
                               ((equal? input observable)
                                (map (cute clone <> #:trail (.trail pc)) pcs))
                               (else
                                (map (mark-pc input pc) pcs))))
                    (traces (map (cut cons <> trace) pcs)))
               (cond
                ((ast:declarative? o)
                 (let ((declarative
                        imperative (partition
                                    (compose ast:declarative? .statement car)
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
    (define (reset-posponed-match trace)
      (let* ((pc (car trace))
             (observe-pc (cadr trace))
             (trail (.trail pc))
             (input (.input (.status pc)))
             (drop-event? (equal? input (observable observe-pc)))
             (trail (if drop-event? (cdr trail) trail))
             (trace (rewrite-trace-head (cut clone <> #:status #f #:trail trail) trace)))
        trace))
    (let* ((traces (map reset-posponed-match traces))
           (traces (delete-duplicates traces trace-equal?)))
      (loop (append-map extend-trace traces))))

  (define (choice-label trace)
    (match (trace->trail trace)
      ((label ... ((and ($ <trigger-return>) return) . string) (#f . "<postponed-match>"))
       (.event.name return))
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

  (define (previous-provides? trace)
    (let ((previous (any .trigger trace)))
      (and previous
           (and=> (.port previous) ast:provides?))))

  (define (must-switch? trace)
    (and (not (is-a? (%sut) <runtime:port>))
         (not (previous-provides? trace))))

  (define (loop traces)
    (let* ((traces (if (%exploring?) traces (filter-illegal traces)))
           (traces (filter-match-error traces))
           (traces (filter-postponed-match traces))
           (traces (filter-implicit-illegal traces))
           (pcs (map car traces)))
      (cond
       ((null? traces)
        '())
       ((and (%exploring?)
             (find (compose (is-status? <livelock-error>) car) traces))
        traces)
       ((every (conjoin (negate (is-status? <postponed-match>))
                        (disjoin rtc? (is-status? <match-error>)))
               pcs)
        (let* ((to-switch traces (partition must-switch? traces))
               (traces (append traces (map switch-context to-switch)))
               (done todo (partition rtc? traces)))
          (append done
                  (loop (append-map extend-trace todo)))))
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
  (let ((pc (if (eq? event 'rtc) pc
                (begin-step pc event))))
    (run-to-completion-unmemoized pc)))

(define run-to-completion
  (let ((cache (make-weak-key-hash-table 523))
        (gc-buffer (make-gc-buffer 256)))
    (lambda (pc event)
      "Memoizing version of RUN-TO-COMPLETION-UNMEMOIZED."
      (if (not (%exploring?)) (run-to-completion-unmemoized pc event)
          (let* ((event-string (cond ((string? event) event)
                                     ((eq? event 'rtc) "*rtc*")
                                     (else (trigger->string event))))
                 (sut (%sut))
                 (root (parent (.ast sut) <root>))
                 (key (string-append
                       (number->string (.id root))
                       (parameterize ((%sut #f)) (runtime:dotted-name sut))
                       (pc->string pc)
                       event-string)))
            (gc-buffer key)
            (or (hash-ref cache key)
                (let ((result (run-to-completion-unmemoized pc event)))
                  (hash-set! cache key result)
                  result)))))))

(define-generic run-to-completion)

(define-method (extend-trace (trace <list>) producer)
  "Return a list of traces produced running PRODUCER or the PC (head
of) TRACE, extending TRACE."
  (let* ((pc (car trace))
         (traces (producer pc)))
    (map (cute append <> trace) traces)))

(define-method (run-to-completion (trace <list>) event)
  "Return a list of traces produced by RUN-TO-COMPLETION, extending TRACE."
  (extend-trace trace (cute run-to-completion <> event)))

(define-method (run-flush (pc <program-counter>))
  "Return a list of traces produced by taking steps, starting by flushing (%SUT),
until RTC?."
  (if (.status pc) '()
      (let ((pc (flush pc)))
        (run-to-completion-unmemoized pc))))

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
    (set-state pc (get-state port-pc port)))
  (%debug "run-silent... ~s\n" (name port))
  (let ((modeling-names (modeling-names port)))
    (if (null? modeling-names) '()
        (let* ((ipc (clone pc #:trigger #f #:previous #f #:instance #f #:trail '() #:statement #f))
               (traces (parameterize ((%sut port)
                                      (%exploring? #t)
                                      (%strict? #t))
                         (append-map (cute run-to-completion ipc <>) modeling-names)))
               (traces (filter (conjoin (compose null? trace->trail)
                                        (compose (negate .status) car))
                               traces)))
          (map (cute rewrite-trace-head (cute update-state pc <>) <>) traces)))))

(define-method (run-silent (pc <program-counter>) event)
  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (clone (string->trigger event) #:parent component))
         (port-name (.port.name trigger))
         (port-instance (runtime:port-name->instance port-name))
         (traces (run-silent pc port-instance)))
    (map car traces)))

(define-method (run-silent traces)
  (let* ((pcs (map last traces))
         (pcs (map (cute clone <> #:status #f) pcs)))
    (append-map (cute run-silent <> (%sut)) pcs)))

(define-method (run-external-modeling (pc <program-counter>) (port <runtime:port>))
  (define (update-state pc port-pc)
    (let ((pc (set-state pc (get-state port-pc port))))
      (clone pc #:external-q (.external-q port-pc) #:status (.status port-pc))))
  (%debug "run-external-modeling... ~s\n" (name port))
  (let* ((r:other-port (runtime:other-port port))
         (external? (and (ast:requires? r:other-port)
                         (ast:external? r:other-port))))
    (if (not external?) '()
        (let ((modeling-names (modeling-names port)))
          (if (null? modeling-names) '()
              (let* ((previous (.previous pc))
                     (ipc (clone pc #:trigger #f #:previous #f #:instance #f
                                 #:trail '() #:statement #f))
                     (traces (parameterize ((%sut port)
                                            (%liveness? 'component)
                                            (%exploring? #t)
                                            (%strict? #f))
                               (append-map (cute run-to-completion ipc <>) modeling-names)))
                     (traces (filter (compose
                                      (disjoin not (is? <queue-full-error>))
                                      .status car)
                                     traces)))
                (map (cute rewrite-trace-head (cute update-state pc <>) <>) traces)))))))

(define-method (run-external-modeling (pc <program-counter>))
  (let* ((ports (filter (conjoin runtime:boundary-port?
                                 ast:external? ast:requires?)
                        (%instances))))
    (append-map (cute run-external-modeling pc <>) ports)))

(define-method (run-external-modeling (pc <program-counter>) event)
  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (clone (string->trigger event) #:parent component))
         (port-name (.port.name trigger))
         (port-instance (runtime:port-name->instance port-name))
         (traces (run-external-modeling pc port-instance)))
    (map car traces)))

(define-method (run-interface (pc <program-counter>) (event <string>))
  (define (event-executed? trace)
    (let ((trail (trace->string-trail trace)))
      (and (pair? trail)
           (equal? event (car trail)))))
  (let* ((interface ((compose .type .ast %sut))))
    (cond
     ((in-event? event)
      (let* ((modeling-names (modeling-names interface))
             (silent-traces (if (null? modeling-names) '()
                                (run-silent pc (%sut))))
             (silent-pcs (map car silent-traces))
             (pcs (cons pc silent-pcs))
             (traces (map list pcs)))
        (append-map (cute run-to-completion <> event) (cons (list pc) traces))))
     (else
      (let* ((modeling? (member event '("inevitable" "optional")))
             (pc (if modeling? pc
                     (clone pc #:trail (cons event (.trail pc)))))
             (modeling-names (if modeling? (list event) (modeling-names)))
             (traces (append-map (cute run-to-completion pc <>) modeling-names))
             (traces (parameterize ((%modeling? modeling?))
                       (filter event-executed? traces))))
        traces)))))

(define-method (run-requires (pc <program-counter>) event)
  (define (event-executed? port-instance trace)
    (let ((status (.status (car trace)))
          (trail (map cdr (trace->trail trace))))
      (or (is-a? status <queue-full-error>)
          (and (pair? trail)
               (equal? event (car trail)))
          (and (null? trail)
               (let* ((pc (car trace))
                      (pc trigger (dequeue-external pc port-instance)))
                 (and trigger
                      (equal? (trigger->string trigger) event)))))))
  (%debug "run-requires... ~s\n" event)
  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (clone (string->trigger event) #:parent component))
         (port-name (.port.name trigger))
         (port-instance (runtime:port-name->instance port-name))
         (interface ((compose .type .ast) port-instance))
         (modeling-names (modeling-names interface))
         (trail (cons event (.trail pc)))
         (pc (clone pc #:trail trail #:status #f))
         (modeling-events (map (cute string-append port-name "." <>) modeling-names))
         (traces (append-map (cute run-to-completion pc <>) modeling-events))
         (traces (filter (cute event-executed? port-instance <>) traces))
         (errors (filter (compose .status car) traces)))

    (if (pair? errors) errors
        (let* ((component-port (runtime:other-port port-instance))
               (component-trigger (trigger->component-trigger component-port
                                                              trigger))
               (instance (.container component-port))
               (traces (map (cute rewrite-trace-head
                              (cute clone <> #:instance instance) <>)
                            traces))
               (collateral-blocked? (or (blocked-on-boundary? pc)
                                        (and (get-handling pc instance)
                                             (blocked-port pc instance))))
               (traces (if collateral-blocked? traces
                           (append-map run-flush traces))))
          traces))))

(define-method (run-async-event (pc <program-counter>))
  (let ((trace (step pc (make <flush-async>))))
    (extend-trace trace run-to-completion-unmemoized)))

(define-method (flush-async-trace (trace <list>) previous-trace)
  (let ((trace (append trace previous-trace)))
    (cond ((.status (car trace))
           (list trace))
          ((livelock? trace)
           =>
           (compose list (cute mark-livelock-error trace <>)))
          (else
           (let* ((pc (car trace))
                  (traces (flush-async pc trace)))
             (map (cute append <> trace) traces))))))

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
                 (livelock (map (cute mark-livelock-error <> <>)
                                livelock
                                (map livelock? livelock))))
            (append stop
                    livelock
                    traces)))))))

(define-method (flush-async (pc <program-counter>))
  (flush-async pc '()))

(define-method (flush-async-event (pc <program-counter>) event)
  (let ((pc (clone pc #:trail (cons event (.trail pc)))))
    (flush-async pc)))

(define-method (run-external-q (pc <program-counter>) (instance <runtime:port>))
  (let* ((pc trigger (dequeue-external pc instance))
         (q-out (make <q-out> #:trigger trigger))
         (q-out (clone q-out #:location (.location trigger)))
         (q-out-pc (clone pc #:instance (%sut) #:statement q-out))
         (traces (run-to-completion pc trigger)))
    (map (lambda (t) (append t (list q-out-pc))) traces)))

(define-method (run-external (pc <program-counter>) event)
  (%debug "run-external ~a pc: ~s\n" event pc)
  (let ((queues (.external-q pc)))
    (if (or (null? queues)
            (pair? (.async pc))) '()
            (match (external-trigger-in-q? pc event)
              ((port q ...)
               (run-external-q pc (or port (%sut))))
              (_
               (let* ((model (runtime:%sut-model))
                      (ast (if (is-a? model <system>) model
                               (.behavior model)))
                      (error (make <match-error> #:ast ast #:input event
                                   #:message "match"))
                      (pc (clone pc #:status error)))
                 (%debug "<match> ~a pc: ~s\n" event pc)
                 (list (list pc) )))))))

(define-method (run-to-completion* (pc <program-counter>) event)
  (define (illegal-trace pc)
    (let ((illegal (make <implicit-illegal-error> #:ast (.trigger pc)
                         #:message "illegal")))
      (list (list (clone pc #:status illegal)))))
  (define (modeling? trace)
    (and=> (any .trigger (reverse trace)) ast:modeling?))
  (%debug "run-to-completion*: ~a\n" event)
  (cond
   ((is-a? (%sut) <runtime:port>)
    (run-interface pc event))
   ((external-trigger-in-q? pc event)
    (run-external pc event))
   ((external-trigger? event)
    (let ((pcs (cons pc (run-external-modeling pc event))))
      (append-map (cute run-external <> event) pcs)))
   ((requires-trigger? event)
    (let ((async-traces (if (null? (.async pc)) '()
                            (flush-async-event pc event))))
      (if (pair? async-traces) async-traces
          (let* ((pcs (cons pc (run-external-modeling pc event)))
                 (port (.port (string->trigger event)))
                 (blocked-port (and=> (blocked-on-boundary? pc event) .ast))
                 (traces (append-map (cute run-requires <> event) pcs)))
            (if (or (not port) (not (ast:eq? port blocked-port))) traces
                (filter (negate modeling?) traces))))))
   ((provides-trigger? event)
    (if (blocked-on-boundary-provides? pc event) (illegal-trace pc)
        (run-to-completion pc event)))
   ((async-event? pc event)
    (flush-async-event pc event))
   ((and (eq? event #f) (pair? (.async pc)))
    (flush-async pc))
   (else
    '())))

(define-method (run-to-completion* trace event)
  (extend-trace trace (cute run-to-completion* <> event)))

(define-method (run-to-completion*-context-switch (pc <program-counter>) event)
  (%debug "run-to-completion*-switch-context: ~a\n" event)
  (let* ((orig-pc pc)
         (blocked-on-action? (blocked-on-action? pc event))
         (pc (if (and (blocked-on-boundary? pc event)
                      (or blocked-on-action? (return-trigger? event)))
                 (blocked-on-boundary-switch-context pc event)
                 pc))
         (switched? (not (eq? pc orig-pc)))
         (trigger? (or (is-a? (%sut) <runtime:port>)
                       (provides-trigger? event)
                       (and (not blocked-on-action?)
                            (requires-trigger? event))
                       (async-event? pc event)))
         (pc (if (or switched? trigger?) pc
                 (blocked-on-boundary-collateral-release pc)))
         (pc (if (provides-trigger? event) pc
                 (switch-context pc)))
         (switched? (not (eq? pc orig-pc)))
         (pc (if switched? pc
                 (clone pc #:instance #f)))
         (skip-rtc? (or (not switched?)
                        (provides-trigger? event)))
         (pc (if (or trigger? (not switched?) (rtc-event? event)) pc
                 (clone pc #:trail (cons event (.trail pc)))))
         (traces (if skip-rtc? (run-to-completion* pc event)
                     (run-to-completion pc 'rtc))))
    (if (or skip-rtc? (not trigger?)) traces
        (append-map (cute run-to-completion* <> event) traces))))
