;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
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
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module (dzn ast ast)
  #:use-module (dzn ast accessor)
  #:use-module (dzn ast equal)
  #:use-module (dzn ast util)
  #:use-module (dzn tree accessor)
  #:use-module (dzn tree lookup)
  #:use-module (dzn tree tree)
  #:use-module (dzn tree util)
  #:use-module (dzn misc)

  #:export (.event
            .event.direction
            .formal
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
(define-method (ast:declaration* (o <root>))
  (filter (cute is-a? <> <declaration>) (ast:top* o)))

(define-method (ast:declaration* (o <ast>))
  (list o))

(define-method (ast:declaration* (o <namespace>))
  (let* ((full-name (ast:full-name o))
         (namespaces (ast:namespace** (or (as o <root>)
                                          (tree:ancestor o <root>))))
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
  (tree:collect o (is? <variable>)))

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
(define-method (ast:global? (o <string>))
  (string-prefix? "." o))

(define-method (ast:global? (o <named>))
  (ast:global? (.name o)))

(define-method (ast:global? (o <string>))
  #f)

(define-method (ast:has-equal-name a (b <named>))
  (ast:name-equal? a (.name b)))

(define-method (ast:has-equal-name a b) #f)

(define-method (ast:statement-prefix (o <ast>))
  (let ((compound (tree:ancestor o <compound>)))
    (if (not compound) '()
        (let* ((statements (ast:statement* compound))
               (path (tree:path o)))
          (take-while (negate (cute memq <> path)) statements)))))


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
      (_ o)))                           ;eq?-ness already stable.
  (lambda args
    (let* ((key (cons base-func (map object->key args)))
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
(define-method (ast:lookup (o <ast>) name)
  (cond
   ((ast:name-equal? name (.name ast:bool))
    ast:bool)
   ((ast:name-equal? name (.name ast:int))
    ast:int)
   ((ast:name-equal? name (.name ast:void))
    ast:void)
   (else
    (let ((scope (or (as o <scope>) (tree:ancestor o <scope>)))
          (root (or (as o <root>) (tree:ancestor o <root>))))
      (tree:lookup scope name)))))

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
      (and (is-a? (tree:parent o) <compound>)
           (ast:lookup-variable (tree:parent o) name (ast:statement-prefix o)))
      (ast:lookup-variable (tree:parent o) name statements)))
    ((? (is? <defer>))
     (ast:lookup-variable (tree:parent o) name (ast:statement-prefix o)))
    ((? (is? <if>))
     (or
      (and (is-a? (tree:parent o) <compound>)
           (ast:lookup-variable (tree:parent o) name (ast:statement-prefix o)))
      (ast:lookup-variable (tree:parent o) name statements)))
    (($ <function>)
     (or (find name? ((compose ast:formal* .signature) o))
         (ast:lookup-variable (tree:parent o) name statements)))
    (($ <formal>)
     (name? o))
    (($ <formal-binding>)
     (name? o))
    (($ <formal-reference>)
     (name? o))
    (($ <formal-reference-binding>)
     (name? o))
    ((or ($ <on>) ($ <canonical-on>))
     (or (find (cute ast:lookup-variable <> name statements)
               (append-map ast:formal* (ast:trigger* o)))
         (ast:lookup-variable (tree:parent o) name statements)))
    (($ <variable>)
     (name? o))
    ((? (lambda (o) (is-a? (tree:parent o) <variable>)))
     (ast:lookup-variable ((compose tree:parent tree:parent) o) name statements))
    (_
     (ast:lookup-variable (tree:parent o) name statements))))

(define-method (ast:lookup-variable (o <boolean>) name)
  #f)

(define (ast:lookup-variable-unmemoized root o name)
  (ast:lookup-variable o name (ast:statement-prefix o)))

(define ast:lookup-variable-memoized (ast:perfect-funcq ast:lookup-variable-unmemoized))
(define-method (ast:lookup-variable (o <ast>) name)
  (define (path->key o)
    (string-join (map (compose number->string tree:id) (tree:path o)) "."))
  (ast:lookup-variable-memoized (path->key o) o name))


;;;
;;; Resolvers.
;;;
(define-method (.port (o <trigger>))
  ;;<trigger> opens a new scope, so lookup the port name the parent scope
  (and (.port.name o) (ast:lookup (tree:parent o) (.port.name o))))

(define-method (.port (o <action>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <reply>)) ;; TODO REMOVEME
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <return>))
  (and (.port.name o) (ast:lookup o (.port.name o))))

(define-method (.port (o <end-point>))
  (if (.instance.name o)
      (let* ((instance (.instance o))
             (component (.type instance)))
        (ast:lookup component (.port.name o)))
      (ast:lookup o (.port.name o))))

(define-method (.port (o <shared-reference>))
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
                        (tree:ancestor o <interface>)))
         (event (ast:lookup interface (.event.name o))))
    (as event <event>)))

(define-method (.event (o <trigger>))
  (let* ((port-name (.port.name o))
         (port (.port o))
         (interface (if (is-a? port <port>) (.type port)
                        (tree:ancestor o <interface>))))
    (cond ((and (not port-name)
                (equal? (.event.name o) "inevitable"))
           (graft interface (make <inevitable>)))
          ((and (not port-name)
                (equal? (.event.name o) "optional"))
           (graft interface (make <optional>)))
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
  (and (.function.name o)
       (ast:lookup
        (and=> (tree:ancestor o <behavior>) .functions)
        (.function.name o))))

(define-method (.variable (o <assign>))
  (and=> (.variable.name o) (cute ast:lookup-variable o <>)))

(define-method (.variable (o <field-test>))
  (and=> (.variable.name o) (cute ast:lookup-variable o <>)))

(define-method (.variable (o <formal-binding>))
  (and=> (.variable.name o) (cute ast:lookup-variable (tree:parent o) <>)))

(define-method (.variable (o <formal-reference-binding>))
  (and=> (.variable.name o) (cute ast:lookup-variable (tree:parent o) <>)))

(define-method (.variable (o <argument>))
  (and=> (.name o) (cute ast:lookup-variable o <>)))

(define-method (.variable (o <reference>))
  (and=> (.name o) (cute ast:lookup-variable o <>)))

(define-method (lookup-shared-variable (port <port>) (name <string>))
  (let ((interface (.type port)))
    (and (as interface <interface>)
         (let ((behavior (.behavior interface)))
           (and (as behavior <behavior>)
                (ast:lookup-variable behavior name))))))

(define-method (.variable (o <shared-reference>))
  (let ((name (.name o)))
    (and name
         (let ((port (.port o)))
           (and (as port <port>)
                (or (let ((port+name (string-append (.name port) name)))
                      (ast:lookup-variable (tree:ancestor o <behavior>) port+name))
                    (lookup-shared-variable port name)))))))

(define-method (.variable (o <shared-field-test>))
  (let ((name (.variable.name o)))
    (and name
         (let ((port (.port o)))
           (and (as port <port>)
                (or (let ((port+name (string-append (.name port) name)))
                      (ast:lookup-variable (tree:ancestor o <behavior>) port+name))
                    (lookup-shared-variable port name)))))))

(define-method (.type (o <argument>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <enum-field>))
  (or (tree:ancestor o <enum>)
      (ast:lookup o (.type.name o))))

(define-method (.formal (o <formal-reference>))
  (let* ((trigger (tree:ancestor o <trigger>))
         (event (.event trigger))
         (trigger-formals (ast:formal* (tree:parent o)))
         (index (list-index (cute eq? o <>) (reverse trigger-formals)))
         (event-formals (if (not event) '() (ast:formal* event))))
    (and event
         (< index (length event-formals))
         (list-ref (reverse event-formals) index))))

;; (define-method (.formal (o <formal-reference-binding>))
;;   (let* ((on (tree:ancestor o <on>))
;;          (trigger (car (ast:trigger* on)))
;;          (event (.event trigger))
;;          (trigger-formals (ast:formal* (tree:parent o)))
;;          (index (list-index (cute eq? o <>) (reverse trigger-formals)))
;;          (formals (ast:formal* event)))
;;     (and event (< index (length formals)) (list-ref (reverse formals) index))))

(define-method (.type (o <formal>))
  (let* ((type-name (.type.name o))
         (scope (or (and=> (tree:ancestor o <on>) tree:parent)
                    (tree:ancestor o <statement>)
                    (tree:ancestor o <behavior>)
                    (and=> (tree:ancestor o <scope>) tree:parent))))
    (and=> type-name (cut ast:lookup scope <>))))

(define-method (.type (o <formal-reference>))
  (let ((formal (.formal o)))
    (and=> formal .type)))

(define-method (.direction (o <formal-reference>))
  (let ((formal (.formal o)))
    (and formal (.direction formal))))

;; (define-method (.direction (o <formal-reference-binding>))
;;   (let ((formal (.formal o)))
;;     (and formal (.direction formal))))

(define-method (.type (o <instance>))
  (let ((name (.type.name o)))
    (or (ast:lookup (tree:parent o) name)
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
  (let* ((parent (or (tree:ancestor o <shared-field-test>)
                     (tree:ancestor o <shared-variable>)))
         (type-name (.type.name o)))
    (cond (parent
           (let ((type-name (tree:name type-name)))
             (ast:lookup ((compose .behavior .type .port) parent) type-name)))
          (else
           (or (tree:ancestor o <enum>)
               (ast:lookup o type-name))))))
