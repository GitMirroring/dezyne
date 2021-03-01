;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn commands simulate)
  #:use-module (ice-9 getopt-long)
  #:use-module (srfi srfi-26)

  #:use-module (dzn command-line)
  #:use-module (dzn simulate)
  #:use-module (dzn commands parse)
  #:use-module (dzn commands trace)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (locations (single-char #\l))
            (model (single-char #\m) (value #t))
            (no-deadlock (single-char #\D))
            (queue-size (single-char #\q) (value #t))
            (strict (single-char #\s))
            (trail (single-char #\t) (value #t))
            (verbose (single-char #\v))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn simulate [OPTION]... [FILE]...
Simulate a Dezyne model

  -D, --no-deadlock      skip the deadlock check
  -f, --format=FORMAT    display trace in format FORMAT [event] {event,trace}
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -l, --locations        prepend locations to output trail,
                           implies --format=trace
  -m, --model=MODEL      generate main for MODEL
  -q, --queue-size=SIZE  use queue size=SIZE for simulation [3]
  -s, --strict           use strict matching of trail
  -t, --trail=TRAIL      use trail=TRAIL [read from stdin]
  -v, --verbose          show non-communication steps in trace,
                           implies --format=trace --locations
")
          (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (options (acons 'behaviour #t options))
         (files (option-ref options '() '()))
         (file-name (car files))
         (model-name (option-ref options 'model #f))
         ;; Parse --model=MODEL cuts MODEL from AST; avoid that
         (parse-options (filter (negate (compose (cut eq? <> 'model) car)) options))
         (ast (parse parse-options file-name))
         (no-deadlock? (option-ref options 'no-deadlock #f))
         (queue-size (command-line:get 'queue-size 3))
         (strict? (command-line:get 'strict #f))
         (verbose? (command-line:get 'verbose #f))
         (locations? (command-line:get 'locations verbose?))
         (trace (command-line:get 'format (if locations? "trace" "event")))
         (trail (option-ref options 'trail #f)))
    (simulate ast
              #:model-name model-name
              #:deadlock-check? (not no-deadlock?)
              #:locations? locations?
              #:queue-size queue-size
              #:strict? strict?
              #:trace trace
              #:trail trail
              #:verbose? verbose?)))
