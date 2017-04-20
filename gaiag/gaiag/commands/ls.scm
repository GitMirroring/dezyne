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

(define-module (gaiag commands ls)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gaiag reader)
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
Usage: gdzn ls [OPTION]... [FILE]...
  -h, --help             display this help and exit
  -R, --recursive        list subdirectories recursively
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (files (map (lambda (f) (if (not (string-prefix? "/" f)) f (string-drop f 1))) files))
         (debug? (find (cut equal? <> "--debug") (command-line)))
         (recursive? (option-ref options 'recursive #f))
         (prefix (getenv "DEZYNE_PREFIX"))
         (services (if (access? (string-append prefix "/root") R_OK) prefix
                       (string-append prefix "/services")))
         (root (string-append services "/root/fs")))
    ;;(stderr "root=~a\n" root)
    (chdir root)
    (let* ((string (gulp-pipe
                    (string-append "ls -1 -F -L"
                                   (if (not recursive?) ""
                                       " -R")
                                   (string-join files " " 'prefix))))
           (lines (string-split string #\newline))
           (output (let loop ((dir "") (lines lines))
                     (if (null? lines) '()
                         (let* ((line (car lines))
                                (line (cond ((string-prefix? "/" line) (string-drop line 1))
                                            ((string-prefix? "./" line) (string-drop line 2))
                                            (else line))))
                            (if (string-suffix? ":" line)
                                (loop (string-append (string-drop-right line 1) "/") (cdr lines))
                                (cons (string-append dir line) (loop dir (cdr lines)))))))))
      (display (string-join output "\n" 'suffix)))))
