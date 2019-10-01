;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; Code:

(define-module (gaiag lts)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-43)
  #:export (add-failures
            assert-deadlock
            assert-deterministic
            assert-file-exists
            assert-illegal
            assert-livelock
            assert-partially-deterministic
            aut-edge-label
            aut-file->lts
            aut-header-regex
            lts->nodes
            lts-hide
            <lts>
            make-aut-edge
            make-lts
            lts-edges
            lts-state
            lts-states
            text->aut-header
            text-file->aut-header
            write-lts))

(define %version "git")

(define (assert-file-exists file)
  (if (not (access? file R_OK))
      (begin (format (current-error-port) "File not found: ~a\n" file)
             #f)
      file))

;; ===== text-file =====
(define (text-file->line-list text)
  (map (cut string-trim-right <> #\cr) (string-split text #\newline)))

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

(define-record-type <aut-edge>
  (make-aut-edge_ start-state label tau? end-state)
  aut-edge?
  (start-state aut-edge-start-state set-aut-edge-start-state!)
  (label aut-edge-label)
  (tau? aut-edge-tau?)
  (end-state aut-edge-end-state))

;; (define aut-edge-regex (make-regexp "[(]([0-9]+),[\"](.*)[\"],([0-9]+)[)]"))
;; (define (text->aut-edge text)
;;   (let* ((rem (regexp-exec aut-edge-regex text))
;;          (start-state (and rem (string->number (match:substring rem 1))))
;;          (label (and rem (match:substring rem 2)))
;;          (end-state (and rem (string->number (match:substring rem 3)))))
;;     (and start-state label end-state (make-aut-edge start-state label end-state))))
;; (define (test:text->aut-edge)
;;   (and (text->aut-edge "(0,\"aap\",1)")
;;        (not (text->aut-edge "des (0,1,2)"))))
(define (text->aut-edge text)
  (let* ((first-paren 0)
         (last-paren (string-length text))
         (first-comma (string-index text #\,))
         (last-comma (string-rindex text #\,))
         (start-state (string->number (string-copy text (1+ first-paren) first-comma)))
         (label (string-copy text (+ 2 first-comma) (1- last-comma)))
         (end-state (string->number (string-copy text (1+ last-comma) (1- last-paren)))))
    (make-aut-edge start-state label end-state)))

(define (make-aut-edge start-state label end-state)
  (make-aut-edge_ start-state
                  label
                  (or (and (symbol? label) (equal? 'tau label))
                      (and (string? label) (string= label "tau")))
                  end-state))

(define (clone-aut-edge e)
  (make-aut-edge_ (aut-edge-start-state e) (aut-edge-label e) (aut-edge-tau? e) (aut-edge-end-state e)))

(define (states edges)
  "List of states referenced in edges."
  (sort (delete-duplicates (append (map aut-edge-start-state edges) (map aut-edge-end-state edges))) <))

(define (edges->successor-edge-vector states edges)
  "Vector with successor edges per node"

  (define (bin result state-nrs edges)
    (if (null? state-nrs) result
        (let* ((state (car state-nrs))
               (parts (receive (state-edges other-edges)
                          (span (lambda (e) (= state (aut-edge-start-state e))) edges)
                        (cons state-edges other-edges)))
               (head (car parts))
               (tail (cdr parts)))
          (bin (cons head result) (cdr state-nrs) tail))))

  (list->vector (bin '()
                     (reverse (iota states))
                     (sort edges (lambda (a b) (> (aut-edge-start-state a) (aut-edge-start-state b)))))))

(define (edges->predecessor-edge-vector states edges)
  "Vector with predecessor edges per node"

  (define (bin result state-nrs edges)
    (if (null? state-nrs) result
        (let* ((state (car state-nrs))
               (parts (receive (state-edges other-edges)
                          (span (lambda (e) (= state (aut-edge-end-state e))) edges)
                        (cons state-edges other-edges)))
               (head (car parts))
               (tail (cdr parts)))
          (bin (cons head result) (cdr state-nrs) tail))))

  (list->vector (bin '()
                     (reverse (iota states))
                     (sort edges (lambda (a b) (> (aut-edge-end-state a) (aut-edge-end-state b)))))))

;; - - - - -   l t s   - - - - -
(define-record-type <lts>
  (make-lts state states edges)
  lts?
  (state lts-state) ;; list of numbers (state identifiers)
  (states lts-states) ;; number of states in lts
  (edges lts-edges) ;; list of <aut-edge>
  )

(define (lts-succ lts state)
  "Edges transitioning from STATE"
  (filter (lambda (e) (= state (aut-edge-start-state e))) (lts-edges lts)))

(define (lts-pred lts state)
  "Edges transitioning into STATE"
  (filter (lambda (e) (= state (aut-edge-end-state e))) (lts-edges lts)))

(define (aut-file->lts text)
  "List starting with one <aut-header> followed by multiple <aut-edge>"
  (let* ((rm-empty-lines (lambda (lines) (filter (lambda (l) (not (equal? "" l))) lines)))
         (lines (rm-empty-lines (text-file->line-list text)))
         (header (car lines))
         (edges (cdr lines)))
    (make-lts (list (aut-header-first-state  (text->aut-header header)))
              (aut-header-nr-states (text->aut-header header))
              (map text->aut-edge edges))))

(define (lts-hide lts tau)
  "Mark edges labeled with name occurring in TAU as tau-edge."
  (make-lts (lts-state lts)
            (lts-states lts)
            (map (lambda (edge) (if (or (member (aut-edge-label edge) tau)
                                        (not (null? (filter (cut string-prefix? <> (aut-edge-label edge))
                                                            (map (cut string-append <> "(") tau)))))
                                    (make-aut-edge_ (aut-edge-start-state edge)
                                                    (aut-edge-label edge)
                                                    #t
                                                    (aut-edge-end-state edge))
                                    edge))
                 (lts-edges lts))))

(define (lts->alphabet lts)
  "List of non-tau edge labels found in lts"
  (delete-duplicates (map aut-edge-label (filter (negate aut-edge-tau?) (lts-edges lts)))))

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
              (stable-acceptance-sets (map (lambda (edge-set) (delete-duplicates (map aut-edge-label edge-set)))
                                           acceptance-sets)))
         (delete-duplicates stable-acceptance-sets))))

;; v v v v v   l i v e l o c k   c h e c k   v v v v v

(define-record-type <node>
  (make-node state succ pred root? color parent distance cycle)
  node?
  (state node-state set-node-state!)
  (succ node-succ set-node-succ!) ;; (<aut-edge>)
  (pred node-pred)
  (root? node-root?)
  (color node-color set-node-color!) ;; integer
  (parent node-parent set-node-parent!) ;; aut-edge from parent
  (distance node-distance set-node-distance!) ;; -1 signifies infinite distance (unreachable)
  (cycle node-cycle set-node-cycle!) ;; aut-edge to previous node in tau-loop
  )

(define (clone-node n)
  (make-node (node-state n) (node-succ n) (node-pred n) (node-root? n) (node-color n) (node-parent n) (node-distance n) (node-cycle n)))

(define test-lts-livelock
  (make-lts '(0)
            5
            (list (make-aut-edge_ 0 "aap" #f 1)
                  (make-aut-edge_ 1 "return" #f 0)
                  (make-aut-edge_ 0 "blaat" #t 2)
                  (make-aut-edge_ 2 "noot" #f 3)
                  (make-aut-edge_ 2 "blaat" #t 3)
                  (make-aut-edge_ 3 "tau" #t 3)
                  (make-aut-edge_ 3 "live" #t 4)
                  (make-aut-edge_ 4 "lock" #t 3)
                  (make-aut-edge_ 3 "mies" #f 0))))
(define test-lts-livelock-2
  (make-lts '(1)
            3
            (list (make-aut-edge_ 0 "tau" #t 0)
                  (make-aut-edge_ 2 "BlindLoop'return(BlindLoop'in'start, reply_BlindLoop'Void(void))" #f 0)
                  (make-aut-edge_ 1 "BlindLoop'event(BlindLoop'in'start)" #f 2))))

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
                  (succ (filter (lambda (edge) (= -1 (node-distance (vector-ref nodes (aut-edge-end-state edge))))) succ))
                  (next-frontier (fold (lambda (edge next-frontier)
                                         (let ((node (vector-ref nodes (aut-edge-end-state edge))))
                                           (set-node-distance! node (1+ distance))
                                           (set-node-parent! node edge)
                                           (cons (aut-edge-end-state edge) next-frontier)))
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

(define (lts->nodes lts)
  "Vector of <node> representing LTS"
  (let* ((states (iota (lts-states lts)))
         (roots (lts-state lts))
         (succ (edges->successor-edge-vector (lts-states lts) (lts-edges lts)))
         (pred (vector)) ;;(pred (edges->predecessor-edge-vector (lts-states lts) (lts-edges lts)))
         (nodes (map (lambda (state) (make-node state
                                                (vector-ref succ state)
                                                #f ;; (vector-ref pred state)
                                                (if (memv state roots) #t #f)
                                                WHITE
                                                #f
                                                -1
                                                #f))
                     states))
         (nodes (list->vector nodes)))
    (annotate-parent nodes)))

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
            (if (= (node-color node) WHITE) (let* ((tau-edges (filter aut-edge-tau? (node-succ node))))
                                              (set-node-color! node GREY)
                                              (set-node-cycle! node entry-edge)
                                              (for-each (lambda (e) (loop-detect (aut-edge-end-state e) e)) tau-edges)
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
            (trace-it (aut-edge-start-state parent) (cons parent edges)))))
    (trace-it state '())))

(define (tau-loop loop-entry-state nodes)
  "Loop of events leading from LOOP-ENTRY-STATE back to LOOP-ENTRY-STATE"
  (define (loop-edges trace state)
    (let* ((predecessor-edge (node-cycle (vector-ref nodes state)))
           (predecessor-state (aut-edge-start-state predecessor-edge))
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
        (append (or loop-entry-trace '()) (or loop-trace '())))))

(define (rm-tau-loops lts)
  "Remove all edges starting in a tau-loop entry state. (Promotes
livelock to deadlock.)"
  (let* ((livelock-states (lts-tau-loops (lts->nodes lts)))
         (lts (make-lts (lts-state lts)
                        (lts-states lts)
                        (filter (lambda (e) (not (memv (aut-edge-start-state e) livelock-states)))
                                (lts-edges lts)))))
    lts))

;; ^ ^ ^ ^ ^   l i v e l o c k   c h e c k   ^ ^ ^ ^ ^

(define (annotate-exclude nodes excludes)
  (vector-for-each (lambda (i n) (set-node-color! n (pair? (filter (cut member <> excludes) (map aut-edge-label (node-succ n)))))) nodes))

(define (remove-illegal nodes)
  (define (to-exclude? edge)
    (node-color (vector-ref nodes (aut-edge-end-state edge))))
  (begin
   (annotate-exclude nodes (list "dillegal"))
   (list->vector (map (lambda (n) (let ((new-node (clone-node n)))
                                    (set-node-succ! new-node (filter (negate to-exclude?) (node-succ n)))
                                    new-node))
                      (vector->list nodes)))))

(define (deadlock-nodes nodes)
  "States without outgoing edges"
  (define (has-deadlock? state)
      (null? (filter (lambda (e) ((negate node-color) (vector-ref nodes (aut-edge-end-state e)))) (node-succ (vector-ref nodes state)))))
  (begin
    (annotate-exclude nodes (list "dillegal"))
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

(define (illegal-nodes nodes illegals)
  "States with labels of outgoing edges contained in illegals"
  (define (has-illegal? state)
    (pair? (filter (cut member <> illegals) (map aut-edge-label (node-succ (vector-ref nodes state))))))
  (filter has-illegal?
   (sort (iota (vector-length nodes))
         (lambda (a b) (< (node-distance (vector-ref nodes a))
                          (node-distance (vector-ref nodes b)))))))

(define (assert-illegal nodes illegals)
  "Trace to nodes without outgoing edges or #f if no deadlock found"
  (let* ((illegal-nodes (illegal-nodes nodes illegals))
         (illegal-trace (and (not (null? illegal-nodes)) (trace nodes (car illegal-nodes)))))
    (if (null? illegal-nodes) #f
        illegal-trace)))

(define (assert-partially-deterministic lts labels)
  "Trace to non-deterministic state extended with non-det edge or #f
if no non-deterministic states found. Only transitions with LABELS are
required to be non-deterministic."
  (define (nondet-edge-sets lts)
    "Sets of edges with identical start-state and label"
    (let* ((edges (lts-edges lts))
           (edges (sort edges (lambda (a b) (or (< (aut-edge-start-state a) (aut-edge-start-state b))
                                                (and (= (aut-edge-start-state a) (aut-edge-start-state b))
                                                     (string<? (aut-edge-label a) (aut-edge-label b)))))))
           (equivalent-edge (lambda (a b) (and (= (aut-edge-start-state a) (aut-edge-start-state b))
                                               (equal? (aut-edge-label a) (aut-edge-label b)))))
           (nondet-edges (fold (lambda (elem prev)
                                 (if (and (equivalent-edge (car (car prev)) elem))
                                     (cons (cons elem (car prev)) (cdr prev))
                                     (cons (list elem) prev)))
                               (list (list (car edges)))
                               (cdr edges))))
      (filter (lambda (es) (> (length es) 1)) nondet-edges)))
  (let* ((witness-edge-sets (nondet-edge-sets lts))
         (witness-edge-sets (map (lambda (wes) (filter (lambda (e) (member (aut-edge-label e) labels)) wes)) witness-edge-sets))
         (witness-edge-sets (filter (negate null?) witness-edge-sets))
         (nondet-states (map (compose aut-edge-start-state car) witness-edge-sets)))
    (if (null? nondet-states) #f
        (let* ((nodes (lts->nodes lts))
               (nondet-traces (map (cut trace nodes <>) nondet-states))
               (witness-traces (map (lambda (trc wes) (append trc (list (car wes)))) nondet-traces witness-edge-sets)))
          (car witness-traces)))))

(define (assert-deterministic lts)
  "Trace to non-deterministic state extended with non-det edge or #f if no non-deterministic states found"
  ;; ASSUMPTION: valid only for Dezyne-specific lts generated from lps2lts before ltsconvert
  (define (nondet-edge-sets lts)
    "Sets of edges with identical start-state and label"
    (let* ((edges (lts-edges lts))
           (edges (sort edges (lambda (a b) (or (< (aut-edge-start-state a) (aut-edge-start-state b))
                                                (and (= (aut-edge-start-state a) (aut-edge-start-state b))
                                                     (string<? (aut-edge-label a) (aut-edge-label b)))))))
           (equivalent-edge (lambda (a b) (and (= (aut-edge-start-state a) (aut-edge-start-state b))
                                               (equal? (aut-edge-label a) (aut-edge-label b)))))
           (nondet-edges (fold (lambda (elem prev)
                                 (if (and (equivalent-edge (car (car prev)) elem))
                                     (cons (cons elem (car prev)) (cdr prev))
                                     (cons (list elem) prev)))
                               (list (list (car edges)))
                               (cdr edges))))
      (filter (lambda (es) (> (length es) 1)) nondet-edges)))
  (let* ((witness-edge-sets (nondet-edge-sets lts))
         (nondet-states (map (compose aut-edge-start-state car) witness-edge-sets)))
    (if (null? nondet-states) #f
        (let* ((nodes (lts->nodes lts))
               (nondet-traces (map (cut trace nodes <>) nondet-states))
               (witness-traces (map (lambda (trc wes) (append trc (list (car wes)))) nondet-traces witness-edge-sets)))
          (car witness-traces)))))

(define (step-tau lts)
  "LTS which has progressed by following tau edges until stable state reached"
  ;; pre-condition: LTS shall not contain tau-loops
  (let* ((succ (edges->successor-edge-vector (lts-states lts) (lts-edges lts)))
         (tau-edges (lambda (state) (filter aut-edge-tau? (vector-ref succ state))))
         (stable? (lambda (state) (null? (tau-edges state)))))
    (let it ((states (lts-state lts)))
      (let* ((stable-states (filter stable? states))
             (unstable-states (filter (negate stable?) states))
             (tau-edges (append-map tau-edges unstable-states))
             (tau-targets (map aut-edge-end-state tau-edges)))
        (if (null? unstable-states) (make-lts stable-states (lts-states lts) (lts-edges lts))
            (it (append stable-states tau-targets)))))))

(define (step lts event)
  "LTS which has progressed by following edges labelled with EVENT"
  ;; pre-condition: LTS shall be in a stable state
  ;; pre-condition: LTS shall not contain tau loops
  ;; post-condition: LTS is in a stable state
  (let* ((acceptance-sets (lts-accept-edge-sets lts))
         (edges (append-map (lambda (as) (filter (lambda (e) (equal? (aut-edge-label e) event)) as)) acceptance-sets))
         (states (delete-duplicates (map aut-edge-end-state edges)))
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
  (or (equal? (aut-edge-label e) "optional")
      (string-suffix? "'optional" (aut-edge-label e))
      (string-suffix? "'optional)" (aut-edge-label e))))

(define (inevitable? e)
  (or (equal? (aut-edge-label e) "inevitable")
      (string-suffix? "'inevitable" (aut-edge-label e))
      (string-suffix? "'inevitable)" (aut-edge-label e))))

(define (replace-model-with-tau e)
  (if (or (optional? e) (inevitable? e))
      (make-aut-edge_ (aut-edge-start-state e) "tau" #t (aut-edge-end-state e))
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
              (set-node-succ! org-node (cons (make-aut-edge (node-state org-node) "tau" state) (map clone-aut-edge (node-succ org-node))))
              (set-node-state! node state)
              (for-each (lambda (e) (set-aut-edge-start-state! e state)) (node-succ node))
              (1+ state))) nr-states add)
    (let ((lts-list (append lts-list add)))
      (for-each (lambda (n) (set-node-succ! n (map replace-model-with-tau (node-succ n)))) lts-list)
      (list->vector lts-list))))


;; - - - - -   w r i t e   a u t   f i l e - - - - -
(define (write-lts  key single-line start-state lts)
  (let* ((edges (append-map node-succ (vector->list lts)))
         (header (string-join (list "des (" (number->string start-state) "," (number->string (length edges)) "," (number->string (vector-length lts))  ")") ""))
         (lines (map
                 (lambda (e)
                   (string-join (list "(" (number->string (aut-edge-start-state e)) ",\""
                                      (aut-edge-label e) "\","
                                      (number->string (aut-edge-end-state e)) ")") ""))
                 edges)))
    (if single-line (display (string-append key ":" (string-join (cons header lines) ";") "\n"))
        (display (string-join (cons header lines) "\n")))))

;; - - - - -   v a l i d a t e   a u t   f i l e   - - - - -
(define aut-header-regex (make-regexp "^des [(]([0-9]+),([0-9]+),([0-9]+)[)]"))
(define aut-edge-regex (make-regexp "[(]([0-9]+),[\"](.*)[\"],([0-9]+)[)]"))
(define (aut-file-format-error aut-lines)
  "Error text string or #f"
  (if (null? aut-lines)
      "File empty"
      (let* ((aut-lines (map (cut string-delete #\cr <>) aut-lines)) ;strip off 'carriage return' char (MS-DOS compatibility)
             (aut-header (car aut-lines))
             (valid-header? (regexp-exec aut-header-regex aut-header))
             (valid-edges? (not (member #f (map (lambda (line)
                                                  (regexp-exec aut-edge-regex line))
                                                (cdr aut-lines))))))
        (cond ((not valid-header?) "Invalid aut header")
              ((not valid-edges?) "Invalid aut edge")
              (else #f)))))

(define (validate-aut-file text)
  (let* ((rm-empty-lines (lambda (lines) (filter (lambda (l) (not (equal? "" l))) lines)))
         (error (aut-file-format-error (rm-empty-lines (text-file->line-list text)))))
    error))

(define (print-metrics aut-file)
  ;; aut_header ::=  'des (' first_state ',' nr_of_transitions ',' nr_of_states ')'
  (let* ((header-text (with-input-from-file aut-file read-line))
         (header (text->aut-header header-text)))
    (format #t "~a: Number of states: ~a, Number of transitions: ~a\n" aut-file (aut-header-nr-states header) (aut-header-nr-transitions header))))
