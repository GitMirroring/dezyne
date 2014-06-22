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

(define debug? #f)
(define (debug . x) #t)
(if debug?
    (set! debug stderr))

(define *ast* '())
(define *module* #f)

(define (asd-> ast)
  (set! *ast* ast)
  (and=> (ast:interface ast) simulate-module)
  (and=> (ast:component ast) simulate-module)
  "")

(define (variable-state variable . value) 
  (cons (ast:identifier variable)
        (state-eval-expression '()
                               (if (pair? value) (car value) 
                                   (ast:initial-value variable)))))

(define i 0)
(define *state-space* '(()))

(define (simulate-module module)
  (stderr "\n\n>>>simulating: ~a ~a --> ~a\n" (ast:class module) (ast:name module) (map ->string (find-in-events module)))
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
        (let ((value (delete-duplicates (sort (cons event events) event<))))
          (set! *state-space* (assoc-set! *state-space* key value))))))

(define (state-vector module)
  (map variable-state (ast:body (ast:variables module))))

(define* (simulate module :optional 
                   (ast (ast:statements (ast:behaviour module)))
                   (state (state-vector module))
                   (events (find-in-events module)))
  (debug "simulate state: ~a\n" state)
  (debug "ast: ")
  (if (equal? ast (ast:statements (ast:behaviour module)))
      (debug "*top*\n")
      (if debug? (pretty-print ast)))

  (let loop ((events events))
    (if (null? events)
        '(events-done)
        (let ((done (seen state ast)))
          (receive (done todo) 
              (partition (lambda (x) (member x done equal?)) events)
            (if (null? todo)
                (if (not state)
                    (simulate module ast)
                    (if (null-is-#f ast)
                        '(ast-done)
                        '(state-done)))
                (if (not state)
                    (cons (simulate module ast) (loop (cdr events)))
                    (if (not ast)
                        (cons (simulate module) (loop (cdr events)))
                        (let ((event (car todo)))
                          (if (seen? state ast event)
                              (loop (cdr events))
                              (begin
                                (stderr "[~a] " (comma-space-join (map ->string state)))
                                (stderr "event: ~a\n" (->string event))
                                (seen! state ast event)
                                (append
                                 (receive (state ast action)
                                     (process ast state event)
                                   (if action
                                       (stderr "continued... ")
                                       (stderr "\n"))
                                   (let ((cont (if action
                                                   (simulate module ast state)
                                                   '()))
                                         (result
                                          (simulate module (ast:statements (ast:behaviour module)) state)))
                                     (cons 
                                      (append cont result)
                                      (loop (cdr events)))))
                                 (simulate module (ast:statements (ast:behaviour module)) state)))))))))))))

(define (var state identifier) (assoc-ref state identifier))

(define (state-eval-expression state expression)
  (match expression
    (#f #f)
    (#t #t)
    ('false #f)
    ('true #t)
    (('field 'state value)  ;;; FIXME name resolution
     (eq? (ast:identifier (var state 'state)) value))
    (('field identifier value) expression)
    (('! expr) (not (state-eval-expression state expr)))
    ((? symbol?) (state-eval-expression state (var state expression)))
    (_ (stderr  "expression NO MATCH: ~a\n" expression))))

(define (process ast state event)
  (set! i (1+ i))
  (if (> i 2000) 
      (throw 'break (format #f "too many iterations: ~a, state space: ~a\n" i
                            (length *state-space*)))
  (and state
       (match ast
         (('on t statement) 
          (debug "[~a] on: ~a: ---> ~a\n" event t (member event t equal?))
          (if (member event t equal?)
              (process statement state event)
              (values state #f #f)))
         (('guard expression statement)
          (debug "guard: ~a? --> ~a\n" expression (state-eval-expression state expression))
          (if (state-eval-expression state expression) 
              (process statement state event) 
              (values state #f #f)))
         (('action 'illegal) (values state #f #f))
         (('action t ...) 
          (stderr "****action: ~a\n" (->string t))
          (values state #f ast))
         (('assign identifier expression)
          (stderr "****assign: ~a := ~a\n" (->string identifier) (->string expression))
          (values (assoc-set! state identifier (state-eval-expression state expression)) #f #f))
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
         (('statements) (values state #f #f))
         (_ (stderr  "process NO MATCH: ~a\n" ast))))))

(define (find-in-events ast) (find-events ast ast:in?))
(define (find-out-events ast) (find-events ast ast:out?))

(define* (find-events ast :optional (predicate identity) (events '()))
  (let ((find-events-p (lambda* (ast :optional (events '()))
                         (find-events ast predicate events))))
    (match ast
      ((? ast:component?)
       (delete-duplicates (sort (apply append (map find-events-p (ast:body (ast:statements (ast:behaviour ast))))) list<)))
      ((? ast:interface?) 
       (let ((declared (ast:body (ast:events ast))))
         (receive (keep discard) 
             (partition predicate declared)
           (let* ((behaviour (apply append (map find-events-p (ast:body (ast:statements (ast:behaviour ast))))))
                  (behaviour-keep (filter (lambda (x) (negate (member x discard equal?))) behaviour)))
             (map ast:identifier (delete-duplicates (sort (append keep behaviour-keep) list<) equal?))))))
      (('statements t ...) (append (apply append (map find-events-p t)) events))
      (('on t statement) (map find-events-p t))
      (('field type identifier) ast)
      (('guard expression statement) (find-events-p statement events))
      ((? symbol?) (ast:make 'in 'void ast)))))

(define (->string src)
  (match src
    (#f "false")
    (#t "true")
    (('field struct name) (->string (list struct "." name)))
    ((identifier 'field x y) (string-join (list (->string identifier)  "=" (->string (cdr src)))))
    ((h ... t) (apply string-append (map ->string src)))
    ((h . t) (string-join (list (->string h) "=" (->string t))))
    (((h ... t)) (->string (car src)))
    (_ ((@ (language asd misc) ->string) src))))

(define (->join lst infix) (string-join (map ->string lst) infix))
(define (comma-space-join lst) (->join lst ", "))

(define (event< a b)
  (match a
    ((? symbol?) (symbol< a b))
    ((h ... t) (list< a b))))
