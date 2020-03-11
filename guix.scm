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

;;; Commentary:
;;
;; GNU Guix development package.  To build and play, run:
;;
;;   guix environment --ad-hoc -l guix.scm guile
;;
;; To build and install, run:
;;
;;   guix package -f guix.scm
;;
;; To build it, but not install it, run:
;;
;;   guix build -f guix.scm
;;
;; To use as the basis for a development environment, run:
;;
;;   guix time-machine --commit=53f21642729e4786141c072dd835b04cb85dfe28 -- environment -l guix.scm
;;
;;; Code:

(use-modules (guix gexp)
             (guix git-download)
             (guix packages)
             (gnu packages))

(define %source-dir (dirname (current-filename)))
(add-to-load-path (string-append %source-dir "/guix"))
(%patch-path (cons (string-append %source-dir "/guix") (%patch-path)))
(use-modules (gnu packages dzn))

(define-public dzn.git
  (package
    (inherit dzn)
    (source (local-file %source-dir
                        #:recursive? #t
                        #:select? (git-predicate %source-dir)))))

dzn.git
