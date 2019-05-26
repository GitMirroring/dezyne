;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (gaiag parse)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 rdelim)

  #:use-module (gaiag parse peg)
  #:use-module (gaiag command-line)
  #:use-module (gaiag goops)
  #:use-module (gaiag parse ast)
  #:use-module (gaiag ast)
  #:use-module (gaiag wfc)

  #:export (peg:parse-file
            parse-file))

(define* (peg:parse-file file-name #:key (imports '()))
  (let* ((string (if (equal? file-name "-") (read-string)
                     (catch #t
                       (lambda () (with-input-from-file file-name read-string))
                       (lambda (key . args)
                         (format (current-error-port) "No such file or directory: ~a\n" file-name)
                         (exit 1)))))
         (imports (if (equal? file-name "-") '()
                      (cons (dirname (canonicalize-path file-name)) imports)))
         (parse-tree (catch 'syntax-error
                       (lambda ()
                         (peg:parse string file-name #:imports imports))
                       (peg:handle-syntax-error file-name string)))
         (gdzn-debug? (gdzn:command-line:get 'debug)))
    (parse-tree->ast parse-tree #:string string #:file-name file-name)))

(define* (parse-file file-name #:key peg? generator? (imports '()) behaviour? model-name locations?)
  (let* ((ast (peg:parse-file file-name #:imports imports))
         (ast (if peg? ast
                  (ast:wfc ast))))
    (if (not model-name) ast
        (ast:filter-model ast (ast:get-model ast model-name)))))
