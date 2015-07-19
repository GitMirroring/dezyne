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

(define-module (gaiag goops util)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 match)
  :use-module (system foreign)
  :use-module (srfi srfi-1)
  :use-module (language dezyne location)

  :use-module (gaiag gaiag)
  :use-module (gaiag misc)
  :use-module (gaiag reader)

  :use-module (gaiag goops ast)
  :use-module (gaiag goops compare)
  :use-module (gaiag goops om)
  :use-module (gaiag goops display)
  :use-module (gaiag goops map)

  :export (
           is?
           om->list
           om2list
           om:booleans
           om:children
           om:component
           om:components
           om:declarative?
           om:imperative?
           om:dir-matches?
           om:enum
           om:enums
           om:event
           om:events
           om:extern
           om:externs
           om:filter
           om:find-triggers
           om:function
           om:function-names
           om:functions
           om:guard-equal?
           om:import
           om:imports
           om:imported?
           om:instance
           om:in?
           om:integer
           om:integers
           om:interface
           om:interface-enums
           om:interface-externs
           om:interface-integers
           om:interface-types
           om:interfaces
           om:model-with-behaviour
           om:models-with-behaviour
           om:modeling?
           om:models
           om:named
           om:out?
           om:out-or-inout?
           om:parent
           om:parse-dezyne
           om:port
           om:ports
           om:provides?
           om:requires?
           om:register
           om:register-model
           om:register-type
           om:reply-enums
           om:statement
           om:statements-of-type
           om:system
           om:systems
           om:triggers-equal?
           om:type
           om:types
           om:typed?
           om:variable
           om:variables
           om:void?
           make-interface-enum
           ))

(define ((is? class) o)
  (and (is-a? o class) o))

(define (om->list om)
  (with-input-from-string
      (with-output-to-string (lambda () (write om)))
    read))

(define* (om2list o :optional (marker null-symbol))
  (match o
    ((and (? (is? <ast>)) (? (negate (is? <ast-list>)))) (cons (symbol-append (ast-name o) marker) (map om2list (om:children o))))
    ((h t ...) (map om2list o))
    (_ o)))

(define-method (om:filter (predicate <top>) (o <ast-list>))
  (filter predicate (.elements o)))

(define-method (om:filter (predicate <top>) (o <list>))
  (filter predicate o))

(define-method (om:filter (predicate <procedure>))
  (lambda (o) (om:filter predicate o)))

(define-method (om:filter (predicate <top>))
  (lambda (o) (om:filter predicate o)))

(define-method (om:filter (class <class>))
  (lambda (o) (om:filter (is? class) o)))

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

(define (om:functions ast)
  (match ast
;;    (($ <behaviour>) (.elements (.functions ast)))
    ((? (is? <model>)) (or (and=> (.behaviour ast) (compose .elements .functions)) '()))
    ;; (($ <port>) (stderr "port: ~a\n" (.type ast))
    ;;  (om:functions (om:import (.type ast) ast->om)))
    ;; (#f '())
    ;; (_ (throw 'match-error  (format #f "~a:om:functions: no match: ~a\n" (current-source-location) ast)))))
    ))

(define-method (om:ports (o <interface>)) '())
(define-method (om:ports (o <model>)) ((compose .elements .ports) o))

(define (om:reply-enums o)
  (match o
    (($ <interface>)
     (let* ((events (filter om:typed? ((compose .elements .events) o)))
            (names (delete-duplicates (map (compose .name .type .signature) events))))
       (map (lambda (n) (om:enum o n)) names)))
    (_ '())))

(define (om:variables ast)
  (match ast
    (($ <behaviour>) (.elements (or (.variables ast) (make <variables>))))
    (($ <interface>) (om:variables (.behaviour ast)))
    (($ <component>) (om:variables (.behaviour ast)))
    (($ <port>) (om:variables (om:import (.type ast) ast->om)))
    (#f '())
    (_ (throw 'match-error  (format #f "~a:om:variables: no match: ~a\n" (current-source-location) ast)))))

(define (om:statement ast)
  (match ast
    (($ <model>) (or (and=> (.behaviour ast) om:statement) (make <compound>)))
    (($ <behaviour>) (or (.statement ast) (make <compound>)))
    (($ <function>) (.statement ast))
    (_ (throw 'match-error  (format #f "~a:om:statement: no match: ~a\n" (current-source-location) ast)))))

(define ((om:statement-of-type type) statement)
  (and statement
   (eq? (ast-name statement) type)))

(define ((om:statements-of-type type) statement)
  (match statement
    ((? (om:statement-of-type type)) (list statement))
    (($ <compound>) (filter identity (apply append (map (om:statements-of-type type) (.elements statement)))))
    (($ <on> triggers statement) (filter identity ((om:statements-of-type type) statement)))
    ((? (is? <statement>)) '())
    (#f '())
    (_ (throw 'match-error  (format #f "~a:om:statements-of-type, type: ~a: no match: ~a\n" (current-source-location) type statement)))))

(define-method (om:typed? (o <event>))
  (let ((type ((compose .type .signature) o)))
    (and (not (eq? (.name type) 'void)) type)))

(define-method (om:typed? (o <boolean>)) #f)

(define-method (om:typed? (m <model>) (o <trigger>))
  (om:typed? (om:event m o)))

(define-method (om:dir-matches? (p <port>) (e <event>))
  (or (and (eq? (.direction p) 'provides)
           (eq? (.direction e) 'in))
      (and (eq? (.direction p) 'requires)
           (eq? (.direction e) 'out))))

(define-method (om:dir-matches? (o <port>))
  (lambda (event) (om:dir-matches? o event)))

;; (define-method (om:component (o <top>)) #f)
;; (define-method (om:component (o <component>)) o)
;; (define-method (om:component (o <list>)) (find (is? <component>) o))
;; (define-method (om:component (o <ast-list>))
;;   (find (is? <component>) (.elements o)))

(define-method (om:interface (o <top>)) #f)
(define-method (om:interface (o <interface>)) o)
(define-method (om:interface (o <list>)) (find (is? <interface>) o))
(define-method (om:interface (o <ast-list>))
  (find (is? <interface>) (.elements o)))

(define-method (om:interface (o <port>))
  (om:import (.type o)))

(define-method (om:interface (o <model>))
  (om:interface (om:port o)))

(define-method (om:system (o <top>)) #f)
(define-method (om:system (o <system>)) o)
(define-method (om:system (o <list>)) (find (is? <system>) o))
(define-method (om:system (o <ast-list>))
  (find (is? <system>) (.elements o)))

(define-method (om:port (o <interface>) name)
  #f)

(define-method (om:port (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (om:ports o)))

(define-method (om:port (o <interface>))
  #f)

(define-method (om:port (o <model>))
  (and=> (null-is-#f (filter om:provides? ((compose .elements .ports) o))) car))

(define-method (om:port (o <system>) (bind <binding>))
  (let* ((port (.port bind)))
    (or
     (and-let* ((name (.instance bind))
                (instance (om:instance o name))
                (type (and=> instance .component))
                (component (om:import type)))
               (om:port component port))
     (om:port o port))))

(define-method (om:instance (o <system>) (name <boolean>))
  #f)

(define-method (om:instance (o <system>) (name <symbol>))
 (find (lambda (x) (eq? (.name x) name)) ((compose .elements .instances) o)))

(define-method (om:instance (o <system>) (bind <binding>))
  (or (om:instance o (.instance bind))
      (om:import (.type (om:port o (.port bind))))))

(define-method (om:in? (o <event>))
  (eq? (.direction o) 'in))

(define-method (om:out? (o <event>))
  (eq? (.direction o) 'out))

(define-method (om:in? (o <trigger>)) #t)

(define-method (om:out? (o <trigger>)) #f)

(define-method (om:out-or-inout? (o <formal>))
  (or (eq? (.direction o) 'out)
      (eq? (.direction o) 'inout)))

(define-method (om:provides? (o <port>))
  (eq? (.direction o) 'provides))

(define-method (om:requires? (o <port>))
  (eq? (.direction o) 'requires))

(define (om:booleans o)
  '())

(define ((make-interface-enum port) o)
  (make <enum> :name (.name o) :scope port :fields (.fields o)))

(define-method (om:interface-enums (o <interface>))
  ((om:filter <enum>) (.types o)))

(define-method (om:interface-enums (port <port>))
  (map (make-interface-enum (.type port)) (om:enums port)))

(define-method (om:interface-enums (o <component>))
  (apply append (map om:interface-enums ((compose .elements .ports) o))))

(define-method (om:interface-enums (o <system>))
  (apply append (map om:interface-enums ((compose .elements .ports) o))))

(define-method (om:enums o)
  ((om:filter <enum>) (om:types o)))

(define-method (om:enum (o <model>) name)
  ((is? <enum>) (om:type o name)))

(define-method (om:enum (o <model>) (type <type>))
  ((is? <enum>) (om:type o type)))

(define ((make-interface-extern port) o)
  (make <extern> :name (.name o) :scope port :value (.value o)))

(define-method (om:interface-externs (o <interface>))
  ((om:filter <extern>) (.types o)))

(define-method (om:interface-externs (port <port>))
  (map (make-interface-extern (.type port)) (om:externs port)))

(define-method (om:interface-externs (o <component>))
  (apply append (map om:interface-externs ((compose .elements .ports) o))))

(define-method (om:interface-externs (o <system>))
  (apply append (map om:interface-externs ((compose .elements .ports) o))))

(define-method (om:externs o)
  ((om:filter <extern>) (om:types o)))

(define-method (om:extern (o <model>) name)
  ((is? <extern>) (om:type o name)))

(define-method (om:extern (o <model>))
  (lambda (name) (om:extern o name)))

(define-method (om:extern (model <model>) (formal <formal>))
  (om:extern model (.type formal)))

;; extern, *global*, TODO
;; (define-method (om:extern (o <model>) (type <type>))
;;   ((is? <extern>) (om:type o type)))

(define-method (om:extern (o <model>) (type <type>))
  (find (lambda (o) (and (eq? (.name o) (.name type))
                         ;;(or (eq? (.scope o) (.scope type)) (and (eq? (.scope o) '*global*) (not (.scope type))))
                         ;;(eq? (.scope o) (.scope type)) NEW gone
                         ))
        (append (om:externs o) (om:externs))))

(define-method (om:extern (o <component>) (type <type>))
  (or (next-method)
      (find (lambda (o) (and (eq? (.name o) (.name type))
                             ;;(eq? (.scope o) (.scope type))
                             )) ;; NEW
            (om:interface-externs o))))

(define ((make-interface-integer port) o)
  (make <int> :name (.name o) :scope port :range (.range o)))

(define-method (om:interface-integers (o <interface>))
  ((om:filter <int>) (.types o)))

(define-method (om:interface-integers (port <port>))
  (map (make-interface-integer (.type port)) (om:integers port)))

(define-method (om:interface-integers (o <component>))
  (apply append (map om:interface-integers ((compose .elements .ports) o))))

(define-method (om:integers o)
  ((om:filter <int>) (om:types o)))

(define-method (om:integer (o <model>) name)
  ((is? <int>) (om:type o name)))

(define-method (om:integer (o <model>) (type <type>))
  ((is? <int>) (om:type o type)))

(define-method (om:variable (o <model>))
  (lambda (name) (om:variable o name)))

(define-method (om:variable (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (om:variables o)))

(define-method (om:function (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (om:functions o)))

(define-method (om:model (o <component>)) o)
(define-method (om:model (o <interface>)) o)
(define (om:models o) ((om:filter <model>) o))
(define (om:imports o) ((om:filter <import>) o))
(define (om:interfaces o) ((om:filter <interface>) o))
(define (om:components o) ((om:filter <component>) o))
(define (om:systems o) ((om:filter <system>) o))

(define-method (om:enums) ((om:filter <enum>) (map cdr *ast-alist*)))
(define-method (om:externs) ((om:filter <extern>) (map cdr *ast-alist*)))
(define-method (om:integers) ((om:filter <int>) (map cdr *ast-alist*)))
(define-method (om:types) ((om:filter <type>) (map cdr *ast-alist*)))
(define-method (om:types (o <list>)) ((om:filter <type>) o))
(define-method (om:types (o <root>)) (om:types (.elements o)))

;; WIP: refactor om:enums, om:integers, om:externs into om:types
(define-method (make-interface-type port)
  (lambda (o) (make-interface-type port o)))

(define-method (make-interface-type port (o <enum>))
  ((make-interface-enum port) o))

(define-method (make-interface-type port (o <extern>))
  ((make-interface-extern port) o))

(define-method (make-interface-type port (o <int>))
  ((make-interface-integer port) o))

(define-method (om:interface-types (o <interface>))
  ((compose .elements .types) o))

(define-method (om:interface-types (port <port>))
  (map (make-interface-type (.type port)) (om:types port)))

(define-method (om:interface-types (o <component>))
  (apply append (map om:interface-types ((compose .elements .ports) o))))

(define-method (om:interface-types (o <system>))
  (apply append (map om:interface-types ((compose .elements .ports) o))))

(define-method (om:types (o <interface>))
  (append (.elements (.types o)) (or (and=> (.behaviour o) (compose .elements .types)) '()) (om:types)))

(define-method (om:types (o <component>))
  (append
   (or (and=> (.behaviour o) (compose .elements .types)) '())
   (om:types)))

(define-method (om:types (o <system>))
  '())

(define-method (om:types (o <behaviour>))
  (.types o))

(define-method (om:types (o <boolean>)) '())

(define-method (om:types (port <port>))
  (om:interface-types (om:import (.type port))))

(define builtin-types (list (make <type> :name 'bool) (make <type> :name 'void)))
(define-method (om:type (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (append (om:types o) (om:types) builtin-types)))

(define-method (om:type (o <model>) (type <type>))
  (or (find (lambda (o) (and (eq? (.name o) (.name type))
                             (or (eq? (.scope o) (.scope type))
                                 (and (or (eq? (.scope o) '*global*))
                                      (not (.scope type))))))
            (append (om:types o) (om:types) builtin-types))))

(define-method (om:type (o <component>) (type <type>))
  (or (next-method)
      (find (lambda (o) (and (eq? (.name o) (.name type))
                             (eq? (.scope o) (.scope type))))
            (om:interface-types o))))

(define-method (om:type (o <model>))
  (lambda (type) (om:type o type)))

(define-method (om:type (model <model>) (variable <variable>))
  (om:type model (.type variable)))

(define-method (om:type (model <model>) (formal <formal>))
  (om:type model (.type formal)))

(define (om:models-with-behaviour om)
  (filter .behaviour (append ((om:filter <component>) om) ((om:filter <interface>) om))))

(define (om:model-with-behaviour om)
  (and-let* ((models (null-is-#f (om:models-with-behaviour om))))
            (car models)))

(define-method (om:event (o <interface>) (name <symbol>))
  (find (lambda (x) (eq? (.name x) name)) (.elements (.events o))))

(define-method (om:event (o <model>) name) #f)

(define-method (om:event (o <interface>) (trigger <trigger>))
  (om:event o (.event trigger)))

(define-method (om:event (o <component>) (trigger <trigger>))
  (om:event (om:interface (om:port o (.port trigger))) (.event trigger)))

;; (define (om:event o trigger)
;;   (match (cons o trigger)
;;     ((($ <interface>) . (? symbol?))
;;      (find (lambda (x) (eq? (.name x) trigger)) (.elements (.events o))))
;;     ((($ <interface>)  . (? (is? <trigger>)))
;;      (om:event o (.event trigger)))
;;     ((($ <component>)  . (? (is? <trigger>)))
;;      (om:event (om:interface (om:port o (.port trigger))) (.event trigger)))
;;     (_ #f)))

(define* (om:events ast)
  (match ast
    (($ <interface>) (.elements (.events ast)))
    (($ <port>) (om:events (om:import (.type ast))))
    (_ (throw 'match-error  (format #f "~a:events: no match: ~a\n" (current-source-location) ast)))))

(define-method (om:guard-equal? (lhs <guard>) (rhs <guard>))
  (equal? (om->list (.expression lhs)) (om->list (.expression rhs))))

(define-method (om:children (o <ast>))
  (map (lambda (slot) (slot-ref o (slot-definition-name slot))) ((compose class-slots class-of) o)))

(define-method (om:triggers-equal? (a <on>) (b <on>))
  (equal? ((compose .elements .triggers) a)
          ((compose .elements .triggers) b)))

;;;; reading/caching
(define *ast-alist* '())

(define (cached-model name)
  (assoc-ref *ast-alist* name))

(define (cache-model name o)
  (set! *ast-alist* (assoc-set! *ast-alist* name o))
  o)

(define (om:unresolved? o)
  (if (not (cached-model (.name o)))
      (let ((resolved (if (is-a? o <interface>)
                          (or (and (null-is-#f ((om:filter <enum>) (.events o))) 'unresolved)
                              'resolved)
                          'component)))
        (if (eq? resolved 'unresolved)
            (stderr "caching [~a]: ~a\n" resolved (.name o))))))

(define-method (om:register-model (o <model>))
  (if (not (cached-model (.name o)))
      (cache-model (.name o) o))
  o)

(define cache-type cache-model)
(define cached-type cached-model)
(define (om:register-type o)
  (if (not (cached-type (.name o)))
      (cache-type (.name o) o))
  o)

(define* ((om:register transform) ast :optional (clear? #f))
  (let ((om (transform ast)))
    (if clear?
        (set! *ast-alist* (filter (lambda (x) (is-a? (cdr x) <*type*>)) *ast-alist*)))
    (for-each om:register-model (om:models om))
    (for-each om:register-type (om:types om))
    om))

(define* (read-ast name #:optional (transform ast->om))
  (and-let* ((ast (null-is-#f (read-dzn name (om:register transform))))
             (models (null-is-#f (om:models ast))))
            (find (lambda (model) (eq? (.name model) name)) models)))

(define* (om:import name #:optional (transform ast->om))
  (or (cached-model name)
      (and-let* ((ast (read-ast name transform)))
                (cache-model name ast))))

(define* (om:parse-dezyne string :optional (register (om:register ast->om)))
  (parse-dezyne string register))

(define (om:declarative? o)
  (or (is-a? o <guard>)
      (is-a? o <on>)
      (and (is-a? o <compound>)
           (>0 (length (.elements o)))
           (om:declarative? (car (.elements o))))
      (and (pair? o)
           (om:declarative? (car o)))))

(define om:imperative? (negate om:declarative?))

(define-method (om:id (o <top>)) ((compose pointer-address scm->pointer) o))

(define-method (om:parent (o <top>) (t <top>)) #f)

(define-method (om:parent (o <ast>) (t <ast>)) #f)

(define-method (om:parent (o <ast-list>) (t <ast>))
  (if (member (om:id t) (map om:id (.elements o)))
      o
      (let loop ((elements (.elements o)))
        (if (null? elements)
            #f
            (let ((parent (om:parent (car elements) t)))
              (if parent parent
                  (loop (cdr elements))))))))

(define-method (om:parent (o <model>) (t <ast>))
  (om:parent ((compose .statement .behaviour) o) t))

(define-method (om:parent (o <guard>) (t <ast>))
  (or (and (eq? (om:id (.statement o)) (om:id t)) o)
      (om:parent (.statement o) t)))

(define-method (om:parent (o <on>) (t <ast>))
  (or (and (eq? (om:id (.statement o)) (om:id t)) o)
      (om:parent (.statement o) t)))

(define ((om:named name) model)
  (eq? (.name model) name))

(define (source-file o)
  (and-let* (((supports-source-properties? o))
             (loc (source-property o 'loc))
             (properties (source-location->user-source-properties loc))
             (file-name (assoc-ref properties 'filename)))
            (string->symbol file-name)))

(define-method (in-file? (o <symbol>))
  (lambda (m) (in-file? m o)))

(define (basename- o)
  (string->symbol (basename (symbol->string o))))

(define-method (in-file? (o <model>) (file <symbol>))
  (and-let* ((model-file (source-file o))
             (model-file (if (string? model-file) (string->symbol model-file) model-file)))
            (eq? (basename- file) (basename- model-file))))

(define-method (in-file? (o <model>) (file <string>))
  (in-file? o (string->symbol file)))

(define-method (om:imported? o)
  (and-let* (((supports-source-properties? o))
             ((assoc 'imported? (source-properties o))))
            (source-property o 'imported?)))

(define-method (om:imported? (o <model>))
  (if (assoc 'imported? (source-properties o))
      (source-property o 'imported?)
      (and-let* (((>2 (length (command-line))))
                 (file (car (option-ref (parse-opts (command-line)) '() '(#f)))))
                (cond
                 ((string= file "-") #f)
                 ((string= file "/dev/stdin") #f)
                 ((string-suffix? ".scm" file) #f)
                 (else (not (in-file? o file)))))))
