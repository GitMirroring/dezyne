;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag commands convert)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (sxml simple)
  #:use-module (gaiag misc)
  #:use-module (gash glob)
  #:export (assert-generator-parse
            generator-parse
            parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
            (globals (single-char #\g))
            (import (single-char #\I) (value #t))
            (map (single-char #\m))
            (output (single-char #\o) (value #t))
            (system (single-char #\s))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: gdzn parse [OPTION]... [FILE]...
  -g, --globals          create or extend GlobalTypes.dzn with externals
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
  -m, --map              generate map file for stub generation
  -o, --output=DIR       write output to DIR
  -s, --system           include system description
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))


(define (asd-interfaces o)
  (match o
    (('ImplementedService dependency) (asd-interfaces dependency))
    (('UsedServices dependency ...) (apply append (filter pair? (map asd-interfaces dependency))))
    (('RelativePath path) (list path))
    ((_ ...) (apply append (filter pair? (map asd-interfaces o))))
    (_ #f)))

(define (generator-parse options file-name)
  (let* ((import-opt (lambda (o) (and (eq? (car o) 'import) (cdr o))))
         (imports (filter-map import-opt options))
         (gdzn-debug? (find (cut equal? <> "--debug") (command-line)))
         (globals? (option-ref options 'globals #f))
         (map? (option-ref options 'map #f))
         (output-dir (option-ref options 'output #f))
         (output (if output-dir (string-append  " -o " output-dir) ""))
         (system? (option-ref options 'system #f))
         (model (with-input-from-file file-name (lambda () (xml->sxml (current-input-port)))))
         (interfaces (map (cut string-append (dirname file-name) "/" <>) (asd-interfaces model)))
         (files (append interfaces (list file-name)))
         (commands (map (cut string-append
                          "PATH=" (dirname (car (command-line))) ":bin:../bin:$PATH" ;; FIXME
                          " asd -a no-system -l gen2 -I " (dirname file-name) " "
                          (string-join imports " -I " 'prefix)
                          output " "
                          <>) files)))
    (stderr "command: ~a\n" commands)
    (display (map gulp-pipe commands))
    (let* ((pattern (string-append output-dir "/*.dzn"))
           (stub? (lambda (file-name)
                    (string-contains (with-input-from-file file-name read-string) "This is a stub")))
           (dzn-files (glob pattern)))
      (for-each delete-file (filter stub? dzn-files)))))

(define (assert-generator-parse options file-name)
  (catch #t
    (lambda _
      (generator-parse options file-name))
    (lambda _
      (exit 1))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (files (map (lambda (f) (if (not (string-prefix? "/" f)) f (string-drop f 1))) files)))
    (assert-generator-parse options (car files))))
