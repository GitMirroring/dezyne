;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (gnu packages guile)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages pkg-config))

(define %source-dir (getcwd))

;; scp kluit.dezyne.org:.../download/dezyne-2.10.0.tar.gz .
;; guix download ./dezyne-2.10.0.tar.gz

;; This makes `git am 0001-guix-dezyne-Update-to-2.13.2.patch' work.
(define guile-3.0-latest guile-next)

(define-public dezyne
  (package
    (name "dezyne")
    (version #!dezyne!# "2.16.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://dezyne.org/download/dezyne/"
                           name "-" version ".tar.gz"))
       (sha256
        (base32 #!dezyne!# "0dnh8wji9npaxg3qjivc45dwxwrzz9fbs77000g8s2192sf4ms7k"))))
    (inputs (list bash-minimal
                  guile-3.0-latest
                  guile-json-4
                  guile-readline
                  mcrl2-minimal
                  sed))
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
                (copy-file "NEWS" (string-append doc "/NEWS")))))
          (add-after 'install 'wrap-binaries
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bash (assoc-ref %build-inputs "bash-minimal"))
                     (guile (assoc-ref %build-inputs "guile-next"))
                     (json (assoc-ref %build-inputs "guile-json"))
                     (mcrl2 (assoc-ref %build-inputs "mcrl2-minimal"))
                     (readline (assoc-ref %build-inputs "guile-readline"))
                     (sed (assoc-ref %build-inputs "sed"))
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
                      (list (string-append out scm-dir)
                            (string-append json scm-dir)
                            (string-append readline scm-dir)))
                     (go-dir (string-append "/lib/guile/" effective
                                            "/site-ccache/"))
                     (go-path (list (string-append out go-dir)
                                    (string-append json go-dir)
                                    (string-append readline go-dir))))
                (wrap-program (string-append out "/bin/dzn")
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
