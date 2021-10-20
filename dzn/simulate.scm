;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn display)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn shell-util)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm normalize)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
  #:use-module (dzn vm step)
  #:use-module (dzn vm util)
  #:use-module (dzn explore)
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

  (let* ((trigger (and=> trigger trigger->component-trigger))
         (port-on-index (or (list-index (compose (is? <on>) .statement)
                                        port-trace)
                            0))
         (port-trace-suffix
          port-trace-prefix (split-at port-trace port-on-index))
         (port-trace-prefix (rewrite-trace-head
                             (cut clone <> #:status #f #:statement #f)
                             port-trace-prefix))
         (port-start (car port-trace-prefix))
         (instance (and=> (find .instance trace) .instance))
         (trace-index (- (length trace)
                         (or (list-index
                              (conjoin
                               (compose (cute ast:equal? <> trigger) .trigger)
                               (compose (cute eq? <> instance) .instance))
                              (reverse trace))
                             0)))
         (trace-suffix trace-prefix (split-at trace trace-index))
         (trace (if (find (cute port-pc-equal? <> port-start) trace) trace
                    (append trace-suffix port-trace-prefix trace-prefix)))
         (instance (and=> (find (compose (is? <runtime:component>) .instance)
                                (reverse trace))
                          .instance))
         (full-trace trace))

    (let loop ((trace trace) (port-trace port-trace))
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
                       (cons pc (loop (cdr trace) port-trace))
                       (cons* action-pc pc (loop (cdr trace) tail))))
                  (_
                   (cons pc (loop (cdr trace) port-trace))))))
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
                     (if (find (cute ast:equal? <> return-pc) full-trace)
                         (cons pc (loop (cdr trace) port-trace))
                         (cons* return-pc pc (loop (cdr trace) tail)))))
                  (_
                   (cons pc (loop (cdr trace) port-trace))))))
             (else
              (cons pc (loop (cdr trace) port-trace)))))))))

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
  (let ((action-step (list-index (cute action-other-provides-port? port <>)
                                 trace)))
    (and action-step
         (let* ((trace (drop trace action-step))
                (pc (car trace))
                (pc (clone pc
                           #:previous #f
                           #:status (make <fork-error>
                                      #:ast (.statement pc)
                                      #:message "compliance"))))
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
                                             #:message "compliance"))))
                  (list (cons pc trace))))))))

(define (rtc-lts-node->traces lts from)
  "Return traces for FROM node of LTS."
  (match (hash-ref lts from)
    ((pc traces ...)
     traces)
    (#f
     '())))

(define* ((rtc-lts->traces pc->state-number #:key prefix-set? continue-on-silent?) lts)
  "Create a (prefix) set of traces from LTS.  When CONTINUE-ON-SILENT?,
never extend a trace, but do continue as long as the trail is silent."

  (define (extend todo trace)
    (map (cute append trace <>) todo))

  (define observable?
    (compose pair? trace->string-trail))

  (let loop ((seen '()) (tos '(1)))
    (if (null? tos) '()
        (let* ((traces (append-map (cute rtc-lts-node->traces lts <>) tos))
               (seen (append seen tos))
               ;;done = seen or observable? when continue-on-silent?
               ;;todo = not seen and not observable?
               (done todo (partition
                           (disjoin
                            (compose (cute member <> seen) pc->state-number car)
                            (if (not continue-on-silent?) (const #f)
                                observable?))
                           traces))
               (tos (map (compose pc->state-number car) todo))
               (tos (delete-duplicates tos =)))
          (let* ((continuations (loop seen tos))
                 (traces (append (if prefix-set? traces done)
                                 (if (null? continuations) todo
                                     (if continue-on-silent? continuations
                                         (append-map (cute extend todo <>) continuations)))))
                 (traces (delete-duplicates
                          traces
                          (lambda (a b)
                            (and (rtc-program-counter-equal? (car a) (car b))
                                 (equal? (trace->string-trail a)
                                         (trace->string-trail b)))))))
            traces)))))

(define* (check-provides-compliance pc event port-traces-alist trace)
  "Check TRACE for traces-compliance with the provides ports, for EVENT.
Update the state of the provides port in TRACE for EVENT.  Return a list
of traces, possibly marked with <compliance-error>."
  (let* ((pc (if (and (external-trigger? event)
                      (pair? (.blocked pc)) (pair? trace))
                 (last trace)
                 pc))
         (component ((compose .type .ast) (%sut)))
         (sut-trail (trace->trail trace))
         (event (cond
                 ((and (pair? (.blocked pc))
                       (requires-trigger? event)
                       (let* ((return (find (compose (is? <trigger-return>)
                                                     .statement)
                                            trace))
                              (instance (and=> return .instance)))
                         (find
                          (conjoin
                           (compose (cute eq? <> instance) .instance)
                           (compose (is? <initial-compound>) .statement)
                           (compose ast:provides? .trigger))
                          trace)))
                  =>
                  (lambda (pc)
                    (let ((trail (trace->trail pc)))
                      (match trail
                        ((ast . event) event)
                        (_ event)))))
                 (else
                  (match sut-trail
                    (((ast . event) step ...) event)
                    (() event)))))
         (trigger (and event (clone (string->trigger event) #:parent component)))
         (provides-trigger? (provides-trigger? event))
         (port-event (and provides-trigger? (.event.name trigger)))
         (port (and provides-trigger? (.port trigger))))

    (define (check-compliance port traces)
      (let* ((trace (car traces))
             (port-name (.name port))
             (port-instance (runtime:port-name->instance port-name)))

        (define (port-event? e)
          (and (string? e)
               (match (string-split e #\.)
                 (('state state) #f)
                 ((port event) (and (equal? port port-name) event))
                 (_ #f))))

        (define (run-provides-port trace event)
          (%debug "run-provides-port... ~a\n" event)
          (parameterize ((%sut port-instance)
                         (%exploring? #t))
            (run-to-completion trace event)))

        (%debug "check-provides-compliance... ~s: ~a\n" port-name event)
        (let* ((interface ((compose .type .ast) port-instance))
               (ipc (clone pc #:previous #f #:trail '() #:status #f #:statement #f))
               (ipc (set-reply pc port-instance #f))
               (modeling-traces (assoc-ref port-traces-alist port-instance))
               (traces (cons (list ipc) modeling-traces))
               ;; provides trace
               (port-traces (if (not port-event) '()
                                (append-map (cut run-provides-port <> port-event)
                                            traces)))
               (port-traces (append port-traces modeling-traces)))

          (when (> (dzn:debugity) 0)
            (%debug "port-traces[~s]:\n" (length port-traces))
            (parameterize ((%sut port-instance))
              (display-trails port-traces)))

          (let* ((port-prefix (format #f "~a." port-name))
                 (sut-trail (filter (compose (disjoin (cut equal? <> "illegal")
                                                      (cut string-prefix? port-prefix <>))
                                             cdr)
                                    sut-trail))
                 (blocked? (and (pair? trace) (pair? (.blocked (car trace))))))

            (define (port-trace->trail trace)
              (parameterize ((%sut port-instance)) (trace->trail trace)))

            (define (first-non-match port-trace)
              (define (non-matching-pair? a b)
                (and (not (equal? (cdr a) ((compose last (cut string-split <> #\.) cdr) b))) (cons a b)))

              (let* ((port-trail (port-trace->trail port-trace))
                     (port-trail (if (not blocked?) port-trail
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

            (let ((port-traces non-compliances
                               (partition (negate first-non-match) port-traces)))
              (cond
               ((and (pair? trace)
                     (.status (car trace))
                     (not (is-a? (.status (car trace)) <match-error>))
                     (pair? (append port-traces non-compliances)))
                (let* ((pc (car trace))
                       (status (.status pc))
                       (trace (rewrite-trace-head (cut clone <> #:status #f #:statement #f) trace))
                       (trace (if (not provides-trigger?) trace
                                  (zip trigger trace (car (append port-traces non-compliances)))))
                       (trace (rewrite-trace-head (cut clone <> #:status status) trace)))
                  (list trace)))
               ((pair? port-traces)
                (let* ((port-pcs (map (compose (cut clone pc #:state <>) .state car) port-traces))
                       (traces (map (lambda (port-pc)
                                      (cons (set-state (car trace) (get-state port-pc port-instance))
                                            (cdr trace)))
                                    port-pcs)))
                  (if (not provides-trigger?) traces
                      (map (cute zip trigger <> <>) traces port-traces))))
               ((and (null? non-compliances)
                     (null? port-traces)
                     (pair? sut-trail))
                (let ((status (make <compliance-error>
                                #:message "compliance"
                                #:component-acceptance (caar sut-trail)
                                #:port port-instance)))
                  (list (rewrite-trace-head (cut clone <> #:status status) trace))))
               ((null? non-compliances)
                (if (null? trace) '()
                    (list trace)))
               ((and (not port-event)
                     (null? sut-trail)
                     (pair? trace))
                (list trace))
               (else
                (let* ((port-acceptances (map first-non-match non-compliances))
                       (port-acceptances (delete-duplicates port-acceptances port-acceptance-equal?))
                       (component-acceptance (and (pair? trace)
                                                  (or (cadar port-acceptances)
                                                      (and=> (.status pc) .ast)
                                                      (trigger->component-trigger trigger))))
                       (port-acceptances (make <acceptances> #:elements (map caar port-acceptances)))
                       (trigger (and (null? sut-trail)
                                     (not (any (cute event-on-trail? (.event.name trigger) <>)
                                               non-compliances))
                                     trigger))
                       (pc (clone pc
                                  #:previous #f
                                  #:status (make <compliance-error>
                                             #:message "compliance"
                                             #:component-acceptance component-acceptance
                                             #:port port-instance
                                             #:port-acceptance port-acceptances
                                             #:trigger trigger))))
                  (if (null? trace) (list (cons pc (car non-compliances)))
                      (let* ((tail (cdr trace))
                             (trace (cons pc tail)))
                        (if (not provides-trigger?) (list trace)
                            (list (zip trigger trace (car non-compliances))))))))))))))

    (if port (or (and (> (length (ast:provides-port* component)) 1)
                      (check-provides-fork port trace))
                 (check-compliance port (list trace)))
        (let ((ports (ast:provides-port* component)))
          (or (and (> (length ports) 1)
                   (check-requires-provides-fork trace))
              (fold check-compliance (list trace) ports))))))

(define (pc->provides-traces r:provides pc)
  (let* ((interface (.type (.ast r:provides)))
         (pc (clone pc #:async '() #:external-q '()))
         (modeling-names (modeling-names interface))
         (provides-lts pc->state-number count
                       (parameterize ((%sut r:provides)
                                      (%exploring? #t))
                         (pc->rtc-lts pc #:labels (const modeling-names)))))
    (parameterize ((%sut r:provides))
      ((rtc-lts->traces pc->state-number #:prefix-set? #t) provides-lts))))

(define (provides-instance-traces-alist pc)
  (let* ((component ((compose .type .ast) (%sut)))
         (ports (ast:provides-port* component))
         (r:ports (map (compose runtime:port-name->instance .name) ports))
         (port-traces-list (map (cute pc->provides-traces <> pc) r:ports)))
    (map cons r:ports port-traces-list)))

;;TODO split check from determine provides trace(s) from pc and event
;;to avoid doing the determination work for every trace in traces
(define-method (check-provides-compliance* (pc <program-counter>) event traces)
  (let ((port-traces-alist (provides-instance-traces-alist pc)))
    (cond
     ((null? traces)
      (check-provides-compliance pc event port-traces-alist '()))
     (else
      (append-map (cute check-provides-compliance pc event port-traces-alist <>) traces)))))

(define-method (event-traces-alist (pc <program-counter>))

  (define (event-traces-alist pc)
    (define (event->label-traces pc event)
      (let* ((pc (clone pc #:trail '()))
             (pc (reset-replies pc))
             (traces (parameterize ((%exploring? #t)
                                    (%liveness? #t))
                       (run-to-completion* pc event))))
        (cons event traces)))
    (define (async-trace->alist trace)
      (match (trace->string-trail trace)
        ((event rest ...)
         (cons event (list trace)))))
    (let* ((alist (map (cute event->label-traces pc <>) (labels)))
           (traces (append-map cdr alist))
           (async-traces (flush-async pc))
           (async-alist (map async-trace->alist async-traces)))
      (merge-alist2 alist async-alist)))

  (define (provides-event->label-traces pc event)
    (let* ((pc (clone pc #:trail '()))
           (pc (reset-replies pc))
           (traces (parameterize ((%exploring? #t)
                                  (%liveness? #t))
                     (run-to-completion* pc event))))
      (cons event traces)))

  (define (requires-event->label-traces pc event)
    (let* ((pc (clone pc #:trail '()))
           (pc (reset-replies pc))
           (traces (parameterize ((%exploring? #t)
                                  (%liveness? #t))
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
    (let ((boundary (filter runtime:boundary-port? (%instances))))
      (append-map (cute port->label-traces pc <>) boundary)))

  (if (is-a? (%sut) <runtime:system>) (system-event-traces-alist pc)
      (event-traces-alist pc)))

(define-method (event-traces-alist (pcs <list>))
  (let ((pcs (map (cute clone <> #:status #f) pcs)))
    (merge-alist-list
     (map event-traces-alist pcs))))

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
                      (if (is-a? model <system>) model
                          (.behaviour model))))))
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
            (valid-pcs-alist (map
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
                   (traces (map (cute rewrite-trace-head mark-deadlock <>) traces)))
              (if (is-a? (%sut) <runtime:port>) traces
                  (append-map (cute check-provides-compliance pc #f
                                    (provides-instance-traces-alist pc) <>)
                              traces))))))))

(define (check-interface-determinism pcs)
  "Run labels for PCS and return traces that are unobservably
nonterministic, or false."
  (define (optional->inevitable trail)
    (match trail
      (("optional" trail ...) `("inevitable" ,@trail))
      (_ trail)))
  (define trail-traces-alist
    (match-lambda ((event traces ...)
                   (let* ((trails (parameterize ((%modeling? #t))
                                    (map trace->string-trail traces)))
                          (trails (map optional->inevitable trails)))
                     (map cons trails (map list traces))))))
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
                              (.behaviour (runtime:%sut-model)))
                    #:message "determinism"))
           (pc (clone pc #:status error)))
      (cons pc trace)))
  (define extend-silent-traces
    (match-lambda
      (((and ("inevitable") trail) traces ...)
       (cons trail (append traces (map list pcs))))
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
  (and (pair? (ast:variable* (.behaviour (runtime:%sut-model))))
       (let* ((event-alist (event-traces-alist pcs))
              (trail-alists (map trail-traces-alist event-alist))
              (trail-alist (merge-alist-list (append trail-alists '(()))))
              (trail-alist (map extend-silent-traces trail-alist))
              (traces (append-map check-determisistic trail-alist)))
         (and (pair? traces) traces))))

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
                              (.behaviour (runtime:%sut-model)))
                    #:message "determinism"))
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
           (pcs (map (cute clone <> #:status #f) pcs))
           (silent-traces (append-map (cute run-silent <> (%sut)) pcs))
           (traces (append traces silent-traces))
           (alist (cons '() traces))
           (traces (check-determisistic alist)))
      (and (pair? traces) traces)))
  (and (pair? (ast:variable* (.behaviour (runtime:%sut-model))))
       (or (check-traces traces)
           (check-silence traces))))

(define-method (run-state (pc <program-counter>) (state <list>))
  (let ((pc (set-state pc state)))
    (serialize (.state pc) (current-output-port))
    (newline)
    (list (list pc))))

(define-method (run-sut (pc+blocked-trace <list>) event)
  (let* ((pc (car pc+blocked-trace))
         (pc (reset-replies pc)))
    (%debug "run-sut pc: ~s\n" pc)
    (%debug "     event: ~s\n" event)
    (match event
      (('state state ...)
       (run-state pc state))
      ((? string?)
       (let* ((pc (clone pc #:instance #f))
              (traces (run-to-completion* pc event))
              (traces (map (cute append <> pc+blocked-trace) traces))
              (traces (if (is-a? (%sut) <runtime:port>) traces
                          (check-provides-compliance* pc event traces))))
         (if (pair? traces) traces
             (let* ((model (runtime:%sut-model))
                    (error (make <match-error> #:message "match" #:ast model #:input event)))
               (list (list (clone pc #:status error)))))))
      ((? (const (pair? (.async pc))))
       (let ((traces (flush-async pc)))
         (check-provides-compliance* pc #f traces)))
      (_
       (let* ((pc (clone pc #:status (make <end-of-trail>)))
              (trace (cons pc (cdr pc+blocked-trace))))
         (if (is-a? (%sut) <runtime:port>) (list trace)
             (let* ((port-traces-alist (provides-instance-traces-alist pc))
                    (traces (check-provides-compliance pc event port-traces-alist trace)))
               traces)))))))

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
    (when %debug?
      (parameterize ((%modeling? #t))
        ((@ (ice-9 pretty-print) pretty-print)
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
        (((or "inevitable" "optional") observable event ...)
         observable)
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
                     interface-determinism-check? refusals-check?
                     state? trace internal? locations? verbose?)
  "If DEADLOCK-CHECK?, run check-deadlock.  If REFUSALS-CHECK?, run
refusals-check.  Run final REPORT and return exit status."

  (define (deadlock-report pcs traces)
    "Run check-deadlock and report.  Return exit status."
    (let* ((pc (car pcs))
           (event pc ((%next-input) pc))
           (event-traces-alist (event-traces-alist pcs))
           (eligible (eligible-labels event-traces-alist))
           (deadlock-traces (check-deadlock pc event-traces-alist event))
           (status (and deadlock-traces (pair? (.blocked pc))
                        (report traces
                                #:internal? internal?
                                #:locations? locations?
                                #:trace trace
                                #:verbose? verbose?)))
           (status (cond ((is-a? status <error>)
                          status)
                         (deadlock-traces
                          (report deadlock-traces
                                  #:eligible eligible
                                  #:internal? internal?
                                  #:locations? locations?
                                  #:trace trace
                                  #:verbose? verbose?))
                         (else
                          #f))))
      (and (is-a? status <error>)
           status)))

  (define (interface-deadlock-report pcs traces)
    "Run deadlock check for all PCs per state."
    (let ((pcs (if (pair? traces) (map car traces) pcs)))
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

    (define (trace-check-provides-fork trace)
      (let ((trigger (and=> (find .trigger trace) .trigger)))
        (and trigger
             (let ((port (.port trigger)))
               (and port
                    (ast:provides? port)
                    (check-provides-fork port trace))))))

    (define (component-check-provides-fork component)
      (let* ((component-lts pc->state-number count
                            (parameterize ((%exploring? #t))
                              (pc->rtc-lts pc
                                           #:trace-done? (conjoin did-provides-out? (negate blocked?)))))
             (component-traces ((rtc-lts->traces pc->state-number) component-lts))
             (component-traces (filter (negate optional-trace?) component-traces)))
        (any trace-check-provides-fork component-traces)))

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
             (refusals (map (cute string-append port-name "." <>) refusals))
             (refusals (map list refusals)))
        (and (pair? refusals) refusals)))

    (define blocked?
      (compose pair? .blocked car))

    (let ((component (runtime:%sut-model)))
      (or
       ;; Forking from one to another provides port is a compliance
       ;; error.
       (and (> (length (ast:provides-port* component)) 1)
            (let ((fork (component-check-provides-fork component)))
              (and fork
                   (report fork
                           #:eligible '()
                           #:internal? internal?
                           #:locations? locations?
                           #:trace trace
                           #:verbose? verbose?))))

       ;; In the failures model, refusals can only occur when the
       ;; component LTS is stable.  When the component LTS is not
       ;; stable, that means outgoing tau events: no refusals.  A
       ;; component LTS is stable when all requires port LTSs are
       ;; stable.  When the a provides port's modeling-LTS in not
       ;; stable, the refusals set consists of all its observable
       ;; events.
       (and (= (length from-pcs) 1)
            (null? (.external-q (car from-pcs)))
            (requires-ports-stable? component pc)
            (let* ((ports (ast:provides-port* component))
                   (instable (find (negate (port-lts-stable? pc)) ports))
                   (pc (car from-pcs))
                   (refusals (and instable (port-refusals pc instable))))

              (define (mark-refusals pc)
                (clone pc #:status (make <refusals-error>
                                     #:ast (.behaviour component)
                                     #:message "compliance"
                                     #:refusals refusals)))

              (and (pair? refusals)
                   (let ((traces (map (cute rewrite-trace-head mark-refusals <>) traces)))
                     (report traces
                             #:eligible '()
                             #:internal? internal?
                             #:locations? locations?
                             #:state? state?
                             #:trace trace
                             #:verbose? verbose?))))))))

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
         (refusals-check? (and refusals-check?
                               (not status)
                               (is-a? (%sut) <runtime:component>))))
    (or (and deadlock-check?
             (is-a? (%sut) <runtime:port>)
             (interface-deadlock-report from-pcs traces))
        (and deadlock-check?
             (not (is-a? (%sut) <runtime:port>))
             (deadlock-report from-pcs traces))
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
        (and refusals-check? (null? traces)
             (any (cute refusals-report from-pcs <> '()) from-pcs))
        (and refusals-check? (pair? traces)
             (any (cute refusals-report from-pcs <> <>) from-pcs list-of-traces))
        (let ((eligible
               (and deadlock-check?
                    (eligible-labels (event-traces-alist pcs)))))
          (report traces
                  #:eligible (or eligible '())
                  #:internal? internal?
                  #:locations? locations?
                  #:state? state?
                  #:trace trace
                  #:verbose? verbose?)))))

(define* (run-trail trail #:key deadlock-check? interface-determinism-check?
                    refusals-check? internal?
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

  (let* ((trail (if (and (null? trail)
                         (not (isatty? (current-input-port))))
                    '(#f) trail))
         (pc (make-pc #:trail trail)))
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
                     (blocked non-blocked (partition (compose pair? .blocked car)
                                                     valid-traces)))
                (cond ((or (null? valid-traces)
                           error-trace?)
                       (end-report from-pcs list-of-traces
                                   #:deadlock-check? deadlock-check?
                                   #:interface-determinism-check?
                                   interface-determinism-check?
                                   #:refusals-check? refusals-check?
                                   #:state? state?
                                   #:trace trace
                                   #:internal? internal?
                                   #:locations? locations?
                                   #:verbose? verbose?))
                      ((pair? blocked)
                       (loop blocked))
                      ((pair? non-blocked)
                       (or (report non-blocked
                                   #:internal? internal?
                                   #:locations? locations?
                                   #:state? state?
                                   #:trace trace
                                   #:verbose? verbose?)
                           (let* ((pcs (map car valid-traces))
                                  (pcs (delete-duplicates pcs rtc-program-counter-equal?)))
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

(define* (simulate root #:key deadlock-check? interface-determinism-check?
                   refusals-check? model-name
                   queue-size strict? trace trail internal? locations? state?
                   verbose?)
  "Entry-point for the command module: dzn simulate: start simulate
session for MODEL, following TRAIL.  When STRICT?, the trail must
include all observable events.  When DEADLOCK-CHECK?, run check-deadlock
at the end.  When REFUSALS-CHECK?, run refusals-check at the end."
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
               #:deadlock-check? deadlock-check?
               #:interface-determinism-check? interface-determinism-check?
               #:refusals-check? refusals-check?
               #:model-name model-name
               #:queue-size queue-size
               #:strict? strict?
               #:trace trace
               #:internal? internal?
               #:locations? locations?
               #:state? state?
               #:verbose? verbose?)))

(define* (simulate* root trail #:key deadlock-check?
                    interface-determinism-check? refusals-check? model-name
                    queue-size strict? trace internal? locations? state?
                    verbose?)
  "Entry point for simulate library: start simulate session for MODEL,
following TRAIL.  When STRICT?, the trail must include all observable
events.  When DEADLOCK-CHECK?, run check-deadlock at the end, when
REFUSALS-CHECK?, run refusals-check at the end."
  (let* ((root (filter-root root #:model-name model-name))
         (root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print root (current-error-port)))
    (let* ((sut (runtime:get-sut root (ast:get-model root model-name)))
           (instances (runtime:create-instances sut)))
      (simulate** sut instances trail
                  #:deadlock-check? deadlock-check?
                  #:interface-determinism-check? interface-determinism-check?
                  #:refusals-check? refusals-check?
                  #:queue-size queue-size
                  #:strict? strict?
                  #:trace trace
                  #:internal? internal?
                  #:locations? locations?
                  #:state? state?
                  #:verbose? verbose?))))

(define* (simulate** sut instances trail #:key deadlock-check?
                     interface-determinism-check? refusals-check?
                     queue-size strict? trace internal? locations? state?
                     verbose?)
  "Entry point for simulate library, much like simulate*.  This
procedure allows reuse with the same root, SUT and INSTANCES, allowing
memoizations to work."
  (parameterize ((%instances instances)
                 (%queue-size (or queue-size 3))
                 (%strict? strict?)
                 (%sut sut))
    (run-trail trail
               #:deadlock-check? deadlock-check?
               #:interface-determinism-check? interface-determinism-check?
               #:refusals-check? refusals-check?
               #:trace trace
               #:internal? internal?
               #:locations? locations?
               #:state? state?
               #:verbose? verbose?)))
