;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (gnu packages mingw base)
  #:use-module (gnu packages base)
  #:use-module (guix build-system gnu)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public sed-mingw
  (package
    (inherit sed)
    (name "sed-mingw")
    (arguments
     `(#:tests? #f
       #:make-flags '("sed/sed.exe")
       ,@(substitute-keyword-arguments (package-arguments sed)
           ((#:phases phases '%standard-phases)
            `(modify-phases ,phases
               (replace 'install
                 (lambda _
                   (let* ((out (assoc-ref %outputs "out"))
                          (bin (string-append out "/bin")))
                     (install-file "sed/sed.exe" bin)))))))))))
