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

(define-class <Main> (<system>)
  (adaptor :accessor .adaptor :init-form (make <Adaptor>))
  (choice :accessor .choice :init-form (make <ChoiceSystem>))
  (runner :accessor .runner :init-value #f :init-keyword :runner))

(define-method (initialize (o <Main>) args)
  (next-method)
  (let-keywords
   args #f ((out-runner #f))
  (set! (.runner o) (.runner (.adaptor o)))
  (set! (.out (.runner o)) out-runner))
  (connect-ports (.c (.choice o)) (.choice (.adaptor o))))
