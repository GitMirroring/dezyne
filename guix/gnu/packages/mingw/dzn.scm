;;; Dezyne --- Dezyne command line tools
;;;
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
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (gnu packages mingw dzn)
  #:use-module (gnu packages dzn)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages mingw base)
  #:use-module (gnu packages mingw guile)
  #:use-module (gnu packages mingw mcrl2)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public dzn-mingw
  (package
    (inherit dzn)
    (name "dzn-mingw")
    (native-inputs `(("guile-json-for-build" ,guile-json)
                     ,@(package-native-inputs dzn)))
    (inputs `(("guile" ,guile-mingw)))
    (propagated-inputs `(("guile-json" ,guile-json-mingw)
                         ("m4-cw" ,m4-changeword)
                         ("mcrl2" ,mcrl2-minimal-mingw)
                         ("sed" ,sed-mingw)))
    (arguments
     (substitute-keyword-arguments (package-arguments dzn)
       ((#:phases phases '%standard-phases)
        `(modify-phases ,phases
           (delete 'wrap-binaries)))))))
