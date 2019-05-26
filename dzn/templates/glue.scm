;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-templates model-glue c++:model-glue)
(define-templates header-model-glue c++:header-model-glue)
(define-templates foreign-header)
(define-templates glue-top-header)
(define-templates glue-top-source)
(define-templates glue-bottom-header)
(define-templates glue-bottom-source)
(define-templates asd-constructor c++:asd-constructor)
(define-templates asd-api-instance-declaration c++:asd-api-instance-declaration)
(define-templates asd-api-instance-init c++:asd-api-instance-init)
(define-templates asd-api-definition c++:asd-api-definition)
(define-templates asd-cb-definition c++:asd-cb-definition)
(define-templates asd-cb-instance-declaration c++:asd-cb-instance-declaration)
(define-templates asd-cb-instance-init c++:asd-cb-instance-init)
(define-templates asd-cb-event-init c++:asd-cb-event-init)
(define-templates asd-get-api c++:asd-get-api)
(define-templates asd-register-cb c++:asd-register-cb)
(define-templates asd-register-st c++:asd-register-st)
(define-templates asd-reset-api c++:asd-reset-api)
(define-templates asd-method-declaration c++:asd-method-declaration)
(define-templates asd-method-definition c++:asd-method-definition)
(define-templates asd-cb-method-definition c++:asd-cb-method-definition)
(define-templates asd-get-api-definition c++:asd-get-api-definition)
(define-templates asd-register-cb-definition c++:asd-register-cb-definition)
(define-templates implemented-port-name c++:implemented-port-name)
(define-templates decapitalize-asd-interface-name c++:decapitalize-asd-interface-name)
(define-templates construction-include c++:construction-include)
(define-templates construction-signature c++:construction-signature)
(define-templates construction-parameters c++:construction-parameters)
(define-templates construction-parameters-locator-set c++:construction-parameters-locator-set)
(define-templates construction-parameters-locator-get c++:construction-parameters-locator-get)
