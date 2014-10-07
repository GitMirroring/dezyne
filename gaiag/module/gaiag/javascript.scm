;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (gaiag javascript)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag code)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast->))

(define (ast-> ast)
  (ast:code ast dump))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dump-indented file-name thunk)
  (dump-output file-name (lambda () (pipe thunk (lambda () (indent))))))

(define-method (dump (o <interface>))
  (mkdir-p "interface")
  (let ((name (.name o)))
    (dump-indented (list 'interface name '.js)
                   (lambda ()
                     (javascript-file 'interface.js.scm (code:module o))))))

(define-method (dump (o <component>))
  (mkdir-p "component")
  (let ((name (.name o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (when (.behaviour o)
      (map dump interfaces)
      (dump-indented (list 'component name '.js)
                   (lambda ()
                     (javascript-file 'component.js.scm (code:module o)))))))

(define-method (dump (o <system>))
  (let ((name (.name o))
        (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
    (dump-indented (list 'component name '.js)
                   (lambda ()
                     (javascript-file 'system.js.scm (code:module o))))))

(define (javascript-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) '(templates javascript))))
    (animate-file file-name module)))

(define* (code:->code model src :optional (locals '()) (indent 1) (compound? #t))
  (parameterize ((template-dir (append (prefix-dir) '(templates javascript))))
    (->code model src locals indent compound?)))
