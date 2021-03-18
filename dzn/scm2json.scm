;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(define-module (dzn scm2json)
  #:use-module (system repl error-handling)
  #:use-module (ice-9 getopt-long)
  #:use-module (json)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:export (main))

(define (parse-opts args)
  (let* ((option-spec
	  '((debug (single-char #\d))
            (help (single-char #\h))
	    (version (single-char #\v))))
	 (options (getopt-long (command-line) option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (> (length files) 1)))
	 (version? (option-ref options 'version #f)))
    (when version?
      (format #t "0.1\n")
      (exit EXIT_SUCCESS))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: scm2json [OPTION]... FILE
Convert scheme-AST in FILE or standard input, to JSON on standard output
  -d, --debug          run with debugging
  -h, --help           display this help
  -v, --version        display version

Examples:
  echo \"(console.arm console.disarm sensor.disabled)\" | ./scm2json
  ./dzn -l simulate -t \"$(cat examples/Alarm-trail.scm)\" examples/Alarm.dzn | ./scm2json
")
	   (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
     options))

(define (->json files)
  (display (scm->json-string
            (read
             (if (null? files)
                 (current-input-port)
                 (open-input-file (car files))))))
  (newline))

(define (main args)
  (let* ((options (parse-opts args))
         (debug? (option-ref options 'debug #f))
	 (files (option-ref options '() '())))
    (if debug?
        (call-with-error-handling (lambda () (->json files)))
        (->json files))))
