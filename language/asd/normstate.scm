;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(read-set! keywords 'prefix)

(define-module (language asd normstate)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)
  :use-module (srfi srfi-1)
  :use-module (system repl error-handling)
  :use-module (system vm trap-state)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd scheme)
  :use-module (language asd reader)
  :export (asd-> asd->normstate))

(define (asd->normstate ast) 
  (with-error-handling
;;  (asd->pretty (normstate ast))))
;;  (asd->scheme (normstate ast))))
;;  (asd->scheme (remove-otherwise '() ast))))
;;   (asd->pretty (remove-otherwise '() ast))))
;;  (asd->scheme (combine-guards (normstate ((remove-otherwise '()) ast))))))
  (asd->pretty (flatten-compound (combine-guards (passdown-on ((remove-otherwise '()) ast)))))))

(define (flatten-compound ast) 
  (match ast
    (('statements s ...) (cons 'statements (apply append (map flatten-compound-stat (cdr ast)))))
    (('on t s) ast)
    ((h ...) (map flatten-compound ast))
    (_ ast)))
      
(define (flatten-compound-stat stat)
   (let ((res (flatten-compound stat)))
     (match res
       (('statements s ...) (cdr res))
       (_ (list res)))))
      
(define (guards-not-or statements)
  (let ((guards (map cadr (cdr statements))))
    (list '! (reduce (lambda (g0 g1) (list 'or g0 g1)) '() (delete 'otherwise guards)))))

(define ((remove-otherwise statements) ast) 
  (match ast
    (('guard 'otherwise s) (list 'guard (guards-not-or statements) ((remove-otherwise '()) s)))
    (('statements s ...) (cons 'statements (map (remove-otherwise ast) (cdr ast))))
    ((h ...) (map (remove-otherwise statements) ast))
    (_ ast)))
 
 (define (combine-guards ast)
  (match ast
    (('guard guard statement) ((passdown-guard guard) statement))
    ((h ...) (map combine-guards ast))
    (_ ast)))

(define ((passdown-guard guard) statement)
  (match statement
    (('statements s ...) (cons 'statements (map (passdown-guard guard) (cdr statement))))
    (('guard g s) ((passdown-guard (list 'and guard g)) s))
    (_ (list 'guard guard statement)))) 

(define (passdown-on ast)
  (match ast
    (('on triggers statement) ((passdown-triggers triggers) statement))
    ((h ...) (map passdown-on ast))
    (_, ast)))

(define ((passdown-triggers triggers) statement)
  (match statement
    (('statements ('guard g s) ...) (cons 'statements (map (passdown-triggers triggers) (cdr statement))))
    (('guard g s) (list 'guard g ((passdown-triggers triggers) s)))
    (_ (list 'on triggers statement)))) 

(define asd-> asd->normstate)
