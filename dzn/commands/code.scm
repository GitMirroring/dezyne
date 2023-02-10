;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn commands code)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 poe)
  #:use-module (dzn code)
  #:use-module (dzn config)
  #:use-module (dzn shell-util)
  #:use-module (dzn command-line)
  #:use-module (dzn commands parse)
  #:export (%languages
            parse-opts
            main))

(define %default-language "c++")
(define (list-languages dir)
  (map (cut basename <> ".go")
       (filter (cute string-contains <> dir)
               (append-map (cute find-files <> "\\.go$")
                           (filter directory-exists?
                                   %load-compiled-path)))))

(define list-languages (pure-funcq list-languages))

(define %languages
  (sort (delete-duplicates (list-languages "/dzn/code/language") string=?)
        string<))

(define (parse-opts args)
  (let* ((option-spec
          '((calling-context (single-char #\c) (value #t))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (init (value #t))
            (language (single-char #\l) (value #t))
            (locations (single-char #\L))
            (model (single-char #\m) (value #t))
            (no-constraint (single-char #\C))
            (no-non-compliance (single-char #\D))
            (no-unreachable (single-char #\U))
            (output (single-char #\o) (value #t))
            (queue-size (single-char #\q) (value #t))
            (queue-size-defer (value #t))
            (queue-size-external (value #t))
            (shell (single-char #\s) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn code [OPTION]... DZN-FILE
Generate code for Dezyne models in DZN-FILE

  -B, --no-blocking           assume system without collateral blocking
  -c, --calling-context=TYPE  generate extra parameter of TYPE for every event
  -C, --no-constraint         do not use a constraining process
  -D, --no-non-compliance     do not generate constraint-any processes
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
      --init=PROCESS          use init PROCESS for mCRL2
  -l, --language=LANG         generate code for language=LANG [~a]
  -L, --locations             prepend locations to output trace
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -q, --queue-size=SIZE       use queue size SIZE [~a]
      --queue-size-defer=SIZE
                              use queue size=SIZE [~a] for defer
      --queue-size-external=SIZE
                              use queue size=SIZE [~a] for external
  -s, --shell=MODEL           generate thread safe system shell for MODEL
  -U, --no-unreachable        do not generate unreachable code tags

Languages: ~a
" %default-language
(%queue-size) (%queue-size-defer) (%queue-size-external)
(string-join %languages ", "))
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (dir (option-ref options 'output #f))
         (calling-context (option-ref options 'calling-context #f))
         (language (option-ref options 'language %default-language))
         (locations? (option-ref options 'locations #f))
         (model (option-ref options 'model #f))
         (queue-size (command-line:get-number 'queue-size (%queue-size)))
         (queue-size-defer (command-line:get-number 'queue-size
                                                    (%queue-size-defer)))
         (queue-size-external (command-line:get-number 'queue-size
                                                       (%queue-size-external)))
         (no-constraint? (command-line:get 'no-constraint))
         (no-unreachable? (command-line:get 'no-unreachable))
         (shell (option-ref options 'shell #f)))
    (parameterize ((%calling-context calling-context)
                   (%no-constraint? no-constraint?)
                   (%locations? locations?)
                   (%no-unreachable? no-unreachable?)
                   (%queue-size queue-size)
                   (%queue-size-defer queue-size-defer)
                   (%queue-size-external queue-size-external)
                   (%shell shell))
      ;; Parse --model=MODEL cuts MODEL from AST; avoid that
      (let* ((parse-options (filter (compose not (cut eq? <> 'model) car)
                                    options))
             (ast (parse parse-options file-name)))
       (code ast
             #:calling-context calling-context
             #:dir dir
             #:model model
             #:language language
             #:locations? locations?
             #:shell shell)))))
