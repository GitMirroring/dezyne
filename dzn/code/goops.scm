;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2016, 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
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

(define-module (dzn code goops)
  #:use-module (srfi srfi-26)

  #:use-module (dzn ast)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast lookup)
  #:export (<action-reply>
            <port-pair>
            <shared-state>
            <shared-transition>
            <shared-value>
            .action
            .assign
            .other
            .prefix
            .skip
            .state
            code:shared-value*)
  #:re-export (.event.name
               .from
               .to
               .port
               .port.name
               .value
               ast:statement*))

;;;
;;; Ast extension.
;;;
(define-ast <port-pair> (<ast>)
  (port)
  (other))

(define-method (.port.name (o <port-pair>)) (.name (.port o)))
(define-method (.other.name (o <port-pair>)) (.name (.other o)))

(define-ast <action-reply> (<statement>)
  (action)
  (port.name)
  (event.name)
  (variable.name))

(define-method (.port (o <action-reply>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.event (o <action-reply>))
  (let* ((port-name (.port.name o))
         (port (.port o))
         (interface (if port (.type port)
                        (ast:parent o <interface>))))
    (ast:lookup interface (.event.name o))))

(define-method (.variable (o <action-reply>))
  (and=> (.variable.name o) (cute ast:lookup-variable o <>)))

(define-method (ast:type (o <action-reply>))
  ((compose ast:type .event) o))

(define-method (ast:in? (o <action-reply>))
  (and=> (.event o) ast:in?))

(define-method (ast:out? (o <action-reply>))
  (and=> (.event o) ast:out?))


;;;
;;; Shared-state.
;;;
(define-ast <shared-transition> (<ast>)
  (from)
  (prefix)
  (to)
  (skip #:init-value #f))

(define-ast <shared-state> (<ast>)
  (state)
  (assign))

(define-ast <shared-value> (<expression>)
  (value))


;;;
;;; Accessors
;;;
(define-method (code:shared-value* (o <shared-transition>))
  (ast:statement* (.prefix o)))

(define-method (ast:statement* (o <shared-state>))
  (ast:statement* (.assign o)))

(define-method (.event.name (o <assign>))
  (and=> (as (.expression o) <action>) .event.name))

(define-method (.event.name (o <variable>))
  (and=> (as (.expression o) <action>) .event.name))

(define-method (.port.name (o <assign>))
  (and=> (as (.expression o) <action>) .port.name))

(define-method (.port.name (o <variable>))
  (and=> (as (.expression o) <action>) .port.name))


;;;
;;; Utility.
;;;

(define-method (ast:equal? (a <shared-transition>) (b <shared-transition>))
  (and
   (equal? (.from a) (.from b))
   (equal? (.to a) (.to b))
   (ast:equal? (.prefix a) (.prefix b))))

(define-method (ast:equal? (a <shared-value>) (b <shared-value>))
  (ast:equal? (.value a) (.value b)))
