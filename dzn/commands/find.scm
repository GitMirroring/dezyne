;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (dzn commands find)
  #:use-module (ice-9 getopt-long)
  #:use-module (dzn code)
  #:use-module (dzn code language makreel)
  #:use-module (dzn commands parse)
  #:use-module (dzn ast)
  #:use-module (dzn find)
  #:use-module (dzn command-line)
  #:export (main))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
            (import (single-char #\I) (value #t))
            (lts (single-char #\l) (value #t))
            (model (single-char #\m) (value #t))
            (trace (single-char #\t) (value #t))))
         (options (getopt-long args option-spec))
         (help? (option-ref options 'help #f)))
    (when help?
      (format #t "\
Usage: dzn find [OPTION]... [FILE]
Find a concrete trace with matches the given trace possibly containing *s
  -h, --help                  display this help and exit
  -m, --model=MODEL           the model MODEL to be used
  -l, --lts=FILE              don't generate lts but use lts from FILE.
  -t, --trace=TRACE           find trace TRACE
")
      (exit EXIT_SUCCESS))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (verbose? (dzn:command-line:get 'verbose #f))
         (files (option-ref options '() '()))
         (lts (option-ref options 'lts #f))
         (model-name (option-ref options 'model #f))
         (trace (option-ref options 'trace #f))
         (trace (if (not trace) '()
                    (string-split (string-trim-both trace)
                                  (char-set #\, #\; #\space))))
         (file-name (car files))
         (ast (parse options file-name))
         (root (parameterize ((%no-unreachable? #t))
                 (makreel:normalize ast)))
         (models (ast:model* root))
         (trace (find:find root models model-name trace lts
                           #:verbose? verbose?)))
    (if trace
        (display trace)
        (display "No match found for given trace.\n" (current-error-port)))))
