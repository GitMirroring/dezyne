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
  #:use-module (dzn shell-util)
  #:use-module (dzn ast)
  #:use-module (dzn wfc)

  #:export (dump-model-stream
            parse
            parse-opts
            main))

(define (dump-model-stream)
  (let loop ((port #f) (files '()) (importeds '()))
    (let ((line (read-line)))
      (cond ((eof-object? line)
             (begin
               (when port (close port))
               (values files importeds)))
            ((string-match "^#file \"([^\"]+)\"" line)
             => (lambda (m)
                  (when port (close port))
                  (let ((file-name (match:substring m 1)))
                    (loop (open-output-file (basename file-name)) (append files (list file-name)) importeds))))
            ((string-match "^#imported \"([^\"]+)\"" line)
             => (lambda (m)
                  (when port (close port))
                  (let ((file-name (match:substring m 1)))
                    (loop (open-output-file (basename file-name)) files (append importeds (list file-name))))))
            ((string-match "^//#(import \\s*([^;]+)\\s*;\\s*)" line)
             => (lambda (m)
                  (display (match:substring m 1) port)
                  (newline port)
                  (loop port files importeds)))
            (else
             (display line port)
             (newline port)
             (loop port files importeds))))))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (locations (single-char #\L))
            (preprocess (single-char #\E))
            (parse-tree (single-char #\t))
            (output (single-char #\o) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn parse [OPTION]... [FILE]...
Parse a Dezyne file and produce an AST

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

(define (parse- options file-name)
  (let* ((skip-wfc? (dzn:command-line:get 'peg #f))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (model-name (option-ref options 'model #f))
         (locations? (command-line:get 'locations))
         (parse-tree? (command-line:get 'parse-tree)))
    (parameterize ((%locations? locations?))
      (let ((ast (file->ast file-name
                            #:imports imports
                            #:parse-tree? parse-tree?
                            #:skip-wfc? skip-wfc?)))
        (if (not model-name) ast
            (ast:filter-model ast (ast:get-model ast model-name)))))))

(define (handle-parser-exceptions file-name)
  (lambda (key . args)
    (case key
      ((syntax-error)
       (exit EXIT_FAILURE))
      ((import-error)
       (let ((file (first args))
             (import-paths (second args))
             (imported-from (third args)))
         (cond ((string=? file-name (car args))
                (format (current-error-port) "No such file: ~a\n" file-name))
               (else (format (current-error-port)
                             "No such file: ~a, in: ~a;\n"
                             file (string-join import-paths ", "))
                     (let ((from (assoc-ref imported-from (basename file))))
                       (let loop ((from from))
                         (when from
                           (format (current-error-port) "imported from ~a\n" from)
                           (loop (assoc-ref imported-from (basename from)))))))))
       (exit EXIT_FAILURE))
      ((well-formedness-error)
       (for-each wfc:report-error args)
       (exit EXIT_FAILURE))
      ((system-error)
       (let ((errno (system-error-errno (cons key args))))
         (format (current-error-port) "~a: ~a\n"
                 (strerror errno) file-name))
       (exit EXIT_FAILURE))
      (else (format (current-error-port) "internal error: ~a: ~a: ~s\n"
                    file-name key args)
            (exit EXIT_FAILURE)))))

(define (assert-parse options file-name)
  (catch #t
    (cut parse- options file-name)
    (handle-parser-exceptions file-name)))

(define (parse options file-name)
  (let* ((debug? (dzn:command-line:get 'debug #f))
         (skip-wfc? (dzn:command-line:get 'peg #f)))
    ((if (or debug? skip-wfc?) parse- assert-parse) options file-name)))

(define (assert-preprocess options file-name)
  (let* ((import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (debug? (dzn:command-line:get 'debug #f)))
    (if debug? (display (preprocess file-name #:imports imports))
        (catch #t
          (lambda _ (display (preprocess file-name #:imports imports)))
          (handle-parser-exceptions file-name)))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (and (pair? files) (car files)))
         (preprocess? (option-ref options 'preprocess #f)))
    (cond (preprocess?
           (assert-preprocess options file-name))
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
