;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn commands exec)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (dzn command-line)
  #:use-module (dzn misc))

(define (parse-opts args)
  (let* ((option-spec
          '((force (single-char #\f))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (verbose (single-char #\v))))
	 (options (getopt-long args option-spec #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn exec [OPTION]... COMMAND-LINE
Run any COMMAND-LINE

  -h, --help             display this help and exit
  -v, --verbose          be verbose; show command to be executed
")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (debug? (dzn:command-line:get 'debug))
         (command-line (option-ref options '() '()))
         (verbose? (or (command-line:get 'verbose)
                       (dzn:command-line:get 'debug)
                       (dzn:command-line:get 'verbose))))

    (match command-line
      ((command args ...)
       (when debug?
         (format (current-error-port) "exec: ~a\n" (string-join command-line)))
       (apply execlp command command-line)))))
