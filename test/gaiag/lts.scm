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
;;; Tests for the lts module.
;;;
;;; Code:

(define-module (test gaiag lts)
  #:use-module (gaiag lts)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-64)
  #:use-module (test gaiag automake))

;; TODO: string->aut

(define aap-aut "\
des (0,2,2)
(0,\"aap\",1)
(1,\"return\",0)")

(define comp-livelock-aut "\
des (0,11,10)
(0,\"iter'event(Iterate'in'map)\",1)
(1,\"tau\",2)
(2,\"list'event(List'in'next)\",3)
(2,\"list'event(List'in'next)\",4)
(3,\"list'return(List'in'next, reply_List'Bool(false))\",5)
(4,\"list'return(List'in'next, reply_List'Bool(true))\",6)
(5,\"tau\",7)
(6,\"tau\",2)
(7,\"tau\",8)
(8,\"tau\",9)
(9,\"iter'return(Iterate'in'map, reply_Iterate'Void(void))\",0)
")

(define component-deterministic-fail0-aut "\
des (0,5,4)
(0,\"i'in(I'in'e)\",1)
(0,\"i'in(I'in'e)\",2)
(1,\"ii'out(I'in'e)\",3)
(2,\"i'reply_out(I'in'e, reply_I'Void(void))\",0)
(3,\"ii'reply_in(I'in'e, reply_I'Void(void))\",2)
")

(define component-deterministic-fail1-aut "\
des (0,7,6)
(0,\"i'in(I'in'e)\",1)
(1,\"i'reply_out(I'in'e, reply_I'Void(void))\",2)
(2,\"i'in(I'in'e)\",3)
(2,\"i'in(I'in'e)\",4)
(3,\"i'reply_out(I'in'e, reply_I'Void(void))\",2)
(4,\"ii'out(I'in'e)\",5)
(5,\"ii'reply_in(I'in'e, reply_I'Void(void))\",3)
")

(define ComponentIsNonDeterministic-aut "\
des (0,5,4)
(0,\"pp'in(I'in'ia)\",1)
(0,\"pp'in(I'in'ia)\",2)
(1,\"pp'out(I'out'oa)\",3)
(2,\"pp'out(I'out'ob)\",3)
(3,\"pp'reply_out(I'in'ia, reply_I'Void(void))\",0)
")

(define double-entry-aut "\
des (1,10,8)
(6,\"listIt'return(IIterator'in'getNextElmt, reply_IIterator'IIterator'IsPastEnd(IIterator'IsPastEnd'Yes))\",0)
(7,\"listIt'return(IIterator'in'getNextElmt, reply_IIterator'IIterator'IsPastEnd(IIterator'IsPastEnd'No))\",5)
(0,\"pp'return(IDriver'in'step, reply_IDriver'Void(void))\",1)
(5,\"listIt'event(IIterator'in'getNextElmt)\",7)
(5,\"listIt'event(IIterator'in'getNextElmt)\",6)
(4,\"listIt'return(IIterator'in'getFirstElmt, reply_IIterator'IIterator'IsPastEnd(IIterator'IsPastEnd'Yes))\",0)
(3,\"listIt'return(IIterator'in'getFirstElmt, reply_IIterator'IIterator'IsPastEnd(IIterator'IsPastEnd'No))\",5)
(2,\"listIt'event(IIterator'in'getFirstElmt)\",4)
(2,\"listIt'event(IIterator'in'getFirstElmt)\",3)
(1,\"pp'event(IDriver'in'step)\",2)
")

(define itimer-aut "\
des (0,7,5)
(0,\"create\",1)
(0,\"cancel\",4)
(1,\"return\",2)
(2,\"cancel\",4)
(2,\"tau\",3)
(3,\"timeout\",0)
(4,\"return\",0)")

(define livelock-aut "\
des (0,5,9)
(0,\"aap\",1)
(1,\"return\",0)
(0,\"blaat\",2)
(2,\"noot\",3)
(2,\"blaat\",3)
(3,\"tau\",3)
(3,\"live\",4)
(4,\"lock\",3)
(3,\"mies\",0)
")

(define nolivelock-aut "\
des (1,2,2)
(0,\"nolivelock'flush\",1)
(1,\"nolivelock'event(nolivelock'out'dummy)\",0)
")

(define noloop-aut "\
des (0,4,4)
(0,\"tau\",1)
(0,\"tau\",2)
(1,\"tau\",3)
(2,\"tau\",3)")

(define timer-aut "\
des (0,12,10)
(0,\"create\",1)
(0,\"cancel\",9)
(1,\"hw.enable\",2)
(2,\"hw.return\",3)
(3,\"return\",4)
(4,\"cancel\",5)
(5,\"hw.disable\",6)
(6,\"hw.return\",7)
(7,\"return\",0)
(4,\"hw.interrupt\",8)
(8,\"timeout\",0)
(9,\"return\",0)
")

(define verify-component-aut "\
des (1,15,13)
(0,\"pp'return(II'Actions'ic,reply_II'Void(void))\",10)
(12,\"pp'return(II'Actions'ic,reply_II'Void(void))\",5)
(11,\"pp'return(II'Actions'ic,reply_II'Void(void))\",1)
(10,\"pp'event(II'Actions'ic)\",0)
(9,\"pp'flush\",10)
(8,\"pp'event(II'Actions'oa)\",9)
(7,\"rp'flush\",8)
(6,\"rp'event(IO'Actions'oa)\",7)
(5,\"rp'optional\",6)
(5,\"pp'event(II'Actions'ic)\",12)
(4,\"pp'return(II'Actions'ia,reply_II'Void(void))\",5)
(3,\"rp'return(IO'Actions'ia,reply_IO'Void(void))\",4)
(2,\"rp'event(IO'Actions'ia)\",3)
(1,\"pp'event(II'Actions'ia)\",2)
(1,\"pp'event(II'Actions'ic)\",11)
")

(define verify-provided-aut "\
des (3,9,7)
(6,\"pp'return(II'Actions'ic,reply_II'Void(void))\",3)
(0,\"pp'return(II'Actions'ic,reply_II'Void(void))\",1)
(4,\"pp'return(II'Actions'ia,reply_II'Void(void))\",1)
(3,\"pp'event(II'Actions'ia)\",4)
(3,\"pp'event(II'Actions'ic)\",6)
(2,\"pp'flush\",3)
(5,\"pp'event(II'Actions'oa)\",2)
(1,\"tau\",5)
(1,\"pp'event(II'Actions'ic)\",0)
")

(define wrong-edge-aut "\
des (1,15,13)
(0,pp'return(II'Actions'ic,reply_II'Void(void)),10)
(12,\"pp'return(II'Actions'ic,reply_II'Void(void))\",5)
(11,\"pp'return(II'Actions'ic,reply_II'Void(void))\",1)
(10,\"pp'event(II'Actions'ic)\",0)
(9,\"pp'flush\",10)
(8,\"pp'event(II'Actions'oa)\",9)
(7,\"rp'flush\",8)
(6,\"rp'event(IO'Actions'oa)\",7)
(5,\"rp'optional\",6)
(5,\"pp'event(II'Actions'ic)\",12)
(4,\"pp'return(II'Actions'ia,reply_II'Void(void))\",5)
(3,\"rp'return(IO'Actions'ia,reply_IO'Void(void))\",4)
(2,\"rp'event(IO'Actions'ia)\",3)
(1,\"pp'event(II'Actions'ia)\",2)
(1,\"pp'event(II'Actions'ic)\",11)
")

(define wrong-header-aut "\
(1,15,13)
(0,\"pp'return(II'Actions'ic,reply_II'Void(void))\",10)
(12,\"pp'return(II'Actions'ic,reply_II'Void(void))\",5)
(11,\"pp'return(II'Actions'ic,reply_II'Void(void))\",1)
(10,\"pp'event(II'Actions'ic)\",0)
(9,\"pp'flush\",10)
(8,\"pp'event(II'Actions'oa)\",9)
(7,\"rp'flush\",8)
(6,\"rp'event(IO'Actions'oa)\",7)
(5,\"rp'optional\",6)
(5,\"pp'event(II'Actions'ic)\",12)
(4,\"pp'return(II'Actions'ia,reply_II'Void(void))\",5)
(3,\"rp'return(IO'Actions'ia,reply_IO'Void(void))\",4)
(2,\"rp'event(IO'Actions'ia)\",3)
(1,\"pp'event(II'Actions'ia)\",2)
(1,\"pp'event(II'Actions'ic)\",11)
")

(define (test:text->aut-header)
  (and (text->aut-header "des (0,1,2)")
       (not (text->aut-header "(0,\"aap\",2)"))))
;;(test:text->aut-header)

(define (test:text->aut-edge)
  (and (equal? (make-aut-edge 0 "aap" 1)
               (text->aut-edge "(0,\"aap\",1)"))
       (equal? (make-aut-edge 10 "robot'return(ITransfer'in'calibrate, reply_ITransfer'Void(void))" 15)
               (text->aut-edge "(10,\"robot'return(ITransfer'in'calibrate, reply_ITransfer'Void(void))\",15)"))))
;;(test:text->aut-edge)

(define (test:edges->successor-edge-vector)
  (equal?
   (list->vector (list (list (make-aut-edge 0 "aap" 1))
                       (list (make-aut-edge 1 "return_false" 0)
                             (make-aut-edge 1 "return_true" 2))
                       (list (make-aut-edge 2 "cancel" 3))
                       (list (make-aut-edge 3 "return" 0)
                             (make-aut-edge 3 "deadlock" 4))
                       '()))
   (edges->successor-edge-vector 5
                                 (list (make-aut-edge 0 "aap" 1)
                                       (make-aut-edge 2 "cancel" 3)
                                       (make-aut-edge 1 "return_false" 0)
                                       (make-aut-edge 3 "return" 0)
                                       (make-aut-edge 1 "return_true" 2)
                                       (make-aut-edge 3 "deadlock" 4)))))
;;(test:edges->successor-edge-vector)

(define (test:edges->predecessor-edge-vector)
  (equal?
   (list->vector (list (list (make-aut-edge 1 "return_false" 0)
                             (make-aut-edge 3 "return" 0))
                       (list (make-aut-edge 0 "aap" 1))
                       (list (make-aut-edge 1 "return_true" 2))
                       (list (make-aut-edge 2 "cancel" 3))
                       (list (make-aut-edge 3 "deadlock" 4))))
   (edges->predecessor-edge-vector 5
                                   (list (make-aut-edge 0 "aap" 1)
                                         (make-aut-edge 1 "return_false" 0)
                                         (make-aut-edge 1 "return_true" 2)
                                         (make-aut-edge 2 "cancel" 3)
                                         (make-aut-edge 3 "return" 0)
                                         (make-aut-edge 3 "deadlock" 4)))))
;;(test:edges->predecessor-edge-vector)

(define (test:aut-file->lts)
  (equal? (make-lts '(0)
                    2
                    (list (make-aut-edge 0 "aap" 1)
                          (make-aut-edge 1 "return" 0)))
          (aut-file->lts "../../tst/aap.aut")))
;;(test:aut-file->lts)

;; ===== Performance test =====
;; (define (write-test-file)
;;   (with-output-to-file "blaat.txt"
;;     (lambda ()
;;       (let* ((n 160000)
;;              (edges-per-state 2)
;;              (header (string-append "des (0," (number->string n) "," (number->string (/ n edges-per-state)) ")"))
;;              (edges (map (lambda (n) (string-append "(" (number->string (floor (/ n edges-per-state))) ",\"blaat\"," (number->string (floor (/ n edges-per-state))) ")"))
;;                          (iota n)))
;;              (lines (cons header edges))
;;              (txt (string-join lines "\n")))
;;         (display txt)))))
;;(write-test-file)
;; (use-modules (statprof))
;; (statprof (lambda ()
;;             (lts-hide (aut-file->lts "blaat.txt") '())
;;             #f))
;; ===== Performance test =====

(define (test:lts-hide)
  (and (equal? (make-lts 0
                         2
                         (list (make-aut-edge_ 0 "aap" #t 1)
                               (make-aut-edge 1 "return" 0)))
               (lts-hide (make-lts 0
                                   2
                                   (list (make-aut-edge 0 "aap" 1)
                                         (make-aut-edge 1 "return" 0)))
                         (list "aap")))
       (equal? (make-lts 0
                         2
                         (list (make-aut-edge_ 0 "aap(0)" #t 1)
                               (make-aut-edge_ 0 "aap(een'twee)" #t 1)
                               (make-aut-edge_ 0 "aap(42)" #t 1)
                               (make-aut-edge_ 0 "aap'return(0)" #t 1)
                               (make-aut-edge_ 0 "aapje" #f 1)
                               (make-aut-edge 1 "return" 0)))
               (lts-hide (make-lts 0
                                   2
                                   (list (make-aut-edge 0 "aap(0)" 1)
                                         (make-aut-edge 0 "aap(een'twee)" 1)
                                         (make-aut-edge 0 "aap(42)" 1)
                                         (make-aut-edge 0 "aap'return(0)" 1)
                                         (make-aut-edge 0 "aapje" 1)
                                         (make-aut-edge 1 "return" 0)))
                         (list "aap" "aap'return" "noot" "mies")))))
;;(test:lts-hide)

(define (test:lts->alphabet)
  (equal? (list "aap" "return")
          (lts->alphabet (make-lts 0
                                   3
                                   (list (make-aut-edge 0 "aap" 1)
                                         (make-aut-edge 1 "return" 0)
                                         (make-aut-edge_ 1 "blaat" #t 42))))))
;;(test:lts->alphabet)


(define (test:accept-edge-sets)
  (and (equal? (list (list (make-aut-edge 0 "aap" 1)))
               (lts-accept-edge-sets (make-lts '(0)
                                               2
                                               (list (make-aut-edge 0 "aap" 1)
                                                     (make-aut-edge 1 "return" 0)))))
       (equal? (list (list (make-aut-edge 0 "aap" 1)
                           (make-aut-edge 0 'tau 2))
                     (list (make-aut-edge 3 "mies" 0)))
               (lts-accept-edge-sets (make-lts '(0 3)
                                               4
                                               (list (make-aut-edge 0 "aap" 1)
                                                     (make-aut-edge 1 "return" 0)
                                                     (make-aut-edge 0 'tau 2)
                                                     (make-aut-edge 2 "noot" 3)
                                                     (make-aut-edge 2 'tau 3)
                                                     (make-aut-edge 3 "mies" 0)))))))
;;(test:accept-edge-sets)

(define (test:lts-stable-accepts)
  (equal? (list '("aap"))
          (lts-stable-accepts (step-tau (make-lts '(0)
                                                  2
                                                  (list (make-aut-edge 0 "aap" 1)
                                                        (make-aut-edge 1 "return" 0))))))
  (equal? (list '("return"))
          (lts-stable-accepts (step-tau (make-lts '(1)
                                                  2
                                                  (list (make-aut-edge 0 "aap" 1)
                                                        (make-aut-edge 1 "return" 0))))))
  ;; Fail if tau edges not properly removed:
  (equal? (list '("mies"))
          (lts-stable-accepts (step-tau (make-lts '(0 2 3)
                                                  4
                                                  (list (make-aut-edge 0 "aap" 1)
                                                        (make-aut-edge 1 "return" 0)
                                                        (make-aut-edge 0 'tau 2)
                                                        (make-aut-edge 2 "noot" 3)
                                                        (make-aut-edge 2 'tau 3)
                                                        (make-aut-edge 3 "mies" 0))))))
  ;; Fail if tau edges not properly removed:
  (equal? (list '("mies"))
          (lts-stable-accepts (step-tau (make-lts '(0 2 3)
                                                  4
                                                  (list (make-aut-edge_ 0 "aap" #f 1)
                                                        (make-aut-edge_ 1 "return" #f 0)
                                                        (make-aut-edge_ 0 "blaat" #t 2)
                                                        (make-aut-edge_ 2 "noot" #f 3)
                                                        (make-aut-edge_ 2 "blaat" #t 3)
                                                        (make-aut-edge_ 3 "mies" #f 0)))))))
;;(test:lts-stable-accepts)


(define (test:annotate-parent)
  (define (assert nodes)
    (let* ((nodes (vector->list nodes))
           (nodes-without-distance (filter (lambda (n) (negative? (node-distance n))) nodes))
           (nodes-without-parent (filter (negate node-parent) nodes)))
      (and (equal? 0 (length nodes-without-distance)) ;; no unreachable nodes in test-lts
           (equal? 1 (length nodes-without-parent))))) ;; root node has no parent
  (let* ((lts test-lts-livelock)
         (states (iota (lts-states lts)))
         (nodes (map (lambda (state) (make-node state
                                                (lts-succ lts state)
                                                (lts-pred lts state)
                                                (if (= state 0) #t #f)
                                                WHITE
                                                #f
                                                -1
                                                #f))
                     states))
         (nodes (list->vector nodes)))
    (assert (annotate-parent nodes))))
;;(test:annotate-parent)

(define (test:root)
  (let* ((lts (aut-file->lts "../../tst/verify_component.aut"))
         (lts-root (car (lts-state lts)))
         (nodes (lts->nodes lts))
         (nodes-root (root nodes)))
    (eqv? lts-root nodes-root)))
;;(test:root)

(define (test:lts-tau-loops)
  (and (equal? '(3)
               (let ((nodes (lts->nodes test-lts-livelock)))
                 (lts-tau-loops nodes)))
       (equal? '(5)
               (let ((nodes (lts->nodes (lts-hide (aut-file->lts "../../tst/double-entry.aut")
                                                  (list "listIt'return" "listIt'event" "ListIt'flush")))))
                 (lts-tau-loops nodes)))
       ))
;;(test:lts-tau-loops)

(define (test:trace)
  (equal? '(() ("create") ("create" "return") ("create" "return" "tau") ("cancel"))
          (let* ((lts (lts-hide (aut-file->lts "../../tst/itimer.aut") '()))
                 (test-nodes (lts->nodes lts)))
            (map (cut map aut-edge-label <>) (map (cut trace test-nodes <>) (iota 5))))))
;;(test:trace)

(define (test:tau-loop)
  (let ((actual (let* ((nodes (lts->nodes test-lts-livelock))
                       (livelock-nodes (lts-tau-loops nodes))
                       (entry-trace (trace nodes (car livelock-nodes)))
                       (entry-state (aut-edge-end-state (last entry-trace))))
                  (tau-loop entry-state nodes))))
    (or (equal? (list (make-aut-edge_ 3 "tau" #t 3))
                actual)
        (equal? (list (make-aut-edge_ 3 "live" #t 4)
                      (make-aut-edge_ 4 "lock" #t 3))
                actual))))
;;(test:tau-loop)

(define (test:assert-livelock)
  (and (equal? (list (make-aut-edge_ 0 "blaat" #t 2)
                 (make-aut-edge_ 2 "blaat" #t 3)
                 (make-aut-edge_ 3 "live" #t 4)
                 (make-aut-edge_ 4 "lock" #t 3))
               (let ((nodes (lts->nodes test-lts-livelock)))
                 (assert-livelock nodes)))
       (equal? (list (make-aut-edge_ 1 "BlindLoop'event(BlindLoop'in'start)" #f 2)
                     (make-aut-edge_ 2 "BlindLoop'return(BlindLoop'in'start, reply_BlindLoop'Void(void))" #f 0)
                     (make-aut-edge_ 0 "tau" #t 0))
               (let ((nodes (lts->nodes test-lts-livelock-2)))
                 (assert-livelock nodes)))
       (not (let* ((lts (lts-hide (aut-file->lts "../../tst/nolivelock.aut") '()))
                   (test-nodes (lts->nodes lts)))
              (assert-livelock test-nodes)))))
;;(test:assert-livelock)

(define (test:rm-tau-loops)
  (define expect-lts
    (make-lts '(0)
              5
              (list (make-aut-edge_ 0 "aap" #f 1)
                    (make-aut-edge_ 1 "return" #f 0)
                    (make-aut-edge_ 0 "blaat" #t 2)
                    (make-aut-edge_ 2 "noot" #f 3)
                    (make-aut-edge_ 2 "blaat" #t 3)
                    ;;(make-aut-edge_ 3 "tau" #t 3)
                    ;;(make-aut-edge_ 3 "live" #t 4)
                    (make-aut-edge_ 4 "lock" #t 3)
                    ;;(make-aut-edge_ 3 "mies" #f 0)
                    )))
  (equal? expect-lts
          (rm-tau-loops test-lts-livelock)))
;;(test:rm-tau-loops)

(define (test:assert-deadlock)
  (define test-lts-deadlock
    (make-lts '(0)
              5
              (list (make-aut-edge_ 0 "aap" #f 1)
                    (make-aut-edge_ 1 "return" #f 0)
                    (make-aut-edge_ 0 "blaat" #t 2)
                    (make-aut-edge_ 2 "noot" #f 3)
                    (make-aut-edge_ 2 "blaat" #t 3)
                    (make-aut-edge_ 3 "tau" #t 3)
                    (make-aut-edge_ 3 "dead" #t 4)
                    (make-aut-edge_ 3 "mies" #f 0))))
  (equal? '("blaat" "blaat" "dead")
          (map aut-edge-label (assert-deadlock (lts->nodes test-lts-deadlock)))))
;;(test:assert-deadlock)


(define (test:assert-illegal)
  (define test-lts-illegal
    (make-lts '(0)
              5
              (list (make-aut-edge_ 0 "aap" #f 1)
                    (make-aut-edge_ 1 "return" #f 0)
                    (make-aut-edge_ 0 "blaat" #t 2)
                    (make-aut-edge_ 2 "noot" #f 3)
                    (make-aut-edge_ 2 "blaat" #t 3)
                    (make-aut-edge_ 3 "tau" #t 3)
                    (make-aut-edge_ 3 "dead" #t 4)
                    (make-aut-edge_ 3 "mies" #f 0))))
  (equal? '("blaat" "blaat")
          (map aut-edge-label (assert-illegal (lts->nodes test-lts-illegal) (list "dead")))))
;;(test:assert-illegal)

(define (test:assert-partially-deterministic)
  (let ((deterministic-lts-1 (make-lts '(0)
                                       2
                                       (list (make-aut-edge 0 "aap" 1)
                                             (make-aut-edge 0 "noot" 1)
                                             (make-aut-edge 1 "return" 0))))
        (deterministic-lts-2 (make-lts '(0)
                                       2
                                       (list (make-aut-edge 0 "aap" 1)
                                             (make-aut-edge 1 "true" 0)
                                             (make-aut-edge 1 "false" 0))))
        (nondet-lts-1 (make-lts '(0)
                                3
                                (list (make-aut-edge 0 "aap" 1)
                                      (make-aut-edge 0 "aap" 2)
                                      (make-aut-edge 1 "true" 0)
                                      (make-aut-edge 2 "false" 0))))
        (nondet-lts-2 (aut-file->lts "../../tst/component_deterministic_fail0.aut"))
        (nondet-lts-3 (aut-file->lts "../../tst/component_deterministic_fail1.aut"))
        (nondet-lts-4 (aut-file->lts "../../tst/ComponentIsNonDeterministic.aut")))
    (and (equal? #f (assert-partially-deterministic deterministic-lts-1 '()))
         (equal? #f (assert-partially-deterministic deterministic-lts-2 '()))
         (not (equal? #f (assert-partially-deterministic nondet-lts-1 '("aap"))))
         (not (equal? #f (assert-partially-deterministic nondet-lts-2 '("i'in(I'in'e)"))))
         (not (equal? #f (assert-partially-deterministic nondet-lts-3 '("i'in(I'in'e)"))))
         (not (equal? #f (assert-partially-deterministic nondet-lts-4 '("pp'in(I'in'ia)")))))))
;; (test:assert-partially-deterministic)

(define (test:assert-deterministic)
  (let ((deterministic-lts-1 (make-lts '(0)
                                       2
                                       (list (make-aut-edge 0 "aap" 1)
                                             (make-aut-edge 0 "noot" 1)
                                             (make-aut-edge 1 "return" 0))))
        (deterministic-lts-2 (make-lts '(0)
                                       2
                                       (list (make-aut-edge 0 "aap" 1)
                                             (make-aut-edge 1 "true" 0)
                                             (make-aut-edge 1 "false" 0))))
        (nondet-lts-1 (make-lts '(0)
                                3
                                (list (make-aut-edge 0 "aap" 1)
                                      (make-aut-edge 0 "aap" 2)
                                      (make-aut-edge 1 "true" 0)
                                      (make-aut-edge 2 "false" 0))))
        (nondet-lts-2 (aut-file->lts "../../tst/component_deterministic_fail0.aut"))
        (nondet-lts-3 (aut-file->lts "../../tst/component_deterministic_fail1.aut"))
        (nondet-lts-4 (aut-file->lts "../../tst/ComponentIsNonDeterministic.aut")))
    (and (equal? #f (assert-deterministic deterministic-lts-1))
         (equal? #f (assert-deterministic deterministic-lts-2))
         (not (equal? #f (assert-deterministic nondet-lts-1)))
         (not (equal? #f (assert-deterministic nondet-lts-2)))
         (not (equal? #f (assert-deterministic nondet-lts-3)))
         (not (equal? #f (assert-deterministic nondet-lts-4))))))
;; (test:assert-deterministic)

(define (test:step-tau)
  (define test-lts (make-lts '(1)
                             4
                             (list (make-aut-edge_ 0 "a" #f 1)
                                   (make-aut-edge_ 1 "tau" #t 2)
                                   (make-aut-edge_ 1 "tau" #t 3)
                                   (make-aut-edge_ 2 "true" #f 0)
                                   (make-aut-edge_ 3 "false" #f 0))))
  (equal? '(2 3) (lts-state (step-tau test-lts))))
;;(test:step-tau)

(define (test:step)
  (define test-lts (make-lts '(0)
                             4
                             (list (make-aut-edge_ 0 "a" #f 1)
                                   (make-aut-edge_ 1 "tau" #t 2)
                                   (make-aut-edge_ 1 "tau" #t 3)
                                   (make-aut-edge_ 2 "true" #f 0)
                                   (make-aut-edge_ 3 "false" #f 0))))
  (equal? '(2 3) (lts-state (step test-lts "a"))))
;;(test:step)

(define (test:run)
  (let* ((lts-a (make-lts '(0)
                          2
                          (list (make-aut-edge 0 "aap" 1)
                                (make-aut-edge 1 "return" 0))))
         (lts-b (run lts-a '("aap" "return")))
         (lts-c (make-lts '(1)
                          2
                          (list (make-aut-edge 0 "aap" 1)
                                (make-aut-edge 1 "return" 0))))
         (lts-d (run lts-a '("aap")))
         (lts-e (make-lts '(0)
                          3
                          (list (make-aut-edge 0 "aap" 1)
                                (make-aut-edge 0 "aap" 2)
                                (make-aut-edge 1 "true" 0)
                                (make-aut-edge 2 "false" 0))))
         (lts-f1 (run lts-e '("aap" "true")))
         (lts-f2 (run lts-e '("aap" "false"))))
    (and (equal? lts-a lts-b)
         (equal? lts-c lts-d)
         (equal? lts-e lts-f1 lts-f2))))
;;(test:run)

(define (test:aut-file-format-error)
  (define correct-aut
    (list "des (0,1,2)"
          "(0,\"aap\",1)"
          "(1,\"return\",0)"))
  (define wrong-aut-header
    (list "des(0,1,2)"
          "(0,\"aap\",1)"
          "(1,\"return\",0)"))
  (define wrong-aut-edge
    (list "des (0,1,2)"
          "(0,aap,1)"
          "(1,\"return\",0)"))
  (and (not (aut-file-format-error correct-aut))
       (aut-file-format-error wrong-aut-header)
       (aut-file-format-error wrong-aut-edge)
       #t))
;;(test:aut-file-format-error)

;; - - - - -   u n i t   t e s t   - - - - -
(define (test:unit)
  (and
   (test:text->aut-header)
   (test:text->aut-edge)
   (test:edges->successor-edge-vector)
   (test:edges->predecessor-edge-vector)
   (test:aut-file->lts)
   (test:lts-hide)
   (test:lts->alphabet)
   (test:accept-edge-sets)
   (test:lts-stable-accepts)
   (test:annotate-parent)
   (test:root)
   (test:lts-tau-loops)
   (test:trace)
   (test:tau-loop)
   (test:assert-livelock)
   (test:rm-tau-loops)
   (test:assert-deadlock)
   (test:assert-partially-deterministic)
   (test:assert-deterministic)
   (test:step-tau)
   (test:step)
   (test:run)
   (test:aut-file-format-error)
   #t
   ))
;;(test:unit)

(define (test:main)
  ;; (main (list "command" "../../tst/verify_component.aut")) ;; display lts
  (main (list "command" "-e" "../../tst/verify_provided.aut")) ;; list events in alphabet
  (main (list "command" "-e" "-t" "tau;pp'flush" "../../tst/verify_provided.aut")) ;; list events in alphabet hiding flush and tau
  ;; (main (list "command" "-e" "../../tst/verify_component.aut")) ;; list events in alphabet
  ;; (main (list "command" "-a" "../../tst/verify_provided.aut")) ;; list acceptances in initial state
  (main (list "command" "-a" "../../tst/verify_component.aut")) ;; list acceptances in initial state
  (main (list "command" "-a"
              "-t" "tau;pp'flush"
              "-p" "pp'event(II'Actions'ic);pp'return(II'Actions'ic,reply_II'Void(void))"
              "../../tst/verify_component.aut")) ;; list acceptances in initial state
  (main (list "command" "-a"
              "-p" "pp'event(II'Actions'ic);pp'return(II'Actions'ic,reply_II'Void(void))"
              "../../tst/verify_component.aut")) ;; list acceptances in initial state
  (main (list "command" "-a"
              "-p" "pp'event(II'Actions'ia);pp'return(II'Actions'ia,reply_II'Void(void))"
              "../../tst/verify_provided.aut")) ;; list acceptances in unstable state (1)
  (main (list "command" "-a"
              "-p" "pp'event(II'Actions'ia);pp'return(II'Actions'ia,reply_II'Void(void))"
              "-t" "tau;pp'flush"
              "../../tst/verify_provided.aut"))
  (main (list "command" "-a"
              "-p" "create;hw.enable;hw.return;return;hw.interrupt"
              "-t" "tau;hw.interrupt;hw.return;hw.disable;hw.enable"
              "../../tst/timer.aut")) ;; expect: ((timeout))

  (main (list "command" "-l"
              "../../tst/livelock.aut")) ;; expect: exit value: #f, stderr output: "tau loop found:\nblaat\nblaat\n"
  (main (list "command" "-l"
              "-t" "list'return;list'event;list'flush"
              "../../tst/comp-livelock.aut")) ;; expect: exit value: #f, stderr output: "tau loop found:iter'event(Iterage'in'map)\ntau\n"
  (main (list "command" "-l"
              "-t" "tau;hw.interrupt;hw.return;hw.disable;hw.enable"
              "../../tst/timer.aut")) ;; expect: ???
  (main (list "command" "-l"
              "-t" "tau"
              "../../tst/noloop.aut")) ;; expect: exit value: ?? stderr output: "No tau loop found"

  (main (list "command" "-n"
              "-t" "tau"
              "../../tst/component_deterministic_fail1.aut"))
  ;; expect: exit value: #f
  ;;         stderr output: "LTS is non-deterministic"
  ;;         stdout: "i.e\ni.return\ni.e"
)
;;(test:main)

(test-begin "lts")

(test-assert "lts dummy"
  #t)

(test-end)
