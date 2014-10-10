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

;; Handwritten
(define-class <SensorExt> ()
  (sensor :accessor .sensor :init-value #f))

(define-method (initialize (o <SensorExt>) args)
  (next-method)
  (set! (.sensor o)
        (make <interface:Sensor>
          :in `((enable . ,(lambda () (enable o)))
                (disable . ,(lambda () (disable o)))))))

(define-method (enable (o <SensorExt>))
  (stderr "SensorExt.enable\n"))

(define-method (disable (o <SensorExt>))
  (stderr "SensorExt.disable\n"))

(define-class <SirenExt> ()
  (siren :accessor .siren :init-value #f))

(define-method (initialize (o <SirenExt>) args)
  (next-method)
  (set! (.siren o) (make <interface:Siren>
                     :in `((turnon . ,(lambda () (turnon o)))
                           (turnoff . ,(lambda () (turnoff o)))))))

(define-method (turnon (o <SirenExt>))
  (stderr "SirenExt.turnon\n"))

(define-method (turnoff (o <SirenExt>))
  (stderr "SirenExt.turnoff\n"))

(define ((port name) o) (assoc-ref o name))

(define (main args)
  (let ((system (make <AlarmSystem>
                  :out-console
                  `((detected . ,(lambda () (stderr "Console.detected\n")))
                    (deactivated . ,(lambda () (stderr "Console.deactivated\n")))))))
    (((compose (port 'arm) .in .console) system))
    (((compose (port 'triggered) .out .sensor .sensor) system))
    (((compose (port 'disarm) .in .console) system))
    (((compose (port 'disabled) .out .sensor .sensor) system))))
