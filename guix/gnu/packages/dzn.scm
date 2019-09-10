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
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages perl)
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
                     ("libtool" ,libtool)
                     ("perl" ,perl)
                     ("pkg-config" ,pkg-config)
                     ("zip" ,zip)))   ; for guix environment -l guix.scm
    (propagated-inputs `(("guile-json" ,guile-json)))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((ice-9 popen)
                  ,@%gnu-build-system-modules)
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'setenv
           (lambda _
             (setenv "GUILE_AUTO_COMPILE" "0")
             (setenv "V" "2"))))))
    (synopsis "Dezyne command line tools")
    (description "Dezyne command line tools")
    (home-page "https://verum.com")
    (license license:gpl3+)))
