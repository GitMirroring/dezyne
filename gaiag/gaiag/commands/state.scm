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

(define-module (gaiag commands state)
  #:use-module (ice-9 getopt-long)

  #:use-module (gaiag commands parse)
  #:use-module (gaiag step)

  #:export (main))


(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (horizon (single-char #\H) (value #t))
            (import (single-char #\I) (value #t))
            (initial (single-char #\i) (value #t))
            (model (single-char #\m) (value #t))
            (remove-duplicate-transitions (single-char #\d))
            (remove-self-transitions (single-char #\s))
            (remove-vars (single-char #\v) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or (and (or (null? files) help?)
             (format #t "\
Usage: gdzn step [OPTION]... [FILE]...
  -f, --format=FORMAT                      display LTS in format FORMAT {go, dot, goops}
  -h, --help                               display this help and exit
  -H, --horizon=HORIZON                    set upper limit of LTS frontier to HORIZON
  -i, --initial=STATE                      set the initial state to STATE
  -I, --import=DIR+                        add DIR to import path
  -m, --model=MODEL                        generate main for MODEL
  -d, --remove-duplicate-transitions       remove duplicate transitions
  -s, --remove-self-transitions            remove self transitions
  -v, --remove-vars=VARS                   remove variables VARS from LTS
  -V, --version=VERSION                    use service version=VERSION
")
          (exit 0)))
    options))

(define (main args)
  (let* ((options (parse-opts args))
         (options (acons 'behaviour #t options))
         (files (option-ref options '() '()))
         (file-name (car files))
         (ast (parse-with-options options file-name))
         (format (option-ref options 'format "go")))
    (cond ((equal? format "dot") (lts-> dot ast))
          ((equal? format "go") (lts-> go ast))
          ((equal? format "goops") (lts-> (@@ (gaiag step) goopify) ast)))
    ""))
