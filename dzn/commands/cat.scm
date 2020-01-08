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

(define-module (dzn commands cat)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 rdelim)
  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn command-line)
  #:use-module (dzn parse)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((recursive (single-char #\R))
            (help (single-char #\h))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: dzn cat [OPTION]... FILE
  -h, --help             display this help and exit
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (files (map (lambda (f) (if (not (string-prefix? "/" f)) f (string-drop f 1))) files))
         (files (map (lambda (f) (if (not (string-prefix? "share/" f)) f (string-drop f 6))) files))
         ;;(root (string-append %root-dir "/fs"))
         (root %root-dir)
         (file-name (string-append root "/" (car files)))
         (gdzn-debug? (gdzn:command-line:get 'debug)))
    (when gdzn-debug?
      (stderr "root=~a\n" root))
    (chdir root)
    (let ((string (with-input-from-file file-name read-string)))
      (display string))))
