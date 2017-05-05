;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag compare)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag goops)

  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag display)
  #:use-module (gaiag util)

  #:export (
           om:<
           om:equal?
           om:guard-equal?
           om:triggers-equal?
           om:remove-formals
           om:scope.name-equal?
           )
  #:re-export (< equal?))

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
  (< (list (.port.name a) (.event.name a))
     (list (.port.name b) (.event.name b))))

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

(define-method (equal? (a <scope.name>) (b <scope.name>))
  (and (equal? (.scope a) (.scope b)) (equal? (.name a) (.name b))))
(define-method (equal? (a <port>) (b <port>))
  (and (equal? (.name a) (.name b)) (equal? (.name (.type a)) (.name (.type b)))))

;(define-method (equal? (a <ast>) (b <ast>))
;  (equal? (om2list a) (om2list b)))

(define-method (equal? (a <trigger>) (b <trigger>))
  (define (name o)
    (if (is-a? o <named>) (.name o) o))
  
  (and (or (eq? (.port a) (.port b))
           (equal? (name (.port a))
                   (name (.port b))))
       (equal? (name (.event a))
               (name (.event b)))
       (equal? (.formals a) (.formals b))))

(define-method (om:guard-equal? (lhs <guard>) (rhs <guard>))
  (equal? (om->list (.expression lhs)) (om->list (.expression rhs))))

(define-method (om:port-event-equal? a b)
  #f)

(define-method (om:remove-formals (o <trigger>))
  (clone o #:formals (make <formals>)))

(define-method (om:triggers-equal? a b)
  #f)

(define-method (om:triggers-equal? (a <on>) (b <on>))
  (equal? ((compose .elements .triggers) a)
          ((compose .elements .triggers) b)))

(define-method (om:scope.name-equal? (a <scoped>) (b <scoped>))
  (let ((a (.name a))
        (b (.name b)))
    (equal? (append (.scope a) (list (.name a)))
            (append (.scope b) (list (.name b))))))

