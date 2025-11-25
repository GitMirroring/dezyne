;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021, 2022, 2023, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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
;;; The design of this module is predicated on executing a binary
;;; providing it with inputs and checking its outputs following a depth
;;; first search path through the LTS until each transition in the LTS
;;; has been executed, or until an optional retry limit is reached.
;;;
;;; The rationale for the depth first search is to reduce the overhead
;;; of restarting the binary as well as to keep the backtracking state
;;; on the stack.
;;;
;;; Every time the path reaches a node on the path, we restart the
;;; binary along a new variation of the current path, until all
;;; variations run out or an optional retry limit is reached.
;;;
;;; Testing behavior with non-deterministic choices as a result of
;;; hiding increases the test time dramatically due to the increase of
;;; the number of retries to produce a specific path.
;;;
;;; Open issues:
;;;
;;; - Interface testing
;;; - Add flush to i/o LTS
;;; - Multi threaded testing for [collateral] blocking
;;; - Data
;;;
;;; Code:

(define-module (dzn test)
  #:use-module ((rnrs base) #:prefix rnrs:)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-43)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 rdelim)

  #:use-module (dzn trace)
  #:use-module (dzn misc)
  #:use-module (dzn pipe)

  #:export (aut->lts
            lts->aut
            test))

;;;
;;; LTS
;;;
(define-record-type <transition>
  (make-transition from label to)
  transition?
  (from transition-from)
  (label transition-label)
  (to transition-to))

(define (aut->lts file-name)
  "Read an AUT (Aldebaran format) file with name FILE-NAME and return an
LTS. An LTS is a vector of states, where a state is a vector of
transitions and a transition is a label and a to state index."
  (define (comma->space c)
    (if (eq? c #\,) #\space c))
  (define (string->scm string)
    (with-input-from-string string read))
  (let* ((port (open-input-file file-name))
         (des (read-line port))
         (size-string (substring des 4))
         (scm-size-string (string-map comma->space size-string))
         (scm-size (string->scm scm-size-string)))
    (match scm-size
      ((start transitions states)
       (let ((lts (let loop ((line (read-line port 'concat)))
                    (if (eof-object? line) '()
                        (let* ((scm-string (string-map comma->space line))
                               (transition (string->scm scm-string)))
                          (match transition
                            ((from label to)
                             (cons (make-transition from label to)
                                   (loop (read-line port 'concat))))))))))
         (close port)
         (values lts start))))))

(define (transition->aut t)
  (format #f "(~a,~s,~a)\n"
          (transition-from t)
          (transition-label t)
          (transition-to t)))

(define* (lts->aut lts start #:optional (port (current-error-port)))
  (format port "des (~a,~a,~a)\n"
          start
          (length lts)
          (1+ (fold (lambda (t states) (max states (transition-from t))) 0 lts)))
  (for-each
   (compose (cute display <> port) transition->aut)
   lts))

(define (dot-preamble start)
  (format
   #t
   "digraph G {
~a[shape=doublecircle,width=0.2,fillcolor=black,style=filled,label=\"\"]
node[shape=circle,width=0.2,label=\"\"]\n" start))

(define (dot-postamble)
  (format #t "}"))

(define (transition->dot t)
  (format #f "~a [xlabel=~s]\n~a -> ~a [label=~s]\n"
          (transition-from t)
          (transition-from t)
          (transition-from t)
          (transition-to t)
          (transition-label t)))

(define (transitions->dot lts)
  (for-each
   (compose display transition->dot)
   lts))

(define (lts->dot lts start)
  (dot-preamble start)
  (transition->dot lts)
  (dot-postamble))

(define (node->transitions from lts)
  (filter (compose (cute = from <>) transition-from) lts))

(define node->transitions (pure-funcq node->transitions))


;;;
;;; Test execution
;;;
(define-record-type <ports>
  (make-ports output input error)
  ports?
  (output ports-output)
  (input ports-input)
  (error ports-error))

(define (test:pipeline* proc)
  ;;(pke 'start)
  (let ((output input error pids (pipeline* `((,proc "--flush")))))
    (values (make-ports output input error)
            pids)))

(define (test:stop-pipeline* ports pids)
  ;;(pke 'stop)
  (close (ports-output ports))
  (close (ports-input ports))
  (close (ports-error ports))
  (map (cute kill <> SIGINT) pids)
  (for-each (lambda (pid) (false-if-exception (waitpid pid))) pids))

(define (quiescent? ms i)
  (let* ((t (* ms 1000))
         (s us (rnrs:div-and-mod t 1000000)))
    (match (select `(,i) '() '() s us)
      ((() () ()) #t)
      ((r () ()) #f))))


;;;
;;; Label predicates
;;;
(define (suffix label)
  (string-join (cdr (string-split label #\.)) "."))

(define (defer? label)
  (equal? "<defer>" label))

(define (illegal? line)
  (string-contains line "<illegal>"))

(define (input? transition)
  (string-prefix? "in." (transition-label transition)))

(define (output? transition)
  (string-prefix? "out." (transition-label transition)))

(define (return? transition)
  (string-suffix? ".return" (transition-label transition)))


;;;
;;; Trace
;;;;
(define (trace transitions)
  (string-join (map transition-label transitions)))


;;;
;;; Exploration/execution
;;;
(define ms 100)

(define* (io:write i o transition #:key debug?)
  (let ((label (suffix (transition-label transition))))
    ;;(pke 'io:write label)
    (write-line label o)
    (force-output o)
    (cond ((defer? label)
           transition)
          ((not (quiescent? ms i))
           (let loop ()
             (let ((line (read-line i 'concat)))
               (when debug?
                 (format (current-error-port) "write:echo: ~a" line))
               (and (not (eof-object? line))
                    (let* ((flush? (string-suffix? "<flush>\n" line))
                           (output (if flush? line (trace:format-trace line #:format "event")))
                           (output (string-trim-right output char-set:whitespace)))
                      (if (string-null? output) (loop)
                          (if (equal? label output) transition
                                  (and (simple-format
                                        (current-error-port) "~a != ~a\n"
                                        label output)
                                       #f))))))))
          (else
           #f))))

(define* (io:read i o #:key debug?)
  "When there the process is not quiescent read until the output is not
string-null? then echo it back and return it otherwise #f"
  ;;(pke 'io:read)
  (and (not (quiescent? 100 i))
       (let ((line (read-line i 'concat)))
         (when debug?
           (format (current-error-port) "read:echo: ~a~a"
                   line (if (eof-object? line) "\n" "")))
         (and (not (eof-object? line))
              (if (illegal? line) "<illegal>"
                  (let* ((output (trace:format-trace line #:format "event"))
                         (output (string-trim-right output char-set:whitespace)))
                    (cond
                     ((string-null? output)
                      (io:read i o #:debug? debug?))
                     (else
                      (write-line output o)
                      (force-output o)
                      output))))))))

(define* (execute i o transitions #:key debug?)
  (let ((inputs outputs (partition input? transitions)))
    ;;(pke 'execute 'i: (map transition-label inputs) 'o: (map transition-label outputs))
    (cond ((pair? outputs)
           (let ((output (io:read i o #:debug? debug?)))
             (find (compose (cute equal? output <>)
                            suffix transition-label)
                   outputs)))
          ((pair? inputs)
           (io:write i o (car inputs) #:debug? debug?))
          (else
           #f))))

(define* (replay i o path #:key debug?)
  ;; (pke 'replay (length path))
  (let* ((replayed
          (let loop ((path path))
            (cond ((null? path)
                   '())
                  ((execute i o (list (car path)) #:debug? debug?)
                   =>
                   (lambda (t)
                     (if (not (eq? (car path) t)) (list t)
                         (cons t (loop (cdr path))))))
                  (else
                   '()))))
         (replayed? (and (<= (length path) (length replayed))
                         (every eq? path replayed))))
    (when (and debug? (not replayed?))
      (pke 'failed-replay (trace replayed)
           'missing (trace (drop path (length replayed)))))
    replayed?))

(define* (explore i o explored lts from #:key debug?)
  "TODO optimize lset-difference"
  (let ((path
         (let loop ((path '()) (from from))
           (let ((transitions (lset-difference
                               (conjoin (lambda (a b) (not (return? a))) eq?)
                               (node->transitions from lts)
                               path
                               (node->transitions from explored))))
             (cond ((null? transitions)
                    path)
                   (else
                    (let ((t (execute i o transitions #:debug? debug?)))
                      (if (not t) path
                          (loop (cons t path) (transition-to t))))))))))
    (when (and #f (pair? path))
      (pke 'explore (transition-from (last path)) (trace (reverse path))))
    path))

(define (path lts from to)
  "Return the shortest path between FROM and TO, using a breadth first
search, remove longer candidates that reach the same node along the way."
  (define (extend paths)
    "Determine extensions for each path remove candidates already covered"
    (append-map
     (lambda (path)
       (let* ((from (transition-to (car path)))
              (extensions (node->transitions from lts))
              (extensions (lset-difference eq? extensions
                                           (apply append paths))))
         (if (null? extensions) '()
             (map (cute cons <> path) extensions))))
     paths))
  (define (reduce paths)
    "Remove the longer path joining a shorter path"
    (fold (lambda (path paths)
            (let ((join (find (compose
                               (cute = (transition-to (car path)) <>)
                               transition-to car)
                              paths)))
              (cond ((not join)
                     (cons path paths))
                    ((<= (length join) (length path))
                     paths)
                    (else
                     (cons path (delete join paths))))))
          '() paths))
  (if (= from to) '()
      (let loop ((paths (map list (node->transitions from lts))))
        (if (null? paths) '()
            (let ((paths (extend paths))
                  (shortest (find (compose (cute = to <>) transition-to car) paths)))
              (or shortest
                  (loop (reduce paths))))))))

(define path (pure-funcq path))

(define (underexplored explored lts from)
  "Determine an under explored state from the difference between EXPLORED
and LTS and return a trace to it."
  (cond
   ((null? explored) from)
   (else
    (let* ((delta (lset-difference eq? lts explored))
           (to (transition-from (car delta))))
      to))))

(define* (test proc lts from #:key debug? retry format)
  "When PROC is not running, explore the LTS returning accumulated result
LTS, repeat explore until delta empty return true, or give up return LTS
difference (optionally in DOT output showing missing and extraneous
transitions in different colors)."
  (let ((explored
         (let loop ((explored '()) (retries 0))
           (cond
            ((< retry retries)
             explored)
            ((lset= eq? lts explored)
             explored)
            (else
             (when debug?
               (simple-format (current-error-port) "\n~a\n\n" proc))
             (let* ((ports pids (test:pipeline* proc))
                    (to (underexplored explored lts from))
                    (path (reverse (path lts from to)))
                    (replayed? (replay (ports-error ports)
                                       (ports-output ports)
                                       path
                                       #:debug? debug?))
                    (path (if (not replayed?) '()
                              (explore (ports-error ports)
                                       (ports-output ports)
                                       explored lts to
                                       #:debug? debug?))))
               (test:stop-pipeline* ports pids)
               (if (pair? path) (loop (lset-union eq? path explored) retries)
                   (loop explored (1+ retries)))))))))
    (cond ((equal? "aut" format) (lts->aut explored from (current-output-port)))
          ((equal? "dot" format)
           (let ((expect "black")
                 (missing "magenta")
                 (extraneous "cyan")
                 (diff intersect (lset-diff+intersection eq? lts explored)))
             (dot-preamble from)
             (simple-format #t "node[color=~a]\nedge[penwidth=2,color=~a,fontcolor=~a]\n" expect expect expect)
             (transitions->dot intersect)
             (simple-format #t "node[color=~a]\nedge[penwidth=2,color=~a,fontcolor=~a]\n" missing missing missing)
             (transitions->dot diff)
             (simple-format #t "node[color=~a]\nedge[color=~a,fontcolor=~a]\n" extraneous extraneous extraneous)
             (dot-postamble)))
          (else
           explored))))
