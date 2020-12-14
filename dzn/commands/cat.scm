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
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 rdelim)
  #:use-module (dzn config)
  #:use-module (dzn command-line)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((recursive (single-char #\R))
            (help (single-char #\h))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn cat [OPTION]... FILE
Copy a Dezyne runtime support file to standard output

  -h, --help             display this help and exit
")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (files (map (lambda (f) (if (not (string-prefix? "/" f)) f (string-drop f 1))) files))
         (files (map (lambda (f) (if (or (equal? f "share") (equal? f "share/")) "." f)) files))
         (files (map (lambda (f) (if (not (string-prefix? "share/" f)) f (string-drop f 6))) files))
         (root %root-dir)
         (file-name (string-append root "/" (car files)))
         (dzn-debug? (dzn:command-line:get 'debug)))
    (when dzn-debug?
      (format (current-error-port) "root=~a\n" root))
    (chdir root)
    (let ((string (with-input-from-file file-name read-string)))
      (display string))))
