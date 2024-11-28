;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019, 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn code language cs)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (scmackerel indent)

  #:use-module (dzn ast ast)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code scmackerel cs)
  #:use-module (dzn code util)
  #:use-module (dzn misc)
  #:export (<capture-variable>
            cs:capture-name
            cs:defer-equality*
            cs:defer-variable*
            cs:number-argument
            cs:out-ref))

;;;
;;; Ast.
;;;
(define-ast <capture-variable> (<variable>)
  (depth))


;;;
;;; Accessors.
;;;
(define-method (cs:out-ref (o <formal>) (name <string>))
  (cond ((ast:in? o) name)
        ((ast:out? o) (string-append "out " name))
        ((ast:inout? o) (string-append "ref " name))))

(define-method (cs:out-ref (o <formal>) (name <top>))
  (cs:out-ref o))

(define-method (cs:out-ref (o <formal>) (name <number>))
  (cs:out-ref o (number->string name)))

(define-method (cs:number-argument (o <formal>))
  (cs:out-ref o (code:number-argument o)))

(define-method (cs:out-ref (o <formal>))
  (cs:out-ref o (.name o)))

(define-method (cs:defer-variable* (o <defer>))
  (let* ((variables (ast:defer-variable* o))
         (depth (length (filter (is? <defer>) (ast:path o)))))
    (map (cute make <capture-variable> #:name <> #:type.name <> #:depth depth)
         (map .name variables)
         (map .type.name variables))))

(define-method (cs:defer-equality* (o <defer>))
  (filter (compose not (is? <extern>) .type) (cs:defer-variable* o)))

(define-method (cs:capture-name (o <variable>))
  (code:capture-name o))

(define-method (cs:capture-name (o <capture-variable>))
  (simple-format #f "~a~a" (code:capture-name o) (.depth o)))

(define-method (cs:model (o <root>))
  (let* ((models (ast:model** o))
         (models (filter (negate (disjoin (is? <type>)
                                          (is? <namespace>)
                                          ast:imported?))
                         models))
         (models (ast:topological-model-sort models))
         (models (map code:annotate-shells models)))
    models))


;;;
;;; Normalizations.
;;;
(define (cs:normalize ast)
  (parameterize ((%normalize:short-circuit? code:short-circuit?))
    ((compose
      code:annotate-shells
      add-reply-port
      normalize:event+illegals
      remove-otherwise
      code:add-calling-context)
     ast)))


;;;
;;; Entry point.
;;;
(define* (ast-> root #:key (dir ".") empty-files? model verbose?)
  "Entry point."

  (code:foreign-conflict? root)

  (parameterize ((%language "cs")
                 (%member-prefix "this.")
                 (%name-infix ".")
                 (%type-infix ".")
                 (%type-prefix "global::"))
    (let ((root (cs:normalize root)))
      (let ((generator (sm:indenter (cute print-code-ast root)))
            (file-name (code:root-file-name root dir ".cs")))
        (code:dump generator #:file-name file-name))

      (when model
        (let ((model (ast:get-model root model)))
          (when (is-a? model <component-model>)
            (let ((generator (sm:indenter (cute print-main-ast model)))
                  (file-name (code:source-file-name "main" dir ".cs")))
              (code:dump generator #:file-name file-name))))))))
