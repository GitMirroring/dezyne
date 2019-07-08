;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

;;; Commentary:
;;
;; GNU Guix development package.  To build and install, run:
;;
;;   guix package -f guix.scm
;;
;; or
;;
;;   guix package -f guix.scm
;;
;; To build it, but not install it, run:
;;
;;   guix build -f guix.scm
;;
;; To use as the basis for a development environment, run:
;;
;;   guix environment -l guix.scm
;;
;; To build individual dependencies run, e.g.,
;;
;;   GUIX_PACKAGE_PATH=guix guix build dezyne-services@git
;;   GUIX_PACKAGE_PATH=guix guix build dezyne-regression-test@git
;;   GUIX_PACKAGE_PATH=guix guix build lts
;;   GUIX_PACKAGE_PATH=guix guix build mcrl2
;;
;;; Code:

(use-modules (ice-9 popen)
             (ice-9 rdelim)
             (guix git-download)
             (guix gexp)
             (guix packages)
             (gnu packages))

(define %source-dir (dirname (current-filename)))
(define %guix-dir (string-append %source-dir "/guix"))

(format (current-error-port) "guix-dir:~s\n" %guix-dir)
(add-to-load-path %guix-dir)
(%patch-path (cons %guix-dir (%patch-path)))

(use-modules (dezyne git))

(define (git-commit)
  (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ)))

;; Return it here so `guix build/environment/package' can consume it directly.
dezyne-pack.git
