;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

(define-module (gaiag cd)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  ;; #:use-module (ice-9 readline)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag ast)
  #:use-module (gaiag code)
  #:use-module (gaiag command-line)
  #:use-module (gaiag config)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag dzn)
  #:use-module (gaiag goops)
  #:use-module (gaiag misc)
  #:use-module (gaiag templates)
  #:use-module (gaiag util)

)


(define-templates-macro define-templates cd)
(include "../templates/cd.scm")

(define (cd:root-> root)
  (parameterize ((language 'cd)
                 (%x:source x:source)
                 )
    (code:root-> root)))

(define (ast-> ast)
  (let ((ast (code:om ast)))
    (pretty-print (om->list ast))
    (cd:root-> ast)))
