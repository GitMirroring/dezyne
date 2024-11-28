;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2021, 2023, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
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

(define-module (dzn code language c++)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (scmackerel indent)

  #:use-module (dzn ast ast)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code scmackerel c++)
  #:use-module (dzn code util)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:export (c++:ref
            c++:capture-name))

;;;
;;; Accessors.
;;;
(define-method (c++:capture-name (o <variable>) (d <defer>))
  (simple-format #f "~a_~a" (code:capture-name o) (.offset (.location d))))

(define-method (c++:generate-source? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (disjoin (is? <enum>)
                          (is? <interface>) ;; no inline (yet??)
                          (is? <foreign>)   ;; no inline (yet??
                          (is? <component>)
                          (is? <system>)))
        (ast:top** o)))

(define-method (c++:ref (o <string>))
  (string-append "&" o))


;;;
;;; Entry point.
;;;
(define* (ast-> root #:key (dir ".") empty-files? model verbose?)
  "Entry point."

  (code:foreign-conflict? root)

  (let* ((root (code:normalize root))
         (depend-dir (code:depend-dir dir)))
    (when depend-dir
      (mkdir-p depend-dir))
    (let ((depend (and depend-dir
                       (open-output-file (code:depend-file-name root dir))))
          (generator (sm:indenter (cute print-header-ast root)))
          (header-file-name (code:root-file-name root dir ".hh"))
          (source-file-name (code:root-file-name root dir ".cc")))
      (when depend-dir
        (let* ((import-files (code:depend-imports root))
               (source-file (ast:source-file root)))
          (format depend "~a: ~a~a\n" (basename header-file-name)
                  (code:relative-file-name dir source-file)
                  (string-join import-files " " 'prefix))))
      (code:dump generator #:file-name header-file-name #:verbose? verbose?)

      (if (c++:generate-source? root)
          (let ((generator (sm:indenter (cute print-code-ast root))))
            (code:dump generator #:file-name source-file-name #:verbose? verbose?)
            (when depend-dir
              (format depend "~a: ~a\n"
                      (basename source-file-name)
                      (basename header-file-name))))
          (and empty-files?
               (code:touch source-file-name #:verbose? verbose?)))

      (when model
        (let ((model (false-if-exception (ast:get-model root model)))) ;FIXME
          (when (is-a? model <component-model>)
            (let ((generator (sm:indenter (cute print-main-ast model)))
                  (main-file-name (code:source-file-name "main" dir ".cc")))
              (code:dump generator #:file-name main-file-name #:verbose? verbose?)
              (when depend-dir
                (format depend "~a: ~a\n" (basename main-file-name) source-file-name))))))
      (when depend
        (force-output depend)
        (close-port depend)))))
