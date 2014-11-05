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

(define-module (gaiag json2scm)
  :use-module (system repl error-handling)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 match)
  :use-module (ice-9 pretty-print)

  :use-module (json)
  :use-module (gaiag misc)
  :export (json->symbol-scm main))

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
Convert JSON in FILE or standard input, to scheme-AST on standard output
  -d, --debug          run with debugging
  -h, --help           display this help
  -v, --version        display version

Examples:
  ./gaiag -a \"$(cat examples/assert.json | ./json2scm)\" -l csp examples/Alarm.asd
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define (json->symbol-scm src)
  (match src
    ((? string?) (string->symbol src))
    ((h ...) (map json->symbol-scm src))
    (_ src)))

(define (->scm files)
  (json->symbol-scm
   (json->scm
    (if (null? files)
	(current-input-port)
	(open-input-file (car files))))))

(define (script files)
  (pretty-print (->scm files)))

(define (main args)
  (let* ((options (parse-opts args))
         (debug? (option-ref options 'debug #f))
	 (files (option-ref options '() '())))
    (call-with-error-handling (lambda () (script files)) :on-error (if debug? 'debug 'backtrace))))
