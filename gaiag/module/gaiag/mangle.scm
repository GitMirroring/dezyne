;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
  :use-module (gaiag list match)

  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

    ;;:use-module (oop goops describe)
  :use-module (gaiag ast)

  :export (ast-> om:mangle mangle-prefix-alist))

(define-method (mangle (o <top>)) o)
(define-method (mangle (o <named>))
  (define ((mangle-name-initializer o) name)
    (let* ((element (slot-ref o name))
           (p (om:prefix o)))
      (list (symbol->keyword name)
            (if (and (eq? name 'name)
                     p)
                ((prefix p) element)
                element))))
  (om:clone o mangle-name-initializer))

(define-method (mangle (o <port>))
  (make <port>
    :name ((prefix (om:prefix o)) (.name o))
    :direction (.direction o)
    :type ((prefix (om:prefix 'interface)) (.type o))))

(define-method (mangle (o <trigger>))
  (make <trigger>
    :port (and=> (.port o) (prefix (om:prefix 'port)))
    :event ((prefix (om:prefix 'event)) (.event o))))

(define-method (mangle (o <binding>))
  (make <binding>
    :instance (and=> (.instance o) (prefix (om:prefix 'instance)))
    :port (and=> (.port o) (prefix (om:prefix 'port)))))

(define-method (mangle (o <instance>))
  (make <instance>
    :name (and=> (.name o) (prefix (om:prefix 'instance)))
    :component (and=> (.component o) (prefix (om:prefix 'component)))))

(define-method (mangle (o <variable>))
  (make <variable>
    :name ((prefix (om:prefix 'var)) (.name o))
    :type (.type o)
    :expression (.expression o)))

(define mangle-prefix-alist
  (make-parameter '((event . ev)
                    (instance . is)
                    (interface . if)
                    (component . co)
                    (formal . va)
                    (port . po)
                    (var . va))))

(define-method (om:prefix (o <top>)) #f)
(define-method (om:prefix (o <symbol>))
  (assoc-ref (mangle-prefix-alist) o))
(define-method (om:prefix (o <ast>)) (om:prefix (ast-name o)))

(define ((prefix p) name) (if p (symbol-append p '_ name) name))

(define (om:mangle ast) (om:map* mangle ast))
(define (ast-> ast)
  ((compose om->list om:mangle ast:resolve ast->om) ast))
