;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; Code:

(read-set! keywords 'prefix)

(define-module (g guile om)
  :use-module (srfi srfi-1)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)    
  :use-module (ice-9 match) 
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

;;  :use-module (language dezyne location)
  :use-module (gaiag annotate)
  
  :use-module (g g)  
  :use-module (g reader)
  :use-module (g misc)
  :use-module (g guile util)   

  :export (
           ast->gom
           ast-name
           gom->list
           gom:children
           collect
           gom:collect
           gom:filter
           gom:guard-equal?
           gom:map

           gom:register

           gom:import
           gom:imported?

           gom:enum
           gom:event           
           gom:extern
           gom:function           
           gom:integer

           gom:port
           
           gom:register-model
           gom:register-type
           gom:triggers-equal?
           gom:type
           gom:types           
           gom:variable
           ))

(cond-expand-provide (current-module) '(guile-om))

(define (xgom:map f o)
  (stderr "gom map: ~a ==> ~a\n" o (ast-list? o))
  (match o
    ((? ast-list?)
     (list (car o) (map f (.elements o))))
    ;; ?? ((h t ...) (map (lambda (x) (gom:map f x)) o))
    (_ (f o))))

(define (xgom:map f o)
  (stderr "gom map: ~a ==> ~a\n" o (ast-list? o))
  (match o
    ;;    ((? ast-list?) (list (car o) (map f (.elements o))))
    ((? ast?) (cons (car o) (gom:map f (cdr o))))
    ((h t ...) (map (lambda (x) (gom:map f x)) o))
    (_ o)))

(define (xgom:map f lst)
  (stderr "gom map: ~a ==> ~a\n" lst (ast-list? lst))
  (list (car lst) (map f (.elements lst))))

(define (gom:map f o)
  (stderr "gom map: ~a ==> ~a\n" o (ast-list? o))
  (match o
    ((? ast-list?) (list (car o) (map f (.elements o))))
    ((h t ...) (cons (car o) (map f (cdr o))))
    (_ o)))

(define ast->gom ast:annotate)
(define gom->list identity)
(define ((gom:type model) o)
  (match o
    ((? symbol?) (find (named o) (gom:types model)))
    (('type 'bool) o)
    (('type 'void) o)    
    (('type name) (find (named name) (gom:types model)))
    (('type name scope) (find (scoped name scope) (gom:types model)))
    (('variable name type expression) ((gom:type model) type))))

(define ((named name) ast)
  (eq? (.name ast) name))

(define ((scoped name scope) ast)
  (and (eq? (.name ast) name)
       (or (eq? (.scope ast) scope)
           (and (not scope)
                (eq? (.scope ast) '*global*)))))

(define* (gom:port model :optional (name #f))
  (find
   (if name (named name) (lambda (x) (eq? (.direction x) 'provides)))
   (.elements (.ports model))))

(define (gom:event model o)
  (find (named o) ((compose .elements .events) model)))
(define (gom:variable model o)
  (find (named o) (or (and=> (.behaviour model) (compose .elements .variables)) '())))
(define (gom:function model o)
  (find (named o) (or (and=> (.behaviour model) (compose .elements .functions)) '())))

(define (gom:enum model identifier)
  (enum? ((gom:type model) identifier)))
(define (gom:extern model identifier) (extern? ((gom:type model) identifier)))
(define (gom:integer model identifier) (integer? ((gom:type model) identifier)))
(define* (gom:types :optional (model #f))
  (append
   (match model
     (#f '())
     (('interface name types events ('behaviour b btypes _ ...)) (append (.elements btypes) (.elements types)))
     (('component name ports ('behaviour b btypes _ ...))
      (append (.elements btypes) (apply append (map interface-types ports))))
     (('root models ...) (filter type? models))) 
   (globals)))

(define (interface-types port)
  (let ((scope (.type port)))
   (map (lambda (o)
          (match o
            (('enum name _ fields) (list 'enum name scope fields))
            (('extern name _ value) (list 'extern name scope value))
            (('int name _ range) (list 'int name scope range))))
        ((compose public-types ast .type) port))))

(define (public-types ast)
  (match ast
    ((? interface?) ((compose .elements .types) ast))))

(define ((collect predicate) o)
  (match o
    (('compound t ...)
     (filter identity (apply append (map (collect predicate) t))))
    (('guard e s) (filter identity ((collect predicate) s)))
    (('on t s) (filter identity ((collect predicate) s)))
    ((? (compose null-is-#f predicate)) (list o))
    ;; TODO: component, interface, behaviour?
    ;; (('root models ...)
    ;;  (filter identity (apply append (map (collect predicate) models))))
    ;; sharp axe method
    ((h t ...)
     (filter identity (apply append (map (collect predicate) o))))
    (_ '())))

(define ((gom:collect x) o)
  (match x
    (symbol? ((collect (is? x)) o))
    (procedure? ((collect x) o))))

(define ((gom:filter x) o)
  (match x
    (symbol? (filter (is? x) o))
    (procedure? (filter x o))))

(define (gom:guard-equal? lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
   (equal? (.expression lhs) (.expression rhs))))

(define (gom:children o)
  (cdr o))

(define (ast-name o) (car o))

(define (remove-arguments o)
  (match o
    (('trigger p e arguments) (list 'trigger p e))
    (_ o)))

(define (gom:triggers-equal? a b)
  (equal? (map remove-arguments (.triggers a))
          (map remove-arguments (.triggers b))))

;;;; OM handling

(use-modules (system base lalr))

(define (source-location src)
  (and-let* (((supports-source-properties? src))
	     (loc (source-property src 'loc)))
	    (if (source-location? loc)
		loc
		(source-location loc))))

(define (source-location->user-source-properties loc)
  `((filename . ,(source-location-input loc))
    (line . ,(+ 1 (source-location-line loc)))
    (column . ,(+ 1 (source-location-column loc)))
    (offset . ,(source-location-offset loc))
    (length . ,(source-location-length loc))))


(define (source-file o)
  (and-let* (((supports-source-properties? o))
             (loc (source-property o 'loc))
             (properties (source-location->user-source-properties loc))
             (file-name (assoc-ref properties 'filename)))
            (string->symbol file-name)))

(define (basename- o)
  (string->symbol (basename (symbol->string o))))

(define (in-file? o file)
  (let ((file (if (string? file) (string->symbol file) file)))
    (and-let* ((model-file (source-file o))
               (model-file (if (string? model-file) (string->symbol model-file) model-file)))
              (eq? (basename- file) (basename- model-file)))))

;; (define (parse-opts x)  ((@@ (g g) parse-opts) x))

(define (gom:imported? o)
  (if (assoc 'imported? (source-properties o))
      (source-property o 'imported?)
      (and-let* (((>2 (length (command-line))))
                 (file (car (option-ref (parse-opts (command-line)) '() '(#f))))
                 ((not (string-suffix? ".scm" file))))
                (not (in-file? o file)))))

;;;; reading/caching
(define *ast-alist* '())
(define (ast-add name ast)
  (set! *ast-alist* (assoc-set! *ast-alist* name ast))
  ast)

(define (register-model m)
  (and-let* ((name (.name m)))
            (if (not (assoc-ref *ast-alist* name))
                (ast-add name m))
            m))

(define (register-type t)
  (and-let* ((name (.name t)))
            (if (not (assoc-ref *ast-alist* name))
                (ast-add name t))
            t))

(define (globals)
  (filter type? (map cdr *ast-alist*)))

(define* (register ast :optional (clear? #f))
  (if clear?
      (set! *ast-alist* '()))
  (for-each register-model (filter model? ast))
  (for-each register-type (filter type? ast))
  ast)

;; procedure: ast:import MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define (read-ast model-name)
  (and-let* ((ast (null-is-#f (read-dzn (list model-name '.dzn))))
             (models (null-is-#f (filter model? ast))))
            (find (lambda (model) (eq? (.name model) model-name)) models)))

(define* (import-ast name #:optional (transform identity))
  "
procedure: ast:import MODEL-NAME

Read and parse the ASD source file for MODEL-NAME, return its AST.

"
  (or (assoc-ref *ast-alist* name)
      (and-let* ((ast (transform (read-ast name))))
                (ast-add name ast))))

;; procedure: ast:ast MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define ast import-ast)

;; 
(define gom:register-type register-type)
(define gom:register-model register-model)
(define gom:register register)

