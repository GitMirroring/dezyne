;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2020 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Dezyne Language lookup in parse trees
;;;
;;; Code:

;;; XXX TODO: use MATCH instead of first, second, third, fourth
;;; XXX TODO: sort-out lookup:name vs tree:name
;;; XXX TODO: move AST bits into library

(define-module (gaiag parse lookup)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (gaiag parse tree)
  #:export (lookup:name ;; XXX sort out tree:name
            lookup-definition))

;;;
;;; Utilities.
;;;

(define (assert-type o . any-of-types)
  (unless (any (cute <> o) (map is? any-of-types))
    (throw 'assert (format #f "~a is not one of type: ~a\n" o any-of-types))))

(define (assert-predicate o . pred) ;;consider macro
  (unless (every (cute <> o) pred)
    (throw #t (format #f "~a does not meet every precondition: ~a\n" o pred))))

(define (head-name o)
  (cond ((is-a? o 'name) o)
        ((is-a? o 'compound-name)
         (let ((scope (slot o 'scope))
               (name (slot o 'name)))
           (if scope (second scope) name)))
        (else #f)))

(define (tail-name o)
  (cond ((is-a? o 'name) #f)
        ((is-a? o 'compound-name)
         (let ((scope (slot o 'scope))
               (name (slot o 'name)))
           (if (and scope (pair? (cddr scope))) (list 'scope (cddr scope) name) name)))
        (else #f)))

(define (lookup:name o) ;;; FIXME, see tree:name
  (match o
    ((? (is? 'name)) o)
    ((? (is? 'port)) (slot o 'name))
    ((? (is? 'event)) (slot (slot o 'event-name) 'name))
    ((? (is? 'variable)) (slot o 'name))
    ((? (is? 'var)) (slot o 'name))
    (_ (or (slot o 'name) (slot o 'compound-name)))))

(define (flatten name)
  ;;(assert-type name 'name 'compound-name 'scope)
  (cond ((is-a? name 'name) (list (second name)))
        ((is-a? name 'event-name) (list (second name)))
        ((and (is-a? name 'compound-name) (slot name 'scope))
         (append (flatten (slot name 'scope)) (flatten (slot name 'name))))
        ((is-a? name 'compound-name) (flatten (slot name 'name)))
        (is-a? name 'scope) (append-map flatten (cdr name))))

(define (equal-name? name1 name2)
  ;;(assert-type name1 'name 'compound-name)
  ;;(assert-type name2 'name 'compound-name)
  (let ((flat1 (flatten name1))
        (flat2 (flatten name2)))
    (equal? flat1 flat2)))

(define (common-prepart? name1 name2)
  ;;(assert-type name1 'name 'compound-name)
  ;;(assert-type name2 'name 'compound-name)
  (let* ((first1 (head-name name1))
         (first2 (head-name name2)))
    (equal? (second first1) (second first2))))

(define (list-head? o)
  (and (pair? o) (pair? (car o))))

(define (defines-scope? o)
  (or (is-a? o 'root)
      (is-a? o 'namespace)
      (is-a? o 'interface)
      (is-a? o 'component)
      (is-a? o 'system)
      (is-a? o 'compound)
      (is-a? o 'enum)
      (is-a? o 'trigger)
      (is-a? o 'behaviour)
      (is-a? o 'function)))

(define (declaration? o)
  (or (is-a? o 'namespace)
      (is-a? o 'interface)
      (is-a? o 'component)
      (is-a? o 'enum)
      (is-a? o 'extern)
      (is-a? o 'bool)
      (is-a? o 'void)
      (is-a? o 'int)
      (is-a? o 'event)
      (is-a? o 'instance)
      (is-a? o 'port)
      (is-a? o 'variable)
      (is-a? o 'formal)
      (is-a? o 'behaviour)
      (is-a? o 'function)))

(define (make-list-head o)
  (if (list-head? o) o (list o)))

(define (declaration* o)
  (match o
    ((? (is? 'root)) (filter declaration? (cdr o)))
    ((? (is? 'namespace)) (make-list-head (third o))) ;; models, types
    ((? (is? 'interface)) (filter declaration? (cdr (third o)))) ;; types, events
    ((? (is? 'component)) (append (filter declaration? (cdr (third o))) ;; ports
                                  (if (is-a? (fourth o) 'system)
                                      (filter declaration? (cdr (second (fourth o))))  ;; instances
                                      '())))
    ((? (is? 'behaviour)) (filter declaration? (cdr (second o)))) ;; types, functions, variables, ports(async)
    ((? (is? 'compound)) (filter (is? 'variable) (cdr o))) ;; variables
    ((? (is? 'enum)) (filter (is? 'name) (cdr (slot o 'fields)))) ;; fields
    ((? (is? 'trigger)) (let ((formals (slot o 'trigger-formals)))
                          (if formals (filter (is? 'trigger-formal) (cdr formals))) '())) ;; formals
    ((? (is? 'function)) (filter (is? 'formal) (cdr (slot o 'formals)))) ;; formals
    (_ '())))

(define (empty-namespace? name) #f) ;; TODO: implement


;;;
;;; Lookup, lookdown.
;;;

(define (lookup name context)
  (match (lookup-list name context)
    ((first rest ...) first)
    (_ #f)))

(define (look name o)
  (let ((name-o (lookup:name o)))
    (cond ((not (defines-scope? o)) '())
          ((and (is-a? name 'compound-name) (not (slot name 'scope)))
           (look (slot name 'name) o))
          ((is-a? name 'compound-name)
           (let* ((head (head-name name))
                  (found-head (look head o)))
             (if (null? first-head) '()
                 (lookdown (tail-name name) first-head))))
          ((is-a? name 'name)
           (cond ((empty-namespace? name) (if (is-a? o 'root) (list o) '()))
                 (else (filter (lambda (decl) (equal-name? (lookup:name decl) name)) (declaration* o)))))
          (else '()))))

(define (lookup-list name context)
  (assert-predicate context pair?)
  (let* ((current (car context))
         (currents (if (list-head? current) current (list current)))
         (found (append-map (cut look name <>) currents)))
    (cond ((pair? found) found)
          ((null? (cdr context)) '())
          (else (lookup-list name (cdr context))))))

(define (lookdown name o)
  (cond ((pair? current) (append-map (cut lookdown name <>) current))
        ((not (defines-scope? o)) '())
        ((is-a? name 'name)
         (filter (lambda (decl) (equal-name? (lookup:name decl) name)) (declaration* o)))
        ((is-a? name 'compound-name)
         (let* ((head (head-name name))
                (found-head (lookdown head o)))
           (if (null? first-head) '()
               (lookdown (tail-name name) first-head))))
          (else '())))


;;;
;;; Resolvers.
;;;

(define (resolve-port-type t context)
  (let* ((models (cdr (last context)))
         (interfaces (filter (lambda (m) (equal? (first m) 'interface)) models)))
    (find (lambda (i) (equal? (second (second (second i))) (second t))) interfaces)))

(define (resolve-action o name context)
  (resolve-trigger o name context))

(define (resolve-port o name context)
  (unless ((is? 'port) o) (throw #t "not a port"))
  (and (equal-name? name (slot o 'compound-name)) (lookup name context)))

(define (resolve-trigger o name context)
  (assert-type o 'trigger 'action)
  (let* ((port-name (and (is-a? (third o) 'name) (second o)))
         (event-name (if port-name (third o) (second o))))
    (cond ((and port-name (equal-name? name port-name))
           (lookup port-name context))
          ((and port-name (equal-name? name event-name))
           (let* ((port (lookup port-name context))
                  (interface-name (and port (slot port 'compound-name)))
                  (interface (and interface-name (resolve-port port interface-name context))))
             (and interface (lookup event-name (list interface)))))
          ((and (not port-name) (equal-name? name event-name))
           (lookup event-name context))
          (else #f))))

(define (resolve-instance o name context)
  (assert-type o 'instance 'port)
  (if (equal-name? name (slot o 'compound-name)) (lookup name context)
      #f))

(define (resolve-var o name context)
  (assert-type o 'assign 'var)
  (match o
    ((? (is? 'assign))
     (if (equal-name? name (slot o 'name)) (lookup name context)
         #f))
    ((? (is? 'var))
     (if (equal-name? name (slot o 'name)) (lookup name context)
         #f))))


;;;
;;; Entry point.
;;;

(use-modules (gaiag misc))
(define* (lookup-definition name context #:key (file-name->parse-tree (const '())))
  "Return definition of NAME in CONTEXT or #f if it cannot be found,
using FILE-NAME->PARSE-TREE to search in imports."

  (define (lookup-import name import)
    (let* ((file-name (.file-name import))
           (tree      (and file-name (file-name->parse-tree file-name)))
           (result    (and tree (lookup name (list tree)))))
      (if (not result) '()
          `((,file-name ,result)))))

  (match name
    ((? (is? 'name))
     (let* ((context (cdr context)) ;; WTF? -- USE MATCH here...
            (simple? (not (and (pair? context)
                               (is-a? (car context) 'compound-name))))
            (name    (if simple? name (car context)))
            (context (if simple? context (cdr context)))
            (obj     (and (pair? context) (car context)))
            (context (and (pair? context) (cdr context)))
            (obj     (and (pair? context) obj))
            (result  (match obj
                       ((? (is? 'action))
                        (resolve-action obj name context))
                       ((? (is? 'port))
                        (resolve-port obj name context))
                       ((? (is? 'trigger))
                        (resolve-trigger obj name context))
                       ((? (is? 'instance))
                        (resolve-instance obj name context))
                       ((? (is? 'assign))
                        (resolve-var obj name context))
                       ((? (is? 'var))
                        (resolve-var obj name context))
                       (_ #f))))
       (if result result
           (let* ((root (parent context 'root))
                  (imports (tree:import* root))
                  (result (append-map (cut lookup-import name <>) imports)))
             (match result
               ((first rest ...) first)
               (_ #f))))))
    (_ #f)))
