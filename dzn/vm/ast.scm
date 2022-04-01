;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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
            ast:label*
            ast:statement
            ast:trigger-equal?
            ast:valued?)
  #:re-export (.port
               ast:async?
               ast:external?
               ast:equal?
               ast:provides?
               ast:requires?
               ast:type))

(define-method (.port (o <trigger-return>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (ast:acceptance* (o <acceptances>)) (.elements o))
(define-method (ast:acceptance* (o <compliance-error>)) ((compose ast:acceptance* .port-acceptance) o))

(define-method (ast:label* (o <labels>)) (.elements o))
(define-method (ast:label* (o <end-of-trail>)) (ast:label* (.labels o)))

(define-method (ast:type (o <runtime:instance>))
  ((compose .type .ast) o))

(define-method (ast:statement (o <runtime:instance>))
  ((compose ast:statement ast:type) o))

(define-method (ast:statement (o <model>))
  ((compose .statement .behavior) o))

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

(define-method (ast:async? (o <runtime:port>))
  (ast:async? (.ast o)))

(define-method (ast:blocking? (o <runtime:port>))
  (ast:blocking? (.ast o)))

(define-method (ast:provides? (o <instance>))
  #f)

(define-method (ast:provides? (o <runtime:port>))
  (ast:provides? (.ast o)))

(define-method (ast:provides? (o <runtime:instance>))
  #f)

(define-method (ast:requires? (o <instance>))
  #f)

(define-method (ast:requires? (o <runtime:port>))
  (ast:requires? (.ast o)))

(define-method (ast:requires? (o <runtime:instance>))
  #f)

(define-method (ast:external? (o <instance>))
  #f)

(define-method (ast:external? (o <runtime:port>))
  (ast:external? (.ast o)))

(define-method (ast:external? (o <runtime:instance>))
  #f)

(define-method (ast:equal? (a <end-of-trail>) (b <end-of-trail>))
  (ast:equal? (.labels a) (.labels b)))
