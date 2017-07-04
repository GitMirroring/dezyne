;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag commands run)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag misc)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (strict (single-char #\s))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: gdzn run [OPTION]... [FILE]...
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -m, --model=MODEL      generate main for MODEL
  -s, --strict           require the trace to be complete, i.e. including all events
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define (replay-trace options file-name)
  (let* ((import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (model-opt (option-ref options 'model #f))
         (strict? (option-ref options 'strict #f))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (command (string-append
                   "PATH=" (dirname (car (command-line))) ":bin:../bin:$PATH" ;; FIXME
                   " seqdiag "
                   (string-append " -m " model-opt)
                   ;;(string-join imports " -I " 'prefix)
                   " " file-name
		   "| trace2net.js --illegal")))
    (if gdzn-debug? (stderr "command: ~a\n" command))
    (let ((trace (gulp-pipe command)))
      (if strict?
          ;; FIXME: use format `trace:e,f,g' for aspects.js:run
          (format #t "trace:~a\n" (string-join (string-split trace #\newline) ","))
          (display trace)))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '())))
    (catch #t
      (lambda _
        (replay-trace options (car files)))
      (lambda _
        (exit 1)))))
