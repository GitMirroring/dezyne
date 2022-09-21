;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2018, 2019, 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; TODO:
;;; * functional style
;;;   + reduce use of set! and imperative style;
;;;   + use functional setters and map instead of for-each.
;;;   + make <node> immutable
;;;     - use set-field instead of set-node-*!
;;;   + remove set! (add-failures, lts-tau-loops, ... etc.)
;;;   + use vector-map instead of vector-set! !
;;; * remove edge-from
;;; * remove node-state
;;; * node-succ => node-edges
;;; * move node-pred, node-color, node-parent etc into <node-info> record(s)
;;;
;;; Code:

(define-module (dzn lts)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-43)

  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)

  #:use-module (dzn misc)
  #:use-module (dzn peg)
  #:export (%<declarative-illegal>
            %<illegal>
            add-failures
            assert-deadlock
            assert-illegal
            assert-livelock
            assert-nondeterministic
            assert-unreachable
            aut-text->lts
            cleanup-aut
            cleanup-error
            display-lts
            edge-label
            lts->rtc-lts
            lts->traces
            lts-hide
            make-shared-string
            remove-illegal
            remove-tag-edges))

;;; TODO:
;;; * functional style
;;;   + make <node> immutable
;;;     - use set-field instead of set-node-*!
;;;   + remove set! (add-failures, lts-tau-loops, ... etc.)
;;;   + use vector-map instead of vector-set! !
;;; * remove edge-from
;;; * remove node-state
;;; * node-succ => node-edges
;;; * move node-pred, node-color, node-parent etc into <node-info> record(s)

;;;
;;; Utility.
;;;
(define make-shared-string
  (let ((table (make-hash-table)))
    (lambda (string)
      (or (hash-ref table string)
          (begin
            (hash-set! table string string)
            string)))))

(define %<ack> (make-shared-string "<ack>"))
(define %<declarative-illegal> (make-shared-string "<declarative-illegal>"))
(define %<defer> (make-shared-string "<defer>"))
(define %<flush> (make-shared-string "<flush>"))
(define %<illegal> (make-shared-string "<illegal>"))
(define %<state> (make-shared-string "<state>"))
(define %<queue-full> (make-shared-string "<queue-full>"))
(define %inevitable (make-shared-string "inevitable"))
(define %optional (make-shared-string "optional"))
(define %tau (make-shared-string "tau"))

(define (vector-map-one f vector)
  (vector-map (lambda (i n) (f n)) vector))

(define-immutable-record-type <aut-header>
  (make-aut-header first-state nr-transitions state-count)
  aut-header?
  (first-state aut-header-first-state)
  (nr-transitions aut-header-nr-transitions)
  (state-count aut-header-state-count))

(define aut-header-regex (make-regexp "^des [(]([0-9]+),([0-9]+),([0-9]+)[)]"))
(define (text->aut-header text)
  (let* ((rem (regexp-exec aut-header-regex text))
         (first-state (and rem (string->number (match:substring rem 1))))
         (nr-transitions (and rem (string->number (match:substring rem 2))))
         (state-count (and rem (string->number (match:substring rem 3)))))
    (and initial nr-transitions state-count
         (make-aut-header first-state nr-transitions state-count))))

(define-immutable-record-type <edge>
  (make-edge- from label to tau?)
  edge?
  (from edge-from)
  (label edge-label)
  (to edge-to)
  ;;
  (tau? edge-tau?))

(define (text->edge text)
  (let* ((first-paren 0)
         (last-paren (string-length text))
         (first-comma (string-index text #\,))
         (last-comma (string-rindex text #\,))
         (from (string->number (string-copy text (1+ first-paren) first-comma)))
         (label (string-copy text (+ 2 first-comma) (1- last-comma)))
         (to (string->number (string-copy text (1+ last-comma) (1- last-paren)))))
    (make-edge from label to)))

(define* (make-edge from label to #:key tau?)
  (let ((label (make-shared-string label)))
    (make-edge- from label to (or tau? (eq? %tau label)))))

(define (clone-edge e)
  (make-edge- (edge-from e) (edge-label e) (edge-to e) (edge-tau? e)))

(define (make-edge-loop)
  (make-edge -1 "<loop>" -1 #:tau? #t))

(define (edge-canonical-label edge)
  (let ((label (edge-label edge)))
    (if (string-prefix? "<state>" label) %<state> label)))

(define-record-type <node>
  (make-node state succ pred initial? color parent distance cycle)
  node?
  (state node-state set-node-state!)
  (succ node-succ set-node-succ!)             ; (<edge>)
  (initial? node-initial? set-node-initial?!)
  ;;
  (pred node-pred set-node-pred!)
  (color node-color set-node-color!)          ; integer
  (parent node-parent set-node-parent!)       ; edge from parent
  (distance node-distance set-node-distance!) ; -1 signifies infinite distance (unreachable)
  (cycle node-cycle set-node-cycle!))         ; edge to previous node in tau-loop

(define %white 0)
(define %grey 1)
(define %black 2)

(define node-exclude? node-color)
(define node-type node-color)
(define node-nondet-witness node-color)
(define node-rtc? node-color)
(define set-node-rtc?! set-node-color!)
(define set-node-nondet-witness! set-node-color!)

(define (initial lts)
  "Index (state) of initial node in LTS vector."
  (let it ((state 0))
    (cond ((= (vector-length lts) state) 0)
          ((node-initial? (vector-ref lts state)) state)
          (else (it (1+ state))))))

(define* (construct-lts header edges #:key traces?)
  (define (state->node state)
    (make-node state '() '() #f %white #f -1 #f))
  (let* ((state-count (aut-header-state-count header))
         (lts (list->vector (map state->node (iota state-count)))))
    (for-each
     (lambda (edge)
       (let* ((from (edge-from edge))
              (node (vector-ref lts from)))
         (set-node-succ! node (cons edge (node-succ node))))
       (when traces?
         (let* ((to (edge-to edge))
                (node (vector-ref lts to)))
           (set-node-pred! node (cons edge (node-pred node))))))
     edges)
    (vector-for-each
     (lambda (i node)
       (set-node-succ! node
                       (sort (node-succ node)
                             (lambda (e0 e1)
                               (string<? (edge-canonical-label e0)
                                         (edge-canonical-label e1))))))
     lts)
    (set-node-initial?! (vector-ref lts (aut-header-first-state header)) #t)
    (if traces? lts (annotate-parent lts))))

(define* (aut-text->lts text #:key traces?)
  "Vector of <node> representing LTS"
  (let* ((lines (string-split text #\newline))
         (lines (map (cute string-trim-right <> #\cr) lines))
         (lines (filter (negate string-null?) lines))
         (header (text->aut-header (car lines)))
         (edges (map text->edge (cdr lines))))
    (construct-lts header edges #:traces? traces?)))

(define (aut-file->lts file-name)
  (aut-text->lts (with-input-from-file file-name read-string)))

(define (lts-hide lts tau exclude-tau)
  "Mark edges labeled with name occurring in TAU as tau-edge."
  (let ((tau (map make-shared-string tau))
        (exclude-tau (map make-shared-string exclude-tau)))
    (define (set-edge-tau edge)
      (let ((tau? (and (or (memq (edge-label edge) tau)
                           (find (cut string-prefix? <> (edge-label edge))
                                 (append (map (cute string-append <> ".") tau)
                                         (map (cute string-append <> "(") tau))))
                       (not (memq (edge-label edge) exclude-tau))
                       #t)))
        (set-field edge (edge-tau?) tau?)))
    (define (set-edge-taus node)
      (let ((succ (map set-edge-tau (node-succ node))))
        (set-field node (node-succ) succ)))
    (vector-map-one set-edge-taus lts)))

(define (annotate-parent lts)
  "Set 'parent' and 'distance' from initial-state in each node in LTS"
  (define (update-frontier distance edge next-frontier)
    (let ((node (vector-ref lts (edge-to edge))))
      (set-node-distance! node (1+ distance))
      (set-node-parent! node edge)
      (cons (edge-to edge) next-frontier)))
  (define (annotate-parent-it lts curr-frontier next-frontier)
    (cond ((and (null? curr-frontier)
                (null? next-frontier))
           lts)
          ((and (null? curr-frontier)
                (not (null? next-frontier)))
           (annotate-parent-it lts next-frontier curr-frontier))
          ((not (null? curr-frontier))
           (let* ((state (car curr-frontier))
                  (node (vector-ref lts state))
                  (distance (node-distance node))
                  (succ (node-succ node))
                  (succ (filter (compose (cute =  <> -1)
                                         node-distance
                                         (cute vector-ref lts <>)
                                         edge-to)
                                succ))
                  (next-frontier (fold (cute update-frontier distance <> <>)
                                       next-frontier
                                       succ)))
             (annotate-parent-it lts (cdr curr-frontier) next-frontier)))))
  (let* ((initial-state (initial lts))
         (initial-node (vector-ref lts initial-state)))
    (set-node-distance! initial-node 0)
    (set-node-parent! initial-node #f)
    (annotate-parent-it lts (list initial-state) '())))

(define (iota-distance-sorted lts)
  (sort (iota (vector-length lts))
        (lambda (a b) (< (node-distance (vector-ref lts a))
                         (node-distance (vector-ref lts b))))))


;;;
;;; Livelock.
;;;
(define (lts-tau-loops lts)
  "States that are part of a tau-loop"
  (let ((livelocks '()))
    (define (loop-detect state entry-edge)
      (define (report-cycle state)
        (set! livelocks (cons state livelocks)))
      (let ((node (vector-ref lts state)))
        (cond ((= (node-color node) %grey)
               (set-node-cycle! node entry-edge)
               (report-cycle state))
              ((= (node-color node) %white)
               (let* ((tau-edges (filter edge-tau? (node-succ node))))
                 (set-node-color! node %grey)
                 (set-node-cycle! node entry-edge)
                 (for-each (lambda (e) (loop-detect (edge-to e) e)) tau-edges)
                 (set-node-color! node %black)))
              (else node))))
    (for-each (cute loop-detect <> #f) (iota-distance-sorted lts))
    (delete-duplicates livelocks)))

(define (trace lts state)
  "Trace from INITIAL to STATE"
  (let ((lts lts))
    (define (trace-it state edges)
      (let ((parent (node-parent (vector-ref lts state))))
        (if (not parent) edges
            (trace-it (edge-from parent) (cons parent edges)))))
    (trace-it state '())))

(define (tau-loop loop-entry-state lts)
  "Loop of events leading from LOOP-ENTRY-STATE back to LOOP-ENTRY-STATE"
  (define (loop-edges trace state)
    (let* ((predecessor-edge (node-cycle (vector-ref lts state)))
           (predecessor-state (edge-from predecessor-edge))
           (predecessor-node (vector-ref lts predecessor-state)))
      (if (eq? predecessor-state loop-entry-state) (cons predecessor-edge trace)
          (loop-edges (cons predecessor-edge trace) predecessor-state))))
  (loop-edges '()  loop-entry-state))

(define (assert-livelock lts)
  "Trace to entry point of first livelock or #f if no tau loops found"
  (let* ((livelock-nodes (lts-tau-loops lts))
         (loop-entry-trace (and (pair? livelock-nodes)
                                (trace lts (car livelock-nodes))))
         (loop-entry-node (and loop-entry-trace (car livelock-nodes)))
         (loop-trace (and loop-entry-node (tau-loop loop-entry-node lts))))
    (if (null? livelock-nodes) #f
        (append (or loop-entry-trace '())
                (list (make-edge-loop))
                (or loop-trace '())))))


;;;
;;; Illegal.
;;;
(define (annotate-exclude lts excludes)
  (define (exclude-label node)
    (let* ((labels (map edge-label (node-succ node)))
           (exclude? (find (cute memq <> excludes) labels))
           (node (set-field node (node-color) exclude?)))
      (vector-set! lts (node-state node) node) ;; FIXME
      node))
  (vector-map-one exclude-label lts))

(define (remove-illegal lts)
  (define (exclude? lts edge)
    (node-exclude? (vector-ref lts (edge-to edge))))
  (define (exclude node)
    (let ((succ (filter (negate (cute exclude? lts <>))
                        (node-succ node))))
      (set-field node (node-succ) succ)))
  (let ((lts (annotate-exclude lts (list %<declarative-illegal> %<illegal>))))
    (vector-map-one exclude lts)))

(define (trim-queue-full lts)
  (define (reset-exclude node)
    (set-field node (node-color) #f))
  (define (exclude-queue-full node)
    (let ((succ (if (node-exclude? node) '()
                    (node-succ node))))
      (set-field node (node-succ) succ)))
  (define (set-exclude-queue-full lts i node)
    (let* ((succ (node-succ node))
           (edge (find (compose (cute eq? <> %<queue-full>) edge-label) succ)))
      (when edge
        (let* ((i (edge-to edge))
               (node (vector-ref lts i))
               (node (set-field node (node-color) #t)))
          (vector-set! lts i node)))))
  (let ((lts (vector-map-one reset-exclude lts)))
    (vector-for-each (cute set-exclude-queue-full lts <> <>) lts)
    (vector-map-one exclude-queue-full lts)))


;;;
;;; Deadlock.
;;;
(define (remove-info-edges lts)
  (define (info-edge? edge)
    (or (string-prefix? "<state>" (edge-label edge))
        (string-prefix? "tag(" (edge-label edge))))
  (define (remove-info node)
    (let ((succ (filter (negate info-edge?) (node-succ node))))
      (set-field node (node-succ) succ)))
  (vector-map-one remove-info lts))

(define (remove-tag-edges lts)
  (define (tag-edge? edge)
    (string-prefix? "tag(" (edge-label edge)))
  (define (remove-tag node)
    (let ((succ (filter (negate tag-edge?) (node-succ node))))
      (set-field node (node-succ) succ)))
  (vector-map-one remove-tag lts))

(define (deadlock-nodes lts)
  "States without outgoing edges"
  (let* ((lts (remove-info-edges lts))
         (lts (trim-queue-full lts))
         (lts (annotate-exclude lts (list %<declarative-illegal>))))
    (define (edges? state)
      (let ((node (vector-ref lts state)))
        (find (compose (negate node-exclude?)
                       (cute vector-ref lts <>)
                       edge-to)
              (node-succ node))))
    (filter (negate edges?)
            (filter (compose (negate node-exclude?) (cute vector-ref lts <>))
                    (iota-distance-sorted lts)))))

(define (assert-deadlock lts)
  "Trace to node without outgoing edges or #f if no deadlock found"
  (let* ((deadlock-nodes (deadlock-nodes lts))
         (deadlock-trace (and (pair? deadlock-nodes)
                              (trace lts (car deadlock-nodes)))))
    deadlock-trace))

(define (assert-unreachable lts tags)
  "Return any TAGS that are not present in LTS."
  (let* ((succs (append-map node-succ (vector->list lts)))
         (labels (map edge-label succs))
         (lts-tages (filter (cut string-prefix? "tag(" <>) labels))
         (lts-tages (delete-duplicates lts-tages))
         (missing-tags (filter (negate (cut member <> lts-tages)) tags))
         (missing-tags (delete-duplicates missing-tags)))
    (if (null? missing-tags) #f
        missing-tags)))

(define (illegal-nodes lts)
  "States with labels of illegal outgoing edges."
  (define (has-illegal? state)
    (find (cute eq? <> %<illegal>) (map edge-label (node-succ (vector-ref lts state)))))
  (filter has-illegal? (iota-distance-sorted lts)))

(define (assert-illegal lts)
  "Trace to nodes without outgoing edges or #f if no deadlock found"
  (let* ((illegal-nodes (illegal-nodes lts))
         (illegal-trace (and (not (null? illegal-nodes)) (trace lts (car illegal-nodes)))))
    (if (null? illegal-nodes) #f
        illegal-trace)))

(define (nondeterministic-nodes lts labels)
  "States with multiple outgoing edges with same label of set of 'labels'"
  (let ((labels (map make-shared-string labels)))
    (define (is-nondeterministic? state)
      (let* ((node (vector-ref lts state))
             (succ (filter (lambda (e) (memq (edge-canonical-label e) labels)) (node-succ node)))
             (res (let loop ((last #f) (succ succ))
                    (cond
                     ((null? succ) #f)
                     ((and last (eq? (edge-canonical-label last) (edge-canonical-label (car succ)))) last)
                     (else (loop (car succ) (cdr succ)))))))
        (when res
          (set-node-nondet-witness! node res))
        res))
    (filter is-nondeterministic? (iota-distance-sorted lts))))

(define (assert-nondeterministic lts labels)
  "Trace to nondetermistic node of #f is none found"
  (let* ((nondeterministic-nodes (nondeterministic-nodes lts labels))
         (nondeterministic-node (and (pair? nondeterministic-nodes) (car nondeterministic-nodes)))
         (nondeterministic-witness (and nondeterministic-node (node-nondet-witness (vector-ref lts nondeterministic-node))))
         (nondeterministic-trace (and nondeterministic-node
                                      (append (trace lts nondeterministic-node)
                                              (if (equal? (edge-canonical-label nondeterministic-witness) %<state>) '()
                                                  (list nondeterministic-witness))))))
    nondeterministic-trace))


;;;
;;; Failures.
;;;
(define (optional? e)
  (or (eq? (edge-label e) %optional)
      (string-suffix? ".optional" (edge-label e))
      (string-suffix? "'optional" (edge-label e))
      (string-suffix? "'optional)" (edge-label e))))

(define (inevitable? e)
  (or (eq? (edge-label e) %inevitable)
      (string-suffix? ".inevitable" (edge-label e))
      (string-suffix? "'inevitable" (edge-label e))
      (string-suffix? "'inevitable)" (edge-label e))))

(define modeling? (disjoin optional? inevitable?))

(define (add-failures lts)
  "Return LTS with failures."
  (define (modeling->tau e)
    (if (modeling? e) (make-edge (edge-from e) %tau (edge-to e))
        e))
  (define (add-failure node state)
    (let* ((org-node (vector-ref lts (node-state node)))
           (succ (cons (make-edge (node-state org-node) %tau state)
                       (map clone-edge (node-succ org-node)))))
      (set-node-succ! org-node succ)
      (set-node-state! node state)
      (let* ((succ (node-succ node))
             (succ (map (cut set-field <> (edge-from) state) succ)))
        (set-node-succ! node succ))
      (1+ state)))
  (define (remove-optional node)
    (let ((succ (filter (negate optional?) (node-succ node))))
      (set-field node (node-succ) succ)))
  (define (node:modeling->tau node)
    (let ((succ (map modeling->tau (node-succ node))))
      (set-field node (node-succ) succ)))
  (let* ((state-count (vector-length lts))
         (lts-list (vector->list lts))
         (add (filter (compose (cute find optional? <>) node-succ) lts-list))
         (add (map remove-optional add)))
    (fold add-failure state-count add)
    (let* ((lts-list (append lts-list add))
           (lts-list (map node:modeling->tau lts-list)))
      (list->vector lts-list))))


;;;
;;; Trace generation.
;;;
(define %fout-inc 0)

(define node-allowed-end? node-color)
(define set-node-allowed-end?! set-node-color!)
(define node-close node-parent)
(define set-node-close! set-node-parent!)

(define* (generate-trace initial lts provides-ports provides-in fout out #:key verbose?)

  (define (allowed-end? node)
    (define (label-provides-in? label)
      (and (pair? provides-in)
           (memq label provides-in)))
    (define (get-port label)
      (car (string-split label #\.)))
    (define (idle-node? node)
      (let* ((labels (map edge-label (node-succ node)))
             (labels (filter label-provides-in? labels))
             (ports (map get-port labels))
             (ports (delete-duplicates ports string=?)))
       (= (length ports)
          (length provides-ports))))
    (and (idle-node? node)
         (not (find (lambda (e) (or (eq? %<ack> (edge-label e))
                                    (eq? %<defer> (edge-label e))))
                    (node-succ node)))))

  (define (annotate)
    (let* ((frontier (map node-state
                          (filter (lambda (node)
                                    (set-node-allowed-end?! node (allowed-end? node))
                                    (node-allowed-end? node))
                                  (vector->list lts)))))
      (define (extend-frontier index)
        (let loop ((edges (node-pred (vector-ref lts index))))
          (if (null? edges) '()
              (let* ((edge (car edges))
                     (node-index (edge-from edge))
                     (node (vector-ref lts node-index)))
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
      (if (memq label (list %tau %<ack>)) trace
          (append trace (list label))))

    (define (trace-close trace index)
      (let* ((node (vector-ref lts index))
             (close-edge (node-close node)))
        (if (or (node-allowed-end? node)
                (not close-edge))
            trace
            (let ((ext-trace (trace-extend trace (edge-label close-edge))))
              (trace-close ext-trace (edge-to close-edge))))))

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
             (let ((node (vector-ref lts index)))
               (hashq-set! done index #t)
               (let loop ((edges (node-succ node)) (generated-trace? #f))
                 (if (null? edges) generated-trace?
                     (let* ((edge (car edges))
                            (edge-index (edge-to edge)))
                       (if (= edge-index index) (loop (cdr edges) generated-trace?)
                           (let ((ext-trace (trace-extend trace (edge-label edge))))
                             (when (not (step edge-index ext-trace))
                               (trace-log (trace-close ext-trace edge-index)))
                             (loop (cdr edges) #t))))))))))

    (annotate)
    (step initial '())))

(define* (lts->traces data illegal? flush? interface out model provides-ports
                      provides-in
                      #:key verbose?)
  (let* ((provides-ports (if (not interface) provides-ports
                             (list model)))
         (interface (and=> (and interface model) make-shared-string))
         (provides-ports (map make-shared-string provides-ports))
         (provides-in (map make-shared-string provides-in)))

    (define (convert-label label)
      (let* ((label (if (or flush? (not (string-contains label %<flush>)))
                        label
                        %tau))
             (interface-port (and interface (last (string-split interface #\.))))
             (interface-port (make-shared-string interface-port)))
        (match (map make-shared-string (string-split label #\.))
          (((? (cute eq? <> interface-port)) label) label)
          (((? (cute memq <> provides-ports)) %<flush>) %tau)
          (_ label))))

    (define (convert-edge edge)
      (set-field edge (edge-label) (convert-label (edge-label edge))))

    (define (convert-node node)
      (let ((pred (map convert-edge (node-pred node)))
            (succ (map convert-edge (node-succ node))))
        (set-fields node ((node-pred) pred) ((node-succ) succ))))

    (let* ((text (string-join data "\n"))
           (lts (aut-text->lts text #:traces? #t))
           (lts (vector-map-one convert-node lts))
           (lts (if illegal? lts (remove-illegal lts)))
           (lts (remove-info-edges lts))
           (initial (initial lts)))
      (generate-trace initial lts provides-ports provides-in
                      (string-append model ".trace") out #:verbose? verbose?))))

(define (lts->rtc-lts lts)
  (define (clear-node-succ node)
    (set-field node (node-succ) '()))

  (let ((result (vector-map-one clear-node-succ lts)))
    (define (illegal? label)
      (match label
        ("<illegal>" #t)
        ("<declarative-illegal>" #t)
        ("illegal" #t)
        ("declarative_illegal" #t)
        (_ #f)))

    (define (modeling? o)
      (and (string? o)
           (string-contains o "'internal(")))

    (define (trigger? o)
      (and (string? o)
           (string-contains o "'in(")))

    (define (rtc? node)
      (find (disjoin modeling? trigger?) (map edge-label (node-succ node))))

    (define (extend trail label)
      (match label
        (#f trail)
        ("tau" trail)
        ((and (? string?) (? (cute string-suffix? "<flush>" <>))) trail)
        ((? string?) (cons label trail))))

    (define (add from to trail)
      (let ((from (vector-ref result (node-state from)))
            (succ (cons (make-edge (node-state from) (reverse trail) to)
                        (node-succ from))))
        (set-node-succ! from succ))) ;; todo: avoid duplicates

    (define (step from to trail)
      (let ((node (vector-ref lts to)))
        (if (and (pair? trail) (or (rtc? node) (illegal? (car trail))))
          (add from to trail)
          (for-each
            (lambda (edge)
              (step from (edge-to edge) (extend trail (edge-label edge))))
            (node-succ node)))))

    (define (step-rtc i node)
      (when (rtc? node)
        (step node i '())))

    (vector-for-each step-rtc lts)
    result))


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
     reply-literal      <   'reply' (tick 'reordered')?
     state-literal      <   'state'
     tag-literal        <   'tag'
     tau-literal        <   'tau'
     illegal            <-- 'illegal' / 'declarative_illegal' / 'constrained_illegal'
     error              <--  queue-full / range-error / reply-error / missing-reply / second-reply
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
    (let ((parameters (if (pair? (car parameters)) parameters (list parameters))))
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
                         (initial lts)
                         (length edges)
                         (vector-length lts)))
         (lines (map
                 (lambda (e)
                   ;; format has a significant performance impact on
                   ;; large LTSs.
                   (string-append
                    "("
                    (number->string (edge-from e)) ","
                    "\"" (edge-label e) "\","
                    (number->string (edge-to e))
                    ")"))
                 edges))
         (lines (cons header lines))
         (text (string-join lines separator)))
    (display text)))
