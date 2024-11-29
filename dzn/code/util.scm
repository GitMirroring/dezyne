;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2023 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn code util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn ast ast)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)

  #:export (code:dump
            code:depend-dir
            code:depend-file-name
            code:depend-imports
            code:foreign-conflict?
            code:generate-source?
            code:relative-file-name
            code:root-file-name
            code:source-file-name))

(define (code:source-file-name base dir ext)
  (cond ((equal? dir "-") "-")
        (dir (string-append dir "/" base ext))
        (else (string-append base ext))))

(define (code:root-file-name root dir ext)
  (let ((base (basename (ast:source-file root) ".dzn")))
    (code:source-file-name base dir ext)))

(define (code:depend-dir dir)
  (cond ((equal? dir "-") #f)
        (dir (string-append dir "/.deps"))
        (else ".deps")))

(define (code:depend-file-name root dir)
  (let ((base (basename (ast:source-file root) ".dzn"))
        (dir (code:depend-dir dir)))
    (and dir
         (string-append dir "/" base ".dzn.dep"))))

(define (code:relative-file-name dir file-name)
  (if (or (not dir) (absolute-file-name? file-name)) file-name
      (let* ((dir-components (string-split dir #\/))
             (file-components (string-split file-name #\/))
             (common (common-prefix dir-components file-components #:eq? equal?))
             (file-components (drop file-components (length common)))
             (parent-components (map (const "..") (iota (1- (length file-components)))))
             (file-components (append parent-components file-components)))
        (string-join file-components "/"))))

(define (code:depend-imports root)
  (let* ((imports (ast:import* root))
         (import-files (map .name imports))
         (source-file (ast:source-file root))
         (dir (dirname source-file)))
    (map (cute code:relative-file-name dir <>) import-files)))

(define* (code:dump generate #:key file-name)
  (cond
   ((equal? file-name "-")
    (generate))
   (else
    (mkdir-p (dirname file-name))
    (with-output-to-file file-name
      generate))))

(define-method (code:base-name (o <foreign>))
  (string-join (ast:full-name o) "_"))

(define-method (code:foreign-conflict? (o <root>))
  (let* ((foreigns (filter (conjoin (is? <foreign>)
                                    (negate ast:imported?))
                           (ast:model** o)))
         (foreign-bases (map code:base-name foreigns))
         (conflict? (member (ast:base-name o) foreign-bases)))
    (when conflict?
      ;; XXX TODO: throw / catch
      (format (current-error-port) "cowardly refusing to clobber file with basename: ~a\n"
              (ast:base-name o))
      (exit EXIT_FAILURE))))

(define-method (code:generate-source? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (disjoin (is? <enum>) (is? <component>) (is? <foreign>) (is? <system>)))
        (ast:top** o)))
