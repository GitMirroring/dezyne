;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag gom util)
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
;;  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag gom ast)
  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)
  :use-module (gaiag gom map)

  :export (
           is?
           gom->list
           gom:booleans
           gom:children
           gom:component
           gom:components
           gom:declarative?
           gom:dir-matches?
           gom:enum
           gom:enums
           gom:event
           gom:events
           gom:extern
           gom:externs
           gom:filter
           gom:find-triggers
           gom:function
           gom:function-names
           gom:functions
           gom:guard-equal?
           gom:import
           gom:imports
           gom:imported?
           gom:instance
           gom:in?
           gom:integer
           gom:integers
           gom:interface
           gom:interface-enums
           gom:interface-externs           
           gom:interface-integers
           gom:interface-types           
           gom:interfaces
           gom:model-with-behaviour
           gom:models-with-behaviour
           gom:modeling?
           gom:member-names
           gom:member-values
           gom:models
           gom:named
           gom:out?
           gom:out-or-inout?
           gom:parent
           gom:parse-dezyne
           gom:port
           gom:ports
           gom:provides?
           gom:requires?
           gom:register
           gom:register-model
           gom:register-type
           gom:reply-enums
           gom:statement
           gom:statements-of-type
           gom:system
           gom:systems
           gom:triggers-equal?
           gom:type
           gom:types
           gom:typed?
           gom:variable
           gom:variables
           gom:void?
           ))

(define ((is? class) o)
  (and (is-a? o class) o))

(define (gom->list gom)
  (with-input-from-string
      (with-output-to-string (lambda () (write gom)))
    read))

(define-method (gom:filter (predicate <top>) (o <ast-list>))
  (filter predicate (.elements o)))

(define-method (gom:filter (predicate <top>) (o <list>))
  (filter predicate o))

(define-method (gom:filter (predicate <procedure>))
  (lambda (o) (gom:filter predicate o)))

(define-method (gom:filter (predicate <top>))
  (lambda (o) (gom:filter predicate o)))

(define-method (gom:filter (class <class>))
  (lambda (o) (gom:filter (is? class) o)))

(define* (gom:find-triggers ast :optional (found '()))
  "Search for optional and inevitable."
  (match ast
    ((or ($ <interface>) ($ <component>))
     (or (and=> (.behaviour ast) gom:find-triggers) '()))
    (($ <behaviour>) (or (and=> (.statement ast) gom:find-triggers) '()))
    (($ <compound> statements)
     (delete-duplicates (sort (append (apply append (map gom:find-triggers statements))) <)))
    (($ <on>) (gom:find-triggers (.triggers ast)))
    (($ <triggers>) (.elements ast))
    (($ <guard>) (gom:find-triggers (.statement ast) found))
    (('inevitable) ast)
    (('optional) ast)
    (('action x) '())
    (('illegal) '())
    (('skip) '())
    ('() ast)
    (_ (throw 'match-error  (format #f "~a:gom:find-triggers: no match: ~a\n" (current-source-location) ast)))))

(define (gom:functions ast)
  (match ast
    (($ <behaviour>) (.elements (.functions ast)))
    ((? (is? <model>)) (or (and=> (.behaviour ast) (compose .elements .functions)) '()))
    (($ <gom:port>) (stderr "port: ~a\n" (.type ast))
     (gom:functions (gom:import (.type ast) ast->gom)))
    (#f '())
    (_ (throw 'match-error  (format #f "~a:gom:functions: no match: ~a\n" (current-source-location) ast)))))

(define-method (gom:ports (o <interface>)) '())
(define-method (gom:ports (o <model>)) ((compose .elements .ports) o))

(define (gom:variables ast)
  (match ast
    (($ <behaviour>) (.elements (or (.variables ast) (make <variables>))))
    (($ <interface>) (gom:variables (.behaviour ast)))
    (($ <component>) (gom:variables (.behaviour ast)))
    (($ <gom:port>) (gom:variables (gom:import (.type ast) ast->gom)))
    (#f '())
    (_ (throw 'match-error  (format #f "~a:gom:variables: no match: ~a\n" (current-source-location) ast)))))

(define ((extern? model) var) (gom:extern model (.type var)))

(define (gom:member-names model)
  (map .name (filter (negate (extern? model)) (gom:variables model))))

(define (gom:member-values model)
  (map (compose .value .expression) (filter (negate (extern? model)) (gom:variables model))))

(define (gom:statement ast)
  (match ast
    (($ <model>) (or (and=> (.behaviour ast) gom:statement) (make <compound>)))
    (($ <behaviour>) (or (.statement ast) (make <compound>)))
    (($ <function>) (.statement ast))
    (_ (throw 'match-error  (format #f "~a:gom:statement: no match: ~a\n" (current-source-location) ast)))))

(define ((gom:statement-of-type type) statement)
  (and statement
   (eq? (ast-name statement) type)))

(define ((gom:statements-of-type type) statement)
  (match statement
    ((? (gom:statement-of-type type)) (list statement))
    (($ <compound>) (filter identity (apply append (map (gom:statements-of-type type) (.elements statement)))))
    (($ <on> triggers statement) (filter identity ((gom:statements-of-type type) statement)))
    ((? (is? <statement>)) '())
    (#f '())
    (_ (throw 'match-error  (format #f "~a:gom:statements-of-type, type: ~a: no match: ~a\n" (current-source-location) type statement)))))

(define-method (gom:typed? (o <event>))
  (let ((type ((compose .type .signature) o)))
    (and (not (eq? (.name type) 'void)) type)))

(define-method (gom:typed? (o <boolean>)) #f)

(define-method (gom:typed? (m <model>) (o <trigger>))
  (gom:typed? (gom:event m o)))

(define-method (gom:modeling? (o <trigger>))
  (and (not (.port o)) (not (member (.event o) '(optional inevitable)))))

(define-method (gom:modeling? (m <model>) (o <trigger>))
  (gom:modeling? o))

(define-method (gom:void? (m <model>) (o <trigger>))
  (and (not (gom:modeling? o)) (not (gom:typed? m o))))

(define-method (gom:dir-matches? (p <gom:port>) (e <event>))
  (or (and (eq? (.direction p) 'provides)
           (eq? (.direction e) 'in))
      (and (eq? (.direction p) 'requires)
           (eq? (.direction e) 'out))))

(define-method (gom:dir-matches? (o <gom:port>))
  (lambda (event) (gom:dir-matches? o event)))

(define-method (gom:event (o <interface>) (name <symbol>))
  (find (lambda (x) (eq? (.name x) name)) (.elements (.events o))))

(define-method (gom:event (o <model>) name) #f)

(define-method (gom:event (o <interface>) (trigger <trigger>))
  (gom:event o (.event trigger)))

(define-method (gom:event (o <component>) (trigger <trigger>))
  (gom:event (gom:interface (gom:port o (.port trigger))) (.event trigger)))

(define-method (gom:component (o <top>)) #f)
(define-method (gom:component (o <component>)) o)
(define-method (gom:component (o <list>)) (find (is? <component>) o))
(define-method (gom:component (o <ast-list>))
  (find (is? <component>) (.elements o)))

(define-method (gom:interface (o <top>)) #f)
(define-method (gom:interface (o <interface>)) o)
(define-method (gom:interface (o <list>)) (find (is? <interface>) o))
(define-method (gom:interface (o <ast-list>))
  (find (is? <interface>) (.elements o)))

(define-method (gom:interface (o <gom:port>))
  (gom:import (.type o)))

(define-method (gom:interface (o <model>))
  (gom:interface (gom:port o)))

(define-method (gom:system (o <top>)) #f)
(define-method (gom:system (o <system>)) o)
(define-method (gom:system (o <list>)) (find (is? <system>) o))
(define-method (gom:system (o <ast-list>))
  (find (is? <system>) (.elements o)))

(define-method (gom:port (o <interface>) name)
  #f)

(define-method (gom:port (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (gom:ports o)))

(define-method (gom:port (o <interface>))
  #f)

(define-method (gom:port (o <model>))
  (and=> (null-is-#f ((gom:filter gom:provides?) (.ports o))) car))

(define-method (gom:port (o <system>) (bind <binding>))
  (let* ((port (.port bind)))
    (or
     (and-let* ((name (.instance bind))
                (instance (gom:instance o name))
                (type (and=> instance .component))
                (component (gom:import type)))
               (gom:port component port))
     (gom:port o port))))

(define-method (gom:instance (o <system>) (name <boolean>))
  #f)

(define-method (gom:instance (o <system>) (name <symbol>))
 (find (lambda (x) (eq? (.name x) name)) ((compose .elements .instances) o)))

(define-method (gom:instance (o <system>) (bind <binding>))
  (or (gom:instance o (.instance bind))
      (gom:import (.type (gom:port o (.port bind))))))

(define-method (gom:in? (o <event>))
  (eq? (.direction o) 'in))

(define-method (gom:out? (o <event>))
  (eq? (.direction o) 'out))

(define-method (gom:in? (o <trigger>)) #t)

(define-method (gom:out? (o <trigger>)) #f)

(define-method (gom:out-or-inout? (o <gom:parameter>)) 
  (or (eq? (.direction o) 'out)
      (eq? (.direction o) 'inout)))

(define-method (gom:provides? (o <gom:port>))
  (eq? (.direction o) 'provides))

(define-method (gom:requires? (o <gom:port>))
  (eq? (.direction o) 'requires))

(define (gom:booleans o)
  '())

(define ((make-interface-enum port) o)
  (make <enum> :name (.name o) :scope port :fields (.fields o)))

(define-method (gom:reply-enums (o <interface>))
  (let* ((events (filter gom:typed? ((compose .elements .events) o)))
         (names (delete-duplicates (map (compose .name .type .signature) events))))
    (map (lambda (n) (gom:enum o n)) names)))

(define-method (gom:reply-enums o)
  '())

(define-method (gom:interface-enums (o <interface>))
  ((gom:filter <enum>) (.types o)))

(define-method (gom:interface-enums (port <gom:port>))
  (map (make-interface-enum (.type port)) (gom:enums port)))

(define-method (gom:interface-enums (o <component>))
  (apply append (map gom:interface-enums ((compose .elements .ports) o))))

(define-method (gom:interface-enums (o <system>))
  (apply append (map gom:interface-enums ((compose .elements .ports) o))))

(define-method (gom:enums o)
  ((gom:filter <enum>) (gom:types o)))

(define-method (gom:enum (o <model>) name)
  ((is? <enum>) (gom:type o name)))

(define-method (gom:enum (o <model>) (type <type>))
  ((is? <enum>) (gom:type o type)))

(define ((make-interface-extern port) o)
  (make <extern> :name (.name o) :scope port :value (.value o)))

(define-method (gom:interface-externs (o <interface>))
  ((gom:filter <extern>) (.types o)))

(define-method (gom:interface-externs (port <gom:port>))
  (map (make-interface-extern (.type port)) (gom:externs port)))

(define-method (gom:interface-externs (o <component>))
  (apply append (map gom:interface-externs ((compose .elements .ports) o))))

(define-method (gom:interface-externs (o <system>))
  (apply append (map gom:interface-externs ((compose .elements .ports) o))))

(define-method (gom:externs o)
  ((gom:filter <extern>) (gom:types o)))

(define-method (gom:extern (o <model>) name)
  ((is? <extern>) (gom:type o name)))

;; extern, *global*, TODO
;; (define-method (gom:extern (o <model>) (type <type>))
;;   ((is? <extern>) (gom:type o type)))
  
(define-method (gom:extern (o <model>) (type <type>))
  (find (lambda (o) (and (eq? (.name o) (.name type))
                         ;;(or (eq? (.scope o) (.scope type)) (and (eq? (.scope o) '*global*) (not (.scope type))))
                         ;;(eq? (.scope o) (.scope type)) NEW gone
                         ))
        (append (gom:externs o) (gom:externs))))

(define-method (gom:extern (o <component>) (type <type>))
  (or (next-method)
      (find (lambda (o) (and (eq? (.name o) (.name type))
                             ;;(eq? (.scope o) (.scope type))
                             )) ;; NEW
            (gom:interface-externs o))))

(define ((make-interface-integer port) o)
  (make <int> :name (.name o) :scope port :range (.range o)))

(define-method (gom:interface-integers (o <interface>))
  ((gom:filter <int>) (.types o)))

(define-method (gom:interface-integers (port <gom:port>))
  (map (make-interface-integer (.type port)) (gom:integers port)))

(define-method (gom:interface-integers (o <component>))
  (apply append (map gom:interface-integers ((compose .elements .ports) o))))

(define-method (gom:integers o)
  ((gom:filter <int>) (gom:types o)))

(define-method (gom:integer (o <model>) name)
  ((is? <int>) (gom:type o name)))

(define-method (gom:integer (o <model>) (type <type>))
  ((is? <int>) (gom:type o type)))

(define-method (gom:variable (o <model>))
  (lambda (name) (gom:variable o name)))

(define-method (gom:variable (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (gom:variables o)))

(define-method (gom:function (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (gom:functions o)))

(define-method (gom:model (o <component>)) o)
(define-method (gom:model (o <interface>)) o)
(define (gom:models o) ((gom:filter <model>) o))
(define (gom:imports o) ((gom:filter <import>) o))
(define (gom:interfaces o) ((gom:filter <interface>) o))
(define (gom:components o) ((gom:filter <component>) o))
(define (gom:systems o) ((gom:filter <system>) o))

(define-method (gom:enums) ((gom:filter <enum>) (map cdr *ast-alist*)))
(define-method (gom:externs) ((gom:filter <extern>) (map cdr *ast-alist*)))
(define-method (gom:integers) ((gom:filter <int>) (map cdr *ast-alist*)))
(define-method (gom:types) ((gom:filter <type>) (map cdr *ast-alist*)))
(define-method (gom:types (o <list>)) ((gom:filter <type>) o))
(define-method (gom:types (o <root>)) (gom:types (.elements o)))

;; WIP: refactor gom:enums, gom:integers, gom:externs into gom:types
(define-method (make-interface-type port)
  (lambda (o) (make-interface-type port o)))

(define-method (make-interface-type port (o <enum>))
  ((make-interface-enum port) o))

(define-method (make-interface-type port (o <extern>))
  ((make-interface-extern port) o))

(define-method (make-interface-type port (o <int>))
  ((make-interface-integer port) o))

(define-method (gom:interface-types (o <interface>))
  ((compose .elements .types) o))

(define-method (gom:interface-types (port <gom:port>))
  (map (make-interface-type (.type port)) (gom:types port)))

(define-method (gom:interface-types (o <component>))
  (apply append (map gom:interface-types ((compose .elements .ports) o))))

(define-method (gom:interface-types (o <system>))
  (apply append (map gom:interface-types ((compose .elements .ports) o))))

(define-method (gom:types (o <interface>))
  (append (.elements (.types o)) (or (and=> (.behaviour o) (compose .elements .types)) '())))

(define-method (gom:types (o <component>))
  (or (and=> (.behaviour o) (compose .elements .types)) '()))

(define-method (gom:types (o <system>))
  '())

(define-method (gom:types (o <behaviour>))
  (.types o))

(define-method (gom:types (o <boolean>)) '())

(define-method (gom:types (port <gom:port>))
  (gom:interface-types (gom:import (.type port))))

(define builtin-types (list (make <type> :name 'bool) (make <type> :name 'void)))
(define-method (gom:type (o <model>) name)
  (find (lambda (o) (eq? (.name o) name)) (append (gom:types o) (gom:types) builtin-types)))

(define-method (gom:type (o <model>) (type <type>))
  (or (find (lambda (o) (and (eq? (.name o) (.name type))
                             (or (eq? (.scope o) (.scope type))
                                 (and (eq? (.scope o) '*global*)
                                      (not (.scope type))))))
            (append (gom:types o) (gom:types) builtin-types))))

(define-method (gom:type (o <component>) (type <type>))
  (or (next-method)
      (find (lambda (o) (and (eq? (.name o) (.name type))
                             (eq? (.scope o) (.scope type))))
            (gom:interface-types o))))

(define-method (gom:type (o <model>))
  (lambda (type) (gom:type o type)))

(define-method (gom:type (model <model>) (variable <variable>))
  (gom:type model (.type variable)))

(define (gom:models-with-behaviour gom)
  (filter .behaviour (append ((gom:filter <component>) gom) ((gom:filter <interface>) gom))))

(define (gom:model-with-behaviour gom)
  (and-let* ((models (null-is-#f (gom:models-with-behaviour gom))))
            (car models)))

(define* (gom:events ast)
  (match ast
    (($ <interface>) (.elements (.events ast)))
    (($ <gom:port>) (gom:events (gom:import (.type ast))))
    (_ (throw 'match-error  (format #f "~a:events: no match: ~a\n" (current-source-location) ast)))))

(define-method (gom:guard-equal? (lhs <guard>) (rhs <guard>))
  (equal? (gom->list (.expression lhs)) (gom->list (.expression rhs))))

(define-method (gom:children (o <ast>))
  (map (lambda (slot) (slot-ref o (slot-definition-name slot))) ((compose class-slots class-of) o)))

(define-method (gom:triggers-equal? (a <on>) (b <on>))
  (equal? ((compose .elements .triggers) a)
          ((compose .elements .triggers) b)))

;;;; reading/caching
(define *ast-alist* '())

(define (cached-model name)
  (assoc-ref *ast-alist* name))

(define (cache-model name o)
  (set! *ast-alist* (assoc-set! *ast-alist* name o))
  o)

(define (gom:unresolved? o)
  (if (not (cached-model (.name o)))
      (let ((resolved (if (is-a? o <interface>)
                          (or (and (null-is-#f ((gom:filter <enum>) (.events o))) 'unresolved)
                              'resolved)
                          'component)))
        (if (eq? resolved 'unresolved)
            (stderr "caching [~a]: ~a\n" resolved (.name o))))))

(define-method (gom:register-model (o <model>))
  (if (not (cached-model (.name o)))
      (cache-model (.name o) o))
  o)

(define cache-type cache-model)
(define cached-type cached-model)
(define (gom:register-type o)
  (if (not (cached-type (.name o)))
      (cache-type (.name o) o))
  o)

(define* ((gom:register transform) ast :optional (clear? #f))
  (let ((gom (transform ast)))
    (if clear?
        (set! *ast-alist* (filter (lambda (x) (is-a? (cdr x) <type>)) *ast-alist*)))
    (for-each gom:register-model (gom:models gom))
    (for-each gom:register-type (gom:types gom))
    gom))

(define* (read-ast name #:optional (transform ast->gom))
  (and-let* ((ast (null-is-#f (read-dezyne name (gom:register transform))))
             (models (null-is-#f (gom:models ast))))
            (find (lambda (model) (eq? (.name model) name)) models)))

(define* (gom:import name #:optional (transform ast->gom))
  (or (cached-model name)
      (and-let* ((ast (read-ast name transform)))
                (cache-model name ast))))

(define* (gom:parse-dezyne string :optional (register (gom:register ast->gom)))
  (parse-dezyne string register))

(define-method (gom:declarative? (o <statement>)) #f)
(define-method (gom:declarative? (o <on>)) #t)
(define-method (gom:declarative? (o <guard>)) #t)

(define-method (gom:id (o <top>)) ((compose pointer-address scm->pointer) o))

(define-method (gom:parent (o <top>) (t <top>)) #f)

(define-method (gom:parent (o <ast>) (t <ast>)) #f)

(define-method (gom:parent (o <ast-list>) (t <ast>))
  (if (member (gom:id t) (map gom:id (.elements o)))
      o
      (let loop ((elements (.elements o)))
        (if (null? elements)
            #f
            (let ((parent (gom:parent (car elements) t)))
              (if parent parent
                  (loop (cdr elements))))))))

(define-method (gom:parent (o <model>) (t <ast>))
  (gom:parent ((compose .statement .behaviour) o) t))

(define-method (gom:parent (o <guard>) (t <ast>))
  (or (and (eq? (gom:id (.statement o)) (gom:id t)) o)
      (gom:parent (.statement o) t)))

(define-method (gom:parent (o <on>) (t <ast>))
  (or (and (eq? (gom:id (.statement o)) (gom:id t)) o)
      (gom:parent (.statement o) t)))

(define ((gom:named name) model)
  (eq? (.name model) name))

(define (source-file o)
  (and-let* (((supports-source-properties? o))
             (loc (source-property o 'loc))
             (properties (source-location->user-source-properties loc))
             (file-name (assoc-ref properties 'filename)))
            (string->symbol file-name)))

(define-method (in-file? (o <symbol>))
  (lambda (m) (in-file? m o)))

(define-generic basename)
(define-method (basename (o <symbol>))
  (string->symbol (basename (symbol->string o))))

(define-method (in-file? (o <model>) (file <symbol>))
  (and-let* ((model-file (source-file o)))
            (eq? (basename file) (basename model-file))))

(define-method (in-file? (o <model>) (file <string>))
  (in-file? o (string->symbol file)))

(define-method (gom:imported? o)
  (and-let* (((supports-source-properties? o))
             ((assoc 'imported? (source-properties o))))
            (source-property o 'imported?)))

(define-method (gom:imported? (o <model>))
  (if (assoc 'imported? (source-properties o))
      (source-property o 'imported?)
      (and-let* (((>2 (length (command-line))))
                 (file (car (option-ref (parse-opts (command-line)) '() '(#f))))
                 ((not (string-suffix? ".scm" file))))
                (not (in-file? o file)))))
