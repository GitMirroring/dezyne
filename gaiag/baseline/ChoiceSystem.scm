;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-class <ChoiceSystem> (<system>)
  (choice :accessor .choice :init-form (make <Choice>))
  (c :accessor .c :init-value #f :init-keyword :c))

(define-method (initialize (o <ChoiceSystem>) args)
  (next-method)
  (let-keywords
   args #f ((out-c #f))
  (set! (.c o) (.c (.choice o)))
  (set! (.out (.c o)) out-c)))
