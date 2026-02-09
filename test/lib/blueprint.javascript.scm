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

             (ice-9 rdelim)

             (blue build)
             (blue stencils copy-file)
             (blue types blueprint)
	     (blue types configuration)
  	     (blue types variable)
	     (blue utils hash)

             (dzn misc)
             (dzn shell-util))

(define %srcdir "../../../../../")
(define %runtime/javascript (in-vicinity %srcdir "runtime/javascript/"))
(define %runtime/javascript/dzn (in-vicinity %runtime/javascript "dzn"))

(define %test-dir "../../")
(define %test-dir/javascript (in-vicinity %test-dir "javascript/"))

(define javascript-file? (cute string-suffix? ".js" <>))

(define runtime-js-files
  (list-files %runtime/javascript/dzn javascript-file?))

(define handwritten-sources
  (append (list-files %test-dir javascript-file?)
          (if (not (file-exists? %test-dir/javascript)) '()
              (list-files %test-dir/javascript javascript-file?))))

(define (handwritten-override? file)
  (find (compose (cute equal? <> (basename file)) basename)
        (map basename handwritten-sources)))

(define +sources+
  (let* ((generated (list-files "." javascript-file?))
         (keep (filter (negate handwritten-override?) generated)))
    (append handwritten-sources
            keep)))

(define main.js
  (or (file-exists? (in-vicinity %test-dir "main.js"))
      (file-exists? (in-vicinity %test-dir/javascript "main.js"))
      "main.js"))

(define* (src->dest src #:key (dir ".") (dest (in-vicinity dir (basename src))))
  (copy-file
   (inputs src)
   (outputs dest)))

(define +files+
  (append
   (list (src->dest main.js #:dest "test"))
   (map src->dest handwritten-sources)
   (map (cute src->dest <> #:dir "dzn") runtime-js-files)))

(blueprint
 (configuration (configuration))
 (buildables +files+))
