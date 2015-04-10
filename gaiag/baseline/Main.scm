;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-class <Main> (<system>)
  (adaptor :accessor .adaptor :init-value #f)
  (choice :accessor .choice :init-value #f)
  (runner :accessor .runner :init-value #f :init-keyword :runner))

(define-method (initialize (o <Main>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (let-keywords
   args #f ((runtime #f)
            (name (symbol))
            (parent #f)
            (runner.out (make <IRun.out>)))
  (set! (.adaptor o) (make <Adaptor> :runtime (.runtime o) :parent o :name 'adaptor))
  (set! (.choice o) (make <ChoiceSystem> :runtime (.runtime o) :parent o :name 'choice))
  (set! (.runner o) (.runner (.adaptor o)))
  (set! (.out (.runner o)) runner.out))
  (connect-ports (.c (.choice o)) (.choice (.adaptor o))))
