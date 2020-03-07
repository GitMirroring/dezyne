;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn vm normalize)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (dzn misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn vm goops)
  #:use-module (dzn normalize)
  #:use-module (dzn ast)
  #:export (vm:normalize))

(define-method (normalize-compounds (o <root>))
  (define (normalize-compound o)
    (cond ((is-a? o <model>)
           (tree-map normalize-compound o))
          ((is-a? o <behaviour>)
           (tree-map normalize-compound o))
          ((is-a? o <compound>)
           (cond
            ((is-a? (.parent o) <behaviour>)
             (let* ((elements (map normalize-compound (.elements o)))
                    (compound (make <initial-compound> #:elements elements)))
               (clone compound #:location (.location o))))
            ((ast:declarative? o)
             (let* ((elements (map normalize-compound (.elements o)))
                    (compound (make <declarative-compound> #:elements elements)))
               (clone compound #:location (.location o))))
            ((null? (.elements o))
             (let ((skip (make <skip>)))
               (clone skip #:location (.location o))))
            (else o)))
          ((is-a? o <declarative>)
           (tree-map normalize-compound o))
          ((is-a? o <namespace>)
           (tree-map normalize-compound o))
          (else
           o)))
  (tree-map normalize-compound o))

(define* ((annotate-otherwise #:optional (statements '())) o) ;; FIXME *unspecified*
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*)))
  (match o
    ((and ($ <guard>) (= .expression (and ($ <otherwise>) (= .value value)))) (=> failure)
     (if (or (not (virgin-otherwise? value)) (null? statements)) (failure)
         (clone o #:expression ((annotate-otherwise statements) (.expression o)))))
    (($ <otherwise>)
     (or (let* ((guards (filter (is? <guard>) statements))
                (value (guards-not-or guards)))
           (and value (clone o #:value value)))
         o))
    ((and ($ <compound>) (= .elements (statements ...)))
     (clone o #:elements (map (annotate-otherwise statements) statements)))
    (($ <skip>) o)
    ((? (is? <ast>)) (tree-map (annotate-otherwise statements) o))
    (_ o)))

(define* ((transform-action #:optional model) o)
  (define (component? x) (is-a? model <component>))

  (define (system-port-event? trigger)
    ;; instance-path
    ;; port-name

    (and (ast:provides? (.port trigger))
         (ast:out? (.event trigger))))

  (define (add-flush o f)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (clone o #:elements (append (ast:statement* o) f)))
      ((? ast:imperative?)
       (make <compound> #:elements (cons o f) #:location (.location o)))
      (($ <compound>)
       (clone o #:elements (map (cut add-flush <> f) (ast:statement* o))))
      (($ <guard>) (clone o #:statement (add-flush (.statement o) f)))))

  (match o
    ((and ($ <on>) (= ast:trigger* triggers) (= .statement statement))
     (let* ((statement ((transform-action model) statement))
            (actions (tree-collect (is? <action>) statement))
            (trigger ((compose car ast:trigger*) o))
            (model (parent o <model>))
            (statement (if (or (is-a? model <interface>)
                               (ast:out? (.event trigger))
                               (is-a? (.event trigger) <modeling-event>)) statement
                           (add-flush statement (list (clone (make <flush> #:location (.location o)) #:parent statement))))))
       (clone o #:statement statement)))

    (($ <interface>)
     (clone o #:behaviour ((transform-action o) (.behaviour o))))

    (($ <component>)
     (clone o #:behaviour ((transform-action o) (.behaviour o))))

    ((? (is? <ast>)) (tree-map (transform-action model) o))
    (_ o)))

(define (transform-end-of-on o)
  (define (add-end-of-on o r)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (clone o #:elements (append (ast:statement* o) r)))
      ((? ast:imperative?)
       (make <compound> #:elements (cons o r) #:location (.location o)))
      (($ <compound>)
       (clone o #:elements (map (cut add-end-of-on <> r) (ast:statement* o))))
      (($ <guard>)
       (clone o #:statement (add-end-of-on (.statement o) r)))))

  (match o
    (($ <on>)
     (let* ((end-of-on (make <end-of-on> #:location (.location o)))
            (end-of-on (clone end-of-on #:parent (.statement o)))
            (statement (add-end-of-on (.statement o) (list end-of-on))))
       (clone o #:statement statement)))
    (($ <behaviour>)
     (clone o #:statement (transform-end-of-on (.statement o))))
    (($ <interface>)
     (clone o #:behaviour (transform-end-of-on (.behaviour o))))
    (($ <component>)
     (clone o #:behaviour (transform-end-of-on (.behaviour o))))
    ((? (is? <ast>)) (tree-map transform-end-of-on o))
    (_ o)))

(define (add-function-return o)
  (define (add-return o)
    (match o
      (($ <compound>)
       (clone o #:elements (add-return (ast:statement* o))))
      ((statement ... ($ <return>)) o)
      ((statement ...) (append o (list (make <return>))))))
  (match o
    (($ <interface>)
     (clone o #:behaviour (add-function-return (.behaviour o))))
    (($ <component>)
     (clone o #:behaviour (add-function-return (.behaviour o))))
    (($ <behaviour>)
     (clone o #:functions (add-function-return (.functions o))))
    (($ <functions>)
     (clone o #:elements (map add-function-return (ast:function* o))))
    (($ <function>)
     (clone o #:statement (add-return (.statement o))))
    ((? (is? <ast>)) (tree-map add-function-return o))
    (_ o)))


;;;
;;; Entry point: normalize.
;;;

(define (vm:normalize root)
  ((compose
    normalize-compounds
    add-function-return
    transform-end-of-on
    (transform-action)
    (annotate-otherwise)
    purge-data)
   root))
