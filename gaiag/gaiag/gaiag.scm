;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014, 2015, 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)

  #:use-module (ice-9 match)

  #:use-module (system repl error-handling)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag coverage)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)

  #:export (main parse-opts))


(define (parse-opts args)
  (define (interactive?)
    (let ((program (car (command-line))))
      (string-suffix? "guile" program)))
  (define (test-suite?)
    (let ((program (car (command-line))))
      (string-suffix? "run-tests" program)))
  (let* ((option-spec
	  '((assert (single-char #\a))
            (calling-context (single-char #\c) (value #t))
	    (coverage)
	    (debug (single-char #\d))
	    (glue (single-char #\g) (value #t))
            (help (single-char #\h))
            (include (single-char #\I) (value #t))
            (json (single-char #\j))
            (language (single-char #\l) (value #t))
            (lts)
            (model (single-char #\m) (value #t))
            (shell (single-char #\s) (value #t))
            (trail (single-char #\t) (value #t))
            (output (single-char #\o) (value #t))
            (queue-size (single-char #\q) (value #t))
	    (session (single-char #\S) (value #t)) ;; FIXME
	    (version (single-char #\v))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files)))
	 (version? (option-ref options 'version #f)))
    (or
     (interactive?)
     (test-suite?)
     (and version?
	  (stdout "0.1\n"))
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gaiag [OPTION]... FILE
  -a, --assert                generate all asserts inline, not in asserts.csp
  -c, --calling-context=TYPE  generate additional first event parameter with type TYPE
      --coverage              write lcov coverage data to gaiag.info
  -d, --debug                 run with debugging
  -g, --glue=TYPE             generate glue code for TYPE [dzn]
  -I, --include=DIR           append DIR to include path
  -h, --help                  display this help
  -j, --json                  use json-friendly format; strings and hash tables
  -m, --model=MODEL           use model named MODEL
  -l, --language=LANG         generate output for language=LANG [ast]
  -s, --shell=MODEL           generate thread safe system shell for MODEL
  -t, --trail=TRAIL           specify trail TRAIL for trail-walker
  -o, --output=FILE           generate output in FILE
  -v, --version               display version

Languages: c c++ cs csp dzn goops html java javascript python
           c++03 c++msvc11 java7
           ast annotate om norm-event norm-state resolve
           run table-event table-state wfc

Examples:
  ./gaiag examples/Alarm.dzn
  ./gaiag -l dzn examples/Alarm.scm
  ./gaiag -l csp examples/Alarm.dzn
  ./gaiag -l csp -o alarm.csp examples/Alarm.dzn
  ./gaiag -l c++ examples/Alarm.dzn
  ./gaiag -l wfc examples/wfc/wfc-double-on.dzn
  ./gaiag -l run -t '(arm)' examples/IConsole.dzn ./gaiag -l run -t '(console.arm)' -j examples/Alarm.dzn | ./scm2json | ../client/pretty
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
         (result (file->lang file-name language))
         (opt-include? (lambda (o) (eq? (car o) 'include))))
    (set! %include-path (append (map cdr (filter opt-include? options))
                                (list (dirname file-name))))
    (match result
      ("" #t)
      ((? string?) (display result))
      ((? pair?) (pretty-print result))
      ((? null?) (display result))
      ((? (is? <ast>)) (pretty-print (om->list result)))
      (_ #t))))

(define (main args)
  (let* ((options (parse-opts args))
         (debug? (option-ref options 'debug #f))
         (coverage? (or (option-ref options 'coverage #f)
                        (getenv "GAIAG_COVERAGE"))))
    (if coverage?
        (cover (lambda () (main- args)) (->string (getenv "ABS_BUILD") "/gaiag.lcov/gaiag-" (getpid) ".info"))
        (if debug?
         (call-with-error-handling (lambda () (main- args)))
         (main- args)))))
