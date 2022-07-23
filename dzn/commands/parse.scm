;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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

  #:use-module (dzn ast serialize)

  #:use-module (dzn ast display)
  #:use-module (dzn ast wfc)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse tree)
  #:use-module (dzn parse)
  #:use-module (dzn shell-util)

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
            (list-models (single-char #\l))
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
  -l, --list-models      print the name of each model in FILE
  -L, --locations        show locations in output AST
  -m, --model=MODEL      generate ast for MODEL
  -t, --parse-tree       write PEG parse tree
  -o, --output=FILE      write AST to FILE (\"-\" for standard output)
")
          (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (parse options file-name)
  (let* ((debug? (dzn:command-line:get 'debug #f))
         (skip-wfc? (dzn:command-line:get 'skip-wfc #f))
         (imports (command-line:get 'import))
         (locations? (command-line:get 'locations))
         (model-name (option-ref options 'model #f))
         (parse-tree? (command-line:get 'parse-tree))
         (fall-back? (command-line:get 'fall-back))
         (transform (dzn:multi-opt 'transform)))
    (parameterize ((%locations? locations?)
                   (%peg:fall-back? fall-back?))
      (let ((ast (file->ast file-name
                            #:debug? debug?
                            #:imports imports
                            #:parse-tree? parse-tree?
                            #:skip-wfc? skip-wfc?
                            #:transform transform)))
        (if (not model-name) ast
            (call-with-handle-exceptions
             (lambda _ (ast:filter-model ast (ast:get-model ast model-name)))
             #:backtrace? debug?
             #:file-name file-name))))))

(define (preprocess options file-name)
  (let* ((imports (command-line:get 'import))
         (debug? (dzn:command-line:get 'debug #f)))
    (file->stream file-name #:debug? debug? #:imports imports)))

(define (list-models file-name)
  "For each model in FILE-NAME, print 'name type'."
  (let* ((debug? (dzn:command-line:get 'debug #f))
         (text (with-input-from-file file-name read-string))
         (tree (call-with-handle-exceptions
                (lambda _
                  (parameterize ((%peg:fall-back? #t))
                    (string->parse-tree text #:file-name file-name)))
                #:backtrace? debug?
                #:file-name file-name)))
    (define (print-model context)
      (let* ((model (find tree:model? context))
             (type (cond ((is-a? model 'interface) 'interface)
                         ((tree:component? model) 'component)
                         ((tree:foreign? model) 'foreign)
                         ((tree:system? model) 'system))))
        (format #t "~a ~a\n" (context:dotted-name context) type)))
    (for-each print-model (tree:list-model* tree))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (and (pair? files) (car files)))
         (list-models? (command-line:get 'list-models))
         (debug? (dzn:command-line:get 'debug))
         (preprocess? (option-ref options 'preprocess #f)))
    (cond (preprocess?
           (display (preprocess options file-name)))
          (list-models? (list-models file-name))
          (else
           (let ((ast (parse options file-name)))
             (if (option-ref options 'output #f)
                 (let* ((file-name (option-ref options 'output "-"))
                        (locations? (command-line:get 'locations))
                        (sexp (and (not debug?)
                                   (parameterize ((%locations? locations?))
                                     (ast:serialize ast))))
                        (output (with-output-to-string
                                  (if debug? (cute ast:pretty-print ast)
                                      (cute pretty-print sexp)))))
                   (if (equal? file-name "-") (display output)
                       (with-output-to-file file-name (cut display output))))
                 (when (dzn:command-line:get 'verbose)
                   (display "parse: no errors found\n"))))))))
