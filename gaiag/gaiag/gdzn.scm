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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag gdzn)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:export (main))

(define (parse-opts args)
  (let* ((option-spec
	  '((debug (single-char #\d))
            (help (single-char #\h))
	    (verbose (single-char #\v))
	    (version (single-char #\V))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files)))
	 (version? (option-ref options 'version #f)))
    (or
     (and version?
	  (stdout "0.1\n"))
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn [OPTION]... COMMAND [COMMAND-ARGUMENT...]
  -d, --debug        enable debug ouput
  -h, --help         display this help
  -v, --verbose      be more verbose, show progress
  -V, --version      display version
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define (run-command args)
  (let* ((command (string->symbol (car args)))
         (module (resolve-module `(gaiag commands ,command)))
         (main (module-ref module 'main)))
    (main args)))

(define (main args)
  (let* ((options (parse-opts args))
         (command (option-ref options '() '()))
         (debug? (option-ref options 'debug #f)))
    (run-command command)))
