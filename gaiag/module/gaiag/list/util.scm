;;; Dezyne --- Dezyne command line tools
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

(define-module (gaiag list util)
  :use-module (srfi srfi-1)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)    
  :use-module (gaiag list match) 
  :use-module (ice-9 optargs)
  :use-module (ice-9 pretty-print)

  :use-module (language dezyne location)
  :use-module (gaiag annotate)
  
  :use-module (gaiag gaiag)  
  :use-module (gaiag reader)
  :use-module (gaiag misc)
  :use-module (gaiag list om)   

  :export (
           ast->om
           ast-name
           om->list
           om:children
           collect
           om:collect
           om:filter
           om:find-triggers
           om:guard-equal?
           om:map
           om:named
           om:scoped           
           om:declarative?
           om:imperative?

           om:import
           om:imported?

           om:enum
           om:event           
           om:extern
           om:function           
           om:integer

           om:port
           
           om:register
           om:register-model
           om:register-type
           om:triggers-equal?
           om:type
           om:types           
           om:variable

           om:variables
           om:functions
           
           om:<
           om:equal?

           om:in?
           om:out?
           om:out-or-inout?
           om:provides?
           om:requires?
           om:ports
           om:interface           

           
           ))

(define (om:map f o)
  (match o
    ((? (is? <ast-list>))
     (retain-source-properties o (cons (car o) (map f (.elements o)))))
    ((h t ...) (retain-source-properties o (cons (car o) (map f (cdr o)))))
    (_ o)))


(define ast->om ast:annotate)
(define om->list identity)
(define ((om:type model) o)
  (match o
    ((? symbol?) (find (om:named o) (om:types model)))
    (('type 'bool) o)
    (('type 'void) o)    
    (('type name) (find (om:named name) (om:types model)))
    (('type name scope) (find (om:scoped name scope) (om:types model)))
    (('variable name type expression) ((om:type model) type))))

(define ((om:named name) ast)
  (eq? (.name ast) name))

(define ((om:scoped name scope) ast)
  (and (eq? (.name ast) name)
       (or (eq? (.scope ast) scope)
           (and (not scope)
                (eq? (.scope ast) '*global*)))))

(define* (om:port model :optional (name #f))
  (find
   (if name (om:named name) (lambda (x) (eq? (.direction x) 'provides)))
   (.elements (.ports model))))

(define (om:event model o)
  (find (om:named o) ((compose .elements .events) model)))
(define (om:variable model o)
  (find (om:named o) (or (and=> (.behaviour model) (compose .elements .variables)) '())))
(define (om:function model o)
  (find (om:named o) (or (and=> (.behaviour model) (compose .elements .functions)) '())))

(define (om:variables model)
  ((compose .elements .variables .behaviour) model))

(define (om:functions model)
  ((compose .elements .functions .behaviour) model))

;; FIXME
(define* (om:find-triggers ast :optional (found '()))
  "Search for optional and inevitable."
  (match ast
    ((or ($ <interface>) ($ <component>))
     (or (and=> (.behaviour ast) om:find-triggers) '()))
    (($ <behaviour>) (or (and=> (.statement ast) om:find-triggers) '()))
    (('compound statements ...)
     (delete-duplicates (sort (append (apply append (map om:find-triggers statements))) om:<)))
    (($ <on>) (om:find-triggers (.triggers ast)))
    (('triggers triggers ...) triggers)
    (($ <guard>) (om:find-triggers (.statement ast) found))
    (('inevitable) ast)
    (('optional) ast)
    (('action x) '())
    (('illegal) '())
    (('skip) '())
    ('() ast)))

(define (om:enum model identifier) (is-a? ((om:type model) identifier) <enum>))
(define (om:extern model identifier) (is-a? ((om:type model) identifier) <extern>))
(define (om:integer model identifier) (is-a? ((om:type model) identifier) <int>))
(define* (om:types :optional (model #f))
  (append
   (match model
     (#f '())
     (('interface name types events ('behaviour b btypes _ ...)) (append (.elements btypes) (.elements types)))
     (('component name ports ('behaviour b btypes _ ...))
      (append (.elements btypes) (apply append (map interface-types (.elements ports)))))
     (('root models ...) (filter (is? <*type*>) models))
     (('import file) '()))
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
    ((? (is? <interface>)) ((compose .elements .types) ast))))

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

(define ((om:collect x) o)
  (match x
    (symbol? ((collect (is? x)) o))
    (procedure? ((collect x) o))))

(define ((om:filter x) o)
  (match x
    (symbol? (filter (is? x) o))
    (procedure? (filter x o))))

(define (om:guard-equal? lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
   (equal? (.expression lhs) (.expression rhs))))

(define (om:children o)
  (cdr o))

(define (ast-name o) (car o))

(define (om:declarative? o)
  (or (is-a? o <guard>)
      (is-a? o <on>)
      (and (is-a? o <compound>)
           (>0 (length (.elements o)))
           (om:declarative? (car (.elements o))))))

(define om:imperative? (negate om:declarative?))

(define (om:event o trigger)
  (match (cons o trigger)
    ((($ <interface>) . (? symbol?))
     (find (lambda (x) (eq? (.name x) trigger)) (.elements (.events o))))
    ((($ <interface>)  . (? (is? <trigger>)))
     (om:event o (.event trigger)))
    ((($ <component>)  . (? (is? <trigger>)))
     (om:event (om:interface (om:port o (.port trigger))) (.event trigger)))
    (_ #f)))

(define (om:in? o)
  (match o
    (($ <event>)
     (eq? (.direction o) 'in))
    (($ <trigger>) #t)))

(define (om:out? o)
  (match o
    (($ <event>)
     (eq? (.direction o) 'out))
    (($ <trigger>) #f)))

(define (om:out-or-inout? o)
  (match o
    (($ <formal>)
     (or (eq? (.direction o) 'out)
         (eq? (.direction o) 'inout)))))

(define (om:provides? o)
  (eq? (.direction o) 'provides))

(define (om:requires? o)
  (eq? (.direction o) 'requires))

;; ugh
(define (om:interface o)
  (match o
    (($ <port>) (om:import (.type o)))
    (($ <interface>) o)
    ((h t ...) (find (is? <interface>) o))))

;; compare
(define (remove-arguments o)
  (match o
    (('trigger p e arguments) (list 'trigger p e))
    (_ o)))

(define (om:triggers-equal? a b)
  (equal? (map remove-arguments (.triggers a))
          (map remove-arguments (.triggers b))))

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

(define (om:equal? a b)
  (or (and (is-a? a <trigger>)
           (is-a? b <trigger>)
           (equal? (remove-arguments a) (remove-arguments b)))
      (equal? a b)))

;;;; OM handling

(define (basename- o)
  (string->symbol (basename (symbol->string o))))

(define (in-file? o file)
  (let ((file (if (string? file) (string->symbol file) file)))
    (and-let* ((model-file (source-file o))
               (model-file (if (string? model-file) (string->symbol model-file) model-file)))
              (eq? (basename- file) (basename- model-file)))))

(define (parse-opts x)  ((@@ (gaiag gaiag) parse-opts) x))

(define (om:imported? o)
  (if (assoc 'imported? (source-properties o))
      (source-property o 'imported?)
      (and-let* (((>2 (length (command-line))))
                 (file (car (option-ref (parse-opts (command-line)) '() '(#f))))
                 ((not (string-suffix? ".scm" file))))
                (not (in-file? o file)))))

;;;; reading/caching
(define *ast-alist* '())

(define (cache-model name o)
  (set! *ast-alist* (assoc-set! *ast-alist* name o))
  o)

(define (cached-model name)
  (assoc-ref *ast-alist* name))

(define (globals)
  (filter (is? <*type*>) (map cdr *ast-alist*)))

;; (define* (register ast :optional (clear? #f))
;;   (if clear?
;;       (set! *ast-alist* '()))
;;   (for-each register-model (filter (is? <model>) ast))
;;   (for-each register-type (filter (is? <*type*>) ast))
;;   ast)

;; (define om:register-type register-type)
;; (define om:register-model register-model)

(define (om:register-model o)
  (if (not (cached-model (.name o)))
      (cache-model (.name o) o))
  o)

(define om:register-type om:register-model)

(define* ((om:register transform) ast :optional (clear? #f))
  (let ((om (transform ast)))
    (if clear?
        (set! *ast-alist* (filter (lambda (x) (is-a? (cdr x) <*type*>)) *ast-alist*)))
    (for-each om:register-model (filter (is? <model>) ast))
    (for-each om:register-type (filter (is? <*type*>) ast))
    om))

(define* (read-ast name #:optional (transform ast->om))
  (and-let* ((ast (null-is-#f (read-dzn name (om:register transform))))
             (models (null-is-#f (find (is? <model>) ast))))
            (find (lambda (model) (eq? (.name model) name)) models)))

(define* (om:import name #:optional (transform ast->om))
  (or (cached-model name)
      (and-let* ((ast (read-ast name transform)))
                (cache-model name ast))))

(define* (import-ast name #:optional (transform identity))
  "
procedure: ast:import MODEL-NAME

Read and parse the ASD source file for MODEL-NAME, return its AST.

"
  (or (assoc-ref *ast-alist* name)
      (and-let* ((ast (transform (read-ast name))))
                (cache-model name ast))))

;; procedure: ast:ast MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define ast import-ast)

