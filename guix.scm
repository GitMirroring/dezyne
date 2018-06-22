;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
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

;;; guix.scm -- Guix package definition

;;; Borrowing code from:
;;; guile-sdl2 --- FFI bindings for SDL2
;;; Copyright © 2015 David Thompson <davet@gnu.org>

;;; Commentary:
;;
;; GNU Guix development package.  To build and install, run:
;;
;;   GUIX_PACKAGE_PATH=guix guix package -f guix.scm
;;
;; or
;;
;;   ./pre-inst-env guix package -f guix.scm
;;
;; To build it, but not install it, run:
;;
;;   ./pre-inst-env guix build -f guix.scm
;;
;; To use as the basis for a development environment, run:
;;
;;   ./pre-inst-env guix environment -l guix.scm
;;
;;; Code:

(use-modules (dezyne git))


;; Return it here so `guix build/environment/package' can consume it directly.
dezyne-services.git
