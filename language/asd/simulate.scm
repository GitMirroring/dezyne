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

(define-module (language asd simulate)
  :use-module (ice-9 match)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd reader)
  :export (asd->))

(define *ast* '())
(define *state-vector* '())

(define (asd-> ast)
  (set! *ast* ast)
  (and=> (ast:component ast) simulate)
  "")

(define (variable-state variable . value) 
  (cons (ast:identifier variable) (if (pair? value) (car value) (ast:initial-value variable))))

(define (sim component)
  (pretty-print (simulate component)))

(define (simulate component)
  (let loop ((state (map variable-state (ast:body (ast:variables component))))
             (events (find-triggers component))) 
    (stderr "events:~a\n" events)
    (stderr "state:~a\n" state)
    (if (null? events)
        state
        (let ((next (null-is-#f (process (ast:statements (ast:behaviour component)) state (car events)))))
          (stderr "next: ~a\n"next)
          (if next
              (loop next events)
              (loop state (cdr events)))))))

(define (var state identifier) (assoc-ref state identifier))

(define (state-eval-expression state expression)
  (stderr "eval ~a ? ~a\n" state expression)
  (match expression
    (('field identifier value) 
     (stderr "FIELD: ~a =? ~a --->~a\n" (var state identifier) value (eq? (ast:identifier (var state identifier)) value))
     (eq? (ast:identifier (var state identifier)) value))
    ((? symbol?) 
     (stderr "FIELD: ~a =? ~a\n" (var state expression) 'true (eq? (var state expression) 'true))
     (eq? (var state expression) 'true))))

(define (process ast state event)
  ;; eval / apply?
  (stderr "processing: ~a\n" event)
  (and state
       (match ast
         (('on t statement) 
          (let* ((on (map ast:identifier t))
                 (in  (member event on))
                 (r (if in (process statement state event) #f)))
            (stderr "ON ~a ? [~a]:~a ===>\n" event on in r)
            r))
         (('guard expression statement)
          (let ((r (if (state-eval-expression state expression) (process statement state event) #f)))
            (stderr "GUARD ~a ==>~a\n" expression r)
            r))
         (('assign identifier expression)
          (stderr "assign: state=~a\n" state)
          (stderr "assign: ~a --> ~a\n" identifier expression)
          (stderr "assign: state=~a\n" (assoc-set! state identifier expression))
          (assoc-set! state identifier expression))
         (('action 'illegal) #f)
         (('action t ...) (stderr "send: ~a" t) state)
         (('statements t ...) (let loop ((state state) (statements t))
                                (if (null? statements)
                                    (and (stderr "STATEMENTS: ~a\n" state) state)
                                    (loop (process (car statements) state event) (cdr statements))))))))

(define* (find-triggers ast :optional (triggers '()))
  (match ast
    ((? ast:component?)
     (delete-duplicates (sort (apply append (map find-triggers (ast:body (ast:statements (ast:behaviour ast))))) symbol<)))
    ((? ast:interface?) 
     (delete-duplicates (sort (append (map ast:identifier (ast:body (ast:events ast))) (apply append (map find-triggers (ast:body (ast:statements (ast:behaviour ast)))))) symbol<)))
    (('statements t ...) (append (apply append (map find-triggers t)) triggers))
    (('on t statement) (map find-triggers t))
    (('field type identifier) identifier)
    (('guard expression statement) (find-triggers statement triggers))
    ((? symbol?) ast)))
