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
  #:use-module (dzn misc)
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
            (output (single-char #\o) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: dzn parse [OPTION]... [FILE]...
  -E, --preprocess       resolve imports
  -h, --help             display this help and exit
  -L, --locations        show locations in output AST
  -I, --import=DIR+      add DIR to import path
  -m, --model=MODEL      generate ast for MODEL
  -o, --output=FILE      write ast to FILE
")
          (exit (or (and usage? 2) 0))))
    options))

(define (parse- options file-name)
  (let* ((skip-wfc? (gdzn:command-line:get 'peg #f))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (model-name (option-ref options 'model #f))
         (ast (file->ast file-name #:skip-wfc? skip-wfc? #:imports imports)))
    (if (not model-name) ast
        (ast:filter-model ast (ast:get-model ast model-name)))))

(define (handle-parser-exceptions file-name)
  (lambda (key . args)
    (case key
      ((syntax-error)
       (exit 1))
      ((import-error)
       (format (current-error-port)
               "No such file: ~a: imported from ~a in: ~a\n"
               (car args) file-name (cdr args))
       (exit 1))
      ((well-formedness-error)
       (for-each wfc:report-error args)
       (exit 1))
      ((system-error)
       (let ((errno (system-error-errno (cons key args))))
         (format (current-error-port) "~a: ~a\n"
                 (strerror errno) file-name))
       (exit 1))
      (else (format (current-error-port) "internal error: ~a: ~a: ~s\n"
                    file-name key args)
            (exit 1)))))

(define (assert-parse options file-name)
  (catch #t
    (cut parse- options file-name)
    (handle-parser-exceptions file-name)))

(define (parse options file-name)
  (let* ((debug? (gdzn:command-line:get 'debug #f))
         (skip-wfc? (gdzn:command-line:get 'peg #f)))
    ((if (or debug? skip-wfc?) parse- assert-parse) options file-name)))

(define (assert-preprocess options file-name)
  (let* ((import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (debug? (gdzn:command-line:get 'debug #f)))
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
                        (json? (gdzn:command-line:get 'json))
                        (locations? (command-line:get 'locations))
                        (sexp (parameterize ((%locations? locations?))
                                (ast:serialize ast)))
                        (output (if json? (scm->json-string sexp)
                                    (with-output-to-string
                                      (cute pretty-print sexp)))))
                   (if (equal? file-name "-") (display output)
                       (with-output-to-file file-name (cut display output))))
                 (when (gdzn:command-line:get 'verbose)
                   (display "parse: no errors found\n"))))))))
