;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code language json)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module ((oop goops)
                #:select (class-name class-of class-slots
                                     slot-definition-name slot-ref))

  #:use-module (dzn ast ast)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast)
  #:use-module (dzn code util)
  #:use-module (dzn command-line)
  #:use-module (dzn templates)

  #:export (json:get-fields
            json:elements
            json:value
            system-diagram))

(define-class <json:field> ()
  (name #:getter .name #:init-value #f #:init-keyword #:name)
  (value #:getter .value #:init-value #f #:init-keyword #:value))

(define-class <json:fieldlist> (<json:field>))

(define-method (json:get-fields (o <ast-node>))
  (let* ((names (map slot-definition-name (class-slots (class-of o))))
         (names (if (%locations?)
                    names
                    (filter (negate (cut eq? <> 'location)) names))))
    (filter-map (lambda (name)
                  (let* ((value (slot-ref o name))
                         (list? (or (null? value) (pair? value))))
                    (and value (make (if list? <json:fieldlist> <json:field>)
                                 #:name name #:value value))))
                names)))

(define (nodot o)
  (string-map (lambda (c) (if (eq? c #\.) #\_ c)) o))

(define-method (json:ast-name (o <top>))
  (let ((name (ast-name o)))
    (nodot name)))

(define-method (json:name (o <json:field>))
  (nodot (symbol->string (.name o))))

(define-method (json:get-fields (o <ast>))
  (json:get-fields (.node o)))


(define-method (json:elements (o <ast-list-node>))
  (map json:value (.elements o)))

(define-method (json:elements (o <ast-list>))
  (json:elements (.node o)))

(define (unspecified? x) (eq? x *unspecified*))

(define-method (json:value o)
  (match o
    ((? string?) (simple-format #f "~s" o))
    ((? symbol?) (json:value (symbol->string o)))
    ((? pair?) (map json:value o))
    ((? unspecified?) "null")
    (#f "false")
    (#t "true")
    (_ o)))

(define-method (json:value (o <json:field>))
  (json:value (.value o)))

(define-templates-macro define-templates json)
(include-from-path "dzn/templates/json.scm")


;;;
;;; Entry points.
;;;
(define* (system-diagram root #:key dir empty-files? model verbose?)
  (let* ((root (if (not model) root
                   (ast:filter-model root model)))
         (root (if (%locations?) root (remove-location root)))
         (file-name (code:root-file-name root dir ".json"))
         (generate (cute x:source (.node root))))
    (code:dump generate #:file-name file-name)))

(define* (ast-> ast #:key dir empty-files? model verbose?)
  (let ((model (ast:get-model ast model)))
    (system-diagram ast #:dir dir #:model model)))
