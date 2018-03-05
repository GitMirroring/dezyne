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
  #:use-module (gaiag csp)
  #:use-module (gaiag asserts)
  #:use-module (gaiag misc)  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag mcrl2)
  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag util)
  #:use-module (gaiag ast)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag resolve)
  #:use-module (gaiag command-line)
  #:use-module (gaiag parse)

  #:use-module (gaiag shell-util)
  #:use-module (gash job)
  #:use-module (gash pipe)

  #:use-module (scmcrl2 verification)

  #:export (parse-opts
            main))

(define x:interface-lts-init (@@ (gaiag mcrl2) x:interface-lts-init))
(define x:component-init (@@ (gaiag mcrl2) x:component-init))

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

(define* (parse-with-options options file-name #:key mangle?)
  (let* ((gaiag? (option-ref options 'gaiag #f))
         (import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (model (option-ref options 'model #f)))
    (parse-file file-name #:gaiag? gaiag? #:imports imports #:mangle? mangle? #:model model)))

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

;; (define pipeline->string- pipeline->string)
;; (define (pipeline->string . commands)
;;   (stderr "commands:~s\n" commands)
;;   (apply pipeline->string- commands))

;; (define pipeline- pipeline)
;; (define (pipeline fg? . commands)
;;   (stderr "commands:~s\n" commands)
;;   (apply pipeline- (cons fg? commands)))

;; (define pipeline+- pipeline+)
;; (define (pipeline+ fg? open? . commands)
;;   (stderr "commands:~s\n" commands)
;;   (apply pipeline+- (cons* fg? open? commands)))

(define (create-lts model-name root)
  (let* ((component (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <component>) (.elements root))))
         (interface (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <interface>) (.elements root))))
         (root (if component root interface))
         (init (if component x:component-init x:interface-lts-init))
         (commands `(,(cut init root)
                     ("cat" "-" "verify.mcrl2")
                     ("tee" "0")
                     ("mcrl22lps" "--quiet" "-b")
                     ("tee" "1")
                     ("lpsconstelm" "--quiet" "-st")
                     ("tee" "2")
                     ("lpsparelm")
                     ("tee" "3")
                     ;; outfile /dev/stdout does not work
                     ;;("lps2lts" "-v" "--cached" "--out=aut" "/dev/stdin" "/dev/stdout")
                     ("lps2lts" "--quiet" "--cached" "--out=aut" "/dev/stdin" "lts")
                     ("tee" "4")
                     ;;("ltsconvert" "-eweak-trace" "--in=aut" "--out=aut" "/dev/stdin" "/dev/stdout")
                     ))
         (result (apply pipeline->string commands))
         (commands `(("cat" "lts")
                     ("ltsconvert" "-eweak-trace" "--in=aut" "--out=aut"))))
    (receive (job ports)
        (apply pipeline+ #f 2 commands)
      (set-port-encoding! (car ports) "ISO-8859-1")
      (let ((lts (read-string (car ports)))
            (error (read-string (cadr ports)))
            (status (wait job)))
        lts))))

(define (lts-mcrl2 options file-name)
  (let* ((modelname (option-ref options 'model #f))
     (ast (parse-with-options options file-name))
         (module (resolve-module `(gaiag mcrl2)))
         (root-> (module-ref module 'root->))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (gdzn-verbose? (or (find (cut equal? <> "--verbose") (command-line))
                            (find (cut equal? <> "-v") (command-line))))
         (root ((compose ast:resolve tick-names parse->om) ast))
         (root (mcrl2:om root))
         (cwd (getcwd))
         (tmp (string-append (tmpnam) "-traces"))
         (foo (mkdir tmp)))
    (chdir tmp)
    (with-output-to-file "verify.mcrl2" (cut root-> root))
    (let ((lts (create-lts modelname root)))
      (chdir cwd)
      lts)))

(define (model->traces options root model file-name)
  (let ((lts (lts-mcrl2 options file-name))
        (gdzn-debug? (find (cut equal? <> "--debug") (command-line))))
    ;;    (if gdzn-debug? (stderr "LTS:\n ~s\n" (gulp-file lts)))
    (let* ((provided-ports (filter ast:provides? (om:ports model)))
           (foo (if gdzn-debug? (stderr "provides: ~a\n" provided-ports)))
           (provided (map (compose symbol->string .name) provided-ports))
           (tmp (tmpnam))
           (foo (mkdir tmp))
           (model-name (symbol->string (demangle ((om:scope-name '.) model))))
           ;;(tmp.lts (string-append tmp "/" model-name ".lts"))
           ;;(foo (with-output-to-file tmp.lts lts))
           (bin ((compose dirname car) (command-line)))
           (traces.py (string-append %service-dir "/scripts/traces.py"))
           (foo (if gdzn-debug? (stderr "traces.py=~s\n" traces.py)))
           (flush-opt (option-ref options 'flush #f))
           (illegal-opt (option-ref options 'illegal #f))
           (lts-opt (option-ref options 'lts #f))
           (dir (option-ref options 'output "."))
           (foo (mkdir-p dir))
           (json? (gdzn:command-line:get 'json #f))
           (traces (pipeline->string (cut display lts)
                                     `("python" ,traces.py
                                       ,@(if json? '() `("--out" ,dir))
                                       ,@(if (not illegal-opt) '() '("--illegal"))
                                       ,@(if (is-a? model <interface>) '("--interface") '())
                                       ,@(if (not flush-opt) '() '("--flush"))
                                       ,@(if (not lts-opt) '() '("--lts"))
                                       "--model" ,model-name
                                       ,@(append-map (lambda (p) (list "--provided" p)) provided)
                                       "-")))

           (traces (string-trim-right traces)))
      (when json? (display traces))
      (when gdzn-debug?
        (stderr "provided=~s\n" provided)
        (stderr "traces=~s\n" traces))
      (if (not gdzn-debug?)
          (delete-file-recursively tmp)))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (ast (parse-with-options options file-name #:mangle? #f))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
 ;;        (foo (if gdzn-debug? (stderr "AST:\n ~s\n" ast)))
         (root (csp:parse->om ast))
         (model-name (option-ref options 'model #f))
         (models (filter (is? <model>) (.elements root)))
         (model (if model-name (find (lambda (o) (equal? ((compose symbol->string verify:scope-name) o) model-name)) models)
                    (find .behaviour (append (om:filter (is? <component>) root)
                                             (om:filter (is? <interface>) root))))))
    (if (not model) (if model-name (error "no such model:" model-name)
                        (let ((names (map (compose demangle .name) models)))
                          (error "no model with behaviour:" names)))
        (when (not (is-a? model <system>))
          (model->traces options root model file-name)))))
