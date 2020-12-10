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
            lookup-definition
            lookup-location
            tree:lookup
            tree:->location))

;;;
;;; Lookup.
;;;

(define (lookup-import name import)
  (let* ((file-name (.file-name import))
         (tree      (and file-name ((%file-name->parse-tree) file-name))))
    (and tree (append-map (lambda (t) (lookdown name tree (list tree))) tree))))

(define (lookup-imported name root)
  (let ((imports (tree:import* root)))
    (append-map (cut lookup-import name <>) imports)))

(define (look-in-scope name scope context)
  "Look for NAME (a 'name) in SCOPE, a tree:scope?.  Return a location
with file-name from CONTEXT in offsets."
  (assert-type name 'name)
  (assert-type scope tree:scope?)
  (let* ((root (find (is? 'root) context))
         (file-name (and=> root .file-name))
         (found (filter (compose (cute tree:name-equal? <> name) tree:name)
                        (tree:declaration* scope)))
         (found (map (cute tree:add-file-name <> file-name) found)))
    (if (is-a? scope 'root)
        (append found (lookup-imported name scope))
        found)))

(define (lookdown name search-scope context)
  "Find named scope in SEARCH-SCOPE for NAME (a 'compound-name), until
NAME's scope prefix matches, then look-in-scope for NAME."
  (assert-type name 'compound-name 'name)
  (assert-type search-scope tree:scope?)
  (let* ((loc (.location name))
         (scope name (tree:scope+name name)))
    (if (null? scope) (or (tree:context? (look-in-scope name search-scope context))
                          '())
        (let* ((first (car scope))
               (first-scopes (lookdown first search-scope context)))
          (if (null? first-scopes) '()
              (let* ((scope (cdr scope))
                     (name (if (null? scope)`(compound-name ,name ,loc)
                               `(compound-name (scope ,@scope) ,name ,loc))))
                (append-map (cute lookdown name <> context) first-scopes)))))))

(define (lookup-n name context)
  "Find NAME (a 'name or 'compound-name) in CONTEXT (a tree:context? or
null)."
  (if (not context) '()
      (let* ((loc (.location name))
             (scope name (tree:scope+name name)))
        (assert-type context tree:context?)
        (if (null? scope) (or (tree:context? (look-in-scope name (.tree context) context))
                              (let* ((tree (.tree context))
                                     (name (if (is-a? tree 'namespace)
                                               `(compound-name (scope ,(.name (.name tree))) ,name ,loc)
                                               name)))
                                (lookup-n name (parent-context context tree:scope?))))
            (let* ((first (car scope))
                   (first-scopes (lookup-n first context)))
              (if (null? first-scopes) '()
                  (let* ((scope (cdr scope))
                         (name (if (null? scope) `(compound-name ,name ,loc)
                                   `(compound-name (scope ,@scope) ,name ,loc))))
                    (append-map (cute lookdown name <> context) first-scopes))))))))

(define (tree:lookup name context)
  (let ((scope (if (tree:scope? (.tree context)) context
                   (parent-context context tree:scope?))))
    (match (lookup-n name scope)
      ((first rest ...) first)
      (_ #f))))

(define (tree:lookup-var name context)
  (define (helper name o)
    (define (name? o)
      (and (tree:name-equal? (.name o) name) o))
    (let ((tree (.tree o)))
      (match tree
        ((? (is? 'behaviour-compound))
         (find name? (tree:variable* tree)))
        ((? (is? 'compound))
         (or (find name? (filter (is? 'variable) (tree:statement* tree)))
             (helper name (.parent o))))
        ((? (is? 'function))
         (or (find name? (tree:formal* tree))
             (helper name (.parent o))))
        ((or (? (is? 'formal))
             (is? 'formal-binding))
         (and (equal? (.name tree) name)
              tree))
        ((? (is? 'on))
         (or (find (cute helper name <>)
                   (append-map tree:formal* (tree:trigger* tree)))
             (helper name (.parent o))))
        ((? (is? 'variable))
         (name? tree))
        ((? (cute parent <> 'variable))
         (helper name (.parent (parent o 'variable))))
        ((? tree?)
         (helper name (.parent o))))))
  (let* ((root (find (is? 'root) context))
         (file-name (and=> root .file-name)))
    (and=> (helper name context) (cute tree:add-file-name <> file-name))))


;;;
;;; Resolvers.
;;;

(define (resolve-action o name context)
  (resolve-trigger o name context))

(define (resolve-port o name context)
  (assert-type o 'port)
  (or (and (tree:name-equal? name (slot o 'compound-name))
           (tree:lookup name context))
      (tree:lookup (slot o 'compound-name) context)))

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
         (var-name (.name var))
         (variable (tree:lookup var-name context))
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

(define (resolve-call o name context)
  (assert-type o 'call)
  (let ((function-name (.function-name o)))
    (cond ((and function-name (tree:name-equal? name function-name))
           (tree:lookup function-name context))
          (else #f))))


;;;
;;; Utilities.
;;;

(define (declaration->offset declaration)
  "Return the offset of the name of DECLARATION."
  (let ((name (tree:name declaration)))
    (tree:offset name)))

(define* (tree:->location o text #:key file-name)
  "Create a <location> for tree O using TEXT, and return it."
  (let ((file-name (or file-name (tree:file-name o)))
        (offset    (or (tree:offset o) 0)))
    (file-offset->location file-name offset text)))


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
        ((parent context 'call)
         => (cute resolve-call <> name context))
        (else
         #f))))

(define* (lookup-definition name context #:key
                            file-name
                            (file-name->parse-tree (const '()))
                            (resolve-file (lambda args (car args))))
  "Return declaration of NAME in CONTEXT, using FILE-NAME->PARSE-TREE to
search in imports, as (FILE-NAME DECLARATION), or #f if not found."
  (and (is-a? name 'name)
       (parameterize ((%file-name->parse-tree file-name->parse-tree)
                      (%resolve-file resolve-file))
         (context-lookup-definition name context))))

(define* (lookup-location name context #:key
                          file-name
                          (file-name->text (const ""))
                          (file-name->parse-tree (const '()))
                          (resolve-file (lambda args (car args))))
  "Return location of NAME in CONTEXT, using FILE-NAME->PARSE-TREE to
search in imports, or #f if not found."
  (let ((def (lookup-definition name context
                                #:file-name file-name
                                #:file-name->parse-tree file-name->parse-tree
                                #:resolve-file resolve-file)))
    (and def
         (let* ((file-name (or (tree:file-name def) file-name))
                (text      (file-name->text file-name))
                (name      (tree:name def)))
           (tree:->location name text #:file-name file-name)))))
