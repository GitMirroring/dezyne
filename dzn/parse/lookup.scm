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

(define-module (dzn parse lookup)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn parse tree)
  #:use-module (dzn parse util)

  #:export (declaration->offset
            lookup
            lookup->location
            lookup-definition
            lookup-location
            tree:lookup))

;;;
;;; Lookup.
;;;

(define (look-in-scope name scope)
  "Look for NAME (a 'name) in SCOPE, a tree:scope?."
  (assert-type name 'name)
  (assert-type scope tree:scope?)
  (filter (lambda (decl) (tree:name-equal? (tree:name decl) name))
          (tree:declaration* scope)))

(define (lookdown name search-scope)
  "Find named scope in SEARCH-SCOPE for NAME (a 'compound-name), until
NAME's scope prefix matches, then look-in-scope for NAME."
  (assert-type name 'compound-name 'name)
  (assert-type search-scope tree:scope?)
  (let* ((loc (.location name))
         (scope name (tree:scope+name name)))
    (if (null? scope) (or (tree:context? (look-in-scope name search-scope))
                          '())
        (let* ((first (car scope))
               (first-scopes (lookdown first search-scope)))
          (if (null? first-scopes) '()
              (let* ((scope (cdr scope))
                     (name (if (null? scope)`(compound-name ,name ,loc)
                               `(compound-name (scope ,@scope) ,name ,loc))))
                (append-map (cute lookdown name <>) first-scopes)))))))

(define (lookup-n name context)
  "Find NAME (a 'name or 'compound-name) in CONTEXT (a tree:context? or
null)."
  (if (not context) '()
      (let* ((loc (.location name))
             (scope name (tree:scope+name name)))
        (assert-type context tree:context?)
        (if (null? scope) (or (tree:context? (look-in-scope name (.tree context)))
                              (lookup-n name (parent-context context tree:scope?)))
            (let* ((first (car scope))
                   (first-scopes (lookup-n first context)))
              (if (null? first-scopes) '()
                  (let* ((scope (cdr scope))
                         (name (if (null? scope)`(compound-name ,name ,loc)
                                   `(compound-name (scope ,@scope) ,name ,loc))))
                    (append-map (cute lookdown name <>) first-scopes))))))))

(define (tree:lookup name context)
  (let ((scope (if (tree:scope? (.tree context)) context
                   (parent-context context tree:scope?))))
    (match (lookup-n name scope)
      ((first rest ...) first)
      (_ #f))))

(define (tree:lookup-var name o)
  (define (name? o)
    (and (tree:name-equal? (.name o) name) o))
  (let ((tree (.tree o)))
    (match tree
      ((? (is? 'behaviour-compound))
       (find name? (tree:variable* tree)))
      ((? (is? 'compound))
       (or (find name? (filter (is? 'variable) (tree:statement* tree)))
           (tree:lookup-var name (.parent o))))
      ((? (is? 'function))
       (or (find name? ((compose tree:formal* .signature) tree))
           (tree:lookup-var name (.parent o))))
      ((or (? (is? 'formal))
           (is? 'formal-binding))
       (and (equal? (.name tree) name)
            tree))
      ((? (is? 'on))
       (or (find (cute tree:lookup-var name <>)
                 (append-map tree:formal* (tree:trigger* tree)))
           (tree:lookup-var name (.parent o))))
      ((? (is? 'variable))
       (name? tree))
      ((? (cute parent <> 'variable))
       (tree:lookup-var name (.parent (parent o 'variable))))
      ((? tree?)
       (tree:lookup-var name (.parent o))))))


;;;
;;; Resolvers.
;;;

(define (resolve-action o name context)
  (resolve-trigger o name context))

(define (resolve-port o name context)
  (assert-type o 'port)
  (and (tree:name-equal? name (slot o 'compound-name))
       (tree:lookup name context)))

(define (resolve-trigger o name context)
  (assert-type o 'trigger 'action 'interface-action)
  (let* ((port-name (.port-name o))
         (event-name (.event-name o)))
    (cond ((and port-name (tree:name-equal? name port-name))
           (tree:lookup port-name context))
          ((and port-name (tree:name-equal? name event-name))
           (let* ((port (tree:lookup port-name context))
                  (interface-name (and port (slot port 'compound-name)))
                  (interface (and interface-name (resolve-port port interface-name context))))
             (and interface (tree:lookup event-name (list interface)))))
          ((and (not port-name) (tree:name-equal? name event-name))
           (tree:lookup event-name context))
          (else #f))))

(define (resolve-instance o name context)
  (assert-type o 'instance 'port)
  (and (tree:name-equal? name (slot o 'compound-name))
       (tree:lookup name context)))

(define (resolve-var o name context)
  (assert-type o 'assign 'var)
  (tree:lookup-var name context))

(define (resolve-enum-literal o name context)
  (assert-type o 'enum-literal)
  (let* ((type (.type-name o))
         (field  (.field o))
         (enum (tree:lookup type context)))
    (cond
     ((not enum) #f)
     ((equal? field name)
      (find (cute tree:name-equal? <> field) (tree:field* enum)))
     (else enum))))

(define (resolve-field-test o name context)
  (assert-type o 'field-test)
  (let* ((var (.var o))
         (name (.name var))
         (variable (tree:lookup name context))
         (type-name (.type-name variable))
         (enum (tree:lookup type-name context))
         (field (.field o)))
    (cond
     ((not enum) #f)
     ((equal? field name)
      (find (cute tree:name-equal? <> field) (tree:field* enum)))
     (else enum))))

(define (resolve-type o name context)
  (assert-type o 'type-name)
  (let ((name (.name o)))
    (tree:lookup name context)))

(define (resolve-end-point o name context)
  (assert-type o 'end-point)
  (let* ((instance-name (.instance-name o))
         (port-name (.port-name o)))
    (cond ((and instance-name (tree:name-equal? name instance-name))
           (tree:lookup instance-name context))
          ((and instance-name (tree:name-equal? name port-name))
           (let* ((instance (tree:lookup instance-name context))
                  (component-name (and instance (slot instance 'compound-name)))
                  (component (and component-name (resolve-instance instance component-name context))))
             (and component (tree:lookup port-name (list component)))))
          ((and (not instance-name) (tree:name-equal? name port-name))
           (tree:lookup port-name context))
          (else #f))))


;;;
;;; Utilities.
;;;

(define (declaration->offset declaration)
  "Return the offset of the name of DECLARATION."
  (let ((name (tree:name declaration)))
    (tree:offset name)))

(define* (lookup->location lookup text #:key file-name)
  "Create a <location> for LOOKUP result using TEXT, and return it."
  (match lookup
    (((? string? file-name) (? (is? 'name) name))
     (let ((offset (tree:offset name)))
       (file-offset->location file-name offset text)))
    (((? string? file-name) (? tree:declaration? declaration))
     (let ((offset (declaration->offset declaration)))
       (file-offset->location file-name offset text)))
    ((#f (? (is? 'name) name))
     (let ((offset (tree:offset name)))
       (file-offset->location file-name offset text)))
    ((#f (? tree:declaration? declaration))
     (let ((offset (declaration->offset declaration)))
       (file-offset->location file-name offset text)))))


;;;
;;; Entry points.
;;;

(define (context-lookup-definition name context)
  "Return declaration of NAME in CONTEXT, or #f if not found."
  (and (is-a? name 'name)
       (cond
        ((or (parent context 'action)
             (parent context 'interface-action))
         => (cute resolve-action <> name context))
        ((parent context 'port)
         => (cute resolve-port <> name context))
        ((parent context 'trigger)
         => (cute resolve-trigger <> name context))
        ((parent context 'instance)
         => (cute resolve-instance <> name context))
        ((parent context 'enum-literal)
         => (cute resolve-enum-literal <> name context))
        ((parent context 'type-name)
         => (cute resolve-type <> name context))
        ((parent context 'var)
         => (cute resolve-var <> name context))
        ((parent context 'field-test)
         => (cute resolve-field-test <> name context))
        ((parent context 'end-point)
         => (cute resolve-end-point <> name context))
        (else
         #f))))

(define* (lookup-definition name context #:key
                            file-name
                            (file-name->parse-tree (const '())))
  "Return declaration of NAME in CONTEXT, using FILE-NAME->PARSE-TREE to
search in imports, as (FILE-NAME DECLARATION), or #f if not found."
  (define (lookup-import name import)
    (let* ((file-name (.file-name import))
           (tree      (and file-name (file-name->parse-tree file-name)))
           (result    (and tree (tree:lookup name (list tree)))))
      (if (not result) '()
          `((,file-name ,result)))))
  (define (lookup-imported)
    (let* ((root    (parent context 'root))
           (imports (tree:import* root))
           (result  (append-map (cut lookup-import name <>) imports)))
      (match result
        ((first rest ...) first)
        (_ #f))))
  (and (is-a? name 'name)
       (let ((declaration (context-lookup-definition name context)))
      (if declaration `(,file-name ,declaration)
          (lookup-imported)))))

(define* (lookup-location name context #:key
                          file-name
                          (file-name->text (const ""))
                          (file-name->parse-tree (const '())))
  "Return location of NAME in CONTEXT, using FILE-NAME->PARSE-TREE to
search in imports, or #f if not found."
  (let ((def (lookup-definition name context
                                #:file-name file-name
                                #:file-name->parse-tree file-name->parse-tree)))
    (match def
      ((file declaration)
       (let* ((file-name (or file file-name))
              (text      (file-name->text file-name)))
         (lookup->location def text #:file-name file-name))))))
