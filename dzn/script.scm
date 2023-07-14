;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2022, 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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
  #:use-module (ice-9 documentation)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (system repl error-handling)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (dzn command-line)
  #:use-module (dzn shell-util)
  #:export (main
            parse-opts
            script:command
            script:command-module))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (help (single-char #\h))
            (skip-wfc (single-char #\p))
            (timings (single-char #\T))
            (transform (single-char #\t) (value #t))
            (verbose (single-char #\v))
            (version (single-char #\V))))
         (options (getopt-long args option-spec
                               #:stop-at-first-non-option #t))
         (verbose? (option-ref options 'verbose #f))
         (help? (option-ref options 'help #f))
         (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files)))
         (version? (option-ref options 'version #f)))

    (define (list-commands dir)
      (map (cut basename <> ".go")
           (filter
            (cute string-contains <> dir)
            (append-map
             (cute list-directory <>
                   (cute string-suffix? ".go" <>))
             (filter directory-exists?
                     (map (cute string-append <> "/dzn/commands/")
                          %load-compiled-path))))))

    (when version?
      (show-version-and-exit))
    (when (or help? usage?)
      (let* ((port (if usage? (current-error-port) (current-output-port)))
             (commands (list-commands "/dzn/commands/"))
             (commands (sort (delete-duplicates commands string=?) string<))
             (transform (resolve-interface `(dzn transform)))
             (symbol.var->string.doc
              (match-lambda
                ((symbol . var)
                 (cons (string-append "  " (symbol->string symbol))
                       (object-documentation (variable-ref var))))))
             (transformations (map symbol.var->string.doc
                                   (module-map cons transform)))
             (string< (lambda (a b) (string< (car a) (car b))) )
             (transformations (sort transformations string<))
             (prologue-length (map (compose string-length car) transformations))
             (tabs (ceiling (/ (apply max prologue-length) 8)))
             (string.doc->string
              (match-lambda
                ((string . doc)
                 (let* ((prologue (string-append string ":"))
                        (block-format (cute block-format <> prologue tabs 80))
                        (doc (and=> doc block-format)))
                   (if (not doc) string
                       (string-append doc "\n")))))))
        (format port "\
Usage: dzn [OPTION]... COMMAND [COMMAND-ARGUMENT...]
  -d, --debug            enable debug ouput
  -h, --help             display this help
  -p, --skip-wfc         use plain PEG, skip well-formedness checking
  -v, --verbose          be more verbose, show progress
  -V, --version          display version
  -t, --transform=TRANS  use transformation TRANS
  -T,--timings           show timings

Commands:~a

Transformations: ~a

Use \"dzn COMMAND --help\" for command-specific information.
"
                (string-join commands "\n  " 'prefix)
                (if verbose? (string-join
                              (map string.doc->string transformations)
                              "\n" 'prefix)
                    "Use dzn --help --verbose to list transformations.")))
      (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS)))
    options))

(define parse-opts (pure-funcq parse-opts))

(define* (script:command #:key (options (parse-opts (command-line))))
  (match (command:command-line options)
    ((command rest ...) (string->symbol command))
    (_ #f)))

(define* (script:command-module #:key (options (parse-opts (command-line))))
  (let ((command (script:command #:options options)))
    (resolve-module `(dzn commands ,command))))

(define (run-command args)
  (let* ((options (parse-opts args))
         (command (script:command #:options options))
         (module (script:command-module #:options options))
         (main (and module (false-if-exception (module-ref module 'main))))
         (command-args (command:command-line options)))
    (unless main
      (format (current-error-port) "dzn: no such command: ~a\n" command)
      (exit EXIT_OTHER_FAILURE))
    (main command-args)))

(define (main args)
  (let ((repl? (getenv "DZN_REPL")))
    (if repl? (call-with-error-handling (cute run-command args))
        (run-command args))))
