;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gnu packages guile-patched)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages guile))

(define-public guile-2.2.6
  (package
    (inherit guile-2.2)
    (version "2.2.6")
    (source (origin
              (method url-fetch)

              ;; Note: we are limited to one of the compression formats
              ;; supported by the bootstrap binaries, so no lzip here.
              (uri (string-append "mirror://gnu/guile/guile-" version
                                  ".tar.xz"))
              (sha256
               (base32
                "1269ymxm56j1z1lvq1y42rm961f2n7rinm3k6l00p9k52hrpcddk"))))))

(define-public guile-patched
  (package
    (inherit guile-2.2.6)
    (name "guile-piped-process")
    (source (origin
              (inherit (package-source guile-2.2.6))
              (patches (cons* (search-patch "guile-piped-process.patch")
                              (origin-patches (package-source guile-2.2.6))))
              ;; Use pre-built object files.  Saves ~3h build time.
              (snippet #f)))))
