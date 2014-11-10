;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag gom compare)
  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag gom ast)
  :use-module (gaiag gom display)
  :use-module (gaiag gom gom)
  :use-module (gaiag gom util)

  :re-export (< equal?))

(define-method (< (a <on>) (b <on>))
  (< (.triggers a) (.triggers b)))

(define-method (< (a <triggers>) (b <triggers>))
  (< (stable-sort (.elements a) <)
     (stable-sort (.elements b) <)))

(define-method (< (a <trigger>) (b <trigger>))
  (< (list (.port a) (.event a)) (list (.port b) (.event b))))

(define-method (< (a <list>) (b <list>))
  (cond
   ((null? a) (not (null? b)))
   ((null? b) #f)
   ((and (not (< (car a) (car b)))
               (not (< (car b) (car a))))
    (< (cdr a) (cdr b)))
   (else (< (car a) (car b)))))

(define-method (< (a <symbol>) (b <symbol>))
  (symbol< a b))

(define-method (< (a <boolean>) (b <symbol>))
  #t)

(define-method (< (a <boolean>) (b <boolean>))
  #f)

(define-method (< (a <symbol>) (b <boolean>))
  #f)

(define-method (equal? (a <statement>) (b <statement>))
  (equal? (gom->list a) (gom->list b)))

(define-method (equal? (a <trigger>) (b <trigger>))
  (and (eq? (.port a) (.port b))
       (eq? (.event a ) (.event b))))

(define-method (equal? (lhs <literal>) (rhs <literal>))
  (and (eq? (.scope lhs) (.scope rhs))
       (eq? (.type lhs) (.type rhs))
       (eq? (.field lhs) (.field rhs))))

(define-method (equal? (lhs <field>) (rhs <field>))
  (and (eq? (.identifier lhs) (.identifier rhs))
       (eq? (.field lhs) (.field rhs))))

(define-method (equal? (lhs <var>) (rhs <var>))
  (eq? (.name lhs) (.name rhs)))
