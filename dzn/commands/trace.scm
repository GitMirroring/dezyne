;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn commands trace)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 rdelim)

  #:use-module (dzn command-line)
  #:use-module (dzn trace)
  #:export (main))

(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (internal (single-char #\i))
            (locations (single-char #\L))
            (trail (single-char #\t) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f)))
    (when help?
      (format #t "\
Usage: dzn trace [OPTION]... FILE
Convert between different trace formats

  -f, --format=FORMAT    display trace in format FORMAT [event] {code,diagram,event,json,sexp}
  -h, --help             display this help and exit
  -i, --internal         display system-internal events
  -L, --locations        prepend locations to output trace
  -t, --trail=TRAIL      use trail=TRAIL [read from stdin]
")
      (exit EXIT_SUCCESS))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (if (pair? files) (car files) "-"))
         (trail (command-line:get 'trail))
         (trace (or trail
                    (if (equal? file-name "-") (read-string)
                        (with-input-from-file (car files) read-string))))
         (format (option-ref options 'format "event"))
         (internal? (command-line:get 'internal #f))
         (locations? (command-line:get 'locations #f))
         (debug? (dzn:command-line:get 'debug))
         (trace (trace:format-trace trace
                                    #:debug? debug?
                                    #:file-name file-name
                                    #:format format
                                    #:internal? internal?
                                    #:locations? locations?)))
    (display trace)))
