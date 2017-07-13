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

(define-module (gaiag commands query)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:use-module (gaiag shell-util)
  #:export (main service-versions))

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
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define* (get-prefix #:key (resolve? #t))
  (let* ((path (car (command-line)))
         (path (if (string-index path #\/) path
                   (search-path (string-split (getenv "PATH") #\:) path)))
         (path (if resolve? (canonicalize-path path) path))
         (prefix ((compose dirname dirname) path)))
    prefix))

(define (service-versions)
  (let* ((prefix (get-prefix #:resolve? #f))
         (services-dir (if (file-exists? (string-append prefix "/gaiag/gaiag")) (dirname prefix)
                            (string-append prefix "/services")))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line))))
    (when gdzn-debug?
      (stderr "prefix: ~s\n" prefix)
      (stderr "services-dir: ~s\n" services-dir))
    (sort (map basename (find-files services-dir ".*")) equal?)))

(define (show-versions options)
  (let* ((versions (service-versions))
         (version (option-ref options 'version (basename (get-prefix))))
         (versions (map (lambda (v) (if (equal? v version) (string-append "* " v) (string-append "  " v))) versions))
         (versions-string (string-join versions "\n")))
    (format (current-output-port) "~a\n" versions-string)))

(define (main args)
  (let ((options (parse-opts args)))
    (show-versions options)))
