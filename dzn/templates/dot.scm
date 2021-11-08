;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021 Jan Nieuwenhuizen <janneke@gnu.org>
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

;;;
;;; System
;;;
(define-templates source-sut)

(define-templates instance dot:instance*)
(define-templates connection-instance dot:connection-instance)
(define-templates other-connection-instance dot:other-connection-instance)

(define-templates headlabel dot:headlabel)
(define-templates taillabel dot:taillabel)

;;; component
(define-templates provides-port dot:provides-port*)
(define-templates requires-port dot:requires-port*)
(define-templates connection dot:connection*)


;;;
;;; Dependency
;;;

;;; expand:
;;;
;;; root
;;;   system
;;;     instance -> interface, component-model
;;;   component-model
;;;     instance -> interface
;;;   interface

;;; dependent: system, component, interface
;;; dependency: system -> interface, system -> component, component -> interface

(define-templates source-dependent)
(define-templates dependent dot:dependent)
(define-templates dependency dot:dependency)
(define-templates dependency-instance ast:instance*)
(define-templates dependency-provides ast:provides-port*)
(define-templates dependency-requires ast:requires-port*)
