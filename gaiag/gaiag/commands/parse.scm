;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag shell-util)
  #:export (assert-parse
            dump-model-stream
            parse-with-options
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
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: gdzn parse [OPTION]... [FILE]...
  -h, --help             display this help and exit
  -I, --import=DIR+           add DIR to import path
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define* (parse-with-options options file-name #:key mangle? csp?)
  (let* ((gaiag? (option-ref options 'gaiag #f))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (language (string->symbol (option-ref options 'language "c++")))
         (mangle? (option-ref options 'mangle mangle?))
         (model (option-ref options 'model #f))
         ;; Only forward --model to generate for CSP, not
         ;; for executable code: generator cuts models
         (csp? (or csp? (equal? language "csp")))
         (model (and csp? model)))
    (parse-file file-name #:gaiag? gaiag? #:imports imports #:mangle? mangle? #:model model)))

(define* (assert-parse options file-name #:key mangle? csp?)
  (catch #t
    (lambda _
      (parse-with-options options file-name #:mangle? mangle? #:csp? csp?))
    (lambda _
      (exit 1))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (gdzn-verbose? (find (lambda (o) (or (equal? o "--verbose") (equal? o "-v"))) (command-line))))
    (assert-parse options (car files))
    (if gdzn-verbose? (display "parse: no errors found"))))
