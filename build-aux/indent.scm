#! /bin/sh
# -*-scheme-*-
exec guile -L ${0%/*} -e '(indent)' -s "$0" "$@"
!#

;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define* (emacs-indent file)
  (system*
   "emacs"
   "--batch"
   "--no-init-file"
   "--eval"
   (format #f "
(let ((error nil)
      (version-control nil))
  (setq enable-local-eval :all)
  (setq enable-local-variables :all)
  (load-library \"scheme\")
  (find-file ~s)
  (scheme-mode)
  (indent-region (point-min) (point-max))
  (delete-trailing-whitespace)
  (when (buffer-modified-p (current-buffer))
    (save-buffer)))"
           file)))

(define (indent-file file)
  (false-if-exception (emacs-indent file)))

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
