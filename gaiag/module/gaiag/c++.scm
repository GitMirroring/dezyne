;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag c++)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag code)
  :use-module (gaiag indent)
  :use-module (gaiag mangle)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast->
           c++:gom
           c++:import
           *glue-alist*))

(define *glue-alist* '())
(define (ast-> ast)
  (let ((gom ((gom:register c++:gom) ast #t)))
    (and-let* ((file "AlarmSystem.text"))
              (set! *glue-alist* (glue-mapping->alist (gulp-file file))))
    (map dump ((gom:filter <model>) gom)))
  "")

(define (c++:import name)
  (gom:import name c++:gom))

(define (c++:gom ast)
  ((compose mangle ast:wfc ast:resolve ast->gom) ast))

(define (mangle o)
  (if #f
      o
      (parameterize ((mangle-prefix-alist '((port . po) (instance . is)))) (gom:mangle o))))

(define-method (dump (o <interface>))
  (let ((name (.name o)))
    (dump-indented (symbol-append 'interface- name '-c3.hh)
                   (lambda ()
                     (c++-file 'interface.hh.scm (code:module o))))))

(define-method (dump (o <component>))
  (let ((name (.name o))
        (interfaces (map c++:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (symbol-append 'component- name '-c3.hh)
                   (lambda ()
                     (c++-file 'component.hh.scm (code:module o))))
    (if (.behaviour o)
        (dump-indented (symbol-append 'component- name '-c3.cc)
                       (lambda ()
                         (c++-file 'component.cc.scm (code:module o))))
        (dump-indented (symbol-append 'glue-component- name '-c3.cc)
                       (lambda ()
                         (c++-file 'glue-bottom-component.cc.scm (code:module o)))))))

(define-method (dump (o <system>))
  (let ((name (.name o))
        (interfaces (map c++:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (symbol-append 'component- name '-c3.hh)
                   (lambda ()
                     (c++-file 'system.hh.scm (code:module o))))
    (dump-indented (symbol-append 'component- name '-c3.cc)
                   (lambda ()
                     (c++-file 'system.cc.scm (code:module o))))
    (dump-indented (symbol-append name 'Interface.h)
                   (lambda ()
                     (c++-file 'glue-top-system-interface.hh.scm (code:module o))))
    (dump-indented (symbol-append name 'Component.h)
                   (lambda ()
                     (c++-file 'glue-top-system.hh.scm (code:module o))))
    (dump-indented (symbol-append name 'Component.cpp)
                   (lambda ()
                     (c++-file 'glue-top-system.cc.scm (code:module o))))))

(define (c++-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) '(templates c++))))
    (animate-file file-name module)))

(define (glue-mapping->alist string)
  (fold (lambda (e r)
          (if (pair? e)
              (or (and-let* ((v (assoc-ref r (car e))))
                            (assoc-set! r (car e) (append v (list (cdr e)))))
                  (acons (car e) (list (cdr e)) r)) r))
        '()
        (map (lambda (o) (map string->symbol (string-tokenize o char-set:graphic)))
             (string-split string #\newline))))
