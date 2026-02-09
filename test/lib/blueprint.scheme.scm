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
             (blue stencils guile)
             (blue stencils template-file)
             (blue types blueprint)
	     (blue types configuration)
  	     (blue types variable)
	     (blue utils hash)

             (dzn misc)
             (dzn shell-util))

(define %srcdir "../../../../../")
(define %runtime/scheme (in-vicinity %srcdir "runtime/scheme/"))

(define %test-dir "../../")
(define %test-dir/scheme (in-vicinity %test-dir "scheme/"))

(define scheme-file? (cute string-suffix? ".scm" <>))

(define handwritten-sources
  (append (list-files %test-dir scheme-file?)
          (if (not (file-exists? %test-dir/scheme)) '()
              (list-files %test-dir/scheme scheme-file?))))

(define (handwritten-override? file)
  (find (compose (cute equal? <> (basename file)) basename)
        (map basename handwritten-sources)))

(define +sources+
  (let* ((generated (list-files "." scheme-file?))
         (keep (filter (negate handwritten-override?) generated)))
    (append handwritten-sources
            keep)))

(define* (scm->go source #:key (enabled? #t))
  (guile-module
   (inputs (list source))
   (outputs (->.go source))
   (enabled? enabled?)
   (load-path (append (list %srcdir
                            %runtime/scheme
                            %test-dir
                            ".")
                      (if (not (file-exists? %test-dir/scheme)) '()
                          (list %test-dir/scheme))))
   (install-location "/dev/null")      ;FIXME: never gonna be installed!
   (install-source-location "/dev/null"))) ;FIXME: never gonna be installed!

(define +modules+
  (map scm->go +sources+))

(define test
  (template-file
   (inputs (list (in-vicinity %srcdir "/test/lib/test.scm")))
   (outputs "test")
   (install-location "/dev/null")      ;FIXME: never gonna be installed!
   (mode #o755)
   (regexp "@([a-zA-Z_-]+)@")))

(blueprint
 (configuration (merge-configuration
                 (configuration
                  (variables
                   (list
                    (variable
                     (name "OUT")
                     (value (getcwd))))))
                 %guile-configuration
                 'first))
 (buildables (cons test +modules+)))
