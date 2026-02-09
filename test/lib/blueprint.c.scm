;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2026 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(use-modules (srfi srfi-1)
             (srfi srfi-26)

             (blue build)
             (blue file-system find)
             (blue stencils c)
             (blue types blueprint)
	     (blue types configuration)
  	     (blue types variable)
	     (blue utils hash)

             (dzn misc)
             (dzn shell-util))

(define %srcdir "../../../../../")
(define %runtime/c (in-vicinity %srcdir "runtime/c/"))

(define %test-dir "../../")
(define %test-dir/c (in-vicinity %test-dir "c/"))

(define c-file? (cute string-suffix? ".c" <>))

(define warn-flags
  (or (and=> (getenv "WARN_FLAGS")
             (compose (cute filter (negate string-null?) <>)
                      (cute string-split <> #\space)))
      '("-Wall"
        "-Wextra"
        "-Werror")))

(define no-warn-flags
  (or (and=> (getenv "NOWARN_FLAGS")
             (compose (cute filter (negate string-null?) <>)
                      (cute string-split <> #\space)))
      '("-Wno-error=parentheses"
        "-Wno-error=unused-but-set-variable"
        "-Wno-error=unused-function"
        "-Wno-error=unused-parameter"
        "-Wno-error=unused-variable")))

(define includes
  (append (list "-I" "."
                "-I" %runtime/c
                "-I" %test-dir)
          (if (not (file-exists? %test-dir/c)) '()
              (list "-I" %test-dir/c))))

(define cflags '())

(define ldflags
  (list "-L" %runtime/c
        "-Wl,-rpath"
        (string-append "-Wl," (canonicalize-path %runtime/c))
        "-l" "dzn-c"
        ;; FIXME: TODO "-l" #%?libpth
        ))

(define libs '())

(define handwritten-sources
  (append (list-files %test-dir c-file?)
          (if (not (file-exists? %test-dir/c)) '()
              (list-files %test-dir/c c-file?))))

(define (handwritten-override? file)
  (find (compose (cute equal? <> (basename file)) basename)
        (map basename handwritten-sources)))

(define +sources+
  (let* ((generated (list-files "." c-file?))
         (keep (filter (negate handwritten-override?) generated)))
    (append handwritten-sources
            keep)))

(define test
  (c-binary
   (toolchain #%~#%?CC)
   (inputs +sources+)
   (cppflags (append includes
                     warn-flags
                     no-warn-flags))
   (cflags cflags)
   (ldflags ldflags)
   (libs libs)
   (outputs "test")))

(blueprint
 (configuration %c-configuration)
 (buildables (list test)))
