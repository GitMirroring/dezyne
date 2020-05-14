;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019,2020,2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (pack mcrl2)
  #:use-module (gnu packages)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages maths)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public mcrl2-next
  (package
    (inherit mcrl2)
    (version "202206.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://www.mcrl2.org/download/release/mcrl2-"
                    version ".tar.gz"))
              (sha256
               (base32
                "1rbfyw47bi31qla1sa4fd1npryb5kbdr0vijmdc2gg1zhpqfv0ia"))))
    (name "mcrl2-next")))

(define-public mcrl2-next-minimal
  (package
    (inherit mcrl2-minimal)
    (name "mcrl2-next-minimal")
    (version (package-version mcrl2-next))
    (source (package-source mcrl2-next))))
