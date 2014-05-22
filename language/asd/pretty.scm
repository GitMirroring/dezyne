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

(define-module (language asd pretty)
  :use-module (ice-9 rdelim)
  :use-module (ice-9 match)
  :use-module (system base lalr)
  :use-module (language tree-il)
  :use-module (asd format-keys)
  :export (asd->string))

(define *pretty* (current-module))

(define (gulp-text-file name)
  (let* ((file (open-file name "r"))
	 (text (read-delimited "" file)))
    (close file)
    text))

(define (gulp-snippet name)
  (gulp-text-file (string-join (map symbol->string `(snippets asd ,name)) "/")))

(define (format-snippet name pairs) 
  (format-keys (gulp-snippet name) pairs))

(define (asd->string tree) 
  ;;(format #t "tree:~a\n" tree)
  (apply string-append (map ->string tree)))

(define (safe-eval src)
  (catch #t
    (lambda ()
      (apply (eval (car src) *pretty*) (cdr src)))
    (lambda (key . args)
      (format #f "eval failed:~a ~a\n" key args))))

(define (->string src) 
;;  (format #t "MATCHING:~a\n" src)
  (match src
    (#f "false")
    (#t "true")
    (('behaviour) "")
    ((x ... y) (safe-eval src))
    (? (symbol? src) (symbol->string src))
    (_ (format #f "\nNO MATCH:~a\n" src))))

(define (interface name types ports behaviour)
  (format #f "interface ~a\n{\n~a~a~a\n}\n" name 
          (->string types)
          (->string ports)
          (->string behaviour)))

(define (component name ports behaviour)
  (format-snippet 'component
                  `((name . ,name)
                    (ports . ,(->string ports))
                    (behaviour . ,(->string behaviour)))))

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
(define (variables . x) 
  (apply string-append (map ->string x)))
(define (declare type var value) (format #f "~a ~a = ~a;\n" type var (->string  value)))
(define (dot x y) 
  (format #f "~a.~a" x y))
(define (on trigger statement) (format #f "on ~a:\n{\n ~a}\n" (->string trigger) (->string statement)))
(define (statements . x) (string-join (map ->string x)))
(define (guard expression statements) 
  (format #f "[~a]\n{\n~a}\n" (->string expression) (->string statements)))
(define (assign var value) 
  (format #f "~a = ~a;\n" var (->string value)))
(define (action var) 
  (format #f "~a;\n" (->string var)))
(define (|| x y) 
    (format #f "~a || ~a" (->string x) (->string y)))
(define (in type identifier)
  (format #f "in ~a ~a;\n" type identifier))
(define (out type identifier)
  (format #f "out ~a ~a;\n" type identifier))
(define (imports . x) (string-join (map ->string x)))
(define (import file) (format #f "import ~a;\n" file))
