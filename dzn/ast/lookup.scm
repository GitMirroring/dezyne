;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

  #:use-module (ice-9 match)

  #:use-module (dzn ast accessor)
  #:use-module (dzn ast equal)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast util)
  #:use-module (dzn misc)

  #:export (.event
            .event.direction
            .function
            .instance
            .type
            .variable

            ast:lookup
            ast:pure-funcq))

;;;
;;; Accessors.
;;;
(define-method (ast:declaration* (o <root>))
  (filter (cut is-a? <> <declaration>) (ast:top* o)))

(define-method (ast:declaration* (o <namespace>))
  (let* ((full-name (ast:full-name o))
         (namespaces (ast:namespace-recursive* (or (as o <root>)
                                                   (ast:parent o <root>))))
         (namespaces (filter (compose (cute equal? <> full-name) ast:full-name)
                             namespaces)))
    (filter (cut is-a? <> <declaration>)
            (append-map ast:top* namespaces))))

(define-method (ast:declaration* (o <interface>))
  (append (ast:type* o) (ast:event* o)))

(define-method (ast:declaration* (o <component-model>))
  (ast:port* o))

(define-method (ast:declaration* (o <system>))
  (append (ast:port* o) (ast:instance* o)))

(define-method (ast:declaration* (o <behavior>))
  (append (ast:type* o) (ast:function* o) (ast:variable* o) (ast:port* o)))

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


;;;
;;; Predicates.
;;;
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

(define (ast:pure-funcq base-func)
  (define (name->symbol o)
    (match o
      ((? string?) (string->symbol o))
      (($ <scope.name-node>) (name->symbol (string-join (.ids o) ".")))
      (_ o)))
  (lambda args
    (let* ((key (cons base-func (map (compose name->symbol ast:unwrap) args)))
           (cached (hashx-ref funcq-hash funcq-assoc funcq-memo key not-found)))
      (if (not (eq? cached not-found))
	  (begin
	    (funcq-buffer key)
	    cached)

	  (let ((val (apply base-func args)))
	    (funcq-buffer key)
	    (hashx-set! funcq-hash funcq-assoc funcq-memo key val)
	    val)))))


;;;
;;; Lookup.
;;;
(define-method (ast:lookup-n (o <scope>) (name <scope.name>))
  (let ((ids (.ids name)))
    (if (null? (cdr ids))
        (let ((down (ast:lookdown o name)))
          (if (pair? down) down
              (if (ast:has-equal-name (car ids) o) (list o)
                  (ast:lookup-n o (car ids)))))
        (let* ((first (car ids))
               (first-scopes (ast:lookup-n o first)))
          (if (null? first-scopes) '()
              (let ((name (clone name #:ids (cdr ids))))
                (ast:lookdown first-scopes name)))))))

(define-method (ast:lookdown (o <list>) (name <scope.name>))
  (append-map (cut ast:lookdown <> name) o))

(define-method (ast:lookdown (o <scope>) (name <string>))
  (filter (lambda (decl)
            (let ((decl (cond ((string? decl) decl)
                              ((is-a? decl <named>) (.name decl)))))
              (ast:name-equal? decl name)))
          (ast:declaration* o)))

(define-method (ast:lookdown (o <scope>) (name <scope.name>))
  (let ((ids (.ids name)))
    (if (null? (cdr ids)) (ast:lookdown o (car ids))
        (let* ((first (car ids))
               (first-scopes (ast:lookdown o first)))
          (if (null? first-scopes) '()
              (let ((name (clone name #:ids (cdr ids))))
                (ast:lookdown first-scopes name)))))))

(define-method (ast:lookdown (o <ast>) (name <scope.name>))
  '())

(define-method (ast:lookup-n (o <ast>) name)
  (ast:lookup-n (or (as o <scope>) (ast:parent o <scope>)) name))

(define-method (ast:lookup-n (o <formals>) name)
  (filter (cut ast:name-equal? <> name) (ast:formal* o)))

(define-method (ast:lookup-n (o <scope>) (name <string>))
  (cond ((equal? name "void")
         (list (find (conjoin (is? <declaration>)
                              (lambda (decl) (ast:name-equal? (.name decl) name)))
                     (ast:declaration* (or (as o <root>)
                                           (ast:parent o <root>))))))
        ((ast:empty-namespace? name) (list (or (as o <root>)
                                           (ast:parent o <root>))))
        (else (let ((found (filter (conjoin (is? <declaration>)
                                            (lambda (decl) (ast:name-equal? (.name decl) name)))
                                   (ast:declaration* o)))
                    (p (.parent o)))
                (cond
                 ((pair? found) found)
                 ((or (not name) (not p)) '())
                 (else (ast:lookup-list (or (as p <scope>)
                                            (ast:parent p <scope>))
                                        name)))))))

(define-method (ast:lookup-n (o <boolean>) name)
  '())

(define (ast:lookup-list- root o name)
  (ast:lookup-n o name))

(define (ast:lookup-list o name)
  ((ast:pure-funcq ast:lookup-list-)
   (or (as o <root>) (ast:parent o <root>)) o name))

(define (ast:lookup o name)
  (let ((lookup (ast:lookup-list o name)))
    (if (null? lookup) #f (car lookup))))

(define-method (ast:lookup-variable (o <ast>) name statements)
  (define (name? o) (and (equal? (.name o) name) o))
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
    (($ <function>)
     (or (find name? ((compose ast:formal* .signature) o))
         (ast:lookup-variable (.parent o) name statements)))
    (($ <formal>)
     (name? o))
    (($ <formal-binding>)
     (name? o))
    (($ <on>)
     (or (find (cute ast:lookup-variable <> name statements)
               (append-map ast:formal* (ast:trigger* o)))
         (ast:lookup-variable (.parent o) name statements)))
    (($ <variable>)
     (name? o))
    ((? (lambda (o) (is-a? (.parent o) <variable>)))
     (ast:lookup-variable ((compose .parent .parent) o) name statements))
    (_
     (ast:lookup-variable (.parent o) name statements))))

(define (ast:lookup-variable- root o name)
  (ast:lookup-variable o name (ast:statement-prefix o)))

(define-method (ast:lookup-variable (o <ast>) name)
  ((ast:pure-funcq ast:lookup-variable-) (ast:parent o <root>) o name))

(define-method (ast:lookup-variable (o <boolean>) name)
  #f)


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

(define-method (.port.name (o <out-bindings>)) (and=> (.port o) .name))
(define-method (.port.name (o <blocking-compound>)) (and=> (.port o) .name))

(define-method (.instance (o <end-point>))
  (and (.instance.name o) (ast:lookup o (.instance.name o))))

(define-method (.event (o <action>))
  (let* ((port-name (.port.name o))
         (port (.port o))
         (interface (if port (.type port)
                        (ast:parent o <interface>))))
    (ast:lookup interface (.event.name o))))

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
          (else (and interface
                     (let ((event (ast:lookdown interface (.event.name o))))
                       (and (pair? event) (car event))))))))

(define-method (.event.direction (o <action>))
  ((compose .direction .event) o))

(define-method (.event.direction (o <trigger>))
  ((compose .direction .event) o))

(define-method (.function (model <model>) (o <call>))
  (and (.function.name o) (ast:lookup model (.function.name o))))

(define-method (.function (o <call>))
  (and (.function.name o) (ast:lookup o (.function.name o))))

(define-method (.variable (o <assign>))
  (and=> (.variable.name o) (cut ast:lookup-variable o <>)))

(define-method (.variable (o <field-test>))
  (and=> (.variable.name o) (cut ast:lookup-variable o <>)))

(define-method (.variable (o <formal-binding>))
  (and=> (.variable.name o) (cut ast:lookup-variable (.parent o) <>)))

(define-method (.variable (o <var>))
  (and=> (.name o) (cut ast:lookup-variable o <>)))

(define-method (.type (o <argument>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <enum-field>))
  (or (ast:parent o <enum>)
      (ast:lookup o (.type.name o))))

(define-method (.type (o <enum-literal>))
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
         (index (list-index (cute ast:eq? o <>) (reverse (.elements (.parent o))))))
    (and event (list-ref (reverse (ast:formal* event)) index))))

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
  (let* ((name (.type.name o))
         (found (ast:lookdown (.parent o) name)))
    (if (pair? found) (car found)
        (ast:lookup o name))))

(define-method (.type (o <port>))
  (let ((component (ast:parent o <component-model>)))
    (and component
         (ast:lookup (.parent component) (.type.name o)))))

(define-method (.type (o <signature>))
  (ast:lookup o (.type.name o)))

(define-method (.type (o <variable>))
  (ast:lookup o (.type.name o)))
