;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dezyne server)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages guile)

  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)

  #:use-module (guix packages)

  #:use-module (dezyne config)
  #:use-module (dezyne extra)
  #:use-module (dezyne services))

(define-public dezyne-server
  (package
   (name "dezyne-server")
   (version "development")
   (source dezyne-source-development)
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
