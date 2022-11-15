;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
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

(define-module (dzn code language c++)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code)
  #:use-module (dzn code-util)
  #:use-module (dzn config)
  #:use-module (dzn indent)
  #:use-module (dzn misc)
  #:use-module (dzn templates)

  #:export (c++:capture-arguments
            c++:dzn-locator
            c++:enum->string
            c++:enum-field->string
            c++:enum-field-type
            c++:enum-literal
            c++:formal-type
            c++:model
            c++:string->enum
            c++:type-name
            c++:type-ref))

;;; ast accessors / template helpers

(define-method (c++:type-ref (o <formal>))
  (if (not (eq? 'in (.direction o))) "&" ""))

(define-method (c++:capture-arguments (o <trigger>))
  (map .name (filter (negate (disjoin ast:out? ast:inout?)) (code:formals o))))

(define-method (c++:formal-type (o <formal>)) o)
(define-method (c++:formal-type (o <port>))
  (code:formals (car (ast:event* o))))

(define (c++:pump-include o) (if (pair? (ast:port* (.behavior o))) "#include <dzn/pump.hh>" ""))

(define-method (c++:enum-field->string (o <enum>))
  (map (string->enum-field o) (ast:field* o) (iota (length (ast:field* o)))))
(define-method (c++:string->enum (o <model>))
  (filter (is? <enum>) (ast:type* o)))
(define-method (c++:string->enum (o <enum>))
  (map (string->enum-field o) (ast:field* o) (iota (length (ast:field* o)))))

(define-method (c++:enum->string (o <interface>))
  (filter (is? <enum>) (append (ast:type* (ast:parent o <root>))
                                (ast:type* o))))

(define-method (c++:type-name o)
  (code:type-name o))

(define-method (c++:type-name (o <enum>))
  (append (list "") (ast:full-name o) (list "type")))

(define-method (c++:type-name (o <enum-field>))
  (append (c++:type-name (.type o)) (list (.field o))))

(define-method (c++:type-name (o <enum-literal>))
  (c++:type-name (.type o)))

(define-method (c++:type-name (o <event>))
  ((compose c++:type-name .type .signature) o))

(define-method (c++:type-name (o <formal>))
  ((compose c++:type-name .type) o))

(define-method (c++:type-name (o <var>))
  (c++:type-name o))

(define-method (c++:type-name (o <variable>))
  (c++:type-name (.type o)))

(define-method (c++:enum-field-type (o <enum-field>))
  (append (c++:type-name (.type o)) (list (.field o))))

(define-method (c++:enum-literal (o <enum-literal>))
  (append (c++:type-name (.type o)) (list (.field o))))

(define-method (c++:model (o <root>))
  (let* ((models (ast:model* o))
         (models (filter (negate
                          (disjoin (is? <type>) (is? <namespace>)
                                   ast:imported?))
                      models))
         (models (ast:topological-model-sort models))
         (models (map code:annotate-shells models)))
    models))

(define-method (c++:dzn-locator (o <instance>))
  (let ((model (ast:parent o <model>)))
    (if (null? (code:injected-bindings model)) '()
        o)))

(define-templates-macro define-templates c++)
(include-from-path "dzn/templates/dzn.scm")
(include-from-path "dzn/templates/code.scm")
(include-from-path "dzn/templates/c++.scm")


;;;
;;; Entry point.
;;;

(define* (ast-> root #:key (dir ".") model)
  "Entry point."

  (code-util:foreign-conflict? root)

  (let ((root (code:om+determinism root)))
    (let ((generator (code-util:indenter (cute x:header root)))
          (file-name (code-util:root-file-name root dir ".hh")))
      (code-util:dump root generator #:file-name file-name))

    (when (code-util:generate-source? root)
      (let ((generator (code-util:indenter (cute x:source root)))
            (file-name (code-util:root-file-name root dir ".cc")))
        (code-util:dump root generator #:file-name file-name)))

    (when model
      (let ((model (ast:get-model root model)))
        (when (is-a? model <component-model>)
          (let ((generator (code-util:indenter (cute x:main model)))
                (file-name (code-util:file-name "main" dir ".cc")))
            (code-util:dump root generator #:file-name file-name)))))))
