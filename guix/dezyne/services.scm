;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018, 2019 Henk Katerberg <henk.katerberg@verum.com>
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

(define-module (dezyne services)

  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages check)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages xml)

  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix packages)

  #:use-module (dezyne config)
  #:use-module (dezyne extra))

(define-public dezyne-source-development
  (origin
    (method git-fetch)
    (uri (git-reference
          (url (string-append git.oban/blessed "/development.git"))
          (commit (git-describe->commit "2.9.0-18-gc000dcb4a"))))
    (sha256 (base32 "1sr5r10hxgq5awiij4m7i55718niwpxiq365dx72ylbfar3m54b1"))))

(define-public dezyne-services
  (package
    (name "dezyne-services")
    (version "development")
    (source dezyne-source-development)
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
            (separator #f)              ;single entry
            (files '(".")))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((srfi srfi-1)
                  (ice-9 rdelim)
                  (ice-9 regex)
                  ,@%gnu-build-system-modules)
       #:make-flags '("services" "COMMIT=git" "VERBOSE=")
       #:test-target "services-check"
       #:phases
       (modify-phases %standard-phases
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

(define-public dezyne-test-content
  (package
    (name "dezyne-test-content")
    (version "development")
    (source dezyne-source-development)
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

(define-public dzn-client-tarball
  (package
    (name "dzn-client-tarball")
    (version "development")
    (source dezyne-source-development)
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

(define-public node-dzn
  (package
    (name "node-dzn")
    (version "development")
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
