;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022, 2023, 2025, 2026 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018, 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
;;; Copyright © 2019, 2020, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn ast lookup)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-2)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module (dzn ast accessor)
  #:use-module (dzn ast equal)
  #:use-module (dzn ast ast)
  #:use-module (dzn ast util)
  #:use-module (dzn misc)

  #:export (.event
            .event.direction
            .function
            .instance
            .type
            .variable

            ast:bool
            ast:int
            ast:void
            ast:lookup
            ast:lookup-variable
            ast:perfect-funcq
            ast:pure-funcq
            ast:unique-import*))

;;;
;;; TODO: Lazy import, lazy well-formedness check.
;;;

;;; Function returning AST for FILE-NAME.
(define %file-name->ast (make-parameter (const (make <root>))))


;;;
;;; Builtin types.
;;;
(define ast:bool (make <bool>))
(define ast:int (make <int>))
(define ast:void (make <void>))


;;;
;;; Accessors.
;;;
(define-method (ast:id* (o <string>))
  (list o))

(define-method (ast:id* (o <scope.name>))
  (.ids o))

(define-method (ast:id* (o <named>))
  (ast:id* (.name o)))

(define-method (ast:declaration* (o <root>))
  (filter (cute is-a? <> <declaration>) (ast:top* o)))

(define-method (ast:declaration* (o <ast>))
  (list o))

(define-method (ast:declaration* (o <namespace>))
  (let* ((full-name (ast:full-name o))
         (namespaces (ast:namespace** (or (as o <root>)
                                          (ast:parent o <root>))))
         (namespaces (filter (compose (cute equal? <> full-name) ast:full-name)
                             namespaces)))
    (filter (cute is-a? <> <declaration>)
            (append-map ast:top* namespaces))))

(define-method (ast:declaration* (o <interface>))
  (append (ast:type* o) (ast:event* o)))

(define-method (ast:declaration* (o <component-model>))
  (ast:port* o))

(define-method (ast:declaration* (o <system>))
  (append (ast:port* o) (ast:instance* o)))

(define-method (ast:declaration* (o <behavior>))
  (append (ast:type* o) (ast:function* o) (ast:variable* o)))

(define-method (ast:declaration* (o <defer>))
  (tree-collect (is? <variable>) o))

(define-method (ast:declaration* (o <compound>))
  (ast:variable* o))

(define-method (ast:declaration* (o <if>))
  (append (ast:variable* (.then o))
          (or (and=> (.else o) ast:variable*) '())))

(define-method (ast:declaration* (o <functions>))
  (ast:function* o))

(define-method (ast:declaration* (o <function>))
  (ast:formal* o))

(define-method (ast:declaration* (o <trigger>))
  (ast:formal* o))

(define-method (ast:declaration* (o <formals>))
  (ast:formal* o))

(define-method (ast:declaration* (o <enum>))
  (ast:field* o))

(define-method (ast:unique-import* (o <root>))
  (delete-duplicates (ast:import* o) ast:equal?))


;;;
;;; Predicates.
;;;
(define-method (ast:global? (o <scope.name>))
  (match (ast:scope o)
    (("/" scope ...)
     #t)
    (_ #f)))

(define-method (ast:global? (o <named>))
  (ast:global? (.name o)))

(define-method (ast:global? (o <string>))
  #f)

(define-method (ast:has-equal-name a (b <named>))
  (ast:name-equal? a (.name b)))

(define-method (ast:has-equal-name a b) #f)

(define-method (ast:statement-prefix (o <ast>))
  (let ((compound (ast:parent o <compound>)))
    (if (not compound) '()
        (let* ((statements (ast:statement* compound))
               (path (ast:path o)))
          (take-while (negate (cute member <> path ast:eq?)) statements)))))


;;;
;;; ast:pure-funcq
;;;
(define funcq-hash (@@ (ice-9 poe) funcq-hash))
(define funcq-assoc (@@ (ice-9 poe) funcq-assoc))
(define funcq-memo (@@ (ice-9 poe) funcq-memo))
(define funcq-buffer (@@ (ice-9 poe) funcq-buffer))
(define not-found (list 'not-found))

(define ((ast:funcq funcq-memo) base-func)
  (define (object->key o)
    "Return a stable, i.e., memoizable key for O."
    (match o
      ((? string?)                      ;name
       (string->symbol o))
      (((and (? string?) o) ..1)        ;scope
       (string->symbol (string-join o ".")))
      (($ <scope.name-node>)            ;name
       (object->key (string-join (.ids o) ".")))
      (_ o)))                           ;eq?-ness already stable.
  (lambda args
    (let* ((key (cons base-func (map (compose object->key ast:unwrap) args)))
           (cached (hashx-ref funcq-hash funcq-assoc funcq-memo key not-found)))
      (funcq-buffer key)
      (if (not (eq? cached not-found)) cached
          (let ((val (apply base-func args)))
            (hashx-set! funcq-hash funcq-assoc funcq-memo key val)
            val)))))

(define ast:perfect-funcq (ast:funcq (make-hash-table 1021)))
(define ast:pure-funcq (ast:funcq funcq-memo))


;;;
;;; Lookup.
;;;
(define (search-import-unmemoized root scope name import)
  (let* ((file-name (.name import))
         (ast       (and file-name ((%file-name->ast) file-name))))
    (and ast (search-or-widen-context scope name ast))))

(define (search-import scope name context)
  (let ((root (or (as context <root>) (ast:parent context <root>))))
    ((ast:perfect-funcq search-import-unmemoized) root scope name context)))

(define (search-unmemoized root scope name context)
  (if (and (null? scope) (string-contains name "."))
      (let ((names (string-split name #\.)))
        (search-unmemoized root (drop-right names 1) (last names) context))
      (let* ((global? (and (pair? scope) (equal? "/" (car scope))))
             (scope (if (not (and global? (is-a? context <root>))) scope
                        (filter (match-lambda ("/" #f) (o o)) scope)))
             (global? (and (pair? scope) (equal? "/" (car scope))))
             (target (if (null? scope) name (car scope)))
             (foo (ast:declaration* context))
             (found (filter (cute ast:name-equal? <> target)
                            (ast:declaration* context))))
        (and (pair? found)
             (match scope
               (()
                (car found))
               ((scope tail ...)
                (any (cute search tail name <>) found)))))))

(define (search scope name context)
  (let ((root (or (as context <root>) (ast:parent context <root>))))
    ((ast:perfect-funcq search-unmemoized) root scope name context)))

(define (widen-to-parent-unmemoized root
                                    scope name context)
  (let ((parent (ast:parent context <scope>)))
    (and parent
         (let* ((scope-name (and=> (as context <namespace>) .name))
                (scope+ (if scope-name (cons scope-name scope) scope)))
           (or (search-or-widen-context scope name parent)
               (search-or-widen-context scope+ name parent))))))

(define (widen-to-parent scope name context)
  (let ((root (or (as context <root>) (ast:parent context <root>))))
    ((ast:perfect-funcq widen-to-parent-unmemoized) root scope name context)))

(define (widen-to-imports-unmemoized root scope name context)
  (and context (is-a? context <root>)
       (let ((imports (ast:unique-import* context)))
         (any (cute search-import scope name <>) imports))))

(define (widen-to-imports scope name context)
  (let ((root (or (as context <root>) (ast:parent context <root>))))
    ((ast:perfect-funcq widen-to-imports-unmemoized) root scope name context)))

(define (search-or-widen-context scope name context)
  (or (search scope name context)
      (widen-to-parent scope name context)
      (widen-to-imports scope name context)))

(define (ast:lookup-unmemoized root context name)
  "Find NAME (a 'name or 'compound-name) depth first in CONTEXT (a context? or
null) and return its CONTEXT."
  (cond
   ((not context)
    #f)
   ((ast:name-equal? name (.name ast:bool))
    ast:bool)
   ((ast:name-equal? name (.name ast:int))
    ast:int)
   ((ast:name-equal? name (.name ast:void))
    ast:void)
   (else
    (let* ((global? (ast:global? name))
           (context (if global? (ast:parent context <root>) context))
           (name scope (ast:name+scope name)))
      (search-or-widen-context scope name context)))))

(define ast:lookup-memoized (ast:perfect-funcq ast:lookup-unmemoized))
(define-method (ast:lookup (context <ast>) name)
  (let* ((context (or (as context <scope>) (ast:parent context <scope>)))
         (root (or (as context <root>) (ast:parent context <root>))))
    (ast:lookup-memoized root context name)))
(define-method (ast:lookup name)
  (ast:lookup name name))

(define-method (ast:lookup-variable (o <ast>) name statements)
  (define (name? o)
    (cond ((is-a? o <shared-variable>)
           (and (equal? (string-append (.port.name o) (.name o)) name) o))
          (else
           (and (equal? (.name o) name) o))))
  (match o
    (($ <behavior>)
     (find name? (ast:variable* o)))
    ((? (is? <compound>))
     (or
      (find name? (filter (is? <variable>) statements))
      (and (is-a? (.parent o) <compound>)
           (ast:lookup-variable (.parent o) name (ast:statement-prefix o)))
      (ast:lookup-variable (.parent o) name statements)))
    ((? (is? <defer>))
     (ast:lookup-variable (.parent o) name (ast:statement-prefix o)))
    ((? (is? <if>))
     (or
      (and (is-a? (.parent o) <compound>)
           (ast:lookup-variable (.parent o) name (ast:statement-prefix o)))
      (ast:lookup-variable (.parent o) name statements)))
    ((? (is? <function>))
     (or (find name? ((compose ast:formal* .signature) o))
         (ast:lookup-variable (.parent o) name statements)))
    (($ <formal>)
     (name? o))
    (($ <formal-binding>)
     (name? o))
    ((or ($ <on>) ($ <canonical-on>))
     (or (find (cute ast:lookup-variable <> name statements)
               (append-map ast:formal* (ast:trigger* o)))
         (ast:lookup-variable (.parent o) name statements)))
    (($ <variable>)
     (name? o))
    ((? (lambda (o) (is-a? (.parent o) <variable>)))
     (ast:lookup-variable ((compose .parent .parent) o) name statements))
    (_
     (ast:lookup-variable (.parent o) name statements))))

(define-method (ast:lookup-variable (o <boolean>) name)
  #f)

(define (ast:lookup-variable-unmemoized root o name)
  (ast:lookup-variable o name (ast:statement-prefix o)))

(define ast:lookup-variable-memoized (ast:perfect-funcq ast:lookup-variable-unmemoized))
(define-method (ast:lookup-variable (o <ast>) name)
  (define (path->key o)
    (string-join (map (compose number->string .id) (ast:path o)) "."))
  (ast:lookup-variable-memoized (path->key o) o name))


;;;
;;; Resolvers.
;;;
(define-method (.port (o <trigger>))
  ;;<trigger> opens a new scope, so lookup the port name the parent scope
  (and (.port.name o) (ast:lookup (.parent o) (.port.name o))))

(define-method (.port (o <action>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <reply>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <end-point>))
  (if (.instance.name o)
      (let* ((instance (.instance o))
             (component (.type instance)))
        (ast:lookup component (.port.name o)))
      (ast:lookup o (.port.name o))))

(define-method (.port (o <shared-var>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <shared-variable>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <shared-field-test>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port.name (o <out-bindings>)) (and=> (.port o) .name))
(define-method (.port.name (o <blocking-compound>)) (and=> (.port o) .name))

(define-method (.instance (o <end-point>))
  (and (.instance.name o) (ast:lookup o (.instance.name o))))

(define-method (.event (o <action>))
  (let* ((port-name (.port.name o))
         (port (.port o))
         (interface (if port (.type port)
                        (ast:parent o <interface>)))
         (event (ast:lookup interface (.event.name o))))
    (as event <event>)))

(define-method (.event (o <trigger>))
  (let* ((port-name (.port.name o))
         (port (.port o))
         (interface (if (is-a? port <port>) (.type port)
                        (ast:parent o <interface>))))
    (cond ((and (not port-name)
                (equal? (.event.name o) "inevitable"))
           (clone (ast:inevitable) #:parent interface))
          ((and (not port-name)
                (equal? (.event.name o) "optional"))
           (clone (ast:optional) #:parent interface))
          (else (and
                 interface
                 (let ((event (ast:lookup interface (.event.name o))))
                   (as event <event>)))))))

(define-method (.event.direction (o <action>))
  ((compose .direction .event) o))

(define-method (.event.direction (o <trigger>))
  ((compose .direction .event) o))

(define-method (.function (model <model>) (o <call>))
  (and (.function.name o) (ast:lookup model (.function.name o))))

(define-method (.function (o <call>))
  (and (.function.name o) (ast:lookup o (.function.name o))))

(define-method (.variable (o <assign>))
  (and=> (.variable.name o) (cute ast:lookup-variable o <>)))

(define-method (.variable (o <field-test>))
  (and=> (.variable.name o) (cute ast:lookup-variable o <>)))

(define-method (.variable (o <formal-binding>))
  (and=> (.variable.name o) (cute ast:lookup-variable (.parent o) <>)))

(define-method (.variable (o <argument>))
  (and=> (.name o) (cute ast:lookup-variable o <>)))

(define-method (.variable (o <var>))
  (and=> (.name o) (cute ast:lookup-variable o <>)))

(define-method (lookup-shared-variable (port <port>) (name <string>))
  (let ((interface (.type port)))
    (and (as interface <interface>)
         (let ((behavior (.behavior interface)))
           (and (as behavior <behavior>)
                (ast:lookup-variable behavior name))))))

(define-method (.variable (o <shared-var>))
  (let ((name (.name o)))
    (and name
         (let ((port (.port o)))
           (and (as port <port>)
                (or (let ((port+name (string-append (.name port) name)))
                      (ast:lookup-variable (ast:parent o <behavior>) port+name))
                    (lookup-shared-variable port name)))))))

(define-method (.variable (o <shared-field-test>))
  (let ((name (.variable.name o)))
    (and name
         (let ((port (.port o)))
           (and (as port <port>)
                (or (let ((port+name (string-append (.name port) name)))
                      (ast:lookup-variable (ast:parent o <behavior>) port+name))
                    (lookup-shared-variable port name)))))))

(define-method (.type (o <function>))
  (.type (.signature o)))

(define-method (.type (o <argument>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <enum-field>))
  (or (ast:parent o <enum>)
      (ast:lookup o (.type.name o))))

(define-method (ast:event-formal (o <formal>))
  (let* ((trigger (ast:parent o <trigger>))
         (event (.event trigger))
         (index (list-index (cute ast:eq? o <>) (reverse (.elements (.parent o)))))
         (formals (if (not event) '() (ast:formal* event))))
    (and event (< index (length formals)) (list-ref (reverse formals) index))))

(define-method (ast:event-formal (o <formal-binding>))
  (let* ((on (ast:parent o <on>))
         (trigger (car (ast:trigger* on)))
         (event (.event trigger))
         (index (list-index (cute ast:eq? o <>) (reverse (.elements (.parent o)))))
         (formals (ast:formal* event)))
    (and event (< index (length formals)) (list-ref (reverse formals) index))))

(define-method (.type (o <formal>))
  (let* ((type-name (.type.name o))
         (scope (or (and=> (ast:parent o <on>) .parent)
                    (ast:parent o <statement>)
                    (ast:parent o <behavior>)
                    (and=> (ast:parent o <scope>) .parent))))
    (if type-name (ast:lookup scope type-name)
        (let ((formal (ast:event-formal o)))
          (and formal (.type formal))))))

(define-method (.direction (o <formal>))
  (let ((type-name (.type.name o)))
    (if type-name (.direction (.node o))
        (let ((formal (ast:event-formal o)))
          (and formal (.direction formal))))))

(define-method (.type (o <instance>))
  (let ((name (.type.name o)))
    (or (ast:lookup (.parent o) name)
        (ast:lookup o name))))

(define-method (.type (o <port>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <signature>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <variable>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <shared-variable>))
  (let ((type-name (.type.name o)))
    (ast:lookup ((compose .behavior .type .port) o) type-name)))

(define-method (.type (o <enum-literal>))
  (let ((type-name (.type.name o)))
    (or (and-let* ((parent (or (ast:parent o <shared-field-test>)
                               (ast:parent o <shared-variable>)))
                   (type-name (last (.ids type-name))))
          (ast:lookup ((compose .behavior .type .port) parent) type-name))
        (ast:parent o <enum>)
        (ast:lookup o type-name))))
