;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; Handwritten
(define-class <dezyne:Sensor> (<dezyne:component>)
  (sensor :accessor .sensor :init-value #f))

(define-method (initialize (o <dezyne:Sensor>) args)
  (next-method)
  (set! (.sensor o)
        (make <dezyne:ISensor>
          :in (make <dezyne:ISensor.in>
                :name 'sensor
                :self o
                :enable (lambda () (enable o))
                :disable (lambda () (disable o))))))

(define-method (enable (o <dezyne:Sensor>))
  (stderr "Sensor.enable\n"))

(define-method (disable (o <dezyne:Sensor>))
  (stderr "Sensor.disable\n"))

(define-class <dezyne:Siren> (<dezyne:component>)
  (siren :accessor .siren :init-value #f))

(define-method (initialize (o <dezyne:Siren>) args)
  (next-method)
  (set! (.siren o) (make <dezyne:ISiren>
                     :in
                     (make <dezyne:ISiren.in>
                       :name 'siren
                       :self o
                       :turnon (lambda () (turnon o))
                       :turnoff (lambda () (turnoff o))))))

(define-method (turnon (o <dezyne:Siren>))
  (stderr "Siren.turnon\n"))

(define-method (turnoff (o <dezyne:Siren>))
  (stderr "Siren.turnoff\n"))

(define (main args)
  (let* ((loc (make <dezyne:locator>))
         (rt (make <dezyne:runtime>))
         (sut (make <dezyne:AlarmSystem>
                :locator (set loc rt)
                :console.out
                (make <dezyne:IConsole.out>
                  :detected (lambda () (stderr "Console.detected\n"))
                  :deactivated (lambda () (stderr "Console.deactivated\n"))))))
    (action (.alarm sut) .console .in .arm)
    (action (.sensor sut) .sensor .out .triggered)
    (action (.alarm sut) .console .in .disarm)
    (action (.sensor sut) .sensor .out .disabled)))
