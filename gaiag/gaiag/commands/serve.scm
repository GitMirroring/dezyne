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

(define-module (gaiag commands serve)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)

  #:use-module (srfi srfi-26)

  #:use-module (web server)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module (web uri)

  #:use-module (gaiag config)
  #:use-module (gaiag command-line)
  #:use-module (gaiag commands parse)
  #:use-module (gaiag misc)

  #:use-module (gash pipe)

  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: gdzn serve [OPTION]...



  -h, --help             display this help and exit
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define (serve-js file)
  (values '((content-type . (text/javascript)))
          (with-input-from-file (string-append %datadir "/trace/" file) read-string)))

(define (query->alist query)
  (map (lambda (q) (let ((elements (string-split q #\=)))
                     (cons (car elements) (cadr elements))))
       (string-split query #\&)))

(define (serve-html request request-body)
  (let* ((uri (request-uri request))
         (file (string-join (split-and-decode-uri-path (uri-path uri)) "/"))
         (debug? (gdzn:command-line:get 'debug)))
    (when #t ;;debug?
      (stderr "serving: ~a\n" file))
    (match file
      ("go.js" (serve-js file))
      ("seqdiag.js" (serve-js file))
      ("gendiag.js" (serve-js file))
      ("state" (let* ((dir (string-append %datadir "/test/all/Camera"))
                      (ast (parse-with-options '() (string-append dir "/Camera.dzn")))
                      (lts (with-output-to-string
                             (cut (@@ (gaiag step) lts->) ast)))
                      (svg (pipeline->string  (cut display lts) (list "dot" "-Tsvg"))))
                 (values '((content-type . (text/html)))
                         (string-append "<html><body>" svg "</body></html>"))))
      ("step" (let* ((query (warn 'QUERY (query->alist (uri-query uri))))
                     (test (or (assoc-ref query "test") "Camera"))
                     (dir (string-append %datadir "/test/all/" test))
                     (ast (parse-with-options '() (string-append dir "/" test ".dzn")))
                     (trace-file (string-append dir "/trace"))
                     (trace ((compose read-string open-input-file) trace-file))
                     (pijltjes (with-output-to-string
                                 (cut with-input-from-string
                                   trace
                                   (cut (@@ (gaiag step) step:ast->) ast))))
                     (pijltjes ((@@ (gaiag commands trace) trace:step->trace:code) pijltjes))
                     (html (pipeline->string  (cut display pijltjes) (list (string-append %datadir "/trace/t.js")))))
                (values '((content-type . (text/html)))
                        html)))
      (_ (values (build-response #:code 404) (string-append file " not found")))))
  )

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (host "0.0.0.0")
         (port 1818))
    (format (current-error-port) "listening on ~a:~a\n" host port)
    (run-server serve-html 'http `(#:host ,host #:port ,port))))
