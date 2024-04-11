;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2022, 2024 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn code ast)
  #:use-module (srfi srfi-26)

  #:use-module (dzn ast)
  #:use-module (dzn ast ast)
  #:use-module (dzn ast lookup)
  #:export (.action
            .other))

;;;
;;; Ast extension.
;;;
(define-ast <port-pair> (<ast>)
  (port)
  (other))

(define-method (.port.name (o <port-pair>)) (.name (.port o)))

(define-ast <action-reply> (<statement>)
  (action)
  (variable.name))

(define-method (.port.name (o <action-reply>))
  (.port.name (.action o)))

(define-method (.event.name (o <action-reply>))
  (.event.name (.action o)))

(define-method (.port (o <action-reply>))
  (.port (.action o)))

(define-method (.event (o <action-reply>))
  (.event (.action o)))

(define-method (.variable (o <action-reply>))
  (and=> (.variable.name o) (cute ast:lookup-variable o <>)))

(define-method (ast:type (o <action-reply>))
  ((compose ast:type .event) o))

(define-method (ast:in? (o <action-reply>))
  (and=> (.event o) ast:in?))

(define-method (ast:out? (o <action-reply>))
  (and=> (.event o) ast:out?))
