;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018, 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2019, 2020, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn ast util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module ((oop goops)
                #:select (class-slots slot-definition-name slot-ref))

  #:use-module (dzn ast accessor)
  #:use-module (dzn tree context)
  #:use-module (dzn goops goops)
  #:use-module (dzn tree util)
  #:use-module (dzn ast ast)
  #:use-module (dzn goops util)
  #:use-module (dzn misc)

  #:export (ast-name
            ast:name-keyword+child*
            tree:shallow-filter
            tree:shallow-map)
  #:re-export (tree:ancestor
               tree:parent))

;;;
;;; Ast utilities.
;;;
(define-method (ast-name (o <class>))
  (let* ((name (symbol->string (class-name o)))
         (m (string-match "^<(.*)>$" name)))
    (match:substring m 1)))

(define-method (ast-name (o <top>))
  (ast-name (class-of o)))

(define-method (ast:name-keyword+child* (o <object>))
  (let ((keyword-values (keyword+child* o))
        (name-fields '(#:elements
                       #:event.name
                       #:field
                       #:function.name
                       #:instance.name
                       #:name
                       #:port.name
                       #:type.name
                       #:variable.name)))
    (filter (compose (cute memq <> name-fields) car) keyword-values)))


;;;
;;; Tree overrides.
;;;
(define-method (tree:ancestor (o <bool>) (type <class>))
  (and (tree:context o) (next-method)))

(define-method (tree:ancestor (o <int>) (type <class>))
  (and (tree:context o) (next-method)))

(define-method (tree:ancestor (o <void>) (type <class>))
  (and (tree:context o) (next-method)))

(define-method (tree:ancestor (o <ast>) (predicate <procedure>))
  (and=> (tree:parent (tree:context o) predicate)
         .ast))


;;;
;;; Tree utilities.
;;;
(define-method (tree:shallow-map f (o <object>))
  (let* ((class (class-of o))
         (actual-keyword-values (keyword+child* o))
         (keyword-values (map (match-lambda
                                ((keyword (values ...))
                                 (list keyword (map f values)))
                                ((keyword value)
                                 (list keyword (f value))))
                              actual-keyword-values))
         (keyword-values (apply append keyword-values)))
    (if (equal? keyword-values actual-keyword-values) o
        (apply make class keyword-values))))

(define-method (tree:shallow-map f (o <top>)) o)

(define-method (tree:shallow-filter f (o <ast>))
  (and (f o) o))

(define-method (tree:shallow-filter f (o <ast-list>))
  (clone o #:elements (map (cute tree:shallow-filter f <>) (filter f (.elements o)))))
