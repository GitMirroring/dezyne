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
(define %runtime/c++ (in-vicinity %srcdir "runtime/c++/"))

(define %test-dir "../../")
(define %test-dir/c++ (in-vicinity %test-dir "c++/"))

(define cc-file? (cute string-suffix? ".cc" <>))

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
      '()))

(define includes
  (append (list "-I" "."
                "-I" %runtime/c++
                "-I" %test-dir)
          (if (not (file-exists? %test-dir/c++)) '()
              (list "-I" %test-dir/c++))))

(define cflags
  (list "--std=c++11"))

(define ldflags
  (list "-L" %runtime/c++
        "-Wl,-rpath"
        (string-append "-Wl," (canonicalize-path %runtime/c++))
        "-l" "dzn-c++"
        ;; FIXME: TODO "-l" "boost_coroutine"
        ))

(define libs
  (if (not (getenv "THREAD_POOL_O")) '()
      (list (in-vicinity %runtime/c++ (getenv "THREAD_POOL_O")))))

(define handwritten-sources
  (append (list-files %test-dir cc-file?)
          (if (not (file-exists? %test-dir/c++)) '()
              (list-files %test-dir/c++ cc-file?))))

(define (handwritten-override? file)
  (find (compose (cute equal? <> (basename file)) basename)
        (map basename handwritten-sources)))

(define +sources+
  (let* ((generated (list-files "." cc-file?))
         (keep (filter (negate handwritten-override?) generated)))
    (append handwritten-sources
            keep)))

(define test
  (c-binary
   (toolchain #%~#%?CXX)
   (inputs +sources+)
   (cppflags (append includes
                     warn-flags
                     no-warn-flags))
   (cflags cflags)
   (ldflags ldflags)
   (libs libs)
   (outputs "test")))

(blueprint
 (configuration %cxx-configuration)
 (buildables (list test)))
