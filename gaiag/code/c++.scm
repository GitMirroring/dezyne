;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (gaiag code c++)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)

  #:use-module (gaiag misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag config)

  #:use-module (gaiag command-line)
  #:use-module (gaiag code dzn)
  #:use-module (gaiag code)
  #:use-module (gaiag code-util)
  #:use-module (gaiag indent)

  #:use-module (gaiag ast)

  #:use-module (gaiag templates)

  #:export (c++:argument_n
            c++:capture-arguments
            c++:enum->string
            c++:enum-literal
            c++:type-name
            c++:enum-field-type
            c++:enum-field->string
            c++:model
            c++:name
            c++:optional-type
            c++:string->enum
            c++:type-ref))

;;; ast accessors / template helpers

(define-method (c++:type-ref (o <formal>))
  (if (not (eq? 'in (.direction o))) "&" ""))

(define-method (c++:name (o <binding>))  ;; FIXME
  (injected-instance-name o))

(define-method (c++:capture-arguments (o <trigger>))
  (map .name (filter (negate (disjoin ast:out? ast:inout?)) (code:formals o))))

(define-method (c++:formal-type (o <formal>)) o)
(define-method (c++:formal-type (o <port>)) ((compose ast:formal* car ast:event*) o))

(define (c++:pump-include o) (if (pair? (ast:port* (.behaviour o))) "#include <dzn/pump.hh>" ""))

(define-method (c++:enum-field->string (o <enum>))
  (map (symbol->enum-field o) (ast:field* o) (iota (length (ast:field* o)))))
(define-method (c++:string->enum (o <model>))
  (filter (is? <enum>) (ast:type* o)))
(define-method (c++:string->enum (o <enum>))
  (map (symbol->enum-field o) (ast:field* o) (iota (length (ast:field* o)))))

(define-method (c++:enum->string (o <interface>))
  (filter (is? <enum>) (append (ast:type* (parent o <root>))
                                (ast:type* o))))

(define-method (c++:argument_n (o <trigger>))
  (map
   (lambda (f i) (clone f #:name (string-append "_"  (number->string i))))
   (code:formals o)
   (iota (length (code:formals o)) 1 1)))

(define-method (c++:optional-type (o <trigger>))
  (let ((type (ast:type o)))
    (if (is-a? type <void>) '() type)))

(define-method (c++:type-name o)        ; MORTAL SIN HERE!!?
  (let* ((type (or (as o <model>) (as o <type>) (ast:type o))))
    (map dzn:->string
         (match type
           (($ <enum>) (c++:type-name type))
           (($ <extern>) (list (.value type)))
           ((or ($ <bool>) ($ <int>) ($ <void>)) (code:scope+name type))
           (_ (c++:type-name type))))))

(define-method (c++:type-name o)
  (code:type-name o))

(define-method (c++:type-name (o <binding>))
  ((compose c++:type-name .type (cut ast:lookup (parent o <model>) <>) injected-instance-name) o))

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
                          (disjoin (is? <type>) (is? <namespace>) ast:async?
                                   (conjoin ast:imported?
                                            (negate (is? <foreign>)))))
                      models))
         (models (ast:topological-model-sort models))
         (models (map dzn:annotate-shells models)))
    models))

(define-templates-macro define-templates c++)
(include-from-path "gaiag/templates/dzn.scm")
(include-from-path "gaiag/templates/code.scm")
(include-from-path "gaiag/templates/c++.scm")


;;;
;;; Entry points.
;;;

(define* (root-> root #:key (dir ".") main)
  "Entry point."

  (code-util:foreign-conflict? root)

  (let ((root (code:om root)))
    (let ((generator (code-util:indenter (cute x:header root)))
          (file-name (code-util:root-file-name root dir ".hh")))
      (code-util:dump root generator #:file-name file-name))

    (when (code-util:generate-source? root)
      (let ((generator (code-util:indenter (cute x:source root)))
            (file-name (code-util:root-file-name root dir ".cc")))
        (code-util:dump root generator #:file-name file-name)))

    (when main
      (let ((model (ast:get-model root main)))
        (when (is-a? model <component-model>)
          (let ((generator (code-util:indenter (cute x:main model)))
                (file-name (code-util:file-name "main" dir ".cc")))
            (code-util:dump root generator #:file-name file-name)))))))

(define (ast-> ast)
  "XXX REMOVEME Legacy entry point"
  (let ((dir (command-line:get 'output "."))
        (main (command-line:get 'model #f)))
    (root-> ast #:dir dir #:main main)))
