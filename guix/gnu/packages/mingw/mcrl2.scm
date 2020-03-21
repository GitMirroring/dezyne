;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019,2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gnu packages mingw mcrl2)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages mingw boost)
  #:use-module (gnu packages mcrl2))

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
           (add-before 'configure 'setenv
             (lambda _
               (let ((gcc (assoc-ref %build-inputs "cross-gcc"))
                     (libc (assoc-ref %build-inputs "cross-libc")))
                 (setenv "CROSS_CPLUS_INCLUDE_PATH"
                         (string-append gcc "/include/c++"
                                        ":" gcc "/include"
                                        ":" libc "/include"))
                 (format #t "environment variable `CROSS_CPLUS_INCLUDE_PATH' set to `~a'\n" (getenv "CROSS_CPLUS_INCLUDE_PATH"))
                 #t)))
           (delete 'install-dparser)))))))
