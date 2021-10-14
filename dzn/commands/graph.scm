;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2021 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (dzn commands graph)
  #:use-module (ice-9 getopt-long)
  #:use-module (srfi srfi-26)

  #:use-module (dzn command-line)
  #:use-module (dzn explore)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn parse)
  #:use-module (dzn commands parse)
  #:use-module (dzn vm normalize)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((backend (single-char #\b) (value #t))
            (behaviour (single-char #\B))
            (format (single-char #\f) (value #t))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (locations (single-char #\L))
            (model (single-char #\m) (value #t))
            (queue-size (single-char #\q) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn graph [OPTION]... [FILE]...
Generate graph from a Dezyne model

  -b, --backend=TYPE     write a graph of TYPE to stdout [system]
                           {dependency,lts,state,system}
  -B, --behaviour        disregard the interaction with, and state of ports
                           implies --backend=state
  -f, --format=FORMAT    produce graph in format FORMAT [dot] {aut,dot,json}
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -L, --locations        include locations in graph
  -m, --model=MODEL      produce graph for MODEL
  -q, --queue-size=SIZE  use queue size=SIZE for exploration [3]

")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (model-name (option-ref options 'model #f))
         (behaviour? (option-ref options 'behaviour #f))
         (backend (option-ref options 'backend (if behaviour? "state"
                                                   "system")))
         (dependency? (equal? backend "dependency"))
         (lts? (equal? backend "lts"))
         (state? (equal? backend "state"))
         (debug? (dzn:command-line:get 'debug #f))
         (locations? (option-ref options 'locations #f))
         ;; Parse --model=MODEL cuts MODEL from AST; avoid that
         (parse-options (filter (negate (compose (cute eq? <> 'model) car))
                                options))
         (ast (parse parse-options file-name))
         (root (if (member backend '("lts" "state")) (vm:normalize ast) ast))
         (model (call-with-handle-exceptions
                 (lambda _ (ast:get-model root model-name))
                 #:backtrace? debug?
                 #:file-name file-name))
         (language (option-ref options 'format "dot"))
         (queue-size (string->number (command-line:get 'queue-size "3"))))
    (unless model
      (format (current-error-port) "~a: No dezyne model found.\n" file-name)
      (exit EXIT_OTHER_FAILURE))
    (cond (behaviour? (state-diagram root
                                     #:behaviour? #t
                                     #:format language
                                     #:model model
                                     #:queue-size queue-size))
          (dependency? (code root
                             #:ast-> 'dependency-diagram
                             #:model model
                             #:language language))
          (lts? (lts root #:model model #:queue-size queue-size))
          (state? (state-diagram root
                                 #:format language
                                 #:model model
                                 #:queue-size queue-size))
          (else (code root
                      #:ast-> 'system-diagram
                      #:model model
                      #:language language
                      #:locations? locations?)))))
