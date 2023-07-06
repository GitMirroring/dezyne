;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021, 2022, 2023 Janneke  Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code language c++-exception-wrappers)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code legacy dzn)
  #:use-module (dzn code legacy code)
  #:use-module (dzn code language c++)
  #:use-module (dzn code scmackerel c++)
  #:use-module (dzn code util)
  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:use-module (dzn templates))

(define-templates-macro define-templates c++-exception-wrappers)
(include-from-path "dzn/templates/dzn.scm")
(include-from-path "dzn/templates/code.scm")
(include-from-path "dzn/templates/c++-exception-wrappers.scm")

(define-method (c++:type-ref (o <formal>))
  (if (not (eq? 'in (.direction o))) "&" ""))

(define-method (c++ew:ast-system* (o <root>))
  (filter (negate ast:imported?) (ast:system* o)))

(define-method (c++ew:trigger-type-base (o <trigger>))
  (let ((type ((compose .type .signature .event) o)))
    (match type
      (($ <bool>) "false")
      (($ <subint>) (.from (.range type)))
      (($ <enum>) (append (code:type-name type) (list (last (ast:field* type))))))))

(define-method (c++ew:typed-event? (o <trigger>))
  (if (not (is-a? ((compose .type .signature .event) o) <void>))
      o
      ""))

(define-method (c++ew:calling-context-type-name (o <ast>))
  (or (%calling-context)
      "undefined-calling-context-type"))

(define-method (c++ew:formals (o <event>))
  (ast:formal* ((compose .formals .signature) o)))

(define-method (c++ew:formals (o <trigger>))
  (ast:formal* (.formals o)))

(define-method (c++ew:formals (o <top>))
  (code:formal* o))

(define-method (c++ew:formal-names (o <trigger>))
  (map .name (ast:formal* o)))

(define-method (c++ew:port-event-to-trigger (o <port>) (e <event>))
  (make <trigger> #:port.name (.name o)
        #:event.name (.name e)
        #:formals (clone (.formals (.signature e)))))

(define-method (c++ew:port-to-in-trigger* (o <port>))
  (let* ((events (ast:in-event* o)))
    (map (cut c++ew:port-event-to-trigger o <>) events)))

(define-method (c++ew:port-to-out-trigger* (o <port>))
  (let* ((events (ast:out-event* o)))
    (map (cut c++ew:port-event-to-trigger o <>) events)))

(define-method (c++ew:port-type-upcase (o <port>))
  (let* ((type (ast:full-name (.type o)))
         (type (map string-upcase type)))
    (string-join type "_")))

(define %char-set:identifier (list->char-set '(#\_) char-set:letter+digit))
(define-method (c++ew:file-name-upcase (o <ast>))
  (string-map (lambda (c)
                (if (char-set-contains? %char-set:identifier c) c #\_))
              ((compose string-upcase code:file-name) o)))


;;;
;;; Entry point.
;;;

(define* (ast-> root #:key (dir ".") model)
  "Entry point."

  (let ((root (code:om root)))
    (let* ((generator (code:indenter (cute x:header root)))
           (base (basename (ast:source-file root) ".dzn"))
           (file-name (code:source-file-name base dir "_exception_forwarding.hh")))
      (code:dump root generator #:file-name file-name))))
