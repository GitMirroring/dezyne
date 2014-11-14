;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-class <Reply7> (<component>)
  (reply-IReply7-E :accessor .reply-IReply7-E :init-value #f)
  (p :accessor .p :init-form (make <interface:IReply7>))
  (r :accessor .r :init-form (make <interface:IReply7>)))

(define-method (initialize (o <Reply7>) args)
  (next-method)
  (set! (.p o)
    (make <interface:IReply7>
      :in `((foo . ,(lambda () (p-foo o))))))
  (set! (.r o)
    (make <interface:IReply7>)))

(define-method (p-foo (o <Reply7>))
  (stderr "Reply7.p.foo\n")
    (f o)
    (.reply-IReply7-E o))

(define-method (f (o <Reply7>) )
  (call/cc
   (lambda (return) 
    (let ((v (action o .r .in 'foo))) 
    (set! (.reply-IReply7-E o) v)))))


