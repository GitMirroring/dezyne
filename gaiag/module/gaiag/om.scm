;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag om)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 optargs)

  :use-module (system foreign)
  :use-module (language dezyne location)

  :use-module (srfi srfi-1)

  ;;:use-module (gaiag goops goops) ;; GOOPS backend
  :use-module (gaiag list goops)  ;; LIST backend

  :use-module (gaiag list match)
  :use-module (gaiag annotate)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :export (
           om:collect
           om:declarative?
           om:dir-matches?
           om:drop-scope
           om:enum
           om:enums
           om:event
           om:events
           om:extern
           om:filter
           om:find-triggers
           om:function
           om:functions
           om:imperative?
           om:import
           om:imported?
           om:in?
           om:integers
           om:instance
           om:interface-enums
           om:integer
           om:interface
           om:interface-types
           om:interfaces
           om:model-with-behaviour
           om:name
           om:named
           om:out-or-inout?
           om:out?
           om:outer-scope?
           om:parent
           om:parse-dzn
           om:port
           om:ports
           om:public-types
           om:provided
           om:provides?
           om:register
           om:register-model
           om:register-type
           om:reply-enums
           om:required
           om:requires?
           om:scope
           om:scope+name
           om:scope-join ;; JUNKME
           om:scope-name
           om:scoped
           om:scoped-extern
           om:type
           om:typed?
           om:types
           om:variable
           om:variables
           ))

(cond-expand
 (goops-om
  (cond-expand-provide (current-module) '(goops-om))
  (re-export-modules
   (gaiag goops goops)))
 (list-om
  (cond-expand-provide (current-module) '(list-om))
  (re-export-modules
   (gaiag list goops)))
 (else
  ))

;;; AST-LIST shorthands
(define* (om:events o)
  (match o
    (($ <interface>) ((compose .elements .events) o))
    (($ <port>) ((compose om:events om:import .type) o))))

(define* (om:enums :optional (model #f))
  (filter (is? <enum>) (om:types model)))

(define* (om:externs :optional (model #f))
  (filter (is? <extern>) (om:types model)))

(define* (om:integers :optional (model #f))
  (filter (is? <int>) (om:types model)))

(define (om:functions model)
  ((compose .elements .functions .behaviour) model))

(define (om:ports o)
  (match o
    (($ <interface>) '())
    (($ <component> name ('ports ports ...)) ports)
    (($ <system> name ('ports ports ...)) ports)))

(define (om:provided o)
  (filter om:provides? (om:ports o)))

(define (om:required o)
  (filter om:requires? (om:ports o)))

(define* (om:types :optional (model #f))
  (append
   (match model
     (('root models ...) (filter (is? <*type*>) models))
     (($ <behaviour> b types) (.elements types))
     (($ <interface> name types events ($ <behaviour> b btypes)) (append (.elements btypes) (.elements types)))
     (($ <component> name ports ($ <behaviour> b btypes))
      (append (.elements btypes) (om:interface-types model)))
     (($ <component> name ports) (om:interface-types model))
     (($ <system> name ports) (om:interface-types model))
     (($ <import> name) '())
     (#f '())
     ((? unspecified?) '()))
   (globals)))

(define (om:variables model)
  ((compose .elements .variables .behaviour) model))

(define (om:interface-enums o)
  (match o
    (($ <interface>) (filter (is? <enum>) (.types o)))
    (($ <port>) (om:enums o))
    (($ <component>)
     (append-map om:interface-enums ((compose .elements .ports) o)))
    (($ <system>)
     (append-map om:interface-enums ((compose .elements .ports) o)))))


;;; SINGLE-LOOKUP

;; FIXME -- whut?
;; (define (om:event model o)
;;   (find (om:named o) (om:events model)))

(define (om:enum model identifier)
  (is-a? ((om:type model) identifier) <enum>))
(define (om:extern model identifier)
  (is-a? ((om:type model) identifier) <extern>))
(define (om:integer model identifier)
  (is-a? ((om:type model) identifier) <int>))

(define (om:event o trigger)
  (match (cons o trigger)
    ((($ <interface>) . (? symbol?))
     (find (lambda (x) (eq? (.name x) trigger)) (.elements (.events o))))
    ((($ <interface>)  . (? (is? <trigger>)))
     (om:event o (.event trigger)))
    ((($ <component>)  . (? (is? <trigger>)))
     (om:event (om:interface (om:port o (.port trigger))) (.event trigger)))
    (_ #f)))

(define (om:function model o)
  (find (om:named o) (om:functions model)))

(define (om:instance model o)
  (match o
    ((? symbol?)
     (find (lambda (x) (eq? (.name x) o)) ((compose .elements .instances) model)))
    (($ <binding>) (or (om:instance model (.instance o))
                       (om:import (.type (om:port model (.port bind))))))
    ((? boolean?) #f)))

(define (om:interface o)
  (match o
    (($ <port>) (om:import (.type o)))
    (($ <interface>) o)
    ((? (is? <model>)) (om:interface (om:port o)))
    (('name name ...) (cached-model o))
    ((h t ...) (find (is? <interface>) o))))

(define* (om:port model :optional (o #f))
  (match o
    (($ <binding>)
     (let* ((port (.port o)))
       (or
        (and-let* ((name (.instance o))
                   (instance (om:instance model name))
                   (type (and=> instance .component))
                   (component (om:import type)))
                  (om:port component port))
        (om:port model port))))
    (_ (find (if o (om:named o)
                 (lambda (x) (eq? (.direction x) 'provides)))
        (.elements (.ports model))))))

(define (om:variable model o)
  (find (om:named o) (om:variables model)))

(define (unspecified? x) (eq? x *unspecified*))

;;; TYPES

(define ((om:type model) o)
  (let ((r ((om:type- model) o)))
    ;;(stderr "\nom:type[~a]: ~a ==> ~a\n" (.name model) o r)
    ;;(stderr "TYPES[~a]: ~a\n" (.name model) (om:types model))
    r))

(define ((om:type- model) o)
  (match o
    ((? symbol?) (find (om:named `(name ,@(cdr (.name model)) ,o)) (om:types model)))
    (('name scope ... name)
     (find (om:named o) (om:types model)))

    ;; (('type name scope)
    ;;  (or (find (om:scoped name scope) (om:types model))
    ;;      (find (om:scoped-extern name scope) (om:types model))))

    ;; (($ <type> ('name scope ... name)) ((om:type- model) `(type ,name ,(cons 'name scope))))
    (($ <type> 'bool) o)
    (($ <type> 'void) o)
    (($ <type> name) (=> failure)
     ;;(stderr "SEARCHING FOR: ~a\n" name)
     (or (find (om:named name) (om:types model))
         (failure)))
    (($ <type> ('name name))
     ;; (stderr "SEARCHING FOR: ~a\n" (append (.name model) (list name)))
     (or (find (om:scoped (.name model) name) (om:types model))
         ;;(find (om:scoped-extern (.name model) name) (om:types model))
         ))
    (($ <type>) #f)
    (($ <variable> name type expression) ((om:type- model) type))
    (($ <formal> name type) ((om:type- model) type))
    (($ <formal> name type direction) ((om:type- model) type))
    (#f #f)))

(define ((om:named name) ast)
  (match name
    ((? symbol?) (or (eq? name (.name ast)) ((om:named `(name ,name)) ast)))
    (_ (equal? (.name ast) name))))

(define ((om:scoped scope name) ast)
  (equal? (append scope (list name)) (.name ast)))

(define ((om:scoped-extern scope name) ast)
  (or (append scope (list name)) (.name ast)
      (and (equal? (om:name ast) (om:name scope))
           (or (is-a? ast <extern>) ;; ignore scope on extern...
               (equal? (om:scope ast) (om:scope scope))
               (and (null? (om:scope scope))
                    (equal? (om:scope ast) '(*)))))))



;;; NAME/NAMESPACE/SCOPE
(define (om:scope+name o)
  (match o
    (('name name ...) name)
    (($ <instance> x name) (om:scope+name name))
    (($ <port> x name) (om:scope+name name))
    (($ <type> 'bool) '(bool))
    (($ <type> 'void) '(void))
    ((? (is? <named>)) ((compose om:scope+name .name) o))))

(define* ((om:scope-name :optional (infix '_)) o)
  (let ((infix (if (symbol? infix) infix
                   (string->symbol infix))))
    ((->symbol-join infix) (om:scope+name o))))

(define (om:outer-scope? model o)
  (and model (>1 (length o))
       (not (eq? ((compose car om:scope+name) model) (car o)))))

(define* ((om:scope-join :optional (model #f) (infix '_)) o)
  (let* ((outer? (om:outer-scope? model o))
         (scope (if (not model) o
                    (if outer? (cons null-symbol o)
                        (om:drop-scope (.name model) o)))))
    ((->symbol-join infix) scope)))

(define (om:name o)
  ((compose last om:scope+name) o))

(define (om:scope o)
  (drop-right (om:scope+name o) 1))

(define (om:drop-scope scope o)
  (drop-prefix (cdr scope) o))




;;; UTILITIES

(define ((collect predicate) o)
  (match o
    ((? (compose null-is-#f predicate)) (list o))
    (('compound statements ...)
     (filter identity (apply append (map (collect predicate) statements))))
    (($ <guard> e s) (filter identity ((collect predicate) s)))
    (($ <on> t s) (filter identity ((collect predicate) s)))
    (($ <if> e t f) (append (filter identity ((collect predicate) t))
                            (filter identity ((collect predicate) f))))
    ;;;; ((? (compose null-is-#f predicate)) (list o))
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

(define ((om:filter x) o)
  (match x
    (symbol? (filter (is? x) o))
    (procedure? (filter x o))))

(define* (om:find-triggers ast :optional (found '()))
  (match ast
    ((or ($ <interface>) ($ <component>))
     (or (and=> (.behaviour ast) om:find-triggers) '()))
    (($ <behaviour>) (or (and=> (.statement ast) om:find-triggers) '()))
    (('compound statements ...)
     (delete-duplicates (sort (append (apply append (map om:find-triggers statements))) om:<)))
    (($ <on>) (om:find-triggers (.triggers ast)))
    (('triggers triggers ...) triggers)
    (($ <guard>) (om:find-triggers (.statement ast) found))
    (_ '())))

(define (om:interface-types o)
  (match o
    (($ <interface>) (om:public-types o))
    (($ <port>) ((compose om:public-types om:import .type) o))
    ((? (is? <model>)) (append-map om:interface-types (om:ports o)))))

(define (om:public-types o)
  ;;(stderr "PUBLIC[~a]: ~a\n" (.name o) ((compose .elements .types) o))
  (match o
    ((? (is? <interface>)) ((compose .elements .types) o))
    (_ '())))

(define (om:reply-enums o)
  (match o
    (($ <interface>)
     (let* ((events (filter om:typed? (om:events o)))
            (names (delete-duplicates (map (compose .name .type .signature) events))))
       (map (lambda (n) (om:enum o n)) names)))
    (_ '())))

(define* (om:typed? o :optional (trigger #f))
  (if trigger
      (om:typed? (om:event o trigger))
      (match o
        (($ <event>)
         (let ((type ((compose .type .signature) o)))
           (and (not (eq? (.name type) 'void)) type)))
        ((? boolean?) #f))))


(define (om:declarative? o)
  (or (is-a? o <guard>)
      (is-a? o <on>)
      (and (is-a? o <compound>)
           (>0 (length (.elements o)))
           (om:declarative? (car (.elements o))))
      (and (pair? o)
           (om:declarative? (car o)))))

(define om:imperative? (negate om:declarative?))

;; JUNK ME
(define (om:models-with-behaviour o)
  (filter .behaviour (append (filter (is? <component>) o)
                             (filter (is? <interface>) o))))

(define (om:model-with-behaviour o)
  (and-let* ((models (null-is-#f (om:models-with-behaviour o))))
            (car models)))

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

(define ((om:dir-matches? port) event)
  (or (and (eq? (.direction port) 'provides)
           (eq? (.direction event) 'in))
      (and (eq? (.direction port) 'requires)
           (eq? (.direction event) 'out))))


(define (om:id o) ((compose pointer-address scm->pointer) o))

(define (om:parent o t)
  (match o
    ((? (is? <model>))
     (om:parent ((compose .statement .behaviour) o) t))
    (($ <guard>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                     (and (eq? (om:id (.expression o)) (om:id t)) o)
                     (om:parent (.statement o) t)))
    (($ <on>) (or (and (eq? (om:id (.statement o)) (om:id t)) o)
                  (om:parent (.statement o) t)))
    ((? (is? <ast-list>))
     (if (member (om:id t) (map om:id (.elements o)))
         o
         (let loop ((elements (.elements o)))
           (if (null? elements)
               #f
               (let ((parent (om:parent (car elements) t)))
                 (if parent parent
                     (loop (cdr elements))))))))
    (_ #f)))


;;;; reading/caching
(define *ast-alist* '())

(define (om:interfaces)
  (filter (is? <interface>) *ast-alist*))

(define (cache-model name o)
  (set! *ast-alist* (assoc-set! *ast-alist* name o))
  o)

(define (cached-model name)
  (assoc-ref *ast-alist* name))

(define (globals)
  (filter (is? <*type*>) (map cdr *ast-alist*)))

(define (om:register-model o)
  (if (not (cached-model (.name o)))
      (cache-model (.name o) o))
  o)

(define om:register-type om:register-model)

(define* ((om:register transform :optional (clear? #f)) ast)
  (let ((om (transform ast)))
    (if clear?
        (set! *ast-alist* (filter (lambda (x) (is-a? (cdr x) <*type*>)) *ast-alist*)))
    (for-each om:register-model (filter (is? <model>) om))
    (for-each om:register-type (filter (is? <*type*>) om))
    om))

(define* (import-ast name #:optional (transform ast->om))
  (and-let* ((name (if (pair? name) name (list 'name name)))
             (ast (null-is-#f (read-ast name (om:register transform))))
             (models (null-is-#f (filter (is? <model>) ast))))
            (find (lambda (model) (equal? (.name model) name)) models)))

(define* (om:import name #:optional (transform ast->om))
  (let ((name (if (pair? name) name (list 'name name))))
    (or (cached-model name)
        (and-let* ((ast (import-ast name transform)))
                  (cache-model name ast)))))


(define* (om:parse-dzn string :optional (register (om:register ast->om)))
  (parse-dzn string register))

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
                 (file (car (option-ref (parse-opts (command-line)) '() '(#f)))))
                (cond
                 ((string= file "-") #f)
                 ((string= file "/dev/stdin") #f)
                 ((string-suffix? ".scm" file) #f)
                 (else (not (in-file? o file)))))))


(define (ast-> ast)
  ((compose
    om->list
    ast->om
    ast->annotate
    ) ast))
