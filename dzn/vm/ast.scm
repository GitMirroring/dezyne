;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn vm ast)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn vm goops)
  #:use-module (dzn ast)
  #:use-module (dzn vm runtime)
  #:export (ast:acceptance*
            ast:statement
            ast:trigger-equal?
            ast:valued?)
  #:re-export (ast:async?
               ast:provides?
               ast:requires?
               ast:type))

(define-method (ast:acceptance* (o <acceptances>)) (.elements o))
(define-method (ast:acceptance* (o <compliance-error>)) ((compose ast:acceptance* .port-acceptance) o))

(define-method (ast:type (o <runtime:instance>))
  ((compose .type .ast) o))

(define-method (ast:statement (o <runtime:instance>))
  ((compose ast:statement ast:type) o))

(define-method (ast:statement (o <model>))
  ((compose .statement .behaviour) o))

(define-method (ast:statement (o <runtime:system>))
  #f)

(define-method (ast:trigger-equal? (a <trigger>) (b <trigger>))
  (and (equal? (.port.name a) (.port.name b))
       (equal? (.event.name a) (.event.name b))))

(define-method (ast:valued? (o <trigger>))
  (ast:valued-in-triggers))

(define-method (ast:async? (o <port>))
  (string-prefix? "dzn.async" (string-join ((compose ast:full-name .type) o) ".")))

(define-method (ast:async? (o <action>))
  (and=> (.port o) ast:async?))

(define-method (ast:async? (o <trigger>))
  (and=> (.port o) ast:async?))

(define-method (ast:provides? (o <runtime:port>))
  (ast:provides? (.ast o)))

(define-method (ast:provides? (o <instance>))
  #f)

(define-method (ast:requires? (o <runtime:port>))
  (ast:requires? (.ast o)))

(define-method (ast:requires? (o <instance>))
  #f)
