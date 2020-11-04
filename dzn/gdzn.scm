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

(define-module (dzn gdzn)
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
	  '((core (single-char #\c))
            (debug (single-char #\d))
            (help (single-char #\h))
            (json (single-char #\j))
	    (peg (single-char #\p))
	    (verbose (single-char #\v))
	    (version (single-char #\V))))
	 (options (getopt-long args option-spec
		               #:stop-at-first-non-option #t))
	 (core? (option-ref options 'core #f))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files)))
	 (version? (option-ref options 'version #f)))

    (define (list-commands dir)
      (map (cut basename <> ".go")
           (filter (disjoin
                    (cute string-contains <> dir)
                    (conjoin (negate (const core?))
                             (cute string-contains <> "/ide/commands/")))
                   (append-map (cute find-files <> "\\.go$")
                               (filter directory-exists?
                                       %load-compiled-path)))))

    (or
     (and version?
	  ((stdout "dzn ~a\n" %version) (exit 0)))
     (and (or help? usage?)
          ((or (and usage? stderr) stdout)
           (let* ((core-commands (list-commands "/dzn/commands/"))
                  (ide-commands (list-commands "/ide/commands/"))
                  (commands (sort
                             (delete-duplicates
                              (append core-commands ide-commands)
                              string=?)
                             string<)))
             (string-append "\
Usage: dzn [OPTION]... COMMAND [COMMAND-ARGUMENT...]
  -c, --core             run core commands only
  -d, --debug            enable debug ouput
  -h, --help             display this help
  -j, --json             output json
  -p, --peg              use plain PEG, skip well-formedness
  -v, --verbose          be more verbose, show progress
  -V, --version          display version

Commands:"
                            (string-join commands "\n  " 'prefix)
                            "

Use \"dzn COMMAND --help\" for command-specific information.
")))
	  (exit (or (and usage? EXIT_OTHER_FAILURE) 0)))
     options)))

(define parse-opts (pure-funcq parse-opts))

(define* (run-command args #:key core?)
  (let* ((command (string->symbol (car args)))
         (core-module (resolve-module `(dzn commands ,command)))
         (ide-module (resolve-module `(ide commands ,command)))
         (main (or (and (not core?) (false-if-exception (module-ref ide-module 'main)))
                   (false-if-exception (module-ref core-module 'main)))))
    (unless main
      (format (current-error-port) "dzn: no such command: ~a\n" command)
      (exit EXIT_OTHER_FAILURE))
    (main args)))

(define (main args)
  (let* ((options (parse-opts args))
         (command-args (option-ref options '() '()))
         (command (and (pair? command-args) (car command-args)))
         (debug? (option-ref options 'debug #f))
         (core? (option-ref options 'core #f)))
    (if (getenv "DZN_REPL") (call-with-error-handling
                             (lambda _ (run-command command-args #:core? core?)))
        (run-command command-args #:core? core?))))
