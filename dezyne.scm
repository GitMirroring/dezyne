;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dezyne)
  #:use-module (guix licenses)

  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix utils)

  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages ccache)  
  #:use-module (gnu packages compression)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages java)  
  #:use-module (gnu packages markdown)
  #:use-module (gnu packages node)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xml)
  )

(define-public guile-lib-next
  (package (inherit guile-lib)
    (name "guile-lib-next")
    (version "0.2.2")
    (inputs `(("guile" ,guile-next)))
    (native-inputs
     `(("guile" ,guile-next)))
    (arguments
     (append (substitute-keyword-arguments
                 `(#:tests? #f
                            ,@(package-arguments guile-lib)))))))

(define-public fdr2
  (package
    (name "fdr2")
    (version "2.94-academic")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.cs.ox.ac.uk/projects/concurrency-tools/download/fdr-" version "-linux64.tar.gz"))
              (sha256
               (base32
		"0yrdbhavp8bi82jmi0praqn763z9i12kgyxyrahibnpn0xg3y4r6"))))
    (native-inputs
     `(("source" ,source)
       ("tar" ,tar)
       ("gzip" ,gzip)))
   (native-search-paths
    (list (search-path-specification
           (variable "FDRHOME")
	   (files '("/")))))
    (outputs '("out"))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((tar  (assoc-ref %build-inputs "tar"))
               (gzip (assoc-ref %build-inputs "gzip"))
               (out  (assoc-ref %outputs "out")))
           (setenv "PATH" (string-append tar "/bin:" gzip "/bin"))
           (system* "tar" "xvf" (assoc-ref %build-inputs "source"))
           (chdir (string-append "fdr-" ,version "-linux64"))
           (copy-recursively "lib" (string-append out "/lib"))
           (copy-recursively "bin" (string-append out "/bin"))
	   (copy-recursively "bin.linux64" (string-append out "/bin.linux64"))
	   (copy-recursively "demo"  (string-append out "/demo"))
	   (copy-recursively "scripts"  (string-append out "/scripts"))))))
    (synopsis "fdr")
    (description "FDR (Failures-Divergence Refinement) is a model-checking tool for state machines, with foundations in the theory of concurrency based around CSP—Hoare’s Communicating Sequential Processes [Hoare85]. Its method of establishing whether a property holds is to test for the refinement of a transition system capturing the property by the candidate machine. There is also the ability to check determinism of a state machine, and this is used primarily for checking security properties [Roscoe95], [RosWood94]. The main ideas behind FDR are presented in [Roscoe94] and some applications are presented in [Roscoe97]")
    (home-page "https://www.cs.ox.ac.uk/projects/concurrency-tools/")
    (license ((@@ (guix licenses) license)
	      "academic use"
	      "https://www.cs.ox.ac.uk/projects/concurrency-tools/"
	       "academic"))))

(define-public dezyne-server
  (package
    (name "dezyne-server")
    (version "1.2.2") ;; TODO
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    ;;(url "git://git.oban:~buildmaster/development.git")
		    (url "git://localhost/home/janneke/development.git")
                    (commit "master")
		    ;;(branch "master")
		    ))
              (sha256
               (base32
                ;;"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
		"0s1jsfi4dpig5qcjvqp187yzxym80blbwqpf1b8llmwnivqb860c"
		))))
    (build-system gnu-build-system)
    (inputs `(
	      ("bash" ,bash)
	      ("boost" ,boost)
	      ("guile" ,guile-next)
	      ("expat" ,expat)
	      ("fdr2" ,fdr2)
	      ("java" ,icedtea-7)
	      ("node" ,node)
	      ("guile-lib" ,guile-lib-next)
	      ;;("postgresql" ,postgresql)
	      ("webkitgtk-gtk2" ,webkitgtk/gtk+-2)
	      ))

    (native-inputs `(
		     ("bison" ,bison)
		     ("ccache" ,ccache)
		     ("guile" ,guile-next)
		     ("flex" ,flex)
		     ("jdk" ,icedtea-7 "jdk")
		     ("markdown" ,markdown)
		     ("node" ,node)
		     ;;("postgresql" ,postgresql)
		     ("pkgconfig" ,pkg-config)
		     ))


    (outputs '("out" "debug"))

    (arguments `(#:phases (alist-delete 'install %standard-phases)))

    (native-search-paths
     '()
     ;; (list (search-path-specification
     ;;        (variable "GUILE_LOAD_PATH")
     ;;        (files '("share/guile/site/2.0")))
     ;;       (search-path-specification
     ;;        (variable "GUILE_LOAD_COMPILED_PATH")
     ;;        (files '("lib/guile/2.0/ccache"
     ;;                 "share/guile/site/2.0"))))
     )

    (synopsis "Dezyne")
    (description "boo")
    (home-page "http://www.verum.com")
    (license ((@@ (guix licenses) license)
	      "proprietary"
	      "http://verum.com"
	       "internal"))))
