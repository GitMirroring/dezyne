;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2020, 2021, 2022, 2024 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn code shared)
  #:use-module (dzn ast)
  #:use-module (dzn ast ast)
  #:use-module (dzn code ast)
  #:export (.assign
            .prefix
            .state

            code:prefix-equal?
            code:shared-value*))

;;;
;;; Shared-state.
;;;
(define-ast <share-state> (<statement>))

(define-ast <shared-transition> (<ast>)
  (from)
  (prefix)
  (to))

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
(define-method (ast:equal? (a <port-pair>) (b <port-pair>))
  (and (ast:eq? (.port a) (.port b))
       (equal? (.other a) (.other b))))

(define-method (ast:equal? (a <shared-transition>) (b <shared-transition>))
  (and
   (equal? (.from a) (.from b))
   (equal? (.to a) (.to b))
   (ast:equal? (.prefix a) (.prefix b))))

(define-method (ast:equal? (a <shared-value>) (b <shared-value>))
  (ast:equal? (.value a) (.value b)))

(define-method (code:prefix-equal? (a <shared-transition>) (b <shared-transition>))
  (and
   (equal? (.from a) (.from b))
   (ast:equal? (.prefix a) (.prefix b))))
