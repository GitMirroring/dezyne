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

(define-module (gnu packages dzn)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-mingw)
  #:use-module (gnu packages guile-patched)
  #:use-module (gnu packages man)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages mcrl2)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages texinfo))

(define guile-json-1 guile-json)

(define %source-dir (getcwd))

;; scp kluit.dezyne.org:.../download/dzn-dzn-2.10.0.tar.gz .
;; guix download ./dzn-dzn-2.10.0.tar.gz

(define-public dzn
  (package
    (name "dzn")
    (version "2.10.0.rc4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://dezyne.org/download/dzn/"
                           name "-" version ".tar.gz"))
       (sha256
        (base32
         #!dzn!# "0jc3hnmlvv9l1l7xrms81yj6dvy0c8cg8607y5cr101hx4vnz7fb"))))
    (inputs `(("bash" ,bash-minimal)
              ("coreutils" ,coreutils)
              ("guile" ,guile-patched)
              ("m4-cw" ,m4-changeword)
              ("mcrl2" ,mcrl2-minimal-patched)
              ("sed" ,sed)))
    (native-inputs `(("autoconf" ,autoconf)
                     ("automake" ,automake)
                     ("gettext" ,gnu-gettext)
                     ("guile-for-build" ,guile-patched)
                     ("help2man" ,help2man)
                     ("perl" ,perl)
                     ("pkg-config" ,pkg-config)
                     ("texinfo" ,texinfo)
                     ("zip" ,zip))) ; for guix environment -l guix.scm
    (propagated-inputs `(("guile-json" ,guile-json-1)))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((ice-9 popen)
                  ,@%gnu-build-system-modules)
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'setenv
           (lambda _
             (setenv "GUILE_AUTO_COMPILE" "0")))
         (add-after 'install 'wrap-binaries
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bash (assoc-ref %build-inputs "bash"))
                    (coreutils (assoc-ref %build-inputs "coreutils"))
                    (guile (assoc-ref %build-inputs "guile"))
                    (json (assoc-ref %build-inputs "guile-json"))
                    (m4 (assoc-ref %build-inputs "m4-cw"))
                    (mcrl2 (assoc-ref %build-inputs "mcrl2"))
                    (sed (assoc-ref %build-inputs "sed"))
                    (effective (read
                                (open-pipe* OPEN_READ
                                            "guile" "-c"
                                            "(write (effective-version))")))
                    (data-dir (string-append out "/share/dzn"))
                    (path (list (string-append bash "/bin")
                                (string-append coreutils "/bin")
                                (string-append guile "/bin")
                                (string-append m4 "/bin")
                                (string-append mcrl2 "/bin")
                                (string-append sed "/bin")))
                    (scm-dir (string-append out "/share/guile/site/" effective))
                    (scm-path (list (string-append out "/share/guile/site/" effective)
                                    (string-append json "/share/guile/site/" effective)))
                    (go-path (list (string-append out "/lib/guile/" effective
                                                  "/site-ccache/")
                                   (string-append json "/lib/guile/" effective
                                                  "/site-ccache/"))))
               (wrap-program (string-append out "/bin/dzn")
                 `("DATADIR" ":" = (,data-dir))
                 `("PATH" ":" prefix ,path)
                 `("GUILE_AUTO_COMPILE" ":" = ("0"))
                 `("GUILE_LOAD_PATH" ":" prefix ,scm-path)
                 `("GUILE_LOAD_COMPILED_PATH" ":" prefix ,go-path)
                 `("LANG" ":" = ())
                 `("LC_ALL" ":" = ()))
               #t))))))
    (synopsis "Dezyne command line tools")
    (description "Dezyne command line tools")
    (home-page "https://verum.com")
    (license license:gpl3+)))

(define-public dzn-mingw
  (package
    (inherit dzn)
    (name "dzn-mingw")
    (native-inputs `(("guile-json-for-build" ,guile-json-1)
                     ("mcrl2" ,mcrl2-minimal-patched)
                     ,@(package-native-inputs dzn)))
    (inputs `(("guile" ,guile-mingw)))
    (propagated-inputs `(("guile-json" ,guile-json-mingw)
                         ("m4-cw" ,m4-changeword)
                         ("mcrl2" ,mcrl2-minimal-mingw)
                         ("sed" ,sed-mingw)))
    (arguments
     (substitute-keyword-arguments (package-arguments dzn)
       ((#:configure-flags flags)
        (cons*
         "--enable-languages=c++"
         "ac_cv_guile_piped_process=yes"
         "ac_cv_lps2lts_stdout=yes"
         "ac_cv_lpscompare_stdin=yes"
         flags))
       ((#:phases phases '%standard-phases)
        `(modify-phases ,phases
           (delete 'wrap-binaries)))))))

(define-public m4-changeword
  (package
    (inherit m4)
    (name "m4-changeword")
    (arguments
     (substitute-keyword-arguments
         `(#:configure-flags '("--enable-changeword" "--program-suffix=-cw")
           ,@(package-arguments m4))))))

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
