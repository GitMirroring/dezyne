;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-class <AlarmSystem> (<system>)
  (alarm :accessor .alarm :init-form (make <Alarm>))
  (sensor :accessor .sensor :init-form (make <Sensor>))
  (siren :accessor .siren :init-form (make <Siren>))
  (console :accessor .console :init-value #f :init-keyword :console))

(define-method (initialize (o <AlarmSystem>) args)
  (next-method)
  (let-keywords
   args #f ((out-console #f))
  (set! (.console o) (.console (.alarm o)))
  (set! (.out (.console o)) out-console))
  (connect-ports (.sensor (.sensor o)) (.sensor (.alarm o)))
  (connect-ports (.siren (.siren o)) (.siren (.alarm o))))
