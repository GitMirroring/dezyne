;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019, 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015, 2017, 2021, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

  #:use-module (scmackerel indent)

  #:use-module (dzn ast ast)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code ast)
  #:use-module (dzn code scmackerel c)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code util)
  #:use-module (dzn misc)
  #:export (c:base-type-name
            c:closure-name
            c:closure-triggers
            c:defer-arguments-name
            c:defer-name
            c:defer-predicate-name
            c:defer*
            c:end-point->string
            c:event-slot-call-name
            c:enum*
            c:event-name
            c:formal-type-name
            c:ref
            c:type-name))

;;;
;;; Accessors.
;;;
(define-method (c:generate-source? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (disjoin (is? <enum>)
                          (is? <interface>)
                          (is? <foreign>)
                          (is? <component>)
                          (is? <system>)))
        (ast:top** o)))

(define-method (c:ref (o <string>))
  (string-append "&" o))

(define-method (c:event-name o) ; <trigger> or <action>
  (string-append (.port.name o)
                 "->"
                 (code:event-name (.event o))))
(define-method (c:enum* (o <root>))
  (let* ((enums (code:enum* o))
         (models (filter (negate ast:imported?) (ast:model** o)))
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

(define-method (c:formal-type-name (o <formal>))
  (let ((pointer (if (ast:out? o) "*" ""))
        (type (.type o)))
    (string-append (c:type-name type) pointer)))

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

(define-method (c:defer* (o <model>))
  (let ((behavior (.behavior o)))
    (c:defer* behavior)))

(define-method (c:defer* (o <foreign>))
  '())

(define-method (c:defer* (o <behavior>))
  (let* ((statement (.statement o))
         (functions (ast:function* o))
         (statements (cons statement (map .statement functions))))
    (append-map
     (cute tree-collect-filter (disjoin (is? <statement>)
                                        (is? <functions>)
                                        (is? <function>))
           (is? <defer>)
           <>)
     statements)))

(define-method (c:defer* (o <ast>))
  (c:defer* (ast:parent <behavior> o)))

(define-method (c:defer-arguments-name (o <model>))
  (string-append "dzn_defer_arguments_" (c:type-name o)))

(define-method (c:defer-arguments-name (o <ast>))
  (c:defer-arguments-name (ast:parent o <model>)))

(define-method (c:defer-name (o <defer>))
  (let* ((model (ast:parent o <model>))
         (model-name (c:type-name model))
         (defers (c:defer* model))
         (index (list-index (cute ast:eq? <> o) defers)))
    (simple-format #f "dzn_defer~a_~a" index model-name)))

(define-method (c:defer-predicate-name (o <defer>))
  (string-append (c:defer-name o) "_predicate"))


;;;
;;; Entry point.
;;;
(define* (ast-> root #:key (dir ".") empty-files? model verbose?)
  "Entry point."

  (code:foreign-conflict? root)

  (parameterize ((%language "c")
                 (%member-prefix "self->")
                 (%name-infix "_")
                 (%type-infix "_")
                 (%type-prefix ""))
    (let ((root (code:normalize root)))
      (let ((generator (sm:indenter (cute print-header-ast root)))
            (file-name (code:root-file-name root dir ".h")))
        (code:dump generator #:file-name file-name))

      (when (c:generate-source? root)
        (let ((generator (sm:indenter (cute print-code-ast root)))
              (file-name (code:root-file-name root dir ".c")))
          (code:dump generator #:file-name file-name)))

      (when model
        (let ((model (ast:get-model root model)))
          (when (is-a? model <component-model>)
            (let ((generator (sm:indenter (cute print-main-ast model)))
                  (file-name (code:source-file-name "main" dir ".c")))
              (code:dump generator #:file-name file-name))))))))
