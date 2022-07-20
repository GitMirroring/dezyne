;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn code-util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn indent)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)

  #:export (code-util:dump
            code-util:file-name
            code-util:foreign-conflict?
            code-util:generate-source?
            code-util:root-file-name
            code-util:indenter))

(define* (code-util:indenter thunk #:key (width 2) (open #\{) (close #\}) (no-indent "#"))
  (define (pipe producer consumer)
    (with-input-from-string (with-output-to-string producer) consumer))
  (cute pipe thunk
        (cute indent #:width width #:open open #:close close #:no-indent no-indent)))

(define (code-util:file-name base dir ext)
  (cond ((equal? dir "-") "-")
        (dir (string-append dir "/" base ext))
        (else (string-append base ext))))

(define (code-util:root-file-name root dir ext)
  (let ((base (basename (ast:source-file root) ".dzn")))
    (code-util:file-name base dir ext)))

(define* (code-util:dump root generate #:key file-name)
  (cond
   ((equal? file-name "-")
    (generate))
   (else
    (mkdir-p (dirname file-name))
    (with-output-to-file file-name
      generate))))

(define-method (code-util:base-name (o <foreign>))
  (string-join (ast:full-name o) "_"))

(define-method (code-util:foreign-conflict? (o <root>))
  (let* ((foreigns (filter (conjoin (is? <foreign>)
                                    (negate ast:imported?))
                           (ast:model* o)))
         (foreign-bases (map code-util:base-name foreigns))
         (conflict? (member (ast:base-name o) foreign-bases)))
    (when conflict?
      ;; XXX TODO: throw / catch
      (format (current-error-port) "cowardly refusing to clobber file with basename: ~a\n"
              (ast:base-name o))
      (exit EXIT_FAILURE))))

(define-method (code-util:generate-source? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (disjoin (is? <component>) (is? <system>)))
        (ast:model* o)))
