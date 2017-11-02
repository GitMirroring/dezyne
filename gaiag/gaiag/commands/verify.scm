;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
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

(define-module (gaiag commands verify)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag util)
  #:use-module (gaiag config)
  #:use-module (gaiag json2scm)
  #:use-module (gaiag misc)
  #:use-module (gaiag commands parse)
  #:use-module (gaiag resolve)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((all (single-char #\a))
            (debug (single-char #\d))
            (gaiag (single-char #\G))
            (help (single-char #\h))
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
Usage: gdzn verify [OPTION]... DZN-FILE [MAP-FILE]...
  -a, --all                   run all checks
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -q, --queue_size=SIZE       use queue size=SIZE for verification [3]
FIXME:  -V, --version=VERSION       use service version=VERSION
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define ((result->string file-name) result)
  (let* ((check (assoc-ref result 'assert))
         (model (assoc-ref result 'model))
         (trace (assoc-ref result 'trace))
         (trace (map symbol->string trace))
         (micro-trace (assoc-ref result 'sequence))
         (trace (apply string-join `(,trace "\n" prefix))))
    (if (pair? micro-trace)
        (let* ((micro-trace (reverse micro-trace))
               (error (car micro-trace))
               (message (assoc-ref error 'message))
               (message (symbol->string message))
               (location (find (lambda (e) (and=> (assoc-ref e 'selection)
                                                  (compose (cut assoc-ref <> 'file) car)))
                               (map cdr micro-trace)))
               (location (and=> (assoc-ref location 'selection) car))
               (file (assoc-ref location 'file))
               (line (assoc-ref location 'line))
               (column (assoc-ref location 'column))
               (index (assoc-ref location 'index)))
          (format (current-error-port) "~a:~a:~a:i~a: ~a\n" file-name line column index message)
          (format #t "verify: ~a: check: ~a: ~a~a\n" model check "fail" trace))
        (let ((gdzn-verbose? (or (find (cut equal? <> "--verbose") (command-line))
                                 (find (cut equal? <> "-v") (command-line)))))
          (if gdzn-verbose?
              (begin (format #t "verify: ~a: check: ~a: ~a~a\n" model check "ok" trace))
              "")))))

(define (models-for-verification options file-name)
  (let* ((ast (parse-with-options options file-name))
         (root ((compose-root ast:resolve parse->om) ast)))
    (ast:set-scope root
                   (let* ((models (ast:model* root))
                          (components (filter (conjoin (is? <component>) .behaviour) models))
                          (component-names (map (compose symbol->string (om:scope-name)) components))
                          (interfaces (filter (is? <interface>) models))
                          (interface-names (map (compose symbol->string (om:scope-name)) interfaces))
                          (interface-names (let loop ((components components) (interface-names interface-names))
                                             (if (null? components) interface-names
                                                 (let ((component-interfaces (map (compose symbol->string (om:scope-name) .type) (ast:port* (car components)))))
                                                   (loop (cdr components)
                                                         (filter (negate (cut member <> component-interfaces)) interface-names)))))))
                     (append interface-names component-names)))))

(define (verify-model options file-name model)
  (let* ((bin ((compose dirname car) (command-line)))
         (all? (option-ref options 'all #f))
         (q (option-ref options 'queue_size "3"))
         (verify.js (string-append %service-dir "/scripts/verify.js"))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (imports (cons* (dirname file-name) (dirname (canonicalize-path file-name)) imports))
         (command (string-append
                   verify.js
                   " --model=" model
                   " --queue=" q
                   (string-join imports " -I " 'prefix)
                   " " file-name
                   " | " bin "/json2scm"))
         (sexp (with-input-from-string (gulp-pipe command) read))
         (results (append-map (lambda (e) (or (assoc-ref e 'progress)
                                              (assoc-ref e 'result) '()
                                              '())) sexp))
         (error? (lambda (o) (pair? (assoc-ref o 'sequence))))
         (traces (filter error? results))
         (message? (lambda (o) (assoc-ref o 'assert)))
         (messages (filter message? results))
         (messages (if (or all? (null? results) (null? traces)) messages
                       (append (take-while (negate error?) messages)
                               (list (find error? messages))))))
    (for-each (result->string file-name) messages)
    traces))

(define (verify options file-name)
  (let* ((bin ((compose dirname car) (command-line)))
         (model (option-ref options 'model #f))
         (models (if model (list model) (models-for-verification options file-name)))
         (all? (option-ref options 'all #f)))
    (let loop ((models models) (traces '()))
      (if (and (or (null? models) (not all?)) (pair? traces)) (exit 1))
      (if (null? models) traces
          (loop (cdr models) (append traces (verify-model options file-name (car models))))))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files)))
    (assert-parse options file-name)
    (verify options file-name)))
