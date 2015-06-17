;;; Dezyne --- Dezyne command line tools
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

;; Handwritten
;; (define-class <Sensor> (<component>)
;;   (sensor :accessor .sensor :init-value #f))

;; (define-method (initialize (o <Sensor>) args)
;;   (next-method)
;;   (set! (.sensor o)
;;         (make <ISensor>
;;           :in (make <ISensor.in>
;;                 :name 'sensor
;;                 :self o
;;                 :enable (lambda () (enable o))
;;                 :disable (lambda () (disable o))))))

;; (define-method (enable (o <Sensor>))
;;   (stderr "Sensor.enable\n"))

;; (define-method (disable (o <Sensor>))
;;   (stderr "Sensor.disable\n"))

;; (define-class <Siren> (<component>)
;;   (siren :accessor .siren :init-value #f))

;; (define-method (initialize (o <Siren>) args)
;;   (next-method)
;;   (set! (.siren o) (make <ISiren>
;;                      :in
;;                      (make <ISiren.in>
;;                        :name 'siren
;;                        :self o
;;                        :turnon (lambda () (turnon o))
;;                        :turnoff (lambda () (turnoff o))))))

;; (define-method (turnon (o <Siren>))
;;   (stderr "Siren.turnon\n"))

;; (define-method (turnoff (o <Siren>))
;;   (stderr "Siren.turnoff\n"))

(define (main args)
  (let* ((loc (make <locator>))
         (rt (make <runtime>))
         (sut (make <AlarmSystem>
                :locator (set loc rt)
                :name 'sut
                :console.out
                (make <IConsole.out>
                 :detected (lambda () (stderr "Console.detected\n"))
                 :deactivated (lambda () (stderr "Console.deactivated\n"))))))
    (action sut .alarm .console .in .arm)
    (action sut .sensor .sensor .out .triggered)
    (flush (.sensor sut))
    (action sut .alarm .console .in .disarm)
    (action sut .sensor .sensor .out .disabled)
    (flush (.sensor sut))))

