;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (language asd resolve)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd reader)

  :export (
           ast->
           ast:resolve
           ast:resolve-model
           ast:resolve-system
           ))

(define (ast:resolve ast)
  ((ast:resolve- ast) ast))

(define ((ast:resolve- ast) src)
  (match src
    (('system name ports ('compound s ...)) ((ast:resolve-system src) src))
    (('component name ports ('system name ...)) ((ast:resolve-system src) src))
    (('component name ...) ((ast:resolve-model src) src))
    (('interface name ...) ((ast:resolve-model src) src))
    ((h ...) (map (lambda (x) ((ast:resolve- ast) x)) src))
    (_ src)))

(define ((ast:resolve-model model) src)
  (let* ((port? (lambda (port)
                  (if (eq? (ast:class model) 'interface)
                      #f
                      (member port (map ast:name (ast:ports model))))))
         (enum? (lambda (identifier)
                  (member identifier (map ast:name (ast:enums model)))))
         (enum-field? (lambda (identifier)
                          (lambda (field)
                            (and-let* ((enum (find (lambda (x) (eq? (ast:name x) identifier))
                                                   (ast:enums model))))
                                      (member field (ast:fields enum))))))
         (member? (lambda (identifier)
                    (member identifier (ast:member-names model))))
         (member-field? (lambda (identifier)
                          (lambda (field)
                            (and-let* ((variable (ast:variable model identifier))
                                       (type (ast:name (ast:type variable)))
                                       (enum (find (lambda (x) (eq? (ast:name x) type))
                                                   (ast:enums model))))
                                      (member field (ast:fields enum)))))))
    (match src
      (('action identifier)
       (if (member identifier (map ast:name (ast:functions (ast:behaviour model))))
           (list 'call identifier)
           src))
      (('variable type identifier ('value (and (? port?) (get! port)) event))
       (list 'variable type identifier (list 'action (list 'trigger (port) event))))
      (('assign identifier ('value (and (? port?) (get! port)) event))
       (list 'assign identifier (list 'action (list 'trigger (port) event))))
      (('value (? member?) (? (member-field? (cadr src))))
       (cons 'field (cdr src)))
      (('value (? enum?) (? (enum-field? (cadr src))))
       (append '(literal #f) (cdr src)))
      ((h ...) (map (lambda (x) ((ast:resolve-model model) x)) src))
      (_ src))))

(define ((ast:resolve-system model) src)
  (let ((binding (lambda (binding)
                   (match binding
                     ((? symbol?) (list 'binding #f binding))
                     (('value instance port) (list 'binding instance port))))))
    (match src
      (('component name ports ('system foo statement))
       (list 'system name ports ((ast:resolve-system model) statement)))
      (('bind left right) (list 'bind (binding left) (binding right)))
      ((h ...) (map (lambda (x) ((ast:resolve-system model) x)) src))
      (_ src))))

(define ast-> ast:resolve)
