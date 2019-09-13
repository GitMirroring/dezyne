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

(define-module (gnu packages guile-mingw)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages mingw)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages texinfo))

(define-public guile-mingw
  (let ((commit "6d6bc013e1f9db98334e1212295b8be0e39fbf0a")
        (revision "0"))
    (package
      (inherit guile-2.2)
      (name "guile-mingw")
      ;;(version (string-append (package-version guile-2.2) "-" revision "." (string-take commit 7)))
      (version (string-append "2.2.3" "-" revision "." (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://git.savannah.gnu.org/git/guile.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "1f3dl663y2l6ala6hslwv9j6pycqpb3zp2bb85vyyw5zrchb26rh"))))
      (native-inputs
       `(("autoconf" ,autoconf)
         ("automake" ,automake)
         ("libtool" ,libtool)
         ("flex" ,flex)
         ("texinfo" ,texinfo)
         ("gettext" ,gettext-minimal)
         ,@(package-native-inputs guile-2.2)))
      (arguments
       `(#:tests? #f
         ,@(if (%current-target-system)
               (substitute-keyword-arguments (package-arguments guile-2.2)
                 ((#:phases phases '%standard-phases)
                  `(modify-phases ,phases
                     (replace 'bootstrap
                       (lambda _
                         (invoke "sh" "autogen.sh")
                         #t))
                     ;; configure: error: building Guile UNKNOWN but `/gnu/store/9alic3caqhay3h8mx4iihpmyj6ymqpcx-guile-2.2.4/bin/guile' has version 2.2.4"
                     (add-after 'unpack 'patch-version-gen
                       (lambda _
                         (setenv "ac_cv_guile_for_build_version" "2.2.3")
                         (substitute* "configure.ac"
                           (("git-version-gen --match") "git-version-gen --fallback 2.2.3 --match"))
                         ;; (substitute* "acinclude.m4"
                         ;;   (("if test \"[$]ac_cv_guile_for_build_version\"" all)
                         ;;    (string-append "set -x; " all)))
                         (substitute* "build-aux/git-version-gen"
                           (("#!/bin/sh") (string-append "#! " (which "sh"))))
                         #t))
                     (replace 'sacrifice-elisp-support
                       (lambda _
                         ;; Cross-compiling language/elisp/boot.el fails, so
                         ;; sacrifice it.  See
                         ;; <https://git.savannah.gnu.org/cgit/guile.git/commit/?h=stable-2.2&id=988aa29238fca862c7e2cb55f15762a69b4c16ce>
                         ;; for the upstream fix.
                         (substitute* "module/Makefile.am"
                           (("ELISP_SOURCES =.*") "ELISP_SOURCES =\n")
                           ((" *language/elisp/boot\\.el") ""))
                         #t)))))
               (package-arguments guile-2.2)))))))

(define-public guile-json-mingw
  (package
    (inherit guile-json)
    (name "guile-json-mingw")
    (inputs `(("guile" ,guile-mingw)))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("guile-for-build" ,guile-2.2)))))
