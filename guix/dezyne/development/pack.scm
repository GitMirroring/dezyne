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

(define-module (dezyne development pack)
  #:use-module (srfi srfi-1)

  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages check)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages java)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages markup)
  #:use-module (gnu packages node)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages w3m)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages)
  #:use-module (guix build utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix git-download)
  #:use-module (guix packages)

  #:use-module (dezyne config)
  #:use-module (dezyne extra))

(define dezyne-services
  (package
   (name "dezyne-services")
   (version "development")
   (source (origin
            (method git-fetch)
            (uri (git-reference
                  (url (string-append git.oban "/development.git"))
                  (commit (git-describe->commit "v2.9.1-22-gbb0da784b"))))
            (sha256 (base32 "1qmzkf8nkw9ls0p9ciciiwlxp3h38m5fd7i8g3dqa2rgbpaxws4y"))))
   (propagated-inputs `(("asd-converter" ,asd-converter-0.1.8)
                        ("bash" ,bash)
                        ("fakechroot" ,fakechroot)
                        ("gcc" ,gcc)
                        ("glibc-utf8-locales" ,glibc-utf8-locales)
                        ("graphviz" ,graphviz)
                        ("googletest" ,googletest)
                        ("guile" ,guile-2.2)
                        ("guile-readline" ,guile-readline)
                        ("guile-json" ,guile-json)
                        ("lts" ,lts-0.3-0)
                        ("m4-cw" ,m4-changeword)
                        ("mcrl2" ,mcrl2-git-1)
                        ("node" ,node6)
                        ("python" ,python-2) ; dzn traces
                        ("node-snapshot" ,node-snapshot)))
   (inputs `(("boost" ,boost)
             ("expat" ,expat)))
   (native-inputs `(("bison" ,bison)
                    ("fakechroot" ,fakechroot)
                    ("emacs" ,emacs)
                    ("emacs-htmlize" ,emacs-htmlize)
                    ("flex" ,flex)
                    ("gcc" ,gcc)
                    ("gcc-lib" ,gcc "lib")
                    ("gojs" ,gojs)
                    ("guile" ,guile-2.2)
                    ("guile-readline" ,guile-readline)
                    ("perl" ,perl)
                    ("python" ,python-2)
                    ("tcl" ,tcl)
                    ("tcllib" ,tcllib)
                    ("tclxml" ,tclxml)))
   (native-search-paths
    (list (search-path-specification
           (variable "DEZYNE_PREFIX")
           (separator #f)               ;single entry
           (files '(".")))))
   (build-system gnu-build-system)
   (arguments
    `(#:modules ((srfi srfi-1)
                 ,@%gnu-build-system-modules)
      #:make-flags '("services" "COMMIT=git" "VERBOSE=")
      #:test-target "services-check"
      #:phases
      (modify-phases %standard-phases
                     (add-after 'unpack 'remove-release
                                (lambda _
                                  (delete-file "gaiag/gaiag/commands/release.scm")
                                  #t))
                     (add-before 'configure 'setenv
                                 (lambda _
                                   (let ((htmlize (and=> (find-files (string-append
                                                                      (assoc-ref %build-inputs "emacs-htmlize")
                                                                      "/share/emacs/site-lisp/guix.d")
                                                                     "htmlize.elc")
                                                         (compose dirname car))))
                                     (when htmlize
                                       (setenv "EMACSLOADPATH" (string-append htmlize ":"))))
                                   (setenv "GOJS" (assoc-ref %build-inputs "gojs"))
                                   (setenv "TCLLIBPATH"
                                           (string-append (assoc-ref %build-inputs "tcllib")
                                                          "/lib/tcllib1.19 "
                                                          (assoc-ref %build-inputs "tclxml")
                                                          "/lib/Tclxml3.2 "
                                                          (getenv "TCLLIBPATH")))))
                     (replace 'install
                              (lambda* (#:key outputs #:allow-other-keys)
                                (let ((out (assoc-ref outputs "out")))
                                  (zero? (system* "make" "install-services" "DESTDIR="
                                                  (string-append "PREFIX=" out)))))))))
   (synopsis "javacript dezyne-server service adapters and services' command line tools")
   (description "Dezyne is a component-based model-driven software
development environment.")
   (home-page "http://verum.com")
   (license ((@@ (guix licenses) license)
             "proprietary"
             "http://verum.com"
             "internal"))))

(define dezyne-test-content
  (package
    (name "dezyne-test-content")
    (version (package-version dezyne-services))
    (source (package-source dezyne-services))
    (native-inputs `(("guile" ,guile-2.2)
                     ("guile-readline" ,guile-readline)
                     ("python" ,python-2)
                     ("node" ,node6)))  ; patch-source-shebangs
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags '("test")
       #:tests? #f
       #:phases
       (modify-phases %standard-phases
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (zero? (system* "make" "install-test" "DESTDIR="
                               (string-append "PREFIX=" out)))))))))
    (synopsis "test content")
    (description "test content")
    (home-page "http://verum.com")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))

(define dzn-client-tarball
  (package
    (name "dzn-client-tarball")
    (version (package-version dezyne-services))
    (source (package-source dezyne-services))
    (native-inputs
     `(("dezyne-services" ,dezyne-services)
       ("gojs" ,gojs)
       ("guile" ,guile-2.2)             ; for configure (run by make)
       ("node" ,node6)                  ; for NODE_PATH
       ("node-snapshot" ,node-snapshot) ; for jison
       ("perl" ,perl)                   ; for shasum
       ("sed" ,sed)))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags `("EXCLUDE_INFO=t" "dzn-client"
                      "COMMIT=git")
       #:modules ((srfi srfi-1)
                  ,@%gnu-build-system-modules)
       #:tests? #f
       #:phases
       (modify-phases %standard-phases
         (replace 'patch-generated-file-shebangs
           (lambda* (. args)
             (apply (assoc-ref %standard-phases 'patch-generated-file-shebangs) args)
             (substitute* (append (find-files "dzn/bin" "dzn")
                                  (find-files "client/bin" "dzn"))
               (("#!/gnu/store/.*") "#!/usr/bin/env node\n"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (version (last (string-split out #\-)))
                    (tarball (string-append "dzn-" version ".tar.gz"))
                    (download-dir (string-append out "/root/download/npm")))
               (mkdir-p download-dir)
               (copy-file (string-append "build/" tarball)
                          (string-append download-dir "/" tarball))))))))
    (synopsis "dzn client tarball for npm install")
    (description "dzn client tarball for npm install")
    (home-page "https://hosting.verum.com/download/npm")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))

(define dzn-client
  (package
    (name "dzn-client")
    (version (package-version dezyne-services))
    (source #f)
    (native-inputs `(("dzn-client-tarball" ,dzn-client-tarball)))
    (propagated-inputs `(("bash" ,bash)
                         ("node" ,node6)
                         ("node-snapshot" ,node-snapshot)))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:modules ((srfi srfi-1)
                  ,@%gnu-build-system-modules)
       #:phases
       (modify-phases %standard-phases
         (replace 'unpack
           (lambda* (#:key outputs source #:allow-other-keys)
             (let* ((unpack (assoc-ref %standard-phases 'unpack))
                    (out (assoc-ref outputs "out"))
                    (version (last (string-split out #\-))))
               (unpack #:source (string-append (assoc-ref %build-inputs "dzn-client-tarball")
                                               "/root/download/npm/dzn" "-"
                                               version
                                               ".tar.gz")))))
         (delete 'configure)
         (delete 'build)
         (delete 'validate-runpath)
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (node-modules (string-append out "/lib/node_modules/dzn"))
                    (bin (string-append out "/bin")))
               (mkdir-p node-modules)
               (copy-recursively "." node-modules)
               (mkdir-p bin)
               (symlink (string-append node-modules "/bin/dzn") (string-append bin "/dzn"))
               (symlink (string-append node-modules "/bin/browse") (string-append bin "/browse"))))))))
    (synopsis "dzn client")
    (description "dzn client")
    (home-page "https://hosting.verum.com/download/npm")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))

(define dezyne-server
  (package
   (name "dezyne-server")
   (version (package-version dezyne-services))
   (source (package-source dezyne-services))
   (build-system gnu-build-system)
   (propagated-inputs `(("node" ,node6)
                        ("postgresql" ,postgresql-9.6)
                        ("node-snapshot" ,node-snapshot)))
   (native-inputs `(("dezyne-services" ,dezyne-services)
                    ("guile" ,guile-2.2)
                    ("guile-readline" ,guile-readline)
                    ("gojs" ,gojs)))
   (native-search-paths
    (list (search-path-specification
           (variable "DEZYNE_PREFIX")
           (separator #f)            ; single entry
           (files '(".")))))
   (arguments
    `(#:modules ((srfi srfi-1)
                 (ice-9 rdelim)
                 (ice-9 regex)
                 ,@%gnu-build-system-modules)
      #:make-flags `("server")
      #:test-target "server-check"
      #:phases
      (modify-phases %standard-phases
                     (add-before 'configure 'setenv
                                 (lambda _
                                   (setenv "GOJS" (assoc-ref %build-inputs "gojs"))
                                   (setenv "DEZYNE_PREFIX" (assoc-ref %build-inputs "dezyne-services"))
                                   (format (current-error-port) "DEZYNE_PREFIX=~a\n" (getenv "DEZYNE_PREFIX"))))
                     (replace 'install
                              (lambda* (#:key outputs #:allow-other-keys)
                                (let ((out (assoc-ref outputs "out")))
                                  (zero? (system* "make" "install-server" "DESTDIR="
                                                  (string-append "PREFIX=" out)))))))))
   (synopsis "Dezyne server")
   (description "Dezyne is a component-based model-driven software
development environment.")
   (home-page "http://www.verum.com")
   (license ((@@ (guix licenses) license)
             "proprietary"
             "http://verum.com"
             "internal"))))

(define dezyne-regression-test
  (package
    (version (package-version dezyne-services))
    (name "dezyne-regression-test")
    (source #f)
    (native-inputs
     `(("dezyne-services" ,dezyne-services)
       ("dezyne-test-content" ,dezyne-test-content)
       ("bash" ,bash)
       ("boost" ,boost)
       ("coreutils" ,coreutils)
       ("diffutils" ,diffutils)
       ("emacs" ,emacs)
       ("fakechroot" ,fakechroot)
       ("gcc" ,gcc)
       ("gcc-lib" ,gcc "lib")
       ("gcc-toolchain" ,gcc-toolchain-5)
       ("glibc-locales" ,glibc-locales)
       ("glibc-utf8-locales" ,glibc-utf8-locales)
       ("grep" ,grep)
       ("guile" ,guile-2.2)
       ("guile-readline" ,guile-readline)
       ("jdk" ,icedtea-8 "jdk")
       ("linux-libre-headers" ,linux-libre-headers)
       ("m4-cw" ,m4-changeword)
       ("make" ,gnu-make)
       ("markdown" ,markdown)
       ("mono" ,mono-4.2)
       ("node" ,node6)
       ("node-snapshot" ,node-snapshot)
       ("perl" ,perl)
       ("pkgconfig" ,pkg-config)
       ("procps" ,procps)
       ("psmisc" ,psmisc)
       ("python" ,python-2)
       ("sed" ,sed)
       ("texinfo" ,texinfo)
       ("util-linux" ,util-linux)
       ("w3m" ,w3m)))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((srfi srfi-1)
                  ,@%gnu-build-system-modules)
       #:phases
       (modify-phases %standard-phases
         (delete 'unpack)
         (delete 'check)
         (delete 'install)
         (replace 'configure
           (lambda _
             (let* ((out (assoc-ref %outputs "out"))
                    (prefix (string-append (getcwd) "/prefix"))
                    (services (string-append prefix "/services")))
               (mkdir-p out)
               (mkdir-p (string-append out "/out"))
               (mkdir-p services)
               (setenv "DEZYNE_PREFIX" prefix)
               (format (current-error-port) "DEZYNE_PREFIX=" (getenv "DEZYNE_PREFIX"))
               (for-each (lambda (input)
                           (let* ((dir (cdr input))
                                  (version (last (string-split dir #\-)))
                                  (version (if (string-prefix? "git" version) "development" version)))
                             (symlink (string-append dir "/services/" version)
                                      (string-append services "/" version))))
                         (filter (lambda (o) (string-prefix? "dezyne-services" (car o)))
                                 %build-inputs))
               (and (zero? (system* "ls" "-l" services))
                    (zero? (system* "gdzn" "--version"))
                    (zero? (system* "gdzn" "-d" "query"))))))
         (replace 'build
           (lambda _
             (let* ((out (assoc-ref %outputs "out"))
                    (version (last (string-split out #\-)))
                    (version (if (string-prefix? "git" version) "development" version))
                    (services (assoc-ref %build-inputs "dezyne-services"))
                    (service-dir (string-append services "/services/" version))
                    (gdzn (string-append service-dir "/bin/gdzn"))
                    (test (assoc-ref %build-inputs "dezyne-test-content"))
                    (version (last (string-split out #\-)))
                    (regression (string-append out "/root/regression"))
                    (results
                     (fold
                      (lambda (dir status+dirs)
                        (format (current-error-port) "dir=~s, status+dirs=~s\n" dir status+dirs)
                        (let ((cmd (format #f "set -x; cd ~a && DZN=~a ~a/test/bin/test --quiet -j ~a ~a/test/~a" "/tmp" gdzn test (current-processor-count) test dir))
                              (status (car status+dirs))
                              (dirs (cdr status+dirs)))
                          (if (not status) status+dirs
                              (cons (and ;;(zero? (status:exit-val (system cmd)))
                                     (status:exit-val (system cmd))
                                         (file-exists? (string-append "/tmp/out/" dir ".html")))
                                    (if (not (file-exists? (string-append "/tmp/out/" dir ".html"))) dirs
                                        (cons dir dirs))))))
                      '(0 . ())
                      '("smoke" "hello" "regression"
                        "interpreter-error-msg" "verification-error-msg"
                        "examples"
                        "old-regression"
                        "NUTS")))
                    (dirs (cdr results)))
               (for-each
                (lambda (dir)
                  (copy-file (string-append "/tmp/out/" dir ".html")
                             (string-append out "/out/" dir ".html"))
                  (copy-file (string-append "/tmp/out/" dir ".details.html")
                             (string-append out "/out/" dir ".details.html")))
                dirs)
               (mkdir-p regression)
               (symlink (string-append out "/out") (string-append regression "/" version))))))))
    (synopsis "run the regression test and install regression.html")
    (description "run the regression test and install regression.html")
    (home-page "http://verum.com")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))

(define dezyne-pack
  (package
   (version (package-version dezyne-services))
   (name "dezyne-pack")
   (source #f)
   (propagated-inputs
    `(("dezyne-server" ,dezyne-server)

      ("dezyne-services" ,dezyne-services)
      ("dezyne-test-content" ,dezyne-test-content)
      ("dzn-client-tarball" ,dzn-client-tarball)
      ("dzn-client" ,dzn-client)
      ("dezyne-regression-test" ,dezyne-regression-test)

      ("shepherd" ,shepherd)
      ("postgres-config" ,postgres-config)))
   (build-system trivial-build-system)
   (arguments
    `(#:modules ((guix build utils))
      #:builder (begin (use-modules (guix build utils))
                       (mkdir-p (assoc-ref %outputs "out")))))
   (synopsis "meta package for a dezyne release")
   (description "meta package for a dezyne release")
   (home-page "http://verum.com")
   (license ((@@ (guix licenses) license)
             "proprietary"
             "http://verum.com"
             "internal"))))

(define-public dezyne-services-development dezyne-services)
(define-public dezyne-server-development dezyne-server)
(define-public dezyne-regression-test-development dezyne-regression-test)
(define-public dezyne-test-content-development dezyne-test-content)
(define-public dzn-client-tarball-development dzn-client-tarball)
(define-public dzn-client-development dzn-client)
(define-public dezyne-pack-development dezyne-pack)
