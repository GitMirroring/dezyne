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

(define-module (dezyne v2.8 extra)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)

  #:use-module ((guix licenses) #:prefix license:)

  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages xml)

  #:use-module (gnu packages)

  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)

  #:use-module (guix utils)

  #:use-module (dezyne config)
  #:use-module (dezyne extra))


(define-public mcrl2-git-1
  (let ((commit "2c7d1d5d3196622c63ac39f69d41a4bf0e9fa447")
        (version "201707")
        (revision "1"))
    (package
      (inherit mcrl2)
      (name "mcrl2-git")
      (version (string-append version "." revision "." (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/mCRL2org/mCRL2")
                      (commit commit)))
                (patches (search-patches "mcrl2-Remove-git-magic-from-MCRL2Version.cmake.patch"
                                         "mcrl2-pipeline-support.patch"
                                         "mcrl2-ltsgraph-override-lts-type.patch"))
                (sha256
                 (base32
                  "1ky11f1g2hlq9cp3gj2z4rly87pl7p9sr0b6ls3ls2nrzi4fis7r"))))
      (arguments
       `(#:configure-flags '("-DCMAKE_BUILD_TYPE=Release")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'set-version
             (lambda* _
               (substitute* '("build/cmake/MCRL2Version.cmake")
                 (("(set\\(MCRL2_MINOR_VERSION \")Unknown(\"\\))" all left right)
                  (string-append left ,(string-take commit 7) right)))))))))))

(define-public lts-0.3-0
  (let* ((commit "8a6bab5c729d0173105e900e239aed4aedd7f82e")
         (src-url (string-append git.oban/git "/lts.git"))
         (src-hash "1qjnhv7yf2x6slzy49pizpcbrqcrxlfbqzqfr4yssy3iv4j48lpr")
         (revision "0"))
    (package
      (name "lts")
      (version (string-append "0.3-" revision "." (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference (url src-url) (commit commit)))
                (sha256 (base32 src-hash))))
      (propagated-inputs
       `(("guile" ,guile-2.2)
         ("guile-readline" ,guile-readline)))
      (build-system gnu-build-system)
      (synopsis "lts")
      (description "Navigate and query lts from FILE in (Aldebaran) aut format.")
      (home-page "http://www.verum.com")
      (license ((@@ (guix licenses) license)
                "proprietary"
                "http://verum.com"
                "internal")))))

(define-public asd-converter-0.1.5
  (package
    (name "asd-converter")
    (version "0.1.5")
    (source (origin
              (method git-fetch)
              (uri (git-reference (url (string-append git.oban/git "/gen1gen2.git"))
                                  (commit "eb94c2078db092116b7e7eb3bb4c35f7ce606034")))
              (sha256 (base32 "11c7psc0rswjw3b5xgac7qy7vs11g9i4h8ngmkbmrv37xlvq62vy"))))
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
