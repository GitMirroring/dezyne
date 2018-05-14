;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag util)

  #:use-module (gaiag asserts)
  #:use-module (gaiag misc)
  #:use-module (gaiag mcrl2)
  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag resolve)
  #:use-module (gaiag commands parse)
  #:use-module (gaiag commands verify)
  #:use-module (gaiag command-line)
  #:use-module (gaiag makreel)

  #:use-module (gaiag shell-util)
  #:use-module (gash job)
  #:use-module (gash pipe)

  #:use-module (scmcrl2 verification)
  #:use-module (scmcrl2 traces)

  #:export (parse-opts
            main))

(define x:interface-init (@@ (scmcrl2 verification) x:interface-init))
(define x:component-init (@@ (scmcrl2 verification) x:component-init))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (flush (single-char #\f))
            (gaiag (single-char #\G))
            (help (single-char #\h))
            (illegal (single-char #\i))
            (import (single-char #\I) (value #t))
            (lts (single-char #\l))
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
  -l, --lts                   generate lts
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -q, --queue_size=SIZE       use queue size=SIZE for generation
FIXME:  -V, --version=VERSION       use service version=VERSION
")
          (exit (or (and usage? 2) 0)))
     options)))

(define (mcrl2->lts init)
  (let* ((commands `(,init
                    ("cat" "-" "verify.mcrl2")
                    ("mcrl22lps" "--quiet" "-b")
                    ("lpsconstelm" "--quiet" "-st")
                    ("lpsparelm")
                    ("lps2lts" "--quiet" "--cached" "--out=aut" "/dev/stdin" "lts")))
        (result (apply pipeline->string commands))
        (commands `(("cat" "lts")
                    ("ltsconvert" "-eweak-trace" "--in=aut" "--out=aut"))))
    (receive (job ports)
        (apply pipeline+ #f 2 commands)
      (set-port-encoding! (car ports) "ISO-8859-1")
      (let ((lts (string-trim-right (read-string (car ports))))
            (error (read-string (cadr ports)))
            (status (wait job)))
        lts))))

(define (model->lts root model)
  (let* ((cwd (getcwd))
         (tmp (string-append (tmpnam) "-traces"))
         (foo (mkdir tmp)))
    (chdir tmp)
    (model->mcrl2 root model)
    (let* ((init (if (is-a? model <component>) x:component-init x:interface-init))
           (lts (mcrl2->lts (cut init model)))
           (lts (cleanup-lts lts #:illegal? #t)))
      (chdir cwd)
      lts)))

(define (model->traces options root model)
  (let* ((gdzn-debug? (gdzn:command-line:get 'debug))
         (lts (model->lts root model))
         (provided-ports (filter ast:provides? (om:ports model)))
         (provides-in (if (is-a? model <component>)
                          (map (lambda (t) (symbol-append (symbol-drop-right (.port.name t) 1) '. (.event.name t)))
                               (ast:provided-in-triggers model))
                          (map .name (filter ast:in? (ast:event* model)))))
         (provides-in (map symbol->string provides-in))
         (foo (if gdzn-debug? (stderr "provides: ~a\n" provided-ports)))
         (provided (map (compose symbol->string .name) provided-ports))
         (tmp (tmpnam))
         (foo (mkdir tmp))
         (model-name (symbol->string (verify:scope-name model)))
         (bin ((compose dirname car) (command-line)))
         (traces.py (string-append %service-dir "/scripts/traces.py"))
         (foo (if gdzn-debug? (stderr "traces.py=~s\n" traces.py)))
         (flush-opt (option-ref options 'flush #f))
         (illegal-opt (option-ref options 'illegal #f))
         (lts-opt (option-ref options 'lts #f))
         (dir (option-ref options 'output "."))
         (foo (mkdir-p dir))
         (json? (gdzn:command-line:get 'json #f))
         (commands `(,(cut display lts)
                     ,@(if gdzn-debug? '(("tee" "lts.aut")) '())
                     ("python" ,traces.py
                      ,@(if json? '() `("--out" ,dir))
                      ,@(if (not illegal-opt) '() '("--illegal"))
                      ,@(if (is-a? model <interface>) '("--interface") '())
                      ,@(if (not flush-opt) '() '("--flush"))
                      ,@(if (not lts-opt) '() '("--lts"))
                      "--model" ,model-name
                      ,@(append-map (lambda (p) (list "--provides-in" p)) provides-in)
                      "-")))
         (foo (if gdzn-debug? (stderr "commands: ~s\n" commands)))
         (traces (receive (job ports)
                    (apply pipeline+ #f commands)
                   (set-port-encoding! (car ports) "ISO-8859-1")
                  (let ((traces (read-string (car ports)))
                        (error (read-string (cadr ports))))
                    (handle-error job error)
                    (string-trim-right traces))))
         (traces (string-trim-right traces)))
    (when json? (display traces))
    (when gdzn-debug?
      (stderr "provides-in=~s\n" provides-in)
      (stderr "traces=~s\n" traces))
    (if (not gdzn-debug?)
        (delete-file-recursively tmp))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (ast (assert-parse options file-name))
         (root (makreel:om ast))
         (model-name (option-ref options 'model #f)))
    (define (named? o)
      (equal? (symbol->string (verify:scope-name o)) model-name))
    (let* ((models (ast:model* root))
           (components-interfaces (append (filter (conjoin (is? <component>) .behaviour) models)
                                          (filter (is? <interface>) models)))
           (model (or (and model-name (find named? models))
                      (and (pair? components-interfaces) (car components-interfaces)))))
      (cond ((and model-name (not model)) (error "no such model:" model-name))
            ((is-a? model <system>) #t) ;; silently no traces
            ((and model-name (not (.behaviour model))) (error "no model with behaviour:" model-name))
            (model (model->traces options root model))))))
