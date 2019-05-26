;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
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

(define-module (gaiag command-line)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag gdzn)
  #:export (command-line:get
            gdzn:command-line:get
            gdzn:debugity
            gdzn:multi-opt
            gdzn:verbosity
            language))

(define multi-options
  '(import))

(define* (command-line:get option #:optional default)
  (and (> (length (command-line)) 1)
       (let* ((files (option-ref (parse-opts (command-line)) '() '(#f)))
              (file (car files))
              (commands '("code" "parse" "run" "step" "table" "trace" "traces" "verify" "lts"))
              (command (and=> (member file commands) (compose string->symbol car)))
              (parse-opts (let ((module (resolve-module `(gaiag commands ,command))))
                            (module-ref module 'parse-opts)))
              (options (if command (parse-opts files)
                           (parse-opts (command-line))))
              (multi-opt (lambda (option) (lambda (o) (and (eq? (car o) option) (cdr o))))))
         (if (not (member option multi-options)) (option-ref options option default)
             (filter-map (multi-opt option) options)))))

(define* (gdzn:command-line:get option #:optional default)
  (and (> (length (command-line)) 1)
       (let ((options (parse-opts (command-line))))
         (option-ref options option default))))

(define (multi-opt options name)
  (let ((opt? (lambda (o) (and (eq? (car o) name) (cdr o)))))
    (filter-map opt? options)))

(define (gdzn:multi-opt name)
  (and (> (length (command-line)) 1)
       (multi-opt (parse-opts (command-line)) name)))

(define (gdzn:debugity)
   (or (and (pair? (command-line))
         (equal? ((compose basename car command-line)) "gdzn")
         (length (gdzn:multi-opt 'debug)))
       0))

(define (gdzn:verbosity)
  (gdzn:multi-opt 'debug))

(define language (make-parameter 'c++))
