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
;;; Algorithm pseudo code:
;;; - primitives:
;;;
;;;
;;; Open issues:
;;;
;;; - Interface testing
;;; - Add flush to i/o LTS
;;; - Multi threaded testing for [collateral] blocking
;;; - Data
;;;
;;; Code:

(define-module (dzn commands test)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)

  #:use-module (dzn command-line)
  #:use-module (dzn test)

  #:export (main))

(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (retry (single-char #\r) (value #t))))
	 (options (getopt-long args option-spec))
         (files (option-ref options '() '()))
	 (help? (option-ref options 'help #f))
         (usage? (and (not help?) (not (= (length files) 2)))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn test [OPTION]... LTS PROGRAM
Explore entire LTS state of PROGRAM.

  -f, --format=FORMAT      output format to use for LTS {aut,dot} [aut]
  -h, --help               display this help and exit
  -r, --retry=VALUE        retry VALUE times upon failure (0 means infinite)
")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (debug? (= (dzn:debugity) 1))
         (files (option-ref options '() '()))
         (format (option-ref options 'format "aut"))
         (retry (string->number (option-ref options 'retry "0"))))
    (match files
      ((aut file)
       (let ((lts initial (aut->lts aut)))
         (when debug?
           (lts->aut lts initial))
         (test file lts initial
               #:debug? debug?
               #:retry retry
               #:format format))))))
