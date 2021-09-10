;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (ice-9 poe)

  #:use-module (dzn parse tree)
  #:use-module (dzn parse util)

  #:export (.event
            .instance
            .port
            .type
            context:lookup
            context:look-down
            declaration->offset
            lookup
            lookup-definition
            lookup-location
            tree:lookup
            tree:->location))

;;;
;;; Lookup.
;;;

(define search-import
  (pure-funcq
   (lambda (scope name import)
     (let* ((file-name (.file-name import))
            (tree      (and file-name ((%file-name->parse-tree) file-name))))
       (and tree (search-or-widen-context scope name (tree->context tree)))))))

(define search
  (pure-funcq
   (lambda (scope name context)
     (let* ((target (if (null? scope) name (car scope)))
            (found (filter (compose (cute tree:name-equal? <> target) tree:name)
                           (tree:declaration* (.tree context)))))
       (and (pair? found)
            (let* ((found (if (null? scope) (and (pair? found) (cons (car found) context))
                              (let ((tail (cdr scope)))
                                (any (compose (cute search tail name <>)
                                              (cute tree->context <> context))
                                     found))))
                   (root (find (is? 'root) context))
                   (file-name (and=> root .file-name)))
              (and found
                   (map (cute tree:add-file-name <> file-name) found))))))))

(define widen-to-parent
  (pure-funcq
   (lambda (scope name context)
     (let ((parent-context (parent-context context tree:scope?)))
       (and parent-context
            (let* ((parent-tree (and=> parent-context .tree))
                   (scope-name (.name (.tree context)))
                   (scope+ (if scope-name (cons scope-name scope) scope)))
              (or (search-or-widen-context scope name parent-context)
                  (search-or-widen-context scope+ name parent-context))))))))

(define widen-to-imports
  (pure-funcq
   (lambda (scope name context)
     (and context (is-a? (.tree context) 'root)
          (let* ((root (.tree context))
                 (imports (tree:import* root)))
            (any (cute search-import scope name <>) imports))))))

(define (search-or-widen-context scope name context)
  (or (search scope name context)
      (widen-to-parent scope name context)
      (widen-to-imports scope name context)))

(define context:lookup
  (pure-funcq
   (lambda (name context)
     "Find NAME (a 'name or 'compound-name) depth first in CONTEXT (a tree:context? or
null) and return its CONTEXT."
     (cond
      ((not context)
       '())
      ((tree:name-equal? (.name name) (.name tree:bool))
       context:bool)
      ((tree:name-equal? (.name name) (.name tree:void))
       context:void)
      (else
       (let* ((context (if (.global name) (parent-context context 'root) context))
              (scope name (tree:scope+name name)))
         (search-or-widen-context scope name context)))))))

(define (tree:lookup name context)
  (let ((scope (if (tree:scope? (.tree context)) context
                   (parent-context context tree:scope?))))
    (and=> (tree:context? (context:lookup name context)) .tree)))

(define (tree:lookup-var name context)
  (define (helper name o)
    (define (name? o)
      (and (tree:name-equal? (.name o) name) o))
    (let ((tree (.tree o)))
      (match tree
        ((? (is? 'behaviour-statements))
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
         (or (find name? (append-map tree:formal* (tree:trigger* tree)))
             (helper name (.parent o))))
        ((? (is? 'variable))
         (or (name? tree)
             (tree:lookup-var name (parent-context context tree:statement?))))
        ((? (is? 'trigger-formal))
         (or (name? tree)
             (tree:lookup-var name (parent-context context tree:statement?))))
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

(define (.event context)
  (let* ((tree (.tree context)))
    (match tree
      ((or (? (is? 'action))
           (? (is? 'illegal-trigger))
           (? (is? 'interface-action))
           (? (is? 'trigger)))
       (let ((port (.port context))
             (event-name (.event-name tree)))
         (cond (port
                (and=> (.type port) (cute context:lookup event-name <>)))
               (else
                (search '() event-name (.parent context)))))))))

(define (.instance context)
  (let ((tree (.tree context)))
    (match tree
      ((? (is? 'end-point))
       (and=> (.instance-name tree) (cute context:lookup <> (.parent context)))))))

(define (.port context)
  (let ((tree (.tree context)))
    (match tree
      ((? (is? 'trigger))
       ;;<trigger> opens a new scope, so lookup the port name the parent scope
       (and=> (.port-name tree) (cute context:lookup <> (.parent context))))
      ((? (is? 'end-point))
       (let* ((instance (.instance context))
              (component (and=> instance .type)))
         (if component
             (and=> (.port-name tree) (cute context:lookup <> component))
             (and=> (.port-name tree) (cute context:lookup <> (.parent context)))))))))

(define (.type context)
  (let ((tree (.tree context)))
    (match tree
      ((? (is? 'event)) (and=> (.type-name tree) (cute context:lookup <> context)))
      ((? (is? 'formal)) (and=> (.type-name tree) (cute context:lookup <> context)))
      ((? (is? 'port)) (and=> (.type-name tree) (cute context:lookup <> context)))
      ((? (is? 'trigger)) (and=> (.event context) .type))
      ((? (is? 'instance)) (and=> (.type-name tree) (cute context:lookup <> context))))))

(define (resolve-action o name context)
  (resolve-trigger o name context))

(define (resolve-interface o name context)
  (assert-type o 'port)
  (or (and (tree:name-equal? name (slot o 'compound-name))
           (tree:lookup name context))
      (tree:lookup (slot o 'compound-name) context)))

(define (resolve-port o name context)
  (assert-type o 'illegal-trigger 'trigger 'action 'interface-action 'reply)
  (let ((port-name (.port-name o)))
    (cond ((and port-name (tree:name-equal? name port-name))
           (tree:lookup port-name context))
          (else #f))))

(define (resolve-trigger o name context)
  (assert-type o 'illegal-trigger 'trigger 'action 'interface-action)
  (let* ((port-name (.port-name o))
         (event-name (.event-name o)))
    (cond ((and port-name (tree:name-equal? name port-name))
           (tree:lookup port-name context))
          ((and port-name (tree:name-equal? name event-name))
           (let* ((port (tree:lookup port-name context))
                  (interface-name (and port (slot port 'compound-name)))
                  (interface (and interface-name (resolve-interface port interface-name context))))
             (and interface (tree:lookup event-name (list interface)))))
          ((and (not port-name) (tree:name-equal? name event-name))
           (tree:lookup event-name context))
          (else #f))))

(define (resolve-instance o name context)
  (assert-type o 'instance 'port)
  (and (tree:name-equal? name (slot o 'compound-name))
       (tree:lookup name context)))

(define (resolve-var o name context)
  (assert-type o 'assign 'var 'trigger-formal)
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

(define (resolve-import o)
  (assert-type o 'import)
  (let* ((file-name (.file-name o))
         (file-name ((%resolve-file) file-name)))
    `(root (location 0 0 ,file-name))))


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
  (or
   (and (or (is-a? name 'name)
            (is-a? name 'global))
        (cond
         ((parent context 'var)
          => (cute resolve-var <> name context))
         ((or (parent context 'action)
              (parent context 'interface-action))
          => (cute resolve-action <> name context))
         ((parent context 'port)
          => (cute resolve-interface <> name context))
         ((parent context 'trigger-formal)
          => (cute resolve-var <> name context))
         ((or (parent context 'illegal-trigger)
              (parent context 'trigger))
          => (cute resolve-trigger <> name context))
         ((parent context 'instance)
          => (cute resolve-instance <> name context))
         ((parent context 'enum-literal)
          => (cute resolve-enum-literal <> name context))
         ((parent context 'type-name)
          => (cute resolve-type <> name context))
         ((parent context 'field-test)
          => (cute resolve-field-test <> name context))
         ((parent context 'end-point)
          => (cute resolve-end-point <> name context))
         ((parent context 'call)
          => (cute resolve-call <> name context))
         ((parent context 'reply)
          => (cute resolve-port <> name context))
         (else
          #f)))
   (and (is-a? name 'import)
        (resolve-import name))))

(define* (lookup-definition name context #:key
                            file-name
                            (file-name->parse-tree (const '()))
                            (resolve-file (lambda args (car args))))
  "Return declaration of NAME in CONTEXT, using FILE-NAME->PARSE-TREE to
search in imports, as (FILE-NAME DECLARATION), or #f if not found."
  (and (or (is-a? name 'name)
           (is-a? name 'global)
           (is-a? name 'import))
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
                (target    (or (tree:name def) def)))
           (tree:->location target text #:file-name file-name)))))
