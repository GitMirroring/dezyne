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

(define-module (dezyne v2.8 server)

  #:use-module (gnu packages bash)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages guile)

  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)

  #:use-module (guix packages)

  #:use-module (dezyne config)
  #:use-module (dezyne extra)
  #:use-module (dezyne v2.8 services))

(define-public dezyne-server-11
  (let ((version "11"))
    (package
      (name "dezyne-server")
      (version version)
      (source dezyne-source-2.8)
      (build-system gnu-build-system)
      (propagated-inputs `(("node" ,node6)
                           ("postgresql" ,postgresql)
                           ("node-snapshot" ,node-snapshot)))
      (native-inputs `(("dezyne-services" ,dezyne-services-2.8)
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
         #:make-flags `("server" "dzn-daemon")
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
               (let* ((out (assoc-ref outputs "out"))
                      (version (last (string-split out #\-)))
                      (tarball (string-append "dzn-daemon-0.0." version ".tar.gz"))
                      (etc (string-append out "/etc"))
                      (download-dir (string-append out "/root/download/npm")))
                 (system* "make" "node-dzn-daemon")
                 (mkdir-p download-dir)
                 (copy-file (string-append "build/" tarball)
                            (string-append download-dir "/" tarball))
                 (zero? (system* "make" "install-server" "DESTDIR="
                                 (string-append "PREFIX=" out)))))))))
      (synopsis "Dezyne server")
      (description "Dezyne is a component-based model-driven software
development environment.")
      (home-page "http://www.verum.com")
      (license ((@@ (guix licenses) license)
                "proprietary"
                "http://verum.com"
                "internal")))))

(define-public dzn-daemon-tarball-11
  (package
    (name "dzn-daemon-tarball")
    (version "11")
    (source #f)
    (native-inputs `(("dezyne-server" ,dezyne-server-11)))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:modules ((srfi srfi-1)
                  ,@%gnu-build-system-modules)
       #:phases
       (modify-phases %standard-phases
         (delete 'unpack)
         (delete 'configure)
         (delete 'build)
         (delete 'validate-runpath)
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (version (last (string-split out #\-)))
                    (server (assoc-ref %build-inputs "dezyne-server"))
                    (tarball (string-append "dzn-daemon-0.0." version ".tar.gz"))
                    (download-dir "root/download/npm")
                    (dest (string-append out "/" download-dir "/" tarball)))
               (mkdir-p (string-append out "/" download-dir))
               (copy-file (string-append server "/" download-dir "/" tarball)
                          dest)
               (chmod dest #o644)))))))
    (synopsis "dzn daemon")
    (description "dzn daemon")
    (home-page "https://hosting.verum.com/download/npm")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))

(define-public node-dzn-daemon-11
  (package
    (name "node-dzn-daemon")
    (version "0.0.11")
    (source #f)
    (native-inputs `(("dzn-daemon-tarball" ,dzn-daemon-tarball-11)))
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
               (unpack #:source (string-append (assoc-ref %build-inputs "dzn-daemon-tarball")
                                               "/root/download/npm/dzn-daemon" "-"
                                               version
                                               ".tar.gz")))))
         (delete 'configure)
         (delete 'build)
         (delete 'validate-runpath)
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (node-modules (string-append out "/lib/node_modules/dzn-daemon"))
                    (bin (string-append out "/bin")))
               (mkdir-p node-modules)
               (copy-recursively "." node-modules)
               (mkdir-p bin)
               (symlink (string-append node-modules "/bin/daemon") (string-append bin "/daemon"))))))))
    (synopsis "dzn daemon")
    (description "dzn daemon")
    (home-page "https://hosting.verum.com/download/npm")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))
