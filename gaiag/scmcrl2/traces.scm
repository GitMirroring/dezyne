;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
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

(define-module (scmcrl2 traces)

  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (gaiag misc)

  #:export (make-trace))

(define (find-aliases mcrl2file)
  (let* ((mcrl2-text (call-with-input-file "verify.mcrl2" read-string))
	 (aliases (map
		   (lambda (m) (match:substring m 1))
		   (list-matches "\\b([a-zA-Z0-9_']*)\\s*=\\s*struct\\b" mcrl2-text))))
    aliases))

(define (rename-lts-actions srcfile destfile)
  (let* ((sorted-names (find-aliases "verify.mcrl2"))
	 (trace (call-with-input-file srcfile read-string))
	 ;; Remove reply variable wrappers
	 (trace (regexp-substitute/global #f "\\breply_[^(]*\\(([^)]*)\\)" trace 'pre 1 'post))
	 ;; Remove void return arguments
	 (trace (regexp-substitute/global #f "('return\\([^,]+),\\s*void\\)" trace 'pre 1 ")" 'post))
	 ;; Return statements with two arguments need special handling.
	 ;; Only the part of the second argument after the single quote needs to be kept.
	 (trace (regexp-substitute/global #f "'return\\(['\\w]+,\\s*\\w+'(\\w+)\\)" trace 'pre "." 1 'post))
	 ;; Remove sort names
	 (trace (let lp ((trc trace) (names sorted-names))
		  (if (equal? names '())
		      trc
		      (lp (regexp-substitute/global #f (string-append (car names) "'") trc 'pre "" 'post) (cdr names)))))
	 ;; Remove numeric prefixes
	 (trace (regexp-substitute/global #f "\\bi\\d+_" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "'event\\(" trace 'pre "." 'post))
 	 (trace (regexp-substitute/global #f "\\b\\w+'flush\\b" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "\\b\\(" trace 'pre "." 'post))
	 (trace (regexp-substitute/global #f "\\)" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "'return\\.\\w+" trace 'pre ".return" 'post))
	 (trace (regexp-substitute/global #f "\\b\\w+'inevitable\\b" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "\\b\\w+'optional\\b" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "\\billegal\\b" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "\\bdouble_reply_error\\b" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "\\bno_reply_error\\b" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\btau\n" trace 'pre "" 'post))
	 (trace (regexp-substitute/global #f "([\n])[\n]+" trace 'pre 1 'post)))
    ;;   (with-output-to-file destfile (lambda () (display trace)))
    (if (string=? trace "\n")
        ""
        trace)
    ))

(define (make-json-trace modelname tracefile dznfile outfile)
  (system (string-append "seqdiag -m " modelname " -t " tracefile " " dznfile " > " outfile))
  outfile)

(define (make-trace tracefile option modelname)
  (let ((outfile (string-append modelname option ".trc")))
    (system (string-append "tracepp " tracefile " > trace1.txt"))
    (rename-lts-actions "trace1.txt" outfile)
    ;;(make-json-trace modelname outfile file-name (string-append outfile ".json"))
    ))
