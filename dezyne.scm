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
  #:use-module (ice-9 optargs)

  #:use-module (srfi srfi-1)

  #:use-module (guix build utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix utils)

  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages ccache)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages java)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages markdown)
  #:use-module (gnu packages node)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages w3m)

  #:export (patch-source-shebangs-no-symlinks)
  )

(define-public guile-next-lib
  (package (inherit guile-lib)
    (name "guile-next-lib")
    (version "0.2.2")
    (inputs `(("guile" ,guile-next)))
    (arguments
     (append (substitute-keyword-arguments
              `(#:tests? #f ;; 2 tests still fail
                ,@(package-arguments guile-lib)))))))

(define-public tcllib
  (package
    (name "tcllib")
    (version "1.18")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/" name "/"
                                  name "-" version ".tar.gz"))
              (sha256
               (base32
                "05dmrk9qsryah2n17z6z85dj9l9lfyvnsd7faw0p9bs1pp5pwrkj"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("tcl" ,tcl)))
    (native-search-paths
     (list (search-path-specification
	    (variable "TCLLIBPATH")
	    (separator " ")
	    (files (list (string-append "lib/tcllib" version ""))))))
    (home-page "https://core.tcl.tk/tcllib/home")
    (synopsis "Standard Tcl Library")
    (description "Tcllib, the standard Tcl library, is a collection of common utility
 functions and modules all written in high-level Tcl.
")
    (license (non-copyleft "http://www.tcl.tk/software/tcltk/license.html"
			   "Tcl/Tk license"))))


(define-public tclxml
  (package
    (name "tclxml")
    (version "3.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/" name "/"
                                  name "-" version ".tar.gz"))
              (sha256
               (base32
                "0ffb4aw63inig3aql33g4pk0kjk14dv238anp1scwjdjh1k6n4gl"))
	      (patches (list (search-patch (string-append (getenv "HOME") "/development.git/tclxml-3.2-install.patch"))))))
    (build-system gnu-build-system)
    (native-inputs
     `(("tcl" ,tcl)
       ("tcllib" ,tcllib)
       ("libxml2" ,libxml2)
       ("libxslt" ,libxslt)))
   (native-search-paths
    (list (search-path-specification
           (variable "TCLLIBPATH")
	   (separator " ")
	   (files (list (string-append "lib/Tclxml" version))))))
   (arguments
    `(#:configure-flags
      (list (string-append "--with-tclconfig="
			   (assoc-ref %build-inputs "tcl")
			   "/lib")
	    (string-append "--with-xml2-config="
			   (assoc-ref %build-inputs "libxml2")
			   "/bin/xml2-config")
	    (string-append "--with-xslt-config="
			   (assoc-ref %build-inputs "libxslt")
			   "/bin/xslt-config"))
      #:phases (modify-phases %standard-phases
                 (delete 'check))))
    (home-page "http://tclxml.sourceforge.net/")
    (synopsis " Tcl library for XML parsing")
    (description " TclXML provides event-based parsing of XML documents.  The
 application may register callback scripts for certain document
 features, and when the parser encounters those features while parsing
 the document the callback is evaluated.")
    (license (non-copyleft "http://www.tcl.tk/software/tcltk/license.html"
			   "Tcl/Tk license"))))

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

(define* (configure #:key outputs make-maker? #:allow-other-keys)
  "Configure the given Perl package."
  (let* ((out (assoc-ref outputs "out")))
    (zero? (apply system* "sh"))))

(define (file-is-symlink? file)
  (and (file-exists? file)
       (eq? 'symlink (stat:type (lstat file)))))

(define* (patch-source-shebangs-no-symlinks #:key source #:allow-other-keys)
  "Patch shebangs in all source files; this includes non-executable
files such as `.in' templates.  Most scripts honor $SHELL and
$CONFIG_SHELL, but some don't, such as `mkinstalldirs' or Automake's
`missing' script."
  (for-each patch-shebang
            (remove (lambda (file)
                      (or (not (file-exists? file)) ;dangling symlink
                          (file-is-symlink? file)
                          (file-is-directory? file)))
                    (find-files "."))))

(define-public dezyne-server
  (package
    (name "dezyne-server")
    (version "1.2.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
    		    "http://git.oban/" name "-" version ".tar.xz"))
              (sha256
               (base32
    		"1d4hg0xdqsby8bwwy1hc9ygja2sads32fxssi89bbzxg51al13xs"))))
    (build-system gnu-build-system)
    (inputs `(
	      ("bash" ,bash)
	      ("boost" ,boost)
	      ("expat" ,expat)
	      ("fdr2" ,fdr2)
	      ("graphviz" ,graphviz)
	      ("guile" ,guile-next)
	      ("guile-lib" ,guile-next-lib)
	      ("gtkmm" ,gtkmm)
	      ("java" ,icedtea-7)
	      ("node" ,node)
	      ("postgresql" ,postgresql)
	      ("python" ,python-2)
	      ("webkitgtk-gtk2" ,webkitgtk/gtk+-2)
	      ))

    (native-inputs `(
		     ("bash" ,bash)
		     ("bison" ,bison)
		     ("guile" ,guile-next)
		     ("guile-lib" ,guile-next-lib)
		     ("flex" ,flex)
		     ("jdk" ,icedtea-7 "jdk")
		     ("markdown" ,markdown)
		     ("node" ,node)
		     ("perl" ,perl)
		     ("pkgconfig" ,pkg-config)
		     ("postgresql" ,postgresql)
		     ("procps" ,procps)
		     ("python" ,python-2)
		     ("tcl" ,tcl)
		     ("tcllib" ,tcllib)
		     ("tclxml" ,tclxml)
		     ("w3m" ,w3m)
		     ))


    (outputs '("out" "debug"))

    (arguments `(#:modules ((srfi srfi-1)
			    ,@%gnu-build-system-modules)
		 #:phases
		 (modify-phases %standard-phases
		   (delete 'install)
		   (add-before
		    'configure 'setenv
		    (lambda _
		      (setenv "TCLLIBPATH"
			      (string-append (assoc-ref %build-inputs "tcllib")
					     "/lib/tcllib1.18 "
					     (assoc-ref %build-inputs "tclxml")
					     "/lib/Tclxml3.2 "
					     (getenv "TCLLIBPATH")))
		      (setenv "GUILE_AUTO_COMPILE" "0")))
		   (replace 'patch-source-shebangs
		   	    ;;patch-source-shebangs-no-symlinks
		   	    (lambda* (#:key outputs #:allow-other-keys)
		   	      (for-each patch-shebang
		   	    		(remove (lambda (file)
		   	    			  (or (not (file-exists? file)) ;dangling symlink
		   	    			      ;;(file-is-symlink? file)
						      (and (file-exists? file)
							   (eq? 'symlink (stat:type (lstat file))))
		   	    			      (file-is-directory? file)))
		   	    			(find-files ".")))))
		   (replace 'configure
			    (lambda* (#:key outputs #:allow-other-keys)
			      (let* ((out (assoc-ref outputs "out")))
				(zero? (system* "./configure"))))))))

    (synopsis "Dezyne")
    (description "boo")
    (home-page "http://www.verum.com")
    (license ((@@ (guix licenses) license)
	      "proprietary"
	      "http://verum.com"
	       "internal"))))
