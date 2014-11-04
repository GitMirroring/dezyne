;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag gaiag)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 match)

  :use-module (system repl error-handling)

  :use-module (gaiag coverage)
  :use-module (gaiag misc)
  :use-module (gaiag pretty-print)
  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (gaiag gom)

  :export (main parse-opts))

(define (parse-opts args)
  (let* ((option-spec
	  '((assert (single-char #\a))
	    (coverage (single-char #\c))
	    (debug (single-char #\d))
            (help (single-char #\h))
            (json (single-char #\j))
            (language (single-char #\l) (value #t))
            (model (single-char #\m) (value #t))
            (trail (single-char #\t) (value #t))
            (output (single-char #\o) (value #t))
	    (version (single-char #\v))))
	 (options (getopt-long args option-spec
		   :stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files)))
	 (version? (option-ref options 'version #f)))
    (or
     (and version?
	  (stdout "0.1\n")
	  (exit 0))
      (and (or help? usage?)
	   ((or (and usage? stderr) stdout) "\
Usage: gaiag [OPTION]... FILE
  -a, --assert         generate all asserts inline, not in asserts.csp
  -c, --coverage       write lcov coverage data to gaiag.info
  -d, --debug          run with debugging
  -h, --help           display this help
  -j, --json           use json-friendly format; strings and hash tables
  -m, --model=MODEL    use model named MODEL
  -l, --language=LANG  generate output for language=LANG [ast]
  -t, --trail=TRAIL    specify trail TRAIL for trail-walker
  -o, --output FILE    generate FILE containing the output
  -v, --version        display version

Languages: asd c++ csp goops java javascript python
           ast annotate gom normstate resolve simulate table wfc

Examples:
  ./gaiag examples/Alarm.asd
  ./gaiag -l asd examples/Alarm.scm
  ./gaiag -l csp examples/Alarm.asd
  ./gaiag -l csp -o alarm.csp examples/Alarm.asd
  ./gaiag -l c++ examples/Alarm.asd
  ./gaiag -l wfc examples/wfc/wfc-double-on.asd
  ./gaiag -l simulate -t '(a a a a)' examples/regression/If.asd
  ./gaiag -l simulate -t '(a a a a)' -j examples/regression/If.asd | ./scm2json
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define (file->lang file-name language)
  (catch 'syntax-error
    (lambda ()
      ((module-ref (resolve-module `(gaiag ,language)) 'ast->) (read-ast file-name)))
    (lambda (key x message location token d . r)
      (let ((file-name (or (assoc-ref location 'filename) file-name))
            (line (or (assoc-ref location 'line) ""))
            (column (or (assoc-ref location 'column) "")))
        (stderr "~a:~a:~a:~a~a\n" file-name line column message token)))))

(define (main- args)
  (let* ((options (parse-opts args))
	 (file-name (car (option-ref options '() '())))
         (language (string->symbol (option-ref options 'language "ast")))
         (result (file->lang file-name language)))
    (match result
      ("" #t)
      ((? string?) (display result))
      ((? pair?) (pretty-print result))
      ((? null?) (display result))
      ((? (is? <ast>)) (pretty-print (gom->list result)))
      (_ #t))))

(define (main args)
  (let* ((options (parse-opts args))
         (debug? (option-ref options 'debug #f))
         (coverage? (option-ref options 'coverage #f)))
    (if coverage?
        (cover (lambda () (main- args)) (list 'gaiag '.info))
        (call-with-error-handling (lambda () (main- args))
                                  :on-error (if debug? 'debug 'backtrace)))))
