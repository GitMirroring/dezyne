;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn vm compliance)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm util)

  #:export (%compliance-check?
            check-provides-compliance
            check-provides-compliance*))

;;; Commentary:
;;;
;;; ’compliance’ implements running the provides port, checking for
;;; provides port compliance and zipping the provides port trace and
;;; component trace.
;;;
;;; Code:

;; Should we report compliance errors?
(define %compliance-check? (make-parameter #t))

(define (zip trigger trace port-trace)
  "Merge PORT-TRACE into TRACE, the first part starting just before the
component TRIGGER, the last part at the end.  Also synthesize
corresponding actions and returns to support the split-arrow trace
format."
  (define ((action-equal? r:port) a b)
    (let* ((instance (.instance b))
           (b (.statement b)))
      (and (is-a? a <action>) (is-a? b <action>)
           (eq? instance r:port)
           (equal? (.event.name a) (.event.name b)))))

  (define (port-pc-equal? a b)
    (and (ast:eq? (.statement a) (.statement b))
         (eq? (.instance a) (.instance b))))

  (define ((return-equal? r:port) a b)
    (let ((instance (.instance b))
          (b (.statement b)))
      (and (is-a? a <trigger-return>) (is-a? b <trigger-return>)
           (eq? instance r:port))))

  (define (statement-equal? a b)
    (and a b
         (eq? (.instance a) (.instance b))
         (ast:equal? (.trigger a) (.trigger b))
         (ast:equal? (.statement a) (.statement b))))

  (let* ((trigger (and=> trigger trigger->component-trigger))
         (port-status (.status (car port-trace)))
         (port-illegal? (or (as port-status <illegal-error>)
                            (as port-status <implicit-illegal-error>)))
         (port-on-index (or (list-index (compose (is? <on>) .statement)
                                        port-trace)
                            0))
         (port-trace-suffix
          port-trace-prefix (split-at port-trace port-on-index))
         (port-trace-prefix
          (if (not (.status (car port-trace-prefix))) port-trace-prefix
              (cdr port-trace-prefix)))
         (port-start (car port-trace-prefix))
         (port-instance (and=> (find .instance port-trace) .instance))
         (other-port (runtime:other-port port-instance))
         (instance (.container other-port))
         (foreign? (is-a? instance <runtime:foreign>))
         (instance (if (not foreign?) instance
                       other-port))
         (trace-index (or (and=> (list-index
                                  (conjoin
                                   (compose (is? <initial-compound>) .statement)
                                   (compose (cute ast:equal? <> trigger) .trigger)
                                   (compose (cute eq? <> instance) .instance))
                                  trace)
                                 1+)
                          (length trace)))
         (trace-suffix trace-prefix (split-at trace trace-index))
         (trace-suffix (if (not port-illegal?) trace-suffix
                           (take-right trace-suffix 1)))
         (merged? (or
                   (and (pair? trace-prefix)
                        (eq? (.instance (car trace-prefix)) port-instance))
                   (and (pair? trace-suffix)
                        (find (compose (cute eq? <> port-instance) .instance)
                              trace-suffix))))
         (status (.status (car trace)))
         (error? (and (is-a? status <error>)
                      (not (is-a? status <illegal-error>))
                      (not (is-a? status <implicit-illegal-error>))))
         (trace (if merged? trace
                    (append trace-suffix port-trace-prefix trace-prefix)))
         (trace (if (or (not port-illegal?) error?) trace
                    (let ((pc (clone (car trace) #:status port-illegal?)))
                      (cons pc trace))))
         (full-trace trace))

    (let loop ((trace trace) (port-trace port-trace) (previous #f))
      (if (null? trace) '()
          (let* ((pc (car trace))
                 (pc-instance (.instance pc))
                 (statement (.statement pc)))
            (cond
             ((and (not (is-a? (%sut) <runtime:port>))
                   (eq? instance pc-instance)
                   (is-a? statement <action>)
                   (is-a? pc-instance <runtime:component>)
                   (ast:out? statement))
              (let* ((port (.port statement))
                     (r:port (if (is-a? pc-instance <runtime:port>) pc-instance
                                 (runtime:port pc-instance port)))
                     (port (.ast r:port))
                     (port-name (.name port))
                     (r:other-port (runtime:other-port r:port))
                     (port-action+trace (member statement port-trace
                                                (action-equal? r:other-port)))
                     (port-action+trace (if (member statement trace-suffix (action-equal? r:other-port)) #f
                                            port-action+trace)))
                (match port-action+trace
                  ((action-pc tail ...)
                   (if (find (cute ast:equal? <> action-pc) full-trace)
                       (cons pc (loop (cdr trace) port-trace pc))
                       (cons* action-pc pc (loop (cdr trace) tail action-pc))))
                  (_
                   (cons pc (loop (cdr trace) port-trace pc))))))
             ((and (not (is-a? (%sut) <runtime:port>))
                   instance
                   (eq? pc-instance instance)
                   (is-a? statement <trigger-return>)
                   (or (.port.name statement)
                       foreign?))
              (let* ((port (.port statement))
                     (r:port (if (is-a? pc-instance <runtime:port>) pc-instance
                                 (runtime:port pc-instance port)))
                     (r:other-port (runtime:other-port r:port))
                     (port-return+trace (member statement port-trace
                                                (return-equal? r:other-port))))
                (match port-return+trace
                  ((return-pc tail ...)
                   (let* ((port-state (get-state return-pc))
                          (return-pc (clone return-pc #:state (.state pc)))
                          (return-pc (set-state return-pc port-state)))
                     (if (statement-equal? return-pc previous)
                         (cons pc (loop (cdr trace) port-trace pc))
                         (cons* return-pc pc (loop (cdr trace) tail return-pc)))))
                  (_
                   (cons pc (loop (cdr trace) port-trace pc))))))
             (else
              (cons pc (loop (cdr trace) port-trace pc)))))))))

(define (action-other-provides-port? port pc)
  (let ((statement (.statement pc)))
    (and (is-a? statement <action>)
         (let ((action-port (.port statement)))
           (and action-port
                (not (ast:eq? action-port port))
                (ast:provides? action-port))))))

(define (check-provides-fork port trace)
  "Check TRACE for a V-fork with respect to PORT.  If TRACE contains
actions to a provides port other than PORT, mark the trace as
<fork-error>, otherwise return false."
  (let* ((pc (find (conjoin
                    .trigger
                    (compose .port .trigger)
                    (compose (is? <on>) .statement)
                    (compose ast:provides? .port .trigger))
                   trace))
         (port (or (and pc (.port (.trigger pc))) port))
         (action-step (list-index (cute action-other-provides-port? port <>)
                                  trace)))
    (and pc
         action-step
         (let* ((trace (drop trace action-step))
                (action-pc (car trace))
                (action (.statement action-pc))
                (pc (clone pc
                           #:previous #f
                           #:status (make <fork-error>
                                      #:ast action
                                      #:message "non-compliance"))))
           (list (cons pc trace))))))

(define (check-requires-provides-fork trace)
  "Check TRACE for a Y-fork.  If TRACE contains actions to more than one
provides port, mark the trace as <fork-error>, otherwise return false."
  (let ((pc (find (cute action-other-provides-port? #f <>) (reverse trace))))
    (and pc
         (let* ((action (.statement pc))
                (port (.port action))
                (action-step (list-index
                              (cute action-other-provides-port? port <>)
                              trace)))
           (and action-step
                (let* ((trace (drop trace action-step))
                       (pc (car trace))
                       (pc (clone pc
                                  #:previous #f
                                  #:status (make <fork-error>
                                             #:action action
                                             #:ast (.statement pc)
                                             #:message "non-compliance"))))
                  (list (cons pc trace))))))))

(define-method (check-provides-compliance (pc <program-counter>)
                                          (instance <runtime:instance>)
                                          trigger trace)
  "Check TRACE for traces-compliance with the provides ports of INSTANCE, for EVENT.
Update the state of the provides port in TRACE for TRIGGER.  For a blocked
trace, the check is done in an incremental way: only the part that the
component has executed is considered.

Return a list of traces, possibly marked with <compliance-error>."

  (define (drop-prefix pc trigger trace)
    (let* ((r:port (runtime:port-name->instance (.port.name trigger)))
           (r:component-port (runtime:other-port r:port))
           (instance (.container r:component-port))
           (component-trigger (trigger->component-trigger trigger))
           (at (list-index
                (if (ast:provides? component-trigger)
                    (conjoin
                     (compose (cute eq? <> instance) .instance)
                     (compose (is? <initial-compound>) .statement)
                     (compose (cute ast:equal? <> component-trigger) .trigger))
                    (conjoin
                     .trigger
                     (compose ast:modeling? .trigger)
                     (compose (is? <runtime:port>) .instance)
                     (compose (is? <initial-compound>) .statement)))
                trace))
           (trace (if (not at) trace
                      (list-head trace (1+ at))))
           (trace (if (ast:provides? component-trigger) trace
                      (filter (compose (negate (is? <trigger-return>)) .statement) trace))))
      trace))

  (let* ((event (and=> trigger trigger->string))
         (blocking? (find (compose pair? .blocked) trace))
         (sut-trace (if (or (not trigger) (not blocking?)) trace
                        (drop-prefix pc trigger trace)))
         (sut-trail (trace->trail sut-trace))
         (component (runtime:ast-model instance))
         (provides-event (any (compose (conjoin (disjoin (is? <action>)
                                                         (is? <trigger>))
                                                ast:provides?
                                                identity)
                                       .statement)
                              (reverse trace)))
         (provides-event (and=> provides-event .event.name))
         (provides-trigger? (or (provides-trigger? provides-event)
                                (provides-trigger? event)))
         (port-event (and provides-trigger? (.event.name trigger)))
         (port (and provides-trigger? (.port trigger))))

    (define (check-compliance port traces)
      (let* ((trace (if (null? traces) '() (car traces)))
             (port-name (.name port))
             (port-instance (runtime:port-name->instance port-name)))

        (define (port-event? e)
          (and (string? e)
               (match (string-split e #\.)
                 (('state state) #f)
                 ((port event) (and (equal? port port-name) event))
                 (_ #f))))

        (define (run-provides-modeling ipc port-instance)
          (%debug "run-provides-modeling... ~a\n" event)
          (let* ((ipc (clone pc #:instance port-instance #:statement #f))
                 (interface ((compose .type .ast) port-instance))
                 (modeling-names (modeling-names interface)))
            (parameterize ((%sut port-instance)
                           (%exploring? #t)
                           (%strict? #f))
              (append-map (cute run-to-completion ipc <>) modeling-names))))

        (define (run-provides-port pc event)
          (%debug "run-provides-port... ~a ~a\n" port-instance event)
          (%debug "  pc: ~a\n" pc)
          (parameterize ((%sut port-instance)
                         (%exploring? #t))
            (run-to-completion pc event)))

        (%debug "check-provides-compliance... ~s: ~a [~a]\n" port-name event port-event)
        (let* ((ipc (clone pc #:previous #f #:trail '() #:status #f #:statement #f))
               (ipc (reset-reply ipc port-instance))
               (port-traces (if port-event (run-provides-port ipc port-event)
                                (run-provides-modeling ipc port-instance)))
               (port-prefix (format #f "~a." port-name))
               (sut-trail (filter (compose (disjoin
                                            (cute equal? <> "<illegal>")
                                            (cute string-prefix? port-prefix <>))
                                           cdr)
                                  sut-trail))
               (blocked? (and (pair? trace)
                              (or (pair? (.blocked (car trace)))
                                  (find blocked-on-boundary? trace)))))

          (define (port-trace->trail trace)
            (parameterize ((%sut port-instance)) (trace->trail trace)))

          (define (first-non-match port-trace)
            (define (non-matching-pair? a b)
              (and (not (equal? (cdr a) ((compose last (cut string-split <> #\.) cdr) b))) (cons a b)))

            (let* ((port-trail (port-trace->trail port-trace))
                   (port-length (length port-trail))
                   (sut-length (length sut-trail))
                   (port-next (and (> port-length sut-length)
                                   (and=> (list-ref port-trail sut-length) cdr)))
                   (truncate? (and provides-trigger?
                                   blocked?
                                   (not (equal? port-next "<illegal>"))))
                   (port-trail (if (not truncate?) port-trail
                                   ;; Check prefix only as long as trace is blocked
                                   (list-head port-trail (min (length port-trail)
                                                              (length sut-trail)))))
                   (foo (%debug "     port trail : ~s\n" (map cdr port-trail)))
                   (port-name ((compose .name .ast) port-instance))
                   (events (map (compose last (cut string-split <> #\.) cdr) sut-trail))
                   (foo (%debug "      sut trail : ~s\n\n" events)))
              (or (any non-matching-pair? port-trail sut-trail)
                  (let ((port-length (length port-trail))
                        (sut-length (length sut-trail)))
                    (cond ((< port-length sut-length) (cons '(#f) (list-ref sut-trail port-length)))
                          ((> port-length sut-length) (list (list-ref port-trail sut-length) #f))
                          (else #f))))))

          (define (port-acceptance-equal? a b)
            (and (equal? (and=> (caar a) trigger->string)
                         (and=> (caar b) trigger->string))
                 (equal? (cadr a) (cadr b))))

          (define (event-on-trail? event-name trace)
            (let* ((trail (port-trace->trail trace))
                   (trail (map cdr trail)))
              (member event-name trail)))

          (when (> (dzn:debugity) 0)
            (%debug "sut-trail:~s\n" (map cdr sut-trail))
            (%debug "port-traces[~s]:\n" (length port-traces))
            (parameterize ((%sut port-instance))
              (display-trails port-traces)))

          (let ((port-traces
                 non-compliances
                 (partition (negate first-non-match) port-traces)))
            (cond
             ((and (pair? (append port-traces non-compliances))
                   (every (compose (disjoin (is-status? <illegal-error>)
                                            (is-status? <implicit-illegal-error>))
                                   car)
                          (append port-traces non-compliances)))
              (%debug "  exit 0\n")
              (map (cute zip trigger <> <>) traces
                   (append port-traces non-compliances)))
             ((and (pair? trace)
                   (.status (car trace))
                   (not (is-a? (.status (car trace)) <match-error>))
                   (pair? (append port-traces non-compliances)))
              (%debug "  exit 1\n")
              (let* ((statement (.statement (car trace)))
                     (trace (rewrite-trace-head (cut clone <> #:statement #f) trace))
                     (trace (zip trigger trace (car (append port-traces non-compliances))))
                     (trace (rewrite-trace-head (cut clone <> #:statement statement) trace)))
                (list trace)))
             ((and (pair? port-traces)
                   (pair? trace))
              (%debug "  exit 2\n")
              (let* ((port-pcs (map (compose (cut clone pc #:state <>) .state car) port-traces))
                     (traces (map (lambda (port-pc)
                                    (cons (set-state (car trace) (get-state port-pc port-instance))
                                          (cdr trace)))
                                  port-pcs)))
                (map (cute zip trigger <> <>) traces port-traces)))
             ((and (%compliance-check?)
                   (null? non-compliances)
                   (not blocking?)
                   (null? port-traces)
                   (pair? sut-trail))
              (%debug "  exit 3\n")
              (let ((status (make <compliance-error>
                              #:message "non-compliance"
                              #:component-acceptance (caar sut-trail)
                              #:port port-instance)))
                (list (rewrite-trace-head (cut clone <> #:status status) trace))))
             ((null? non-compliances)
              (%debug "  exit 4\n")
              (if (null? trace) '()
                  (list trace)))
             ((and (not port-event)
                   (null? sut-trail)
                   (pair? trace))
              (%debug "  exit 5\n")
              (list trace))
             ((let* ((port-instance (any .instance trace))
                     (container (and=> port-instance .container)))
                (is-a? container <runtime:foreign>))
              (%debug "  exit 6\n")
              (map (cute zip trigger trace <>)
                   (append port-traces non-compliances)))
             ((%compliance-check?)
              (%debug "  exit 7\n")
              (let* ((port-acceptances (map first-non-match non-compliances))
                     (port-acceptances (delete-duplicates port-acceptances
                                                          port-acceptance-equal?))
                     (component-acceptance
                      (and (pair? trace)
                           (or (and (pair? port-acceptances)
                                    (cadar port-acceptances))
                               (and=> (.status pc) .ast)
                               (if (is-a? (%sut) <runtime:system>)
                                   (trigger->system-trigger port-instance trigger)
                                   (trigger->component-trigger trigger)))))
                     (other-port-instance (runtime:other-port port-instance))
                     (instance (.container other-port-instance))
                     (component-acceptance
                      (if (and component-acceptance
                               (is-a? instance <runtime:system>))
                          (trigger->system-trigger instance component-acceptance)
                          component-acceptance))
                     (port-acceptances (make <acceptances>
                                         #:elements (map caar port-acceptances)))
                     (compliance-trigger
                      (and trigger
                           (null? sut-trail)
                           (not (any (cute event-on-trail? (.event.name trigger) <>)
                                     non-compliances))
                           trigger))
                     (pc (clone pc
                                #:previous #f
                                #:status (make <compliance-error>
                                           #:message "non-compliance"
                                           #:component-acceptance component-acceptance
                                           #:port port-instance
                                           #:port-acceptance port-acceptances
                                           #:trigger compliance-trigger))))
                (if (null? trace) (list (cons pc (car non-compliances)))
                    (let* ((tail (cdr trace))
                           (trace (cons pc tail)))
                      (list (zip trigger trace (car non-compliances)))))))
             (else
              (%debug "  exit 8\n")
              (let* ((port-trace (car non-compliances))
                     (port-state (get-state (last port-trace)))
                     (port-trace
                      (rewrite-trace-head
                       (cut set-state <> port-state)
                       port-trace))
                     (trace (zip trigger trace (car non-compliances)))
                     (trace
                      (rewrite-trace-head
                       (cut clone <> #:skip-compliance? #t)
                       trace)))
                (list trace))))))))

    (define (check-provides-fork-and-zip port trace)
      (let ((traces (check-provides-fork port trace)))
        (cond ((not traces)
               #f)
              (port
               (check-compliance port traces))
              (else
               (let ((ports (ast:provides-port* component)))
                 (fold check-compliance traces ports))))))

    (if port (or (and (%compliance-check?)
                      (> (length (ast:provides-port* component)) 1)
                      (is-a? (%sut) <runtime:component>)
                      (check-provides-fork-and-zip port trace))
                 (check-compliance port (list trace)))
        (let ((ports (ast:provides-port* component)))
          (or (and (%compliance-check?)
                   (> (length ports) 1)
                   (is-a? (%sut) <runtime:component>)
                   (or (check-provides-fork-and-zip #f trace)
                       (check-requires-provides-fork trace)))
              (fold check-compliance (list trace) ports))))))

(define-method (check-provides-compliance (pc <program-counter>) event trace)
  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (and (string? event)
                       (not (equal? event "<defer>"))
                       (clone (string->trigger event) #:parent component))))
    (check-provides-compliance pc (%sut) trigger trace)))

(define* (check-provides-compliance+ pc event trace)
  "Run check-provides-compliance.  For a blocking trace that has been
released by a requires event, also rerun check-provides-compliance for
the full trace, i.e., starting from the initial blocking provides
event.  This ensures proper of zipping the port trace, including the
port return."
  (let* ((skip? (blocked-on-boundary? (car trace) event))
         (traces (if skip? (list trace)
                     (check-provides-compliance pc event trace)))
         (pc (car trace))
         (blocked (.blocked pc))
         (collateral (.collateral pc))
         (compliance-for-blocking?
          (or (find blocked-on-boundary? trace)
              (and (not (find .status trace))
                   (find (compose pair? .blocked) trace))))
         (pcs (filter
               (conjoin
                (compose (is? <initial-compound>) .statement)
                (compose ast:provides? .trigger))
               (reverse trace))))
    (cond
     ((and (pair? pcs)
           compliance-for-blocking?
           (find (compose (is? <trigger-return>) .statement) trace))
      =>
      (lambda (rpc)
        (let* ((rtc-block-pc (and (pair? collateral)
                                  (rtc-block-pc (cdar collateral))))
               (rtc-block-trigger (and=> rtc-block-pc .trigger))
               (rtc-block-trigger (if (not
                                       (and rtc-block-trigger
                                            (is-a? (%sut) <runtime:system>)))
                                      rtc-block-trigger
                                      (trigger->system-trigger
                                       (.instance rtc-block-pc)
                                       rtc-block-trigger))))
          (let loop ((traces traces) (pcs pcs))
            (if (null? pcs) traces
                (let* ((trail (trace->trail (car pcs)))
                       (event (match trail ((ast . event) event) (_ event)))
                       (cpc (last trace))
                       (cpc (reset-replies cpc))
                       (cpc (clone cpc #:instance #f))
                       (skip? (or
                               (and (and=> rtc-block-trigger
                                           ast:provides?)
                                    (equal? (trigger->string rtc-block-trigger)
                                            event))
                               (symbol? event)
                               (not (.port (string->trigger event))))))
                  (if skip? (loop traces (cdr pcs))
                      (loop
                       (append-map
                        (cute check-provides-compliance cpc event <>)
                        traces)
                       (cdr pcs)))))))))
     (else
      traces))))

;;TODO split check from determine provides trace(s) from pc and event
;;to avoid doing the determination work for every trace in traces
(define-method (check-provides-compliance* (pc <program-counter>) event traces)
  "Helper to call CHECK-PROVIDES-COMPLIANCE+ on for empty set of
TRACES."
  (cond
   ((null? traces)
    (check-provides-compliance pc event '()))
   (else
    (append-map
     (cute check-provides-compliance+ pc event <>)
     traces))))
