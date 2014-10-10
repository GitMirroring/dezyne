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

(define-class <Comp> (<component>)
  (s :accessor .s :init-value '(State Uninitialized))
  (reply-IComp-result_t :accessor .reply-IComp-result_t :init-value #f)
  (reply-IDevice-result_t :accessor .reply-IDevice-result_t :init-value #f)
  (client :accessor .client :init-form (make <interface:IComp>))
  (device_A :accessor .device_A :init-form (make <interface:IDevice>)))

(define-method (initialize (o <Comp>) args)
  (next-method)
  (set! (.client o)
    (make <interface:IComp>
      :in `((initialize . ,(lambda () (client-initialize o)))
            (recover . ,(lambda () (client-recover o)))
            (perform_actions . ,(lambda () (client-perform_actions o))))))
  (set! (.device_A o)
    (make <interface:IDevice>)))

(define-method (client-initialize (o <Comp>))
  (stderr "Comp.client.initialize\n")
    (cond 
    ((equal? (.s o) '(State Uninitialized))
      (let ((res (action o .device_A .in 'initialize))) 
      (cond ((equal? res '(result_t OK)) 
        (set! res (action o .device_A .in 'calibrate))))
      (cond ((equal? res '(result_t OK)) 
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

(define-method (client-recover (o <Comp>))
  (stderr "Comp.client.recover\n")
    (cond 
    ((equal? (.s o) '(State Uninitialized))
      (illegal))
    ((equal? (.s o) '(State Initialized))
      (illegal))
    ((equal? (.s o) '(State Error))
      (let ((res (action o .device_A .in 'calibrate))) 
      (cond ((equal? res '(result_t OK)) 
        (set! (.s o) '(State Initialized))
        (set! (.reply-IDevice-result_t o) '(result_t OK)))
      (else 
        (set! (.s o) '(State Error))
        (set! (.reply-IDevice-result_t o) '(result_t NOK)))))))
    (.reply-IComp-result_t o))

(define-method (client-perform_actions (o <Comp>))
  (stderr "Comp.client.perform_actions\n")
    (cond 
    ((equal? (.s o) '(State Uninitialized))
      (illegal))
    ((equal? (.s o) '(State Initialized))
      (let ((res (action o .device_A .in 'perform_action1))) 
      (cond ((equal? res '(result_t OK)) 
        (set! res (action o .device_A .in 'perform_action2))))
      (cond ((equal? res '(result_t OK)) 
        (set! (.s o) '(State Initialized))
        (set! (.reply-IDevice-result_t o) '(result_t OK)))
      (else 
        (set! (.s o) '(State Error))
        (set! (.reply-IDevice-result_t o) '(result_t NOK))))))
    ((equal? (.s o) '(State Error))
      (illegal)))
    (.reply-IComp-result_t o))


