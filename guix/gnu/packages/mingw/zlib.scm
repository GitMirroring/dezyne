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

(define-module (gnu packages mingw zlib)
  #:use-module (gnu packages compression)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public zlib-mingw
  (package
    (inherit zlib)
    (name "zlib-mingw")
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
             '())))))
