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


(define (main . args)
  ((@ (dezine alarm) main) (command-line)))

(read-set! keywords 'prefix)

(define-module (dezine alarm)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (oop goops)
  :export (main))

(define-class <interface> ()
  (in :accessor .in :init-value #f :init-keyword :in)
  (out :accessor .out :init-value #f :init-keyword :out))

(define-class <interface:Console> (<interface>))

(define-class <interface:Siren> (<interface>))

(define-class <interface:Sensor> (<interface>))

(define-class <Alarm> ()
  (state :accessor .state :init-value '(Alarm States Disarmed))
  (sounding :accessor .sounding :init-value #f)
  (console :accessor .console
           :init-form (make <interface:Console>
                        :in `((arm . ,console-arm)
                              (disarm . ,console-disarm))))
  (sensor :accessor .sensor
          :init-form (make <interface:Siren>
                       :out `((triggered . ,sensor-triggered)
                              (disabled . ,sensor-disabled))))
  (siren :accessor .siren :init-form (make <interface:Sensor>)))

(define-method (console-arm (o <Alarm>))
  (format (current-error-port) "Alarm.console-arm")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    ((assoc-ref ((compose .in .sensor) o) 'enable))
    (set! (.state o) '(Alarm States Armed)))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Disarming)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Triggered)) (throw 'assert))))

(define-method (console-disarm (o <Alarm>))
  (format (current-error-port) "Alarm.console-disarm")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    ((assoc-ref ((compose .in .sensor) o) 'enable))
    (set! (.state o) '(Alarm States Armed)))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Disarming)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Triggered)) (throw 'assert))))

(define-method (sensor-triggered (o <Alarm>))
  (format (current-error-port) "Alarm.sensor-triggered")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    ((assoc-ref ((compose .in .sensor) o) 'enable))
    (set! (.state o) '(Alarm States Armed)))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Disarming)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Triggered)) (throw 'assert))))

(define-method (sensor-disabled (o <Alarm>))
  (format (current-error-port) "Alarm.sensor-disabled")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    ((assoc-ref ((compose .in .sensor) o) 'enable))
    (set! (.state o) '(Alarm States Armed)))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Armed)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Disarming)) (throw 'assert))
   ((equal? (.state o) '(Alarm States Triggered)) (throw 'assert))))

(define-class <Sensor> ()
  (sensor :accessor .sensor
           :init-form (make <interface:Sensor>
                        :in `((enable . ,sensor-enable)
                              (disable . ,sensor-disable)))))

(define-method (sensor-enable (o <Sensor>))
  (format (current-error-port) "Sensor.sensor-enable"))

(define-method (sensor-disable (o <Sensor>))
  (format (current-error-port) "Sensor.sensor-disable"))

(define-class <Siren> ()
  (siren :accessor .siren
           :init-form (make <interface:Siren>
                        :in `((turnon . ,siren-turnon)
                              (turnoff . ,siren-turnoff)))))

(define-method (siren-turnon (o <Siren>))
  (format (current-error-port) "Siren.siren-turnon"))

(define-method (siren-turnoff (o <Siren>))
  (format (current-error-port) "Siren.siren-turnoff"))

(define-class <AlarmSystem> ()
  (alarm :accessor .alarm :init-form (make <Alarm>))
  (sensor :accessor .sensor :init-form (make <Sensor>))
  (siren :accessor .siren :init-form (make <Siren>))
  (console :accessor .console :init-value #f :init-keyword :console))

(define-generic connect)
(define-method (connect (provided <interface>) (required <interface>))
  (set! (.out provided) (.out required))
  (set! (.in required) (.in provided)))

(define-method (initialize (o <AlarmSystem>) args)
  (let-keywords
   args #f ((out #f))
   (next-method)
   (set! (.console o) ((compose .console .alarm) o))
   (set! (.out (.console o)) out)
   (connect ((compose .sensor .sensor) o)
            ((compose .sensor .alarm) o))
   (connect ((compose .siren .siren) o)
            ((compose .siren .alarm) o))))

(define ((port name) o) (assoc-ref o name))

(define (main args)
  (let ((system (make <AlarmSystem>
                  :out `((detected . ,(lambda () (format (current-error-port) "Console.detected")))
                         (deactivated . ,(lambda () (format (current-error-port) "Console.deactivated")))))))
    (format (current-error-port) "Hello\n")
    (((compose (port 'arm) .in .console) system))
    (((compose (port 'triggered) .out .sensor .sensor) system))
    (((compose (port 'disarm) .in .console) system))
    (((compose (port 'disabled) .out .sensor .sensor) system))))
