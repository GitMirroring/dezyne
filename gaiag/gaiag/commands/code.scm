;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag commands code)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gaiag reader)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (depends) ;; FIXME
            (glue (single-char #\g) (value #t))
            (calling-context (single-char #\c) (value #t))
            (gaiag (single-char #\G))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (language (single-char #\l) (value #t))
            (mangle (single-char #\M))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (shell (single-char #\s) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn code [OPTION]... DZN-FILE [MAP-FILE]...
FIXME:      --depends[=TYPE]        generate dependency for DZN-FILE and write to DZN-FILE.TYPE, default is stdout
  -c, --calling-context=TYPE  generate extra parameter of TYPE for every event
  -g, --glue=TYPE             generate glue for TYPE [dzn]
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -l, --language=LANG         generate code for language=LANG [c++]
  -M, --mangle                enable generator mangling
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -s, --shell=MODEL           generate thread safe system shell for MODEL
FIXME:  -V, --version=VERSION       use service version=VERSION
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define (generator-read-ast options file-name)
  (let* ((import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (model-opt (option-ref options 'model #f))
         (mangle-opt (option-ref options 'mangle #f))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (debug? (option-ref options 'debug #f))
         (language (string->symbol (option-ref options 'language "c++")))
         (command (string-append
                   "PATH=" (dirname (car (command-line))) ":bin:../bin:$PATH" ;; FIXME
                   " generate -l scm -L -o -"
                   (if (not mangle-opt) "" " -M")
                   (string-join imports " -I " 'prefix)
                   ;; Only forward --model to generate for CSP, not
                   ;; for executable code: generator cuts models
                   (if (or (not (equal? language "csp")) (not model-opt)) ""
                       (string-append " -m " model-opt))
                   " " file-name)))
    (if gdzn-debug? (stderr "command: ~a\n" command))
    (with-input-from-string (gulp-pipe command) read)))

(define (file->ast options file-name)
  (let ((gaiag? (option-ref options 'gaiag #f)))
    (if gaiag? (read-ast file-name)
        (generator-read-ast options file-name))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (map-files (cdr args))
         (language (string->symbol (option-ref options 'language "c++")))
         (ast (file->ast options file-name))
         (module (resolve-module `(gaiag ,language)))
         (ast-> (module-ref module 'ast->))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line))))
    (if gdzn-debug? (stderr "AST:\n ~s\n" ast))
    (ast-> ast)
    *unspecified*))
