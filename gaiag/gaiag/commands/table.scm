;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (gaiag commands table)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:use-module (gaiag om)
  #:use-module (gaiag command-line)
  #:use-module (gaiag commands parse)
  #:use-module (gaiag shell-util)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (diagram (single-char #\d)) ;; FIXME
            (form (single-char #\f) (value #t))
            (gaiag (single-char #\G))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn table [OPTION]... DZN-FILE
FIXME  -d, --diagram          produce svg diagram output
  -f, --form=FORM        generate table for normal form=FORM [state]
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -m, --model=NAME       generate table for model=NAME
  -o, --output=DIR       write output to DIR (use - for stdout)
  -V, --version=VERSION  use service version=VERSION
")
	   (exit (or (and usage? 2) 0)))
     options)))

(use-modules (ice-9 pretty-print))
(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (map-files (cdr args))
         (form (option-ref options 'form "state"))
         (ast (parse-with-options options file-name))
         (gdzn-debug? (gdzn:command-line:get 'debug))
         (out-dir (option-ref options 'output ".")))
    (if gdzn-debug? (stderr "AST:\n ~s\n" ast))
    (let ((result (if (equal? form "state") ((@ (gaiag table-state) ast->) ast)
                      ((@ (gaiag table-event) ast->) ast))))
      (if (equal? out-dir "-") (if (pair? result) (pretty-print result) (display result))
          (let* ((ext (if (pair? result) ".scm" ".dzn"))
                 (base (basename file-name ".dzn"))
                 (base (basename base ".scm"))
                 (out-file-name (string-append out-dir "/" base "-" form ext)))
            (mkdir-p (dirname out-file-name))
            (with-output-to-file out-file-name
              (lambda _
                (if (pair? result) (pretty-print result) (display result)))))))
    *unspecified*))
