;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag compare)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag ast)
  #:use-module (gaiag goops)

  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag display)
  #:use-module (gaiag util)

  #:export (
           om:<
           ;;ast:equal?
           om:guard-equal?
           om:triggers-equal?
           om:remove-formals
           om:scope.name-equal?
           )
  #:re-export (< equal?))

(define om:< <)

;; (define-method (ast:equal? a b)
;;   (equal? (om->list a) (om->list b)))

;; (define-method (ast:equal? (a <ast>) (b <ast>))
;;   (ast:equal? (.node a) (.node b)))

(define-method (children (o <ast>))
  (children (.node o)))

(define-method (children (o <ast-node>))
  (let ((getters (map slot-definition-getter (class-slots (class-of o)))))
    (map (cut <> o) getters)))

;; (define-method (ast:equal? (a <ast-node>) (b <ast-node>))
;;   (or (= (.id a) (.id b))
;;       (and (eq? (class-name (class-of a)) (class-name (class-of b)))
;;            (every ast:equal? (children a) (children b)))))

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
  (< (stable-sort (ast:trigger* a) <)
     (stable-sort (ast:trigger* b) <)))

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

;; (define-method (ast:equal? (a <scope.name>) (b <scope.name>))
;;   (and (equal? (.scope a) (.scope b)) (equal? (.name a) (.name b))))
;; (define-method (ast:equal? (a <port>) (b <port>))
;;   (and (equal? (.name a) (.name b)) (ast:equal? (.type.name a) (.type.name b))))


;; (define-method (ast:equal? (a <trigger>) (b <trigger>))
;;   (and (equal? (.port.name a) (.port.name b))
;;        (equal? (.event.name a) (.event.name b))
;;        (ast:equal? (.formals a) (.formals b))))

(define-method (om:guard-equal? (lhs <guard>) (rhs <guard>))
  (ast:equal? (.expression lhs) (.expression rhs)))

(define-method (om:port-event-equal? a b)
  #f)

(define-method (om:remove-formals (o <trigger>))
  (clone o #:formals (make <formals>)))

(define-method (om:triggers-equal? a b)
  #f)

(define-method (om:triggers-equal? (a <on>) (b <on>))
  (ast:equal? (ast:trigger* a)
             (ast:trigger* b)))

(define-method (om:scope.name-equal? (a <named>) (b <named>))
  (ast:equal? (.name a) (.name b)))
