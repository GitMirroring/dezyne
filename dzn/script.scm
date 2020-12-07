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

(define-module (dzn script)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 poe)
  #:use-module (system repl error-handling)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (dzn config)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:export (main
            parse-opts))

(define (parse-opts args)
  (let* ((option-spec
	  '((debug (single-char #\d))
            (help (single-char #\h))
            (json (single-char #\j))
	    (peg (single-char #\p))
	    (verbose (single-char #\v))
	    (version (single-char #\V))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files)))
	 (version? (option-ref options 'version #f)))

    (define (list-commands dir)
      (map (cut basename <> ".go")
           (filter (cute string-contains <> dir)
                   (append-map (cute find-files <> "\\.go$")
                               (filter directory-exists?
                                       %load-compiled-path)))))

    (when version?
      (format (current-output-port) "dzn ~a\n" %version)
      (exit EXIT_SUCCESS))
    (when (or help? usage?)
      (let* ((port (if usage? (current-error-port) (current-output-port)))
             (commands (list-commands "/dzn/commands/"))
             (commands (sort (delete-duplicates commands string=?) string<)))
        (format port "\
Usage: dzn [OPTION]... COMMAND [COMMAND-ARGUMENT...]
  -d, --debug            enable debug ouput
  -h, --help             display this help
  -j, --json             output json
  -p, --peg              use plain PEG, skip well-formedness
  -v, --verbose          be more verbose, show progress
  -V, --version          display version

Commands:~a

Use \"dzn COMMAND --help\" for command-specific information.
"
                (string-join commands "\n  " 'prefix)))
      (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS)))
    options))

(define parse-opts (pure-funcq parse-opts))

(define (run-command args)
  (let* ((command (string->symbol (car args)))
         (module (resolve-module `(dzn commands ,command)))
         (main (and module (false-if-exception (module-ref module 'main)))))
    (unless main
      (format (current-error-port) "dzn: no such command: ~a\n" command)
      (exit EXIT_OTHER_FAILURE))
    (main args)))

(define (main args)
  (let* ((options (parse-opts args))
         (command-args (option-ref options '() '()))
         (command (and (pair? command-args) (car command-args)))
         (debug? (option-ref options 'debug #f)))
    (if (getenv "DZN_REPL") (call-with-error-handling (cut run-command command-args))
        (run-command command-args))))
