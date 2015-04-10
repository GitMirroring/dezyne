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


(define-class <Comp> (<component>)
  (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
  (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
  (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
  (q :accessor .q :init-form (make-q) :init-keyword :q)
  (s :accessor .s :init-value '(State Uninitialized))
  (reply-IComp-result_t :accessor .reply-IComp-result_t :init-value #f)
  (reply-IDevice-result_t :accessor .reply-IDevice-result_t :init-value #f)
  (client :accessor .client :init-value #f)
  (device_A :accessor .device_A :init-value #f))

(define-method (initialize (o <Comp>) args)
  (next-method)
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o)))
  (set! (.client o)
    (make <IComp>
       :in (make <IComp.in>
              :name 'client
              :self o
              :initialize (lambda (. args) (call-in o (lambda () (apply client-initialize (cons o args))) `(,(.client o) initialize))) 
              :recover (lambda (. args) (call-in o (lambda () (apply client-recover (cons o args))) `(,(.client o) recover))) 
              :perform_actions (lambda (. args) (call-in o (lambda () (apply client-perform_actions (cons o args))) `(,(.client o) perform_actions))) )))
  (set! (.device_A o)
     (make <IDevice>
       :out (make <IDevice.out>
              :name 'device_A
              :self o))))

(define-method (client-initialize (o <Comp>) )
    (cond 
    ((equal? (.s o) '(State Uninitialized))
      (let ((res (make <v> :v (action o .device_A .in .initialize)))) 
      (cond ((equal? (.v res) '(result_t OK)) 
        (set! (.v res) (action o .device_A .in .calibrate))))
      (cond ((equal? (.v res) '(result_t OK)) 
        (set! (.s o) '(State Initialized))
        (set! (.reply-IDevice-result_t o) '(result_t OK)))
      (else 
        (set! (.s o) '(State Uninitialized))
        (set! (.reply-IDevice-result_t o) '(result_t NOK))))))
    ((equal? (.s o) '(State Initialized))
      (illegal))
    ((equal? (.s o) '(State Error))
      (illegal)))
    (.reply-IComp-result_t o))

(define-method (client-recover (o <Comp>) )
    (cond 
    ((equal? (.s o) '(State Uninitialized))
      (illegal))
    ((equal? (.s o) '(State Initialized))
      (illegal))
    ((equal? (.s o) '(State Error))
      (let ((res (make <v> :v (action o .device_A .in .calibrate)))) 
      (cond ((equal? (.v res) '(result_t OK)) 
        (set! (.s o) '(State Initialized))
        (set! (.reply-IDevice-result_t o) '(result_t OK)))
      (else 
        (set! (.s o) '(State Error))
        (set! (.reply-IDevice-result_t o) '(result_t NOK)))))))
    (.reply-IComp-result_t o))

(define-method (client-perform_actions (o <Comp>) )
    (cond 
    ((equal? (.s o) '(State Uninitialized))
      (illegal))
    ((equal? (.s o) '(State Initialized))
      (let ((res (make <v> :v (action o .device_A .in .perform_action1)))) 
      (cond ((equal? (.v res) '(result_t OK)) 
        (set! (.v res) (action o .device_A .in .perform_action2))))
      (cond ((equal? (.v res) '(result_t OK)) 
        (set! (.s o) '(State Initialized))
        (set! (.reply-IDevice-result_t o) '(result_t OK)))
      (else 
        (set! (.s o) '(State Error))
        (set! (.reply-IDevice-result_t o) '(result_t NOK))))))
    ((equal? (.s o) '(State Error))
      (illegal)))
    (.reply-IComp-result_t o))


