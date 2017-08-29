;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag command-line)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 getopt-long)
  #:use-module (gaiag gaiag)
  #:export (command-line:get
            language))

(define multi-options
  '(import))

(define* (command-line:get option #:optional default)
  (let* ((files (option-ref (parse-opts (command-line)) '() '(#f)))
         (file (car files))
         (commands '("code" "table" "traces"))
         (command (and=> (member file commands) (compose string->symbol car)))
         (parse-opts (if (not command) parse-opts
                         (let ((module (resolve-module `(gaiag commands ,command))))
                           (module-ref module 'parse-opts))))
         (options (if command (parse-opts files)
                      (parse-opts (command-line))))
         (multi-opt (lambda (option) (lambda (o) (and (eq? (car o) option) (cdr o))))))
    (if (not (member option multi-options)) (option-ref options option default)
        (filter-map (multi-opt option) options))))

(define (language)
  (string->symbol (command-line:get 'language "c++")))
