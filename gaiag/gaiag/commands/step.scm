;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag commands step)
  #:use-module (ice-9 getopt-long)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag commands parse)
  #:use-module (gaiag commands trace)
  #:use-module (gaiag step)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((dup)
            (format (single-char #\f) (value #t))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (lts (single-char #\l) (value #t))
            (locations (single-char #\L))
            (model (single-char #\m) (value #t))
            (self)
            (trail (single-char #\t) (value #t))
            (vars (single-char #\v) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or (and (or (null? files) help?)
             (format #t "\
Usage: gdzn step [OPTION]... [FILE]...
      --dup              remove duplicate transitions
  -f, --format=FORMAT    display trace in format FORMAT [code]
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -l, --lts=FORMAT       print lts in FORMAT = {go,dot}
  -L, --locations        prepend locations to output trail
  -m, --model=MODEL      generate main for MODEL
      --self             remove self transitions
  -t, --trail=TRAIL      use trail=TRAIL [read from stdin]
      --vars=VARS        remove VARS
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (options (acons 'behaviour #t options))
         (files (option-ref options '() '()))
         (file-name (car files))
         (ast (parse-with-options options file-name))
         (format (option-ref options 'format #f)))
    (if format (let ((trace (with-output-to-string (cut step:ast-> ast))))
                 (display (format-trace trace  #:format format)))
        (step:ast-> ast))
    ""))
