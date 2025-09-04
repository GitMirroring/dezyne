#! /bin/sh
# -*-scheme-*-
exec guile -L ${0%/*} -e '(indent)' -s "$0" "$@"
!#
;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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
;;; Properly indenting Scheme code without using Emacs proves to be
;;; very hard.  If you're not an Emacs user yet, use this script to
;;; properly indent your code.
;;;
;;; Code:

(define-module (indent)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:export (main))

(define EXIT_OTHER_FAILURE 2)

(define (emacs-indent-scm file)
  (system*
   "emacs"
   "--batch"
   "--no-init-file"
   "--eval"
   (format #f "
(progn
  (defun vc-mode-line-state (&rest ignored) nil)
  (setq error nil)
  (setq version-control nil)
  (setq vc-use-short-revision nil)
  (setq scheme-mode-hook nil)
  (setq enable-local-eval :all)
  (setq enable-local-variables :all)
  (load-library \"scheme\")
  (find-file ~s)
  (scheme-mode)

  ;; Guix' dir-locals
  (put 'lambda* 'scheme-indent-function 1)
  (put 'test-assert 'scheme-indent-function 1)
  (put 'test-assertm 'scheme-indent-function 1)
  (put 'test-equalm 'scheme-indent-function 1)
  (put 'test-equal 'scheme-indent-function 1)
  (put 'test-eq 'scheme-indent-function 1)
  (put 'call-with-input-string 'scheme-indent-function 1)
  (put 'call-with-port 'scheme-indent-function 1)

  ;; geiser-syntax--scheme-indent -- geiser-syntax.el
  (put 'and-let* 'scheme-indent-function 1)
  (put 'case-lambda 'scheme-indent-function 0)
  (put 'catch 'scheme-indent-function 'defun)
  (put 'class 'scheme-indent-function 'defun)
  (put 'dynamic-wind 'scheme-indent-function 0)
  (put 'guard 'scheme-indent-function 1)
  (put 'let*-values 'scheme-indent-function 1)
  (put 'let-values 'scheme-indent-function 1)
  (put 'let/ec 'scheme-indent-function 1)
  (put 'letrec* 'scheme-indent-function 1)
  (put 'match 'scheme-indent-function 1)
  (put 'match-lambda 'scheme-indent-function 0)
  (put 'match-lambda* 'scheme-indent-function 0)
  (put 'match-let 'scheme-indent-function 'scheme-let-indent)
  (put 'match-let* 'scheme-indent-function 1)
  (put 'match-letrec 'scheme-indent-function 1)
  (put 'opt-lambda 'scheme-indent-function 1)
  (put 'parameterize 'scheme-indent-function 1)
  (put 'parameterize* 'scheme-indent-function 1)
  (put 'receive 'scheme-indent-function 2)
  (put 'require-extension 'scheme-indent-function 0)
  (put 'syntax-case 'scheme-indent-function 2)
  (put 'test-approximate 'scheme-indent-function 1)
  (put 'test-assert 'scheme-indent-function 1)
  (put 'test-eq 'scheme-indent-function 1)
  (put 'test-equal 'scheme-indent-function 1)
  (put 'test-eqv 'scheme-indent-function 1)
  (put 'test-group 'scheme-indent-function 1)
  (put 'test-group-with-cleanup 'scheme-indent-function 1)
  (put 'test-runner-on-bad-count! 'scheme-indent-function 1)
  (put 'test-runner-on-bad-end-name! 'scheme-indent-function 1)
  (put 'test-runner-on-final! 'scheme-indent-function 1)
  (put 'test-runner-on-group-begin! 'scheme-indent-function 1)
  (put 'test-runner-on-group-end! 'scheme-indent-function 1)
  (put 'test-runner-on-test-begin! 'scheme-indent-function 1)
  (put 'test-runner-on-test-end! 'scheme-indent-function 1)
  (put 'test-with-runner 'scheme-indent-function 1)
  (put 'unless 'scheme-indent-function 1)
  (put 'when 'scheme-indent-function 1)
  (put 'while 'scheme-indent-function 1)
  (put 'with-exception-handler 'scheme-indent-function 1)
  (put 'with-syntax 'scheme-indent-function 1)

  ;; geiser-syntax--scheme-indent -- geiser-guile.el
  (put 'c-declare 'scheme-indent-function 0)
  (put 'c-lambda 'scheme-indent-function 2)
  (put 'call-with-input-string 'scheme-indent-function 1)
  (put 'call-with-output-string 'scheme-indent-function 0)
  (put 'call-with-prompt 'scheme-indent-function 1)
  (put 'call-with-trace 'scheme-indent-function 0)
  (put 'eval-when 'scheme-indent-function 1)
  (put 'lambda* 'scheme-indent-function 1)
  (put 'pmatch 'scheme-indent-function 'defun)
  (put 'sigaction 'scheme-indent-function 1)
  (put 'syntax-parameterize 'scheme-indent-function 1)
  (put 'with-error-to-file 'scheme-indent-function 1)
  (put 'with-error-to-port 'scheme-indent-function 1)
  (put 'with-error-to-string 'scheme-indent-function 0)
  (put 'with-fluid* 'scheme-indent-function 1)
  (put 'with-fluids 'scheme-indent-function 1)
  (put 'with-fluids* 'scheme-indent-function 1)
  (put 'with-input-from-string 'scheme-indent-function 1)
  (put 'with-method 'scheme-indent-function 1)
  (put 'with-mutex 'scheme-indent-function 1)
  (put 'with-output-to-string 'scheme-indent-function 0)
  (put 'with-throw-handler 'scheme-indent-function 1)

  (indent-region (point-min) (point-max))
  (delete-trailing-whitespace)
  (when (buffer-modified-p (current-buffer))
    (save-buffer))))"
           file)))

(define (emacs-indent-c++ file)
  (system*
   "emacs"
   "--batch"
   "--no-init-file"
   "--eval"
   (format #f "
(progn
  (defun vc-mode-line-state (&rest ignored) nil)
  (setq error nil)
  (setq version-control nil)
  (setq vc-use-short-revision nil)
  (setq enable-local-eval :all)
  (setq enable-local-variables :all)
  (load-library \"cc-mode\")
  (dir-locals-read-from-dir \".\")
  (find-file ~s)
  (c++-mode)
  (indent-region (point-min) (point-max))
  (delete-trailing-whitespace)
  (when (buffer-modified-p (current-buffer))
    (save-buffer)))"
           file)))

(define (indent-c file)
  ;; Although we try to keep code < 80 columns when reviewing patches,
  ;; have indent be lenient wrt line length.
  (system* "indent"
           "--no-tabs"
           "--line-length" "110"
           "--honour-newlines"
           "--break-before-boolean-operator"
           file))

(define (indent-c++ file)
  ;; Not using indent, which is more GNU correct but still has trouble
  ;; handling C++
  (system* "astyle"
           "--options=none"
           "--quiet"
           "-n"
           "--style=gnu"
           "--indent=spaces=2"
           "--break-return-type"
           "--align-pointer=name"
           "--max-instatement-indent=60"
           "--indent-cases"
           "--pad-oper"
           "--keep-one-line-blocks"
           "--pad-first-paren-out"
           file)
  (system* "sed" "-i"
           ;; FIXUP for astyle --pad-first-paren-out missing foo() => foo ()
           "-e" "s, *(), (),g"
           ;; FIXUP for astyle --align-reference=type
           "-e" "s,\\([!)]\\) *&&,\\1 \\&\\&,g"
           file)
  (emacs-indent-c++ file))

(define (indent-file file)
  (cond
   ((string-suffix? ".scm" file)
    (false-if-exception (emacs-indent-scm file)))
   ((or (string-suffix? ".hh" file)
        (string-suffix? ".cc" file))
    (false-if-exception (indent-c++ file)))
   ((or (string-suffix? ".h" file)
        (string-suffix? ".c" file))
    (false-if-exception (indent-c++ file)))))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
            (version (single-char #\V))))
         (options (getopt-long args option-spec
                               #:stop-at-first-non-option #t))
         (verbose? (option-ref options 'verbose #f))
         (help? (option-ref options 'help #f))
         (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files)))
         (version? (option-ref options 'version #f)))
    (when version?
      (format #t "indent.scm 0.0\n")
      (exit EXIT_SUCCESS))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: indent [OPTION]... FILE...
  -h, --help             display this help
  -V, --version          display version
"))
      (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS)))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '())))
    (for-each indent-file files)))
