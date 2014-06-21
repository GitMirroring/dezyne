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
  (cons variable (if (pair? value) (car value) (ast:initial-value variable))))

(define (sim component)
  (pretty-print (simulate component)))

(define (simulate component)
  (stderr "state vector:~a\n" (ast:body (ast:variables component)))
  (let loop ((state (map variable-state (ast:body (ast:variables component))))
;;             (state-vector '(()))
             (events (find-triggers component))) 
;;    (stderr "events:~a\n" events)
;;    (stderr "state:~a\n" state)
    (if (null? events)
        state
        (let ((state (process state (car events)) state))
          (if state
              (loop )
              )
          )
        (loop (append ) (cdr events)))))

(define (process state event)
  
  (stderr "processing: ~a\n" event)
  (list (cons (random 100) state)))

(define* (find-triggers ast :optional (triggers '()))
  (match ast
    ((? ast:component?)
     (delete-duplicates (sort (apply append (map find-triggers (ast:body (ast:statements (ast:behaviour ast))))) symbol<)))
    ((? ast:interface?) 
     (delete-duplicates (sort (append (map ast:identifier (ast:body (ast:events ast))) (apply append (map find-triggers (ast:body (ast:statements (ast:behaviour ast)))))) symbol<)))
    (('statements t ...) (append (apply append (map find-triggers t)) triggers))
    (('on t statement) (map find-triggers t))
    (('field type identifier) identifier)
    (('guard expression statements) (find-triggers statements triggers))
    ((? symbol?) ast)))
