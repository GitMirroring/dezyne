;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018, 2019 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (test dzn lts)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)
  #:use-module (dzn lts)
  #:use-module (test dzn automake))


(define edges->successor-edge-vector (@@ (dzn lts) edges->successor-edge-vector))
(define edges->predecessor-edge-vector (@@ (dzn lts) edges->predecessor-edge-vector))
(define make-edge_ (@@ (dzn lts) make-edge_))
(define lts-accept-edge-sets (@@ (dzn lts) lts-accept-edge-sets))
(define node-distance (@@ (dzn lts) node-distance))
(define node-parent (@@ (dzn lts) node-parent))
(define test-lts-livelock (@@ (dzn lts) test-lts-livelock))
(define make-node (@@ (dzn lts) make-node))
(define lts-succ (@@ (dzn lts) lts-succ))
(define lts-pred (@@ (dzn lts) lts-pred))
(define WHITE (@@ (dzn lts) WHITE))
(define annotate-parent (@@ (dzn lts) annotate-parent))
(define root (@@ (dzn lts) root))
(define lts-tau-loops (@@ (dzn lts) lts-tau-loops))
(define trace (@@ (dzn lts) trace))
(define edge-end-state (@@ (dzn lts) edge-end-state))
(define last (@@ (dzn lts) last))
(define tau-loop (@@ (dzn lts) tau-loop))
(define test-lts-livelock-2 (@@ (dzn lts) test-lts-livelock-2))
(define step (@@ (dzn lts) step))
(define aut-file-format-error (@@ (dzn lts) aut-file-format-error))
(define main (@@ (dzn commands lts) main))


(test-begin "lts")

(test-assert "lts dummy"
  #t)

(define (test:text->aut-header)
  (and (text->aut-header "des (0,1,2)")
       (not (text->aut-header "(0,\"aap\",2)"))))
(test-assert (test:text->aut-header))

(define (test:text->edge)
  (and (equal? (make-edge 0 "aap" 1)
               (text->edge "(0,\"aap\",1)"))
       (equal? (make-edge 10 "robot'return(ITransfer'in'calibrate, reply_ITransfer'Void(void))" 15)
               (text->edge "(10,\"robot'return(ITransfer'in'calibrate, reply_ITransfer'Void(void))\",15)"))))
(test-assert (test:text->edge))

(define (test:edges->successor-edge-vector)
  (equal?
   (list->vector (list (list (make-edge 0 "aap" 1))
                       (list (make-edge 1 "return_false" 0)
                             (make-edge 1 "return_true" 2))
                       (list (make-edge 2 "cancel" 3))
                       (list (make-edge 3 "return" 0)
                             (make-edge 3 "deadlock" 4))
                       '()))
   (edges->successor-edge-vector 5
                                 (list (make-edge 0 "aap" 1)
                                       (make-edge 2 "cancel" 3)
                                       (make-edge 1 "return_false" 0)
                                       (make-edge 3 "return" 0)
                                       (make-edge 1 "return_true" 2)
                                       (make-edge 3 "deadlock" 4)))))
(test:edges->successor-edge-vector)

(define (test:edges->predecessor-edge-vector)
  (equal?
   (list->vector (list (list (make-edge 1 "return_false" 0)
                             (make-edge 3 "return" 0))
                       (list (make-edge 0 "aap" 1))
                       (list (make-edge 1 "return_true" 2))
                       (list (make-edge 2 "cancel" 3))
                       (list (make-edge 3 "deadlock" 4))))
   (edges->predecessor-edge-vector 5
                                   (list (make-edge 0 "aap" 1)
                                         (make-edge 1 "return_false" 0)
                                         (make-edge 1 "return_true" 2)
                                         (make-edge 2 "cancel" 3)
                                         (make-edge 3 "return" 0)
                                         (make-edge 3 "deadlock" 4)))))
(test-assert (test:edges->predecessor-edge-vector))

(define (test:aut-file->lts)
  (equal? (make-lts '(0)
                    2
                    (list (make-edge 0 "aap" 1)
                          (make-edge 1 "return" 0)))
          (aut-file->lts "test/lts/aap.aut")))
(test-assert (test:aut-file->lts))

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
                         (list (make-edge_ 0 "aap" #t 1)
                               (make-edge 1 "return" 0)))
               (lts-hide (make-lts 0
                                   2
                                   (list (make-edge 0 "aap" 1)
                                         (make-edge 1 "return" 0)))
                         (list "aap")))
       (equal? (make-lts 0
                         2
                         (list (make-edge_ 0 "aap(0)" #t 1)
                               (make-edge_ 0 "aap(een'twee)" #t 1)
                               (make-edge_ 0 "aap(42)" #t 1)
                               (make-edge_ 0 "aap'return(0)" #t 1)
                               (make-edge_ 0 "aapje" #f 1)
                               (make-edge 1 "return" 0)))
               (lts-hide (make-lts 0
                                   2
                                   (list (make-edge 0 "aap(0)" 1)
                                         (make-edge 0 "aap(een'twee)" 1)
                                         (make-edge 0 "aap(42)" 1)
                                         (make-edge 0 "aap'return(0)" 1)
                                         (make-edge 0 "aapje" 1)
                                         (make-edge 1 "return" 0)))
                         (list "aap" "aap'return" "noot" "mies")))))
(test-assert (test:lts-hide))

(define (test:lts->alphabet)
  (equal? (list "aap" "return")
          (lts->alphabet (make-lts 0
                                   3
                                   (list (make-edge 0 "aap" 1)
                                         (make-edge 1 "return" 0)
                                         (make-edge_ 1 "blaat" #t 42))))))
(test-assert (test:lts->alphabet))


(define (test:accept-edge-sets)
  (and (equal? (list (list (make-edge 0 "aap" 1)))
               (lts-accept-edge-sets (make-lts '(0)
                                               2
                                               (list (make-edge 0 "aap" 1)
                                                     (make-edge 1 "return" 0)))))
       (equal? (list (list (make-edge 0 "aap" 1)
                           (make-edge 0 'tau 2))
                     (list (make-edge 3 "mies" 0)))
               (lts-accept-edge-sets (make-lts '(0 3)
                                               4
                                               (list (make-edge 0 "aap" 1)
                                                     (make-edge 1 "return" 0)
                                                     (make-edge 0 'tau 2)
                                                     (make-edge 2 "noot" 3)
                                                     (make-edge 2 'tau 3)
                                                     (make-edge 3 "mies" 0)))))))
(test-assert (test:accept-edge-sets))

(define (test:lts-stable-accepts)
  (equal? (list '("aap"))
          (lts-stable-accepts (step-tau (make-lts '(0)
                                                  2
                                                  (list (make-edge 0 "aap" 1)
                                                        (make-edge 1 "return" 0))))))
  (equal? (list '("return"))
          (lts-stable-accepts (step-tau (make-lts '(1)
                                                  2
                                                  (list (make-edge 0 "aap" 1)
                                                        (make-edge 1 "return" 0))))))
  ;; Fail if tau edges not properly removed:
  (equal? (list '("mies"))
          (lts-stable-accepts (step-tau (make-lts '(0 2 3)
                                                  4
                                                  (list (make-edge 0 "aap" 1)
                                                        (make-edge 1 "return" 0)
                                                        (make-edge 0 'tau 2)
                                                        (make-edge 2 "noot" 3)
                                                        (make-edge 2 'tau 3)
                                                        (make-edge 3 "mies" 0))))))
  ;; Fail if tau edges not properly removed:
  (equal? (list '("mies"))
          (lts-stable-accepts (step-tau (make-lts '(0 2 3)
                                                  4
                                                  (list (make-edge_ 0 "aap" #f 1)
                                                        (make-edge_ 1 "return" #f 0)
                                                        (make-edge_ 0 "blaat" #t 2)
                                                        (make-edge_ 2 "noot" #f 3)
                                                        (make-edge_ 2 "blaat" #t 3)
                                                        (make-edge_ 3 "mies" #f 0)))))))
(test-assert (test:lts-stable-accepts))


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
(test-assert (test:annotate-parent))

(define (test:root)
  (let* ((lts (aut-file->lts "test/lts/verify-component.aut"))
         (lts-root (car (lts-state lts)))
         (nodes (lts->nodes lts))
         (nodes-root (root nodes)))
    (eqv? lts-root nodes-root)))
(test-assert (test:root))

(define (test:lts-tau-loops)
  (and (equal? '(3)
               (let ((nodes (lts->nodes test-lts-livelock)))
                 (lts-tau-loops nodes)))
       (equal? '(5)
               (let ((nodes (lts->nodes (lts-hide (aut-file->lts "test/lts/double-entry.aut")
                                                  (list "listIt'return" "listIt'event" "ListIt'flush")))))
                 (lts-tau-loops nodes)))
       ))
(test-assert (test:lts-tau-loops))

(define (test:trace)
  (equal? '(() ("create") ("create" "return") ("create" "return" "tau") ("cancel"))
          (let* ((lts (lts-hide (aut-file->lts "test/lts/itimer.aut") '()))
                 (test-nodes (lts->nodes lts)))
            (map (cut map edge-label <>) (map (cut trace test-nodes <>) (iota 5))))))
(test-assert (test:trace))

(define (test:tau-loop)
  (let ((actual (let* ((nodes (lts->nodes test-lts-livelock))
                       (livelock-nodes (lts-tau-loops nodes))
                       (entry-trace (trace nodes (car livelock-nodes)))
                       (entry-state (edge-end-state (last entry-trace))))
                  (tau-loop entry-state nodes))))
    (or (equal? (list (make-edge_ 3 "tau" #t 3))
                actual)
        (equal? (list (make-edge_ 3 "live" #t 4)
                      (make-edge_ 4 "lock" #t 3))
                actual))))
(test-assert (test:tau-loop))

(define (test:assert-livelock)
  (and (equal? (list (make-edge_ 0 "blaat" #t 2)
                 (make-edge_ 2 "blaat" #t 3)
                 (make-edge_ 3 "live" #t 4)
                 (make-edge_ 4 "lock" #t 3))
               (let ((nodes (lts->nodes test-lts-livelock)))
                 (assert-livelock nodes)))
       (equal? (list (make-edge_ 1 "BlindLoop'event(BlindLoop'in'start)" #f 2)
                     (make-edge_ 2 "BlindLoop'return(BlindLoop'in'start, reply_BlindLoop'Void(void))" #f 0)
                     (make-edge_ 0 "tau" #t 0))
               (let ((nodes (lts->nodes test-lts-livelock-2)))
                 (assert-livelock nodes)))
       (not (let* ((lts (lts-hide (aut-file->lts "test/lts/no-livelock.aut") '()))
                   (test-nodes (lts->nodes lts)))
              (assert-livelock test-nodes)))))
(test-assert (test:assert-livelock))

(define (test:rm-tau-loops)
  (define expect-lts
    (make-lts '(0)
              5
              (list (make-edge_ 0 "aap" #f 1)
                    (make-edge_ 1 "return" #f 0)
                    (make-edge_ 0 "blaat" #t 2)
                    (make-edge_ 2 "noot" #f 3)
                    (make-edge_ 2 "blaat" #t 3)
                    ;;(make-edge_ 3 "tau" #t 3)
                    ;;(make-edge_ 3 "live" #t 4)
                    (make-edge_ 4 "lock" #t 3)
                    ;;(make-edge_ 3 "mies" #f 0)
                    )))
  (equal? expect-lts
          (rm-tau-loops test-lts-livelock)))
(test-assert (test:rm-tau-loops))

(define (test:assert-deadlock)
  (define test-lts-deadlock
    (make-lts '(0)
              5
              (list (make-edge_ 0 "aap" #f 1)
                    (make-edge_ 1 "return" #f 0)
                    (make-edge_ 0 "blaat" #t 2)
                    (make-edge_ 2 "noot" #f 3)
                    (make-edge_ 2 "blaat" #t 3)
                    (make-edge_ 3 "tau" #t 3)
                    (make-edge_ 3 "dead" #t 4)
                    (make-edge_ 3 "mies" #f 0))))
  (equal? '("blaat" "blaat" "dead")
          (map edge-label (assert-deadlock (lts->nodes test-lts-deadlock)))))
(test-assert (test:assert-deadlock))

(define (test:assert-illegal)
  (define test-lts-illegal
    (make-lts '(0)
              5
              (list (make-edge_ 0 "aap" #f 1)
                    (make-edge_ 1 "return" #f 0)
                    (make-edge_ 0 "blaat" #t 2)
                    (make-edge_ 2 "noot" #f 3)
                    (make-edge_ 2 "blaat" #t 3)
                    (make-edge_ 3 "tau" #t 3)
                    (make-edge_ 3 "<illegal>" #t 4)
                    (make-edge_ 3 "mies" #f 0))))
  (equal? '("blaat" "blaat")
          (map edge-label (assert-illegal (lts->nodes test-lts-illegal)))))
(test-assert (test:assert-illegal))

(define (test:assert-partially-deterministic)
  (let ((deterministic-lts-1 (make-lts '(0)
                                       2
                                       (list (make-edge 0 "aap" 1)
                                             (make-edge 0 "noot" 1)
                                             (make-edge 1 "return" 0))))
        (deterministic-lts-2 (make-lts '(0)
                                       2
                                       (list (make-edge 0 "aap" 1)
                                             (make-edge 1 "true" 0)
                                             (make-edge 1 "false" 0))))
        (nondet-lts-1 (make-lts '(0)
                                3
                                (list (make-edge 0 "aap" 1)
                                      (make-edge 0 "aap" 2)
                                      (make-edge 1 "true" 0)
                                      (make-edge 2 "false" 0))))
        (nondet-lts-2 (aut-file->lts "test/lts/deterministic-fail0.aut"))
        (nondet-lts-3 (aut-file->lts "test/lts/deterministic-fail1.aut"))
        (nondet-lts-4 (aut-file->lts "test/lts/deterministic-fail2.aut")))
    (and (equal? #f (assert-partially-deterministic deterministic-lts-1 '()))
         (equal? #f (assert-partially-deterministic deterministic-lts-2 '()))
         (not (equal? #f (assert-partially-deterministic nondet-lts-1 '("aap"))))
         (not (equal? #f (assert-partially-deterministic nondet-lts-2 '("i'in(I'in'e)"))))
         (not (equal? #f (assert-partially-deterministic nondet-lts-3 '("i'in(I'in'e)"))))
         (not (equal? #f (assert-partially-deterministic nondet-lts-4 '("pp'in(I'in'ia)")))))))
(test-assert (test:assert-partially-deterministic))

(define (test:assert-deterministic)
  (let ((deterministic-lts-1 (make-lts '(0)
                                       2
                                       (list (make-edge 0 "aap" 1)
                                             (make-edge 0 "noot" 1)
                                             (make-edge 1 "return" 0))))
        (deterministic-lts-2 (make-lts '(0)
                                       2
                                       (list (make-edge 0 "aap" 1)
                                             (make-edge 1 "true" 0)
                                             (make-edge 1 "false" 0))))
        (nondet-lts-1 (make-lts '(0)
                                3
                                (list (make-edge 0 "aap" 1)
                                      (make-edge 0 "aap" 2)
                                      (make-edge 1 "true" 0)
                                      (make-edge 2 "false" 0))))
        (nondet-lts-2 (aut-file->lts "test/lts/deterministic-fail0.aut"))
        (nondet-lts-3 (aut-file->lts "test/lts/deterministic-fail1.aut"))
        (nondet-lts-4 (aut-file->lts "test/lts/deterministic-fail2.aut")))
    (and (equal? #f (assert-deterministic deterministic-lts-1))
         (equal? #f (assert-deterministic deterministic-lts-2))
         (not (equal? #f (assert-deterministic nondet-lts-1)))
         (not (equal? #f (assert-deterministic nondet-lts-2)))
         (not (equal? #f (assert-deterministic nondet-lts-3)))
         (not (equal? #f (assert-deterministic nondet-lts-4))))))
(test-assert (test:assert-deterministic))

(define (test:step-tau)
  (define test-lts (make-lts '(1)
                             4
                             (list (make-edge_ 0 "a" #f 1)
                                   (make-edge_ 1 "tau" #t 2)
                                   (make-edge_ 1 "tau" #t 3)
                                   (make-edge_ 2 "true" #f 0)
                                   (make-edge_ 3 "false" #f 0))))
  (equal? '(2 3) (lts-state (step-tau test-lts))))
(test-assert (test:step-tau))

(define (test:step)
  (define test-lts (make-lts '(0)
                             4
                             (list (make-edge_ 0 "a" #f 1)
                                   (make-edge_ 1 "tau" #t 2)
                                   (make-edge_ 1 "tau" #t 3)
                                   (make-edge_ 2 "true" #f 0)
                                   (make-edge_ 3 "false" #f 0))))
  (equal? '(2 3) (lts-state (step test-lts "a"))))
(test-assert (test:step))

(define (test:run)
  (let* ((lts-a (make-lts '(0)
                          2
                          (list (make-edge 0 "aap" 1)
                                (make-edge 1 "return" 0))))
         (lts-b (run lts-a '("aap" "return")))
         (lts-c (make-lts '(1)
                          2
                          (list (make-edge 0 "aap" 1)
                                (make-edge 1 "return" 0))))
         (lts-d (run lts-a '("aap")))
         (lts-e (make-lts '(0)
                          3
                          (list (make-edge 0 "aap" 1)
                                (make-edge 0 "aap" 2)
                                (make-edge 1 "true" 0)
                                (make-edge 2 "false" 0))))
         (lts-f1 (run lts-e '("aap" "true")))
         (lts-f2 (run lts-e '("aap" "false"))))
    (and (equal? lts-a lts-b)
         (equal? lts-c lts-d)
         (equal? lts-e lts-f1 lts-f2))))
(test-assert (test:run))

(define (test:aut-file-format-error)
  (define correct-aut
    (list "des (0,1,2)"
          "(0,\"aap\",1)"
          "(1,\"return\",0)"))
  (define wrong-aut-header
    (list "des(0,1,2)"
          "(0,\"aap\",1)"
          "(1,\"return\",0)"))
  (define wrong-edge
    (list "des (0,1,2)"
          "(0,aap,1)"
          "(1,\"return\",0)"))
  (and (not (aut-file-format-error correct-aut))
       (aut-file-format-error wrong-aut-header)
       (aut-file-format-error wrong-edge)
       #t))
(test-assert (test:aut-file-format-error))

(define (test:main)
  ;; (main (list "command" "test/lts/verify-component.aut")) ;; display lts
  (main (list "command" "--list-events" "test/lts/verify-provides.aut"))
  (main (list "command" "--list-events" "--tau" "tau;pp'flush" "test/lts/verify-provides.aut"))
  ;; (main (list "command" "--list-events" "test/lts/verify-component.aut"))
  ;; (main (list "command" "--list-accepts" "test/lts/verify-provides.aut"))
  (main (list "command" "--list-accepts" "test/lts/verify-component.aut"))
  (main (list "command" "--list-accepts"
              "--tau" "tau;pp'flush"
              "--prefix" "pp'event(II'Actions'ic);pp'return(II'Actions'ic,reply_II'Void(void))"
              "test/lts/verify-component.aut")) ;; list acceptances in initial state
  (main (list "command" "--list-accepts"
              "--prefix" "pp'event(II'Actions'ic);pp'return(II'Actions'ic,reply_II'Void(void))"
              "test/lts/verify-component.aut")) ;; list acceptances in initial state
  (main (list "command" "--list-accepts"
              "--prefix" "pp'event(II'Actions'ia);pp'return(II'Actions'ia,reply_II'Void(void))"
              "test/lts/verify-provides.aut")) ;; list acceptances in unstable state (1)
  (main (list "command" "--list-accepts"
              "--prefix" "pp'event(II'Actions'ia);pp'return(II'Actions'ia,reply_II'Void(void))"
              "--tau" "tau;pp'flush"
              "test/lts/verify-provides.aut"))
  (main (list "command" "--list-accepts"
              "--prefix" "create;hw.enable;hw.return;return;hw.interrupt"
              "--tau" "tau;hw.interrupt;hw.return;hw.disable;hw.enable"
              "test/lts/timer.aut")) ;; expect: ((timeout))

  (main (list "command" "--livelock"
              "test/lts/livelock.aut")) ;; expect: exit value: #f, stderr output: "tau loop found:\nblaat\nblaat\n"
  (main (list "command" "--livelock"
              "--tau" "list'return;list'event;list'flush"
              "test/lts/livelock-component.aut")) ;; expect: exit value: #f, stderr output: "tau loop found:iter'event(Iterage'in'map)\ntau\n"
  (main (list "command" "--livelock"
              "--tau" "tau;hw.interrupt;hw.return;hw.disable;hw.enable"
              "test/lts/timer.aut")) ;; expect: ???
  (main (list "command" "--livelock"
              "--tau" "tau"
              "test/lts/no-loop.aut")) ;; expect: exit value: ?? stderr output: "No tau loop found"

  (main (list "command" "--deterministic"
              "--tau" "tau"
              "test/lts/deterministic-fail1.aut"))
  ;; expect: exit value: #f
  ;;         stderr output: "LTS is non-deterministic"
  ;;         stdout: "i.e\ni.return\ni.e"
)
(test-assert (test:main))
(test:main)

(test-end)
