;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag gdzn)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 poe)
  #:use-module (system repl error-handling)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (gaiag config)
  #:use-module (gaiag misc)
  #:use-module (gaiag shell-util)
  #:export (main
            parse-opts))

(define (parse-opts args)
  (let* ((option-spec
	  '((debug (single-char #\d))
	    (generator (single-char #\g))
            (help (single-char #\h))
            (html (single-char #\H))
            (json (single-char #\j))
	    (peg (single-char #\p))
	    (session (single-char #\S) (value #t))
	    (verbose (single-char #\v))
	    (version (single-char #\V))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files)))
	 (version? (option-ref options 'version #f)))

    (or
     (and version?
	  ((stdout "gdzn ~a\n" %service-version) (exit 0)))
     (and (or help? usage?)
          ((or (and usage? stderr) stdout)
           (let ((commands (map (cut basename <> ".go") (find-files %command-dir ".*.go"))))
             (string-append "\
Usage: gdzn [OPTION]... COMMAND [COMMAND-ARGUMENT...]
  -d, --debug            enable debug ouput
  -h, --help             display this help
  -H, --html             output html
  -j, --json             output json
  -g, --generator        use generator
  -p, --peg              use plain PEG, skip well-formedness
  -S, --session=SESSION  use session=SESSION [1]
  -v, --verbose          be more verbose, show progress
  -V, --version          display version

Commands:"
                                  (string-join commands "\n  " 'prefix)
                                  "

Use \"gdzn COMMAND --help\" for command-specific information.
")))
	   (exit (or (and usage? 2) 0)))
     options)))

(define parse-opts (pure-funcq parse-opts))

(define (run-command args)
  (setenv "PATH" (string-append %service-bindir ":" (getenv "PATH")))
  (let* ((command (string->symbol (car args)))
         (module (resolve-module `(gaiag commands ,command)))
         (main (module-ref module 'main)))
    (main args)))

(define (service-version args)
  (define (version-option? o)
    (or (string-prefix? "--version" o)
        (string-prefix? "-V" o)))
  (let ((v (drop-while (negate version-option?) args)))
    (and (pair? v)
         (let ((opt (car v)))
           (cond ((member opt '("-V" "--version")) (cadr v))
                 ((string-prefix? "--version=" opt) (cadr (string-split opt #\=)))
                 ((string-prefix? "-V" opt) (string-drop opt 2))
                 (else (error "error parsing version option" opt)))))))
-
(define (exec-gdzn-version version args)
  (let* ((service-bindir (string-append %service-versions-dir "/" version "/bin"))
         (gdzn (string-append service-bindir "/gdzn")))
    (if (not (access? gdzn (logior R_OK X_OK))) (error (format #f "gdzn: no such version: ~a" version))
        (let ((self? (equal? (canonicalize-path (car (command-line)))
                             (canonicalize-path gdzn))))
          (if self? (run-command args) ; for development: avoid loop
              (apply execl gdzn gdzn args))))))

(define (main args)
  (let* ((options (parse-opts args))
         (command-args (option-ref options '() '()))
         (command (and (pair? command-args) (car command-args)))
         (debug? (option-ref options 'debug #f))
         (service-version (service-version command-args)))
    (if (and #f service-version (not (equal? service-version %service-version)))
        (exec-gdzn-version service-version (cdr args))
        (if (getenv "GDZN_REPL") (call-with-error-handling (cut run-command command-args))
            (run-command command-args)))))
