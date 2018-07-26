;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
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

(define-module (dezyne pack)
  #:use-module (srfi srfi-1)

  #:use-module (gnu packages)
  #:use-module (gnu packages admin)       ; shepherd
  #:use-module (gnu packages base)        ; coreutils
  #:use-module (gnu packages databases)   ; postgres

  #:use-module (gnu packages bash)      ; regression-test
  #:use-module (gnu packages boost)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages java)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages node)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages w3m)       ; end regression-test

  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build utils)
  #:use-module (guix git-download)      ; git-reference-commit
  #:use-module (guix packages)

  #:use-module (dezyne extra)

  #:use-module (dezyne server)
  #:use-module (dezyne services)

  #:use-module (dezyne v2.4 services)
  #:use-module (dezyne v2.8 services))

(when (resolve-module '(gnu packages markdown) #:ensure #f)
  (use-modules (gnu packages markdown))) ; guix 0.13
(when (resolve-module '(gnu packages markup) #:ensure #f)
  (use-modules (gnu packages markup)))  ; guix 0.14

(define-public dezyne-regression-test
  (package
    (version "development")
    (name "dezyne-regression-test")
    (source #f)
    (native-inputs
     `(("dezyne-services" ,dezyne-services)
       ("dezyne-test-content" ,dezyne-test-content)
       ("dezyne-services-2.8" ,dezyne-services-2.8)
       ("dezyne-services-2.4" ,dezyne-services-2.4)

       ("bash" ,bash)
       ("boost" ,boost)
       ("coreutils" ,coreutils)
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

(define-public dezyne-pack
  (let ((version "11.2.8.0")
        (revision "0")
        (commit ((compose git-reference-commit origin-uri) dezyne-source-development)))
    (package
      (version (string-append version "." revision "." (string-take commit (min (string-length commit) 7))))
      (name "dezyne-pack")
      (source #f)
      (propagated-inputs
       `(("dezyne-server" ,dezyne-server)

         ("dezyne-services" ,dezyne-services)
         ("dezyne-regression-test" ,dezyne-regression-test)
         ("dezyne-test-content" ,dezyne-test-content)
         ("dzn-client-tarball" ,dzn-client-tarball)

         ("dezyne-services-2.8" ,dezyne-services-2.8)
         ("dzn-client-tarball-2.8" ,dzn-client-tarball-2.8)

         ("dezyne-services-2.4" ,dezyne-services-2.4)
         ;;("dzn-client-tarball-2.4" ,dzn-client-tarball-2.4)

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
                "internal")))))
