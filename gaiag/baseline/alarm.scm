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

(define (stderr . args)
  (apply format (cons* (current-error-port) args)))

(define-class <interface> ()
  (in :accessor .in :init-value #f :init-keyword :in)
  (out :accessor .out :init-value #f :init-keyword :out))

(define-class <interface:Console> (<interface>))

(define-class <interface:Siren> (<interface>))

(define-class <interface:Sensor> (<interface>))

(define-class <Alarm> ()
  (state :accessor .state :init-value '(Alarm States Disarmed))
  (sounding :accessor .sounding :init-value #f)
  (console :accessor .console :init-value #f)
  (sensor :accessor .sensor :init-value #f)
  (siren :accessor .siren :init-form (make <interface:Siren>)))

(define-method (initialize (o <Alarm>) args)
  (next-method)
  (set! (.console o)
        (make <interface:Console>
          :in `((arm . ,(lambda () (console-arm o)))
                (disarm . ,(lambda () (console-disarm o))))))
  (set! (.sensor o)
        (make <interface:Sensor>
          :out `((triggered . ,(lambda () (sensor-triggered o)))
                 (disabled . ,(lambda () (sensor-disabled o)))))))

(define-method (console-arm (o <Alarm>))
  (stderr "Alarm.console-arm\n")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    ((assoc-ref ((compose .in .sensor) o) 'enable))
    (set! (.state o) '(Alarm States Armed)))
   ((equal? (.state o) '(Alarm States Armed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Armed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Disarming))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Triggered))
    (throw 'assert 'illegal))))

(define-method (console-disarm (o <Alarm>))
  (stderr "Alarm.console-disarm\n")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Armed))
    ((assoc-ref ((compose .in .sensor) o) 'disable))
    (set! (.state o) '(Alarm States Disarming)))
   ((equal? (.state o) '(Alarm States Armed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Disarming))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Triggered))
    ((assoc-ref ((compose .in .sensor) o) 'disable))
    ((assoc-ref ((compose .in .siren) o) 'turnoff))
    (set! (.sounding o) #f)
    (set! (.state o) '(Alarm States Disarming)))))

(define-method (sensor-triggered (o <Alarm>))
  (stderr "Alarm.sensor-triggered\n")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Armed))
    ((assoc-ref ((compose .out .console) o) 'detected))
    ((assoc-ref ((compose .in .siren) o) 'turnon))
    (set! (.sounding o) #t)
    (set! (.state o) '(Alarm States Triggered)))
   ((equal? (.state o) '(Alarm States Armed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Disarming))
    #t)
   ((equal? (.state o) '(Alarm States Triggered))
    (throw 'assert 'illegal))))

(define-method (sensor-disabled (o <Alarm>))
  (stderr "Alarm.sensor-disabled\n")
  (cond
   ((equal? (.state o) '(Alarm States Disarmed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Armed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Armed))
    (throw 'assert 'illegal))
   ((equal? (.state o) '(Alarm States Disarming))
    (cond
     ((.sounding o)
      ((assoc-ref ((compose .out .console) o) 'deactivated))
      ((assoc-ref ((compose .in .siren) o) 'turnoff))
      (set! (.state o) '(Alarm States Disarmed))
      (set! (.sounding o) #f))
     (else
      ((assoc-ref ((compose .out .console) o) 'deactivated))
      (set! (.state o) '(Alarm States Disarmed)))))
   ((equal? (.state o) '(Alarm States Triggered))
    (throw 'assert 'illegal))))

(define-class <AlarmSystem> ()
  (alarm :accessor .alarm :init-form (make <Alarm>))
  (sensor :accessor .sensor :init-form (make <SensorExt>))
  (siren :accessor .siren :init-form (make <SirenExt>))
  (console :accessor .console :init-value #f :init-keyword :console))

(define-method (connect-ports (provided <interface>) (required <interface>))
  (set! (.out provided) (.out required))
  (set! (.in required) (.in provided)))

(define-method (initialize (o <AlarmSystem>) args)
  (let-keywords
   args #f ((out #f))
   (next-method)
   (set! (.console o) ((compose .console .alarm) o))
   (set! (.out (.console o)) out)
   (connect-ports (.sensor (.sensor o)) (.sensor (.alarm o)))
   (connect-ports (.siren (.siren o)) (.siren (.alarm o)))))


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
                  :out `((detected . ,(lambda () (stderr "Console.detected\n")))
                         (deactivated . ,(lambda () (stderr "Console.deactivated\n")))))))
    (((compose (port 'arm) .in .console) system))
    (((compose (port 'triggered) .out .sensor .sensor) system))
    (((compose (port 'disarm) .in .console) system))
    (((compose (port 'disabled) .out .sensor .sensor) system))))
