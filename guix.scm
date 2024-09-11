;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2017 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2020 Rutger van Beusekom <rutger@dezyne.org>
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

;;; Commentary:
;;
;; GNU Guix development package.  To build and install, run:
;;
;;   guix package -f guix.scm
;;
;; To build it, but not install it, run:
;;
;;   guix build -f guix.scm
;;
;; To use as the basis for a development environment, run:
;;
;;   guix shell -D -f guix.scm
;;
;; or simply
;;
;;   guix shell
;;
;; To use the canonical commit that has everything prebuilt:
;;
;;   guix time-machine --commit=f977cb2b609f7122db2cf026cac5ab9d6d44a206 -- shell
;;
;;; Code:

(use-modules (guix gexp)
             (guix git-download)
             (guix packages)
             (gnu packages)
             (gnu packages autotools)
             (gnu packages gettext)
             (gnu packages man)
             (gnu packages perl)
             (gnu packages texinfo))

(define %source-dir (dirname (current-filename)))
(add-to-load-path (string-append %source-dir "/guix"))
(%patch-path (cons (string-append %source-dir "/guix") (%patch-path)))
(use-modules (pack dezyne))

(define-public dezyne.git
  (package
    (inherit dezyne)
    (version "git")
    (source (local-file %source-dir
                        #:recursive? #t
                        #:select? (git-predicate %source-dir)))
    (native-inputs `(("autoconf" ,autoconf)
                     ("automake" ,automake)
                     ("gettext" ,gnu-gettext)
                     ("help2man" ,help2man)
                     ("libtool" ,libtool)
                     ("perl" ,perl)
                     ("texinfo" ,texinfo)
                     ,@(package-native-inputs dezyne)))))

dezyne.git
