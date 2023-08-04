;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
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

  #:use-module (dzn ast goops)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast)
  #:use-module (dzn ast util)
  #:use-module (dzn misc)
  #:use-module (dzn vm goops)
  #:export (vm:normalize
            normalize:compounds))

(define* (normalize:compounds o #:key wrap-imperative?)
  "Remove externeous compound wrapping."
  (define (normalize-compound o)
    (cond ((is-a? o <model>)
           (tree-map normalize-compound o))
          ((is-a? o <behavior>)
           (tree-map normalize-compound o))
          ((is-a? o <functions>)
           (graft o #:elements (map normalize-compound (.elements o))))
          ((is-a? o <function>)
           (graft o #:statement (normalize-compound (.statement o))))
          ((and (is-a? o <imperative>)
                (is-a? (.parent o) <declarative>)
                wrap-imperative?)
           (graft (.parent o) (make <compound>
                                #:elements (list o)
                                #:location (.location o))))
          ((is-a? o <compound>)
           (cond
            ((is-a? (.parent o) <behavior>)
             (let* ((elements (map normalize-compound (.elements o)))
                    (location (.location o)))
               (graft (.parent o) (make <initial-compound>
                                    #:elements elements
                                    #:location location))))
            ((ast:declarative? o)
             (let* ((elements (map normalize-compound (.elements o)))
                    (location (.location o))
                    (compound (graft (.parent o) (make <declarative-compound>
                                                   #:elements elements
                                                   #:location location))))
               (cond ((and (= (length elements) 1)
                           (not wrap-imperative?))
                      (car elements))
                     (else
                      compound))))
            ((null? (.elements o))
             (graft (.parent o) (make <skip> #:location (.location o))))
            (else
             (let* ((elements (map normalize-compound (.elements o)))
                    (elements (filter
                               (conjoin (negate (is? <skip>))
                                        (disjoin (negate (is? <compound>))
                                                 (compose pair? .elements)))
                               elements)))
               (cond ((null? elements)
                      (graft (.parent o) (make <skip> #:location (.location o))))
                     ((and (= (length elements) 1)
                           (not wrap-imperative?))
                      (car elements))
                     (else
                      (graft o #:elements elements)))))))
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
                      (if requires? (ast:provides-port (ast:parent o <model>))
                          ((compose .port car ast:trigger*) o)))))
       (clone o #:statement (set-blocking-reply-port (.statement o) port block?))))
    (($ <guard>) (clone o #:statement (set-blocking-reply-port (.statement o) port block?)))
    (($ <compound>) (clone o #:elements (map (cut set-blocking-reply-port <> port block?) (ast:statement* o))))
    (($ <behavior>) (clone o #:statement (set-blocking-reply-port (.statement o) port block?)
                           ;; FIXME #t??
                           #:functions (set-blocking-reply-port (.functions o) port #t)))
    (($ <component>) (clone o #:behavior (set-blocking-reply-port (.behavior o) (if (= 1 (length (ast:provides-port* o))) (car (ast:provides-port* o)) #f) block?)))
    (($ <system>) o)
    (($ <foreign>) o)
    (($ <interface>) o)
    ((? (is? <ast>)) (tree-map (cut set-blocking-reply-port <> port block?) o))
    (_ o)))

(define* ((annotate-otherwise #:optional (statements '())) o) ;; FIXME *unspecified*
  (define (virgin-otherwise? x) (or (eq? x 'otherwise) (eq? x *unspecified*)))
  (match o
    (($ <interface>)
     (clone o #:behavior ((annotate-otherwise) (.behavior o))))
    (($ <component>)
     (clone o #:behavior ((annotate-otherwise) (.behavior o))))
    (($ <behavior>)
     (clone o #:statement ((annotate-otherwise) (.statement o))))
    (($ <system>)
     o)
    ((and ($ <guard>) (= .expression (and ($ <otherwise>) (= .value value)))) (=> failure)
     (if (or (not (virgin-otherwise? value)) (null? statements)) (failure)
         (clone o #:expression ((annotate-otherwise statements) (.expression o)))))
    (($ <otherwise>)
     (or (let* ((guards (filter (is? <guard>) statements))
                (value (not-or-guards guards)))
           (and value (clone o #:value value)))
         o))
    ((and ($ <compound>) (= .elements (statements ...)))
     (if (ast:imperative? o) o
         (clone o #:elements (map (annotate-otherwise statements) statements))))
    (($ <skip>) o)
    ((? (is? <ast>)) (tree-map (annotate-otherwise statements) o))
    (_ o)))

(define (transform-end-of-on o)
  (define (add-end-of-on o r)
    (match o
      ((and ($ <compound>) (? ast:imperative?))
       (let* ((location (.location o))
              (block (graft (.parent o) (make <block> #:location location)))
              (statements (ast:statement* o))
              (statements (filter (negate (is? <the-end>)) statements))
              (statements (append (ast:statement* o)
                                  (if (ast:parent o <blocking>) (cons block r) r))))
         (clone o #:elements statements)))
      ((? ast:imperative?)
       (let* ((location (.location o))
              (block (graft (.parent o) (make <block> #:location location)))
              (elements (cons o (if (ast:parent o <blocking>) (cons block r)
                                    r))))
         (graft (.parent o) (make <compound> #:elements elements
                                  #:location location))))
      (($ <compound>)
       (let* ((statements (ast:statement* o))
              (statements (filter (negate (is? <the-end>)) statements)))
         (clone o #:elements (map (cut add-end-of-on <> r) statements))))
      (($ <guard>)
       (clone o #:statement (add-end-of-on (.statement o) r)))
      (($ <blocking>)
       (clone o #:statement (add-end-of-on (.statement o) r)))
      (($ <declarative-illegal>)
       (graft (.parent o) (make <illegal>)))))

  (match o
    (($ <on>)
     (let* ((end-of-on (graft (.statement o) (make <end-of-on>
                                               #:location (.location o))))
            (statement (add-end-of-on (.statement o) (list end-of-on))))
       (clone o #:statement statement)))
    (($ <behavior>)
     (clone o #:statement (transform-end-of-on (.statement o))))
    (($ <interface>)
     (clone o #:behavior (transform-end-of-on (.behavior o))))
    (($ <component>)
     (clone o #:behavior (transform-end-of-on (.behavior o))))
    ((? (is? <ast>)) (tree-map transform-end-of-on o))
    (_ o)))


;;;
;;; Entry point: normalize.
;;;

(define (vm:normalize root)
  "Normalizations for the simulator: purge-data, add-explicit-temporaries, annotate-otherwise, transform-end-of-on, set-blocking-reply-port, add-function-return, normalize:compounds."
  ((compose
    (with-root (cut normalize:compounds <> #:wrap-imperative? #t))
    (with-root add-function-return)
    (with-root set-blocking-reply-port)
    (with-root transform-end-of-on)
    (with-root (annotate-otherwise))
    (with-root add-explicit-temporaries)
    (with-root purge-data))
   root))
