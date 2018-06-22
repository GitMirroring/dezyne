;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dezyne v2.2 extra)

  #:use-module (gnu packages boost)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages xml)

  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix packages)

  #:use-module (dezyne config))


(define-public asd-converter-0.1.0
  (package
    (name "asd-converter-0.1.0")
    (version "0.1.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference (url (string-append git.oban/git "/gen1gen2.git"))
                                  (commit "master")))
              (sha256 (base32 "0hsaj3gf72y4yyv64q434psn6bjb6gz3ws2iaxm243l3p7y5zqzd"))))
    (inputs `(("boost" ,boost)
              ("expat" ,expat)))
    (native-inputs `(("bison" ,bison)
                     ("flex" ,flex)
                     ("gcc" ,gcc)
                     ("gcc-lib" ,gcc "lib")
                     ("tcl" ,tcl)
                     ("tcllib" ,tcllib)
                     ("tclxml" ,tclxml)))
    (build-system gnu-build-system)
    (arguments
     `(#:parallel-tests? #f
       #:parallel-build? #f
       #:tests? #f
       #:make-flags '("-C" "product/code")
       #:modules ((srfi srfi-1)
                  ,@%gnu-build-system-modules)
       #:phases (modify-phases %standard-phases
                  (delete 'configure)
                  (replace 'install
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let* ((out (assoc-ref outputs "out"))
                             (version (last (string-split out #\-)))
                             (bin (string-append out "/bin"))
                             (asd (string-append "asd" "-" version)))
                        (mkdir-p (string-append out "/bin"))
                        (copy-file "product/code/build/linux64/asd"
                                   (string-append bin "/" asd))
                        (symlink (string-append asd) (string-append bin "/asd"))))))))
    (synopsis "package for asd->dzn converter")
    (description "package for asd->dzn converter")
    (home-page "http://verum.com")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))
