;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2015, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag javascript)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag config)

  #:use-module (gaiag ast)
  #:use-module (gaiag dzn)
  #:use-module (gaiag code)
  #:use-module (gaiag templates))

(define (javascript:namespace-setup o)
  (->string
   (let loop ((todo (cons 'dzn (ast:full-scope o))) (namespace '()))
     (if (null? todo) '()
         (let* ((namespace (append namespace (list (car todo))))
                (x ((->join ".") namespace)))
           (append (list x " = " x " || {};\n" )
                   (loop (cdr todo) namespace)))))))

(define-templates-macro define-templates javascript)
(include "templates/dzn.scm")
(include "templates/code.scm")
(include "templates/javascript.scm")

(define (javascript:root-> root)
  (parameterize ((language 'javascript)
                 (%x:main x:main)
                 (%x:header identity)
                 (%x:source x:source))
    (code:root-> root)))

(define (ast-> ast)
  (let ((root (code:om ast)))
    (javascript:root-> root))
  "")
