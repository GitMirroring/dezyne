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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gr record util)
  :use-module (srfi srfi-1)

  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (language dezyne location)

  :use-module (gr gaiag)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :use-module (gr record om)

  :export (
           om:named
           om->list
           collect
           om:collect
           om:filter
           om:guard-equal?
           om:declarative?
           om:imperative?
           om:map

           om:register

           om:import
           om:imported?

           om:enum
           om:event
           om:extern
           om:function
           om:integer

           om:port

           om:register-model
           om:register-type
           om:triggers-equal?
           om:type
           om:types
           om:variable
           om:variables           
           om:<
           om:equal?
           ))

(define ((om:named name) model)
  (eq? (.name model) name))

(define (om->list o)
  (match o
    ((? (is? <ast>)) (cons (ast-name o) (map om->list (om:children o))))
    ((h t ...) (map om->list o))
    (_ o)))

(define (om:map f o)
  (match o
    ((? (is? <ast>)) (om:clone o f))
    ((h t ...) (map (lambda (x) (om:map f x)) o))
    (_ (f o))))

(define ((collect predicate) o)
  (match o
    (($ <compound> s)
     (filter identity (apply append (map (collect predicate) s))))
    (($ <guard> e s) (filter identity ((collect predicate) s)))
    (($ <on> t s) (filter identity ((collect predicate) s)))
    ((? (compose null-is-#f predicate)) (list o))
    ;; TODO: component, interface, behaviour?
    ;; (('root models ...)
    ;;  (filter identity (apply append (map (collect predicate) models))))
    ;; sharp axe method
    ((h t ...)
     (filter identity (apply append (map (collect predicate) o))))
    (_ '())))

(define ((om:collect x) o)
  (match x
    ((? procedure?) ((collect x) o))
    (_ ((collect (is? x)) o))))


(define ((named name) ast)
  (eq? (.name ast) name))

(define ((scoped name scope) ast)
  (and (eq? (.name ast) name)
       (or (eq? (.scope ast) scope)
           (and (not scope)
                (eq? (.scope ast) '*global*)))))

(define ((om:type model) o)
  (match o
    ((? symbol?) (find (named o) (om:types model)))
    (($ <type> 'bool) o)
    (($ <type> 'void) o)
    (($ <type> name #f) (find (named name) (om:types model)))
    (($ <type> name scope) (find (scoped name scope) (om:types model)))
    (($ <variable> name type expression) ((om:type model) type))))

(define* (om:port model :optional (name #f))
  (find
   (if name (named name) (lambda (x) (eq? (.direction x) 'provides)))
   (.elements (.ports model))))

(define (om:event model o)
  (find (named o) ((compose .elements .events) model)))
(define (om:variable model o)
  (find (named o) (or (and=> (.behaviour model) (compose .elements .variables)) '())))
(define (om:function model o)
  (find (named o) (or (and=> (.behaviour model) (compose .elements .functions)) '())))

(define (om:variables model)
  ((compose .elements .variables .behaviour) model))

(define (om:enum model identifier)
  ((is? <enum>) ((om:type model) identifier)))
(define (om:extern model identifier) ((is? <extern>) ((om:type model) identifier)))
(define (om:integer model identifier)
  ((is? <int>) ((om:type model) identifier)))
(define* (om:types :optional (model #f))
  (append
   (match model
     (#f '())
     (($ <interface> name ($ <types> types) events ($ <behaviour> b ($ <types> btypes) _ ...)) (append btypes types))
     (($ <component> name ($ <ports> ports) ($ <behaviour> b ($ <types> btypes) _ ...))
      (append btypes (apply append (map interface-types ports))))
     (($ <root> models) (filter (is? <*type*>) models)))
   (globals)))

(define (interface-types port)
  (let ((scope (.type port)))
   (map (lambda (o)
          (match o
            (($ <enum> name _ fields) (make <enum> :name name :scope scope :fields fields))
            (($ <extern> name _ value) (make <extern> :name name :scope scope :value value))
            (($ <int> name _ range) (make <int> name :name :scope scope :range range))))
        ((compose public-types ast .type) port))))

(define (public-types ast)
  (match ast
    ((? (is? <interface>)) ((compose .elements .types) ast))))

(define ((om:filter x) o)
  (match x
    (symbol? (filter (is? x) o))
    (procedure? (filter x o))))

(define (om:declarative? o)
  (or (is-a? o <guard>)
      (is-a? o <on>)
      (and (is-a? o <compound>)
           (>0 (length (.elements o)))
           (om:declarative? (car (.elements o))))))

(define om:imperative? (negate om:declarative?))

;; compare
(define (om:guard-equal? lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
       (equal? (om->list (.expression lhs))
               (om->list (.expression rhs)))))

(define (om:triggers-equal? lhs rhs)
  (and (is-a? lhs <on>) (is-a? rhs <on>)
       (equal? (map remove-arguments ((compose .elements .triggers) lhs))
               (map remove-arguments ((compose .elements .triggers) rhs)))))

(define (remove-arguments o)
  (match o
    (($ <trigger> p e arguments) (list 'trigger p e))
    (_ o)))

(define (om:equal? a b)
  (cond
   ((is-a? a <ast>)
    (and (is-a? b <ast>)
         (eq? (ast-name a) (ast-name b))
         (match (cons a b)
           ((($ <trigger> p e) . ($ <trigger> p e)) #t)
           ((($ <trigger>) . ($ <trigger>)) (equal? (remove-arguments a) (remove-arguments b)))
           ((($ <literal> scope type field) . ($ <literal> scope type field)) #t)
           (_ (equal? (om->list a) (equal? om->list b))))))
   (else (equal? a b))))

(define (om:< a b)
  (match (cons a b)
    ((($ <guard> ea sa) . ($ <on> tb sb)) #t)
    ((($ <on> ta sa) . ($ <guard> eb sb)) #f)
    
    ((($ <guard> ea sa) . ($ <guard> eb sb)) (om:< ea eb))
    ((($ <on> ta sa) . ($ <on> tb sb)) (om:< ta tb))

    ((($ <expression> va) . ($ <otherwise> vb)) #t)
    ((($ <otherwise> va) . ($ <expression> vb)) #f)
    ((($ <expression> va) . ($ <expression> vb))
     (om:< (om->list va) (om->list vb)))

    ((($ <triggers> ta) . ($ <triggers> tb))
     (om:< (stable-sort ta om:<) (stable-sort tb om:<)))

    ((($ <trigger>) . ($ <trigger>))
     (om:< (remove-arguments a) (remove-arguments b)))

    ((() . ()) #f)
    ((() . (hb tb ...)) #t)
    (((ha ta ...) . ()) #f)
    (((ha ta ...) . (hb tb ...))
     (cond
      ((and (not (om:< (car a) (car b)))
            (not (om:< (car b) (car a))))
       (om:< (cdr a) (cdr b)))
      (else (om:< (car a) (car b)))))
    (((? symbol?) . (? symbol?)) (symbol< a b))
    (((? symbol?) . (? boolean?)) #f)
    (((? boolean?) . (? symbol?)) #t)
    ((#t . #t) #f)
    ((#f . #f) #f)
    ((#f . #t) #t)
    ((#t . #f) #f)
    (_ (< a b))))

;;;; OM handling

(use-modules (system base lalr))

(define (source-location src)
  (and-let* (((supports-source-properties? src))
	     (loc (source-property src 'loc)))
	    (if (source-location? loc)
		loc
		(source-location loc))))

(define (source-location->user-source-properties loc)
  (if (not (source-location? loc))
      (begin
        (stderr "programming error: not a source location: ~a\n" loc)
        '((filename . "unknown") (line . 0 )))
      `((filename . ,(source-location-input loc))
        (line . ,(+ 1 (source-location-line loc)))
        (column . ,(+ 1 (source-location-column loc)))
        (offset . ,(source-location-offset loc))
        (length . ,(source-location-length loc)))))


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

(define (om:imported? o)
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
  (filter (is? <*type*>) (map cdr *ast-alist*)))

(define* (register ast :optional (clear? #f))
  (if clear?
      (set! *ast-alist* '()))
  (for-each register-model (filter (is? <model>) ast))
  (for-each register-type (filter (is? <*type*>) ast))
  ast)

;; procedure: ast:import MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define (read-ast model-name)
  (and-let* ((ast (null-is-#f (read-dzn (list model-name '.dzn))))
             (models (null-is-#f (filter (is? <model>) ast))))
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
(define om:register-type register-type)
(define om:register-model register-model)
(define* ((om:register :optional (translate identity)) o :optional (clear? #f))
  (register (translate o) clear?))
