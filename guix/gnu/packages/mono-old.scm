;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
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

(define-module (gnu packages mono-old)
  #:use-module (gnu packages mono)
  #:use-module (guix download)
  #:use-module (guix packages))

(define-public mono-4.2
  (package
    (inherit mono)
    (name "mono")
    (version "4.2.1.102")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://download.mono-project.com/sources/mono/"
                    name "-" version
                    ".tar.bz2"))
              (sha256
               (base32
                "14np3sjqgl7pc1j165ryzlww8cyby73ahsqni0fn4prp0kz63d5p"))))
    (arguments
     `(#:tests? #f ; 4.2.1.102: many tests fail, hang-- disable all
       ,@(package-arguments mono)))))
