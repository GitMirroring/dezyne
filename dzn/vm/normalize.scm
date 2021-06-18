;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
                    (compound (make <initial-compound> #:elements elements #:location o)))
               (clone compound #:location (.location o))))
            ((ast:declarative? o)
             (let* ((elements (map normalize-compound (.elements o)))
                    (compound (make <declarative-compound> #:elements elements #:location o)))
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

(define* (set-blocking-reply-port o #:optional (port #f) (block? #f)) ;; FIXME: drop block? => #t
  (match o
    (($ <reply>) (if (not block?) o
                     (let ((port? (.port o))) (if (and port? (not (symbol? port?))) o (clone o #:port.name (.name port))))))
    (($ <blocking>) (clone o #:statement (set-blocking-reply-port (.statement o) port #t)))
    (($ <on>)
     (let* ((requires? (ast:requires? ((compose .port car ast:trigger*) o)))
            (block? (or block? requires?))
            (port (if port port
                      (if requires? (ast:provides-port (parent o <model>))
                          ((compose .port car ast:trigger*) o)))))
       (clone o #:statement (set-blocking-reply-port (.statement o) port block?))))
    (($ <guard>) (clone o #:statement (set-blocking-reply-port (.statement o) port block?)))
    (($ <compound>) (clone o #:elements (map (cut set-blocking-reply-port <> port block?) (ast:statement* o))))
    (($ <behaviour>) (clone o #:statement (set-blocking-reply-port (.statement o) port block?)
                            ;; FIXME #t??
                            #:functions (set-blocking-reply-port (.functions o) port #t)))
    (($ <component>) (clone o #:behaviour (set-blocking-reply-port (.behaviour o) (if (= 1 (length (ast:provides-port* o))) (car (ast:provides-port* o)) #f) block?)))
    (($ <system>) o)
    (($ <foreign>) o)
    (($ <interface>) o)
    ((? (is? <ast>)) (tree-map (cut set-blocking-reply-port <> port block?) o))
    (_ o)))

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

(define (transform-end-of-on o)
  (define (add-end-of-on o r)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (clone o #:elements (append (ast:statement* o) (if (parent o <blocking>) (cons (make <block> #:location o) r) r))))
      ((? ast:imperative?)
       (make <compound> #:elements (cons o (if (parent o <blocking>) (cons (make <block> #:location o) r) r)) #:location (.location o)))
      (($ <compound>)
       (clone o #:elements (map (cut add-end-of-on <> r) (ast:statement* o))))
      (($ <guard>)
       (clone o #:statement (add-end-of-on (.statement o) r)))
      (($ <blocking>)
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
  (define* (add-return o #:key (loc o))
    (match o
      (($ <compound>)
       (clone o #:elements (add-return (ast:statement* o) #:loc o)))
      ((statement ... ($ <return>)) o)
      ((statement ... t) (append o (list (make <return> #:location (.location (.parent t))))))
      ((statement ...) (append o (list (make <return> #:location (.location loc)))))))
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
    set-blocking-reply-port
    transform-end-of-on
    (annotate-otherwise)
    purge-data)
   root))
