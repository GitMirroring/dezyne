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


(define-class <Alarm> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (state :accessor .state :init-value '(States Disarmed))
  (sounding :accessor .sounding :init-value #f)
  (console :accessor .console :init-value #f)
  (sensor :accessor .sensor :init-value #f)
  (siren :accessor .siren :init-value #f))

(define-method (initialize (o <Alarm>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.console o)
    (make <IConsole>
       :in (make <IConsole.in>
              :name 'console
              :self o
              :arm (lambda (. args) (call-in o (lambda () (console-arm o)) `(,(.console o) arm))) 
              :disarm (lambda (. args) (call-in o (lambda () (console-disarm o)) `(,(.console o) disarm))) )))
  (set! (.sensor o)
     (make <ISensor>
       :out (make <ISensor.out>
              :name 'sensor
              :self o
              :triggered (lambda (. args) (call-out o (lambda () (sensor-triggered o)) `(,(.sensor o) triggered))) 
              :disabled (lambda (. args) (call-out o (lambda () (sensor-disabled o)) `(,(.sensor o) disabled))) )))
  (set! (.siren o)
     (make <ISiren>
       :out (make <ISiren.out>
              :name 'siren
              :self o))))

(define-method (console-arm (o <Alarm>))
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (action o .sensor .in .enable)
      (set! (.state o) '(States Armed)))
    ((equal? (.state o) '(States Armed))
      (illegal))
    ((equal? (.state o) '(States Disarming))
      (illegal))
    ((equal? (.state o) '(States Triggered))
      (illegal))))

(define-method (console-disarm (o <Alarm>))
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (illegal))
    ((equal? (.state o) '(States Armed))
      (action o .sensor .in .disable)
      (set! (.state o) '(States Disarming)))
    ((equal? (.state o) '(States Disarming))
      (illegal))
    ((equal? (.state o) '(States Triggered))
      (action o .sensor .in .disable)
      (action o .siren .in .turnoff)
      (set! (.sounding o) #f)
      (set! (.state o) '(States Disarming)))))

(define-method (sensor-triggered (o <Alarm>))
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (illegal))
    ((equal? (.state o) '(States Armed))
      (action o .console .out .detected)
      (action o .siren .in .turnon)
      (set! (.sounding o) #t)
      (set! (.state o) '(States Triggered)))
    ((equal? (.state o) '(States Disarming))
      #t)
    ((equal? (.state o) '(States Triggered))
      (illegal))))

(define-method (sensor-disabled (o <Alarm>))
    (cond 
    ((equal? (.state o) '(States Disarmed))
      (illegal))
    ((equal? (.state o) '(States Armed))
      (illegal))
    ((and (equal? (.state o) '(States Disarming)) (.sounding o))
      (action o .console .out .deactivated)
      (action o .siren .in .turnoff)
      (set! (.state o) '(States Disarmed))
      (set! (.sounding o) #f))
    ((and (equal? (.state o) '(States Disarming)) (not (.sounding o)))
      (action o .console .out .deactivated)
      (set! (.state o) '(States Disarmed)))
    ((equal? (.state o) '(States Triggered))
      (illegal))))


