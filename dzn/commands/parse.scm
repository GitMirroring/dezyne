;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn commands parse)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)

  #:use-module (dzn serialize)
  #:use-module (json)

  #:use-module (dzn command-line)
  #:use-module (dzn parse)
  #:use-module (dzn parse peg)
  #:use-module (dzn shell-util)
  #:use-module (dzn ast)
  #:use-module (dzn wfc)

  #:export (parse
            parse-opts
            preprocess
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((fall-back (single-char #\f))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (locations (single-char #\L))
            (preprocess (single-char #\E))
            (parse-tree (single-char #\t))
            (output (single-char #\o) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn parse [OPTION]... [FILE]...
Parse a Dezyne file and produce an AST

  -f, --fall-back        use fall-back parser
  -E, --preprocess       resolve imports and produce content stream
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -L, --locations        show locations in output AST
  -m, --model=MODEL      generate ast for MODEL
  -t, --parse-tree       write PEG parse tree
  -o, --output=FILE      write AST to FILE (\"-\" for standard output)
")
          (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (parse options file-name)
  (let* ((debug? (dzn:command-line:get 'debug #f))
         (skip-wfc? (dzn:command-line:get 'peg #f))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (locations? (command-line:get 'locations))
         (model-name (option-ref options 'model #f))
         (parse-tree? (command-line:get 'parse-tree))
         (fall-back? (command-line:get 'fall-back)))
    (parameterize ((%locations? locations?)
                   (%peg:fall-back? fall-back?))
      (let ((ast (file->ast file-name
                            #:debug? debug?
                            #:imports imports
                            #:parse-tree? parse-tree?
                            #:skip-wfc? skip-wfc?)))
        (if (not model-name) ast
            (ast:filter-model ast (ast:get-model ast model-name)))))))

(define (preprocess options file-name)
  (let* ((import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (debug? (dzn:command-line:get 'debug #f)))
    (file->stream file-name #:debug? debug? #:imports imports)))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (and (pair? files) (car files)))
         (preprocess? (option-ref options 'preprocess #f)))
    (cond (preprocess?
           (display (preprocess options file-name)))
          (else
           (let ((ast (parse options file-name)))
             (if (option-ref options 'output #f)
                 (let* ((file-name (option-ref options 'output "-"))
                        (json? (dzn:command-line:get 'json))
                        (locations? (command-line:get 'locations))
                        (sexp (parameterize ((%locations? locations?))
                                (ast:serialize ast)))
                        (output (if json? (scm->json-string sexp)
                                    (with-output-to-string
                                      (cute pretty-print sexp)))))
                   (if (equal? file-name "-") (display output)
                       (with-output-to-file file-name (cut display output))))
                 (when (dzn:command-line:get 'verbose)
                   (display "parse: no errors found\n"))))))))
