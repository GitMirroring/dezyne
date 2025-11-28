;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2022, 2023, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (system repl error-handling)

  #:use-module (ice-9 documentation)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)

  #:use-module (dzn ast ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:use-module (dzn timing)
  #:use-module (dzn timing instrument)

  #:declarative? #f ;for timing instrumentation

  #:export (main
            parse-opts
            script:command
            script:command-module))

;; Procedures to instrument with display-duration
;; the first entry also prints accumulated times.
(define %time
  `(((dzn script) run-command)
    ((dzn parse) parse:file->content-alist)
    ((dzn parse) parse:string->content-alist)
    ((dzn parse) parse:content-alist->tree-alist)
    ((dzn parse) parse:tree-alist->ast)
    ((dzn parse) parse:file->tree-alist+content-alist)
    ((dzn ast normalize) normalize:event+illegals)
    ((dzn ast normalize) normalize:state+illegals)
    ((dzn code) code:normalize)
    ((dzn code language c++) ast->)
    ((dzn code language makreel) makreel:normalize)
    ((dzn code scmackerel makreel) root->scmackerel)
    ((dzn code scmackerel makreel) scmackerel:display)
    ((dzn ast wfc) wfc (,<root>))))

;; Procedures to instrument with measure-duration.
(define %measure
  `(((dzn parse) parse:file->string)
    ((dzn parse) parse:string->tree)
    ((dzn parse) parse:tree->ast)
    ((dzn ast accessor) ast:parent (,<ast> ,<class>))
    ((dzn ast lookup) ast:lookup (,<ast> ,<top>))
    ((dzn ast lookup) ast:lookup-variable (,<ast> ,<top>))))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (help (single-char #\h))
            (repl (single-char #\R))
            (skip-wfc (single-char #\p))
            (timings (single-char #\T))
            (threads (value #t))
            (transform (single-char #\t) (value #t))
            (verbose (single-char #\v))
            (version (single-char #\V))
            (version-number)))
         (options (getopt-long args option-spec
                               #:stop-at-first-non-option #t))
         (verbose? (option-ref options 'verbose #f))
         (help? (option-ref options 'help #f))
         (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files)))
         (version? (option-ref options 'version #f))
         (version-number? (option-ref options 'version-number #f)))

    (define (list-commands dir)
      (let* ((uninstalled? (getenv "DZN_UNINSTALLED"))
             (ext path (if uninstalled? (values ".scm" %load-path)
                           (values ".go" %load-compiled-path))))
        (map (cut basename <> ext)
             (filter
              (cute string-contains <> dir)
              (append-map
               (cute list-directory <>
                     (cute string-suffix? ext <>))
               (filter directory-exists?
                       (map (cute string-append <> "/dzn/commands/")
                            path)))))))

    (when version?
      (show-version-and-exit))
    (when version-number?
      (show-version-number-and-exit))
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
Run COMMAND with ARGUMENTs.

  -d, --debug            enable debug ouput
  -h, --help             display this help
  -p, --skip-wfc         use plain PEG, skip well-formedness checking
  -v, --verbose          be more verbose, show progress
  -V, --version          display version
  -t, --transform=TRANS  use transformation TRANS
  -T, --timings          show timings
      --threads=N        invoke LTS2LPS with --threads=N

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

(define (run-command options)
  (let* ((command (script:command #:options options))
         (module (script:command-module #:options options))
         (main (and module (false-if-exception (module-ref module 'main))))
         (command-args (command:command-line options)))
    (unless main
      (format (current-error-port) "dzn: no such command: ~a\n" command)
      (exit EXIT_OTHER_FAILURE))
    (main command-args)))

(define (main args)
  (let* ((options (parse-opts args))
         (repl? (option-ref options 'repl #f))
         (timings? (option-ref options 'timings #f)))
    (when timings?
      (instrument-timings %time %measure))
    (if repl? (call-with-error-handling (cute run-command options))
        (run-command options))))
