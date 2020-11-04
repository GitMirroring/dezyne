;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2020 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (dzn commands traces)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) 'goops:<port> x)))

  #:use-module (dzn misc)
  #:use-module (dzn config)
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn commands parse)
  #:use-module (dzn commands verify)
  #:use-module (dzn command-line)
  #:use-module (dzn lts)
  #:use-module (dzn code makreel)

  #:use-module (dzn shell-util)
  #:use-module (gash job)
  #:use-module (gash pipe)

  #:use-module (dzn verify pipeline)
  #:use-module (dzn verify traces)

  #:export (parse-opts
            main))

(define x:interface-init (@@ (dzn verify pipeline) x:interface-init))
(define x:component-init (@@ (dzn verify pipeline) x:component-init))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (flush (single-char #\f))
            (dzn (single-char #\G))
            (help (single-char #\h))
            (illegal (single-char #\i))
            (import (single-char #\I) (value #t))
            (lts (single-char #\l))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (queue-size (single-char #\q) (value #t))))
	 (options (getopt-long args option-spec
                               #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: dzn traces [OPTION]... DZN-FILE
Generate exhaustive set of traces for Dezyne model

  -f, --flush                 include <flush> events in trace
  -h, --help                  display this help and exit
  -i, --illegal               include traces that lead to an illegal
  -I, --import=DIR+           add DIR to import path
  -l, --lts                   generate LTS
  -m, --model=MODEL           generate traces for model MODEL
  -o, --output=DIR            write traces in directory DIR
  -q, --queue-size=SIZE       use queue size=SIZE for generation
")
          (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS)))
     options)))

(define (mcrl2->lts ast model init)
  (let* ((commands `(,(cut model->mcrl2 ast model)
                     ("bash" "-c" ,(format #f "cat - ; echo \"~a\"" init))
                     ("m4-cw")
                     ("mcrl22lps" "--quiet" "-b")
                     ("lpsconstelm" "--quiet" "-st")
                     ("lpsparelm")
                     ("lps2lts" "--quiet" "--cached" "--out=aut""--save-at-end" "-" "-")))
         (result (pipeline->string commands))
         (commands `(,(cut display result)
                     ("ltsconvert" "-eweak-trace" "--in=aut" "--out=aut")))
         (result (pipeline->string commands)))
    (string-trim-right result)))

(define (model->lts root model)
  (let* ((cwd (getcwd))
         (tmp (string-append (tmpnam) "-traces"))
         (foo (mkdir tmp)))
    (chdir tmp)
    (let* ((init (if (is-a? model <component>) (x:component-init model) (x:interface-init model)))
           (lts (mcrl2->lts root model init))
           (lts (cleanup-lts lts #:illegal? #t)))
      (chdir cwd)
      lts)))

(define (model->traces options root model)
  (let* ((gdzn-debug? (gdzn:command-line:get 'debug))
         (lts (model->lts root model))
         (provided-ports (if (is-a? model <interface>) '()
                             (ast:provides-port* model)))
         (provides-in (if (is-a? model <component>)
                          (map (lambda (t) (string-append (string-drop-right (.port.name t) 1) "." (.event.name t)))
                               (ast:provided-in-triggers model))
                          (map .name (filter ast:in? (ast:event* model)))))
         (foo (if gdzn-debug? (stderr "provides: ~a\n" provided-ports)))
         (provided (map .name provided-ports))
         (tmp (tmpnam))
         (foo (mkdir tmp))
         (model-name (verify:scope-name model))
         (bin ((compose dirname car) (command-line)))
         (flush-opt (option-ref options 'flush #f))
         (illegal-opt (option-ref options 'illegal #f))
         (lts-opt (option-ref options 'lts #f))
         (dir (option-ref options 'output "."))
         (foo (mkdir-p dir))
         (json? (gdzn:command-line:get 'json #f))
         (commands `(,(cut display lts)
                     ,@(if gdzn-debug? '(("tee" "lts.aut")) '())
                     ("lts2traces"
                      ,@(if json? '() `("--out" ,dir))
                      ,@(if (not illegal-opt) '() '("--illegal"))
                      ,@(if (not flush-opt) '() '("--flush"))
                      ,@(if (is-a? model <interface>) '("--interface") '())
                      ,@(if (not lts-opt) '() '("--lts"))
                      "--model" ,model-name
                      ,@(append-map (lambda (p) (list "--provides-in" p)) provides-in)
                      "-")))
         (foo (if gdzn-debug? (stderr "commands: ~s\n" commands)))
         (traces (with-output-to-string
                   (lambda _
                     (let* ((text (string-trim-right lts))
                            (lines (string-split text #\newline)))
                       (lts->traces lines
                                    illegal-opt
                                    flush-opt
                                    (is-a? model <interface>)
                                    dir
                                    lts-opt
                                    model-name
                                    '()
                                    provides-in)))))
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
         (ast (parse options file-name))
         (root (makreel:om ast))
         (model-name (option-ref options 'model #f)))
    (define (named? o)
      (equal? (verify:scope-name o) model-name))
    (let* ((models (ast:model* root))
           (components-interfaces (append (filter (conjoin (is? <component>) .behaviour) models)
                                          (filter (is? <interface>) models)))
           (model (or (and model-name (find named? models))
                      (and (pair? components-interfaces) (car components-interfaces)))))
      (cond ((and model-name (not model)) (error "no such model:" model-name))
            ((is-a? model <system>) #t) ;; silently no traces
            ((and model-name (or (is-a? model <foreign>) (not (.behaviour model)))) (error "no model with behaviour:" model-name))
            (model (model->traces options root model))))))
