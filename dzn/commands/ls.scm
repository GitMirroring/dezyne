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

(define-module (dzn commands ls)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn command-line)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((recursive (single-char #\R))
            (help (single-char #\h))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: dzn ls [OPTION]... [FILE]...
List available Dezyne runtime support files

  -h, --help             display this help and exit
  -R, --recursive        list subdirectories recursively
")
          (exit EXIT_SUCCESS)))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (files (map (lambda (f) (if (not (string-prefix? "/" f)) f (string-drop f 1))) files))
         (files (map (lambda (f) (if (not (string-prefix? "share/" f)) f (string-drop f 6))) files))
         (recursive? (option-ref options 'recursive #f))
         ;;(root (string-append %root-dir "/fs"))
         (root %root-dir)
         (dzn-debug? (dzn:command-line:get 'debug)))
    (when dzn-debug?
      (stderr "root=~a\n" root))
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
