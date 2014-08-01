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
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)

  :export (ast-> mangle))

(define ((prefix p) name) (symbol-append p '_ name))

;; TODO: function, variable mangling. Does that have priority?
(define (mangle ast)
  (match ast
    (('interface name rest ...) (append (list 'interface ((prefix 'if) name)) (map mangle rest)))
    (('in type event) (list 'in type ((prefix 'ev) event)))
    (('out type event) (list 'out type ((prefix 'ev) event)))
    (('component name rest ...) (append (list 'component ((prefix 'co) name)) (map mangle rest)))
    (('provides name event) (list 'provides ((prefix 'if) name) ((prefix 'po) event)))
    (('requires name event) (list 'requires ((prefix 'if) name) ((prefix 'po) event)))
    ;; Do we need this for LOPW? (('variable type name expression) (list 'variable type ((prefix 'va) name) expression))
    ;; FIXME: type interface trigger (on ((trigger #f x)) statemnt)?
    (('on ((? symbol?) ...) statement) (list 'on (map (prefix 'ev) (ast:triggers ast)) (mangle statement)))
    (('trigger port event) (list 'trigger ((prefix 'po) port) ((prefix 'ev) event)))
    (('action 'illegal) ast)
    ;; FIXME: type interface trigger (action '(trigger #f x))?
    (('action (? symbol?)) (list 'action ((prefix 'ev) (cadr ast))))
    ((h ...) (map mangle ast))
    (_ ast)))

(define (ast-> ast)
  (pretty-print (mangle ast)) "")
