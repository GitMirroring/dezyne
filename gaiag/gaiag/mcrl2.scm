;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
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
  #:use-module (system foreign)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

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
  #:use-module (gaiag norm-event)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag resolve)
  #:use-module (gaiag xpand)

  #:export (mcrl2:om
            tick-names
	    root->
            globals-from-scope))

(define %model (make-parameter '***%model-not-set***))
(define-class <mcrl2-interface-node> (<ast-node>)
  (interface #:getter .interface #:init-value #f #:init-keyword #:interface))
(define-class <interface-index-node> (<mcrl2-interface-node>)
  (index #:getter .index #:init-value 0 #:init-keyword #:index))
(define-class <interface-event-node> (<mcrl2-interface-node>)
  (event #:getter .event #:init-value #f #:init-keyword #:event))
(define-class <enum-name-field-node> (<ast-node>)
  (name #:getter .name #:init-value #f #:init-keyword #:name)
  (field #:getter .field #:init-value #f #:init-keyword #:field))
(define-class <interface-type-node> (<interface-index-node>)
  (type #:getter .type #:init-value #f #:init-keyword #:type))
(define-class <refs-node> (<type-node>))
(wrap <refs-node> <refs> (<type>))
(define-class <cont-node> (<type-node>)
  (name #:getter .name #:init-value "cont" #:init-keyword #:name)
  (type #:getter .type #:init-value (make <refs>) #:init-keyword #:type))
(define-class <call-parameter-node> (<ast-node>)
  (name #:getter .name #:init-value #f #:init-keyword #:name)
  (expression #:getter .expression #:init-value #f #:init-keyword #:expression))
(define-class <cont-parameter-node> (<ast-node>)
  (name #:getter .name #:init-value "cont" #:init-keyword #:name)
  (continuation #:getter .continuation #:init-value #f #:init-keyword #:continuation))
(define-class <assign-call-node> (<ast-node>)
  (assign #:getter .assign #:init-value #f #:init-keyword #:assign)
  (call #:getter .call #:init-value #f #:init-keyword #:call))
(define-class <assign-action-node> (<ast-node>)
  (assign #:getter .assign #:init-value #f #:init-keyword #:assign)
  (action #:getter .action #:init-value #f #:init-keyword #:action))
(define-class <variable-call-node> (<ast-node>)
  (variable #:getter .variable #:init-value #f #:init-keyword #:variable)
  (call #:getter .call #:init-value #f #:init-keyword #:call))
(define-class <variable-action-node> (<ast-node>)
  (variable #:getter .variable #:init-value #f #:init-keyword #:variable)
  (action #:getter .action #:init-value #f #:init-keyword #:action))

(wrap <mcrl2-interface-node> <mcrl2-interface> (<ast>))
(wrap <interface-index-node> <interface-index> (<mcrl2-interface>))
(wrap <interface-event-node> <interface-event> (<mcrl2-interface>))
(wrap <enum-name-field-node> <enum-name-field> (<ast>))
(wrap <interface-type-node> <interface-type> (<interface-index>))
(wrap <cont-node> <cont> (<type>))
(wrap <call-parameter-node> <call-parameter> (<ast>))
(wrap <cont-parameter-node> <cont-parameter> (<ast>))
(wrap <assign-call-node> <assign-call> (<ast>))
(wrap <assign-action-node> <assign-action> (<ast>))
(wrap <variable-call-node> <variable-call> (<ast>))
(wrap <variable-action-node> <variable-action> (<ast>))


(define-method (.event.name (o <assign-action>)) ((compose .event.name .action) o))
(define-method (.event.name (o <variable-action>)) ((compose .event.name .action) o))
(define-method (.variable.name (o <assign-action>)) ((compose .variable.name .assign) o))
(define-method (.name (o <variable-action>)) ((compose .name .variable) o))

(define annotate-path-alist '())

(define ((annotate-path path) o)
  (set! annotate-path-alist (acons o path annotate-path-alist))
  (let ((path (cons o path)))
    (match o
      (($ <root>) (map (annotate-path path) (.elements o)) o)
      (($ <declarative-compound>) (map (annotate-path path) (.elements o)))
      (($ <compound>) (map (annotate-path path) (.elements o)))
      (($ <functions>) (map (annotate-path path) (.elements o)))
      (($ <function>) ((annotate-path path) (.statement o)))
      (($ <assign>) ((annotate-path path) (.expression o)))
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

;; (define-method (trigger->illegal (o <trigger>))
;;   (make <on>
;;     #:triggers (make <triggers> #:elements (list o))
;;     #:statement (make <illegal>)))

;; (define* ((ast-add-illegals #:optional model) o)
;;   (stderr "ast-add-illegals: ~a\n" o)
;;   (match o
;;     ((and ($ <component>) (= .behaviour behaviour))
;;      (clone o #:behaviour ((ast-add-illegals o) behaviour)))

;;     ((and ($ <behaviour>) (= .statement statement))
;;      (clone o #:statement ((ast-add-illegals model) statement)))

;;     (($ <guard>) (clone o #:statement ((ast-add-illegals model) (.statement o))))

;;     (($ <on>)
;;      (let* ((triggers (ast:in-triggers model))
;;             (on-triggers ((compose .elements .triggers) o))
;;             (triggers (filter
;;                        (lambda (trigger)
;;                          (not (find (lambda (on-trigger)
;;                                       (and (eq? (.port.name trigger) (.port.name on-trigger))
;;                                            (eq? (.event.name trigger) (.event.name on-trigger))))
;;                                     on-triggers)))
;;                        triggers)))
;;        (make <compound> #:elements (append (list o) (map trigger->illegal triggers)))))

;;     ((and ($ <compound>) (? om:declarative?)) (=> failure)
;;      (if (and (pair? (.elements o)) (is-a? (car (.elements o)) <guard>))
;;          (clone o #:elements (map (ast-add-illegals model) (.elements o)))
;;          (if (is-a? (car (.elements o)) <on>)
;;              (let* ((triggers (ast:in-triggers model))
;;                     (ons (filter (is? <on>) (.elements o)))
;;                     (compounds (filter (is? <compound>) (.elements o)))

;;                     ;;(ons (append (ons )))
;;                     (on-triggers (append-map (compose .elements .triggers) ons))
;;                     (triggers (filter
;;                                (lambda (trigger)
;;                                  (not (find (lambda (on-trigger)
;;                                               (and (eq? (.port.name trigger) (.port.name on-trigger))
;;                                                    (eq? (.event.name trigger) (.event.name on-trigger))))
;;                                             on-triggers)))
;;                                triggers)))
;;                (clone o #:elements (append (.elements o) (map trigger->illegal triggers))))
;;              o)))
;;     (($ <interface>) o)
;;     (($ <system>) o)
;;     (($ <foreign>) o)
;;     ((? (is? <ast>)) (tree-map (ast-add-illegals model) o))
;;     (_ o)))

(define (ast-add-skips o)
  (match o
    ((and ($ <compound>) (= .elements '())) (make <skip>))
    (($ <functions>) o) ;; FIXME: continuation of if (true) {} in function?
    ((and (? (is? <component>) (= .behaviour behaviour)))
     (clone o #:behaviour (ast-add-skips behaviour)))
    ((and (? (is? <interface>) (= .behaviour behaviour)))
     (clone o #:behaviour (ast-add-skips behaviour)))
    ((? (is? <component-model>)) o)
    ((? (is? <ast>)) (tree-map ast-add-skips o))
    (_ o)))

(define (ast-complete-elses o)
  (match o
    ((and ($ <if>) (= .else #f)) (ast-complete-elses (clone o #:else (make <skip>))))
    ((? (is? <ast>)) (tree-map ast-complete-elses o))
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
    ((? (is? <ast>)) (tree-map ast-tail-calls o))
    (_ o)))

(define (ast-annotate-illegals o)
  (match o
    (($ <on>) (annotate-illegal o))
    ((? (is? <ast>)) (tree-map ast-annotate-illegals o))
    (_ o)))

(define (ast-transform-event-ends o)
  (match o
    (($ <on>) (clone o #:statement (clone (.statement o) #:elements (append ((compose .elements .statement) o) (list (make <the-end> #:trigger ((compose car .elements .triggers) o)))))))
    ((? (is? <ast>)) (tree-map ast-transform-event-ends o))
    (_ o)))

(define* ((root-add-voidreply #:optional (model #f)) o)
  (let ((model (or model o)))
    (match o
      (($ <component>)
       (clone o #:behaviour ((root-add-voidreply o) (.behaviour o))))
      (($ <interface>)
       (clone o #:behaviour ((root-add-voidreply o) (.behaviour o))))
      (($ <compound>)
       (let ((statements
              (let loop ((statements (map (root-add-voidreply model) (ast:statement* o))))
                (if (null? statements) '()
                    (cons (car statements) (loop (cdr statements)))))))
         (if (=1 (length statements))
             (car statements)
             (clone o #:elements statements))))
      (($ <on>)
       (let* ((valued-triggers? (const (ast:typed? ((compose car ast:trigger*) o))))
              (modeling? (const (is-a? ((compose .event car ast:trigger*) o) <modeling-event>))))
         (let ((result ((root-add-voidreply model) (.statement o))))
           (match result
             (($ <blocking>)
              (clone o #:statement result))
             ;;FIXME: fixes silentoptional, breaks compliance_provides_out
             ;;((? modeling?) (clone o #:statement (make <compound> #:elements (list result))))
             ((and ($ <compound>) (= .elements (? null?)))
              (clone o #:statement (make <compound> #:elements (list (make <voidreply>)))))
             ((? valued-triggers?)
              (clone o #:statement (make <compound> #:elements (list result))))
             (_ (clone o #:statement (make <compound> #:elements (list result (make <voidreply>)))))))))
      ((? (is? <ast>)) (tree-map (root-add-voidreply model) o))
      (_ o))))

(define %count (make-parameter 0))
(define (tick-names o)
  (parameterize ((%count 0))
    ((tick-names- '()) o)))

(define ((tick-names- names) o)
  (define (append-tick o)
    (and o (let ((count (or (assoc-ref names o) 0)))
             (symbol-append o (string->symbol (string-append "'" (if (zero? count) "" (number->string count))))))))
  (match o
    (($ <root>) (let ((r (tree-map (tick-names- names) o)))
                  ;; (stderr "root:")
                  ;; (pretty-print (om->list r) (current-error-port))
                  r))
    (($ <behaviour>)
     (let ((names (map (cut cons <> 0) (map .name (ast:variable* o)))))
       (clone o
              #:variables ((compose (tick-names- names) .variables) o)
              #:functions ((compose (tick-names- names) .functions) o)
              #:statement ((compose (tick-names- names) .statement) o))))
    (($ <var>) (clone o #:variable ((compose append-tick .variable) o)))
    (($ <field-test>) (clone o #:variable ((compose append-tick .variable) o)))
    ;; (($ <scope-name>) (clone o #:scope (map append-tick (.scope o))
    ;;                          #:name (append-tick o)))
    ;; (($ <action>) (clone o #:port ((compose append-tick .port@) o)
    ;;                       #:event ((compose append-tick .event) o)))
    ;; (($ <event>) (clone o #:name ((compose append-tick .name) o)))
    ;; (($ <port>) (clone o #:name ((compose append-tick .name) o)))
    ;; (($ <trigger>) (clone o #:port ((compose append-tick .port@) o)
    ;;                       #:event ((compose append-tick .event) o)))
    ;; (($ <enum-literal>) (clone o #:field ((compose append-tick .field) o)))
    (($ <formal>) (clone o #:name ((compose append-tick .name) o)))
    (($ <function>)
     (let* ((signature (.signature o))
            (type ((compose (tick-names- names) .type) signature)))
       (receive (names formals)
           (let loop ((formals (ast:formal* signature)) (bumped '()) (names names))
             (define (bump-tick name)
               (%count (1+ (%count)))
               (acons name (%count) names))
             (if (null? formals) (values names bumped)
                 (let* ((formal (car formals))
                        (names (bump-tick (.name formal)))
                        (formal ((tick-names- names) formal)))
                   (loop (cdr formals) (append bumped (list formal)) names))))
         (clone o #:name ((compose append-tick .name) o)
                #:signature (clone signature #:type type #:formals (clone (.formals signature) #:elements formals))
                #:statement ((compose (tick-names- names) .statement) o)))))
    (($ <call>) (clone o
                       #:function ((compose append-tick .function@) o)
                       #:arguments ((compose (tick-names- names) .arguments) o)))
    (($ <assign>) (clone o #:variable ((compose append-tick .variable) o)
                         #:expression ((compose (tick-names- names) .expression) o)))
    (($ <variable>) (clone o #:name ((compose append-tick .name) o)
                           #:expression ((compose (tick-names- names) .expression) o)))
    (($ <compound>)
     (clone o
            #:elements
            (let loop ((statements (ast:statement* o)) (names names))
              (define (bump-tick name)
                (%count (1+ (%count)))
                (acons name (%count) names))
              (if (null? statements) '()
                  (let* ((statement (car statements))
                         (names (if (is-a? statement <variable>)
                                    (bump-tick (.name statement))
                                    names))
                         (statement ((tick-names- names) statement)))
                    (cons statement (loop (cdr statements) names)))))))
    ((? (is? <ast>)) (tree-map (tick-names- names) o))
    (_ o)))

(define (root-purge-data o)
  (match o
    (($ <action>)
     (clone o #:arguments (make <arguments>)))

    (($ <trigger>)
     (clone o #:formals (make <formals>)))

    ((? (is? <ast-list>))
     (clone o #:elements (filter-map root-purge-data (.elements o))))

    (($ <extern>) #f)
    (($ <assign>)
     (and (not (is-a? (.type (.variable o)) <extern>))
          (clone o #:expression (root-purge-data (.expression o)))))
    (($ <formal>) (and (not (is-a? (.type o) <extern>)) o))
    (($ <variable>) (and (not (is-a? (.type o) <extern>))
                         (clone o #:expression (root-purge-data (.expression o)))))

    (($ <var>) (and (not (is-a? ((compose .type .variable) o) <extern>))
                    o))

    ((and ($ <return>) (= .expression ($ <data-expr>))) (clone o #:expression #f))
    ((? (is? <ast>)) (tree-map root-purge-data o))
    (_ o)))

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

(define (root-> root) (root->mcrl2 root))

(define (root->sexp root)
  ((compose
    pretty-print
    postprocess
    om->list
    ) root))


(define (mcrl2:om root) ;; FIXME: already root/om
  ((compose
    (annotate-path '())
    flatten-compound
    ast-complete-elses
    ast-annotate-illegals
    ast-transform-event-ends
    transform-compounds
    flatten-compound
    ;;(lambda (o) (pretty-print (om->list o) (current-error-port)) o)
    root-purge-data
    (root-add-voidreply)
    ast-tail-calls
    ast-add-skips
    (expand-on)
    norm-state
    code-norm-event
    ;;(lambda (o) (pretty-print (om->list o) (current-error-port)) o)
    ) root))

;; (define (mcrl2:om ast)
;;   ((compose-root
;;     (annotate-path '())
;;     (lambda (o) ((compose pretty-print om->list) o) o)
;;     flatten-compound
;;     ast-complete-elses
;;     ast-annotate-illegals
;;     ast-transform-event-ends
;;     transform-compounds
;;     flatten-compound
;;     (root-purge-data)
;;     (root-add-voidreply)
;;     ast-tail-calls
;;     ast-add-skips
;;     aggregate-guard-g
;;     (expand-on)
;;     flatten-compound
;;     (prepend-true-guard)
;;     (aggregate-on norm:on-same-port-voidness-statement?)
;;     (expand-on norm:port-and-voidness-equal?)
;;     aggregate-guard-g
;;     flatten-compound
;;     combine-guards
;;     passdown-on
;;     flatten-compound
;;     (passdown-blocking)
;;     (remove-otherwise)
;;     om:models
;;     ast:resolve
;;     parse->om
;;     ) ast))

;;(use-modules (statprof))
(define (root->mcrl2 root)
  (let* ((module (make-module 31 `(,(resolve-module '(gaiag deprecated code))
                                   ,(resolve-module '(gaiag mcrl2)))))
         (model-name (and=> (command-line:get 'model #f) string->symbol))
         (model (or (and model-name
                         (find (om:named model-name) (ast:model* root)))
                    (find (is? <component>) (ast:model* root))
                    (find (is? <interface>) (ast:model* root)))))
;;    (stderr "model: ~a\n" model)
    (module-define! module 'root root)
    (parameterize ( ;;(this-module module)
                   (%model model)
                   (template-dir (string-append %template-dir "/mcrl2")))
      (x:pand 'source@root (module-ref module 'root) module)
      ;;      (statprof (lambda () (x:pand 'source@root (module-ref module 'root) module)) #:count-calls? #t)
      )))

(define (ast-> ast)
  (let* ((files (gdzn:command-line:get '() #f))
         (base (basename (car files) ".dzn"))
         (base (basename base ".scm"))
         (dir (command-line:get 'output #f))
         (file-name (string-append base ".mcrl2"))
         (file-name (cond ((equal? dir "-") dir)
			  (dir (string-append dir "/" file-name))
			  (else file-name)))
         (root ((compose ast:resolve tick-names parse->om) ast))
	 (root (mcrl2:om root))
         (ast? (command-line:get 'ast #f))
         (->mcrl2 (if ast? root->sexp
                      root->mcrl2)))
    (if (equal? file-name "-") (->mcrl2 root)
        (with-output-to-file file-name (cut ->mcrl2 root)))
    ""))

;;to be revisited
(define (om:extern model identifier)
  (as ((om:type model) identifier) <extern>))

(define (om:behaviour? o)
  (match o
    ((or ($ <component>) ($ <interface>)) (.behaviour o))
    (($ <behaviour>) o)
    (_ #f)))

(define-method (mcrl2:interface-name (o <ast>)) ((compose mcrl2:interface-name (cut parent <model> <>) .type) o))
(define-method (mcrl2:interface-name (o <mcrl2-interface>)) ((compose mcrl2:interface-name .interface) o))
(define-method (mcrl2:interface-name (o <interface>)) (mcrl2:scope-name o))

(define (mcrl2:ports o) (append (om:ports o) ((compose .elements .ports .behaviour) o)))
(define (mcrl2:interfaces o) (delete-duplicates (map .type (mcrl2:ports o))))
;;(define-method (mcrl2:provided-port-type (o <ast>)) ((compose mcrl2:provided-port-type car (lambda (o) (filter (is? <component>) (.elements o)))) o))
(define-method (mcrl2:provided-port-type (o <ast>)) ((compose mcrl2:provided-port-type (cut parent <model> <>)) o))
(define-method (mcrl2:provided-port-type (o <root>)) ((compose mcrl2:provided-port-type (lambda (o) (find (is? <component>) (.elements o)))) (parent <root> o)))
(define-method (mcrl2:provided-port-type (o <component>)) ((compose mcrl2:provided-port-type .type car om:provided) o)) ;;TODO: only works for single provides port
(define-method (mcrl2:provided-port-type (o <interface>)) (mcrl2:scope-name o))
(define-method (mcrl2:provided-port-name (o <event>)) ((compose mcrl2:provided-port-name .type .signature) o))
(define-method (mcrl2:provided-port-name (o <type>)) ((compose mcrl2:provided-port-name (lambda (o) (find (is? <component>) (.elements o))) (cut parent <root> <>)) o))
(define-method (mcrl2:provided-port-name (o <root>)) ((compose mcrl2:provided-port-name (lambda (o) (find (is? <component>) (.elements o)))) o))
(define-method (mcrl2:provided-port-name (o <component>)) ((compose .name car om:provided) o))
(define-method (mcrl2:provided-port-name (o <interface>)) (mcrl2:scope-name o))
(define-method (mcrl2:get-model (o <root>))
  (let ((component (filter (is? <component>) (.elements o))))
    (if (null? component)
        (car (filter (is? <interface>) (.elements o)))
        component)))
(define-template x:model mcrl2:get-model)
(define-template x:mcrl2-component-name (lambda (o) (mcrl2:model-name (car (filter (is? <component>) (.elements (parent <root> o)))))))
(define-template x:mcrl2-provided-port-type mcrl2:provided-port-type)
;;(define-template x:mcrl2-provided-port-name (lambda (o) (stderr "mcrl2-provided-port-name: ~a\n" o) (mcrl2:provided-port-name o)))
(define-template x:mcrl2-provided-port-name mcrl2:provided-port-name)
(define-template x:provided-port-type (lambda (o) (mcrl2:provided-port-type o)))
(define-template x:provided-port-name (lambda (o) (mcrl2:provided-port-name (parent <model> o))))
(define-template x:global-type om:globals 'newline-indent-infix)
(define-template x:sort-interface mcrl2:interfaces 'newline-indent-infix)
(define-template x:sort-component identity 'newline-indent-infix)
(define-template x:action-struct (lambda (o) (map
					      (lambda (x) (make <interface-event> #:interface o #:event x))
					      ((compose .elements .events) o))) 'pipe-infix)
(define-template x:interface-name mcrl2:interface-name)
(define-template x:interfaces-allow-dillegals mcrl2:interfaces 'newline-indent-infix)
(define-template x:map-interface-name mcrl2:interfaces 'newline-indent-infix)
(define-template x:eqn-interface-name mcrl2:interfaces 'newline-indent-infix)
(define-template x:eqn-allow-dillegals (lambda (o) (mcrl2:interfaces (car (filter (is? <component>) (.elements o))))) 'newline-indent-infix)
(define-template x:global-interface-reply mcrl2:interfaces 'newline-indent-infix)
(define-template x:interface-action-alphabet mcrl2:interfaces 'newline-indent-infix)
(define-template x:port-action-alphabet mcrl2:ports 'newline-indent-infix)
(define-template x:port-interface-name (compose mcrl2:model-name .type))
(define-template x:event-name (compose .name .event))
(define-template x:integers get-ints 'newline-indent-suffix)
(define-template x:enum-struct get-enums 'newline-indent-suffix)

(define-template x:mcrl2-reply-type mcrl2:reply-type)

(define-template x:mcrl2-model-name mcrl2:model-name)

(define-method (mcrl2:model-name (o <model>))
  ((om:scope-name (string->symbol "'")) o))
(define-method (mcrl2:model-name (o <ast>))
  (let ((model (or (parent <model> o)
                   (%model))))
    (mcrl2:scope-name model)))
(define-method (mcrl2:scope-name (o <ast>))
  (or (and=> (parent <model> o) mcrl2:model-name)
      "global'"))

(define-method (mcrl2:reply-type (o <reply>))
  (let ((expr (.expression o)))
    (match expr
      (($ <literal>) (if (number? (.value expr))
                         'Int
                         'Bool))
      ((? (is? <bool-expr>)) 'Bool)
      (($ <var>) ((compose mcrl2:expand-types .type .variable) expr))
      (($ <enum-literal>)  ((compose mcrl2:expand-types .type) expr))
      ((? (is? <int-expr>)) 'Int)
      (_ (mcrl2:expand-types (.type expr))))))

(define-method (mcrl2:reply-type (o <action>))
  ((compose mcrl2:expand-types .signature .event) o))

(define-method (mcrl2:reply-type (o <the-end>))
  ((compose mcrl2:expand-types .signature .event .trigger) o))

(define-template x:mcrl2-references-sort models-with-calls 'newline-infix <model>)

(define (models-with-calls o)
  (append-map
   (lambda (m)
     (if (pair? ((compose ast:function* .behaviour) m))
	 (list m)
	 '()))
   (append (mcrl2:interfaces o) (list o))))

(define-template x:references references 'pipe-infix)
(define-template x:resolve-reference references 'else-infix)
(define-template x:return-types typed-functions 'comma-suffix)
(define-template x:other-function-returns other-function-returns 'comma-infix)
(define-template x:init-return-value (compose .type .signature))
(define (other-function-returns o)
  (let* ((function (parent <function> o))
         (model (parent <model> function))
         (functions (typed-functions model))
         (functions (filter (lambda (f) (not (om:equal? f function))) functions)))
    functions))

(define (typed-functions o)
  (filter (lambda (f) (not (is-a? ((compose .type .signature) f) <void>))) ((compose ast:function* .behaviour) o)))

(define (references o)
  (let* ((variablebycalls ((om:collect (lambda (o) (and (is-a? o <variable>) (is-a? (.expression o) <call>)))) o))
         (assignbycalls ((om:collect (lambda (o) (and (is-a? o <assign>) (is-a? (.expression o) <call>)))) o))
         (callsinassigns (map .expression assignbycalls))
         (calls ((om:collect (lambda (o) (and (is-a? o <call>) (not (or (is-a? (.parent o) <assign>) (is-a? (.parent o) <variable>))) (not (.last? o))))) o)))
    (delete-duplicates (append variablebycalls assignbycalls calls) (lambda (a b) (eq? (.id (process-continuation a)) (.id (process-continuation b)))))))

(define-template x:valued-return
  (lambda (o)
    (or (.expression o) "")) #f <expression>)

(define-template x:valued-comma
  (lambda (o)
    (or (and (.expression o)
             (pair? (other-function-returns o))
             ",") "")) #f <expression>)

(define-template x:mcrl2-return-process
  (lambda (o)
    (let ((models (models-with-calls o)))
      (if (pair? models)
	  models
	  '()))) 'newline-infix <model>)

(define-template x:enum-field-struct
  (lambda (o) (map
	       (lambda (x) (clone (make <enum-name-field> #:name (.name.name o) #:field x) #:parent o))
	       ((compose .elements .fields) o))) 'pipe-infix)
(define-template x:reply-union-struct mcrl2:reply-types 'pipe-infix <type>)

(define-method (scope o) (let ((name (.scope (.name o))))
                           (if (null? name)
                               (list "global'")
                               (map symbol->string name))))
(define-method (scope (o <enum-name-field>)) (scope (.parent o)))
(define-method (scope (o <event>)) ((compose scope .type .signature) o))
(define-method (scope (o <reply>)) (scope (.type (.expression o))))
(define-template x:scope scope 'type-infix)
(define-template x:provided-port-reply-types om:provided)
(define-template x:mcrl2-reply-union-declaration identity)
(define-template x:event-type (compose .type .signature))
(define-template x:mcrl2-reply-types mcrl2:reply-types 'union-suffix <type>)
(define-method (mcrl2:reply-types (o <port>)) (mcrl2:reply-types (.type o)))
(define-method (mcrl2:reply-types (o <interface>))
  (let ((events (om:events o)))
    (delete-duplicates events (lambda (a b) (om:equal? ((compose .type .signature) a) ((compose .type .signature) b)))))
;;  (code:reply-types o #:pred (const #t))
  ;;TODO #:index ??
  ;; (let ((reply-types (code:reply-types o #:pred (const #t))))
  ;;   (map
  ;;    (lambda (x i) (make <interface-type> #:interface o #:type x #:index i))
  ;;    reply-types (iota (length reply-types))))
  )

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
;;  (const "")
  (lambda (o)
    (string-join (string-split (string-trim-right
        			(ast->dzn (or (and=> (as o <behaviour>) .statement) o)))
                               #\newline) "\n     % " 'prefix))
  )

(define-template x:mcrl2-interface-process
  (lambda (o)
    (match o
      (($ <component>) (mcrl2:interfaces o))
      (($ <interface>) (.behaviour o)))))

(define-template x:mcrl2-component-process .behaviour)

(define-method (mcrl2:expand-types (o <enum-literal>)) (.type o))
(define-method (mcrl2:expand-types (o <type>))
  o)

(define-method (mcrl2:expand-types o)
  (mcrl2:expand-types (.type o)))

(define-method (mcrl2:expand-types (o <call>))
  ((compose mcrl2:expand-types .signature .function) o))

(define-method (mcrl2:expand-types (o <action>))
  ((compose mcrl2:expand-types .signature .event) o))

(define-method (mcrl2:expand-types (o <event>))
  (mcrl2:expand-types ((compose .type .signature) o)))

(define-method (mcrl2:expand-types (o <function>))
  (mcrl2:expand-types ((compose .type .signature) o)))

(define-method (mcrl2:expand-types (o <assign>))
  (mcrl2:expand-types (.expression o)))

(define-method (mcrl2:expand-types (o <assign-action>))
  (mcrl2:expand-types ((compose .signature .event .action) o)))

(define-method (mcrl2:expand-types (o <variable-action>))
  (mcrl2:expand-types (.variable o)))

(define-template x:assign-call-var-name (compose .variable.name .assign))
(define-template x:variable-call-var-name (compose .name .variable))
(define-template x:mcrl2-type-name mcrl2:expand-types)
(define-template x:action-union-struct om:ports 'pipe-infix)

(define-template x:mcrl2-process-name identity #f <ast>)
(define-template x:function-name function-name)
(define-method (function-name (o <ast>))
  (let ((parent (parent <function> o)))
    (.name parent)))
(define-template x:function-scope function-scope)
(define-method (function-scope (o <ast>))
  (let ((parent (parent <function> o)))
    (if parent
        ((compose (cut string-append "'function'" <>) ->string .name) parent)
        ""))
 ;; (and=>  (lambda (f) ))
  ;; (let* ((result
  ;;         (match o
  ;;           (($ <function>)
  ;;            (let* ((name ((compose ->string .name) o))
  ;;                   (string (string-append "'function'" name)))
  ;;              string))
  ;;           (($ <behaviour>) "")
  ;;           (($ <root>) "")
  ;;           (_ ((compose function-scope .parent) o))))
  ;;        (foo (stderr "\nresult: <~a>\n" result)))
  ;;   result)
  )

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
	     (sid ((compose .id (cut parent <model> <>)) o))
             (path (ast:path o))
             (id (map .id path))
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
    (mcrl2:process-identifier (process-continuation o))))

(define-template x:mcrl2-type .type)
(define-method (mcrl2-type (o <type>))
  (match o
    (($ <bool>) "Bool")
    (($ <enum>) (string-join (map symbol->string (om:scope+name (.name o))) "'" 'infix))
    (($ <int>) "Int") ;;(string-join (map symbol->string (om:scope+name (.name o))) "'" 'infix)
    (($ <refs>) (string-append ((compose ->string mcrl2:scope-name (cut parent <model> <>)) o) "'" "Refs"))))

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
  (let* ((parent (parent <model> o))
	 (behaviour (.behaviour parent))
	 (vars ((compose .elements .variables) behaviour)))
    vars))

(define-method (locals (o <ast>))
  (let* ((vars (locals- o '())))
    vars))

(define-method (locals- (o <ast>) result)
  (if ((is? <behaviour>) o)
      result
      (let* ((parent (.parent o)))

	(cond ((is-a? parent <compound>) (let* ((pre (cdr (member o (reverse (.elements parent)) om:equal?)))
                                                (result (append result (filter (is? <variable>) pre))))
                                           (locals- parent result)))
	      ((is-a? o <function>) (append result ((compose .elements .formals .signature) o)
					    (list (clone (make <cont> #:type (clone (make <refs>) #:parent parent)) #:parent parent))))
	      (else (locals- parent result))))))

(define-template x:process-parameters identity #f <ast>)
(define-method (variables-in-scope (o <model>)) (globals o))
(define-method (variables-in-scope (o <ast>))
  (append (globals o) (locals o)))
(define-template x:variables-in-scope variables-in-scope 'comma-prefix)
(define-template x:variable-names-in-scope locals 'comma-prefix)

(define-template x:call-parameters call-parameters 'comma-suffix)
(define-method (call-parameters (o <call>))
  (append (map
           (lambda (f e) (make <call-parameter> #:name (.name f) #:expression e))
           ((compose .elements .formals .signature .function) o)
           ((compose .elements .arguments) o))))
(define-method (call-parameters (o <assign>))
  (call-parameters (.expression o)))
(define-method (call-parameters (o <variable>))
  (call-parameters (.expression o)))

(define-template x:cont-parameter
  (lambda (o) (make <cont-parameter> #:continuation (call-continuation o))))

(define (cont-locals o)
  (let* ((cont (process-continuation o))
	 (cont-locals (locals- cont '())))
    cont-locals))

(define-template x:process-continuation-parameters cont-locals 'param-list-grammar <variable>)

(define-method (call-continuation (o <call>))
  (if (.last? o)
      "cont"
      o))

(define-template x:next-call-context cont-locals 'param-list-grammar <variable>)
(define-template x:init-locals-from-cont cont-locals 'comma-infix <variable>)

(define-template x:call-continuation .continuation)

(define-method (model-from-scope (o <root>)) ((compose car (lambda (o) (filter (is? <component>) (.elements o)))) o))
(define-method (model-from-scope (o <port>)) (.type o))
(define-method (model-from-scope (o <model>)) o)

(define-template x:globals-init model-from-scope #f <model>)
(define-template x:global-vars-init globals-from-scope 'comma-prefix)

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
    (if (and (is-a? (parent <model> o) <component>) (ast:requires? (.port o)))
	o
	"")))

(define-template x:on-event-union .elements 'union-infix)
(define-template x:on-event-process .elements)
(define-template x:on-trigger separate-trigger-type)
(define-template x:the-end-trigger separate-trigger-type)
(define (separate-trigger-type o)
  (let ((model (parent <model> o)))
   (match (mcrl2:on-event-trigger o)
     ('optional (clone (make <optional>) #:parent model))
     ('inevitable (clone (make <inevitable>) #:parent model))
     (_ o))))
(define-template x:on-event-trigger mcrl2:on-event-trigger)
(define (mcrl2:on-event-trigger o)
  (match o
    (($ <on>) ((compose .event.name car .elements .triggers) o))
    (($ <action>) (.event.name o))
    (($ <the-end>) ((compose .event.name .trigger) o))
    (($ <illegal>) (.event o))))
(define-template x:trigger-port trigger-port)
(define-method (port p o)
  (if p
      (.name p)
      (mcrl2:model-name (parent <model> o))))
(define-method (trigger-port (o <ast>))
  (match o
    (($ <action>) (port (.port o) o))
    (($ <the-end>) ((compose (cut port <> o) .port .trigger) o))
    (($ <on>) ((compose (cut port <> o) .port car .elements .triggers) o))
    (($ <variable>) ((compose trigger-port .expression) o))
    (($ <assign>) ((compose trigger-port .expression) o))))

(define-template x:trigger-port-type trigger-port-type)
(define-method (port-type p o)
  (if p
      (mcrl2:model-name (.type p))
      (mcrl2:model-name (parent <model> o))))
(define-method (trigger-port-type (o <ast>))
  (match o
    (($ <action>) (port-type (.port o) o))
    (($ <the-end>) ((compose (cut port-type <> o) .port .trigger) o))
    (($ <on>) ((compose (cut port-type <> o) .port car .elements .triggers) o))
    (($ <variable>) ((compose trigger-port-type .expression) o))
    (($ <assign>) ((compose trigger-port-type .expression) o))))

(define-template x:trigger-port-type-reply trigger-port-type-reply)
(define-method (trigger-port-type-reply (o <the-end>))
  (let* ((trigger (.trigger o))
	 (port (.port trigger)))
    (if port
	(if (ast:provides? port)
	    (om:name (.type port))
	    port)
	(om:name (parent <model> o)))))
(define-method (trigger-port-type-reply (o <action>))
  (let ((port (.port o)))
    (if (ast:provides? port)
	(om:name (.type port))
	port)))
(define-method (trigger-port-type-reply (o <assign-action>))
  ((compose trigger-port-type-reply .action) o))
(define-method (trigger-port-type-reply (o <variable-action>))
  ((compose trigger-port-type-reply .action) o))

(define-template x:required-port-the-end required-port-the-end)
(define-method (required-port-the-end (o <the-end>))
  (let* ((trigger (.trigger o))
         (port (.port trigger)))
    (if port (if (ast:requires? port)
                 (mcrl2:init-reply-value (.type port))
                 "")
        "")))

(define-method (illegal-or-dillegal (o <ast>))
  (let* ((parent (.parent o)))
    (match parent
      (($ <on>)
       (let ((port ((compose .port car .elements .triggers) parent)))
         (if port
             (if (ast:requires? port)
                 "Illegal"
                 "Dillegal")
             "Dillegal")))
      (($ <if>) "Illegal")
      (_ (illegal-or-dillegal parent)))))

(define-template x:block-illegals mcrl2:block-illegals)
(define-method (mcrl2:block-illegals (o <on>))
  (let* ((port ((compose .port car .elements .triggers) o))
         (statement ((compose car .elements .statement) o))
         (parent (parent <model> o)))
    (if (or (and port (ast:provides? port) (is-a? statement <illegal>))
            (and (is-a? parent <interface>) (is-a? statement <illegal>)))
        o
        "")))

(define-template x:illegal-type
  (lambda (o)
    (if ((is? <interface>) (parent <model> o))
	"Illegal"
	(illegal-or-dillegal o))))

(define-template x:mcrl2-constrained-behaviour identity)
(define-template x:mcrl2-optional-unconstrained identity)
(define-template x:mcrl2-optional-constrained identity)
(define-template x:mcrl2-run2completion identity)
(define-template x:mcrl2-implementation identity)


(define-template x:mcrl2-component-queues identity)
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

(define-template x:assign-by-call? assign-by-call?)
(define-method (assign-by-call? (o <assign>))
  (let ((e (.expression o)))
    (if (is-a? e <call>)
        o
        "")))
(define-template x:assign-by-action? assign-by-action?)
(define-method (assign-by-action? (o <assign>))
  (let ((e (.expression o)))
    (if (is-a? e <action>)
        o
        "")))

(define-template x:var-decl-by-call? var-decl-by-call?)
(define-method (var-decl-by-call? (o <variable>))
  (let ((e (.expression o)))
    (if (is-a? e <call>)
        o
        "")))
(define-template x:var-decl-by-action? var-decl-by-action?)
(define-method (var-decl-by-action? (o <variable>))
  (let ((e (.expression o)))
    (if (is-a? e <action>)
        o
        "")))
(define-template x:variable-expression .expression)
(define-template x:assign-expression .expression)


(define-template x:assign-function-name (compose .function.name .call))
(define-template x:assign-action-name (compose .name .event .expression))
(define-template x:var-action-name (compose .name .event .expression))
(define-template x:call-function-name (compose .function.name .expression))
(define-template x:action-type action-type)
(define-method (action-type (o <ast>))
  ((compose mcrl2-type .type .signature .event .action) o))

(define-template x:check-range-error mcrl2:range-error)

(define-method (mcrl2:range-error (o <behaviour>))
  (filter (lambda (o) (is-a? (.type o) <int>)) ((compose  .elements .variables) o)))

(define-method (mcrl2:range-error (o <variable>))
  (if (is-a? (.type o) <int>)
      o
      ""))

(define-method (mcrl2:range-error (o <assign>))
  (if (is-a? (.type (.variable o)) <int>)
      o
      ""))

(define-template x:check-integer-bounds check-integer-bounds)
(define-method (check-integer-bounds (o <ast>))
  (let* ((action ((compose .expression) o))
         (type ((compose .type .signature .event) action)))
    (if (is-a? type <int>)
        type
        "")))
(define-template x:range-from mcrl2:range-from)
(define-method (mcrl2:range-from (o <variable>))
  (mcrl2:range-from (.type o)))
(define-method (mcrl2:range-from (o <assign>))
  (mcrl2:range-from (.variable o)))
(define-method (mcrl2:range-from (o <int>))
  ((compose ->string .from .range) o))
(define-template x:range-to mcrl2:range-to)
(define-method (mcrl2:range-to (o <assign>))
  (mcrl2:range-to (.variable o)))
(define-method (mcrl2:range-to (o <variable>))
  (mcrl2:range-to (.type o)))
(define-method (mcrl2:range-to (o <int>))
  ((compose ->string .to .range) o))

(define-method (dzn-type (o <call>))
 ((compose mcrl2-type dzn-type .function) o))
(define-method (dzn:expression (o <call-parameter>))
  (.expression o))

(define-template x:mcrl2-enum-literal mcrl2:enum-literal)

(define-method (mcrl2:enum-literal (o <enum-literal>))
  (string-append ((compose ->string .scope .name .type) o) "'" ((compose ->string .name .name .type) o) "'" ((compose ->string .field) o)))

(define-template x:next-process-parameters process-continuation #f <statement>)

(define-template x:variable-in-scope? mcrl2:variable-in-scope?)
(define-template x:assign-in-scope? mcrl2:variable-in-scope?)
(define-method (mcrl2:variable-in-scope? (o <assign>))
  (let* ((cont (process-continuation o))
         (cont-scope (variables-in-scope cont)))
    (if (member (.variable o) cont-scope (lambda (a b) (eq? (.id a) (.id b))))
        o
        "")))
(define-method (mcrl2:variable-in-scope? (o <variable>))
  (let* ((cont (process-continuation o))
         (cont-scope (variables-in-scope cont)))
    (if (member o cont-scope (lambda (a b) (eq? (.id a) (.id b))))
        o
        "")))

(define-method (process-continuation (o <ast>))
  (let* ((parent (.parent o)))
    (match parent
      (($ <behaviour>) parent)
      (($ <compound>) (let ((cont (cdr (member o (.elements parent) (lambda (a b) (eq? (.node a) (.node b)))))))
			(if (pair? cont)
			    (car cont)
			    (process-continuation parent))))
      (_ (process-continuation parent)))))

(define-method (first-process (o <ast>))
  (let loop ((process o))
    (if (or (not (is-a? process <compound>))
            (null? (.elements process)))
	 process
	 (loop ((compose car .elements) process)))))

(define-method (mcrl2:value (o <expression>))
  (match o
    (($ <enum-literal>) (mcrl2:enum-literal o))
    (($ <literal>) (.value o))))

(define-method (globals-from-scope scope)
  (let* ((behaviour (.behaviour scope))
	 (vars ((compose .elements .variables) behaviour)))
    vars))

(define-template x:init-type-value .type)
(define-template x:mcrl2-init-reply-value mcrl2:init-reply-value)
(define-template x:initial-enum-field (compose car .elements .fields))

(define-method (mcrl2:init-reply-value (o <ast>))
  (let ((reply-type (car (code:reply-types o #:pred (const #t)))))
    reply-type))

(define-method (mcrl2:init-reply-value (o <port>))
  (mcrl2:init-reply-value (.type o)))

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
(define-method (mcrl2:statement-process (o <call>)) o)
(define-method (mcrl2:statement-process (o <action>)) o)
(define-method (mcrl2:statement-process (o <reply>)) o)
(define-method (mcrl2:child-identifier (o <behaviour>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <function>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <guard>)) (mcrl2:process-identifier (.statement o)))
(define-method (mcrl2:child-identifier (o <on>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <if>)) (mcrl2:process-identifier (first-process (.then o))))
