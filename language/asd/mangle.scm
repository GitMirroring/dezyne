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
    (('interface name rest ...) (append (ast:make 'interface (cons ((prefix 'if) name) (map mangle rest)))))
    (('in type event) (ast:make 'in (list type ((prefix 'ev) event))))
    (('out type event) (ast:make 'out (list type ((prefix 'ev) event))))
    (('component name rest ...) (append (ast:make 'component (cons ((prefix 'co) name) (map mangle rest)))))
    (('provides name event) (ast:make 'provides (list ((prefix 'if) name) ((prefix 'po) event))))
    (('requires name event) (ast:make 'requires (list ((prefix 'if) name) ((prefix 'po) event))))
    ;; Do we need this for LOPW? (('variable type name expression) (list 'variable type ((prefix 'va) name) expression))
    ;; FIXME: type interface trigger (on ((trigger #f x)) statemnt)?
    (('on ('triggers (? ast:trigger?) ...) statement) (ast:make 'on (list (ast:make 'triggers (map mangle (ast:triggers ast))) (mangle statement))))
    (('trigger port event) (ast:make 'trigger (list (if port ((prefix 'po) port) #f) ((prefix 'ev) event))))
    (('illegal) ast)
    (('action (? ast:trigger?)) (ast:make 'action (list (mangle (ast:trigger ast)))))
    ((h ...) (map mangle ast))
    (_ ast)))

(define (ast-> ast)
  (pretty-print (mangle ast)) "")
