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

(define-module (gaiag mangle)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)

  :use-module (gaiag ast:)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast-> gom:mangle))

(define-method (mangle (o <top>)) o)
(define-method (mangle (o <named>))
  (define ((make-initializer o) name)
    (let* ((element (slot-ref o name))
           (p (gom:prefix o)))
      (list (symbol->keyword name)
            (if (and (eq? name 'name) p)
                ((prefix p) element)
                element))))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (initializers (map (make-initializer o) names))
         (arguments (cons class (apply append initializers))))
    (apply make arguments)))

(define-method (mangle (o <gom:port>))
  (make <gom:port>
    :name ((prefix (gom:prefix o)) (.name o))
    :direction (.direction o)
    :type ((prefix (gom:prefix 'interface)) (.type o))))

(define-method (mangle (o <trigger>))
  (make <trigger>
    :port (and=> (.port o) (prefix (gom:prefix 'port)))
    :event ((prefix (gom:prefix 'event)) (.event o))))

(define-method (gom:prefix (o <top>)) #f)
(define-method (gom:prefix (o <symbol>))
  (let ((prefix-alist '((interface . if)
                        (component . co)
                        (event . ev)
                        (port . po))))
    (assoc-ref prefix-alist o)))
(define-method (gom:prefix (o <ast>)) (gom:prefix (ast-name o)))

(define ((prefix p) name) (symbol-append p '_ name))

(define (gom:mangle ast) (gom:map mangle ast))
(define (ast-> ast)
  ((compose gom->list gom:mangle ast->gom ast:resolve) ast))
