;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag commands parse)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:export (assert-generator-parse
            generator-parse
            parse-opts
            main))

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

(define (generator-parse options file-name)
  (let* ((import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (command (string-append
                   "PATH=" (dirname (car (command-line))) ":bin:../bin:$PATH" ;; FIXME
                   " generate "
                   (string-join imports " -I " 'prefix)
                   " " file-name)))
    (if gdzn-debug? (stderr "command: ~a\n" command))
    (display (gulp-pipe command))))

(define (assert-generator-parse options file-name)
  (catch #t
    (lambda _
      (generator-parse options file-name))
    (lambda _
      (exit 1))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '())))
    (assert-generator-parse options (car files))))
