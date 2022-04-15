;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
;;;
;;; This file is part of Snuik.
;;;
;;; Snuik is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Snuik is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Snuik.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn goops define-method-star)
  #:use-module (oop goops)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:export (define-method*))

(define-syntax define-method*
  (lambda (x)
    (syntax-case x ()
      ((_ (generic arg-spec ... . tail) body ...)
       (let-values (((required-arg-specs other-arg-specs)
                     (break (compose keyword? syntax->datum)
                            #'(arg-spec ...))))
         #`(define-method (generic #,@required-arg-specs . rest)
             (apply (lambda* (#,@other-arg-specs . tail)
                      body ...)
                    rest)))))))
