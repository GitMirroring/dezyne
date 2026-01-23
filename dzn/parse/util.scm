;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2021, 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
;;; Copyright © 2020, 2021, 2026 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn parse util)
  #:use-module (srfi srfi-1)

  #:use-module (ice-9 rdelim)

  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse tree)

  #:export (list-models-name+type))

(define (list-models-name+type file-name)
  "Return an ALIST of form `((name . type) ...)' for each model in
FILE-NAME."
  (let* ((text (parse:file->string file-name))
         (tree (parameterize ((%peg:fall-back? #t))
                 (parse:string->tree text #:file-name file-name))))
    (define (model->name+type context)
      (let* ((model (find tree:model? context))
             (name (context:dotted-name context))
             (type (cond ((is-a? model 'interface) 'interface)
                         ((tree:component? model) 'component)
                         ((tree:foreign? model) 'foreign)
                         ((tree:system? model) 'system))))
        `(,name . ,type)))
    (map model->name+type (tree:list-model* tree))))
