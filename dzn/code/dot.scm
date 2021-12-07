;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code dot)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn goops)
  #:use-module (dzn misc)
  #:use-module (dzn templates)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm runtime)
  #:export (dependency-diagram
            system-diagram))

;;; Commentary:
;;;
;;; Generate  dependency and system diagram in DOT.
;;;
;;; Code:

;;;
;;; System diagram.
;;;
(define-method (dot:connection* (o <runtime:system>))
  (let ((ports (filter (conjoin (is? <runtime:port>)
                                (negate ast:async?)
                                ast:requires?
                                (negate runtime:boundary-port?)
                                (disjoin (negate (compose runtime:boundary-port? runtime:other-port))
                                         (compose (cute and=> <> (compose (is? <runtime:foreign>) .container))
                                                  runtime:other-port))
                                (disjoin (compose (is? <runtime:component>) .container)
                                         (compose (is? <runtime:foreign>) .container)))
                       (%instances))))
    ports))

(define-method (dot:provides-port* (o <runtime:instance>))
  (filter (conjoin (is? <runtime:port>)
                   ast:provides?
                   (compose (cute eq? <> (%sut)) .container))
          (%instances)))

(define-method (dot:requires-port* (o <runtime:instance>))
  (filter (conjoin (is? <runtime:port>)
                   ast:requires?
                   (negate ast:async?)
                   (compose (cute eq? <> (%sut)) .container))
          (%instances)))

(define-method (dot:headlabel (o <runtime:port>))
  (let ((other-port (runtime:other-port o)))
    (if (not other-port) "headlabel=\"*\""
        other-port)))

(define-method (dot:taillabel (o <runtime:port>))
  o)

(define-method (dot:connection-instance (o <runtime:port>))
  (let* ((container (.container o))
         (container
          (if (and (is-a? (%sut) <runtime:system>)
                   (eq? container (%sut)))
              (.container (runtime:other-port o))
              container)))
    (if (not container) "\"*unbound*\""
        container)))

(define-method (dot:other-connection-instance (o <runtime:port>))
  (let ((other-port (runtime:other-port o)))
    (if (not other-port) "\"*unbound*\""
        (.container other-port))))

(define-method (dot:instance* (o <runtime:system>))
  (filter (conjoin (compose (cute eq? <> o) .container)
                   (negate (is? <runtime:port>)))
          (%instances)))

(define-method (dot:instance* (o <runtime:port>))
  (if (runtime:boundary-port? o) o
      (.container o)))


;;;
;;; Dependency diagram.
;;;
(define-method (dot:dependent (o <root>))
  (ast:model* o))

(define-method (dot:dependency (o <component-model>))
  (ast:port* o))

(define-method (dot:parent-name (o <instance>))
  (ast:dotted-name (parent o <model>)))


;;;
;;; Common.
;;;
(define-method (dot:instance-type-name (o <instance>))
  (ast:dotted-name (.type o)))

(define-method (dot:instance-type-name (o <runtime:instance>))
  (dot:instance-type-name (.ast o)))

(define-method (dot:instance-name (o <runtime:instance>))
  (last (runtime:instance->path o)))

(define-templates-macro define-templates dot)
(include-from-path "dzn/templates/dot.scm")


;;;
;;; Entry points.
;;;
(define* (dependency-diagram root #:key dir model)
  (x:source-dependent root))

(define* (system-diagram root #:key dir model)
  (parameterize ((%sut (runtime:get-sut root (ast:get-model root (ast:dotted-name model)))))
    (parameterize ((%instances (runtime:create-instances (%sut))))
      (x:source-sut (%sut)))))

(define* (ast-> ast #:key dir model)
  (system-diagram ast #:model model))
