;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag c++-msvc11)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag animate)
  #:use-module (gaiag om)
  #:use-module (gaiag code)
  #:use-module (gaiag c++)
  #:export (ast->)
  )

(define ast-> (@@ (gaiag c++) ast->))
(define c++:scope-join (@@ (gaiag c++) c++:scope-join))
(define c++:scope-name (@@ (gaiag c++) c++:scope-name))
(define (c++:init-brace-open) "(")
(define (c++:init-brace-close) ")")
(define c++:out-var-decls (@@ (gaiag c++) c++:out-var-decls))
(define c++:out-param-list (@@ (gaiag c++) c++:out-param-list))
(define c++:skel-file (@@ (gaiag c++) c++:skel-file))
(define glue (@@ (gaiag c++) glue))
