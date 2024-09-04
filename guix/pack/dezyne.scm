;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2017 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (pack dezyne)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pth)
  #:use-module (pack scmackerel))

(define-public dezyne
  (package
    (name "dezyne")
    (version #!dezyne!# "2.18.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://"
                           (if (string-contains version "rc") "kluit." "")
                           "dezyne.org/download/dezyne/"
                           name "-" version ".tar.gz"))
       (sha256
        (base32 #!dezyne!# "1c4bi3gpl2fi6pk8z9gmrspg2ad7flkgqjs18bnczswii47yg2s8"))))
    (build-system gnu-build-system)
    (native-inputs (list guile-3.0 pkg-config))
    (inputs (list bash-minimal
                  boost
                  guile-3.0
                  guile-json-4
                  guile-readline
                  mcrl2-minimal
                  pth
                  scmackerel
                  sed))
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
            (lambda _
              (let* ((base (string-append #$name "-" #$version))
                     (doc (string-append #$output "/share/doc/" base)))
                (mkdir-p doc)
                (copy-file "NEWS" (string-append doc "/NEWS")))))
          (add-after 'install 'wrap-binaries
            (lambda _
              (let* ((bash #$(this-package-input "bash-minimal"))
                     (guile #$(this-package-input "guile-3.0"))
                     (json #$(this-package-input "guile-json"))
                     (mcrl2 #$(this-package-input "mcrl2-minimal"))
                     (readline #$(this-package-input "guile-readline"))
                     (scmackerel #$(this-package-input "scmackerel"))
                     (sed #$(this-package-input "sed"))
                     (effective (read
                                 (open-pipe* OPEN_READ
                                             "guile" "-c"
                                             "(write (effective-version))")))
                     (path (list (string-append bash "/bin")
                                 (string-append guile "/bin")
                                 (string-append mcrl2 "/bin")
                                 (string-append sed "/bin")))
                     (scm-dir (string-append "/share/guile/site/" effective))
                     (scm-path
                      (list (string-append #$output scm-dir)
                            (string-append json scm-dir)
                            (string-append readline scm-dir)
                            (string-append scmackerel scm-dir)))
                     (go-dir (string-append "/lib/guile/" effective
                                            "/site-ccache/"))
                     (go-path (list (string-append #$output go-dir)
                                    (string-append json go-dir)
                                    (string-append readline go-dir)
                                    (string-append scmackerel go-dir))))
                (wrap-program (string-append #$output "/bin/dzn")
                  `("PATH" ":" prefix ,path)
                  `("GUILE_AUTO_COMPILE" ":" = ("0"))
                  `("GUILE_LOAD_PATH" ":" prefix ,scm-path)
                  `("GUILE_LOAD_COMPILED_PATH" ":" prefix ,go-path))))))))
    (synopsis "Programming language with verifyable formal semantics")
    (description "Dezyne is a programming language and a set of tools to
specify, validate, verify, simulate, document, and implement concurrent
control software for embedded and cyber-physical systems.  The Dezyne language
has formal semantics expressed in @url{https://mcrl2.org,mCRL2}.")
    (home-page "https://dezyne.org")
    (license (list license:agpl3+      ;Dezyne itself
                   license:lgpl3+      ;Dezyne runtime library
                   license:cc0)))) ;Code snippets, images, test data
