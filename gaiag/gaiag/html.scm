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
  #:use-module (gaiag dzn)
  #:use-module (gaiag misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag om)
  #:use-module (gaiag xpand)

  #:export (
           ast->
           ast->html
           ))

(define (animate file-name x)
  (with-output-to-string
    (lambda ()
      (parameterize ((template-dir (append (prefix-dir) `(templates html))))
        (animate-file (symbol-append file-name '.html.scm) x)))))

(define* ((ast->html #:optional (model #f)) o)
  (((@@ (gaiag dzn) ast->dzn) model 'html) o))

(define (ast-> ast)
  (let ((ast ((@@ (gaiag dzn) ast->) ast))
        (style (gulp-template '(html dzn.css))))
    (animate 'template `((ast ,ast)
                         (style ,style)))))
