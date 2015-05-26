;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag list ast)
  :use-module (ice-9 match)

  :use-module (gaiag misc)
  :use-module (gaiag list om)
  :use-module (gaiag list util)

  :export (
           ast:interface
           ast:public           
           ))

(define (ast:public ast)
  (match ast
    (('enum name fields) `(enum ,name ,fields))
    (('extern name value) `(extern ,name ,value))
    (('int name range) `(int ,name ,range))
    (('interface name types events behaviour) `(interface ,name ,types ,events))
    ((h t ...) (map ast:public ast))
    (_ '(import))))

(define (ast:interface ast)
  (match ast
    (('root models ...) ast)
    (('interface name body ...) ast)
    ((h t ...) (map ast:interface ast))
    (_ '(import))))
