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

(define-class <AlarmSystem> (<system>)
  (alarm :accessor .alarm :init-value #f)
  (sensor :accessor .sensor :init-value #f)
  (siren :accessor .siren :init-value #f)
  (console :accessor .console :init-value #f :init-keyword :console))

(define-method (initialize (o <AlarmSystem>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (let-keywords
   args #f ((runtime #f)
            (name (symbol))
            (parent #f)
            (console.out (make <IConsole.out>)))
  (set! (.alarm o) (make <Alarm> :runtime (.runtime o) :parent o :name 'alarm))
  (set! (.sensor o) (make <Sensor> :runtime (.runtime o) :parent o :name 'sensor))
  (set! (.siren o) (make <Siren> :runtime (.runtime o) :parent o :name 'siren))
  (set! (.console o) (.console (.alarm o)))
  (set! (.out (.console o)) console.out))
  (connect-ports (.sensor (.sensor o)) (.sensor (.alarm o)))
  (connect-ports (.siren (.siren o)) (.siren (.alarm o))))
