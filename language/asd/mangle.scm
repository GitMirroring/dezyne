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

(define-module (language asd mangle)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)

  :export (ast-> mangle))

(define (mangle ast)
  (match ast
    (('interface name rest ...) (append (list 'interface (symbol-append 'if_ name)) (map mangle rest)))
    (('in type event) (list 'in type (symbol-append 'ev_ event)))
    (('out type event) (list 'out type (symbol-append 'ev_ event)))
    (('component name rest ...) (append (list 'component (symbol-append 'co_ name)) (map mangle rest)))
    (('provides name event) (list 'provides (symbol-append 'if_ name) (symbol-append 'po_ event)))
    (('requires name event) (list 'requires (symbol-append 'if_ name) (symbol-append 'po_ event)))
    (('variable type name expression) (list 'variable type (symbol-append 'va_ name) expression))
    ((h ...) (map mangle ast))
    (_ ast)))

(define (ast-> ast)
  (pretty-print (mangle ast)) "")
