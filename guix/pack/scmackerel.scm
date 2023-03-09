;;; SCMackerel --- A GNU Guile front-end for mCRL2
;;; Copyright © 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of SCMackerel.
;;;
;;; SCMackerel is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; SCMackerel is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with SCMackerel.  If not, see <http://www.gnu.org/licenses/>.

(define-module (pack scmackerel)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages pkg-config))

(define-public scmackerel
  (package
    (name "scmackerel")
    (version #!scmackerel!# "0.3.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://dezyne.org/download/scmackerel/"
                           name "-" version ".tar.gz"))
       (sha256
        (base32 #!scmackerel!# "1fp2g286cdr7ja4nghg1xs0f5j1g53kw539m2qx80252g98q1iwk"))))
    (inputs (list bash-minimal
                  guile-3.0-latest
                  guile-readline
                  mcrl2-minimal))
    (native-inputs (list guile-3.0-latest pkg-config))
    (build-system gnu-build-system)
    (arguments
     (list
      #:modules `((ice-9 popen)
                  ,@%gnu-build-system-modules)
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'setenv
            (lambda _
              (setenv "GUILE_AUTO_COMPILE" "0")))
          (add-after 'install 'install-readmes
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (base (string-append #$name "-" #$version))
                     (doc (string-append out "/share/doc/" base)))
                (mkdir-p doc)
                (copy-file "NEWS" (string-append doc "/NEWS"))))))))
    (synopsis "Programming language with verifyable formal semantics")
    (description "SCMackerel is a library for GNU Guile for creating
abstract syntax trees (ASTs) for @url{https://mcrl2.org,mCRL2} and other
languages, such as C, C++, and C#, based on GNU Guix records.")
    (home-page "https://dezyne.org")
    (license (list license:gpl3+))))
