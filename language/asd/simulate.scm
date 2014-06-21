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
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd reader)
  :export (asd->))

(define *ast* '())
(define *module* #f)
(define *state-vector* '())

(define (asd-> ast)
  (set! *ast* ast)
  (and=> (ast:interface ast) simulate-module)
  (and=> (ast:component ast) simulate-module)
  "")

(define (variable-state variable . value) 
  (cons (ast:identifier variable) (if (pair? value) (car value) (ast:initial-value variable))))

(define i 0)
(define *state-space* '(()))

(define (simulate-module module)
  (stderr "\n\n>>>simulating: ~a ~a --> ~a\n" (ast:class module) (ast:name module) (find-triggers module))
  (set! *module* module)
  (set! *state-space* '(()))
  (set! i 0)
  (pretty-print (simulate module)))

(define sim simulate-module)

(define (seen state ast)
  (let* ((key (list state ast)) 
         (events (f-is-null (assoc-ref *state-space* key))))
    events))

(define (seen? state ast event)
  (find (lambda (x) (equal? x event)) (seen state ast)))

(define (seen! state ast event)
  (let* ((key (list (map list-copy state) ast))
         (events (seen state ast)))
    (if (not (seen? state ast event))
        (let ((value (delete-duplicates (sort (cons event events) symbol<))))
          (set! *state-space* (assoc-set! *state-space* key value))))))

(define* (simulate module :optional 
                   (ast (ast:statements (ast:behaviour module)))
                   (state (map variable-state (ast:body (ast:variables module))))
                   (events (find-triggers module)))
  (if (null? events)
      'events-done
      (if (not state)
          (simulate module ast)
          (if (not (null-is-#f ast))
              (simulate module)
              (let ((done (seen state ast)))
                (receive (done todo) 
                    (partition (lambda (x) (member x done equal?)) events)
                  (if (null? todo)
                      'todo-done
                      (let ((event (car todo)))
                        (if (seen? state ast event)
                            'seen
                            (begin
                              (stderr "\nevent: ~a\n" event)
                              (seen! state ast event)
                              (receive (state ast action)
                                  (process ast state event)
                                (if (eq? action 'break)
                                    'break
                                    (simulate module ast state)))))))))))))

(define (var state identifier) (assoc-ref state identifier))

(define (state-eval-expression state expression)
  (match expression
    (('field identifier value) 
     (eq? (ast:identifier (var state identifier)) value))
    ((? symbol?) 
     (eq? (var state expression) 'true))))

(define (process ast state event)
  (set! i (1+ i))
  (if (> i 100) (values #f #f 'break)
  (and state
       (match ast
         (('on t statement) 
          (if ;;; FIXME(member event (map ast:identifier t))
           (member event t)
              (process statement state event)
              (values state #f #f)))
         (('guard expression statement)
          (if (state-eval-expression state expression) 
              (process statement state event) 
              (values state #f #f)))
         (('action 'illegal) (values state #f #f))
         (('action t ...) 
          (stderr "****action: ~a\n" t)
          (values state #f ast))
         (('assign identifier expression)
          (stderr "****assign: ~a --> ~a\n" identifier expression)
          (assoc-set! state identifier expression)
          (values state #f #f))
         (('if expression statement else) 
          (if (state-eval-expression state expression) 
              (process statement state event) 
              (process else state event)))
         (('if expression statement)
          (if (state-eval-expression state expression) 
              (process statement state event) 
              (values state #f #f)))
         (('statements h t ...)
          (receive (state ast action) (process h state event)
            (if action
                (if ast
                    (values state (append ast t) action)
                    (values state (cons 'statements t) action))
                (if ast
                    (process (append ast t) state event)
                    (process (cons 'statements t) state event)))))
         (('statements) (values state #f #f))))))

(define (find-in-events ast) (find-events in? ast))
(define (find-out-events ast) (find-events out? ast))

(define* (find-events ast :optional (predicate identity) (events '()))
  (let ((find-events-p (lambda* (ast :optional (events '()))
                         (find-events ast predicate events))))
    (match ast
      ((? ast:component?)
       (delete-duplicates (sort (apply append (map find-events-p (ast:body (ast:statements (ast:behaviour ast))))) symbol<)))
      ((? ast:interface?) 
       (let ((declared (ast:body (ast:events ast)))
             (behaviour (map (lambda (x) (ast:make 'in 'void x)) (apply append (map find-events-p (ast:body (ast:statements (ast:behaviour ast))))))))
         (receive (keep discard) (partition predicate declared)
           (stderr "declared:~a\n" declared)
           (stderr "keep:~a\n" keep)
           (stderr "discard:~a\n" discard)
           (stderr "behaviour:~a\n" behaviour))
         (delete-duplicates (sort (append (map ast:identifier declared) (apply append (map find-events-p (ast:body (ast:statements (ast:behaviour ast)))))) symbol<))))
      (('statements t ...) (append (apply append (map find-events-p t)) events))
      (('on t statement) (map find-events-p t))
      (('field type identifier) identifier)
      (('guard expression statement) (find-events-p statement events))
      ((? symbol?) ast))))
