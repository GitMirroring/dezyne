;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2018, 2019, 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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
;;;
;;; Commentary:
;;;
;;; XXX TODO: see wip-stitch
;;;   * Remove duplicate <lts> data structure.
;;;   * Reduce use of set! and general imperative style; use functional
;;;     setters and map instead of for-each.
;;;
;;; Code:

(define-module (dzn lts)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-43)
  #:use-module (dzn misc)
  #:use-module (dzn peg)
  #:export (add-failures
            assert-deadlock
            assert-deterministic
            assert-file-exists
            assert-illegal
            assert-livelock
            assert-partially-deterministic
            assert-unreachable
            edge-label
            aut-file->lts
            aut-text->lts
            aut-header-regex
            cleanup-aut
            cleanup-error
            cleanup-label
            display-lts
            lts->alphabet
            lts->nodes
            lts->traces
            lts-hide
            lts-stable-accepts
            <lts>
            make-edge
            make-lts
            lts-edges
            lts-state
            lts-states
            remove-illegal
            remove-tag-edges
            rm-tau-loops
            run
            step-tau
            text->aut-header
            text->edge
            text-file->aut-header
             write-lts))

(define (assert-file-exists file)
  (if (not (access? file R_OK))
      (begin (format (current-error-port) "File not found: ~a\n" file)
             #f)
      file))

;; ===== text-file =====
(define (text->line-list text)
  (map (cute string-trim-right <> #\cr) (string-split text #\newline)))

(define (text-file->line-list file-name)
  (text->line-list (with-input-from-file file-name read-string)))

;; The Aldebaran file format is a simple format for storing labelled transition systems (LTS’s) explicitly.
;; The syntax of an Aldebaran file consists of a number of lines, where the first line is aut_header and the remaining lines are aut_edge.

;; aut_header is defined as follows:
;;     aut_header        ::=  'des (' first_state ',' nr_of_transitions ',' nr_of_states ')'
;;     first_state       ::=  number
;;     nr_of_transitions ::=  number
;;     nr_of_states      ::=  number

;; Here:
;;     first_state is a number representing the first state, which should always be 0
;;     nr_of_transitions is a number representing the number of transitions
;;     nr_of_states is a number representing the number of states

;; An aut_edge is defined as follows:
;;     aut_edge    ::=  '(' start_state ',' label ',' end_state ')'
;;     start_state ::=  number
;;     label       ::=  '"' string '"'
;;     end_state   ::=  number

;; Here:
;;     start_state is a number representing the start state of the edge;
;;     label is a string enclosed in double quotes representing the label of the edge;
;;     end_state is a number representing the end state of the edge.


(define-record-type <aut-header>
  (make-aut-header first-state nr-transitions nr-states)
  aut-header?
  (first-state aut-header-first-state)
  (nr-transitions aut-header-nr-transitions)
  (nr-states aut-header-nr-states))

(define (text->aut-header text)
  (let* ((rem (regexp-exec aut-header-regex text))
         (first-state (and rem (string->number (match:substring rem 1))))
         (nr-transitions (and rem (string->number (match:substring rem 2))))
         (nr-states (and rem (string->number (match:substring rem 3)))))
    (and first-state nr-transitions nr-states (make-aut-header first-state nr-transitions nr-states))))

(define-record-type <edge>
  (make-edge_ start-state label tau? end-state)
  edge?
  (start-state edge-start-state set-edge-start-state!)
  (label edge-label set-edge-label!)
  (tau? edge-tau?)
  (end-state edge-end-state set-edge-end-state!))

;; (define edge-regex (make-regexp "[(]([0-9]+),[\"](.*)[\"],([0-9]+)[)]"))
;; (define (text->edge text)
;;   (let* ((rem (regexp-exec edge-regex text))
;;          (start-state (and rem (string->number (match:substring rem 1))))
;;          (label (and rem (match:substring rem 2)))
;;          (end-state (and rem (string->number (match:substring rem 3)))))
;;     (and start-state label end-state (make-edge start-state label end-state))))
;; (define (test:text->edge)
;;   (and (text->edge "(0,\"aap\",1)")
;;        (not (text->edge "des (0,1,2)"))))
(define (text->edge text)
  (let* ((first-paren 0)
         (last-paren (string-length text))
         (first-comma (string-index text #\,))
         (last-comma (string-rindex text #\,))
         (start-state (string->number (string-copy text (1+ first-paren) first-comma)))
         (label (string-copy text (+ 2 first-comma) (1- last-comma)))
         (end-state (string->number (string-copy text (1+ last-comma) (1- last-paren)))))
    (make-edge start-state label end-state)))

(define (make-edge start-state label end-state)
  (make-edge_ start-state
                  label
                  (or (and (symbol? label) (equal? 'tau label))
                      (and (string? label) (string= label "tau")))
                  end-state))

(define (clone-edge e)
  (make-edge_ (edge-start-state e) (edge-label e) (edge-tau? e) (edge-end-state e)))

(define (make-edge-loop)
  (make-edge_ -1 "<loop>" #t -1))

(define (states edges)
  "List of states referenced in edges."
  (sort (delete-duplicates (append (map edge-start-state edges) (map edge-end-state edges))) <))

(define (edges->successor-edge-vector states edges)
  "Vector with successor edges per node"

  (define (bin result state-nrs edges)
    (if (null? state-nrs) result
        (let* ((state (car state-nrs))
               (parts (receive (state-edges other-edges)
                          (span (lambda (e) (= state (edge-start-state e))) edges)
                        (cons state-edges other-edges)))
               (head (car parts))
               (tail (cdr parts)))
          (bin (cons head result) (cdr state-nrs) tail))))

  (list->vector (bin '()
                     (reverse (iota states))
                     (sort edges (lambda (a b) (> (edge-start-state a) (edge-start-state b)))))))

(define (edges->predecessor-edge-vector states edges)
  "Vector with predecessor edges per node"

  (define (bin result state-nrs edges)
    (if (null? state-nrs) result
        (let* ((state (car state-nrs))
               (parts (receive (state-edges other-edges)
                          (span (lambda (e) (= state (edge-end-state e))) edges)
                        (cons state-edges other-edges)))
               (head (car parts))
               (tail (cdr parts)))
          (bin (cons head result) (cdr state-nrs) tail))))

  (list->vector (bin '()
                     (reverse (iota states))
                     (sort edges (lambda (a b) (> (edge-end-state a) (edge-end-state b)))))))

;; - - - - -   l t s   - - - - -
(define-record-type <lts>
  (make-lts state states edges)
  lts?
  (state lts-state) ;; list of numbers (state identifiers)
  (states lts-states set-lts-states!) ;; number of states in lts
  (edges lts-edges set-lts-edges!) ;; list of <edge>
  )

(define (lts-succ lts state)
  "Edges transitioning from STATE"
  (filter (lambda (e) (= state (edge-start-state e))) (lts-edges lts)))

(define (lts-pred lts state)
  "Edges transitioning into STATE"
  (filter (lambda (e) (= state (edge-end-state e))) (lts-edges lts)))

(define (aut-text->lts text)
  "List starting with one <aut-header> followed by multiple <edge>"
  (define (remove-empty-lines lines)
    (filter (lambda (l) (not (equal? "" l))) lines))
  (let* ((lines (text->line-list text))
         (lines (filter (negate string-null?) lines))
         (header (car lines))
         (edges (cdr lines)))
    (make-lts (list (aut-header-first-state (text->aut-header header)))
              (aut-header-nr-states (text->aut-header header))
              (map text->edge edges))))

(define (aut-file->lts file-name)
  (aut-text->lts (with-input-from-file file-name read-string)))

(define (lts-hide lts tau exclude-tau)
  "Mark edges labeled with name occurring in TAU as tau-edge."
  (make-lts (lts-state lts)
            (lts-states lts)
            (map (lambda (edge) (if (and
                                      (or (member (edge-label edge) tau)
                                          (find (cut string-prefix? <> (edge-label edge))
                                                  (append (map (cut string-append <> ".") tau)
                                                          (map (cut string-append <> "(") tau))))
                                      (not (member (edge-label edge) exclude-tau)))
                                    (make-edge_ (edge-start-state edge)
                                                    (edge-label edge)
                                                    #t
                                                    (edge-end-state edge))
                                    edge))
                 (lts-edges lts))))

(define (lts->alphabet lts)
  "List of non-tau edge labels found in lts"
  (delete-duplicates (map edge-label (filter (negate edge-tau?) (lts-edges lts)))))

(define (lts-accept-edge-sets lts)
  "List outgoing edge sets for current LTS state."
  (let* ((current-states (lts-state lts))
         (acceptance-sets (map (cut lts-succ lts <>) current-states)))
    (delete-duplicates acceptance-sets)))

(define (lts-stable-accepts lts)
  "List stable acceptance sets. (Acceptance sets of stable
states. Stable state has no outgoing tau edges.)"
  ;; pre-condition: LTS shall be in a stable state
  (and (lts? lts)
       (let* ((acceptance-sets (lts-accept-edge-sets lts))
              (stable-acceptance-sets (map (lambda (edge-set) (delete-duplicates (map edge-label edge-set)))
                                           acceptance-sets)))
         (delete-duplicates stable-acceptance-sets))))

;; v v v v v   l i v e l o c k   c h e c k   v v v v v

(define-record-type <node>
  (make-node state succ pred root? color parent distance cycle)
  node?
  (state node-state set-node-state!)
  (succ node-succ set-node-succ!) ;; (<edge>)
  (pred node-pred set-node-pred!)
  (root? node-root?)
  (color node-color set-node-color!) ;; integer
  (parent node-parent set-node-parent!) ;; edge from parent
  (distance node-distance set-node-distance!) ;; -1 signifies infinite distance (unreachable)
  (cycle node-cycle set-node-cycle!) ;; edge to previous node in tau-loop
  )

(define (clone-node n)
  (make-node (node-state n) (node-succ n) (node-pred n) (node-root? n) (node-color n) (node-parent n) (node-distance n) (node-cycle n)))

(define test-lts-livelock
  (make-lts '(0)
            5
            (list (make-edge_ 0 "aap" #f 1)
                  (make-edge_ 1 "return" #f 0)
                  (make-edge_ 0 "blaat" #t 2)
                  (make-edge_ 2 "noot" #f 3)
                  (make-edge_ 2 "blaat" #t 3)
                  (make-edge_ 3 "tau" #t 3)
                  (make-edge_ 3 "live" #t 4)
                  (make-edge_ 4 "lock" #t 3)
                  (make-edge_ 3 "mies" #f 0))))
(define test-lts-livelock-2
  (make-lts '(1)
            3
            (list (make-edge_ 0 "tau" #t 0)
                  (make-edge_ 2 "BlindLoop'return(BlindLoop'in'start, reply_BlindLoop'Void(void))" #f 0)
                  (make-edge_ 1 "BlindLoop'event(BlindLoop'in'start)" #f 2))))

(define (annotate-parent nodes)
  "Set 'parent' and 'distance' from root-state in each node in NODES"
  (define (annotate-parent-it nodes curr-frontier next-frontier)
    (cond ((and (null? curr-frontier) (null? next-frontier)) nodes)
          ((and (null? curr-frontier) (not (null? next-frontier)))
           (annotate-parent-it nodes next-frontier curr-frontier))
          ((not (null? curr-frontier))
           (let* ((state (car curr-frontier))
                  (node (vector-ref nodes state))
                  (distance (node-distance node))
                  (succ (node-succ node))
                  (succ (filter (lambda (edge) (= -1 (node-distance (vector-ref nodes (edge-end-state edge))))) succ))
                  (next-frontier (fold (lambda (edge next-frontier)
                                         (let ((node (vector-ref nodes (edge-end-state edge))))
                                           (set-node-distance! node (1+ distance))
                                           (set-node-parent! node edge)
                                           (cons (edge-end-state edge) next-frontier)))
                                       next-frontier
                                       succ)))
             (annotate-parent-it nodes (cdr curr-frontier) next-frontier)))))
  (let* ((root-state (root nodes))
         (root-node (vector-ref nodes root-state)))
    (set-node-distance! root-node 0)
    (set-node-parent! root-node #f)
    (annotate-parent-it nodes (list root-state) '())))

(define WHITE 0)
(define GREY 1)
(define BLACK 2)

(define* (lts->nodes lts #:optional traces?)
  "Vector of <node> representing LTS"
  (let* ((states (iota (lts-states lts)))
         (roots (lts-state lts))
         (succ (edges->successor-edge-vector (lts-states lts) (lts-edges lts)))
         (pred (if traces? (edges->predecessor-edge-vector (lts-states lts) (lts-edges lts)) (vector)))
         (nodes (map (lambda (state) (make-node state
                                                (vector-ref succ state)
                                                (if traces? (vector-ref pred state) (vector))
                                                (if (memv state roots) #t #f)
                                                WHITE
                                                #f
                                                -1
                                                #f))
                     states))
         (nodes (list->vector nodes)))
    (if traces? nodes (annotate-parent nodes))))

(define (root nodes)
  "Index (state) of root node in NODES vector."
  (let it ((state 0))
    (cond ((node-root? (vector-ref nodes state)) state)
          ((= (vector-length nodes) state) 0)
          (else (it (1+ state))))))

(define (lts-tau-loops nodes)
  "States that are part of a tau-loop"
  (let ((livelocks '()))
    (define (loop-detect state entry-edge)
      (define (report-cycle state)
        (set! livelocks (cons state livelocks)))
      (let ((node (vector-ref nodes state)))
        (if (= (node-color node) GREY) (begin (set-node-cycle! node entry-edge)
                                               (report-cycle state))
            (if (= (node-color node) WHITE) (let* ((tau-edges (filter edge-tau? (node-succ node))))
                                              (set-node-color! node GREY)
                                              (set-node-cycle! node entry-edge)
                                              (for-each (lambda (e) (loop-detect (edge-end-state e) e)) tau-edges)
                                              (set-node-color! node BLACK))))))
    (for-each (lambda (s) (loop-detect s #f))
              (sort (iota (vector-length nodes))
                    (lambda (a b) (< (node-distance (vector-ref nodes a))
                                     (node-distance (vector-ref nodes b))))))
    (delete-duplicates livelocks)))

(define (trace nodes state)
  "Trace from ROOT to STATE"
  (let ((nodes nodes))
    (define (trace-it state edges)
      (let ((parent (node-parent (vector-ref nodes state))))
        (if (not parent) edges
            (trace-it (edge-start-state parent) (cons parent edges)))))
    (trace-it state '())))

(define (tau-loop loop-entry-state nodes)
  "Loop of events leading from LOOP-ENTRY-STATE back to LOOP-ENTRY-STATE"
  (define (loop-edges trace state)
    (let* ((predecessor-edge (node-cycle (vector-ref nodes state)))
           (predecessor-state (edge-start-state predecessor-edge))
           (predecessor-node (vector-ref nodes predecessor-state)))
     (if (equal? predecessor-state loop-entry-state) (cons predecessor-edge trace)
         (loop-edges (cons predecessor-edge trace) predecessor-state))))
  (loop-edges '()  loop-entry-state))

(define (assert-livelock nodes)
  "Trace to entry point of first livelock or #f if no tau loops found"
  (let* ((livelock-nodes (lts-tau-loops nodes))
         (loop-entry-trace (and (not (null? livelock-nodes)) (trace nodes (car livelock-nodes))))
         (loop-entry-node (and loop-entry-trace (car livelock-nodes)))
         (loop-trace (and loop-entry-node (tau-loop loop-entry-node nodes))))
    (if (null? livelock-nodes) #f
        (append (or loop-entry-trace '())
                (list (make-edge-loop))
                (or loop-trace '())))))

(define (rm-tau-loops lts)
  "Remove all edges starting in a tau-loop entry state. (Promotes
livelock to deadlock.)"
  (let* ((livelock-states (lts-tau-loops (lts->nodes lts)))
         (lts (make-lts (lts-state lts)
                        (lts-states lts)
                        (filter (lambda (e) (not (memv (edge-start-state e) livelock-states)))
                                (lts-edges lts)))))
    lts))

;; ^ ^ ^ ^ ^   l i v e l o c k   c h e c k   ^ ^ ^ ^ ^

(define (annotate-exclude nodes excludes)
  (vector-for-each (lambda (i n) (set-node-color! n (pair? (filter (cut member <> excludes) (map edge-label (node-succ n)))))) nodes))

(define (remove-illegal nodes)
  (define (to-exclude? edge)
    (node-color (vector-ref nodes (edge-end-state edge))))
  (begin
   (annotate-exclude nodes (list "<declarative-illegal>"))
   (list->vector (map (lambda (n) (let ((new-node (clone-node n)))
                                    (set-node-succ! new-node (filter (negate to-exclude?) (node-succ n)))
                                    new-node))
                      (vector->list nodes)))))

(define (remove-info-edges nodes)
  (define (info-edge? edge)
    (or (string-prefix? "<state>" (edge-label edge))
        (string-prefix? "tag(" (edge-label edge))))
  (define (remove-info node)
    (let ((new-node (clone-node node)))
      (set-node-succ! new-node (filter (negate info-edge?) (node-succ node)))
      new-node))
  (list->vector (map remove-info (vector->list nodes))))

(define (remove-tag-edges nodes)
  (define (tag-edge? edge)
    (string-prefix? "tag(" (edge-label edge)))
  (define (remove-tag node)
    (let ((new-node (clone-node node)))
      (set-node-succ! new-node (filter (negate tag-edge?) (node-succ node)))
      new-node))
  (list->vector (map remove-tag (vector->list nodes))))

(define (deadlock-nodes nodes)
  "States without outgoing edges"
  (let* ((nodes (remove-info-edges nodes)))
    (define (has-deadlock? state)
      (null? (filter
              (lambda (e) ((negate node-color) (vector-ref nodes (edge-end-state e))))
              (node-succ (vector-ref nodes state)))))
    (annotate-exclude nodes (list "<declarative-illegal>"))
    (filter has-deadlock?
            (filter (compose not node-color (cut vector-ref nodes <>))
                    (sort (iota (vector-length nodes))
                          (lambda (a b) (< (node-distance (vector-ref nodes a))
                                           (node-distance (vector-ref nodes b)))))))))

(define (assert-deadlock nodes)
  "Trace to node without outgoing edges or #f if no deadlock found"
  (let* ((deadlock-nodes (deadlock-nodes nodes))
         (deadlock-trace (and (not (null? deadlock-nodes)) (trace nodes (car deadlock-nodes)))))
    (if (null? deadlock-nodes) #f
        deadlock-trace)))

(define (assert-unreachable lts tags)
  "Return any TAGS that are not present in LTS."
  (let* ((edges (lts-edges lts))
         (labels (map edge-label edges))
         (lts-tages (filter (cut string-prefix? "tag(" <>) labels))
         (lts-tages (delete-duplicates lts-tages))
         (missing-tags (filter (negate (cut member <> lts-tages)) tags))
         (missing-tags (delete-duplicates missing-tags)))
    (if (null? missing-tags) #f
        missing-tags)))

(define (illegal-nodes nodes)
  "States with labels of illegal outgoing edges."
  (define (has-illegal? state)
    (find (cute equal? <> "<illegal>") (map edge-label (node-succ (vector-ref nodes state)))))
  (filter has-illegal?
   (sort (iota (vector-length nodes))
         (lambda (a b) (< (node-distance (vector-ref nodes a))
                          (node-distance (vector-ref nodes b)))))))

(define (assert-illegal nodes)
  "Trace to nodes without outgoing edges or #f if no deadlock found"
  (let* ((illegal-nodes (illegal-nodes nodes))
         (illegal-trace (and (not (null? illegal-nodes)) (trace nodes (car illegal-nodes)))))
    (if (null? illegal-nodes) #f
        illegal-trace)))

(define (assert-partially-deterministic lts labels)
  "Trace to non-deterministic state extended with non-det edge or #f
if no non-deterministic states found. Only transitions with LABELS are
required to be non-deterministic."
  (define (edge-canonical-label edge)
    (let ((label (edge-label edge)))
      (if (string-prefix? "<state>" label) "<state>" label)))
  (define (nondet-edge-sets lts)
    "Sets of edges with identical start-state and label"
    (let* ((edges (lts-edges lts))
           (edges (sort edges (lambda (a b) (or (< (edge-start-state a) (edge-start-state b))
                                                (and (= (edge-start-state a) (edge-start-state b))
                                                     (string<? (edge-canonical-label a) (edge-canonical-label b)))))))
           (equivalent-edge (lambda (a b) (and (= (edge-start-state a) (edge-start-state b))
                                               (equal? (edge-canonical-label a) (edge-canonical-label b)))))
           (nondet-edges (if (null? edges) '()
                             (fold (lambda (elem prev)
                                     (if (and (equivalent-edge (car (car prev)) elem))
                                         (cons (cons elem (car prev)) (cdr prev))
                                         (cons (list elem) prev)))
                                   (list (list (car edges)))
                                   (cdr edges)))))
      (filter (lambda (es) (> (length es) 1)) nondet-edges)))
  (let* ((witness-edge-sets (nondet-edge-sets lts))
         (witness-edge-sets (map (lambda (wes) (filter (lambda (e) (member (edge-canonical-label e) labels)) wes)) witness-edge-sets))
         (witness-edge-sets (filter (negate null?) witness-edge-sets))
         (nondet-states (map (compose edge-start-state car) witness-edge-sets)))
    (if (null? nondet-states) #f
        (let* ((nodes (lts->nodes lts))
               (nondet-traces (map (cut trace nodes <>) nondet-states))
               (witness-traces
                 (map (lambda (trc wes)
                   (append trc
                     (if (equal? (edge-canonical-label (car wes)) "<state>") '()
                         (list (car wes)))))
                   nondet-traces witness-edge-sets)))
          (car witness-traces)))))

(define (assert-deterministic lts)
  "Trace to non-deterministic state extended with non-det edge or #f if no non-deterministic states found"
  ;; ASSUMPTION: valid only for Dezyne-specific lts generated from lps2lts before ltsconvert
  (define (nondet-edge-sets lts)
    "Sets of edges with identical start-state and label"
    (let* ((edges (lts-edges lts))
           (edges (sort edges (lambda (a b) (or (< (edge-start-state a) (edge-start-state b))
                                                (and (= (edge-start-state a) (edge-start-state b))
                                                     (string<? (edge-label a) (edge-label b)))))))
           (equivalent-edge (lambda (a b) (and (= (edge-start-state a) (edge-start-state b))
                                               (equal? (edge-label a) (edge-label b)))))
           (nondet-edges (if (null? edges) '()
                             (fold (lambda (elem prev)
                                     (if (and (equivalent-edge (car (car prev)) elem))
                                         (cons (cons elem (car prev)) (cdr prev))
                                         (cons (list elem) prev)))
                                   (list (list (car edges)))
                                   (cdr edges)))))
      (filter (lambda (es) (> (length es) 1)) nondet-edges)))
  (let* ((witness-edge-sets (nondet-edge-sets lts))
         (nondet-states (map (compose edge-start-state car) witness-edge-sets)))
    (if (null? nondet-states) #f
        (let* ((nodes (lts->nodes lts))
               (nondet-traces (map (cut trace nodes <>) nondet-states))
               (witness-traces (map (lambda (trc wes) (append trc (list (car wes)))) nondet-traces witness-edge-sets)))
          (car witness-traces)))))

(define (step-tau lts)
  "LTS which has progressed by following tau edges until stable state reached"
  ;; pre-condition: LTS shall not contain tau-loops
  (let* ((succ (edges->successor-edge-vector (lts-states lts) (lts-edges lts)))
         (tau-edges (lambda (state) (filter edge-tau? (vector-ref succ state))))
         (stable? (lambda (state) (null? (tau-edges state)))))
    (let it ((states (lts-state lts)))
      (let* ((stable-states (filter stable? states))
             (unstable-states (filter (negate stable?) states))
             (tau-edges (append-map tau-edges unstable-states))
             (tau-targets (map edge-end-state tau-edges)))
        (if (null? unstable-states) (make-lts stable-states (lts-states lts) (lts-edges lts))
            (it (append stable-states tau-targets)))))))

(define (step lts event)
  "LTS which has progressed by following edges labelled with EVENT"
  ;; pre-condition: LTS shall be in a stable state
  ;; pre-condition: LTS shall not contain tau loops
  ;; post-condition: LTS is in a stable state
  (let* ((acceptance-sets (lts-accept-edge-sets lts))
         (edges (append-map (lambda (as) (filter (lambda (e) (equal? (edge-label e) event)) as)) acceptance-sets))
         (states (delete-duplicates (map edge-end-state edges)))
         (lts (make-lts states (lts-states lts) (lts-edges lts))))
    (step-tau lts)))

(define (run lts trace) ;; public
  "LTS in state reached by performing TRACE"
  ;; pre-condition: LTS shall be in stable state (call (step-tau lts) establishes this condition)
  ;; post-condition: LTS is in a stable state
  (if (or (null? (lts-state lts)) (null? trace)) lts
      (run (step lts (car trace)) (cdr trace))))

;; - - - - -   i n t r o d u c e   f a i l u r e s - - - - -
;;

(define (optional? e)
  (or (equal? (edge-label e) "optional")
      (string-suffix? ".optional" (edge-label e))
      (string-suffix? "'optional" (edge-label e))
      (string-suffix? "'optional)" (edge-label e))))

(define (inevitable? e)
  (or (equal? (edge-label e) "inevitable")
      (string-suffix? ".inevitable" (edge-label e))
      (string-suffix? "'inevitable" (edge-label e))
      (string-suffix? "'inevitable)" (edge-label e))))

(define (replace-model-with-tau e)
  (if (or (optional? e) (inevitable? e))
      (make-edge_ (edge-start-state e) "tau" #t (edge-end-state e))
      e))

(define (add-failures lts)
  (let* ((nr-states (vector-length lts))
         (lts-list (vector->list lts))
         (add (filter (lambda (n) (not (null? (filter optional? (node-succ n))))) lts-list))
         (add (map (lambda (n) (let ((new-node (clone-node n)))
                                 (set-node-succ! new-node (filter (negate optional?) (node-succ n)))
                                 new-node))
                   add)))
    (fold (lambda (node state)
            (let* ((org-node (vector-ref lts (node-state node))))
              (set-node-succ! org-node (cons (make-edge (node-state org-node) "tau" state) (map clone-edge (node-succ org-node))))
              (set-node-state! node state)
              (for-each (lambda (e) (set-edge-start-state! e state)) (node-succ node))
              (1+ state))) nr-states add)
    (let ((lts-list (append lts-list add)))
      (for-each (lambda (n) (set-node-succ! n (map replace-model-with-tau (node-succ n)))) lts-list)
      (list->vector lts-list))))

(define aut-header-regex (make-regexp "^des [(]([0-9]+),([0-9]+),([0-9]+)[)]"))
(define edge-regex (make-regexp "[(]([0-9]+),[\"](.*)[\"],([0-9]+)[)]"))


;;;
;;; Generate traces.
;;;

(define %fout-inc 0)

(define node-allowed-end? node-color)
(define set-node-allowed-end?! set-node-color!)
(define node-close node-parent)
(define set-node-close! set-node-parent!)

(define-record-type <transition>
  (make-transition from label to)
  transition?
  (from transition-from set-transition-from!)
  (label transition-label)
  (to transition-to set-transition-to!))

(define* (generate-trace root nodes provides-ports provides-in fout out #:key verbose?)

  (define (allowed-end? node)
    (define (label-provides-in? label)
      (and (pair? provides-in)
           (member label provides-in)))
    (define (get-port label)
      (car (string-split label #\.)))
    (define (idle-node? node)
      (let* ((labels (map edge-label (node-succ node)))
             (labels (filter label-provides-in? labels))
             (ports (map get-port labels))
             (ports (delete-duplicates ports string=?)))
       (= (length ports)
          (length provides-ports))))
    (or (equal? (node-state node) (1- (vector-length nodes)))
        (and (idle-node? node)
             (not (find (lambda (e) (or (equal? "<ack>" (edge-label e))
                                        (equal? "<defer>" (edge-label e))))
                        (node-succ node))))))

  (define (annotate)
    (let* ((frontier (map node-state
                          (filter (lambda (node)
                                    (set-node-allowed-end?! node (allowed-end? node))
                                    (node-allowed-end? node))
                                  (vector->list nodes)))))
      (define (extend-frontier index)
        (let loop ((edges (node-pred (vector-ref nodes index))))
          (if (null? edges) '()
              (let* ((edge (car edges))
                     (node-index (edge-start-state edge))
                     (node (vector-ref nodes node-index)))
                (if (node-close node) (loop (cdr edges))
                    (begin
                      (set-node-close! node edge)
                      (cons node-index (loop (cdr edges)))))))))
      (let loop ((frontier frontier))
        (when (pair? frontier)
          (let ((index (car frontier)))
            (loop (append (cdr frontier) (extend-frontier index))))))))

  (let ((done (make-hash-table))
        (dir (if (equal? out "-") ""
                 (format #f "~a/" out))))

    (define (trace-extend trace label)
      (if (member label (list "tau" "<ack>")) trace
          (append trace (list label))))

    (define (trace-close trace index)
      (let* ((node (vector-ref nodes index))
             (close-edge (node-close node)))
        (if (or (node-allowed-end? node)
                (not close-edge))
            trace
            (let ((ext-trace (trace-extend trace (edge-label close-edge))))
              (trace-close ext-trace (edge-end-state close-edge))))))

    (define (trace-log trace)
      (let ((file-name (format #f "~a~a.~a" dir fout %fout-inc)))
        (when verbose?
          (format (current-error-port) "~a\n" file-name))
        (let ((port (if (equal? out "-") (current-output-port)
                        (open-output-file file-name))))
          (display (string-join trace "\n" 'suffix) port)))
      (set! %fout-inc (1+ %fout-inc)))

    (define (step index trace)
      (let ((generated-trace? #f))
        (and (not (hashq-ref done index #f))
             (let ((node (vector-ref nodes index)))
               (hashq-set! done index #t)
               (let loop ((edges (node-succ node)) (generated-trace? #f))
                 (if (null? edges) generated-trace?
                     (let* ((edge (car edges))
                            (edge-index (edge-end-state edge)))
                       (if (= edge-index index) (loop (cdr edges) generated-trace?)
                           (let ((ext-trace (trace-extend trace (edge-label edge))))
                             (when (not (step edge-index ext-trace))
                               (trace-log (trace-close ext-trace edge-index)))
                             (loop (cdr edges) #t))))))))))

    (annotate)
    (step root '())))

(define* (lts->traces data illegal? flush? interface out model provides-ports
                      provides-in
                      #:key verbose?)
  (let* ((provides-ports (if (not interface) provides-ports
                             (list model)))
         (interface (and interface model)))

    (define (label-convert label)
      (let ((label (if (or flush? (not (string-contains label "<flush>")))
                       label
                       "tau"))
            (interface-port (and interface (last (string-split interface #\.)))))
        (match (string-split label #\.)
          (((? (cut equal? <> interface-port)) label) label)
          (((? (cut member <> provides-ports)) "<flush>") "tau")
          (_ label))))

    (define (illegal-edge edge)
      (equal? (edge-label edge) "<illegal>"))

    (define (add-illegal-state lts)
      (let ((illegal-state (lts-states lts)))
        (define ((convert-edge illegal-state) edge)
          (when (and illegal? (illegal-edge edge))
            (set-edge-end-state! edge illegal-state))
          (set-edge-label! edge (label-convert (edge-label edge))))
        (for-each (convert-edge illegal-state) (lts-edges lts))
        (set-lts-states! lts (1+ illegal-state))
        lts))

    (define (remove-edges-to-illegal lts)
      (if illegal?
          lts
          (let ((illegal-nodes (map edge-end-state (delete-duplicates (filter illegal-edge (lts-edges lts))))))
            (set-lts-edges! lts
                            (filter (lambda (edge) (not (member (edge-end-state edge) illegal-nodes))) (lts-edges lts)))))
      lts)

    (let* ((lts (aut-text->lts (string-join data "\n")))
           (lts (remove-edges-to-illegal (add-illegal-state lts)))
           (nodes (lts->nodes lts #t))
           (nodes (remove-info-edges nodes))
           (root (car (lts-state lts))))
      (generate-trace root nodes provides-ports provides-in
                      (string-append model ".trace") out #:verbose? verbose?))))


;;;
;;; Cleanup.
;;;

(define (parse-label label)
  (define-peg-string-patterns
    "tree               <-- event / modeling / defer-qout / tag / reply / state / return / queue / tau-literal / illegal / error / end / flush / blocking / parse-error
     parse-error        <-- [a-zA-Z_0-9'()]*
     event              <-- port-name tick direction lpar scope* action-literal lpar scope* direction tick event-name rpar rpar
     modeling           <-- port-name tick internal-literal lpar scope* ('inevitable' / 'optional') rpar
     queue              <-- port-name tick queue-direction lpar scope* action-literal lpar scope* direction tick event-name rpar rpar
     end                <   scope* ('end' / 'silent_end')
     return             <-- 'return'
     flush              <-- port-scope* identifier tick 'flush'
     blocking           <-- port-scope* identifier tick 'blocking'
     reply              <-- port-name tick reply-literal lpar scope* reply-value rpar
     state              <-- port-name tick state-literal state-arguments
     state-arguments    <-  (lpar state-argument (comma state-argument)* rpar)?
     state-argument     <-- bool / int / enum-literal
     scope              <   identifier tick
     tag                <   tag-literal lpar int comma int rpar
     port-name          <-  port-scope* identifier
     port-scope         <   scope !(internal-literal / queue-direction / direction / reply-literal / state-literal / 'queue_full' / 'flush' / 'blocking')
     event-name         <-  identifier
     reply-value        <-  bool-literal lpar bool rpar / lpar enum-literal rpar / int-literal lpar int rpar / void-literal lpar void rpar
     bool-literal       <   'Bool'
     bool               <-- ('true' / 'false' )
     int-literal        <   'Int'
     int                <-- '-'?[0-9]+
     void-literal       <   'Void'
     void               <-- 'void'
     enum-name          <   identifier
     enum-literal       <-- (enum tick)* enum-field
     enum               <-  identifier
     enum-field         <-  identifier
     direction          <   ('qin' / 'in' / 'out') !identifier
     defer-qout         <-- 'defer_qout' paren-arguments
     paren-arguments    <   lpar ((!(lpar / rpar) .)* paren-arguments*)* rpar
     queue-direction    <-- 'qout'
     action-literal     <   'action'
     internal-literal   <   'internal' / 'silent'
     reply-literal      <   'reply'
     state-literal      <   'state'
     tag-literal        <   'tag'
     tau-literal        <   'tau'
     illegal            <-- 'illegal' / 'declarative_illegal'
     error              <-- queue-full / range-error / reply-error / missing-reply / second-reply
     queue-full         <-  'queue_full' / port-name tick 'queue_full'
     range-error        <-  'range_error'
     reply-error        <-  'double_reply_error' / 'no_reply_error'
     missing-reply      <-  'missing_reply'
     second-reply       <-  'second_reply'
     tick               <   [']
     lpar               <   [(]
     rpar               <   [)]
     comma              <   [,][ ]*
     identifier         <-- &(direction [a-zA-Z0-9_]+) [a-zA-Z0-9_]+ / !direction [a-zA-Z_][a-zA-Z0-9_]*")
  (let* ((match (match-pattern tree label))
         (end (peg:end match))
         (tree (peg:tree match)))
    (if (eq? (string-length label) end)
        (if (symbol? tree) '()
            (cdr tree))
        (if match
            (begin
              (format (current-error-port) "input: ~a\nparse error: at offset: ~a\n~s\n" label end tree)
              #f)
            (begin
              (format (current-error-port) "parse error: no match\n")
              #f)))))

(define (cleanup-error e)
  (string-append "<" (string-map (lambda (c) (if (eq? c #\_) #\- c)) e) ">"))

(define* (cleanup-label label #:key internal? illegal?)
  (define (helper-params parameters)
    (let* ((parameters (if (pair? (car parameters)) parameters (list parameters))))
      (string-join (map helper parameters) ",")))
  (define (helper tree)
    (match tree
      (('parse-error parse-error) (format (current-error-port) "parse error:~s\n" tree) parse-error)
      (('defer-qout label) "<defer>")
      (('error error) (cleanup-error error))
      (('error ('identifier port) error) (cleanup-error error))
      (('event ('identifier port) ('identifier event)) (string-append port "." event))
      (('flush ('identifier port) "flush") (string-append port ".<flush>"))
      (('blocking ('identifier port) "blocking") (string-append port ".<blocking>"))
      (('illegal illegal) (and illegal? (cleanup-error illegal)))
      (('modeling ('identifier port) event) (and internal? (string-append port "." event)))
      (('queue ('identifier port) ('queue-direction direction) ('identifier event)) (and internal? (string-append port "." direction "." event)))
      (('reply ('identifier port) ('void "void")) (string-append port ".return"))
      (('reply ('identifier port) ('bool value)) (string-append port "." value))
      (('reply ('identifier port) ('int value)) (string-append port "." value))
      (('reply ('identifier port) ('enum-literal scope ... ('identifier name) ('identifier field))) (string-append port "." name ":" field))
      (('reply ('identifier port) ('enum-literal (scope ... ('identifier name)) ('identifier field))) (string-append port "." name ":" field))
      (('return return) (and internal? "return"))
      (('state ('identifier port) parameters) (string-append port ".<state>(" (helper-params parameters) ")"))
      (('state ('identifier port)) (string-append port ".<state>"))
      (('state-argument value) (helper value))
      (('bool value) value)
      (('int value) value)
      (('enum-literal  scope ... ('identifier name)  ('identifier field)) (string-append name ":" field))
      (('enum-literal (scope ... ('identifier name)) ('identifier field)) (string-append name ":" field))
      ((h) (helper h))
      (_ label)))
  (or (helper (parse-label label)) "tau"))

(define memoizing-cleanup-label
  (pure-funcq
   (lambda* (label #:key internal? illegal? prefix)
     (let ((prefix-length (and prefix (string-length prefix))))
       (define (drop-prefix o)
         (if (and prefix (string-prefix? prefix o)) (substring o prefix-length)
             o))
       (format #f "\"~a\""
               (drop-prefix (cleanup-label (symbol->string label)
                                           #:illegal? illegal?
                                           #:internal? internal?)))))))


;;;
;;; Entry points.
;;;

(define* (cleanup-aut #:key file-name (illegal? #t) (internal? #t) prefix)
  (let ((input-port (if file-name (open-input-file file-name) (current-input-port)))
        (label-re (make-regexp "\"([^\"]*)\"")))
    (let loop ((line (read-line input-port 'concat)))
      (unless (eof-object? line)
        (let ((out-line (regexp-substitute/global
                         #f label-re line
                         'pre
                         (compose (cute memoizing-cleanup-label <>
                                        #:illegal? illegal?
                                        #:internal? internal?
                                        #:prefix prefix)
                                  string->symbol
                                  (cute match:substring <> 1))
                         'post)))
          (display out-line))
        (loop (read-line input-port 'concat))))))

(define* (display-lts lts #:key (separator "\n"))
  (let* ((edges (append-map node-succ (vector->list lts)))
         (header (format #f "des (~a,~a,~a)"
                         (root lts)
                         (length edges)
                         (vector-length lts)))
         (lines (map
                 (lambda (e)
                   ;; format has a significant performance impact on
                   ;; large LTSs.
                   (string-append
                    "("
                    (number->string (edge-start-state e)) ","
                    "\"" (edge-label e) "\","
                    (number->string (edge-end-state e))
                    ")"))
                 edges))
         (lines (cons header lines))
         (text (string-join lines separator)))
    (display text)))
