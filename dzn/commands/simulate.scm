;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

  #:use-module (dzn ast goops)
  #:use-module (dzn command-line)
  #:use-module (dzn commands parse)
  #:use-module (dzn simulate)
  #:use-module (dzn trace)

  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (internal (single-char #\i))
            (locations (single-char #\l))
            (model (single-char #\m) (value #t))
            (no-compliance (single-char #\C))
            (no-deadlock (single-char #\D))
            (no-interface-determinism)
            (no-interface-livelock)
            (no-queue-full (single-char #\Q))
            (no-refusals (single-char #\R))
            (queue-size (single-char #\q) (value #t))
            (state (single-char #\s))
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

  -C, --no-compliance    skip the compliance check
  -D, --no-deadlock      skip the deadlock check
  -Q, --no-queue-full    skip the external queue-full check
  -R, --no-refusals      skip the refusals check
  -f, --format=FORMAT    display trace in format FORMAT [event] {diagram,event,trace}
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -i, --internal         display system-internal events
  -l, --locations        prepend locations to output trail,
                           implies --format=trace
  -m, --model=MODEL      generate main for MODEL
      --no-interface-determinism
                         skip interface RTC determinism check
      --no-interface-livelock
                         skip interface livelock check at EOT
  -q, --queue-size=SIZE  use queue size=SIZE for simulation [3]
      --state            show state after every action, trigger
  -s, --strict           use strict matching of trail
  -t, --trail=TRAIL      use trail=TRAIL [read from stdin]
  -v, --verbose          show non-communication steps in trace,
                           implies --format=trace --locations
")
          (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (model-name (option-ref options 'model #f))
         ;; Parse --model=MODEL cuts MODEL from AST; avoid that
         (parse-options (filter (negate (compose (cut eq? <> 'model) car)) options))
         (ast (parse parse-options file-name))
         (no-compliance? (option-ref options 'no-compliance #f))
         (no-deadlock? (option-ref options 'no-deadlock #f))
         (no-interface-determinism?
          (option-ref options 'no-interface-determinism #f))
         (no-interface-livelock?
          (option-ref options 'no-interface-livelock #f))
         (no-queue-full? (option-ref options 'no-queue-full #f))
         (no-refusals? (option-ref options 'no-refusals #f))
         (queue-size (command-line:get-number 'queue-size 3))
         (state? (command-line:get 'state #f))
         (strict? (command-line:get 'strict #f))
         (verbose? (command-line:get 'verbose #f))
         (internal? (command-line:get 'internal #f))
         (locations? (command-line:get 'locations verbose?))
         (trace (command-line:get 'format "trace"))
         (trail (option-ref options 'trail #f))
         (status (simulate ast
                           #:model-name model-name
                           #:compliance-check? (not no-compliance?)
                           #:deadlock-check? (not no-deadlock?)
                           #:interface-determinism-check?
                           (not no-interface-determinism?)
                           #:interface-livelock-check?
                           (not no-interface-livelock?)
                           #:queue-full-check? (not no-queue-full?)
                           #:refusals-check? (not no-refusals?)
                           #:internal? internal?
                           #:locations? locations?
                           #:queue-size queue-size
                           #:state? state?
                           #:strict? strict?
                           #:trace trace
                           #:trail trail
                           #:verbose? verbose?)))
    (when (is-a? status <error>)
      (exit EXIT_FAILURE))))
