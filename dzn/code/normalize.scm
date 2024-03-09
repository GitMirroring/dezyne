;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code normalize)
  #:use-module (srfi srfi-1)

  #:use-module (ice-9 match)

  #:use-module (dzn ast ast)
  #:use-module (dzn tree util)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn misc)

  #:export (reply->return))

(define-method (reply->return (o <root>))
  "Tranform reply into return + side-effects: local or member variable,
assignment, blocking release."
  (define (compound-reply?)
    (conjoin (is? <compound>) has-reply?))

  (define (has-reply? o)
    (find (is? <reply>) (ast:statement* o)))

  (define (single-reply?)
    (conjoin (is? <reply>) (compose not (is? <compound>) tree:parent)))

  (define (statement:reply->return o)
    (make <return>
      #:expression (.expression o)
      #:port.name (.port.name o)))

  (define (reply->variable o)
    (cond ((and (is-a? o <reply>)
                (is-a? (ast:type (.expression o)) <void>))
           #f)
          ((not (is-a? o <reply>))
           o)
          (else
           (let* ((type (ast:type o))
                  (local-type? (eq? (tree:ancestor type <model>)
                                    (tree:ancestor o <model>)))
                  (type-name
                   (cond
                    ((is-a? type <subint>) (.name (ast:type (make <int>))))
                    (local-type? (.name type))
                    (else (ast:dotted-name type)))))
             (make <variable>
               #:name (code:reply-var type)
               #:type.name type-name #:expression (.expression o))))))

  (define (compound:reply->return o)
    (let ((statements (ast:statement* o)))
      (match statements
        ((statements ... (and ($ <reply>) reply))
         (clone o #:elements (append statements
                                     (list (make <return>
                                             #:expression (.expression reply)
                                             #:port.name (.port.name reply))))))
        (_
         (let* ((reply (has-reply? o))
                (type (ast:type reply))
                (expression (if (is-a? type <void>) (.expression reply)
                                (make <reference> #:name (code:reply-var type)))))
           (clone o #:elements (append (filter-map reply->variable statements)
                                       (list (make <return>
                                               #:expression expression
                                               #:port.name (.port.name reply))))))))))
  (tree:transform
   o
   `((,(single-reply?) . ,statement:reply->return)
     (,(compound-reply?) . ,compound:reply->return))))
