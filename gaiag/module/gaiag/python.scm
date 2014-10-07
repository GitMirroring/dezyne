;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag python)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag code)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast->
           enum-type
           python:gom
           python:import))

(define (ast-> ast)
  (let ((gom ((gom:register python:gom) ast #t)))
    (map dump ((gom:filter <model>) gom)))
  "")

(define (python:import name)
  (gom:import name python:gom))

(define (python:gom ast)
  ((compose ast:wfc ast:resolve ast->gom) ast))

(define-method (dump (o <interface>))
  (mkdir-p "interface")
  (let ((name (.name o)))
    (dump-output (list 'interface name '.py)
                   (lambda ()
                     (python-file 'interface.py.scm (code:module o))))))

(define-method (dump (o <component>))
  (mkdir-p "component")
  (let ((name (.name o))
        (interfaces (map python:import (map .type ((compose .elements .ports) o)))))
    (when (.behaviour o)
      (map dump interfaces)
      (dump-output (list 'component name '.py)
                   (lambda ()
                     (python-file 'component.py.scm (code:module o)))))))

(define-method (dump (o <system>))
  (let ((name (.name o))
        (interfaces (map python:import (map .type ((compose .elements .ports) o)))))
    (dump-output (list 'component name '.py)
                   (lambda ()
                     (python-file 'system.py.scm (code:module o))))))

(define (python-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) '(templates python))))
    (animate-file file-name module)))

(define* (python:->code model src :optional (locals '()) (indent 1) (compound? #t))
  (parameterize ((template-dir (append (prefix-dir) '(templates python))))
    (->code model src locals indent compound?)))
