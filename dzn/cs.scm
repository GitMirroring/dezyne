;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn cs)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (dzn ast)
  #:use-module (dzn config)
  #:use-module (dzn command-line)
  #:use-module (dzn code)
  #:use-module (dzn dzn)
  #:use-module (dzn goops)
  #:use-module (dzn misc)
  #:use-module (dzn normalize)
  #:use-module (dzn templates))

(define-templates-macro define-templates cs)
(include "templates/dzn.scm")
(include "templates/code.scm")
(include "templates/cs.scm")

(define-method (mark-otherwise o)
  (if (and (is-a? o <guard>) (is-a? (.expression o) <otherwise>))
      (clone (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
             #:parent (.parent o))
      o))

(define-method (cs:global-enum-definer (o <root>))
  (filter (conjoin (is? <enum>)
                   (compose (cut equal? (ast:source-file o) <>) (cut ast:source-file <>)))
          (ast:type* o)))

(define-method (cs:delegate-formal-type (o <event>))
  (let ((formals (ast:formal* o)))
    (append (map (lambda (f) (if (ast:out? f) f
                                 (.type f))) formals)
            (if (ast:typed? o) `(,(ast:type o)) '()))))

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
    ("out" "out")
    ("inout" "ref")
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
                       #:type.name (make <scope.name> #:name "*calling-context*")
                       #:direction "inout")
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
                #:type.name (make <scope.name> #:name "*calling-context*")
                #:direction "inout")
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
  (topological-sort
   (map dzn:annotate-shells
        ;; cs needs async!
        (filter (negate (disjoin (is? <data>) (is? <type>) (is? <namespace>) ;; dzn-async?
                                 ast:imported?))
                (ast:model* o)))))

(define (cs:om ast) ;;TODO, replace me with code:om when (binding-into-blocking) is removed
  ((compose
    (lambda (o) (if (gdzn:command-line:get 'debug) (display (ast->dzn o) (current-error-port))) o)
    add-reply-port
    triples:event-traversal
    (remove-otherwise)
    code:add-calling-context)
   ast))

(define (ast-> ast)
  (parameterize ((language "cs")
                 (%x:header x:header)
                 (%x:source x:source)
                 (%x:main x:main))
    (let ((ast (cs:om ast)))
      (code:root-> ast))))
