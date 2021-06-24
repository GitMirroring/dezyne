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
  #:export (repl
            simulate))

;;; Commentary:
;;;
;;; ’simulate’ implements a system simulator using the Dezyne vm.
;;;
;;; Code:

(define (zip trace port-trace)
  "Merge PORT-TRACE into TRACE, and synthesize corresponding actions and
returns to support the split-arrow trace format."
  (define ((action-equal? port-name) a b)
    (let ((b (.statement b)))
      (and (is-a? a <action>) (is-a? b <action>)
           (equal? (.port.name a) port-name)
           (equal? (.event.name a) (.event.name b)))))

  (define ((return-equal? port-name) a b)
    (let ((instance (.instance b))
          (b (.statement b)))
      (and (is-a? a <trigger-return>) (is-a? b <trigger-return>)
           (eq? instance port-name))))

  (let* ((port-on (list-index (compose (is? <on>) .statement) port-trace))
         (trace (append trace (drop port-trace port-on)))
         (port-trace (take port-trace port-on))
         (instance (and=> (find (compose (is? <runtime:component>) .instance) trace)
                          .instance)))

    (let loop ((trace trace) (port-trace port-trace))
      (if (null? trace) '()
          (let* ((pc (car trace))
                 (pc-instance (.instance pc))
                 (statement (.statement pc)))
            (cond ((and (not (is-a? (%sut) <runtime:port>))
                        (is-a? statement <action>)
                        (is-a? pc-instance <runtime:component>)
                        (ast:out? statement))
                   (let* ((port (.port statement))
                          (r:port (if (is-a? pc-instance <runtime:port>) pc-instance
                                      (runtime:port pc-instance port)))
                          (port (.ast r:port))
                          (port-name (.name port))
                          (port-action+trace (member statement port-trace (action-equal? port-name))))
                     (match port-action+trace
                       ((action-pc tail ...)
                        (cons* action-pc pc (loop (cdr trace) tail)))
                       (_
                        (cons pc (loop (cdr trace) port-trace))))))
                  ((and (not (is-a? (%sut) <runtime:port>))
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
                          (cons* return-pc pc (loop (cdr trace) tail))))
                       (_
                        (cons pc (loop (cdr trace) port-trace))))))
                  (else
                   (cons pc (loop (cdr trace) port-trace)))))))))

(define (check-provides-fork port trace)
  "Check TRACE for a fork with respect to PORT.  If TRACE contains
actions to a provides port other than PORT, mark the trace as
<fork-error>, otherwise return false."
  (define (action-other-port pc)
    (let ((statement (.statement pc)))
      (and (is-a? statement <action>)
           (let ((action-port (.port statement)))
             (and action-port
                  (not (ast:eq? action-port port))
                  (ast:provides? action-port))))))
  (let* ((trail (trace->trail trace))
         (action-step (list-index action-other-port trace)))
    (and action-step
         (let* ((trace (drop trace action-step))
                (pc (car trace))
                (pc (clone pc
                           #:previous #f
                           #:status (make <fork-error>
                                      #:ast (.statement pc)
                                      #:message "compliance"))))
           (list (cons pc trace))))))

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
                                         (append-map (cute extend todo <>) continuations))))))
            traces)))))

(define (check-provides-compliance pc event trace)
  "Check TRACE for traces-compliance with the provides ports, for EVENT.
Update the state of the provides port in TRACE for EVENT.  Return a list
of traces, possibly marked with <compliance-error>."
  (let* ((pc (if (and (pair? (.blocked pc)) (pair? trace)) (last trace) pc))
         (component ((compose .type .ast) (%sut)))
         (sut-trail (trace->trail trace))
         (event (match sut-trail
                  (((ast . event) step ...) event)
                  (() event)))
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

        (define (pc->provides-traces r:provides pc)
          (let* ((interface (.type (.ast r:provides)))
                 (modeling-names (modeling-names interface))
                 (provides-lts pc->state-number count
                               (parameterize ((%sut r:provides)
                                              (%exploring? #t))
                                 (pc->rtc-lts pc #:labels (const modeling-names)))))
            (parameterize ((%sut r:provides))
              ((rtc-lts->traces pc->state-number #:prefix-set? #t) provides-lts))))

        (%debug "check-provides-compliance... ~s: ~a\n" port-name event)
        (let* ((interface ((compose .type .ast) port-instance))
               (ipc (clone pc #:previous #f #:trail '() #:status #f #:statement #f))
               (modeling-traces (pc->provides-traces port-instance ipc))
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
                     (foo (%debug "     port trail : ~s\n" port-trail))
                     (foo (%debug "     port trail : ~s\n" (map cdr port-trail)))
                     (port-name ((compose .name .ast) port-instance))
                     (foo (%debug "      sut trail : ~s\n" (map cdr sut-trail)))
                     (events (map (compose last (cut string-split <> #\.) cdr) sut-trail))
                     (foo (%debug "      sut trail : ~s\n" events)))
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
                                  (zip trace (car (append port-traces non-compliances)))))
                       (trace (rewrite-trace-head (cut clone <> #:status status) trace)))
                  (list trace)))
               ((pair? port-traces)
                (let* ((port-pcs (map (compose (cut clone pc #:state <>) .state car) port-traces))
                       (traces (map (lambda (port-pc)
                                      (cons (set-state (car trace) (get-state port-pc port-instance))
                                            (cdr trace)))
                                    port-pcs)))
                  (if (or blocked? (not provides-trigger?)) traces
                      (map zip traces port-traces))))
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
                            (list (zip trace (car non-compliances))))))))))))))

    (if port (or (and (> (length (ast:provides-port* component)) 1)
                      (check-provides-fork port trace))
                 (check-compliance port (list trace)))
        (let* ((ports (ast:provides-port* component)))
          (fold check-compliance (list trace) ports)))))

(define-method (check-provides-compliance* (pc <program-counter>) event traces)
  (cond
   ((null? traces)
    (check-provides-compliance pc event '()))
   (else
    (append-map (cute check-provides-compliance pc event <>) traces))))

(define-method (event-traces-alist (pc <program-counter>))
  (define (event->label-traces pc event)
    (let* ((pc (clone pc #:trail '()))
           (traces (parameterize ((%exploring? #t))
                     (run-to-completion* pc event))))
      (cons event traces)))
  (map (cute event->label-traces pc <>) (labels)))

(define-method (is-not-deadlock? (pc <program-counter>))
  (conjoin (negate .status)
           (lambda (new)
             (or (null? (.blocked pc))
                 (and (pair? (.blocked pc))
                      (or (.released new)
                          (null? (.blocked new))))))))

(define-method (eligible-labels (pc <program-counter>) event-traces-alist)
  (let ((eligible-traces
         (filter (match-lambda
                   ((event)
                    #f)
                   ((event (pcs tails ...) ...)
                    (find (is-not-deadlock? pc) pcs)))
                 event-traces-alist)))
    (map car eligible-traces)))

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
                    (let ((model (.type (.ast (%sut)))))
                      (if (is-a? model <system>) model
                          (.behaviour model))))))
      (if (and error (not (is-a? error <implicit-illegal-error>))) pc
          (clone pc #:status (make <deadlock-error> #:ast ast #:message "deadlock")))))
  (let ((event-traces-alist
         (map (match-lambda
                ((event traces ...)
                 (cons event (filter (negate optional-trace?) traces))))
              event-traces-alist)))
    (cond
     ((and (is-a? (%sut) <runtime:port>)
           (let ((interface (.type (.ast (%sut)))))
             (and (null? (ast:in-event* interface))
                  (list (list (mark-deadlock pc)))))))
     (else
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
                                   (cons event (filter (is-not-deadlock? pc) pcs))))
                                pcs-alist))
              (valid-pcs (append-map cdr valid-pcs-alist)))
         (and (null? valid-pcs)
              (let* ((traces (assoc-ref event-traces-alist event))
                     (traces (if (pair? traces) traces (list (list pc)))))
                (map (cute rewrite-trace-head mark-deadlock <>) traces)))))))))

(define-method (run-state (pc <program-counter>) (state <list>))
  (let ((pc (set-state pc state)))
    (serialize (.state pc) (current-output-port))
    (newline)
    (list (list pc))))

(define-method (run-sut (pc+blocked-trace <list>))
  (let* ((pc (car pc+blocked-trace))
         (event pc ((%next-input) pc)))
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
             (let* ((ast (.ast (%sut)))
                    (model (if (is-a? ast <instance>) (.type ast) ast))
                    (error (make <match-error> #:message "match" #:ast model #:input event)))
               (list (list (clone pc #:status error)))))))
      ((? (const (pair? (.async pc))))
       (flush-async pc))
      (_
       (let* ((pc (clone pc #:status (make <end-of-trail>)))
              (trace (cons pc (cdr pc+blocked-trace))))
         (list trace))))))

(define* (end-report from-pcs list-of-traces #:key deadlock-check?
                     refusals-check? state? trace locations? verbose?)
  "If DEADLOCK-CHECK?, run check-deadlock.  If REFUSALS-CHECK?, run
refusals-check.  Run final REPORT and return exit status."

  (define* (deadlock-report pc traces)
    "Run check-deadlock and report.  Return exit status."
    (let ((event pc ((%next-input) pc)))
      (let* ((event-traces-alist (event-traces-alist pc))
             (eligible (eligible-labels pc event-traces-alist))
             (error-trace? (find
                            (compose (conjoin
                                      .status
                                      (negate (is-status? <compliance-error>))
                                      (negate (is-status? <end-of-trail>)))
                                     car)
                            traces))
             (illegal-trace? (find
                              (compose (disjoin
                                        (is-status? <illegal-error>)
                                        (is-status? <implicit-illegal-error>))
                                       car)
                              traces))
             (deadlock-traces (and (or (not error-trace?)
                                       illegal-trace?)
                                   (check-deadlock pc event-traces-alist event)))
             (status (and deadlock-traces (pair? (.blocked pc))
                          (report traces
                                  #:locations? locations?
                                  #:trace trace
                                  #:verbose? verbose?)))
             (status (cond ((is-a? status <error>)
                            status)
                           (deadlock-traces
                            (report deadlock-traces
                                    #:eligible eligible
                                    #:locations? locations?
                                    #:trace trace
                                    #:verbose? verbose?))
                           (else
                            #f))))
        (and (is-a? status <error>)
             status))))

  (define (refusals-report from-pcs pc traces)
    "Run check-refusals and report.  Return exit status."

    (define (trace->string-trail trace)
      (let ((trail (map cdr (trace->trail trace))))
        (define (strip-sut-prefix o)
          (if (string-prefix? "sut." o) (substring o 4) o))
        (map strip-sut-prefix trail)))

    (define (optional-port-trace? trace)
      (let* ((requires-on (filter (compose (is? <on>) .statement) trace))
             (triggers (map .trigger requires-on)))
        (find ast:optional? triggers)))

    (define ((filter-provides port-name) trail)
      (let ((port-prefix (format #f "~a." port-name)))
        (filter (disjoin (cut equal? <> "<illegal>")
                         (cut string-prefix? port-prefix <>))
                trail)))
    (define (trail->events trail)
      (map (compose last (cut string-split <> #\.)) trail))

    (define ((prepend-port port-name) trail)
      (map (cute string-append port-name "." <>) trail))

    (define blocked?
      (compose pair? .blocked car))

    (define (optional->inevitable trail)
      (match trail
        (("optional" rest ...) (cons "inevitable" rest))
        (_ trail)))

    (define (remove-inevitable trail)
      (filter (negate (cute equal? <> "inevitable")) trail))

    (define (inevitable-trail? trail)
      (match trail
        (("inevitable" rest ...) #t)
        (_ #f)))

    (define (optional-trail? trail)
      (match trail
        (("optional" rest ...) #t)
        (_ #f)))

    (let* ((component (.type (.ast (%sut))))
           (component-lts pc->state-number count
                          (parameterize ((%exploring? #t))
                            (pc->rtc-lts pc
                                         #:trace-done? (conjoin did-provides-out? (negate blocked?)))))
           (component-traces ((rtc-lts->traces pc->state-number) component-lts))
           (component-traces (filter (negate optional-trace?) component-traces)))

      (define (check-refusals provides)

        (define (pc->provides-traces r:provides pc)
          (let ((provides-lts pc->state-number count
                              (parameterize ((%sut r:provides)
                                             (%exploring? #t))
                                (pc->rtc-lts pc))))
            (parameterize ((%sut r:provides))
              ((rtc-lts->traces pc->state-number
                                #:prefix-set? #t
                                #:continue-on-silent? #t)
               provides-lts))))

        (let* ((r:provides (runtime:port (%sut) provides))
               (r:provides (runtime:other-port r:provides))
               (provides-traces (append-map (cute pc->provides-traces r:provides <>) from-pcs))
               (provides-trails (parameterize ((%sut r:provides)
                                               (%modeling? #t))
                                  (map trace->string-trail provides-traces)))
               (provides-trails (filter pair? provides-trails))
               (inevitable-trails? (find inevitable-trail? provides-trails))
               (provides-trails (if inevitable-trails? (map optional->inevitable provides-trails)
                                    (filter (negate optional-trail?) provides-trails)))
               (provides-trails (delete-duplicates provides-trails equal?))
               (triggers (map car provides-trails))
               (unique-triggers (delete-duplicates triggers equal?))
               (non-deterministic-triggers (lset-difference eq? triggers unique-triggers))
               (provides-trails (filter (compose not
                                                 (cute member <> non-deterministic-triggers)
                                                 car)
                                        provides-trails))
               (provides-trails (map remove-inevitable provides-trails))
               (provides-trails (filter pair? provides-trails))
               (port-name (.name provides))
               (component-trails (map trace->string-trail component-traces))
               (component-trails (map (filter-provides port-name) component-trails))
               (component-events (map trail->events component-trails))
               (refusals (lset-difference equal? provides-trails component-events))
               (refusals (map (prepend-port port-name) refusals)))
          (and (pair? refusals) refusals)))

      (define (trace-check-provides-fork trace)
        (let ((trigger (and=> (find .trigger trace) .trigger)))
          (and trigger
               (let ((port (.port trigger)))
                 (and port
                      (ast:provides? port)
                      (check-provides-fork port trace))))))

      (or
       (and (> (length (ast:provides-port* component)) 1)
            (let ((fork (any trace-check-provides-fork component-traces)))
              (and fork
                   (report fork
                           #:locations? locations?
                           #:trace trace
                           #:verbose? verbose?))))

       (let* ((ports (ast:provides-port* component))
              (refusals (any check-refusals ports)))

         (define (mark-refusals pc)
           (clone pc #:status (make <refusals-error>
                                #:ast (.behaviour component)
                                #:message "compliance"
                                #:refusals refusals)))

         (and (pair? refusals)
              (let ((traces (map (cute rewrite-trace-head mark-refusals <>) traces)))
                (report traces
                        #:locations? locations?
                        #:state? state?
                        #:trace trace
                        #:verbose? verbose?)))))))

  (define (eligible traces)
    (match traces
      (((pc rest ...) trace ...)
       (and (is-a? (.status pc) <end-of-trail>)
            (not (.labels (.status pc)))
            (let* ((pc (clone pc #:status #f))
                   (event-traces-alist (event-traces-alist pc)))
              (eligible-labels pc event-traces-alist))))
      (_
       #f)))

  (let* ((traces (apply append list-of-traces))
         (traces (filter-match-error traces))
         (status (any (compose
                       (conjoin .status
                                (negate (is-status? <end-of-trail>)))
                       car)
                      traces))
         (refusals-check? (and refusals-check?
                               (not status)
                               (is-a? (%sut) <runtime:component>))))
    (or (and deadlock-check? (null? traces)
             (any (cute deadlock-report <> '()) from-pcs))
        (and deadlock-check? (pair? traces)
             (any deadlock-report from-pcs list-of-traces))
        (and refusals-check? (null? traces)
             (any (cute refusals-report from-pcs <> '()) from-pcs))
        (and refusals-check? (pair? traces)
             (any (cute refusals-report from-pcs <> <>) from-pcs list-of-traces))
        (report traces
                #:eligible (or (and deadlock-check? (eligible traces)) '())
                #:locations? locations?
                #:state? state?
                #:trace trace
                #:verbose? verbose?))))

(define* (run-trail trail #:key deadlock-check? refusals-check? locations?
                    state? trace verbose?)
  "Run TRAIL on (%SUT) and produce a trace on STDOUT."

  (define (trail-input pc)
    (let ((trail (.trail pc)))
      (if (null? trail) (values #f pc)
          (let* ((event (car trail))
                 (trail (cdr trail)))
            (%debug "  pop trail ~s ~s\n" event trail)
            (values event (clone pc #:trail trail))))))

  (let ((pc (make-pc #:trail trail)))
    (when (equal? trace "trace")
      (serialize-header (.state pc) (current-output-port))
      (newline))
    (or (report (list (list pc)) #:trace trace)
        (parameterize ((%next-input (if (or (not (isatty? (current-input-port))) (pair? trail)) trail-input read-input)))
          (let loop ((traces (list (list pc))))
            (let ((from-pcs (map car traces)))
              (when (interactive?)
                (format (current-error-port) "labels: ~a\n" (string-join (labels)))
                (when deadlock-check?
                  (let* ((pc (car from-pcs))
                         (event-traces-alist (event-traces-alist pc))
                         (eligible (eligible-labels pc event-traces-alist)))
                    (format (current-error-port) "eligible: ~a\n" (string-join eligible)))))
              (let* ((list-of-traces (map run-sut traces))
                     (traces (apply append list-of-traces))
                     (valid-traces (filter (compose (negate .status) car) traces))
                     (blocked non-blocked (partition (compose pair? .blocked car)
                                                     valid-traces)))
                (cond ((null? valid-traces)
                       (end-report from-pcs list-of-traces
                                   #:deadlock-check? deadlock-check?
                                   #:refusals-check? refusals-check?
                                   #:state? state?
                                   #:trace trace
                                   #:locations? locations?
                                   #:verbose? verbose?))
                      ((pair? blocked)
                       (loop blocked))
                      ((pair? non-blocked)
                       (let ((pcs (map car valid-traces)))
                         (or (report non-blocked
                                     #:locations? locations?
                                     #:state? state?
                                     #:trace trace
                                     #:verbose? verbose?)
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
    (%instances (runtime:system* (%sut)))
    (%pc (list (make-pc)))
    (%traces (list (%pc)))
    (%next-input read-input)
    (%pc)))

(define* (simulate* root trail #:key deadlock-check? refusals-check? model-name
                    queue-size strict? trace locations? state? verbose?)
  "Entry point for simulate library: start simulate session for MODEL,
following TRAIL.  When STRICT?, the trail must include all observable
events.  When DEADLOCK-CHECK?, run check-deadlock at the end, when
REFUSALS-CHECK?, run refusals-check at the end."
  (let ((root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print root (current-error-port)))
    (parameterize ((%strict? strict?)
                   (%sut (runtime:get-sut root (ast:get-model root model-name))))
      (parameterize ((%instances (runtime:system* (%sut))))
        (run-trail trail
                   #:deadlock-check? deadlock-check?
                   #:refusals-check? refusals-check?
                   #:locations? locations?
                   #:trace trace
                   #:state? state?
                   #:verbose? verbose?)))))

(define* (simulate root #:key deadlock-check? refusals-check? model-name
                   queue-size strict? trace trail locations? state? verbose?)
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
         (trail (if (and trail? (null? trail)) '(#f) trail)))
    (simulate* root trail
               #:deadlock-check? deadlock-check?
               #:refusals-check? refusals-check?
               #:model-name model-name
               #:queue-size queue-size
               #:strict? strict?
               #:trace trace
               #:locations? locations?
               #:state? state?
               #:verbose? verbose?)))
