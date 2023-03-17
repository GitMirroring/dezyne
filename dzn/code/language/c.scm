;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015, 2017, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

(define-module (dzn code language c)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code goops)
  #:use-module (dzn code scmackerel c)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code util)
  #:use-module (dzn indent)
  #:use-module (dzn misc)
  #:export (c:base-type-name
            c:closure-name
            c:closure-triggers
            c:end-point->string
            c:event-slot-call-name
            c:enum*
            c:event-name
            c:ref
            c:type-name))

;;;
;;; Accessors.
;;;
(define-method (c:generate-source? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (disjoin (is? <interface>)
                          (is? <foreign>)
                          (is? <component>)
                          (is? <system>)))
        (ast:model* o)))

(define-method (c:ref (o <string>))
  (string-append "&" o))

(define-method (c:event-name o) ; <trigger> or <action>
  (string-append (.port.name o)
                 "->"
                 (code:event-name (.event o))))
(define-method (c:enum* (o <root>))
  (let* ((enums (code:enum* o))
         (models (filter (negate ast:imported?) (ast:model* o)))
         (interfaces (filter (is? <interface>) models))
         (public-enums (append-map code:public-enum* interfaces)))
    (append enums public-enums)))

(define-method (c:base-type-name (o <ast>))
  (string-join (ast:full-name o) "_"))

(define-method (c:type-name (o <ast>))
  (c:base-type-name o))

(define-method (c:type-name (o <foreign>))
  (string-append (c:base-type-name o) "_skel"))

(define-method (c:type-name (o <subint>))
  "int")

(define-method (c:type-name (o <data>))
  (.value o))

(define-method (c:type-name (o <extern>))
  (c:type-name (.value o)))

(define-method (c:signature-equal? (a <trigger>) (b <trigger>))
  (ast:equal? ((compose .signature .event) a)
              ((compose .signature .event) b)))

(define-method (c:event-slot-call-name (base <string>) (trigger <trigger>))
  (string-join
   (list "dzn" (code:direction trigger) base (code:event-slot-name trigger))
   "_"))

(define-method (c:closure-name (o <trigger>))
  (let* ((model (ast:parent o <model>))
         (model-name (c:type-name model))
         (formals (ast:formal* o))
         (types (map .type formals))
         (types (map code:type->string types)))
    (string-join (cons* "dzn" model-name "void" types) "_")))

(define-method (c:closure-triggers (o <component-model>))
  (let ((triggers (ast:requires-out-triggers o)))
    (delete-duplicates triggers c:signature-equal?)))

(define-method (c:end-point->string (o <end-point>))
  (let ((instance (.instance o)))
    (string-append (.name instance)
                   (if (not (is-a? (.type instance) <foreign>)) ""
                       ".base")
                   "."
                   (.port.name o))))


;;;
;;; Entry point.
;;;
(define* (ast-> root #:key (dir ".") model)
  "Entry point."

  (code:foreign-conflict? root)

  (parameterize ((%language "c")
                 (%member-prefix "self->")
                 (%name-infix "_")
                 (%type-infix "_")
                 (%type-prefix ""))
    (let ((root (code:om+determinism root)))
      (let ((generator (code:indenter (cute print-header-ast root)))
            (file-name (code:root-file-name root dir ".h")))
        (code:dump root generator #:file-name file-name))

      (when (c:generate-source? root)
        (let ((generator (code:indenter (cute print-code-ast root)))
              (file-name (code:root-file-name root dir ".c")))
          (code:dump root generator #:file-name file-name)))

      (when model
        (let ((model (ast:get-model root model)))
          (when (is-a? model <component-model>)
            (let ((generator (code:indenter (cute print-main-ast model)))
                  (file-name (code:source-file-name "main" dir ".c")))
              (code:dump root generator #:file-name file-name))))))))
