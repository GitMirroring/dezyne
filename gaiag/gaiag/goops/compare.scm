;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag goops compare)
  :use-module (gaiag goops om)

  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag goops display)
  :use-module (gaiag goops om)
  :use-module (gaiag goops util)

  :export (
           om:<
           om:equal?
           om:guard-equal?
           om:triggers-equal?
           )
  :re-export (< equal?))

(define om:< <)
(define om:equal? equal?)

(define-method (< (a <on>) (b <on>))
  (< (.triggers a) (.triggers b)))

(define-method (< (a <on>) (b <guard>))
  #f)

(define-method (< (a <guard>) (b <on>))
  #t)

(define-method (< (a <guard>) (b <guard>))
  (< (.expression a) (.expression b)))

(define-method (< (a <expression>) (b <expression>))
  (< (om->list (.expression a)) (om->list (.expression b))))

(define-method (< (a <expression>) (b <otherwise>))
  #t)

(define-method (< (a <otherwise>) (b <expression>))
  #f)

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
  (equal? (om2list a) (om2list b)))

(define-method (equal? (a <trigger>) (b <trigger>))
  (and (eq? (.port a) (.port b))
       (eq? (.event a ) (.event b))
       (equal? (om->list (.arguments a))
               (om->list (.arguments b)))))

(define-method (equal? (a <literal>) (b <literal>))
  (and (equal? (.name a) (.name b))
       (eq? (.field a) (.field b))))

(define-method (equal? (a <field>) (b <field>))
  (and (eq? (.identifier a) (.identifier b))
       (eq? (.field a) (.field b))))

(define-method (equal? (a <var>) (b <var>))
  (eq? (.name a) (.name b)))

(define-method (equal? (a <expression>) (b <expression>))
  (equal? (om2list (.value a)) (om2list (.value b))))

(define-method (om:guard-equal? (lhs <guard>) (rhs <guard>))
  (equal? (om->list (.expression lhs)) (om->list (.expression rhs))))

(define-method (om:triggers-equal? a b)
  #f)

(define-method (om:triggers-equal? (a <on>) (b <on>))
  (equal? ((compose .elements .triggers) a)
          ((compose .elements .triggers) b)))
