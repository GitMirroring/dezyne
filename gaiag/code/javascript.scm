;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2015, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag code javascript)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag config)

  #:use-module (gaiag ast)
  #:use-module (gaiag code dzn)
  #:use-module (gaiag code)
  #:use-module (gaiag code-util)
  #:use-module (gaiag templates))

(define-method (javascript:class-name (o <model>))
  (string-join (ast:full-name o) "."))

(define-method (javascript:class-name (o <instance>))
  (javascript:class-name (.type o)))

(define-method (javascript:class-name (o <port>))
  (javascript:class-name (.type o)))

(define-method (javascript:module-name (o <root>))
  (let ((dzn-file (ast:source-file o))
        (namespaces (filter (conjoin (negate ast:imported?)
                                     (negate (compose (cut equal? <> '("dzn")) ast:full-name)))
                            (ast:namespace* o))))
    (if (null? namespaces) (basename dzn-file ".dzn")
        (javascript:module-name (car namespaces)))))

(define-method (javascript:module-name (o <foreign>))
  (string-join (ast:full-name o) "/"))

(define-method (javascript:module-name (o <namespace>))
  (let* ((dzn-file (ast:source-file o))
         (base-name (basename dzn-file ".dzn"))
         (namespace (ast:full-name o)))
    (string-join (append namespace (list base-name)) "/")))

(define-method (javascript:module-name (o <model>))
  (let* ((dzn-file (ast:source-file o))
         (base-name (basename dzn-file ".dzn"))
         (namespace (drop-right (ast:full-name o) 1)))
    (string-join (append namespace (list base-name)) "/")))

(define-method (javascript:module-name (o <port>))
  (javascript:module-name (.type o)))

(define-method (javascript:require-module (o <root>))
  (let* ((models (filter ast:imported? (ast:model* o)))
         (modules (map javascript:module-name models))
         (foreigns (map javascript:module-name (code:used-foreigns o)))
         (components (filter (is? <component>) (ast:model* o))))
    (map (cut make <file-name> #:name <>) (delete-duplicates (append modules foreigns)))))

(define-method (javascript:require-module (o <model>))
  (javascript:require-module (parent o <root>)))

(define (javascript:namespace-setup o)
  (->string
   (let loop ((todo (cons "dzn" (ast:full-scope o))) (namespace '()))
     (if (null? todo) '()
         (let* ((namespace (append namespace (list (car todo))))
                (x ((->join ".") namespace)))
           (append (list x " = " x " || {};\n" )
                   (loop (cdr todo) namespace)))))))

(define-templates-macro define-templates javascript)
(include-from-path "gaiag/templates/dzn.scm")
(include-from-path "gaiag/templates/code.scm")
(include-from-path "gaiag/templates/javascript.scm")


;;;
;;; Entry points.
;;;

(define* (root-> root #:key (dir ".") main)
  "Entry point."

  (code-util:foreign-conflict? root)

  (let ((root (code:om root)))

    (let ((generator (code-util:indenter (cute x:source root)))
          (file-name (code-util:root-file-name root dir ".js")))
      (code-util:dump root generator #:file-name file-name))

    (when main
      (let ((model (ast:get-model root main)))
        (when (is-a? model <component-model>)
          (let ((generator (code-util:indenter (cute x:main model)))
                (file-name (code-util:file-name "main" dir ".js")))
            (code-util:dump root generator #:file-name file-name)))))))

(define (ast-> ast)
  "XXX REMOVEME Legacy entry point"
  (let ((dir (command-line:get 'output "."))
        (main (command-line:get 'model #f)))
    (root-> ast #:dir dir #:main main)))
