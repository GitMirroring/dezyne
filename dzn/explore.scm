;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn explore)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (json)

  #:use-module (dzn ast display)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn code makreel)
  #:use-module (dzn misc)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm compliance)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm normalize)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm step)
  #:use-module (dzn vm util)

  #:export (lts
            pc->rtc-lts
            pc->state-number
            state-diagram))

;;; Commentary:
;;;
;;; ’explore’ implements a state diagram.
;;;
;;; Code:

(define-method (process-external (pc <program-counter>))
  (let ((queues (.external-q pc)))
    (if (null? queues) '()
        (let ((instances (map car queues)))
          (append-map (cute run-external-q pc <>) instances)))))

(define (run-to-completion** pc event)
  (let* ((pc (clone pc #:instance #f #:trail '()))
         (pc (reset-replies pc)))
    (cond
     ((eq? event 'defer)
      (if (null? (.defer pc)) '()
          (run-defer-event pc event)))
     ((eq? event 'external)
      (process-external pc))
     ((is-a? (%sut) <runtime:port>)
      (run-to-completion pc event))
     ((requires-trigger? event)
      (let* ((traces (run-requires pc event))
             (port (.port (string->trigger event)))
             (blocked-port (and=> (blocked-on-boundary? pc) .ast)))
        (if (and port (ast:eq? port blocked-port)) '()
            traces)))
     ((provides-trigger? event)
      (if (blocked-on-boundary-provides? pc event) '()
          (run-to-completion pc event)))
     (else
      '()))))

;; table is initially (<"<illegal>") . 0>)
(define* ((pc->state-number table count) pc #:optional trail)
  (let* ((pc-string (pc->string pc))
         (pc-string (if trail (string-append pc-string " t:" trail) pc-string))
         (next (hash-ref table pc-string)))
    (if next next
        (let ((n (car count)))
          (hash-set! table pc-string n)
          (set-car! count (1+ (car count)))
          n))))

(define* (pc->rtc-lts pc #:key (trace-done? (const #f)) (labels labels))
  "Explore the state space of (%SUT).  Start by running all (labels) on
PC, and recurse until no new, valid PCs are found.  A PC with STATUS set
ends the recursion, and a PC for which TRACE-DONE? holds, ends the
recursion.  Return a run-to-completion LTS

   ((pc-hash . (pc . traces))
    ...)

  as a hash table, as multiple values

  (LTS PC->STATE-NUMBER AND STATE-NUMBER-COUNT)
"
  (define (collateral? pc previous-pc)
    "Return #true if the only difference between PC and PREVIOUS-PC is
that PC has one more collaterally blocked coroutine on the same port."
    (define (drop-collateral pc)
      (match (.collateral pc)
        (((port . p) t ...)
         (clone pc
                #:collateral t
                #:previous (and=> (.previous pc) drop-collateral)))
        (_
         pc)))
    (match (.collateral pc)
      (((port . pc0) t ...)
       (and (find (compose (cute eq? <> (.instance pc0)) .instance cdr) t)
            (let ((pc (drop-collateral pc)))
              (pc-equal? pc previous-pc))))
      (_
       #f)))

  (let* ((lts (make-hash-table))
         (state-number-table (make-hash-table))
         (state-number-count (list 1))
         (pc->state-number (pc->state-number state-number-table
                                             state-number-count)))

    (define (blocked-prefix pc)
      (let* ((blocking-pc (rtc-block-pc (cdar (.blocked pc))))
             (blocking-pc (.previous blocking-pc))
             (blocked-from (and=> blocking-pc pc->state-number))
             (pc+traces (hash-ref lts blocked-from)))
        (match pc+traces
          ((pc . traces)
           (or (find (compose pair? .blocked car) traces)
               '()))
          (_
           '()))))

    (define (check-compliance-blocked trace)
      (let ((orig-pc (last trace)))
        (let* ((blocked-prefix (blocked-prefix orig-pc))
               (q-trigger (and (null? blocked-prefix)
                               (and=>
                                (as (.q (get-state orig-pc (%sut))) <pair>)
                                car)))
               (full-trace (append trace blocked-prefix))
               (orig-pc (last full-trace))
               (trigger (or
                         q-trigger
                         (any
                          (conjoin
                           (compose (is? <runtime:component>) .instance)
                           .trigger)
                          (reverse full-trace))))
               (label (and trigger (trigger->string trigger)))
               (checked (if (not label) '()
                            (check-provides-compliance orig-pc label
                                                       full-trace)))
               (illegal? (is-status? <implicit-illegal-error>))
               (checked (filter (compose not illegal? car) checked))
               (pcs (map car checked))
               (corrected (if (not (= 1 (length pcs))) trace
                              (cons (car pcs) trace))))
          corrected)))

    (define (run-label orig-pc label)
      (%debug "run-label ~a\n" label)
      (let* ((orig-pc (clone orig-pc #:collateral-instance #f))
             (defer? (eq? label 'defer))
             (sw-pc (if defer? orig-pc
                        (switch-context orig-pc)))
             (bob-pc (if defer? orig-pc
                         (blocked-on-boundary-switch-context orig-pc)))
             (traces (cond
                      ((and (eq? orig-pc sw-pc)
                            (eq? orig-pc bob-pc))
                       (run-to-completion** orig-pc label))
                      ((and (not (eq? orig-pc sw-pc))
                            (not (provides-trigger? label)))
                       (run-to-completion sw-pc 'rtc))
                      (else
                       (let* ((traces (run-to-completion bob-pc 'rtc))
                              (flush traces
                                     (partition (compose .running-defer? car)
                                                traces))
                              (traces (append traces
                                              (append-map run-flush flush))))
                         (append traces
                                 (run-to-completion** orig-pc label))))))
             (blocked? (not (eq? bob-pc orig-pc)))
             (skip-compliance? (or (.skip-compliance? orig-pc)
                                   (is-a? (%sut) <runtime:port>)
                                   (null? traces)))
             (traces (map (cute append <> (list orig-pc)) traces))
             (traces (cond
                      ((and (not skip-compliance?) (not blocked?))
                       (let* ((cpc orig-pc)
                              (cpc (reset-replies cpc))
                              (cpc (clone cpc #:instance #f)))
                         (check-provides-compliance* cpc label traces)))
                      ((and blocked?
                            (not (.skip-compliance? orig-pc))
                            (not (eq? label 'defer))
                            (not (or (.status pc)
                                     (is-a? (%sut) <runtime:port>)
                                     (is-a? (%sut) <runtime:system>))))
                       (map check-compliance-blocked traces))
                      (else
                       traces)))
             (traces (if (eq? label 'external) traces
                         (filter-implicit-illegal-only traces)))
             (traces (filter (compose not (is-status? <blocked-error>) car)
                             traces))
             (traces (filter (compose not (cute collateral? <> pc) car) traces)))
        (map (cute rewrite-trace-head prune-defer <>) traces)))

    (define (run-labels pc labels)
      (%debug "run-labels ~a\n" labels)
      (let loop ((labels labels) (traces '()))
        (if (null? labels) traces
            (let* ((label (car labels))
                   (new (run-label pc label)))
              (cond
               ((find (compose (is-status? <livelock-error>) car) new)
                (format (current-error-port) "warning: livelock, bailing out\n")
                '())
               (else
                (loop (cdr labels) (append new traces))))))))

    (hash-set! state-number-table "<illegal>" 0)
    (let loop ((pc pc))
      (let ((from (pc->state-number pc)))
        (%debug "loop ~a~a\n" from (if (hash-ref lts from) ": seen!" ""))
        (unless (or (.status pc) (hash-ref lts from))
          (let* ((labels (labels pc))
                 (labels (if (is-a? (%sut) <runtime:port>) labels
                             (cons* 'defer 'external labels)))
                 (traces (run-labels pc labels)))
            (when (or (is-a? (%sut) <runtime:port>)
                      (any pair? traces))
              (hash-set! lts from (cons pc traces))
              (let* ((traces (filter (negate trace-done?) traces))
                     (pcs (map car traces)))
                (for-each loop pcs)))))))

    (when (.status pc) ;; range-member
      (let ((pc0 (clone pc #:status #f)))
        (hash-set! lts 1 (cons pc0 (list (list pc0 pc))))))

    (values lts pc->state-number state-number-count)))


;;;
;;; State diagram
;;;
(define (rtc-lts->state-diagram lts pc->state-number)
  "Create a state-diagram from run-to-completion LTS, return

   ((from from-label transition to trigger-location)
    ...)
"
  (define (on-location trace)
    (let ((pc (find (conjoin (compose (is? <on>) .statement)
                             (disjoin (const (is-a? (%sut) <runtime:port>))
                                      (compose (is? <runtime:component>) .instance)))
                    (reverse trace))))
      (and pc (and=> (.statement pc) ast:location))))

  (define (trace->string-trail trace)
    (let ((trail (map cdr (trace->trail trace))))
      (define (strip-sut-prefix o)
        (if (string-prefix? "sut." o) (substring o 4) o))
      (map strip-sut-prefix trail)))

  (define (transition->dot pc->state-number from pc+traces)
    (let* ((pc traces (match pc+traces ((pc . traces) (values pc traces))))
           (traces (filter (compose not .status car) traces))
           (pcs (map car traces))
           (transition (map trace->string-trail traces))
           (to (map pc->state-number pcs))
           (to+transition (delete-duplicates
                           (map cons to transition)
                           (match-lambda*
                             (((a-to a-transition ...) (b-to b-transition ...))
                              (and (= a-to b-to)
                                   (equal? a-transition b-transition))))))
           (to (map car to+transition))
           (transition (map cdr to+transition))
           (on-location (map on-location traces)))
      (if (null? to) (list (list from pc #f #f #f))
          (map (cut list from pc <> <> <>)
               transition
               to
               on-location))))

  (let* ((alist (hash-table->alist lts))
         (alist (sort alist
                      (match-lambda*
                        (((from-a . pc+traces-a) (from-b . pc+traces-b))
                         (< from-a from-b))))))
    (append-map (cute transition->dot pc->state-number <> <>)
                (map car alist)
                (map cdr alist))))

(define* (lts-remove lts size #:key ports? extended? actions? labels? returns?
                     (self? #t))
  "Remove from the LTS transitions which only differ in terms of
EXTENDED?, PORTS?, LABELS? or ACTIONS?  When SELF?, remove all self
transitions."

  (define (variable-equal? a b)
    (equal? (match a ((name . expression) name)) b))

  (define (remove-extended state)
    (let* ((instance (.instance state))
           (path (runtime:instance->path instance))
           (variables (.variables state))
           (instance (.instance state))
           (model (runtime:ast-model instance)))
      (and (not (equal? path '("client")))
           (pair? variables)
           (or (is-a? (%sut) <runtime:port>)
               (not ports?)
               (not (is-a? instance <runtime:port>)))
           (let* ((members (ast:variable* model))
                  (main (car members))
                  (main-name (.name main))
                  (variables (if (not extended?) variables
                                 (filter (cute variable-equal? <> main-name)
                                         variables))))
             (make <state>
               #:instance instance
               #:variables variables)))))

  (define (remove-state pc)
    (if (and (not ports?) (not extended?)) pc
        (let* ((state-list (.state-list (.state pc)))
               (state-list (filter-map remove-extended state-list))
               (state (make <system-state> #:state-list state-list)))
          (clone pc #:state state))))

  (define (action-return? pc)
    (let ((statement (.statement pc)))
      (and (is-a? statement <trigger-return>)
           (not (.port statement))
           (ast:requires? (.instance pc)))))

  (define (hide-return pc)
    (let ((statement (.statement pc)))
      (and (not (and (action-return? pc)
                     (equal? (.event.name statement) "return")))
           pc)))

  (define (hide-returns trace)
    (filter-map hide-return trace))

  (define hide-actions
    (match-lambda
      ((pc trace ...)
       (let* ((reversed (reverse trace))
              (trigger (any .trigger reversed))
              (action (find (compose (is? <action>) .statement) reversed))
              (trace (filter (negate (disjoin
                                      (compose (is? <action>) .statement)
                                      action-return?))
                             trace))
              (trace (if (ast:modeling? trigger)
                         (reverse (cons action (reverse trace)))
                         trace)))
         (cons pc trace)))))

  (let* ((state-number-table (make-hash-table))
         (state-number-count (list 1))
         (pc->state-number
          (pc->state-number state-number-table state-number-count)))

    (define (merge from result)
      (let ((pc+traces (hash-ref lts from)))
        (if (not pc+traces) result
            (let* ((pc traces (match pc+traces ((pc . traces)
                                                (values pc traces))))
                   (pc (remove-state pc))
                   (traces (map (lambda (trace) (map remove-state trace))
                                traces))
                   (from (pc->state-number pc))
                   (pc+traces (hash-ref result from))
                   (pc traces (match pc+traces
                                ((pc . new-traces)
                                 (values pc (append traces new-traces)))
                                (#f
                                 (values pc traces))))
                   (traces (if (not self?) traces
                               (filter (compose not
                                                (cute = from <>)
                                                pc->state-number car)
                                       traces)))
                   (traces
                    (if (or labels? (not actions?)) traces
                        (map hide-actions traces)))
                   (traces
                    (if (or labels? (not returns?)) traces
                        (map hide-returns traces)))
                   (traces (if (not labels?) traces
                               (map (compose list car) traces))))
              (hash-set! result from (cons pc traces))
              result))))

    (values (fold merge (make-hash-table) (iota size 1))
            pc->state-number
            state-number-count)))

(define (state-diagram->dot graph start)
  "Return a diagram in DOT format from GRAPH produced by
RTC-LTS->STATE-DIAGRAM."
  (define (preamble title)
    (format #f
            "digraph G {
label=~s begin[shape=\"circle\" width=0.3 fillcolor=\"black\" style=\"filled\" label=\"\"]
node[shape=\"rectangle\" style=\"rounded\"]
begin -> 1
" title))

  (define postamble "
}
")
  (define graph->dot
    (match-lambda
      ((from pc (trigger actions ...) to trigger-location)
       (let* ((separator
               (make-string
                (apply max
                       (map string-length (cons trigger actions))) #\-))
              (actions (string-join actions "\n"))
              (label (if (string-null? actions) trigger
                         (format #f "~a\n~a\n~a" trigger separator actions))))
         (string-append
          (format #f "~a [label=~s]\n" from (pc->string-state-diagram pc))
          (format #f "~a -> ~a [label=~s]" from to label))))
      ((from pc () to trigger-location)
       (string-append
        (format #f "~a [label=~s]\n" from (pc->string-state-diagram pc))
        (format #f "~a -> ~a [label=~s]" from to "")))
      ((from pc x #f #f)
       (format #f "~a [label=~s]\n" from (pc->string-state-diagram pc)))))

  (let* ((preamble (preamble (ast:dotted-name (runtime:%sut-model))))
         (dot (map graph->dot graph))
         (dot (string-join dot "\n")))
    (string-append preamble dot postamble)))

(define-method (state->scm (o <state>))
  (let* ((instance (.instance o))
         (path (runtime:instance->path instance))
         (path (match path
                 (("sut" path ...) path)
                 (_ path)))
         (name (string-join path "."))
         (variables (map (match-lambda ((name . value)
                                        `((name  . ,name)
                                          (value . ,(->sexp value)))))
                         (.variables o)))
         (q (.q o)))
    (and (not (equal? path '("client")))
         (or (pair? variables) (pair? q))
         `((instance . ,name)
           (state    . ,(list->vector
                         `(,@variables
                           ,@(if (null? q) '()
                                 `((<q> . (map trigger->string q)))))))))))

(define-method (state->scm (o <system-state>))
  (let* ((state-list (.state-list o))
         (state-list (if (is-a? (%sut) <runtime:port>) state-list
                         (filter (disjoin (compose (is? <runtime:component>) .instance)
                                          (compose ast:requires? .ast .instance))
                                 state-list))))
    (list->vector (filter-map state->scm state-list))))

(define-method (state->scm (pc <program-counter>))
  (state->scm (.state pc)))

(define* (state-diagram->json graph #:optional (working-directory "."))
  "Return a diagram in P5 JSON format from GRAPH produced by
RTC-LTS->STATE-DIAGRAM."
  (define (json-location trigger-location)
    (if (not trigger-location) "\"undefined\""
        (format #f "{\"file-name\":~s,\"line\":~a,\"column\":~a,\"end-line\":~a,\"end-column\":~a}"
                (.file-name trigger-location)
                (.line trigger-location)
                (.column trigger-location)
                (.end-line trigger-location)
                (.end-column trigger-location))))
  (let ((graph (cons `(* #f ("" "") 1 #f) graph))
        (seen (make-hash-table)))
    (string-append
     "{\"states\":[\n"
     (string-join
      (filter-map
       (match-lambda
         ((from pc label to trigger-location)
          (and (not (hash-ref seen from))
               (hash-set! seen from #t)
               (let ((states (if (not pc) "[]"
                                 (scm->json-string (state->scm pc)))))
                 (string-append
                  (format #f "{\"id\":\"~a\", \"state\":~a}" from states))))))
       graph)
      ",\n")
     "],\n"
     "\"transitions\":[\n"
     (string-join
      (filter-map
       (match-lambda
         ((from pc (trigger actions ...) to trigger-location)
          (let* ((location (json-location trigger-location))
                 (actions (scm->json-string (list->vector actions))))
            (format #f
                    "{\"from\":\"~s\", \"to\":\"~s\", \"trigger\":~s, \"action\":~a, \"location\":~a}"
                    from to trigger actions location)))
         ((from pc () to trigger-location)
          (let ((location (json-location trigger-location)))
            (format #f
                    "{\"from\":~s, \"to\":~s, \"trigger\":~s, \"action\":[~s], \"location\":~a}"
                    from to "" "" location)))
         ((from pc x #f #f) #f))
       graph)
      ",\n")
     "],\n"
     (format #f "\"working-directory\":~s\n" working-directory)
     "}\n")))


;;;
;;; LTS
;;;

(define (rtc-lts->lts lts pc->state-number state-number-count)
  "Create an unfolded LTS from the run-to-completion LTS, return

   ((from label to)
     ...))"

  (define (fix-missing-reply-trace trace)
    (let* ((pc (car trace))
           (status (.status pc)))
      (if (not (is-a? status <missing-reply-error>)) trace
          (let* ((instance
                  (or (any (compose (is? <runtime:component>) .instance) trace)
                      (any (compose (is? <runtime:port>) .instance) trace)))
                 (return (list-index
                         (conjoin (negate (is-status? <missing-reply-error>))
                                  (compose (cute eq? <> instance) .instance)
                                  (compose (is? <trigger-return>) .statement))
                         trace)))
            (cons pc (drop trace (1+ return)))))))

  (define (trail->state-numbers pc trail to)
    "Use every trail prefix to hash pc and produce contiguous state
numbers"
    (let* ((prefix (map (cute list-head trail <>)
                        (iota (1- (length trail)) 1)))
           (prefix (map string-join prefix)))
      (append (map (cute pc->state-number pc <>) prefix)
              (list to))))

  (define (trace->lts-triples pc from trace)
    "From a run-to-completion transition PC,TRACE, generate one LTS
triple per label in the trail of the transition."
    (let* ((trace (fix-missing-reply-trace trace))
           (labels (parameterize ((%modeling? #t))
                     (map cdr (trace->trail trace))))
           (labels (if (null? labels) '("tau") labels))
           (to (pc->state-number (car trace)))
           (inner-state-numbers (trail->state-numbers pc labels to)))
      (map list
           (cons from inner-state-numbers)
           labels
           inner-state-numbers)))

  (define (transition->aut from pc+traces)
    (let ((pc traces (match pc+traces ((pc . traces) (values pc traces)))))
      (delete-duplicates
       (append-map
        (cute trace->lts-triples pc from <>)
        traces))))

  (values
   (cons
    (list 0 "<illegal>" 0)
    (apply append (hash-map->list transition->aut lts)))
   (car state-number-count)))

(define (lts->aut lts state-count)
  "Return an LTS in Aldebaran (aut) format from LTS produced by
RTC-LTS->LTS."
  (format #t "des (1,~s,~s)\n" (length lts) state-count)
  (for-each (match-lambda
              ((from step to)
               (format #t "(~s,~s,~s)\n" from step to)))
            lts))


;;;
;;; Entry points.
;;;
(define* (state-diagram ast #:key format model queue-size
                        ports? extended? actions? labels? returns?)
  "Entry-point for dzn explore --state-diagram."
  (let* ((root (vm:normalize ast))
         (model (ast:get-model root (ast:dotted-name model))))
    (parameterize ((%compliance-check? #f)
                   (%debug? (> (dzn:debugity) 0))
                   (%exploring? #t)
                   (%queue-size queue-size)
                   (%sut (runtime:get-sut root model)))
      (parameterize ((%instances (runtime:create-instances (%sut))))
        (let* ((pc (make-pc))
               (lts pc->state-number state-count (pc->rtc-lts pc))
               (size (1- (car state-count)))
               (lts pc->state-number state-count
                    (lts-remove lts size
                                #:ports? (or ports? extended?)
                                #:extended? extended?
                                #:actions? actions?
                                #:labels? labels?
                                #:returns? returns?
                                #:self? (or extended? ports?)))
               (state-diagram (rtc-lts->state-diagram lts pc->state-number)))
          (if (equal? format "json") (display
                                      (state-diagram->json
                                       state-diagram (.working-directory root)))
              (display (state-diagram->dot state-diagram (pc->hash pc)))))))))
(define* (lts ast #:key model queue-size)
  "Entry-point for dzn explore --lts."
  (let* ((root (vm:normalize ast))
         (model (ast:get-model root (ast:dotted-name model))))
    (parameterize ((%compliance-check? #f)
                   (%debug? (> (dzn:debugity) 0))
                   (%exploring? #t)
                   (%queue-size queue-size)
                   (%sut (runtime:get-sut root model)))
      (parameterize ((%instances (runtime:create-instances (%sut))))
        (let* ((pc (make-pc))
               (rtc-lts pc->state-number state-count (pc->rtc-lts pc))
               (lts state-count (rtc-lts->lts rtc-lts pc->state-number state-count)))
          (lts->aut lts state-count))))))
