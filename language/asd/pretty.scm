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

(define-module (language asd pretty)
  #:use-module (system base lalr)
  #:use-module (language tree-il)
  #:use-module (ice-9 match)
  #:export (asd->string))

(define *pretty* (current-module))

(define (asd->string tree) 
  (format #t "tree:~a\n" tree)
  (apply string-append (map ->string tree)))

(define (->string src) 
  (format #t "MATCHING:~a\n" src)
  (match src
    ((b ... e) (apply (eval (car src) *pretty*) (cdr src)))
    ;;(('or x y) (format #f "~a or ~a" "or-left" "or-right"))
    ('false (symbol->string src))
    ('otherwise (symbol->string src))
    ('Disarmed (symbol->string src))
    ((dot x y) "dot")
    ;;(x "foo")   
    ((x) "foo")
    ;;(_ "noop")
    ))

(define (interface name types ports behaviour)
  (format #f "interface ~a\n{\n~a~a~a\n}\n" name 
          (->string types)
          (->string ports)
          (->string behaviour)))

(define (component name ports behaviour)
  (format #f "component ~a\n{\n~a~a\n}\n" name 
          (->string ports)
          (->string behaviour)))

(define (ports . x) (apply string-append (map ->string x)))

(define (requires type name)
  (format #f "requires ~a ~a;\n" type name))

(define (provides type name)
  (format #f "provides ~a ~a;\n" type name))

(define (behaviour name types variables statements)
  (format #f "behaviour ~a\n{\n~a~a~a\n}\n" 
          (if name name "")
          (->string types)
          (->string variables)
          (->string statements)))

(define (enum name elements)
  (format #f "enum ~a { ~a };\n" name (string-join (map symbol->string elements)  ",")))
(define (events . x) (apply string-append (map ->string x)))
(define (types . x) (apply string-append (map ->string x)))
(define (variables . x) (apply string-append (map ->string x)))
(define (declare type var value) (format #f "~a ~a = ~a;\n" type var (->string  value)))
(define (dot struct field) (format #f "~a.~a" struct field))
(define (on trigger statement) (format #f "on ~a:\n{\n ~a\n}\n" (->string trigger) (->string statement)))
(define (statements . x) (apply string-append (map ->string x)))
(define (guard expression statements) 
  (format #f "[~a]\n{\n~a\n}\n" 
          expression
          ;; (->string expression)
          ;;(->string statements)
          statements
          ))
;(define (assign var value) (format #f "~a = ~a;\n" var (->string  value)))
(define (assign var value) 
  ;;"assign"
  (format #f "~a = ~a;\n" var (->string  value))
  )

