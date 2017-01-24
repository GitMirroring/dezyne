;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag python)
  #:use-module (ice-9 pretty-print)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)

  #:use-module (gaiag code)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)

  #:export (ast->))

(define (ast-> ast)
  (parameterize ((indenter #f)) (ast:code ast)))
