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

(define-module (gnu packages mcrl2)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages cross-base)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages mingw))

(define-public mcrl2-patched
  (package
    (inherit mcrl2)
    (name "mcrl2-patched")
    (source
      (origin
        (inherit (package-source mcrl2))
        (patches (search-patches "mcrl2.patch"))))))

(define-public mcrl2-minimal-patched
  (package
    (inherit mcrl2-minimal)
    (name "mcrl2-minimal-patched")
    (source (package-source mcrl2-patched))))

(define-public mcrl2-minimal-with-dparser
  (package
    (inherit mcrl2-minimal-patched)
    (name "mcrl2-minimal-with-dparser")
    (arguments
     (substitute-keyword-arguments (package-arguments mcrl2-minimal-patched)
       ((#:phases phases '%standard-phases)
        `(modify-phases ,phases
           (add-after 'install 'install-dparser
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (let ((out (assoc-ref outputs "out")))
                 (copy-file "stage/bin/make_dparser" (string-append out "/bin/make_dparser"))
                 #t)))))))))

(define-public mcrl2-minimal-mingw
  (package
    (inherit mcrl2-minimal-patched)
    (name "mcrl2-minimal-mingw")
    (inputs `(("boost" ,boost-mingw)))
    (native-inputs `(("mcrl2" ,mcrl2-minimal-with-dparser)))
    (arguments
     (substitute-keyword-arguments (package-arguments mcrl2-minimal-patched)
       ((#:configure-flags flags)
        `(cons*
          (string-append "-DBoost_INCLUDE_DIR:PATH=" (assoc-ref %build-inputs "boost") "/include")
          "-DCMAKE_BUILD_TYPE:STRING=MinSizeRel"
          "-DBUILD_SHARED_LIBS:STRING=ON"
          "-DHAS_CXX11_AUTO:INTERNAL=TRUE"
          "-DHAS_CXX11_AUTO_RET_TYPE:INTERNAL=TRUE"
          "-DHAS_CXX11_BIND:INTERNAL=TRUE"
          "-DHAS_CXX11_CLASS_OVERRIDE_FINAL:INTERNAL=TRUE"
          "-DHAS_CXX11___FUNC__:INTERNAL=TRUE"
          "-DHAS_CXX11_ADD_REFERENCE:INTERNAL=TRUE"
          "-DHAS_CXX11_CONSTEXPR:INTERNAL=TRUE"
          "-DHAS_CXX11_CSTDINT:INTERNAL=TRUE"
          "-DHAS_CXX11_DECLTYPE:INTERNAL=TRUE"
          "-DHAS_CXX11_DELETE:INTERNAL=TRUE"
          "-DHAS_CXX11_ENABLE_IF:INTERNAL=TRUE"
          "-DHAS_CXX11_INITIALIZER_LIST:INTERNAL=TRUE"
          "-DHAS_CXX11_IS_BASE_OF:INTERNAL=TRUE"
          "-DHAS_CXX11_IS_CONVERTIBLE:INTERNAL=TRUE"
          "-DHAS_CXX11_IS_INTEGRAL:INTERNAL=TRUE"
          "-DHAS_CXX11_IS_SORTED:INTERNAL=TRUE"
          "-DHAS_CXX11_INTEGRAL_CONSTANT:INTERNAL=TRUE"
          "-DHAS_CXX11_LAMBDA:INTERNAL=TRUE"
          "-DHAS_CXX11_LONG_LONG:INTERNAL=TRUE"
          "-DHAS_CXX11_MAKE_UNSIGNED:INTERNAL=TRUE"
          "-DHAS_CXX11_NEXT:INTERNAL=TRUE"
          "-DHAS_CXX11_NOEXCEPT:INTERNAL=TRUE"
          "-DHAS_CXX11_NULLPTR:INTERNAL=TRUE"
          "-DHAS_CXX11_RANGE-BASED-FOR:INTERNAL=TRUE"
          "-DHAS_CXX11_REF:INTERNAL=TRUE"
          "-DHAS_CXX11_REGEX:INTERNAL=TRUE"
          "-DHAS_CXX11_REMOVE_CONST:INTERNAL=TRUE"
          "-DHAS_CXX11_REMOVE_REFERENCE:INTERNAL=TRUE"
          "-DHAS_CXX11_RVALUE-REFERENCES:INTERNAL=TRUE"
          "-DHAS_CXX11_SIZEOF_MEMBER:INTERNAL=TRUE"
          "-DHAS_CXX11_STATIC_ASSERT:INTERNAL=TRUE"
          "-DHAS_CXX11_TO_STRING:INTERNAL=TRUE"
          "-DHAS_CXX11_UNARY_FUNCTION:INTERNAL=TRUE"
          "-DHAS_CXX11_UNIQUE_PTR:INTERNAL=TRUE"
          "-DHAS_CXX11_UNORDERED_SET:INTERNAL=TRUE"
          "-DHAS_CXX11_VARIADIC_TEMPLATES:INTERNAL=TRUE"
          ,flags))
      ((#:phases phases '%standard-phases)
       `(modify-phases ,phases
          (add-before 'configure 'fixups
              (lambda _
                (substitute* "build/packaging/CMakeLists.txt"
                  (("if [(]WIN32[)]") "if (0)"))
                #t))
          (delete 'install-dparser)))))))

(define-public boost-mingw
  (package
    (inherit boost)
    (name "boost-mingw")
    (inputs '())
    (arguments
     (substitute-keyword-arguments
      (package-arguments boost)
      ((#:phases phases '%standard-phases)
       `(modify-phases ,phases
          (replace 'configure
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let ((icu (assoc-ref inputs "icu4c"))
                    (out (assoc-ref outputs "out")))
                (substitute* '("libs/config/configure"
                               "libs/spirit/classic/phoenix/test/runtest.sh"
                               "tools/build/src/engine/execunix.c"
                               "tools/build/src/engine/Jambase"
                               "tools/build/src/engine/jambase.c")
                             (("/bin/sh") (which "sh")))

                (setenv "SHELL" (which "sh"))
                (setenv "CONFIG_SHELL" (which "sh"))

                (invoke "./bootstrap.sh"
                        (string-append "--prefix=" out)
                        (if icu (string-append "--with-icu=" icu) "")
                        "--with-toolset=gcc"))))))))))

;; Taken from https://debbugs.gnu.org/cgi/bugreport.cgi?bug=37027
(define-public zlib-mingw
  (package
    (name "zlib-mingw")
    (version "1.2.11")
    (source
     (origin
      (method url-fetch)
      (uri (list (string-append "http://zlib.net/zlib-"
                                 version ".tar.gz")
                 (string-append "mirror://sourceforge/libpng/zlib/"
                                version "/zlib-" version ".tar.gz")))
      (sha256
       (base32
        "18dighcs333gsvajvvgqp8l4cx7h1x7yx9gd5xacnk80spyykrf3"))))
    (build-system gnu-build-system)
    (outputs '("out" "static"))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         ,@(if (target-mingw?)
               `((delete 'configure)
                 (add-before 'install 'set-install-paths
                             (lambda* (#:key outputs #:allow-other-keys)
                               (let ((out (assoc-ref outputs "out")))
                                 (setenv "INCLUDE_PATH" (string-append out "/include"))
                                 (setenv "LIBRARY_PATH" (string-append out "/lib"))
                                 (setenv "BINARY_PATH" (string-append out "/bin"))
                                 #t))))
               `((replace 'configure
                          (lambda* (#:key outputs #:allow-other-keys)
                            ;; Zlib's home-made `configure' fails when passed
                            ;; extra flags like `--enable-fast-install', so we need to
                            ;; invoke it with just what it understand.
                            (let ((out (assoc-ref outputs "out")))
                              ;; 'configure' doesn't understand '--host'.
                              ,@(if (%current-target-system)
                                    `((setenv "CHOST" ,(%current-target-system)))
                                    '())
                              (invoke "./configure"
                                      (string-append "--prefix=" out)))))))
         (add-after 'install 'move-static-library
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let ((out (assoc-ref outputs "out"))
                            (static (assoc-ref outputs "static")))
                        (with-directory-excursion (string-append out "/lib")
                                                  (install-file "libz.a" (string-append static "/lib"))
                                                  (delete-file "libz.a")
                                                  #t)))))
       ,@(if (target-mingw?)
             `(#:make-flags
               '("-fwin32/Makefile.gcc"
                 "SHARED_MODE=1"
                 ,(string-append "CC=" (%current-target-system) "-gcc")
                 ,(string-append "RC=" (%current-target-system) "-windres")
                 ,(string-append "AR=" (%current-target-system) "-ar")))
             '())))
    (home-page "https://zlib.net/")
    (synopsis "Compression library")
    (description
     "zlib is designed to be a free, general-purpose, legally unencumbered --
that is, not covered by any patents -- lossless data-compression library for
use on virtually any computer hardware and operating system.  The zlib data
format is itself portable across platforms.  Unlike the LZW compression method
used in Unix compress(1) and in the GIF image format, the compression method
currently used in zlib essentially never expands the data. (LZW can double or
triple the file size in extreme cases.)  zlib's memory footprint is also
independent of the input data and can be reduced, if necessary, at some cost
in compression.")
    (license license:zlib)))

(define-public xgcc-sans-libc-x86_64-w64-mingw32
  (let ((triplet "x86_64-w64-mingw32"))
    (cross-gcc triplet
               #:xbinutils (cross-binutils triplet))))

(define-public xbinutils-x86_64-w64-mingw32
  (let ((triplet "x86_64-w64-mingw32"))
    (cross-binutils triplet)))

(define-public xgcc-x86_64-w64-mingw32
  (let ((triplet "x86_64-w64-mingw32"))
    (cross-gcc triplet
                     #:xbinutils (cross-binutils triplet)
                     #:libc mingw-w64-x86_64)))
