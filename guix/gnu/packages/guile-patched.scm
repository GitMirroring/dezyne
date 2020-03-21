;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020,2020 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (gnu packages)
  #:use-module (gnu packages guile)
  #:use-module (guix packages))

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
