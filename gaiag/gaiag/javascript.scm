;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-module (gaiag javascript)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 pretty-print)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  ;;#:use-module (gaiag deprecated code)
  #:use-module (gaiag code)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag xpand))

(define code:ast-> (@ (gaiag deprecated code) ast:code))
(define dzn-async? (@@ (gaiag c++) dzn-async?))
(define source-file (@@ (gaiag c++) source-file))

(define (ast-> ast)
  (if (code:model2file?) (code:ast-> ast)
      (let ((root (code:om ast)))
        (ast:set-scope root (code:root-> root))))
  "")

(define (code:root-> root)
  (let* ((models (code:models-voodoo root))
         (module (code:module root))

         (main (command-line:get 'model #f))
         (main (and main (find (compose (cut eq? (string->symbol main) <>) (om:scope-name)) models)))
         (main (and main (as main <component-model>))))

    ;; more voodoo
    (module-define! module 'root (clone root #:elements (if (glue) (filter (negate (is? <system>)) models) models)))
    (code:dump-file (basename (symbol->string (source-file root)) ".dzn") module)
    (map dump-component (filter (is? <foreign>) (.elements root)))
    ;;(if (glue) (map dump-system (filter (is? <system>) (.elements root))))
    (when main (dump-main main))))

(define (code:dump-file file-name module)
  (dump-output (string-append "dzn/" file-name (symbol->string (code:extension (make <interface>))))
               (lambda ()
                 (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
                   (x:pand 'header-root (module-ref module 'root) module))))
  (if (pair? (filter (negate (disjoin (is? <data>) (is? <interface>))) (.elements (module-ref module 'root))))
      (dump-output (string-append "dzn/" file-name (symbol->string (code:extension (make <component>))))
                   (lambda ()
                     (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
                       (x:pand 'source-root (module-ref module 'root) module))))))

(define (code:module root)
  (let ((module (make-module 31 `(,(resolve-module '(gaiag deprecated code))
                                  ,(resolve-module `(gaiag ,(language)))))))
    (module-define! module 'root root)
    module))

(define (code:models-voodoo root)
  (let* ((models ((om:filter:p <model>) root))
         (models (filter (negate om:imported?) models))
         ;; Generator-synthesized models look non-imported, filter harder
         (models (filter (negate dzn-async?) models))

         (main (command-line:get 'model #f))
         (main (and main (find (compose (cut eq? (string->symbol main) <>) (om:scope-name)) models))))
    (sort (filter (disjoin (is? <data>)
                           (conjoin (negate dzn-async?) (negate om:imported?) (negate (is? <foreign>))))
                  (.elements root))
          (lambda (a b) (or (and (is-a? <interface> a)
                                 (is-a? <component> b))
                            (and (is-a? <interface> a)
                                 (is-a? <system> b))
                            (and (is-a? <component> a)
                                 (is-a? <system> b)))))))

(define-template x:main-provided-flush-init om:provided)
(define-template x:main-required-flush-init om:required)

(define (javascript:namespace-setup o)
  (->string
   (let loop ((todo (cons 'dzn (om:scope o))) (namespace '()))
     (if (null? todo) '()
         (let* ((namespace (append namespace (list (car todo))))
                (x ((->join ".") namespace)))
           (append (list x " = " x " || {};\n" )
                   (loop (cdr todo) namespace)))))))

(define-template x:javascript-namespace-setup javascript:namespace-setup)
