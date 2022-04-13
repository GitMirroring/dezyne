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
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (json)

  #:use-module (dzn command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn display)
  #:use-module (dzn misc)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
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
    (if (or (null? queues)
            (pair? (.async pc))) '()
            (let ((instances (map car queues)))
              (append-map (cute run-external-q pc <>) instances)))))

(define (run-to-completion** pc event)
  (let* ((pc (clone pc #:instance #f #:trail '()))
         (pc (reset-replies pc)))
    (cond
     ((eq? event 'async)
      (flush-async pc '()))
     ((eq? event 'external)
      (process-external pc))
     ((is-a? (%sut) <runtime:port>)
      (run-to-completion pc event))
     ((requires-trigger? event)
      (if (pair? (.async pc)) '()
          (let* ((traces (run-requires pc event))
                 (stop flush
                       (partition
                        (disjoin (compose null? .async car)
                                 did-provides-out?
                                 (compose .status car))
                        traces))
                 (port (.port (string->trigger event)))
                 (blocked-port (and=> (blocked-on-boundary? pc) .ast)))
            (if (and port (ast:eq? port blocked-port)) '()
                (append stop (append-map (cute flush-async-trace <> '())
                                         flush))))))
     ((provides-trigger? event)
      (if (blocked-on-boundary-provides? pc event) '()
          (run-to-completion pc event))))))

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

  (define (run-label orig-pc label)
    (let* ((pc (switch-context orig-pc))
           (switched? (not (eq? pc orig-pc)))
           (pc (if switched? pc
                   (blocked-on-boundary-switch-context pc)))
           (bop-switched? (and (not switched?)
                               (not (eq? pc orig-pc))))
           (pc (if (or switched? bop-switched?) pc
                   (blocked-on-boundary-collateral-release pc))))
      (if (eq? pc orig-pc) (run-to-completion** pc label)
          (if (and switched?
                   (not (provides-trigger? label)))
              (run-to-completion pc 'rtc)
              (append (run-to-completion pc 'rtc)
                      (run-to-completion** orig-pc label))))))

  (define (run-labels pc labels)
    (let loop ((labels labels) (traces '()))
      (if (null? labels) traces
          (let* ((label (car labels))
                 (new (run-label pc label))
                 (new (if (eq? label 'external) new
                          (filter-implicit-illegal-only new)))
                 (new (filter (compose not (is-status? <blocked-error>) car)
                              new))
                 (new (filter (compose not (cute collateral? <> pc) car) new)))
            (cond
             ((find (compose (is-status? <livelock-error>) car) new)
              (format (current-error-port) "warning: livelock, bailing out\n")
              '())
             (else
              (loop (cdr labels) (append new traces))))))))

  (let* ((labels (cons* 'async 'external (labels)))
         (lts (make-hash-table))
         (state-number-table (make-hash-table))
         (state-number-count (list 1))
         (pc->state-number (pc->state-number state-number-table
                                             state-number-count)))
    (hash-set! state-number-table "<illegal>" 0)
    (when (.status pc)
      (let ((pc0 (clone pc #:status #f)))
        (hash-set! lts 1 (cons pc0 (list (list pc0 pc))))))
    (let loop ((pc pc))
      (let ((from (pc->state-number pc)))
        (unless (or (.status pc) (hash-ref lts from))
          (let* ((from-pc pc)
                 (pc (clone pc #:collateral-instance #f))
                 (traces (run-labels pc labels))
                 (traces (map (cute append <> (list from-pc)) traces))
                 (pcs (map car traces)))
            (hash-set! lts from (cons from-pc traces))
            (let* ((traces (filter (negate trace-done?) traces))
                   (pcs (map car traces)))
              (for-each loop pcs))))))
    (when (= (car state-number-count) 1)
      (hash-set! lts 1 (cons pc (list (list pc)))))
    (values lts pc->state-number state-number-count)))


;;;
;;; State diagram
;;;
(define (rtc-lts->state-diagram lts pc->state-number)
  "Create a state-diagram from run-to-completion LTS, return

   ((from from-label transition to trigger-location)
    ...)
"
  (define (trigger-location trace)
    (let ((pc (find (conjoin (compose (is? <on>) .statement)
                             (disjoin (const (is-a? (%sut) <runtime:port>))
                                      (compose (is? <runtime:component>) .instance)))
                    (reverse trace))))
      (and pc (and=> (.statement pc) ast:location))))

  (define (trace->string-trail trace)
    (let* ((trail (map cdr (trace->trail trace)))
           (trail (filter (negate (cute string-suffix? ".return" <>)) trail)))
      (define (strip-sut-prefix o)
        (if (string-prefix? "sut." o) (substring o 4) o))
      (map strip-sut-prefix trail)))

  (define ((transition->dot pc->state-number) from pc+traces)
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
           (trigger-location (map trigger-location traces)))
      (if (null? to) (list (list from pc #f #f #f))
          (map (cut list from pc <> <> <>)
               transition
               to
               trigger-location))))

  (apply append (hash-map->list (transition->dot pc->state-number) lts)))

(define* (lts-remove lts size #:key ports? extended? actions? labels?
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

  (define (hide-return-value pc)
    (let ((statement (.statement pc)))
      (if (is-a? statement <trigger-return>)
          (clone pc #:statement (clone statement #:event.name "return"))
          pc)))

  (define hide-actions
    (match-lambda
      ((pc trace ...)
       (let* ((reversed (reverse trace))
              (trigger (any .trigger reversed))
              (action (find (compose (is? <action>) .statement) reversed))
              (trace (filter (compose not (is? <action>) .statement) trace))
              (trace (map hide-return-value trace))
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

  (define postamble
    "
}
")
  (string-append
   (preamble (ast:dotted-name (runtime:%sut-model)))
   (string-join
    (map (match-lambda ((from pc (trigger actions ...) to trigger-location)
                        (let* ((separator (make-string (apply max (map string-length (cons trigger actions))) #\-))
                               (actions (string-join actions "\n"))
                               (label (if (string-null? actions) trigger
                                          (format #f "~a\n~a\n~a" trigger separator actions))))
                          (string-append
                           (format #f "~s [label=~s]\n" from (pc->string-state-diagram pc))
                           (format #f "~s -> ~s [label=~s]" from to label))))
                       ((from pc () to trigger-location)
                        (string-append
                         (format #f "~s [label=~s]\n" from (pc->string-state-diagram pc))
                         (format #f "~s -> ~s [label=~s]" from to "")))
                       ((from pc x #f #f)
                        (format #f "~s [label=~s]\n" from (pc->string-state-diagram pc))))
         graph)
    "\n")
   postamble))

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
    (match trace
      (((and ($ <program-counter>) (? (is-status? <missing-reply-error>)) error)
        ($ <program-counter>) tail ...)
       (cons error tail))
      (_ trace)))

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
      (append-map (cute trace->lts-triples pc from <>) traces)))

  (values
   (cons
    (list 0 "<illegal>" 0)
    (apply append (hash-map->list transition->aut lts)))
   (car state-number-count)))

(define (lts->aut lts state-count)
  "Return an LTS in Aldebaran (aut) format from LTS produced by
RTC-LTS->LTS."
  (format #t "des (1, ~s, ~s)\n" (length lts) state-count)
  (for-each (match-lambda
              ((from step to)
               (format #t "(~s, ~s, ~s)\n" from step to)))
            lts))


;;;
;;; Entry points.
;;;

(define* (state-diagram root #:key format model queue-size
                        ports? extended? actions? labels?)
  "Entry-point for dzn explore --state-diagram."
  (parameterize ((%debug? (> (dzn:debugity) 0))
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
                              #:self? (or extended? ports?)))
             (state-diagram (rtc-lts->state-diagram lts pc->state-number)))
        (if (equal? format "json") (display
                                    (state-diagram->json
                                     state-diagram (.working-directory root)))
            (display (state-diagram->dot state-diagram (pc->hash pc))))))))

(define* (lts root #:key model queue-size)
  "Entry-point for dzn explore --lts."
  (parameterize ((%debug? (> (dzn:debugity) 0))
                 (%exploring? #t)
                 (%queue-size queue-size)
                 (%sut (runtime:get-sut root model)))
    (parameterize ((%instances (runtime:create-instances (%sut))))
      (let* ((pc (make-pc))
             (rtc-lts pc->state-number state-count (pc->rtc-lts pc))
             (lts state-count (rtc-lts->lts rtc-lts pc->state-number state-count)))
        (lts->aut lts state-count)))))
