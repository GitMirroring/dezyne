;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  ((@ (dezine) main) (command-line)))

(read-set! keywords 'prefix)

(define-module (dezine)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (oop goops)
  :export (main))

(define (stderr . args)
  (apply format (cons* (current-error-port) args)))

(define-class <model> ())

(define-class <interface> (<model>)
  (in :accessor .in :init-value #f :init-keyword :in)
  (out :accessor .out :init-value #f :init-keyword :out))

(define-class <component> (<interface>))
(define-class <system> (<model>))

(define-method (connect-ports (provided <interface>) (required <interface>))
  (set! (.out provided) (.out required))
  (set! (.in required) (.in provided)))

(define (illegal) (throw 'assert 'illegal))

(define-method (action (o <component>) (port <accessor>) (dir <accessor>) (event <symbol>))
  ((assoc-ref ((compose dir port) o) event)))
(define-class <interface:ISiren> (<interface>))
(define-class <interface:ISensor> (<interface>))
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
(define-class <interface:IConsole> (<interface>))
(define-class <Alarm> (<component>)
  (state :accessor .state :init-value '(States Disarmed))
  (sounding :accessor .sounding :init-value #f)
  (console :accessor .console :init-form (make <interface:IConsole>))
  (sensor :accessor .sensor :init-form (make <interface:ISensor>))
  (siren :accessor .siren :init-form (make <interface:ISiren>)))

(define-method (initialize (o <Alarm>) args)
  (next-method)
  (set! (.console o)
    (make <interface:IConsole>
      :in `((arm . ,(lambda () (console-arm o)))
            (disarm . ,(lambda () (console-disarm o))))))
  (set! (.sensor o)
    (make <interface:ISensor>
      :out `((triggered . ,(lambda () (sensor-triggered o)))
            (disabled . ,(lambda () (sensor-disabled o))))))
  (set! (.siren o)
    (make <interface:ISiren>)))

(define-method (console-arm (o <Alarm>))
  (stderr "Alarm.console.arm\n")
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (action o .sensor .in 'enable)
      (set! (.state o) '(States Armed)))
    ((equal? (.state o) '(States Armed))
      (illegal))
    ((equal? (.state o) '(States Disarming))
      (illegal))
    ((equal? (.state o) '(States Triggered))
      (illegal))))

(define-method (console-disarm (o <Alarm>))
  (stderr "Alarm.console.disarm\n")
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (illegal))
    ((equal? (.state o) '(States Armed))
      (action o .sensor .in 'disable)
      (set! (.state o) '(States Disarming)))
    ((equal? (.state o) '(States Disarming))
      (illegal))
    ((equal? (.state o) '(States Triggered))
      (action o .sensor .in 'disable)
      (action o .siren .in 'turnoff)
      (set! (.sounding o) #f)
      (set! (.state o) '(States Disarming)))))

(define-method (sensor-triggered (o <Alarm>))
  (stderr "Alarm.sensor.triggered\n")
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (illegal))
    ((equal? (.state o) '(States Armed))
      (action o .console .out 'detected)
      (action o .siren .in 'turnon)
      (set! (.sounding o) #t)
      (set! (.state o) '(States Triggered)))
    ((equal? (.state o) '(States Disarming))
      #t)
    ((equal? (.state o) '(States Triggered))
      (illegal))))

(define-method (sensor-disabled (o <Alarm>))
  (stderr "Alarm.sensor.disabled\n")
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (illegal))
    ((equal? (.state o) '(States Armed))
      (illegal))
    ((equal? (.state o) '(States Disarming))
      (cond 
    ((.sounding o)
        (action o .console .out 'deactivated)
        (action o .siren .in 'turnoff)
        (set! (.state o) '(States Disarmed))
        (set! (.sounding o) #f))
    (else
        (action o .console .out 'deactivated)
        (set! (.state o) '(States Disarmed)))))
    ((equal? (.state o) '(States Triggered))
      (illegal))))


;; Handwritten
(define-class <Sensor> ()
  (sensor :accessor .sensor :init-value #f))

(define-method (initialize (o <Sensor>) args)
  (next-method)
  (set! (.sensor o)
        (make <interface:ISensor>
          :in `((enable . ,(lambda () (enable o)))
                (disable . ,(lambda () (disable o)))))))

(define-method (enable (o <Sensor>))
  (stderr "Sensor.enable\n"))

(define-method (disable (o <Sensor>))
  (stderr "Sensor.disable\n"))

(define-class <Siren> ()
  (siren :accessor .siren :init-value #f))

(define-method (initialize (o <Siren>) args)
  (next-method)
  (set! (.siren o) (make <interface:ISiren>
                     :in `((turnon . ,(lambda () (turnon o)))
                           (turnoff . ,(lambda () (turnoff o)))))))

(define-method (turnon (o <Siren>))
  (stderr "Siren.turnon\n"))

(define-method (turnoff (o <Siren>))
  (stderr "Siren.turnoff\n"))

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
