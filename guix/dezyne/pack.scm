;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Henk Katerberg <henk.katerberg@verum.com>
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

(define-module (dezyne pack)

  #:use-module (dezyne development pack))

(define-public dezyne-services dezyne-services-development)
(define-public dezyne-server dezyne-server-development)
(define-public dezyne-regression-test dezyne-regression-test-development)
(define-public dezyne-test-content dezyne-test-content-development)
(define-public dzn-client-tarball dzn-client-tarball-development)
(define-public dzn-client dzn-client-development)
(define-public dezyne-pack dezyne-pack-development)
