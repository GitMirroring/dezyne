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

(define (trace->string-trail trace)
  (let ((labels (map cdr (trace->trail trace))))
    (match labels
      ((trigger action ...)
       (string-join (cons* trigger "------" action) "\n"))
      (() "------"))))

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

(define (explore pc)
  "Explore the state space of (%SUT).  Start by running all (labels) on
PC, and recurse until no new PCs are found.  Return the graph as

   ((from from-label transition to trigger-location)
    ...)
"
  (define (trigger-location trace)
    (let ((pc (find (conjoin (compose (is? <on>) .statement)
                             (disjoin (const (is-a? (%sut) <runtime:port>))
                                      (compose (is? <runtime:component>) .instance)))
                    (reverse trace))))
      (and pc (and=> (.statement pc) ast:location))))
  (define (graph pc)
    (let* ((labels (cons* 'async 'external (labels)))
           (explored (make-hash-table)))
      (let loop ((pc pc))
        (let ((from (pc->hash pc)))
          (if (equal? (hash-ref explored from) (pc->string pc)) '()
              (let* ((pc (clone pc #:instance #f #:trail '()))
                     (traces (append-map (cute run-to-completion** pc <>) labels))
                     (traces (filter (compose not .status car) traces))
                     (pcs (map car traces))
                     (transition (map trace->string-trail traces))
                     (from-label (pc->string pc))
                     (to (map pc->hash pcs))
                     (trigger-location (map trigger-location traces)))
                (hash-set! explored from (pc->string pc))
                (append (map (cut list from from-label <> <> <>)
                             transition
                             to
                             trigger-location)
                        (append-map loop pcs))))))))
  (let ((graph (graph pc)))
    (if (null? graph) `((,(pc->hash pc) ,(pc->string pc) #f #f #f))
        graph)))

(define (graph->dot graph)
  "Return a diagram in DOT format from GRAPH produced by EXPLORE."
  (define (preamble title)
    (format #f
            "digraph G {
label=~s begin[shape=\"circle\" width=0.3 fillcolor=\"black\" style=\"filled\" label=\"\"]
node[shape=\"rectangle\" style=\"rounded\"]
begin -> " title))

  (define postamble
    "
}
")
  (let ((start (match graph (((from from-label label to trigger-location) transition ...)
                             from))))
    (string-append
     (preamble (ast:dotted-name (.type (.ast (%sut)))))
     (string-append (number->string start) "\n")
     (string-join
      (map (match-lambda ((from from-label label to trigger-location)
                          (string-append
                           (format #f "~s [label=~s]\n" from from-label)
                           (if (and to label)
                               (format #f "~s -> ~s [label=~s]" from to label)
                               ""))))
           graph)
      "\n")
     postamble)))

(define (graph->json graph)
  (let* ((start (match graph (((from from-label label to trigger-location) transition ...)
                              from)))
         (graph (cons `("*" "" "" ,start #f) graph)))
    (string-append
     "{\"states\":[\n"
     (string-join
      (map (match-lambda ((from from-label label to trigger-location)
                          (string-append
                           (format #f "{\"id\":~s, \"state\":~s}\n" from from-label))))
           (delete-duplicates graph (lambda (a b) (and (equal? (first a) (first b))
                                                       (equal? (second a) (second b)))))) ",\n")
     "],\n"
     "\"transitions\":[\n"
     (string-join
      (map (match-lambda
             ((from from-label label to trigger-location)
              (let* ((location (if (not trigger-location) "\"undefined\""
                                   (format #f "{\"file-name\":~s,\"line\":~a,\"column\":~a}"
                                           (.file-name trigger-location)
                                           (.line trigger-location)
                                           (.column trigger-location))))
                     (separator "\n------\n")
                     (pos (string-contains label separator))
                     (trigger (if pos (substring label 0 pos) separator))
                     (action (if pos (substring label (+ pos (string-length separator))) "")))
                (format #f
                        "{\"from\":~s, \"to\":~s, \"trigger\":~s, \"action\":~s, \"location\":~a}"
                        from to trigger action location))))
           (filter (match-lambda ((from from-label #f #f #f) #f) (_ #t)) graph)
           ) ",\n")
     "]}")))


;;;
;;; LTS
;;;

(define %lts-state-count 1) ;; FIXME: remove global

(define (explore-lts pc)
  "Explore the state space of (%SUT).  Start by running all (labels) on
PC, and recurse until no new PCs are found.  Return the graph as

   ((from transition to)
    ...)

  and set! %lts-state-count: the number of states.
"
  (let* ((labels (cons* 'async 'external (labels)))
         (pc-state-number (make-hash-table))
         (explored (make-hash-table)))
    (define (pc->state-number pc)
      (let ((state-string (pc->string pc)))
        (cond ((is-a? (.status pc) <illegal-error>)
               0)
              ((is-a? (.status pc) <implicit-illegal-error>)
               0)
              ((hash-ref pc-state-number state-string))
              (else
               (hash-set! pc-state-number state-string %lts-state-count)
               (set! %lts-state-count (1+ %lts-state-count))
               (pc->state-number pc)))))
    (define fix-illegal-transition
      (match-lambda
        ((from (trail ... "<illegal>") to)
         `(,from (,@trail "<illegal>") 0))
        (()
         '())
        (transition transition)))
    (define (fix-missing-reply-trace trace)
      (match trace
        (((and ($ <program-counter>) (? (is-status? <missing-reply-error>)) error)
          ($ <program-counter>) tail ...)
         (cons error tail))
        (_ trace)))
    (define (traces->transitions pc from label traces)
      (let* ((traces (map fix-missing-reply-trace traces))
             (pcs (map car traces))
             (tos (map pc->state-number pcs))
             (trails (map (lambda (t) (map cdr (trace->trail t))) traces))
             (transitions (map (cut list from <> <>) trails tos))
             (transitions (map fix-illegal-transition transitions)))
        transitions))
    (cons
     '(0 ("<illegal>") 0)
     (let loop ((pc pc))
       (let ((from (pc->state-number pc)))
         (if (or (.status pc) (hash-ref explored from)) '()
             (let* ((pc (clone pc #:instance #f #:trail '()))
                    (traces (map (cute run-to-completion** pc <>) labels))
                    (pcs (append-map (cute map car <>) traces))
                    (transitions (append-map (cute traces->transitions pc from <> <>) labels traces)))
               (hash-set! explored from #t)
               (append transitions
                       (append-map loop pcs)))))))))

(define (graph->lts graph)
  "Return an LTS in Aldebaran format from GRAPH produced by
EXPLORE-LTS."
  (define (next-state-num)
    (let ((res %lts-state-count))
      (set! %lts-state-count (1+ %lts-state-count))
      res))
  (define steps-expand
    (match-lambda
      ((from () to)
       (steps-expand `(,from ("tau") ,to)))
      ((from (step tail ...) to)
       (let* ((l (map (cut list (next-state-num) <>) tail))
              (l0 (cons `(,from ,step) l))
              (l1 (append l (list `(,to #f)))))
         (map (match-lambda*
                (((from step tail ...) (to to-tail ...))
                 (format #f "(~s, ~s, ~s)" from step to)))
              l0 l1)))))
  (let ((lines (append-map steps-expand graph)))
    (string-append
     (format #f "des (1, ~s, ~s)\n" (length lines) %lts-state-count)
     (string-join lines "\n")
     "\n")))


;;;
;;; Entry point.
;;;

(define* (state-diagram root #:key format model-name queue-size)
  "Entry-point for dzn explore --state-diagram."
  (let ((root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (parameterize ((%exploring? #t)
                   (%queue-size queue-size)
                   (%sut (runtime:get-sut root (ast:get-model root model-name)))
)      (parameterize ((%instances (runtime:system* (%sut))))
        (let* ((pc (make-pc))
               (graph (explore pc)))
          (if (equal? format "json") (display (graph->json graph))
              (display (graph->dot graph))))))))

(define* (lts root #:key model-name queue-size)
  "Entry-point for dzn explore --lts."
  (let ((root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (parameterize ((%exploring? #t)
                   (%queue-size queue-size)
                   (%sut (runtime:get-sut root (ast:get-model root model-name))))
      (parameterize ((%instances (runtime:system* (%sut))))
        (let ((pc (make-pc)))
          (display (graph->lts (explore-lts pc))))))))
