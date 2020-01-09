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
  #:use-module (guix build-system node)
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
  #:use-module (gnu packages lts)
  #:use-module (gnu packages man)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages mcrl2)
  #:use-module (gnu packages node)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages texinfo))

(define %source-dir (getcwd))

(define-public dzn
  (package
    (name "dzn")
    (version "0.0")
    ;; TODO: URL to released tarball
    (source (local-file %source-dir
                        #:recursive? #t
                        #:select? (git-predicate %source-dir)))
    (inputs `(("bash" ,bash-minimal)
              ("coreutils" ,coreutils)
              ("guile" ,guile-2.2)
              ("lts" ,lts)
              ("m4-cw" ,m4-changeword)
              ("mcrl2" ,mcrl2-1-minimal)
              ("sed" ,sed)))
    (native-inputs `(("autoconf" ,autoconf)
                     ("automake" ,automake)
                     ("gettext" ,gnu-gettext)
                     ("guile-for-build" ,guile-2.2)
                     ("help2man" ,help2man)
                     ("node" ,node)
                     ("node-getopt" ,node-getopt)
                     ("node-q" ,node-q)
                     ("perl" ,perl)
                     ("pkg-config" ,pkg-config)
                     ("zip" ,zip)))   ; for guix environment -l guix.scm
    (propagated-inputs `(("guile-json" ,guile-json-1)))
    (build-system gnu-build-system)
    (outputs '("out" "regression"))
    (arguments
     `(#:modules ((ice-9 popen)
                  ,@%gnu-build-system-modules)
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'setenv
           (lambda _
             (setenv "GUILE_AUTO_COMPILE" "0")))
         (replace 'check
           (lambda _
             (system* "make" "check-smoke")
             (system* "make" "check-hello")
             (system* "make" "check-regression")
             #t))
         (add-after 'install 'split-regression
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (regression (assoc-ref outputs "regression"))
                    (share "/share/dzn")
                    (dir (string-append share "/test")))
               (mkdir-p (string-append regression share))
               (rename-file (string-append out dir)
                            (string-append regression dir))
               #t)))
         (add-after 'install 'wrap-binaries
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (guile (assoc-ref %build-inputs "guile"))
                    (json (assoc-ref %build-inputs "guile-json"))
                    (lts (assoc-ref %build-inputs "lts"))
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
                                (string-append lts "/bin")
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

(define-public m4-changeword
  (package
    (inherit m4)
    (name "m4-changeword")
    (arguments
     (substitute-keyword-arguments
         `(#:configure-flags '("--enable-changeword" "--program-suffix=-cw")
           ,@(package-arguments m4))))))

(define-public node-q
  (package
    (name "node-q")
    (version "1.5.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://registry.npmjs.org/q/-/q-1.5.0.tgz")
       (sha256
        (base32
         "02swcgz18abmnlxk2f23sxngm0jp8mfzr824s30vjjgvn9p0nfq1"))))
    (build-system node-build-system)
    (propagated-inputs `())
    (native-inputs `())
    (arguments
     `(#:tests? #f                      ; Needs jasmine-node
       #:phases
       (modify-phases %standard-phases
         (add-after 'install 'remove-bin
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (delete-file (string-append out "/bin"))
               #t))))))
    (synopsis
     "A library for promises (CommonJS/Promises/A,B,D)")
    (description
     "A library for promises (CommonJS/Promises/A,B,D)")
    (home-page "https://github.com/kriskowal/q")
    (license expat)))

(define-public node-getopt
  (package
    (name "node-getopt")
    (version "0.2.3")
    (source
     (origin
       (method url-fetch)
       (uri "https://registry.npmjs.org/node-getopt/-/node-getopt-0.2.3.tgz")
       (sha256
        (base32
         "1i8q6bdlnm9nwdjmwadk3rxn7zbjxs6l1rgk31xq67mpiawxf6a6"))))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'install 'remove-bin
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (delete-file (string-append out "/bin"))
               #t))))))
    (build-system node-build-system)
    (propagated-inputs `())
    (native-inputs `())
    (synopsis "featured command line args parser")
    (description "featured command line args parser")
    (home-page "http://npmjs.com")
    (license expat)))
