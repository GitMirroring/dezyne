;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag commands traces)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (gaiag csp)
  #:use-module (gaiag asserts)
  #:use-module (gaiag misc)  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))

  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag util)
  #:use-module (gaiag ast)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag resolve)
  #:use-module (gaiag command-line)
  #:use-module (gaiag parse)

  #:use-module (gaiag shell-util)
  #:use-module (gash pipe)

  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (flush (single-char #\f))
            (gaiag (single-char #\G))
            (help (single-char #\h))
            (illegal (single-char #\i))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (queue_size (single-char #\q) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
                               #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn traces [OPTION]... DZN-FILE
  -f, --flush                 include <flush> event in trace
  -h, --help                  display this help and exit
  -i, --illegal               include traces that lead to an illegal
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -q, --queue_size=SIZE       use queue size=SIZE for generation
FIXME:  -V, --version=VERSION       use service version=VERSION
")
          (exit (or (and usage? 2) 0)))
     options)))

(define* (parse-with-options options file-name #:key mangle?)
  (let* ((gaiag? (option-ref options 'gaiag #f))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (model (option-ref options 'model #f)))
    (parse-file file-name #:generator? (not gaiag?) #:imports imports #:mangle? mangle? #:model model)))

(define ((om:mangle-named name) ast)
  (match name
    ((? symbol?) (eq? name ((compose demangle .name) ast)))
    (($ <scope.name>)
     ((om:mangle-named ((om:scope-name '.) name)) ast))))

(define* (delete-file-recursively dir)
  "Delete DIR recursively, like `rm -rf', without following symlinks.  Report but ignore
errors."
  (let ((dev (stat:dev (lstat dir))))
    (file-system-fold (lambda (dir stat result) ; enter?
                        (= dev (stat:dev stat)))
                      (lambda (file stat result) ; leaf
                        (delete-file file))
                      (const #t)                ; down
                      (lambda (dir stat result) ; up
                        (rmdir dir))
                      (const #t)        ; skip
                      (lambda (file stat errno result)
                        (format (current-error-port)
                                "warning: failed to delete ~a: ~a~%"
                                file (strerror errno)))
                      #t
                      dir

                      ;; Don't follow symlinks.
                      lstat)))

(define (model->traces options root model)
  (let ((csp (with-output-to-string (lambda () (om->csp root #:file-name "-" #:separate-asserts? #t))))
        (gdzn-debug? (find (cut equal? <> "--debug") (command-line))))
    (if gdzn-debug? (stderr "CSP:\n ~s\n" csp))
    ;; FIXME: string processing, should generate CSP for process from model+template
    (let* ((asserts (ast:set-scope root (assert-list root)))
           (csp-asserts (with-output-to-string (lambda () (ast:set-scope root (csp-asserts model)))))
           (csp-asserts (string-trim-right csp-asserts))
           (main-assert (last (string-split csp-asserts #\newline)))
           (process (cadr (string-split main-assert #\space)))
           (provided-ports (filter ast:provides? (om:ports model)))
           (foo (if gdzn-debug? (stderr "provides: ~a\n" provided-ports)))
           (provided (map (compose symbol->string .name) provided-ports))
           (tmp (tmpnam))
           (foo (mkdir tmp))
           (model-name (symbol->string (demangle ((om:scope-name '.) model))))
           (tmp.csp (string-append tmp "/" model-name ".csp"))
           (foo (with-output-to-file tmp.csp (lambda () (display csp))))
           (script (format #f "session mysession
mysession load ~a ~a
mysession compile [mysession evaluate ~s] myism
puts [myism root]
puts [myism transitions]
puts [myism numeric_alphabet]
puts [myism alphabet]
" (dirname tmp.csp) (basename tmp.csp) process))
           (bin ((compose dirname car) (command-line)))
           (traces.py (string-append %service-dir "/scripts/traces.py"))
           (foo (if gdzn-debug? (stderr "traces.py=~s\n" traces.py)))
           (flush-opt (option-ref options 'flush #f))
           (illegal-opt (option-ref options 'illegal #f))
           (dir (option-ref options 'output "."))
           (foo (mkdir-p dir))
           (json? (gdzn:command-line:get 'json #f))
           (traces (pipeline->string `("echo" ,script)
                                     '("fdr2tix" "-insecure" "-nowindow")
                                     `("python" ,traces.py
                                       ,@(if json? '() `("--out" ,dir))
                                       ,@(if (not illegal-opt) '() '("--illegal"))
                                       ,@(if (is-a? model <interface>) '("--interface") '())
                                       ,@(if (not flush-opt) '() '("--flush"))
                                       "--model" ,model-name
                                       ,@(append-map (lambda (p) (list "--provided" p)) provided)
                                       "-")))

           (traces (string-trim-right traces)))
      (when json? (display traces))
      (when gdzn-debug?
        (stderr "asserts=~s\n" asserts)
        (stderr "main-assert=~s\n" main-assert)
        (stderr "process=~s\n" process)
        (stderr "provided=~s\n" provided)
        (stderr "csp=~s\n" csp)
        (stderr "traces=~s\n" traces))
      (if (not gdzn-debug?)
          (delete-file-recursively tmp)))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (ast (parse-with-options options file-name #:mangle? #t))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (foo (if gdzn-debug? (stderr "AST:\n ~s\n" ast)))
         (root (csp:parse->om ast))
         (model-name (option-ref options 'model #f))
         (models (filter (is? <model>) (.elements root)))
         (model (if model-name (find (om:mangle-named (string->symbol model-name)) models)
                    (find .behaviour (append (om:filter (is? <component>) root)
                                             (om:filter (is? <interface>) root))))))
    (if (not model) (if model-name (error "no such model:" model-name)
                        (let ((names (map (compose demangle .name) models)))
                          (error "no model with behaviour:" names)))
        (when (not (is-a? model <system>))
          (model->traces options root model)))))
