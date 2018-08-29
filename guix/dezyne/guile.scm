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

(define-module (dezyne guile)

  #:use-module (gnu packages autotools)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages texinfo)

  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public guile-mingw
  (package
    (inherit guile-2.2)
    (version "2.2.3")
    (name "guile-mingw")
    (source (origin
              (inherit (package-source guile-2.2))
              (uri (string-append "http://git.savannah.gnu.org/cgit/guile.git/snapshot/guile-6d6bc013e1f9db98334e1212295b8be0e39fbf0a.tar.gz"))
              (sha256
               (base32
                "0c1j05gz5kxnxp50h1da6idxq6fiaylx9pqq7mwdiwrb569apvzp"))))
    (native-inputs `(("autoconf" ,autoconf)
                     ("automake" ,automake)
                     ("gettext" ,gettext-minimal)
                     ("libtool" ,libtool)
                     ("flex" ,flex)
                     ("texinfo" ,texinfo)
                     ,@(package-native-inputs guile-2.2)))
    (arguments
     `(#:tests? #f
       ,@(substitute-keyword-arguments (package-arguments guile-2.2)
           ((#:tests? _) #f)
           ((#:phases phases '%standard-phases)
            `(modify-phases ,phases
               ,@(append
                  (if (target-mingw?)
                      '((delete 'sacrifice-elisp-support)
                        (add-after 'bootstrap 'sacrifice-elisp-support
                          (lambda _
                            ;; Cross-compiling language/elisp/boot.el fails, so
                            ;; sacrifice it.  See
                            ;; <https://git.savannah.gnu.org/cgit/guile.git/commit/?h=stable-2.2&id=988aa29238fca862c7e2cb55f15762a69b4c16ce>
                            ;; for the upstream fix.
                            (substitute* "module/Makefile.in"
                              (("language/elisp/boot\\.el")
                               "\n"))
                            #t)))
                      '())
                  '((replace 'bootstrap
                      (lambda _
                        (invoke "sh" "autogen.sh")))
                    (add-before 'bootstrap 'patch-/bin/sh
                      (lambda _
                        (substitute* "build-aux/git-version-gen"
                          (("#!/bin/sh") (string-append "#!" (which "sh"))))
                        #t)))))))))))
