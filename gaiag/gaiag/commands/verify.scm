;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag commands verify)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (gaiag json2scm)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:use-module (gaiag commands parse)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((all (single-char #\a))
            (debug (single-char #\d))
            (gaiag (single-char #\G))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (queue (single-char #\q) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn verify [OPTION]... DZN-FILE [MAP-FILE]...
  -a, --all                   run all checks
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -q, --queue-size=SIZE       use queue size=SIZE for verification [3]
FIXME:  -V, --version=VERSION       use service version=VERSION
")
	   (exit (or (and usage? 2) 0)))
     options)))

(use-modules (ice-9 pretty-print))

(define ((result->string file-name) result)
  (let* ((check (assoc-ref result 'assert))
         (model (assoc-ref result 'model))
         (trace (assoc-ref result 'trace))
         (trace (map symbol->string trace))
         (micro-trace (assoc-ref result 'sequence))
         (trace (apply string-join `(,trace "\n" prefix))))
    (if (pair? micro-trace)
        (let* ((micro-trace (reverse micro-trace))
               (error (car micro-trace))
               (message (assoc-ref error 'message))
               (message (symbol->string message))
               (location (find (lambda (e) (and=> (assoc-ref e 'selection)
                                                  (compose (cut assoc-ref <> 'file) car)))
                               (map cdr micro-trace)))
               (location (and=> (assoc-ref location 'selection) car))
               (file (assoc-ref location 'file))
               (line (assoc-ref location 'line))
               (column (assoc-ref location 'column))
               (index (assoc-ref location 'index)))
          (format (current-error-port) "~a:~a:~a:i~a: ~a\n" file-name line column index message)
          (format #f "verify: ~a: check: ~a: ~a~a" model check "fail" trace))
        (let ((gdzn-verbose? (or (find (cut equal? <> "--verbose") (command-line))
                                 (find (cut equal? <> "-v") (command-line)))))
          (if gdzn-verbose?
              (format #f "verify: ~a: check: ~a: ~a~a" model check "ok" trace)
              "")))))

(define (verify options file-name)
  (let* ((bin ((compose dirname car) (command-line)))
         (prefix (dirname bin))
         (prefix (if (file-exists? (string-append prefix "/services")) prefix
                     (dirname prefix)))
         (services (string-append prefix "/services"))
         (model (option-ref options 'model #f))
         (all? (option-ref options 'all #f))
         (q (option-ref options 'queue-size "3"))
         (verify.js (string-append services "/scripts/verify.js"))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (imports (cons* (dirname file-name) (dirname (canonicalize-path file-name)) imports))
         (command (string-append
                   verify.js
                   " --model=" model
                   " --queue=" q
                   (string-join imports " -I " 'prefix)
                   " " file-name
                   " | " bin "/json2scm"))
         (sexp (with-input-from-string (gulp-pipe command) read))
         (progress (append-map (lambda (e) (or (assoc-ref e 'progress)
                                               (assoc-ref e 'result) '()
                                               '())) sexp))
         (traces (filter (lambda (p) (pair? (assoc-ref p 'sequence))) progress))
         (results (filter (lambda (p) (assoc-ref p 'assert)) progress))
         (results (if (or all? (null? results)) results (list (car results))))
         (output (map (result->string file-name) results)))
    (display (apply string-join `(,output "\n" suffix)))
    (if (pair? traces) (exit 1))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files)))
    (assert-generator-parse options file-name)
    (verify options file-name)))
