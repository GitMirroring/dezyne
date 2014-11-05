;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag scm2json)
  :use-module (system repl error-handling)
  :use-module (ice-9 getopt-long)

  :use-module (srfi srfi-10)

  :use-module (json)
  :use-module (gaiag hash)
  :use-module (gaiag misc)
  :export (main))

(define (parse-opts args)
  (let* ((option-spec
	  '((debug (single-char #\d))
            (help (single-char #\h))
	    (version (single-char #\v))))
	 (options (getopt-long (command-line) option-spec
                               :stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (>1 (length files))))
	 (version? (option-ref options 'version #f)))
    (or
     (and version?
	  (stdout "0.1\n")
	  (exit 0))
      (and (or help? usage?)
	   ((or (and usage? stderr) stdout) "\
Usage: scm2json [OPTION]... FILE
Convert scheme-AST in FILE or standard input, to JSON on standard output
  -d, --debug          run with debugging
  -h, --help           display this help
  -v, --version        display version

Examples:
  echo \"(console.arm console.disarm sensor.disabled)\" | ./scm2json
  ./gaiag -l simulate -t \"$(cat examples/Alarm-trail.scm)\" examples/Alarm.asd | ./scm2json
")
	   (exit (or (and usage? 2) 0)))
     options)))

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
    (call-with-error-handling (lambda () (->json files)) :on-error (if debug? 'debug 'backtrace))))
