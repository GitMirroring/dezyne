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

(define-module (language asd ast)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 receive)

  :use-module (srfi srfi-1)
  :use-module (system foreign)

  :use-module (language asd asd)
  :use-module (language asd misc)
  :use-module (language asd reader)

  :export (
           ast
           behaviour
           behaviour?
           body
           bottom?
           class
           component
           component?
           compound
           declarative?
           dir-matches?
           direction
           elements
           enum?
           event?
           events
           events?
           expression
           find-events
           field?
           guard?
           guard-equals?
           identifier
           in?
           initial-value
           interface
           interface?
           make
           module?
           name
           out?
           parent
           port
           port?
           ports
           provides?
	   read-ast
           requires?
           statement
           statements-of-type
           type
           type-name-component
           typed?
           types
           types?
           variable
           variable?
           variables
           variables?
           ))

(define (make . t)
  (apply (@@ (language asd asd) ast:make) t))

(define (member- ast name) (or (assoc name (body ast)) '()))

(define (module? ast) (or (interface? ast) (component? ast)))
(define (type? type ast)
  (and (pair? ast)
       (let ((head (car ast)))
         (case type
           ((event) (member head '(in out)))
           ((port) (member head '(provides requires)))
         (else (eq? head type))))))

(define (behaviour? ast) (type? 'behaviour ast))
(define (component? ast) (type? 'component ast))
(define (compound? ast) (type? 'compound ast))
(define (enum? ast) (type? 'enum ast))
(define (event? ast) (type? 'event ast))
(define (events? ast) (type? 'events ast))
(define (field? ast) (type? 'field ast))
(define (guard? ast) (type? 'guard ast))
(define (interface? ast) (type? 'interface ast))
(define (variable? ast) (type? 'declare ast)) ;;; FIXME
(define (on? ast) (type? 'on ast))
(define (port? ast) (type? 'port ast))
(define (ports? ast) (type? 'ports ast))
(define (types? ast) (type? 'types ast))
(define (variables? ast) (type? 'variables ast))

(define (body ast)
  (match ast
    ((or (? behaviour?) (? module?))
     (or (and (>2 (length ast)) (cddr ast)) '()))
    ((or (? events?) (? guard?) (? ports?) (? compound?) (? on?) (? types?) (? variables?))
     (cdr ast))
    ('() ast)))

(define (interface- ast) (assoc 'interface ast))

(define (interface ast)
  (and-let* ((interface-ast (interface- ast))
             (name (name interface-ast)))
            (if (not (assoc-ref *ast-alist* name))
                (ast-add name interface-ast))
            interface-ast))

(define (events ast)
  (match ast
    ((? interface?) (member- ast 'events))
    ((? on?) (cadr ast))
    ((? port?) (events (import-ast (type ast))))))

(define (behaviour ast)
  (match ast
    ((? module?) (member- ast 'behaviour))
    ((? port?) (behaviour (import-ast (type ast))))))

(define (component ast) (assoc 'component ast))

(define (ports ast) (match ast ((? component?) (member- ast 'ports))))

(define* (port ast :optional (name #f))
  (if name
      (find (lambda (p) (eq? (identifier p) name))
            (body
             (match ast
               ((? ports?) ast)
               ((? component?) (ports ast)))))
      (match ast
        ((? component?) (assoc 'provides (body (ports ast)))))))

(define (direction ast) (match ast ((or (? event?) (? port?)) (car ast))))
(define (elements ast) (match ast ((? enum?) (caddr ast))))
(define (expression ast) (match ast ((? guard?) (cadr ast))))

(define (identifier ast)
  (match ast
    ((or (? event?) (? field?) (? port?) (? variable?)) (caddr ast))))

(define (in? ast) (match ast ((? event?) (eq? (direction ast) 'in))))
(define (out? ast) (match ast ((? event?) (eq? (direction ast) 'out))))

(define (name ast)
  (match ast
    ((or (? behaviour?) (? enum?) (? module?))
     (or (and (>1 (length ast)) (cadr ast)) ""))))

(define (class ast)
  (match ast 
    ((? event?) 'event)
    ((? field?) 'field)
    ((? port?) 'port)
    ((? variable?) 'variable?)
    (_ (car ast))))

(define (statement ast)
  (match ast
    ((? module?) (statement (behaviour ast)))
    ((? behaviour?) (or (assoc 'compound (body ast)) (make 'compound '())))
    ((? guard?) (caddr ast))
    ((? on?) (caddr ast))))

(define (type ast)
  (match ast 
    ((or (? event?) (? field?) (? port?) (? variable?)) (cadr ast))))

(define (types ast)
  (match ast
    ((or (? interface?) (? behaviour?)) (member- ast 'types))
    ((? component?) (types (behaviour ast)))
    ((? port?) (types (import-ast (type ast))))))

(define (variables ast)
  (match ast
    ((? behaviour?) (member- ast 'variables))
    ((? interface?) (make (cons 'variables (append (body (member- ast 'variables)) 
                                                   (body (variables (behaviour ast)))))))
    ((? component?) (variables (behaviour ast)))
    ((? port?) (variables (import-ast (type ast))))))


;;;;; FIXME

(define (type-name-component type component) (symbol-append (name component) (type type)))

(define (enum-name enum) (cadr enum))

;;;?(define (type-name type) (car type))

(define (initial-value variable) (cadddr variable))


;;; utilities
(define (declarative? statement)
  (or (on? statement) (guard? statement)))

(define (provides? ast) (eq? (direction ast) 'provides))
(define (requires? ast) (eq? (direction ast) 'requires))

(define (guard-equals? lhs rhs) (equal? (expression lhs) (expression rhs)))

(define (typed? ast)
  (match ast
    ((? event?) (not (eq? (type ast) 'void)))
    ((? port?) (null-is-#f (filter typed? (body (events ast)))))))

(define (dir-matches? port)
  (lambda (event)
    (or (and (eq? (direction port) 'provides)
             (eq? (direction event) 'in))
        (and (eq? (direction port) 'requires)
             (eq? (direction event) 'out)))))

(define (bottom? ast)
  (and-let* ((ports (body (ports ast)))
             ((=1 (length ports))))
            (provides? (car ports))))

;;; walkers

(define ((statement-of-type type) statement)
  (and (eq? (car statement) type) statement))

(define ((statements-of-type type) statement)
  (match statement
    ((? (statement-of-type type)) (list statement))
    (('compound h ...) (filter identity (map (statement-of-type type) h)))))

(define (parent ast lst)
  (if (object? lst)
    (id-parent ast (object-id lst))
    #f))

(define (id-parent ast id)
  (let loop ((ast ast) (stack '()))
    (if (null? ast)
        (if (null? stack)
            #f
            (loop (car stack) (cdr stack)))
        (let ((children (map object-id ast)))
          (if (member id children)
              ast
              (if (pair? (car ast))
                  (loop (car ast) (cons (cdr ast) stack))
                  (loop (cdr ast) stack)))))))

(define* ((find-events :optional (predicate identity)) ast :optional (found '()))
  (let ((find-events-p (lambda* (ast :optional (found '()))
                         ((find-events predicate) ast found))))
    (match ast
      ((? component?)
       (delete-duplicates (sort (find-events-p (statement (behaviour ast))) list<)))
      ((? interface?) 
       (let ((declared (body (events ast))))
         (receive (keep discard) 
             (partition predicate declared)
           (let* ((behaviour (find-events-p (statement (behaviour ast))))
                  (behaviour-keep (filter (lambda (x) (negate (member x discard equal?))) behaviour)))
             (map identifier (delete-duplicates (sort (append keep behaviour-keep) list<) equal?))))))
      (('compound t ...) (append (apply append (map find-events-p t)) found))
      (('on t statement) (map find-events-p t))
      (('field type identifier) ast)
      (('guard expression statement) (find-events-p statement found))
      ((? symbol?) (make 'in 'void ast)))))

;;;; reading/caching
(define *ast-alist* '(()))
(define (ast-add name ast)
  (set! *ast-alist* (assoc-set! *ast-alist* name ast))
  ast)

(define (read-ast name)
  (read-asd (->string (list 'examples '/ name '.asd))))

(define (import-ast name)
  (or (assoc-ref *ast-alist* name)
      (and-let* ((ast (read-ast name)))
                (ast-add name (car ast)))))

(define ast import-ast)


