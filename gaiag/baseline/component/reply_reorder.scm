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

(define-class <reply_reorder> (<component>)
  (first :accessor .first :init-value #t)
  (p :accessor .p :init-form (make <interface:Provides>))
  (r :accessor .r :init-form (make <interface:Requires>)))

(define-method (initialize (o <reply_reorder>) args)
  (next-method)
  (set! (.p o)
    (make <interface:Provides>
      :in `((start . ,(lambda () (p-start o))))))
  (set! (.r o)
    (make <interface:Requires>
      :out `((pong . ,(lambda () (r-pong o)))))))

(define-method (p-start (o <reply_reorder>))
  (stderr "reply_reorder.p.start\n")
    (action o .r .in 'ping))

(define-method (r-pong (o <reply_reorder>))
  (stderr "reply_reorder.r.pong\n")
    (cond 
    ((.first o)
      (action o .p .out 'busy)
      (set! (.first o) (not (.first o))))
    ((not (.first o))
      (action o .p .out 'finish)
      (set! (.first o) (not (.first o))))))


