;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag list util)
  :use-module (srfi srfi-1)

  :use-module (system foreign)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (gaiag list match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (language dezyne location)
  :use-module (gaiag annotate)

  :use-module (gaiag gaiag)
  :use-module (gaiag reader)
  :use-module (gaiag misc)
  :use-module (gaiag list om)
  :use-module (gaiag list ast)

  :export (
           ast-name
           collect
           goops:clone
           om->list
           om2list
           om:<
           om:equal?
           om:guard-equal?
           om:map
           om:triggers-equal?
           ))

(define om->list identity)
(define om2list identity)
(define goops:clone identity)

(define (ast-name o)
  (and (pair? o) (car o)))

(define (om:map f o)
  (match o
    ((? (is? <ast-list>)) (rsp o (cons (car o) (map f (.elements o)))))
    ((h t ...) (rsp o (map f o)))
    (_ o)))

(define (om:guard-equal? lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
   (equal? (.expression lhs) (.expression rhs))))

;; compare
(define (remove-arguments o)
  (match o
    (('trigger p e arguments) (list 'trigger p e))
    (_ o)))

(define (om:triggers-equal? a b)
  (and (is-a? a <on>) (is-a? b <on>)
   (equal? (.triggers a) (.triggers b))))

(define (om:< a b)
  (match (cons a b)
    ((($ <guard> ea sa) . ($ <on> tb sb)) #t)
    ((($ <on> ta sa) . ($ <guard> eb sb)) #f)

    ((($ <guard> ea sa) . ($ <guard> eb sb)) (om:< ea eb))
    ((($ <on> ta sa) . ($ <on> tb sb)) (om:< ta tb))

    ((($ <expression> va) . ($ <otherwise> vb)) #t)
    ((($ <otherwise> va) . ($ <expression> vb)) #f)
    ((($ <expression> va) . ($ <expression> vb))
     (om:< (om->list va) (om->list vb)))

    ((($ <triggers> ta) . ($ <triggers> tb))
     (om:< (stable-sort ta om:<) (stable-sort tb om:<)))

    ((() . ()) #f)
    ((() . (hb tb ...)) #t)
    (((ha ta ...) . ()) #f)
    (((ha ta ...) . (hb tb ...))
     (cond
      ((and (not (om:< (car a) (car b)))
            (not (om:< (car b) (car a))))
       (om:< (cdr a) (cdr b)))
      (else (om:< (car a) (car b)))))
    (((ha ta ...) . _) #f)
    ((_ . (hb tb ...)) #t)
    (((? symbol?) . (? symbol?)) (symbol< a b))
    (((? symbol?) . (? boolean?)) #f)
    (((? boolean?) . (? symbol?)) #t)
    ((#t . #t) #f)
    ((#f . #f) #f)
    ((#f . #t) #t)
    ((#t . #f) #f)

    (_ (< a b))))

(define (om:equal? a b)
  (match (cons a b)
    (((? (is? <expression>)) . (? (is? <expression>))) (equal? (.value a) (.value b)))
    (_ (equal? a b))))
