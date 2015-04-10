;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-class <provides_twice> (<system>)
  (one :accessor .one :init-value #f)
  (i :accessor .i :init-value #f :init-keyword :i)
  (ii :accessor .ii :init-value #f :init-keyword :ii))

(define-method (initialize (o <provides_twice>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (let-keywords
   args #f ((runtime #f)
            (name (symbol))
            (parent #f)
            (i.out (make <iprovides_once.out>))
            (ii.out (make <iprovides_twice.out>)))
  (set! (.one o) (make <external_provides_twice> :runtime (.runtime o) :parent o :name 'one))
  (set! (.i o) (.i (.one o)))
  (set! (.out (.i o)) i.out)
  (set! (.ii o) (.ii (.one o)))
  (set! (.out (.ii o)) ii.out)))
