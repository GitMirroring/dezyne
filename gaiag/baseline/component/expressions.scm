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

(define-class <expressions> (<component>)
  (state :accessor .state :init-value 3)
  (c :accessor .c :init-value 0)
  (i :accessor .i :init-form (make <interface:I>)))

(define-method (initialize (o <expressions>) args)
  (next-method)
  (set! (.i o)
    (make <interface:I>
      :in `((e . ,(lambda () (i-e o)))))))

(define-method (i-e (o <expressions>))
  (stderr "expressions.i.e\n")
    (cond 
    (#t
      (cond ((equal? (.state o) 0) 
        (set! (.state o) 3)
        (action o .i .out 'a))
      (else 
        (set! (.state o) (- (.state o) 1))
        (cond ((< (.c o) (.state o)) 
          (set! (.c o) (+ (.c o) 1)))
        (else 
          (cond ((<= (.c o) ((+ (.state o) 1))) 
            (action o .i .out 'lo))
          (else 
            (cond ((> (.c o) (.state o)) 
              (action o .i .out 'hi))))))))))))


