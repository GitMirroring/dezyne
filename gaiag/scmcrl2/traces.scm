;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
  #:use-module (srfi srfi-26)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)

  #:export (make-trace
            make-trace-file
            rename-lts-actions))

(define (find-aliases mcrl2file)
  (let* ((mcrl2-text (call-with-input-file "verify.mcrl2" read-string))
	 (aliases (map
		   (lambda (m) (match:substring m 1))
		   (list-matches "\\b([a-zA-Z0-9_']*)\\s*=\\s*struct\\b" mcrl2-text))))
    aliases))

(define (rename-lts-actions trace)
  (let* ((trace (regexp-substitute/global #f ",\\s*reply_[^(]*\\(([^)]*)\\)" trace 'pre "," 1 'post))
         (trace (regexp-substitute/global #f "('(return|reply_out|reply_in)[^,]+),\\s*void\\)" trace 'pre "" 1 'post))
         (trace (regexp-substitute/global #f "'(return|reply_out|reply_in)\\([^,]+,\\s*\\w+'([^)]+)\\)" trace 'pre "." 2 'post))
         (trace (regexp-substitute/global #f "\\w+'in'" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\w+'out'" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\bi\\d+_" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "'(event|in|out)\\(" trace 'pre "." 'post))
         (trace (regexp-substitute/global #f "\\b\\w+'flush\\b" trace 'pre "" 'post)) ;; extra
         (trace (regexp-substitute/global #f "\\b\\(" trace 'pre "." 'post))
         (trace (regexp-substitute/global #f "\\)" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "'(return|reply_out|reply_in)\\.(\\w|')+" trace 'pre ".return" 'post))
         (trace (regexp-substitute/global #f "\\b\\w+'inevitable\\b" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\b\\w+'optional\\b" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\bdillegal\n" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\billegal\\b" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\brange_error\n" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\bdouble_reply_error\\b" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\bno_reply_error\\b" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "\\btau\n" trace 'pre "" 'post))
         (trace (regexp-substitute/global #f "([\n])[\n]+" trace 'pre 1 'post))
         (trace (regexp-substitute/global #f "'" trace 'pre "_" 'post)))
    (if (string=? trace "\n")
        ""
        (string-trim trace))))

(define (make-json-trace modelname tracefile dir file-name outfile)
  (let* ((cwd (getcwd))
         (outfile (canonicalize-path outfile))
         (command (string-append "seqdiag -m " modelname " -t " tracefile " " file-name " > " outfile)))
    (chdir dir)
    (if (gdzn:command-line:get 'debug) (stderr "seqdiag command: ~s\n" command))
    (system command)
    (chdir cwd))
  (if (gdzn:command-line:get 'json) (display (gulp-file outfile))))

(define (make-trace tracefile option dir file-name modelname)
  (let ((outfile (string-append modelname option ".trc")))
    (system (string-append "tracepp " tracefile " > trace1.txt"))
    (let ((trace (rename-lts-actions "trace1.txt")))
      (with-output-to-file outfile (cut display trace))
      (make-json-trace modelname outfile dir file-name (string-append outfile ".json"))
      (if (gdzn:command-line:get 'json) "" trace))))

(define (make-trace-file tracefile option dir file-name modelname)
  (let ((outfile (format #f "~a~a.trc" modelname option))
        (trace-file "trace1.txt"))
    (system (string-append "tracepp " tracefile " > " trace-file))
    (rename-lts-actions (call-with-input-file trace-file read-string))))
