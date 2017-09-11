;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 optargs)

  #:use-module (gaiag deprecated animate)
  #:use-module (gaiag command-line)
  #:use-module (gaiag ast)
  #:use-module (gaiag resolve)
  #:use-module (gaiag dzn)
  #:use-module (gaiag misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag ast)
  #:use-module (gaiag xpand)
  #:use-module (gaiag goops)

  #:export (
           ast->
           ast->html
           ))

(define (ast-> ast)
  (let ((root (dzn:om ast)))
    (ast:set-scope root (dzn:root-> root)))
  "")

(define (dzn:root-> root)
  (parameterize ((language 'html))
    (if (dzn:model2file?) (dzn:model2file root)
        (dzn:file2file root))))

(define-method (ast->html (o <statement>))
  (parameterize ((language 'html))
    (with-output-to-string (dzn:x:pand-display o 'statement))))

(define-template x:css (lambda (o) (gulp-template 'dzn.css)))
