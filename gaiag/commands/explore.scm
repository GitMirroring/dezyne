;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag commands explore)
  #:use-module (ice-9 getopt-long)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag command-line)
  #:use-module (gaiag explore)
  #:use-module (gaiag commands parse)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (lts)
            (model (single-char #\m) (value #t))
            (queue-size (single-char #\q) (value #t))
            (state-diagram)))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn explore [OPTION]... [FILE]...
Explore the state space of a Dezyne model

  -f, --format=FORMAT    display trace in format FORMAT [dot] {dot,json}
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
      --lts              write the lts in AUT format to stdout
      --state-diagram    write the state diagram to stdout [default]
  -m, --model=MODEL      generate main for MODEL
  -q, --queue-size=SIZE  use queue size=SIZE for exploration [3]
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
         (parse-options (filter (negate (compose (cute eq? <> 'model) car)) options))
         (ast (parse parse-options file-name))
         (format (option-ref options 'format #f))
         (queue-size (command-line:get 'queue-size 3))
         (state-diagram? (option-ref options 'state-diagram #f))
         (lts? (option-ref options 'lts #f)))
    (cond (lts? (lts ast #:model-name model-name #:queue-size 3))
          (else (state-diagram ast
                               #:format format
                               #:model-name model-name
                               #:queue-size queue-size)))))
