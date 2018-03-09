;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag html)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-26)
  #:use-module (gaiag misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag config)
  #:use-module (gaiag command-line)
  #:use-module (gaiag dzn)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag templates)

  #:export (
           ast->
           ast->html
           ))

(define-templates-macro define-templates html)
(include "../templates/dzn.scm")
(include "../templates/html.scm")

(define (ast-> ast)
  (let ((root (dzn:om ast)))
    (parameterize ((%x:source x:source))
     (dzn:root-> root)))
  "")

(define (dzn:root-> root)
  (parameterize ((language 'html)
                 (%x:source x:source))
    (if (dzn:model2file?) (dzn:model2file root)
        (dzn:file2file root))))

(define-method (ast->html (o <statement>))
  (with-output-to-string (cut x:source o)))
