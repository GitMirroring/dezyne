;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  (sort (delete-duplicates (list-languages "/dzn/code/") string=?) string<))

(define (parse-opts args)
  (let* ((option-spec
          '((calling-context (single-char #\c) (value #t))
            (debug (single-char #\d))
            (glue (single-char #\g) (value #t))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (language (single-char #\l) (value #t))
            (locations (single-char #\L))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (queue-size (single-char #\q) (value #t))
            (shell (single-char #\s) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn code [OPTION]... DZN-FILE [MAP-FILE]...
Generate code for Dezyne models in DZN-FILE

  -c, --calling-context=TYPE  generate extra parameter of TYPE for every event
  -g, --glue=TYPE             generate glue for TYPE [dzn]
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -l, --language=LANG         generate code for language=LANG [~a]
  -L, --locations             prepend locations to output trace
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -q, --queue-size=SIZE       use queue size SIZE
  -s, --shell=MODEL           generate thread safe system shell for MODEL

Languages: ~a
" %default-language (string-join %languages ", "))
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (map-files (cdr args))
         (language (option-ref options 'language %default-language))
         (locations? (option-ref options 'locations #f))
         (options (if (equal? language "scheme") (acons 'behaviour #t options)
                      options))
         ;; Parse --model=MODEL cuts MODEL from AST; avoid that
         (parse-options (filter (negate (compose (cut eq? <> 'model) car)) options))
         (ast (parse parse-options file-name))
         (module (resolve-module `(dzn code ,(string->symbol language))))
         (ast-> (false-if-exception (module-ref module 'ast->))))
    (unless ast->
      (format (current-error-port) "code: no such language: ~a\n" language)
      (exit EXIT_OTHER_FAILURE))
    (parameterize ((%language language)
                   (%locations? locations?)) (ast-> ast))
    *unspecified*))
