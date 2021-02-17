;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn code cs)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (dzn ast)
  #:use-module (dzn config)
  #:use-module (dzn command-line)
  #:use-module (dzn code)
  #:use-module (dzn code-util)
  #:use-module (dzn code dzn)
  #:use-module (dzn goops)
  #:use-module (dzn misc)
  #:use-module (dzn normalize)
  #:use-module (dzn templates))

(define-templates-macro define-templates cs)
(include-from-path "dzn/templates/dzn.scm")
(include-from-path "dzn/templates/code.scm")
(include-from-path "dzn/templates/cs.scm")

(define-method (mark-otherwise o)
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (clone (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
             #:parent (.parent o))
      o))

(define-method (cs:global-enum-definer (o <root>))
  (filter (conjoin (is? <enum>)
                   (compose (cut equal? (ast:source-file o) <>) (cut ast:source-file <>)))
          (ast:type* o)))

(define-method (cs:statement (o <compound>))
  (let ((elements (ast:statement* o)))
    (if (null? elements) (make <skip>)
        (map mark-otherwise elements))))

(define-method (cs:statement (o <on>))
  (.statement o))

(define-method (cs:statement (o <function>))
  (.statement o))

(define-method (cs:statement (o <guard>))
  (cond ((is-a? (.expression o) <otherwise>) (clone (make <otherwise-guard>
                                                      #:expression (.expression o)
                                                      #:statement (.statement o))
                                                    #:parent (.parent o)))
        ((ast:literal-true? (.expression o)) (.statement o))
        ((ast:literal-false? (.expression o)) '())
        (else o)))

(define-method (cs:statement (o <statement>))
  o)

(define (direction o)
  (match (.direction o)
    ('out "out")
    ('inout "ref")
    (_ "")))

(define-method (cs:direction (o <formal>))
  (direction o))

(define-method (cs:direction (o <argument>))
  (direction o))

(define-method (cs:formals (o <trigger>))
  (formals o))

(define-method (cs:formals (o <function>))
  (formals o))

(define-method (cs:formals (o <event>))
  (formals o))

(define (formals o)
  (let ((formals (ast:formal* o) )
        (calling-context (command-line:get 'calling-context #f)))
    (if calling-context
        (cons (clone (make <formal>
                       #:name "dzn_cc"
                       #:type.name (make <scope.name> #:ids '("*calling-context*"))
                       #:direction 'inout)
                     #:parent o)
              formals)
        formals)))

(define-method (cs:illegal-out-assign (o <ast>))
  (let ((on (parent o <on>)))
    (if on (filter ast:out? (cs:formals (car (ast:trigger* on))))
        (filter ast:out? (cs:formals (parent o <function>))))))

(define-method (cs:args o)
  (let ((args (ast:argument* o)))
    (if (not (command-line:get 'calling-context #f)) args
        (cons (make <formal>
                #:name "dzn_cc"
                #:type.name (make <scope.name> #:ids '("*calling-context*"))
                #:direction 'inout)
              args))))

(define (expression+formal->argument a f)
         (if (not (is-a? a <named>)) a
             (make <argument>
               #:name (.name a)
               #:type.name (.type.name f)
               #:direction (.direction f))))

(define-method (cs:arguments (o <call>))
  (map expression+formal->argument
       (cs:args o)
       (cs:formals (.function o))))

(define-method (cs:arguments (o <action>))
  (map expression+formal->argument
       (cs:args o)
       (cs:formals (.event o))))

(define-method (cs:arguments (o <trigger>))
  (cs:formals o))


(define-method (return-type (o <event>))
  ((compose .type .signature) o))

(define-method (return-type (o <trigger>))
  ((compose return-type .event) o))

(define-method (return-type (o <on>))
  ((compose return-type car .elements .triggers) o))

(define-method (return-type-if-valued (o <trigger>))
  (let ((rt (return-type o)))
    (if (is-a? rt <void>) '() rt)))

(define-method (cs:model (o <root>))
  (let* ((models (ast:model* o))
         (models (filter (negate (disjoin (is? <type>) (is? <namespace>)
                                          ast:imported?))
                         models))
         (models (ast:topological-model-sort models))
         (models (map dzn:annotate-shells models)))
    models))

(define-method (cs:formal-binding (o <on>))
  (filter (is? <formal-binding>) (cs:formals (car (ast:trigger* o)))))

(define-method (cs:formal-binding (o <blocking-compound>))
  (cs:formal-binding (parent o <on>)))

(define-method (out-ref-local (o <trigger>))
  (filter (negate ast:in?) (cs:formals o)))

(define-method (dzn-prefix (o <formal>))
  (if (ast:in? o) '() o))

(define-method (default-ref (o <formal>))
  (if (ast:inout? o) o '()))

(define-method (default-out (o <formal>))
  (if (ast:out? o) o '()))

(define-method (=expression (o <variable>))
  (let ((e (.expression o)))
    (if (and (is-a? e <literal>) (equal? "void" (.value e))) o
        e)))

(define (cs:function-return-type o)
  (let ((type (return-type o)))
    (if (is-a? type <void>) '()
        o)))

(define (cs:return-statement o)
 (let ((type (return-type o)))
   (if (is-a? type <void>) '()
       o)))

(define (cs:return-temporary-assign o)
  (let ((type (return-type o)))
    (if (is-a? type <void>) '()
        o)))

(define (cs:return-temporary o)
  (let ((type (return-type o)))
    (if (is-a? type <void>) '()
        o)))

(define (cs:non-primitive o)
  (if (or (is-a? (ast:type o) <enum>)
          (is-a? (ast:type o) <interface>)) o
          '()))

(define (cs:data o)
  (cond ((is-a? o <root>) (filter (is? <data>) (.elements o)))
        ((is-a? o <data>) o)
        (else '())))

(define (cs:om ast)
  ((compose
    add-reply-port
    triples:event-traversal
    (remove-otherwise)
    code:add-calling-context)
   ast))


;;;
;;; Entry points.
;;;

(define* (root-> root #:key (dir ".") main)
  "Entry point."

  (code-util:foreign-conflict? root)

  (let ((root (cs:om root)))
    (let ((generator (code-util:indenter (cute x:source root)))
          (file-name (code-util:root-file-name root dir ".cs")))
      (code-util:dump root generator #:file-name file-name))

    (when main
      (let ((model (ast:get-model root main)))
        (when (is-a? model <component-model>)
          (let ((generator (code-util:indenter (cute x:main model)))
                (file-name (code-util:file-name "main" dir ".cs")))
            (code-util:dump root generator #:file-name file-name)))))))

(define (ast-> ast)
  "XXX REMOVEME Legacy entry point"
  (let ((dir (command-line:get 'output "."))
        (main (command-line:get 'model #f)))
    (root-> ast #:dir dir #:main main)))
