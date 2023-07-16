;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2021 Rutger van Beusekom <rutger@dezyne.org>
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

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code scmackerel c++)
  #:use-module (dzn code util)
  #:use-module (dzn misc)
  #:export (c++:ref))

;;;
;;; Accessors.
;;;
(define-method (c++:generate-source? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (disjoin (is? <interface>) ;; no inline (yet??)
                          (is? <foreign>)   ;; no inline (yet??
                          (is? <component>)
                          (is? <system>)))
        (ast:model* o)))

(define-method (c++:ref (o <string>))
  (string-append "&" o))


;;;
;;; Entry point.
;;;
(define* (ast-> root #:key (dir ".") model)
  "Entry point."

  (code:foreign-conflict? root)

  (let ((root (code:normalize+determinism root)))
    (let ((generator (code:indenter (cute print-header-ast root)))
          (file-name (code:root-file-name root dir ".hh")))
      (code:dump root generator #:file-name file-name))

    (when (c++:generate-source? root)
      (let ((generator (code:indenter (cute print-code-ast root)))
            (file-name (code:root-file-name root dir ".cc")))
        (code:dump root generator #:file-name file-name)))

    (when model
      (let ((model (ast:get-model root model)))
        (when (is-a? model <component-model>)
          (let ((generator (code:indenter (cute print-main-ast model)))
                (file-name (code:source-file-name "main" dir ".cc")))
            (code:dump root generator #:file-name file-name)))))))
