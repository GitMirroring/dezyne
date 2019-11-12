;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2016 Henk Katerberg <henk.katerberg@yahoo.com>
;;; Copyright © 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn c++03)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn misc)
  #:use-module (dzn command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn config)

  #:use-module (dzn ast)
  #:use-module (dzn dzn)
  #:use-module (dzn code)
  #:use-module (dzn glue)
  #:use-module (dzn c++)
  #:use-module (dzn templates)
  #:export (
            ast->
            c++03:enum-field-type
            c++03:enum-literal
            ))

(define-method (c++03:type-name o)
  (c++:type-name o))

(define-method (c++03:type-name (o <binding>))
  ((compose c++03:type-name .type (cut ast:lookup (parent o <model>) <>) injected-instance-name) o))

(define-method (c++03:type-name (o <enum>))
  (append (list "") (ast:full-name o) (list "type")))

(define-method (c++03:type-name (o <enum-literal>))
  (c++03:type-name (.type o)))

(define-method (c++03:type-name (o <enum-field>))
  (append (c++03:type-name (.type o)) (list (.field o))))

(define-method (c++03:type-name (o <event>))
  ((compose c++03:type-name .type .signature) o))

(define-method (c++03:type-name (o <var>))
  (warn c++03:type-name o '=> (c++03:type-name o)))

(define-method (c++03:type-name (o <variable>))
  (c++03:type-name (.type o)))


(define-method (c++03:enum-field-type (o <enum-field>))
  (cons "" (append (ast:full-name (.type o)) (list (.field o)))))

(define-method (c++03:enum-literal (o <enum-literal>))
  (cons "" (append (ast:full-name (.type o)) (list (.field o)))))

(define-templates-macro define-templates c++03)
(include "templates/dzn.scm")
(include "templates/code.scm")
(include "templates/c++.scm")
(include "templates/glue.scm")
(include "templates/c++03.scm")

(define (c++03:root-> root)
  (parameterize ((language "c++03")
                 (%x:header x:header)
                 (%x:source x:source)
                 (%x:glue-top-header x:glue-top-header)
                 (%x:glue-top-source x:glue-top-source)
                 (%x:main x:main))
    (c++:dump root)
    (code:dump-main root)
    (when (code:glue)
      (for-each c++:dump-glue (filter (conjoin (is? <system>) (negate ast:imported?)) (ast:model* root))))))

(define (ast-> ast)
  (let ((root (code:om ast)))
    (c++03:root-> root))
  "")
