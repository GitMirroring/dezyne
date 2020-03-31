;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag commands parse)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)

  #:use-module (gaiag serialize)
  #:use-module (json)

  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag ast)
  #:use-module (gaiag goops)
  #:use-module (gaiag parse)
  #:use-module (gaiag shell-util)

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
          '((behaviour (single-char #\b) (value #f))
            (components)
            (foreigns)
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (interfaces)
            (locations (single-char #\L))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (systems)))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: dzn parse [OPTION]... [FILE]...
      --components       list components
      --foreigns         list foreign components
  -h, --help             display this help and exit
      --interfaces       list interfaces
  -I, --import=DIR+      add DIR to import path
  -L, --locations        show locations in AST
  -m, --model=MODEL      generate ast for MODEL
  -b, --behaviour        include behaviour of imported models,
  -o, --output=FILE      write ast to FILE
      --systems          list systems
")
          (exit (or (and usage? 2) 0))))
    options))

(define (parse options file-name)
  (let* ((peg? (gdzn:command-line:get 'peg #f))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (model-name (option-ref options 'model #f))
         (behaviour? (option-ref options 'behaviour #f))
         (locations? (option-ref options 'locations #f)))
    (parse-file file-name #:peg? peg? #:imports imports #:model-name model-name #:behaviour? behaviour? #:locations? locations?)))

(define (assert-parse options file-name)
  (catch #t
    (lambda _
      (parse options file-name))
    (lambda _
      (exit 1))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (debug? (gdzn:command-line:get 'debug #f))
         (peg? (gdzn:command-line:get 'peg #f)) ;; assert-parse eats error message
         (file (and (pair? files) (car files)))
         (ast ((if (or #t debug? peg?) parse assert-parse) options file)))
    (cond ((option-ref options 'output #f)
           (let* ((file-name (option-ref options 'output "-"))
                  (sexp (om->list ast))
                  (json? (gdzn:command-line:get 'json))
                  (output (if json? (scm->json-string sexp)
                              (with-output-to-string (cut pretty-print sexp)))))
             (if (equal? file-name "-") (display output)
                 (with-output-to-file file-name (cut display output)))))
          ((option-ref options 'components #f)
           (let ((pred (conjoin (is? <component>) (negate ast:imported?))))
             (display (string-join (map ast:dotted-name (tree-collect pred ast)) "\n" 'suffix))))
          ((option-ref options 'foreigns #f)
           (let ((pred (conjoin (is? <foreign>) (negate ast:imported?))))
             (display (string-join (map ast:dotted-name (tree-collect pred ast)) "\n" 'suffix))))
          ((option-ref options 'interfaces #f)
           (let ((pred (conjoin (is? <interface>) (negate ast:imported?))))
             (display (string-join (map ast:dotted-name (tree-collect pred ast)) "\n" 'suffix))))
          ((option-ref options 'systems #f)
           (let ((pred (conjoin (is? <system>) (negate ast:imported?))))
             (display (string-join (map ast:dotted-name (tree-collect pred ast)) "\n" 'suffix))))
          ((gdzn:command-line:get 'verbose) (display "parse: no errors found\n")))))
