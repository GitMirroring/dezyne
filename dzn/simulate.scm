;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn simulate)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn display)
  #:use-module (dzn explore)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn shell-util)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm normalize)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm step)
  #:use-module (dzn vm util)
  #:export (filter-root
            repl
            run-trail
            simulate
            simulate**))

;;; Commentary:
;;;
;;; ’simulate’ implements a system simulator using the Dezyne vm.
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
    (and (eq? (.instance a) (.instance a))
         (ast:equal? (.trigger a) (.trigger b))
         (ast:equal? (.statement a) (.statement b))))

  (let* ((trigger (and=> trigger trigger->component-trigger))
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
         (trace-index (or (and=> (list-index
                                  (conjoin
                                   (compose (is? <initial-compound>) .statement)
                                   (compose (cute ast:equal? <> trigger) .trigger)
                                   (compose (cute eq? <> instance) .instance))
                                  trace)
                                 1+)
                          (length trace)))
         (trace-suffix trace-prefix (split-at trace trace-index))
         (merged? (or
                   (and (pair? trace-prefix)
                        (eq? (.instance (car trace-prefix)) port-instance))
                   (and (pair? trace-suffix)
                        (find (compose (cute eq? <> port-instance) .instance)
                              trace-suffix))))
         (trace (if merged? trace
                    (append trace-suffix port-trace-prefix trace-prefix)))
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
                   (eq? pc-instance instance)
                   (is-a? statement <trigger-return>)
                   (.port.name statement))
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

(define (check-provides-compliance pc event trace)
  "Check TRACE for traces-compliance with the provides ports, for EVENT.
Update the state of the provides port in TRACE for EVENT.  For a blocked
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

  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (and (string? event)
                       (not (equal? event "<defer>"))
                       (clone (string->trigger event) #:parent component)))
         (blocking? (find (compose pair? .blocked) trace))
         (sut-trace (if (or (not trigger) (not blocking?)) trace
                        (drop-prefix pc trigger trace)))
         (sut-trail (trace->trail sut-trace))
         (provides-trigger? (provides-trigger? event))
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
             ((and (pair? trace)
                   (.status (car trace))
                   (not (is-a? (.status (car trace)) <match-error>))
                   (pair? (append port-traces non-compliances)))
              (%debug "  exit 0\n")
              (let* ((statement (.statement (car trace)))
                     (trace (rewrite-trace-head (cut clone <> #:statement #f) trace))
                     (trace (zip trigger trace (car (append port-traces non-compliances))))
                     (trace (if (not (.status (car trace))) trace
                                (rewrite-trace-head (cut clone <> #:statement statement) trace))))
                (list trace)))
             ((and (pair? port-traces)
                   (pair? trace))
              (%debug "  exit 1\n")
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
              (%debug "  exit 2\n")
              (let ((status (make <compliance-error>
                              #:message "non-compliance"
                              #:component-acceptance (caar sut-trail)
                              #:port port-instance)))
                (list (rewrite-trace-head (cut clone <> #:status status) trace))))
             ((null? non-compliances)
              (%debug "  exit 3\n")
              (if (null? trace) '()
                  (list trace)))
             ((and (not port-event)
                   (null? sut-trail)
                   (pair? trace))
              (%debug "  exit 4\n")
              (list trace))
             ((%compliance-check?)
              (%debug "  exit 5\n")
              (let* ((port-acceptances (map first-non-match non-compliances))
                     (port-acceptances (delete-duplicates port-acceptances port-acceptance-equal?))
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
                      (if (and component-acceptance (is-a? (%sut) <runtime:system>))
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
              (%debug "  exit 6\n")
              (let* ((port-trace (car non-compliances))
                     (port-state (get-state (last port-trace)))
                     (port-trace
                      (rewrite-trace-head
                       (cut set-state <> port-state)
                       port-trace)))
                (list (zip trigger trace (car non-compliances))))))))))

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
         (rtc-block-pc (and (pair? collateral)
                            (rtc-block-pc (cdar collateral))))
         (rtc-block-trigger (and=> rtc-block-pc .trigger))
         (rtc-block-trigger (if (and rtc-block-trigger
                                     (is-a? (%sut) <runtime:system>))
                                (trigger->system-trigger (.instance rtc-block-pc) rtc-block-trigger)
                                rtc-block-trigger)))
    (cond
     ((and compliance-for-blocking?
           (find (compose (is? <trigger-return>)
                          .statement)
                 trace))
      =>
      (lambda (rpc)
        (let ((pcs (filter
                    (conjoin
                     (compose (is? <initial-compound>) .statement)
                     (compose ast:provides? .trigger))
                    (reverse trace))))
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
  (cond
   ((null? traces)
    (check-provides-compliance pc event '()))
   (else
    (append-map
     (cute check-provides-compliance+ pc event <>)
     traces))))

(define-method (event-traces-alist (pc <program-counter>))

  (define (event-traces-alist pc)
    (define (event->label-traces pc event)
      (let* ((pc (clone pc #:instance #f #:statement #f #:trail '()))
             (pc (reset-replies pc))
             (traces (parameterize ((%exploring? #t)
                                    (%liveness? 'component))
                       (run-to-completion*-context-switch pc event))))
        (cons event traces)))
    (let ((labels (labels pc)))
      (map (cute event->label-traces pc <>) labels)))

  (define (provides-event->label-traces pc event)
    (let* ((pc (clone pc #:instance #f #:statement #f #:trail '()))
           (pc (reset-replies pc))
           (traces (parameterize ((%exploring? #t)
                                  (%liveness? 'component))
                     (run-to-completion* pc event))))
      (cons event traces)))

  (define (requires-event->label-traces pc event)
    (let* ((pc (clone pc #:instance #f #:statement #f #:trail '()))
           (pc (reset-replies pc))
           (traces (parameterize ((%exploring? #t)
                                  (%liveness? 'component))
                     (run-to-completion* pc event)))
           (trails (map trace->string-trail traces)))
      (fold
       (lambda (trace trail alist)
         (match trail
           ((event rest ...)
            (let* ((entry (or (assoc-ref alist event) '()))
                   (entry (cons trace entry)))
              (acons event entry (alist-delete event alist))))
           (_
            alist)))
       '()
       traces trails)))

  (define (add-port port entry)
    (match entry
      ((event traces ...)
       (let* ((name (string-join (runtime:instance->path port) "."))
              (event (string-append name "." event)))
         (cons event traces)))))

  (define (port->label-traces pc port)
    (let* ((pc (clone pc #:trail '()))
           (interface (.type (.ast port)))
           (alist (parameterize ((%sut port))
                    (if (ast:provides? port)
                        (map (cute provides-event->label-traces pc <>)
                             (map .name (ast:in-event* interface)))
                        (append-map (cute requires-event->label-traces pc <>)
                                    (modeling-names interface))))))
      (map (cute add-port port <>) alist)))

  (define (system-event-traces-alist pc)
    (let* ((boundary (filter runtime:boundary-port? (%instances)))
           (traces (append-map (cute port->label-traces pc <>) boundary))
           (fake-traces (list (list pc)))
           (defer-traces (map (cute cons <> fake-traces) (defer-labels pc)))
           (return-traces (map (cute cons <> fake-traces) (return-labels pc)))
           (rtc-traces (map (cute cons <> fake-traces) (rtc-labels pc))))
      (append traces defer-traces return-traces rtc-traces)))

  (if (is-a? (%sut) <runtime:system>) (system-event-traces-alist pc)
      (event-traces-alist pc)))

(define-method (event-traces-alist (pcs <list>))
  (let* ((pcs (map (cute clone <> #:status #f) pcs))
         (alists (map event-traces-alist pcs)))
    (if (null? alists) '()
        (merge-alist-list alists))))

(define-method (eligible-labels event-traces-alist)
  (let* ((eligible-traces
          (filter (match-lambda
                    ((event (pcs tails ...) ...)
                     (find (disjoin (is-status? <end-of-trail>)
                                    (is-status? <livelock-error>)
                                    (negate .status)) pcs)))
                  event-traces-alist))
         (labels (map car eligible-traces))
         (labels (delete-duplicates labels))
         (labels (sort labels string<)))
    labels))

(define (labels-filter-blocked-ports traces labels)
  "Remove from LABELS every label for all ports that are blocked in
TRACES."

  (define (blocked+collateral-ports pc)
    (let* ((blocked-ports (blocked-ports pc))
           (collateral-instances (filter (cute get-handling pc <>)
                                         (%instances)))
           (collateral-ports (append-map runtime:runtime-port*
                                         collateral-instances))
           (collateral-ports (map runtime:other-port collateral-ports))
           (blocked-ports (append blocked-ports collateral-ports))
           (blocked-ports (filter runtime:boundary-port? blocked-ports))
           (blocked-ports (filter ast:provides? blocked-ports)))
      (map (compose .name .ast) blocked-ports)))

  (let* ((pcs (map car traces))
         (blocked-sets (map blocked+collateral-ports pcs))
         (blocked-port-names
          (if (null? blocked-sets) '()
              (apply lset-intersection equal? blocked-sets))))
    (filter (disjoin
             rtc-event?
             return-trigger?
             (compose
              (negate (cute member <> blocked-port-names))
              .port.name
              string->trigger))
            labels)))

(define (optional-trace? trace)
  (let* ((requires-on (filter
                       (conjoin (compose (conjoin (is? <runtime:port>)
                                                  ast:requires?)
                                         .instance)
                                (compose (is? <on>) .statement))
                       trace))
         (triggers (map .trigger requires-on)))
    (find ast:optional? triggers)))

(define-method (check-deadlock (pc <program-counter>) event-traces-alist event)
  (define (mark-deadlock pc)
    (let* ((error (.status pc))
           (ast (or (and error (.ast error))
                    (let ((model (runtime:%sut-model)))
                      (if (or (is-a? model <system>) (is-a? model <foreign>)) model
                          (.behavior model))))))
      (if (and error
               (not (is-a? error <implicit-illegal-error>))
               (not (is-a? error <end-of-trail>)))
          pc
          (clone pc #:status (make <deadlock-error> #:ast ast #:message "deadlock")))))
  (let ((event-traces-alist
         (map (match-lambda
                (("optional" traces ...)
                 '("optional"))
                ((event traces ...)
                 (cons event (filter (negate optional-trace?) traces))))
              event-traces-alist)))
    (and
     (pair? event-traces-alist)
     (let* ((pcs-alist (map
                        (match-lambda
                          ((event traces ...)
                           (cons event (map car traces))))
                        event-traces-alist))
            (valid-pcs-alist
             (map
              (match-lambda
                ((event pcs ...)
                 (cons event (filter (disjoin (is-status? <end-of-trail>)
                                              (is-status? <livelock-error>)
                                              (negate .status))
                                     pcs))))
              pcs-alist))
            (valid-pcs (append-map cdr valid-pcs-alist)))
       (and (null? valid-pcs)
            (let* ((traces (assoc-ref event-traces-alist event))
                   (traces (if (pair? traces) traces (list (list pc))))
                   (traces (map (cute rewrite-trace-head mark-deadlock <>)
                                traces)))
              (if (is-a? (%sut) <runtime:port>) traces
                  (append-map (cute check-provides-compliance pc #f <>)
                              traces))))))))

(define (check-interface-determinism traces)
  "Determine wether TRACES contain unobservably nonterministic traces,
possibly after running RUN-SILENT and return them, or false."
  (define (optional->inevitable event)
    (if (equal? event "optional") "inevitable"
        event))
  (define (trace->trail-traces trace)
    (let* ((trail (parameterize ((%modeling? #t))
                    (trace->string-trail trace)))
           (trail (map optional->inevitable trail)))
      (cons trail (list trace))))
  (define (mark-determinism trace)
    (let* ((trace (set-trigger-locations trace))
           (index (list-index (compose (is? <on>) .statement)
                              trace))
           (pc (if index (list-ref trace index)
                   (car trace)))
           (index (and=>
                   (list-index (compose (is? <initial-compound>) .statement)
                               trace)
                   1+))
           (trace (if index (drop trace index)
                      trace))
           (error (make <determinism-error>
                    #:ast (or (.trigger pc)
                              (.behavior (runtime:%sut-model)))
                    #:message "non-deterministic"))
           (pc (clone pc #:status error)))
      (cons pc trace)))
  (define extend-silent-traces
    (match-lambda
      (((and ("inevitable") trail) silent-traces ...)
       (cons trail (append silent-traces traces)))
      (trail+traces
       trail+traces)))
  (define check-determisistic
    (match-lambda
      ((trail traces ...)
       (let* ((traces
               (delete-duplicates
                traces
                (lambda (a b)
                  (rtc-program-counter-equal? (car a) (car b))))))
         (match traces
           ((trace trace2 rest ...)
            (map mark-determinism traces))
           (_ '()))))))
  (define (check-traces traces)
    (let* ((trail-alist (map trace->trail-traces traces))
           (trail-alist (merge-alist-list (list trail-alist '())))
           (trail-alist (map extend-silent-traces trail-alist))
           (traces (append-map check-determisistic trail-alist)))
      (and (pair? traces) traces)))
  (define (check-silence traces)
    (let* ((pcs (map last traces))
           (start-traces (map list pcs))
           (traces (run-silent traces))
           (traces (append start-traces traces))
           (alist (cons '() traces))
           (traces (check-determisistic alist)))
      (and (pair? traces) traces)))
  (or (check-traces traces)
      (check-silence traces)))

(define (check-interface-livelock traces)
  "Determine wether TRACES contain a livelock after running RUN-SILENT and return them,
or false."
  (define (livelock? trace)
    (let ((trail (parameterize ((%modeling? #t)) (trace->string-trail trace))))
      (and (> (length trace) 1)
           (pc-equal? (car trace) (last trace))
           (list-index (compose (is? <on>) .statement) trace))))
  (let* ((traces (run-silent traces))
         (traces (run-silent traces))
         (livelock traces (partition livelock? traces))
         (livelock (map (cute mark-livelock-error <> <>)
                        livelock
                        (map livelock? livelock))))
    (as livelock <pair>)))

(define-method (run-state (pc <program-counter>) (state <list>))
  (let ((pc (set-state pc state)))
    (serialize (.state pc) (current-output-port))
    (newline)
    (list (list pc))))

(define-method (run-sut (pc+blocked-trace <list>) event)
  (let* ((pc (car pc+blocked-trace))
         (blocked-trace (cdr pc+blocked-trace))
         (pc (reset-replies pc))
         (pc (prune-defer pc)))
    (%debug "run-sut pc: ~s\n" pc)
    (%debug "     event: ~s\n" event)
    (match event
      (('state state ...)
       (run-state pc state))
      ((? string?)
       (let* ((traces (run-to-completion*-context-switch pc event))
              (traces (if (pair? traces) traces
                          (let* ((model (runtime:%sut-model))
                                 (error (make <match-error>
                                          #:message "match"
                                          #:ast model
                                          #:input event)))
                            (%debug "<match-error>: ~a\n" event)
                            (list (list (clone pc #:status error))))))
              (traces (map (cute append <> pc+blocked-trace) traces)))
         (if (is-a? (%sut) <runtime:port>) traces
             (let* ((cpc (if (requires-trigger? event) pc
                             (last pc+blocked-trace)))
                    (cpc (reset-replies cpc))
                    (cpc (clone cpc #:instance #f)))
               (check-provides-compliance* cpc event traces)))))
      ((? (const (and (pair? (.defer pc)) (blocked-on-boundary? pc))))
       (list (cons (clone pc #:defer '()) pc+blocked-trace)))
      ((? (const (and (pair? (.defer pc)) (not (%strict?)))))
       (let* ((traces (flush-defer pc))
              (traces (if (null? blocked-trace) traces
                          (extend-trace blocked-trace (const traces)))))
         (check-provides-compliance* pc event traces)))
      (_
       (when (not (eq? (switch-context pc) pc))
         (%debug "<eot> with switchable, non-rtc pc\n"))
       (let ((trace (cons pc (cdr pc+blocked-trace))))
         (if (or (is-a? (%sut) <runtime:port>)
                 (pair? (.blocked pc))) (list trace)
                 (check-provides-compliance pc event trace)))))))

(define-method (pc->modeling-lts (pc <program-counter>))
  "Create a partial modeling-LTS at PC, i.e., use inevitable and
optional labels only and stop when observable event seen."

  (define observable?
    (compose pair? trace->string-trail))

  (let ((lts pc->state-number count
             (parameterize ((%exploring? #t))
               (pc->rtc-lts pc
                            #:trace-done? observable?
                            #:labels (const '("inevitable" "optional"))))))
    (when (%debug?)
      (parameterize ((%modeling? #t))
        (pretty-print
         (debug:lts->alist pc->state-number lts) (current-error-port))))
    lts))

(define (modeling-lts-stable? lts)
  "Return if modeling-LTS has a node without (INEVITABLE event)."

  (define (inevitable-observable? trace)
    (let ((trail (parameterize ((%modeling? #t))
                   (trace->string-trail trace))))
      (match trail
        (("inevitable" observable event ...)
         #t)
        (_
         #f))))

  (define (node-stable? from pc+traces result)
    (or result
        (let ((traces (match pc+traces
                        ((pc traces ...)
                         traces)
                        (#f
                         '()))))
          (not (find inevitable-observable? traces)))))

  (hash-fold node-stable? #f lts))

(define (modeling-lts->observables lts)
  "Return all observables from the modeling-LTS."

  (define (observable trace)
    (let ((trail (parameterize ((%modeling? #t))
                   (trace->string-trail trace))))
      (match trail
        (((and modeling (or "inevitable" "optional")) observable event ...)
         (list modeling observable))
        (_
         #f))))

  (define (node-observables from pc+traces)
    (let ((traces (match pc+traces
                    ((pc traces ...)
                     traces)
                    (#f
                     '()))))
      (filter-map observable traces)))

  (apply append (hash-map->list node-observables lts)))

(define* (end-report from-pcs list-of-traces #:key deadlock-check?
                     interface-determinism-check? interface-livelock-check?
                     queue-full-check? refusals-check?
                     state? trace internal? locations? verbose?)
  "If DEADLOCK-CHECK?, run check-deadlock.  If QUEUE-FULL-CHECK?, run
check-external queue-full.  If REFUSALS-CHECK?, run refusals-check.  Run
final REPORT and return exit status."

  (define (deadlock-report pcs traces)
    "Run check-deadlock and report.  Return exit status."
    (let* ((pcs (if (null? traces) pcs
                    (map car traces)))
           (pc (car pcs))
           (event pc ((%next-input) pc))
           (event-traces-alist (event-traces-alist pcs))
           (eligible (eligible-labels event-traces-alist))
           (eligible (labels-filter-blocked-ports traces eligible))
           (deadlock-traces (check-deadlock pc event-traces-alist event)))
      (or (and deadlock-traces
               (pair? (.blocked pc))
               (report traces
                       #:internal? internal?
                       #:locations? locations?
                       #:trace trace
                       #:verbose? verbose?))
          (and deadlock-traces
               (report deadlock-traces
                       #:eligible eligible
                       #:internal? internal?
                       #:locations? locations?
                       #:trace trace
                       #:verbose? verbose?)))))

  (define (check-external-queue-full traces)
    (let ((pcs (map car traces)))
      (let loop ((pcs pcs) (q 0))
        (let* ((traces (append-map run-external-modeling pcs))
               (error (find (compose .status car) traces)))
          (if error (list error)
              (let* ((pcs (map car traces))
                     (external-queues (append-map .external-q pcs))
                     (queue (append-map cdr external-queues))
                     (q-size (length queue)))
                (and (> q-size q)
                     (loop pcs q-size))))))))

  (define (interface-deadlock-report pcs traces)
    "Run deadlock check for all PCs per state."
    (let ((pcs (if (null? traces) pcs
                   (map car traces))))
      (let loop ((pcs pcs))
        (match pcs
          (() #f)
          ((pc rest ...)
           (let ((pcs rest
                      (partition (cute rtc-program-counter-equal? <> pc) pcs))
                 (traces other
                         (partition (compose (cute rtc-program-counter-equal? <> pc) car)
                                    traces)))
             (or (deadlock-report pcs traces)
                 (loop rest))))))))

  (define (refusals-report from-pcs pc traces)
    "Run check-provides-fork and check-refusals and report.  Return exit
status."

    (define ((port-lts-stable? pc) port)
      (let* ((instance (runtime:port (%sut) port))
             (instance (runtime:other-port instance))
             (lts (parameterize ((%sut instance))
                    (pc->modeling-lts pc))))
        (parameterize ((%sut instance))
          (and (modeling-lts-stable? lts) lts))))

    (define (requires-ports-stable? component pc)
      (let ((requires (ast:requires-port* component)))
        (every (port-lts-stable? pc) requires)))

    (define (port-refusals pc port)
      (let* ((instance (runtime:port (%sut) port))
             (instance (runtime:other-port instance))
             (lts (parameterize ((%sut instance))
                    (pc->modeling-lts pc)))
             (port-name (.name port))
             (refusals (parameterize ((%sut instance))
                         (modeling-lts->observables lts)))
             (refusals (map (match-lambda
                              ((modeling action)
                               (list modeling (string-append port-name "." action))))
                            refusals))
             (refusals (map list refusals)))
        (and (pair? refusals) refusals)))

    (define blocked?
      (compose pair? .blocked car))

    (let ((component (runtime:%sut-model)))
      (or
       ;; When a trace is blocked, and the component is stable (the
       ;; requires ports are stable), the refusal is the return of the
       ;; blocked provides port.
       (and (= (length from-pcs) 1)
            (find (compose pair? .blocked car) traces)
            (null? (.external-q (car from-pcs)))
            (requires-ports-stable? component pc)
            (eq? (switch-context pc) pc)
            (eq? (blocked-on-boundary-switch-context pc) pc)
            (eq? (blocked-on-boundary-collateral-release pc))
            (not (any (compose blocked-on-boundary? car) traces))
            (let* ((trace-format trace)
                   (trace (find (compose pair? .blocked car) traces))
                   (trace (reverse (set-trigger-locations (reverse trace))))
                   (pc (find (conjoin .trigger
                                      (compose (is? <runtime:component>)
                                               .instance))
                             (reverse trace)))
                   (trigger (.trigger pc))
                   (pc (clone pc #:status (make <refusals-error>
                                            #:ast (.behavior component)
                                            #:message "non-compliance"
                                            #:refusals trigger)))
                   (trace (cons pc trace)))
              (report (list trace)
                      #:eligible '()
                      #:internal? internal?
                      #:locations? locations?
                      #:state? state?
                      #:trace trace-format
                      #:verbose? verbose?)))

       ;; In the failures model, refusals can only occur when the
       ;; component LTS is stable.  When the component LTS is not
       ;; stable, that means outgoing tau events: no refusals.  A
       ;; component LTS is stable when all requires port LTSs are stable
       ;; and the defer queue is empty.  When the a provides port's
       ;; modeling-LTS is not stable, the refusals set consists of all
       ;; its observable events.
       (let* ((pcs (if (null? traces) from-pcs
                       (map car traces)))
              (pc (car pcs)))
         (and (= (length from-pcs) 1)
              (null? (.external-q (car from-pcs)))
              (and (requires-ports-stable? component pc)
                   (null? (.defer pc)))
              (let* ((ports (ast:provides-port* component))
                     (instable (find (negate (port-lts-stable? pc)) ports))
                     (refusals (and instable (port-refusals pc instable))))

                (define (mark-refusals pc)
                  (clone pc #:status (make <refusals-error>
                                       #:ast (.behavior component)
                                       #:message "non-compliance"
                                       #:refusals refusals)))

                (and (pair? refusals)
                     (let ((traces (map (cute rewrite-trace-head mark-refusals <>) traces)))
                       (report traces
                               #:eligible '()
                               #:internal? internal?
                               #:locations? locations?
                               #:state? state?
                               #:trace trace
                               #:verbose? verbose?)))))))))

  (let* ((traces (apply append list-of-traces))
         (traces (filter-illegal+implicit-illegal traces))
         (traces (filter-match-error traces))
         (pcs (map car traces))
         (status (any (compose
                       (conjoin .status
                                (disjoin (negate (is-status? <end-of-trail>))
                                         (compose .labels .status)))
                       car)
                      traces))
         (deadlock-check? (and deadlock-check?
                               (not status)))
         (refusals-check? (and (%compliance-check?)
                               refusals-check?
                               (not status)
                               (is-a? (%sut) <runtime:component>))))
    (or (and deadlock-check?
             (is-a? (%sut) <runtime:port>)
             (interface-deadlock-report from-pcs traces))
        (and deadlock-check?
             (not (is-a? (%sut) <runtime:port>))
             (deadlock-report from-pcs traces))
        (and queue-full-check?
             (not (is-a? (%sut) <runtime:port>))
             (and=> (check-external-queue-full traces)
                    (cute report <>
                          #:eligible '()
                          #:internal? internal?
                          #:locations? locations?
                          #:state? state?
                          #:trace trace
                          #:verbose? verbose?)))
        (and interface-determinism-check?
             (not status)
             (is-a? (%sut) <runtime:port>)
             (and=> (check-interface-determinism traces)
                    (cute report <>
                          #:eligible '()
                          #:internal? internal?
                          #:locations? locations?
                          #:state? state?
                          #:trace trace
                          #:verbose? verbose?)))
        (and interface-livelock-check?
             (not status)
             (is-a? (%sut) <runtime:port>)
             (and=> (check-interface-livelock traces)
                    (cute report <>
                          #:eligible '()
                          #:internal? internal?
                          #:locations? locations?
                          #:state? state?
                          #:trace trace
                          #:verbose? verbose?)))
        (and refusals-check? (null? traces)
             (any (cute refusals-report from-pcs <> '()) from-pcs))
        (and refusals-check? (pair? traces)
             (any (cute refusals-report from-pcs <> <>) from-pcs list-of-traces))
        (let* ((eligible
                (and deadlock-check?
                     (eligible-labels (event-traces-alist pcs))))
               (eligible (and eligible
                              (labels-filter-blocked-ports traces eligible))))
          (report traces
                  #:eligible (or eligible '())
                  #:internal? internal?
                  #:locations? locations?
                  #:state? state?
                  #:trace trace
                  #:verbose? verbose?)))))

(define* (run-trail trail #:key deadlock-check? interface-determinism-check?
                    interface-livelock-check? queue-full-check? refusals-check?
                    internal?
                    locations? state? trace verbose?)
  "Run TRAIL on (%SUT) and produce a trace on STDOUT."

  (define (trail-input pc)
    (match (.trail pc)
      ((event trail ...)
       (%debug "  pop trail ~s ~s\n" event trail)
       (values event (clone pc #:trail trail)))
      (() (values #f pc))))

  (define (drop-event pc)
    (let ((event pc (trail-input pc)))
      pc))

  (define (end-of-trail? traces)
    (and (not (isatty? (current-input-port)))
         (pair? traces)
         (not ((%next-input) (caar traces)))))

  (define (split-collateral-trace trace)
    (if (null? trace) (values '() '())
        (let* ((pc (car trace))
               (collateral (.collateral pc))
               (pc (rtc-block-pc (cdar collateral)))
               (instance (.instance pc))
               (trigger (.trigger pc))
               (index (list-index
                       (conjoin
                        (compose (cute eq? <> instance) .instance)
                        (compose (is? <initial-compound>) .statement)
                        (compose (cute ast:eq? <> trigger) .trigger))
                       trace))
               (port-index
                (list-index
                       (conjoin
                        (compose (is? <runtime:port>) .instance)
                        (compose (is? <initial-compound>) .statement))
                       trace)))
          (if (not port-index) (values trace '())
               ;; PORT-INDEX: port <initial-compound>
               ;; PORT-INDEX+1: port rtc
               ;; PORT-INDEX+2: EOT or start of continuation
              (let ((port-index (min (+ port-index 2) (length trace))))
                (split-at trace port-index))))))

  (let* ((trail (if (and (null? trail)
                         (not (isatty? (current-input-port))))
                    '(#f) trail))
         (pc (make-pc #:trail trail)))
    (when (isatty? (current-input-port))
      (display %startup-info)
      (format #t "Enter `,help' for help.\n\n"))
    (when (equal? trace "trace")
      (serialize-header (.state pc) (current-output-port))
      (newline))
    (or (report (list (list pc)) #:trace trace)
        (parameterize ((%next-input (if (or (not (isatty? (current-input-port))) (pair? trail)) trail-input read-input)))
          (let loop ((traces (list (list pc))))
            (%debug "run-trail #traces ~a\n" (length traces))
            (let ((from-pcs (map car traces)))
              (when (interactive?)
                (format (current-error-port) "labels: ~a\n" (string-join (labels)))
                (when deadlock-check?
                  (let* ((pc (car from-pcs))
                         (event-traces-alist (event-traces-alist pc))
                         (eligible (eligible-labels event-traces-alist)))
                    (show-eligible eligible))))
              (let* ((event pc ((%next-input) (car from-pcs)))
                     (traces (map (cute rewrite-trace-head drop-event <>) traces))
                     (list-of-traces (map (cute run-sut <> event) traces))
                     (traces (apply append list-of-traces))
                     (traces (filter-implicit-illegal traces))
                     (traces (filter-compliance-error traces))
                     (error-trace? (find (compose
                                          (conjoin .status
                                                   (negate (is-status? <end-of-trail>))
                                                   (negate (is-status? <match-error>)))
                                          car)
                                         traces))
                     (traces (or (and interface-determinism-check?
                                      (not error-trace?)
                                      (is-a? (%sut) <runtime:port>)
                                      (end-of-trail? traces)
                                      (check-interface-determinism traces))
                                 traces))
                     (valid-traces (filter (compose (negate .status) car) traces))
                     (valid-traces (delete-duplicates valid-traces trace-equal?))
                     (blocked non-blocked
                              (partition (disjoin
                                          (compose blocked-on-boundary? car)
                                          (compose pair? .blocked car))
                                         valid-traces))
                     (collateral non-blocked
                                 (partition (disjoin
                                             (compose blocked-on-boundary? car)
                                             (compose pair? .collateral car))
                                            non-blocked)))
                (cond ((or (null? valid-traces)
                           error-trace?
                           (not event))
                       (end-report from-pcs list-of-traces
                                   #:deadlock-check? deadlock-check?
                                   #:interface-determinism-check?
                                   interface-determinism-check?
                                   #:interface-livelock-check?
                                   interface-livelock-check?
                                   #:queue-full-check? queue-full-check?
                                   #:refusals-check? refusals-check?
                                   #:state? state?
                                   #:trace trace
                                   #:internal? internal?
                                   #:locations? locations?
                                   #:verbose? verbose?))
                      ((and (pair? collateral) (null? blocked))
                       (let ((todo
                              done
                              (split-lists split-collateral-trace collateral)))
                         (or (and (pair? done)
                                  (report done
                                          #:internal? internal?
                                          #:locations? locations?
                                          #:state? state?
                                          #:trace trace
                                          #:verbose? verbose?))
                             (loop todo))))
                      ((pair? blocked)
                       (loop blocked))
                      ((pair? non-blocked)
                       (or (report non-blocked
                                   #:internal? internal?
                                   #:locations? locations?
                                   #:state? state?
                                   #:trace trace
                                   #:verbose? verbose?)
                           (let ((pcs (map car valid-traces)))
                             (loop (map list pcs)))))))))))))


;;;
;;; Repl helpers
;;;

(define %pc (make-parameter #f))
(define %traces (make-parameter (list)))

(define-method (next-step (pc <program-counter>) event)
  (list (begin-step pc event)))

(define-method (next-step (trace <list>) event)
  (let* ((pc (car trace))
         (pc (begin-step pc event)))
    (list pc)))

(define-method (next-step (pc <program-counter>))
  (step pc (.statement pc)))

(define-method (next-step (trace <list>))
  (let* ((pc (car trace))
         (pcs (step pc (.statement pc))))
    (map (cut cons <> trace) pcs)))

(define-method (next event)
  (%traces (append-map (cut next-step <> event) (%traces)))
  (%pc (map car (%traces)))
  (%pc))

(define-method (next)
  (next (%traces)))

(define-method (next (traces <list>))
  (%traces (append-map (cut next-step <>) (%traces)))
  (%pc (map car (%traces)))
  (%pc))

(define (n . rest)
  (if (and (null? rest)
           (or (not (%pc))
               (every rtc? (%pc)))) (format (current-error-port) "labels: ~a\n" (labels))
               (let ((pcs (apply next rest)))
                 (when (pair? pcs)
                   (let ((trail (trace->trail (car pcs))))
                     (when (pair? trail)
                       (format #t "~a\n" (cdr trail)))))
                 pcs)))

(define* (filter-root root #:key model-name)
  (let* ((model (ast:get-model root model-name))
         (models (ast:model* model))
         (root (tree-filter (disjoin (is? <interface>)
                                     (negate (is? <model>))
                                     (cute member <> models ast:eq?)) root)))
    root))


;;;
;;; Entry points
;;;

(define* (repl file-name #:optional model-name)
  "Entry point REPL, try: C-c C-a (repl \"system_hello.dzn\") RET (n \"h.hello\") RET."
  #!
  ;; Start Emacs inside [Guix] environment or set it after
  ;; echo $GUIX_ENVIRONMENT  => <profile>
  M-x guix-set-emacs-environment <profile> RET
  ;; POSSIBLY (See https://lists.gnu.org/archive/html/guix-patches/2020-09/msg00203.html)
  ;; set exec path:
  (setq exec-path (getenv "PATH"))
  (setq geiser-guile-binary "<profile>/bin/guile")

  ;; then
  C-c C-a
  (repl "system_hello.dzn")
  (n "h.hello")
  (n)
  !#
  (let* ((%test-dir (string-append (dirname (getcwd)) "/test"))
         (file-name (search-path
                     (cons "." (find-files (string-append %test-dir "/all") #:directories? #t))
                     file-name))
         (root (file->ast file-name))
         (root (vm:normalize root)))
    (%sut (runtime:get-sut root (ast:get-model root model-name)))
    (%instances (runtime:create-instances (%sut)))
    (%pc (list (make-pc)))
    (%traces (list (%pc)))
    (%next-input read-input)
    (%pc)))

(define* (simulate root
                   #:key compliance-check? deadlock-check?
                   interface-determinism-check? interface-livelock-check?
                   queue-full-check? refusals-check?
                   model-name queue-size strict? trace trail
                   internal? locations? state? verbose?)
  "Entry-point for the command module: dzn simulate: start simulate
session for MODEL, following TRAIL.  If STRICT?, the trail must include
all observable events.  If COMPLIANCE-CHECK?, report compliance errors.
If DEADLOCK-CHECK?, run check-deadlock at EOT.  If QUEUE-FULL-CHECK?,
run external queue-full-check at EOT.  If REFUSALS-CHECK?, run
refusals-check at EOT."
  (let* ((trail? trail)
         (trail (or trail
                    (and (not (isatty? (current-input-port)))
                         (input-port? (current-input-port))
                         (read-string (current-input-port)))
                    ""))
         (trail trail-model (string->trail+model trail))
         (model-name (or model-name trail-model))
         (trail (if (and trail? (null? trail)) '() trail)))
    (when trail?
      (close-port (current-input-port)))
    (simulate* root trail
               #:compliance-check? compliance-check?
               #:deadlock-check? deadlock-check?
               #:interface-determinism-check? interface-determinism-check?
               #:interface-livelock-check? interface-livelock-check?
               #:queue-full-check? queue-full-check?
               #:refusals-check? refusals-check?
               #:model-name model-name
               #:queue-size queue-size
               #:strict? strict?
               #:trace trace
               #:internal? internal?
               #:locations? locations?
               #:state? state?
               #:verbose? verbose?)))

(define* (simulate* root trail
                    #:key compliance-check? deadlock-check?
                    interface-determinism-check? interface-livelock-check?
                    queue-full-check? refusals-check?
                    model-name queue-size strict? trace
                    internal? locations? state? verbose?)
  "Entry point for simulate library: start simulate session for MODEL,
following TRAIL.  If STRICT?, the trail must include all observable
events.  If COMPLIANCE-CHECK?, report compliance errors.  If
DEADLOCK-CHECK?, run check-deadlock at EOT.  If QUEUE-FULL-CHECK?, run
external queue-full-check at EOT.  If REFUSALS-CHECK?, run
refusals-check at EOT."
  (let* ((root (filter-root root #:model-name model-name))
         (root (vm:normalize root)))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print root (current-error-port)))
    (let* ((sut (runtime:get-sut root (ast:get-model root model-name)))
           (instances (runtime:create-instances sut)))
      (parameterize ((%debug? (> (dzn:debugity) 0)))
        (simulate** sut instances trail
                    #:compliance-check? compliance-check?
                    #:deadlock-check? deadlock-check?
                    #:interface-determinism-check? interface-determinism-check?
                    #:interface-livelock-check? interface-livelock-check?
                    #:queue-full-check? queue-full-check?
                    #:refusals-check? refusals-check?
                    #:queue-size queue-size
                    #:strict? strict?
                    #:trace trace
                    #:internal? internal?
                    #:locations? locations?
                    #:state? state?
                    #:verbose? verbose?)))))

(define* (simulate** sut instances trail
                     #:key compliance-check? deadlock-check?
                     interface-determinism-check? interface-livelock-check?
                     queue-full-check? refusals-check?
                     queue-size strict? trace
                     internal? locations? state? verbose?)
  "Entry point for simulate library, much like simulate*.  This
procedure allows reuse with the same root, SUT and INSTANCES, allowing
memoizations to work."
  (parameterize ((%compliance-check? compliance-check?)
                 (%instances instances)
                 (%queue-size (or queue-size 3))
                 (%strict? strict?)
                 (%sut sut))
    (run-trail trail
               #:deadlock-check? deadlock-check?
               #:interface-determinism-check? interface-determinism-check?
               #:interface-livelock-check? interface-livelock-check?
               #:queue-full-check? queue-full-check?
               #:refusals-check? refusals-check?
               #:trace trace
               #:internal? internal?
               #:locations? locations?
               #:state? state?
               #:verbose? verbose?)))
