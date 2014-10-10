;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gaiag.
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-class <provides_twice> (<system>)
  (one :accessor .one :init-form (make <external_provides_twice>))
  (i :accessor .i :init-value #f :init-keyword :i)
  (ii :accessor .ii :init-value #f :init-keyword :ii))

(define-method (initialize (o <provides_twice>) args)
  (next-method)
  (let-keywords
   args #f ((out-i #f)
            (out-ii #f))
  (set! (.i o) (.i (.one o)))
  (set! (.out (.i o)) out-i)
  (set! (.ii o) (.ii (.one o)))
  (set! (.out (.ii o)) out-ii)))
