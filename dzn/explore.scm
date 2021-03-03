;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2021 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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

  #:use-module (dzn command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

  #:use-module (dzn ast)
  #:use-module (dzn display)
  #:use-module (dzn misc)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm normalize)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
  #:use-module (dzn vm util)
  #:export (lts
            state-diagram))

;;; Commentary:
;;;
;;; ’explore’ implements a state diagram.
;;;
;;; Code:

;;;
;;; State diagram
;;;

(define (process-async pc)
  (if (null? (.async pc)) '()
      (run-async-event pc)))

(define (did-provides-out? trace)
  ;; TODO: mark did-provides-out? event in PC
  (let* ((trail (map cdr (trace->trail trace)))
         (r:ports (filter runtime:boundary-port? (%instances)))
         (ports (map .ast r:ports))
         (provide-ports (filter ast:provides? ports))
         (provide-names (map .name provide-ports)))
    (find (lambda (event)
            (match (string-split event #\.)
              ((port event) (member port provide-names))
              ((path ... port event) #f)))
          trail)))

(define-method (check-mark-livelock trace)
  (if (livelock? trace) (mark-livelock-error trace) trace))

(define-method (flush-async-trace (trace <list>) previous-trace)
  (let* ((trace (check-mark-livelock (append trace previous-trace)))
         (pc (car trace))
         (traces (flush-async pc trace)))
    (map (compose check-mark-livelock (cut append <> trace)) traces)))

(define-method (flush-async (pc <program-counter>) previous-trace)
  (let* ((traces (process-async pc))
         (pcs (map car traces)))
    (cond
      ((or (null? traces)) traces)
      (else
        (let* ((stop flush (partition
                            (disjoin (compose null? .async car) did-provides-out? (compose .status car))
                            traces))
                (traces (append stop (append-map (cute flush-async-trace <> previous-trace) flush)))
                (pcs (map car traces)))
          traces)))))

(define-method (process-external (pc <program-counter>))
  (let ((queues (.external-q pc)))
    (if (or (null? queues)
            (pair? (.async pc))) '()
            (let ((instances (map car queues)))
              (append-map (cute run-external-q pc <>) instances)))))

(define (run-to-completion** pc event)
  (let ((pc (clone pc #:instance #f #:reply #f #:trail '())))
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
                        traces)))
            (append stop (append-map (cute flush-async-trace <> '()) flush)))))
     ((provides-trigger? event)
      (run-to-completion pc event)))))

;; table is initially (<(string-hash "<illegal>") . 0>)
(define* ((pc->state-number table count) pc #:optional trail)
  (let* ((pc-string (pc->string pc))
         (pc-string (if trail (string-append pc-string " t:" trail) pc-string))
         (key (string-hash pc-string))
         (next (hash-ref table key)))
    (if next next
        (let ((n (car count)))
          (hash-set! table key n)
          (set-car! count (1+ (car count)))
          n))))

(define (pc->rtc-lts pc)
  "Explore the state space of (%SUT).  Start by running all (labels) on
PC, and recurse until no new PCs are found.  Return a run-to-completion
LTS

   ((pc-hash . (pc . traces))
    ...)

  as a hash table, as multiple values

  (LTS PC->STATE-NUMBER AND STATE-NUMBER-COUNT)
"
  (let* ((labels (cons* 'async 'external (labels)))
         (lts (make-hash-table))
         (state-number-table (make-hash-table))
         (state-number-count (list 1))
         (pc->state-number (pc->state-number state-number-table state-number-count)))
    (hash-set! state-number-table (string-hash "<illegal>") 0)
    (when (.status pc)
      (let ((pc0 (clone pc #:status #f)))
        (hash-set! lts 1 (cons pc0 (list (list pc0 pc))))))
    (let loop ((pc pc))
      (let ((from (pc->state-number pc)))
        (unless (or (.status pc) (hash-ref lts from))
          (let* ((pc (clone pc #:instance #f #:trail '()))
                 (traces (append-map (cute run-to-completion** pc <>) labels))
                 (pcs (map car traces)))
            (map pc->state-number pcs)
            (hash-set! lts from (cons pc traces))
            (for-each loop pcs)))))
    (when (= (car state-number-count) 1)
      (hash-set! lts 1 (cons pc (list (list pc)))))
    (values lts pc->state-number state-number-count)))

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
    (map cdr (trace->trail trace)))

  (define ((transition->dot pc->state-number) from pc+traces)
    (let* ((pc traces (match pc+traces ((pc . traces) (values pc traces))))
           (traces (filter (compose not .status car) traces))
           (pcs (map car traces))
           (transition (map trace->string-trail traces))
           (from-label (pc->string pc))
           (to (map pc->state-number pcs))
           (trigger-location (map trigger-location traces)))
      (if (null? to) (list (list from from-label #f #f #f))
          (map (cut list from from-label <> <> <>)
               transition
               to
               trigger-location))))

  (apply append (hash-map->list (transition->dot pc->state-number) lts)))

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
   (preamble (ast:dotted-name (.type (.ast (%sut)))))
   (string-join
    (map (match-lambda ((from from-label (trigger actions ...) to trigger-location)
                        (let* ((separator (make-string (apply max (map string-length (cons trigger actions))) #\-))
                               (actions (string-join actions "\n"))
                               (label (if (string-null? actions) trigger
                                          (format #f "~a\n~a\n~a" trigger separator actions))))
                         (string-append
                          (format #f "~s [label=~s]\n" from from-label)
                          (format #f "~s -> ~s [label=~s]" from to label))))
                       ((from from-label #f #f #f)
                        (format #f "~s [label=~s]\n" from from-label)))
         graph)
    "\n")
   postamble))

(define (state-diagram->json graph)
  "Return a diagram in P5 JSON format from GRAPH produced by
RTC-LTS->STATE-DIAGRAM."
  (let ((graph (cons `("*" "" ("" "") "1" #f) graph)))
    (string-append
     "{\"states\":[\n"
     (string-join
      (map (match-lambda ((from from-label label to trigger-location)
                          (string-append
                           (format #f "{\"id\":~s, \"state\":~s}" from from-label))))
           (delete-duplicates graph (lambda (a b) (and (equal? (first a) (first b))
                                                       (equal? (second a) (second b)))))) ",\n")
     "],\n"
     "\"transitions\":[\n"
     (string-join
      (filter-map
       (match-lambda
         ((from from-label (trigger actions ...) to trigger-location)
          (let* ((location (if (not trigger-location) "\"undefined\""
                               (format #f "{\"file-name\":~s,\"line\":~a,\"column\":~a}"
                                       (.file-name trigger-location)
                                       (.line trigger-location)
                                       (.column trigger-location))))
                 (actions (string-join actions "\n")))
            (format #f
                    "{\"from\":~s, \"to\":~s, \"trigger\":~s, \"action\":~s, \"location\":~a}"
                    from to trigger actions location)))
         ((from from-label #f #f #f) #f))
       graph)
      ",\n")
     "]}\n")))


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
           (labels (map cdr (trace->trail trace)))
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

(define* (state-diagram root #:key format model-name queue-size)
  "Entry-point for dzn explore --state-diagram."
  (let ((root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (parameterize ((%exploring? #t)
                   (%queue-size queue-size)
                   (%sut (runtime:get-sut root (ast:get-model root model-name))))
      (parameterize ((%instances (runtime:system* (%sut))))
        (let* ((pc (make-pc))
               (lts pc->state-number state-count (pc->rtc-lts pc))
               (state-diagram (rtc-lts->state-diagram lts pc->state-number)))
          (if (equal? format "json") (display (state-diagram->json state-diagram))
              (display (state-diagram->dot state-diagram (pc->hash pc)))))))))

(define* (lts root #:key model-name queue-size)
  "Entry-point for dzn explore --lts."
  (let ((root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (parameterize ((%exploring? #t)
                   (%queue-size queue-size)
                   (%sut (runtime:get-sut root (ast:get-model root model-name))))
      (parameterize ((%instances (runtime:system* (%sut))))
        (let* ((pc (make-pc))
               (rtc-lts pc->state-number state-count (pc->rtc-lts pc))
               (lts state-count (rtc-lts->lts rtc-lts pc->state-number state-count)))
          (lts->aut lts state-count))))))
