;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gnu packages mingw boost)
  #:use-module (gnu packages boost)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public boost-mingw
  (package
    (inherit boost)
    (name "boost-mingw")
    (inputs '())
    (arguments
     (substitute-keyword-arguments
      (package-arguments boost)
      ((#:phases phases '%standard-phases)
       `(modify-phases ,phases
          (replace 'configure
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let ((icu (assoc-ref inputs "icu4c"))
                    (out (assoc-ref outputs "out")))
                (substitute* '("libs/config/configure"
                               "libs/spirit/classic/phoenix/test/runtest.sh"
                               "tools/build/src/engine/execunix.c"
                               "tools/build/src/engine/Jambase"
                               "tools/build/src/engine/jambase.c")
                             (("/bin/sh") (which "sh")))

                (setenv "SHELL" (which "sh"))
                (setenv "CONFIG_SHELL" (which "sh"))

                (invoke "./bootstrap.sh"
                        (string-append "--prefix=" out)
                        (if icu (string-append "--with-icu=" icu) "")
                        "--with-toolset=gcc"))))))))))
