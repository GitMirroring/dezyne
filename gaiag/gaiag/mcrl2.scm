;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
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
(define-module (gaiag mcrl2)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)

  #:use-module (gaiag deprecated animate)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)
  #:use-module (gaiag config)
  #:use-module (gaiag command-line)
  #:use-module (gaiag compare)
  #:use-module (gaiag code)
  #:use-module (gaiag csp)
  #:use-module (gaiag c++)
  #:use-module (gaiag dzn)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag resolve)
  #:use-module (gaiag xpand)

  #:export (mcrl2:om
	    root->))

(define annotate-path-alist '())

(define ((annotate-path path) o)
  ;;(stderr "\nannotate-path of: ~a\n" o)
  (set! annotate-path-alist (acons o path annotate-path-alist))
  (let ((path (cons o path)))
    (match o
      (($ <root>) (map (annotate-path path) (.elements o)) o)
      (($ <declarative-compound>) (map (annotate-path path) (.elements o)))
      (($ <compound>) (map (annotate-path path) (.elements o)))
      (($ <functions>) (map (annotate-path path) (.elements o)))
      (($ <function>) ((annotate-path path) (.statement o)))
      (($ <return>) ((annotate-path path) (.expression o)))
      (($ <blocking>) ((annotate-path path) (.statement o)))
      (($ <guard>) ((annotate-path path) (.statement o)))
      (($ <on>) ((annotate-path path) (.statement o)))
      (($ <if>) ((annotate-path path) (.then o)) ((annotate-path path) (.else o)))
      (($ <interface>) ((annotate-path path) (.behaviour o)))
      (($ <component>) ((annotate-path path) (.behaviour o)))
      (($ <behaviour>) ((annotate-path path) (.functions o)) ((annotate-path path) (.statement o)))
      (_ o))))

(define-method (ast:parent (o <ast>))
  (assq-ref annotate-path-alist o))

(define (ast-add-skips o)
  (match o
    (($ <compound> ()) (make <skip>))
    (($ <functions> (functions ...)) o)
    ((and (? (is? <component>) (= .behaviour behaviour)))
     (clone o #:behaviour (ast-add-skips behaviour)))
    ((and (? (is? <interface>) (= .behaviour behaviour)))
     (clone o #:behaviour (ast-add-skips behaviour)))
    ((? (is? <component-model>)) o)
    ((? (is? <ast>)) (om:map ast-add-skips o))
    (_ o)))

(define (ast-complete-elses o)
  (match o
    ((and ($ <if>) (= .else #f)) (ast-complete-elses (clone o #:else (make <skip>))))
    ((? (is? <ast>)) (om:map ast-complete-elses o))
    (_ o)))

(define* (annotate-illegal o #:optional (trigger #f))
  (match o
    (($ <on>) (clone o #:statement (annotate-illegal (.statement o) ((compose .name .event car .elements .triggers) o))))
    (($ <compound>)
     (clone o #:elements (map (lambda (s) (annotate-illegal s trigger)) (.elements o))))
    (($ <blocking> statement) (clone o #:statement (annotate-illegal statement trigger)))
    (($ <illegal>) (make <illegal> #:event trigger))
    (_ o)))

(define (ast-tail-calls o)
  (match o
    (($ <function>) (tail-call o))
    ((? (is? <ast>)) (om:map ast-tail-calls o))
    (_ o)))

(define (ast-annotate-illegals o)
  (match o
    (($ <on>) (annotate-illegal o))
    ((? (is? <ast>)) (om:map ast-annotate-illegals o))
    (_ o)))

(define (ast-transform-event-ends o)
  (match o
    (($ <on>) (clone o #:statement (clone (.statement o) #:elements (append ((compose .elements .statement) o) (list (make <the-end> #:trigger ((compose car .elements .triggers) o)))))))
    ((? (is? <ast>)) (om:map ast-transform-event-ends o))
    (_ o)))

(define* ((root-add-voidreply #:optional (model #f)) o)
  (let ((model (or model o)))
    (match o
	   (($ <root>)
	    (clone o #:elements (map (root-add-voidreply) (.elements o))))
	   (($ <component>)
	    (clone o #:behaviour ((root-add-voidreply model) (.behaviour o))))
	   (($ <interface>)
	    (clone o #:behaviour ((root-add-voidreply model) (.behaviour o))))
	   (($ <behaviour>)
	    (clone o #:statement (ast-transform-return model (.statement o)))))))

(define* ((root-purge-data #:optional (model #f)) o)
  (let ((model (or model o)))
    (match o
	   (($ <root>)
	    (clone o #:elements (map (root-purge-data) (.elements o))))
	   (($ <component>)
	    (clone o #:behaviour ((root-purge-data model) (.behaviour o))))
	   (($ <interface>)
	    (clone o
		   #:events ((root-purge-data model) (.events o))
		   #:behaviour ((root-purge-data model) (.behaviour o))))
	   (($ <events>)
	    (clone o #:elements (map (root-purge-data model) (.elements o))))
	   (($ <event>)
	    (clone o #:signature ((root-purge-data model) (.signature o))))
	   (($ <signature>)
	    (clone o #:formals (make <formals>)))
	   (($ <behaviour>)
	    (clone o
		   #:types (make <types> #:elements (purge-data model (.elements (.types o))))
		   #:variables (make <variables> #:elements (filter (lambda (x) (not (om:extern model x))) (.elements (.variables o))))
		   #:functions (make <functions> #:elements (purge-data model (.elements (.functions o))))
		   #:statement (purge-data model (.statement o)))))))

(define (om:models o)
  (clone o #:elements (filter (conjoin (is? <model>) om:behaviour?) (.elements o))))

;; Deprecated/not fully functional
(define (postprocess o)
  (match o
    (('scope.name () name) `(name ,name))
    (('scope.name (scope ...) name) `(name ,@scope ,name))
    (('void ('scope.name () 'void)) '(type void))
    (('value value) value)
    (('signature ('enum name fields) formals) `(signature (type ,(postprocess name)) ,(postprocess formals)))
    (('trigger port ('event name x ...) formals) `(trigger ,port ,name (arguments)))
    (('variable name ('enum ename fields) expression) `(variable ,name (type ,(postprocess ename)) ,(postprocess expression)))
    (('guard ('field ('variable name type expression) value) triggers) `(guard (expression (field ,(postprocess name) ,value)) ,(postprocess triggers)))
    (('assign ('variable name x ...) expression) `(assign ,name ,(postprocess expression)))
    (('reply expression port) `(reply ,(postprocess expression) ,port))
    (('formal name ('enum ename fields) direction) `(formal ,name (type ,(postprocess ename)) ,direction))
    (('var ('variable name x ...)) `(expression (var ,(postprocess name))))
    (('action port ('event name x ...) arguments) `(action (trigger ,port ,name (arguments))))
    (('literal ('enum name fields) field) `(expression (literal ,(postprocess name) ,field)))
    (('behaviour name types ports variables functions statement) (list 'behaviour name types (postprocess variables) (postprocess functions) (postprocess statement)))
    ((t ...) (map postprocess o))
    (_ o)))

(define (root-> root) (ast:set-scope root (root->mcrl2 root)))

(define (root->sexp root)
  ((compose
    pretty-print
    postprocess
    om2list
    ) root))

(define (mcrl2:om ast)
  ((compose-root
    (annotate-path '())
   ;; (lambda (o) (stderr "AST ~a\n" o) o)
    flatten-compound
    ast-complete-elses
    ast-annotate-illegals
    ast-transform-event-ends
    transform-compounds
    flatten-compound
    (root-purge-data)
    (root-add-voidreply)
    ast-tail-calls
    ast-add-skips
    aggregate-guard-g
    (expand-on)
    flatten-compound
    (prepend-true-guard)
    (aggregate-on norm:on-same-port-voidness-statement?)
    (expand-on norm:port-and-voidness-equal?)
    aggregate-guard-g
    flatten-compound
    combine-guards
    passdown-on
    flatten-compound
    (passdown-blocking)
    (remove-otherwise)
    om:models
    ast:resolve
    parse->om
    ) ast))

(define (root->mcrl2 root)
  (let ((module (make-module 31 `(,(resolve-module '(gaiag deprecated code))
                                  ,(resolve-module '(gaiag mcrl2))))))
    (module-define! module 'root root)
    (parameterize ((template-dir (string-append %template-dir "/mcrl2")))
      (x:pand 'source@root (module-ref module 'root) module))))

(define (ast-> ast)
  (let* ((files (gdzn:command-line:get '() #f))
         (base (basename (car files) ".dzn"))
         (base (basename base ".scm"))
         (dir (command-line:get 'output #f))
         (file-name (string-append base ".mcrl2"))
         (file-name (cond ((equal? dir "-") dir)
			  (dir (string-append dir "/" file-name))
			  (else file-name)))
	 (root (mcrl2:om ast))
         (ast? (command-line:get 'ast #f))
         (->mcrl2 (if ast? root->sexp
                      root->mcrl2)))
    (ast:set-scope root
                   (if (equal? file-name "-") (->mcrl2 root)
                       (with-output-to-file file-name (cut ->mcrl2 root))))
    ""))

;;to be revisited
(define (om:extern model identifier)
  (as ((om:type model) identifier) <extern>))

(define (om:behaviour? o)
  (match o
    ((or ($ <component>) ($ <interface>)) (.behaviour o))
    (($ <behaviour>) o)
    (_ #f)))

(define (mcrl2:interface-name o) ((compose om:name .interface) o))
(define (mcrl2:interfaces o) (delete-duplicates (map .type (om:ports o))))
(define-method (mcrl2:provided-port-type (o <component>)) ((compose om:name .type car om:provided) o)) ;;TODO: only works for single provides port
(define-method (mcrl2:provided-port-type (o <interface>)) (om:name o))
(define-method (mcrl2:provided-port-name (o <component>)) ((compose .name car om:provided) o))
(define-method (mcrl2:provided-port-name (o <interface>)) (om:name o))
(define-template x:component (lambda (o) (filter (is? <component>) (.elements o))))
(define-template x:provided-port-type (lambda (o) (mcrl2:provided-port-type (ast:model-scope))))
(define-template x:provided-port-name (lambda (o) (mcrl2:provided-port-name (ast:model-scope))))
(define-template x:sort-interface mcrl2:interfaces 'newline-indent-infix)
(define-template x:sort-component identity 'newline-indent-infix)
(define-template x:action-struct (lambda (o) (map
					      (lambda (x) (make <interface-event> #:interface o #:event x))
					      ((compose .elements .events) o))) 'pipe-infix)
(define-template x:interface-name mcrl2:interface-name)
(define-template x:map-interface-name mcrl2:interfaces 'newline-indent-infix)
(define-template x:eqn-interface-name mcrl2:interfaces 'newline-indent-infix)
(define-template x:global-interface-reply mcrl2:interfaces 'newline-indent-infix)
(define-template x:interface-action-alphabet mcrl2:interfaces 'newline-indent-infix)
(define-template x:port-action-alphabet (compose .elements .ports) 'newline-indent-infix)
(define-template x:port-interface-name (compose om:name .type))
(define-template x:event-name (compose .name .event))
(define-template x:integers get-ints 'newline-indent-suffix)
(define-template x:enum-struct get-enums 'newline-indent-suffix)

(define-template x:mcrl2-references-sort models-with-calls 'newline-infix <model>)

(define (models-with-calls o)
  (append-map
   (lambda (m)
     (if (pair? ((om:collect <call>) m))
	 (list m)
	 '()))
   (append (mcrl2:interfaces o) (list o))))

(define-template x:references references 'pipe-infix)
(define-template x:resolve-reference references 'else-infix)
(define (references o)
  ((om:collect (lambda (o) (and (is-a? o <call>) (not (.last? o))))) o))

(define-template x:valued-return
  (lambda (o)
    (or (.expression o) "")) #f <expression>)

(define-template x:return-type return-type )

(define-method (return-type (o <ast>))
  )

(define-template x:mcrl2-return-process
  (lambda (o)
    (let ((models (models-with-calls o)))
      (if (pair? models)
	  models
	  '()))) 'newline-infix <model>)

(define-template x:enum-field-struct
  (lambda (o) (map
	       (lambda (x) (make <enum-name-field> #:name (.name.name o) #:field x))
	       ((compose .elements .fields) o))) 'pipe-infix)
(define-template x:reply-union-struct
  (lambda (o) (let ((reply-types (code:reply-types o #:pred (const #t))))
		(map
		 (lambda (x i) (make <interface-type> #:interface o #:type x #:index i))
		 reply-types (iota (length reply-types))))) 'pipe-infix)

(define-method (get-enums (o <interface>))
  (append ((compose (cut filter (is? <enum>) <>) .elements .types) o)
	  ((compose (cut filter (is? <enum>) <>) .elements .types .behaviour) o)))

(define-method (get-enums (o <component>))
  ((compose (cut filter (is? <enum>) <>) .elements .types .behaviour) o))

(define-method (get-ints (o <interface>))
  (append ((compose (cut filter (is? <int>) <>) .elements .types) o)
	  ((compose (cut filter (is? <int>) <>) .elements .types .behaviour) o)))
(define-method (get-ints (o <component>))
  ((compose (cut filter (is? <int>) <>) .elements .types .behaviour) o))

(define-template x:print-ast
  (lambda (o) (stderr "AST: ~a\n" o) (->string o)))

(define-template x:pretty-print-dzn
  (lambda (o)
    (string-join (string-split (string-trim-right
				(ast->dzn (or (and=> (as o <behaviour>) .statement) o)))
                               #\newline) "\n     % " 'prefix)))

(define-template x:mcrl2-interface-process
  (lambda (o)
    (match o
      (($ <component>) (mcrl2:interfaces o))
      (($ <interface>) (.behaviour o)))))

(define-template x:mcrl2-component-process .behaviour)

(define (mcrl2:expand-types o)
  (let ((t (.type o)))
    (match t
      (($ <enum>) (string-append ((compose symbol->string mcrl2:interface-name) o) "'" ((compose symbol->string .name .name) t)))
      (($ <void>) 'Void))))

(define-template x:mcrl2-type-name mcrl2:expand-types)
(define-template x:action-union-struct om:ports 'pipe-infix)

(define-template x:mcrl2-process-name identity #f <ast>)
(define-template x:function-scope (lambda (o) (function-scope o (ast:parent o))))
(define-method (function-scope (o <ast>) scope)
  (if (pair? (cdr scope))
      (let ((parent (cadr scope)))
	(match parent
	  (($ <function>) (string-append "'" ((compose ->string .name) parent)))
	  (_ (function-scope parent (cdr scope)))))
      ""))

(define-template x:mcrl2-statement
  (lambda (o)
    (match o
      (($ <behaviour>) (.statement o))
      (($ <guard>) o)
      ((_) "otherwise"))))

(define mcrl2:port-identifier
  (let ((id-alist '())
	(next -1))
    (lambda (o)
      (let ((key (.id o)))
	(number->string (or (assq-ref id-alist key)
			    (begin
			      (set! next (1+ next))
			      (set! id-alist (acons key next id-alist))
			      next)))))))

(define mcrl2:process-identifier
  (let ((id-alist '())
	(next-alist '()))
    (lambda (o)
      (let* ((id (.id o))
	     (sid ((compose .id ast:model-scope)))
	     (key (cons id sid))
	     (next (assq-ref next-alist sid))
	     (next (or next -1)))
	(number->string (or (assoc-ref id-alist key)
			    (let ((next (1+ next)))
				   (set! id-alist (acons key next id-alist))
				   (set! next-alist (assoc-set! next-alist sid next))
				   next)))))))

(define-template x:next-call-reference
  (lambda (o)
    (mcrl2:process-identifier (process-continuation- o (cons #f (ast:parent o))))))

(define-template x:mcrl2-type (compose mcrl2-type .type))
(define-method (mcrl2-type (o <type>))
  (match o
    (($ <bool>) "Bool")
    (($ <enum>) (string-join (map symbol->string (om:scope+name (.name o))) "'" 'infix))
    (($ <int>) (string-join (map symbol->string (om:scope+name (.name o))) "'" 'infix))
    (($ <refs>) (string-append (->string (om:name (ast:model-scope))) "'" "Refs"))))

;; (define-method (mcrl2-expression (o <expression>))
;;   (match o
;;     (($ <literal>) ((compose ->string .value) o))
;;     (($ <var>) ((compose symbol->string .name .variable) o))
;;     (($ <enum-literal>) (string-append (mcrl2-type (.type o)) "'" (symbol->string (.field o))))
;;     (($ <field-test>) (string-append (symbol->string (.variable.name o)) " == " (mcrl2-type (.type (.variable o))) "'" (symbol->string (.field o))))
;;     (($ <and>) (string-append (mcrl2-expression (.left o)) " && " (mcrl2-expression (.right o))))
;;     (($ <not>) (string-append "!" (mcrl2-expression (.expression o))))
;;     (($ <less>) (string-append (mcrl2-expression (.left o)) " < " (mcrl2-expression (.right o))))
;;     (($ <equal>) (string-append (mcrl2-expression (.left o)) " == " (mcrl2-expression (.right o))))
;;     (($ <plus>) (string-append (mcrl2-expression (.left o)) " + " (mcrl2-expression (.right o))))
;;     (($ <call>) "foo" )));;TODO

(define-method (globals (o <ast>))
  (let* ((scope (ast:model-scope))
	 (behaviour (.behaviour scope))
	 (vars ((compose .elements .variables) behaviour)))
    (append-map (lambda (v)
		  (list (string-append (symbol->string (.name v)) ": " (mcrl2-type (.type v))))) vars)))

(define-method (locals (o <ast>) scope)
  (let* ((vars (locals- o scope '())))
    (append-map (lambda (v)
		  (list (string-append (->string (.name v)) ": " (mcrl2-type (.type v))))) vars)))

(define-method (locals- (o <ast>) scope result)
  (if ((is? <behaviour>) o)
      result
      (let* ((parent (cadr scope)))
	(cond ((is-a? parent <compound>) (let* ((pre (cdr (memq o (reverse (.elements parent)))))
						(result (append result (filter (is? <variable>) pre))))
					   (locals- parent (cdr scope) result)))
	      ((is-a? o <function>) (append result ((compose .elements .formals .signature) o)
					    (list (make <cont>))))
	      (else (locals- parent (cdr scope) result))))))

(define-template x:process-parameters
  (lambda (o)
    (let ((provided-port-type (symbol->string (mcrl2:provided-port-type (ast:model-scope)))))
      (string-join
       (append (list
		"br: Bool"
		(string-append "reply_" provided-port-type ": " provided-port-type "'ReplyUnion"))
	       (globals o)
	       (if (is-a? o <model>)
		   '()
		   (locals o (ast:scope))))
       ", " 'infix))))

(define-template x:call-parameters
  (lambda (o)
    (append (map
	     (lambda (f e) (make <call-parameter> #:name (.name f) #:expression e))
	     ((compose .elements .formals .signature .function) o)
	     ((compose .elements .arguments) o)))) 'comma-suffix)
(define-template x:cont-parameter
  (lambda (o) (make <cont-parameter> #:continuation (call-continuation o))))

(define (cont-locals o)
  (let* ((cont (process-continuation- o (cons #f (ast:parent o))))
	 (cont-locals (locals- cont (cons #f (ast:parent cont)) '())))
    cont-locals))

(define-template x:process-continuation-parameters cont-locals 'param-list-grammar <variable>)

(define-method (call-continuation (o <call>))
  (if (.last? o)
      "cont"
      o))
(define-template x:next-call-context cont-locals 'param-list-grammar <variable>)
(define-template x:init-locals-from-cont cont-locals 'comma-infix <variable>)

(define-template x:call-continuation .continuation)

(define-template x:globals-init init-globals)

(define-template x:mcrl2-statement-process mcrl2:statement-process)
(define-template x:mcrl2-function-process (compose .elements .functions))
(define-template x:mcrl2-process-identifier mcrl2:process-identifier)
(define-template x:mcrl2-port-identifier mcrl2:port-identifier)
(define-template x:mcrl2-child-identifier mcrl2:child-identifier)

(define-template x:mcrl2-statement-then .then #f <statement>)
(define-template x:mcrl2-statement-else .else #f <statement>)
(define-template x:if-else-identifier
  (lambda (o) (mcrl2:process-identifier
	       (let ((elsestmt (.else o)))
		 (match elsestmt
		   (($ <compound>) ((compose car .elements) elsestmt))
		   (_ elsestmt))))))

(define-template x:component-reply-in-stmt
  (lambda (o)
    (if (and (is-a? (ast:model-scope) <component>) (ast:requires? (.port o)))
	o
	"")))

(define-template x:on-event-union .elements 'union-infix)
(define-template x:on-event-process .elements)
(define-template x:on-trigger separate-trigger-type)
(define-template x:the-end-trigger separate-trigger-type)
(define (separate-trigger-type o)
  (match (mcrl2:on-event-trigger o)
    ('optional (make <optional>))
    ('inevitable (make <inevitable>))
    (_ o)))
(define-template x:on-event-trigger mcrl2:on-event-trigger)
(define (mcrl2:on-event-trigger o)
  (match o
    (($ <on>) ((compose .event.name car .elements .triggers) o))
    (($ <action>) (.event.name o))
    (($ <the-end>) ((compose .event.name .trigger) o))
    (($ <illegal>) (.event o))))
(define-template x:trigger-port trigger-port)
(define-method (port p)
  (if p
      (.name p)
      (om:name (ast:model-scope))))
(define-method (trigger-port (o <ast>))
  (match o
    (($ <action>) (port (.port o)))
    (($ <the-end>) ((compose port .port .trigger) o))
    (($ <on>) ((compose port .port car .elements .triggers) o))))

(define-template x:trigger-port-type trigger-port-type)
(define-method (port-type p)
  (if p
      (om:name (.type p))
      (om:name (ast:model-scope))))
(define-method (trigger-port-type (o <ast>))
  (match o
    (($ <action>) (port-type (.port o)))
    (($ <the-end>) ((compose port-type .port .trigger) o))
    (($ <on>) ((compose port-type .port car .elements .triggers) o))))
(define-template x:trigger-port-type-reply trigger-port-type-reply)
(define-method (trigger-port-type-reply (o <the-end>))
  (let* ((trigger (.trigger o))
	 (port (.port trigger)))
    (if port
	(if (ast:provides? port)
	    (om:name (.type port))
	    port)
	(om:name (ast:model-scope)))))
(define-method (trigger-port-type-reply (o <action>))
  (let ((port (.port o)))
    (if (ast:provides? port)
	(om:name (.type port))
	port)))

(define-method (illegal-or-dillegal (o <ast>) scope)
  (let* ((parent (cadr scope)))
    (match parent
      (($ <on>) "Dillegal")
      (($ <if>) "Illegal")
      (_ (illegal-or-dillegal parent (cdr scope))))))

(define-template x:illegal-type
  (lambda (o)
    (if ((is? <interface>) (ast:model-scope))
	"Illegal"
	(illegal-or-dillegal o (ast:scope)))))

(define-template x:mcrl2-component-queues identity)
(define-template x:mcrl2-component-run2completion identity)
(define-template x:required-ports-completion om:required 'union-prefix)
(define-template x:required-port-queue om:required 'union-suffix)
(define-template x:inevitable-optional-queue
  (lambda (o)
    (if (pair? (om:required o))
	o
	"")) 'union-suffix)
(define-template x:required-inevitable-allow om:required 'union-infix)
(define-template x:required-optional-allow om:required 'union-infix)
(define-template x:mcrl2-component-rc-required-port identity)
(define-template x:mcrl2-component-rc-provided-port identity)
(define-template x:mcrl2-required-with-out-event required-ports-with-out)
(define-template x:required-ports-run2completion
  (lambda (o)
    (if (pair? (required-ports-with-out o))
	o
	"delta")))
(define-template x:run2completion-port-with-out-event required-ports-with-out 'union-suffix)
(define-template x:provided-run2completion-port-with-out-event required-ports-with-out 'union-suffix)
(define-template x:mcrl2-component-implementation identity)
(define-template x:rename-required-ports om:required 'comma-suffix)
(define-template x:rename-provided-ports (compose car om:provided))
(define-template x:hidden-actions identity)
(define-template x:required-port-hidden-actions om:required 'comma-suffix)
(define-template x:provided-port-hidden-actions (compose car om:provided))
(define-template x:allowed-actions identity)
(define-template x:required-port-allowed-actions om:required 'comma-suffix)
(define-template x:provided-port-allowed-actions (compose car om:provided))
(define-template x:communicated-actions identity)
(define-template x:required-port-communicated-actions om:required 'comma-suffix)
(define-template x:provided-port-communicated-actions (compose car om:provided))
(define-template x:allowed-parallel-actions identity)
(define-template x:required-port-allowed-parallel-actions om:required 'comma-suffix)
(define-template x:provided-port-allowed-parallel-actions (compose car om:provided))
(define-template x:communicated-allowed-parallel-actions identity)
(define-template x:required-port-communicated-allowed-parallel-actions om:required 'comma-suffix)
(define-template x:provided-port-communicated-allowed-parallel-actions (compose car om:provided))
(define-template x:allowed-communicated-allowed-parallel-actions identity)
(define-template x:required-port-allowed-communicated-allowed-parallel-actions om:required 'comma-suffix)
(define-template x:provided-port-allowed-communicated-allowed-parallel-actions (compose car om:provided))
(define-template x:required-port-parallel-communication
  (lambda (o)
    (if (pair? (om:required o))
	o
	"")))
(define-template x:no-required-port-parallel-communication
  (lambda (o)
    (if (pair? (om:required o))
	""
	o)))
(define-template x:communicate-required-port-actions identity)
(define-template x:rename-in-reply-out-req-port om:required 'comma-infix)
(define-template x:rename-required-port-actions om:required 'parallel-suffix)
(define-template x:rename-out-reply-in-req-port om:required 'comma-infix)
(define-template x:process-continuation process-continuation #f <ast>)

(define-method (required-ports-with-out (o <component>))
  (let ((required-ports (om:required o)))
    (filter
     (lambda (p) (not (null? (filter om:out? ((compose .elements .events .type) p)))))
     required-ports)))

(define-class <mcrl2-interface> (<ast>)
  (interface #:getter .interface #:init-value #f #:init-keyword #:interface))

(define-class <interface-index> (<mcrl2-interface>)
  (index #:getter .index #:init-value 0 #:init-keyword #:index))

(define-class <interface-event> (<mcrl2-interface>)
  (event #:getter .event #:init-value #f #:init-keyword #:event))

(define-class <enum-name-field> (<ast>)
  (name #:getter .name #:init-value #f #:init-keyword #:name)
  (field #:getter .field #:init-value #f #:init-keyword #:field))

(define-class <interface-type> (<interface-index>)
  (type #:getter .type #:init-value #f #:init-keyword #:type))

(define-template x:assign-by-call? assign-by-call?)

(define-method (assign-by-call? (o <assign>))
  (if (is-a? (.expression o) <call>)
      (.expression o)
      ""))

(define-class <refs> (<type>))
(define-class <cont> (<type>)
  (name #:getter .name #:init-value "cont" #:init-keyword #:name)
  (type #:getter .type #:init-value (make <refs>) #:init-keyword #:type))
(define-class <call-parameter> (<ast>)
  (name #:getter .name #:init-value #f #:init-keyword #:name)
  (expression #:getter .expression #:init-value #f #:init-keyword #:expression))
(define-method (dzn:expression (o <call-parameter>))
  (.expression o))
(define-class <cont-parameter> (<ast>)
  (name #:getter .name #:init-value "cont" #:init-keyword #:name)
  (continuation #:getter .continuation #:init-value #f #:init-keyword #:continuation))

(define-method (process-continuation- (o <ast>) scope)
  (let* ((parent (cadr scope)))
    (match parent
      (($ <behaviour>) parent)
      (($ <compound>) (let ((cont (cdr (memq o (.elements parent)))))
			(if (pair? cont)
			    (car cont)
			    (process-continuation- parent (cdr scope)))))
      (_ (process-continuation- parent (cdr scope))))))

(define-method (process-continuation (o <ast>))
  (process-continuation- o (ast:scope)))

(define-method (first-process (o <ast>))
  (let loop ((process o))
     (if (not (is-a? process <compound>))
	 process
	 (loop ((compose car .elements) process)))))

(define-method (mcrl2:value (o <expression>))
  (match o
    (($ <enum-literal>) (string-append ((compose ->string om:name) (ast:model-scope)) "'State'" (->string (.field o))))
    (($ <literal>) (.value o))))

;;TODO: stop returning ASCII, start returning objects
(define-method (globals-from-scope scope)
  (let* ((behaviour (.behaviour scope))
	 (vars ((compose .elements .variables) behaviour)))
    (string-join
     (append (list
	      "false"
	      (string-append "reply_" (symbol->string (mcrl2:provided-port-type scope)) "0(void)"))
	     (append-map (lambda (v)
			   (list ((compose ->string mcrl2:value .expression) v))) vars))
     ", " 'infix)))

(define-method (init-globals (o <component>))
  (globals-from-scope (ast:model-scope)))

(define-method (init-globals (o <port>))
  (globals-from-scope (.type o)))

(define-method (mcrl2:statement-process (o <behaviour>)) (.statement o))
(define-method (mcrl2:statement-process (o <compound>)) (.elements o))
(define-method (mcrl2:statement-process (o <declarative-compound>)) (.elements o))
(define-method (mcrl2:statement-process (o <guard>)) (.statement o))
(define-method (mcrl2:statement-process (o <on>)) (.statement o))
(define-method (mcrl2:statement-process (o <illegal>)) o)
(define-method (mcrl2:statement-process (o <if>)) o)
(define-method (mcrl2:statement-process (o <skip>)) o)
(define-method (mcrl2:statement-process (o <assign>)) o)
(define-method (mcrl2:statement-process (o <variable>)) o)
(define-method (mcrl2:statement-process (o <function>)) (.statement o))
(define-method (mcrl2:child-identifier (o <behaviour>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <function>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <guard>)) (mcrl2:process-identifier (.statement o)))
(define-method (mcrl2:child-identifier (o <on>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <if>)) (mcrl2:process-identifier (first-process (.then o))))
