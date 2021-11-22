;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2018, 2019, 2020, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2019, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)

  #:use-module (ice-9 match)

  #:use-module (dzn lts)
  #:use-module (test dzn automake))

(define annotate-parent (@@ (dzn lts) annotate-parent))
(define aut-file->lts (@@ (dzn lts) aut-file->lts))
(define construct-lts (@@ (dzn lts) construct-lts))
(define edge-to (@@ (dzn lts) edge-to))
(define initial (@@ (dzn lts) initial))
(define last (@@ (dzn lts) last))
(define lts-tau-loops (@@ (dzn lts) lts-tau-loops))
(define main (@@ (dzn commands lts) main))
(define make-aut-header (@@ (dzn lts) make-aut-header))
(define make-edge (@@ (dzn lts) make-edge))
(define make-node (@@ (dzn lts) make-node))
(define node-distance (@@ (dzn lts) node-distance))
(define node-parent (@@ (dzn lts) node-parent))
(define node-succ (@@ (dzn lts) node-succ))
(define tau-loop (@@ (dzn lts) tau-loop))
(define text->aut-header (@@ (dzn lts) text->aut-header))
(define text->edge (@@ (dzn lts) text->edge))
(define trace (@@ (dzn lts) trace))

(define (make-lts initial states edges)
  (let* ((header (make-aut-header initial (length edges) states))
         (lts (construct-lts header edges)))
    lts))

(define (test-lts-livelock)
  (make-lts 0
            5
            (list (make-edge 0 " aap" 1)
                  (make-edge 1 "return" 0)
                  (make-edge 0 "blaat" 2 #:tau? #t)
                  (make-edge 2 "noot" 3)
                  (make-edge 2 "blaat" 3 #:tau? #t)
                  (make-edge 3 "live" 4 #:tau? #t)
                  (make-edge 4 "lock" 3 #:tau? #t)
                  (make-edge 3 "tau" 3)
                  (make-edge 3 "mies" 0))))

(define (test-lts-livelock-2)
  (make-lts 1
            3
            (list (make-edge 0 "tau" 0)
                  (make-edge 2 "BlindLoop'return(BlindLoop'in'start, reply_BlindLoop'Void(void))" 0)
                  (make-edge 1 "BlindLoop'event(BlindLoop'in'start)" 2))))

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

(define (test:aut-file->lts)
  (equal? (make-lts 0
                    2
                    (list (make-edge 0 "aap" 1)
                          (make-edge 1 "return" 0)))
          (aut-file->lts "test/lts/aap.aut")))
(test-assert (test:aut-file->lts))

(define (lts-edges lts)
  (append-map node-succ (vector->list lts)))

(define (test:lts-hide)
  (and (equal?
         (lts-edges
           (make-lts 0
                     2
                     (list (make-edge 0 "aap" 1 #:tau? #t)
                     (make-edge 1 "return" 0))))
         (lts-edges
           (lts-hide (make-lts 0
                               2
                               (list (make-edge 0 "aap" 1)
                                     (make-edge 1 "return" 0)))
                     '("aap") '())))
       (equal? (make-lts 0
                         2
                         (list (make-edge 0 "aap(0)" 1 #:tau? #t)
                               (make-edge 0 "aap(een'twee)" 1 #:tau? #t)
                               (make-edge 0 "aap(42)" 1 #:tau? #t)
                               (make-edge 0 "aap'return(0)" 1 #:tau? #t)
                               (make-edge 0 "aapje" 1)
                               (make-edge 1 "return" 0)))
               (lts-hide (make-lts 0
                                   2
                                   (list (make-edge 0 "aap(0)" 1)
                                         (make-edge 0 "aap(een'twee)" 1)
                                         (make-edge 0 "aap(42)" 1)
                                         (make-edge 0 "aap'return(0)" 1)
                                         (make-edge 0 "aapje" 1)
                                         (make-edge 1 "return" 0)))
                         '("aap" "aap'return" "noot" "mies") '()))))
(test-assert (test:lts-hide))

(define (test:annotate-parent)
  (define (assert lts)
    (let* ((lts (vector->list lts))
           (nodes-without-distance (filter (lambda (n) (negative? (node-distance n))) lts))
           (nodes-without-parent (filter (negate node-parent) lts)))
      (and (equal? 0 (length nodes-without-distance)) ;; no unreachable nodes in test-lts
           (equal? 1 (length nodes-without-parent))))) ;; initial node has no parent
  (let ((lts (test-lts-livelock)))
    (assert (annotate-parent lts))))
(test-assert (test:annotate-parent))

(define (test:lts-tau-loops)
  (and (equal? '(3)
               (let ((lts (test-lts-livelock)))
                 (lts-tau-loops lts)))
       (equal? '(5)
               (let ((lts (lts-hide (aut-file->lts "test/lts/double-entry.aut")
                                      '("listIt'return" "listIt'event" "ListIt'flush") '())))
                 (lts-tau-loops lts)))))

(test-assert (test:lts-tau-loops))

(define (test:tau-loop)
  (let ((actual (let* ((lts (test-lts-livelock))
                       (livelock-nodes (lts-tau-loops lts))
                       (entry-trace (trace lts (car livelock-nodes)))
                       (entry-state (edge-to (last entry-trace))))
                  (tau-loop entry-state lts))))
    (or (equal? (list (make-edge 3 "tau" 3 #:tau? #t))
                actual)
        (equal? (list (make-edge 3 "live" 4 #:tau? #t)
                      (make-edge 4 "lock" 3 #:tau? #t))
                actual))))
(test-assert (test:tau-loop))

(define (test:assert-livelock)
  (and (equal? (list (make-edge 0 "blaat" 2 #:tau? #t)
                     (make-edge 2 "noot" 3)
                     (make-edge -1 "<loop>" -1 #:tau? #t)
                     (make-edge 3 "tau" 3 #:tau? #t))
               (let ((lts (test-lts-livelock)))
                 (assert-livelock lts)))
       (equal? (list (make-edge 1 "BlindLoop'event(BlindLoop'in'start)" 2)
                     (make-edge 2 "BlindLoop'return(BlindLoop'in'start, reply_BlindLoop'Void(void))" 0)
                     (make-edge -1 "<loop>" -1 #:tau? #t)
                     (make-edge 0 "tau" 0))
               (let ((lts (test-lts-livelock-2)))
                 (assert-livelock lts)))
       (not (let* ((test-lts (lts-hide (aut-file->lts "test/lts/no-livelock.aut") '() '())))
              (assert-livelock test-lts)))))
(test-assert (test:assert-livelock))

(define (test:assert-deadlock)
  (define test-lts-deadlock
    (make-lts 0
              5
              (list (make-edge 0 "aap" 1)
                    (make-edge 1 "return" 0)
                    (make-edge 0 "blaat" 2 #:tau? #t)
                    (make-edge 2 "blaat" 3 #:tau? #t)
                    (make-edge 2 "noot" 3)
                    (make-edge 3 "tau" 3 #:tau? #t)
                    (make-edge 3 "dead" 4 #:tau? #t)
                    (make-edge 3 "mies" 0))))
  (equal? '("blaat" "noot" "dead")
          (map edge-label (assert-deadlock test-lts-deadlock))))
(test-assert (test:assert-deadlock))

(define (test:assert-illegal)
  (define test-lts-illegal
    (make-lts 0
              5
              (list (make-edge 0 "aap" 1)
                    (make-edge 1 "return" 0)
                    (make-edge 0 "blaat" 2 #:tau? #t)
                    (make-edge 2 "blaat" 3 #:tau? #t)
                    (make-edge 2 "noot" 3)
                    (make-edge 3 "tau" 3 #:tau? #t)
                    (make-edge 3 "<illegal>" 4 #:tau? #t)
                    (make-edge 3 "mies" 0))))
  (equal? '("blaat" "noot")
          (map edge-label (assert-illegal test-lts-illegal))))
(test-assert (test:assert-illegal))

(define (test:assert-nondeterministic)
  (let ((deterministic-lts-1 (make-lts 0
                                       2
                                       (list (make-edge 0 "aap" 1)
                                             (make-edge 0 "noot" 1)
                                             (make-edge 1 "return" 0))))
        (deterministic-lts-2 (make-lts 0
                                       2
                                       (list (make-edge 0 "aap" 1)
                                             (make-edge 1 "true" 0)
                                             (make-edge 1 "false" 0))))
        (nondet-lts-1 (make-lts 0
                                3
                                (list (make-edge 0 "aap" 1)
                                      (make-edge 0 "aap" 2)
                                      (make-edge 1 "true" 0)
                                      (make-edge 2 "false" 0))))
        (nondet-lts-2 (aut-file->lts "test/lts/deterministic-fail0.aut"))
        (nondet-lts-3 (aut-file->lts "test/lts/deterministic-fail1.aut"))
        (nondet-lts-4 (aut-file->lts "test/lts/deterministic-fail2.aut")))
    (and (eq? #f (assert-nondeterministic deterministic-lts-1 '()))
         (eq? #f (assert-nondeterministic deterministic-lts-2 '()))
         (not (eq? #f (assert-nondeterministic nondet-lts-1 '("aap"))))
         (not (eq? #f (assert-nondeterministic nondet-lts-2 '("i'in(I'in'e)"))))
         (not (eq? #f (assert-nondeterministic nondet-lts-3 '("i'in(I'in'e)"))))
         (not (eq? #f (assert-nondeterministic nondet-lts-4 '("pp'in(I'in'ia)")))))))
(test-assert (test:assert-nondeterministic))


(define (test:main)
  (main '("command" "--livelock"
          "test/lts/livelock.aut")) ;; expect: exit value: #f, stderr output: "tau loop found:\nblaat\nblaat\n"
  (main '("command" "--livelock"
          "--tau" "list'return;list'event;list'flush"
          "test/lts/livelock-component.aut")) ;; expect: exit value: #f, stderr output: "tau loop found:iter'event(Iterage'in'map)\ntau\n"
  (main '("command" "--livelock"
          "--tau" "tau;hw.interrupt;hw.return;hw.disable;hw.enable"
          "test/lts/timer.aut")) ;; expect: ???
  (main '("command" "--livelock"
          "--tau" "tau"
          "test/lts/no-loop.aut")) ;; expect: exit value: ?? stderr output: "No tau loop found"
  )
(test-assert (test:main))
(test:main)

(test-end)
