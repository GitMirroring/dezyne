;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (gaiag commands view)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:export (main))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: gdzn query [OPTION]...
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -v, --verbose          be more verbose, show progress
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define (main args)
  (let ((options (parse-opts args)))
    #t))
