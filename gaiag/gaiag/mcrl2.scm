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

  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)
  #:use-module (gaiag config)
  #:use-module (gaiag command-line)
  #:use-module (gaiag compare)
  #:use-module (gaiag code)
  #:use-module (gaiag csp)
  #:use-module (gaiag dzn)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-event)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag resolve)
  #:use-module (gaiag templates)

  #:export (mcrl2:om
            tick-names
	    root->
            globals-from-scope))

(define %model (make-parameter '***%model-not-set***))
(define-ast <mcrl2-interface> (<ast>)
  (interface))
(define-ast <interface-index> (<mcrl2-interface>)
  (index))
(define-ast <interface-event> (<mcrl2-interface>)
  (event))
(define-ast <enum-name-field> (<ast>)
  (name)
  (field))
(define-ast <refs> (<type>))
(define-ast <cont> (<type>)
  (name #:init-value "cont")
  (refs #:init-value (make <refs>)))
(define-ast <call-parameter> (<ast>)
  (name)
  (expression))
(define-ast <cont-parameter> (<ast>)
  (name #:init-value "cont")
  (continuation))
(define-ast <assign-call> (<ast>)
  (assign)
  (call))
(define-ast <assign-action> (<ast>)
  (assign)
  (action))
(define-ast <variable-call> (<ast>)
  (variable)
  (call))
(define-ast <variable-action> (<ast>)
  (variable)
  (action))

(define-method (mcrl2-type (o <ast>)) (.type o))
(define-method (mcrl2-type (o <cont>)) (.refs o))

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
    ((and ($ <function>) (= .statement statement)) (clone o #:statement (ast-add-skips statement)))
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
    (($ <illegal>) (make <illegal> #:event trigger #:incomplete (.incomplete o)))
    (_ o)))

(define (fix-empty-interface-behaviour o)
  (match o
    (($ <component>) o)
    ((and ($ <interface>) (= ast:event* (? (cut find ast:in? <>)))) o)
    ((and ($ <behaviour>) (= .statement (? (lambda (compound) (null? (.elements compound))))))
     (let* ((triggers (make <triggers> #:elements (list (make <trigger> #:event ast:inevitable))))
            (on (make <on> #:triggers triggers #:statement (make <illegal>)))
            (guard (make <guard> #:expression (make <literal> #:value 'false) #:statement on))
            (statement (make <compound> #:elements (list guard))))
       (clone o #:statement statement)))
    ((? (is? <ast>)) (tree-map fix-empty-interface-behaviour o))
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
      (($ <behaviour>)
       (let* ((statement ((root-add-voidreply model) (.statement o)))
              (statement (if (is-a? statement <compound>) statement
                             (make <compound> #:elements (list statement)))))
         (clone o #:statement statement)))
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
              (modeling? (const (is-a? ((compose .event car ast:trigger*) o) <modeling-event>)))
              (port ((compose .port car ast:trigger*) o)))
         (let ((result ((root-add-voidreply model) (.statement o))))
           (match result
             (($ <blocking>)
              (clone o #:statement result))
             ((? modeling?) (clone o #:statement (make <compound> #:elements (list result))))
             ((and ($ <compound>) (= .elements (? null?)))
              (clone o #:statement (make <compound> #:elements (list (make <voidreply>)))))
             ((? valued-triggers?)
              (clone o #:statement (make <compound> #:elements (list result))))
             ((? (const (and port (ast:requires? port))))
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
    (($ <root>) (tree-map (tick-names- names) o))
    (($ <behaviour>)
     (let* ((names (map (cut cons <> 0) (map .name (ast:variable* o))))
            (o (clone o
               #:variables ((compose (tick-names- names) .variables) o)))
            (o (clone o
               #:functions ((compose (tick-names- names) .functions) o)))
            (o (clone o
               #:statement ((compose (tick-names- names) .statement) o))))
       o))
    (($ <var>) (clone o #:variable.name ((compose append-tick .variable.name) o)))
    (($ <field-test>) (clone o #:variable.name ((compose append-tick .variable.name) o)))
    (($ <formal>) (clone o #:name ((compose append-tick .name) o)))
    (($ <formal-binding>) (clone o
                                 #:name ((compose append-tick .name) o)
                                 #:variable.name ((compose append-tick .variable.name) o)))
    (($ <function>)
     (let* ((signature (.signature o))
            (type ((compose (tick-names- names) .type.name) signature)))
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
                #:signature (clone signature #:type.name type #:formals (clone (.formals signature) #:elements formals))
                #:statement ((compose (tick-names- names) .statement) o)))))
    (($ <call>) (clone o
                       #:function.name ((compose append-tick .function.name) o)
                       #:arguments ((compose (tick-names- names) .arguments) o)))
    (($ <assign>) (clone o #:variable.name ((compose append-tick .variable.name) o)
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

(define-method (is-data? (o <ast>))
  (or (is-a? o <data>) (and (is-a? o <var>) (is-a? ((compose .type .variable) o) <extern>))))

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
    (($ <call>) (clone o #:arguments (make <arguments> #:elements (filter (negate is-data?) (ast:argument* o)))))
    (($ <variable>) (and (not (is-a? (.type o) <extern>))
                         (clone o #:expression (root-purge-data (.expression o)))))

    (($ <var>) (and (not (is-a? ((compose .type .variable) o) <extern>))
                    o))

    ((and ($ <return>) (= .expression ($ <data-expr>))) (clone o #:expression #f))
    ((? (is? <ast>)) (tree-map root-purge-data o))
    (_ o)))

(define (om:models o)
  (clone o #:elements (filter (conjoin (is? <model>) om:behaviour?) (.elements o))))

(define (root-> root) (root->mcrl2 root))

(define (root->sexp root)
  ((compose
    pretty-print
    om->list
    ) root))

(define (mcrl2:om root) ;; FIXME: already root/om
  ((compose
    ;;    (lambda (o) (pretty-print (om->list o) (current-error-port)) o)
    flatten-compound
    ast-complete-elses
    ast-annotate-illegals
    ast-transform-event-ends
    transform-compounds
    flatten-compound
    root-purge-data
    (root-add-voidreply)
    ast-tail-calls
    ast-add-skips
    (expand-on)
    norm-state
    code-norm-event
    fix-empty-interface-behaviour
    ) root))

;;(use-modules (statprof))
(define (root->mcrl2 root)
  (let* ((model-name (and=> (command-line:get 'model #f) string->symbol))
         (model (or (and model-name
                         (find (om:named model-name) (ast:model* root)))
                    (find (is? <component>) (ast:model* root))
                    (find (is? <interface>) (ast:model* root)))))
;;    (stderr "model: ~a\n" model)
    (parameterize ((%model model))
            (x:source root)
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

(define-method (mcrl2:reply-expression (o <reply>))
  (let* ((e (.expression o))
         (t (ast:expression-type e)))
    (if (is-a? t <void>)
        o
        e)))

(define-method (mcrl2:model-name (o <model>))
  ((om:scope-name (string->symbol "'")) o))
(define-method (mcrl2:model-name (o <ast>))
  (let ((model (or (parent <model> o)
                   (%model))))
    (mcrl2:scope-name model)))

;; (define (mcrl2:model-name- o)
;;   ((om:scope-name (string->symbol "'")) o))

;; (use-modules (ice-9 poe))
;; (define mcrl2:model-name- (pure-funcq mcrl2:model-name-))

;; (define (mcrl2:model-name o)
;;   (and=> (or (parent <model> o) (%model)) mcrl2:model-name-))

;; (define (mcrl2:parent- model o) (or (parent <model> o) model))
;; (define mcrl2:parent- (pure-funcq mcrl2:parent-))

;; (define (mcrl2:model-name o)
;;   (and=> (or (mcrl2:parent- (%model) o)) mcrl2:model-name-))

(define-method (mcrl2:scope-name (o <ast>))
  (or (and=> (parent <model> o) mcrl2:model-name)
      "global'"))

;; (define (mcrl2:scope-name o)
;;   (or (and=> (parent <model> o) mcrl2:model-name)
;;       "global'"))

;; (define mcrl2:scope-name (pure-funcq mcrl2:scope-name))

(define-method (mcrl2:reply-type (o <reply>))
  (let ((expr (.expression o)))
    (ast:expression-type expr)))

(define-method (mcrl2:reply-type (o <action>))
  ((compose mcrl2:expand-types .signature .event) o))

(define-method (mcrl2:reply-type (o <the-end>))
  ((compose mcrl2:expand-types .signature .event .trigger) o))

(define (other-function-returns o)
  (let* ((function (parent <function> o))
         (model (parent <model> function))
         (functions (typed-functions model))
         (functions (filter (lambda (f) (not (om:equal? f function))) functions)))
    functions))

(define (typed-functions o)
  (filter (lambda (f) (not (is-a? ((compose .type .signature) f) <void>))) ((compose ast:function* .behaviour) o)))


(define (equal-continuation a b)
  (string=? (mcrl2:process-identifier (process-continuation a))
            (mcrl2:process-identifier (process-continuation b))))

(define (models-with-calls o)
  (append-map
   (lambda (m)
     (if (pair? ((om:collect (is? <call>)) ((compose .statement .behaviour) m)))
	 (list m)
	 '()))
   (append (mcrl2:interfaces o) (list o))))

(define (all-referenced-calls o)
  (let ((calls ((om:collect (is? <call>)) (.statement o)))
        (mutual-calls ((om:collect (is? <call>)) (.functions o))))
    (if (null? calls) '()
        (append calls mutual-calls))))

(define (all-referenced-functions o)
  (delete-duplicates (map .function (all-referenced-calls o))))

(define (references o)
  (let ((calls (delete-duplicates (all-referenced-calls (.behaviour o)) equal-continuation)))
    (if (null? calls) o
        calls)))


(define (step refs result)
  (let loop ((refs refs) (result result))
    (if (null? refs) result
        (let* ((ref (car refs))
               (function? (parent <function> ref)))
          (if function? (if (member function? (map .function result)) (loop (cdr refs) (cons ref result))
                            (loop refs result))
              (loop (cdr refs) (cons ref result)))))))

(define (ref-function ref)
  (match ref
    (($ <variable>) ((compose .function .expression) ref))
    (($ <assign>) ((compose .function .expression) ref))
    (($ <call>) (.function ref))))

(define (reachable refs)
  (receive (refs result) (partition (cut parent <function> <>) refs)
    (let loop ((refs refs) (result result))
      (receive (a b) (partition (lambda (ref) (member (.id (parent <function> ref)) (map (compose .id ref-function) result))) refs)
        (let* ((result2 (append a result)))
          (if (equal? result result2) result
              (loop b result2)))))))


(define (references o)
  (let* ((variablebycalls ((om:collect (lambda (o) (and (is-a? o <variable>) (is-a? (.expression o) <call>)))) o))
         (assignbycalls ((om:collect (lambda (o) (and (is-a? o <assign>) (is-a? (.expression o) <call>)))) o))
         (callsinassigns (map .expression assignbycalls))
         (calls ((om:collect (lambda (o) (and (is-a? o <call>) (not (or (is-a? (.parent o) <assign>) (is-a? (.parent o) <variable>))) (not (.last? o))))) o))
         (refs (reachable (delete-duplicates (append variablebycalls assignbycalls callsinassigns calls) equal-continuation))))
    (if (pair? refs)
        refs
        o)))

(define-method (scope o) (let ((name (.scope (.name o))))
                           (if (null? name)
                               (list "global'")
                               (map symbol->string name))))
(define-method (scope (o <enum-name-field>)) (scope (.parent o)))
(define-method (scope (o <event>)) ((compose scope .type .signature) o))
(define-method (scope (o <reply>)) (scope (.type (.expression o))))
(define-method (mcrl2:reply-types (o <port>)) (mcrl2:reply-types (.type o)))
(define-method (mcrl2:reply-types (o <interface>))
  (let ((events (om:events o)))
    (delete-duplicates events (lambda (a b) (om:equal? ((compose .type .signature) a) ((compose .type .signature) b)))))
;;  (code:reply-types o #:pred (const #t))
  ;;TODO #:index ??
  ;; (let ((reply-types (code:reply-types o #:pred (const #t))))
  ;;   (map
  ;;    (lambda (x i) (make <interface-type> #:interface o #:type.name x #:index i))
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

(define-method (function-name (o <ast>))
  (let ((parent (parent <function> o)))
    (.name parent)))
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
					    (list (clone (make <cont> #:refs (clone (make <refs>) #:parent parent)) #:parent parent))))
	      (else (locals- parent result))))))

(define-method (variables-in-scope (o <model>)) (globals o))
(define-method (variables-in-scope (o <ast>)) (append (globals o) (locals o)))

(define-method (call-parameters (o <call>))
  (append (map
           (lambda (f e) (make <call-parameter> #:name (.name f) #:expression e))
           ((compose .elements .formals .signature .function) o)
           ((compose .elements .arguments) o))))
(define-method (call-parameters (o <assign>))
  (call-parameters (.expression o)))
(define-method (call-parameters (o <variable>))
  (call-parameters (.expression o)))

(define (cont-locals o)
  (let* ((cont (process-continuation o))
	 (cont-locals (locals- cont '())))
    cont-locals))

(define-method (call-continuation (o <call>))
  (if (.last? o)
      "cont"
      o))

(define-method (model-from-scope (o <root>)) ((compose car (lambda (o) (filter (is? <component>) (.elements o)))) o))
(define-method (model-from-scope (o <port>)) (.type o))
(define-method (model-from-scope (o <model>)) o)

(define-method (on-from-provided (o <the-end>))
  (let* ((on (parent <on> o))
         (port ((compose .port car ast:trigger*) on)))
    (if (or (not port) (ast:provides? port))
        o
        "")))
(define-method (on-from-required (o <the-end>))
  (let* ((on (parent <on> o))
         (port ((compose .port car ast:trigger*) on)))
    (if (and port (ast:requires? port))
        o
        "")))
(define (trigger-expected-reply? o)
  (let ((event ((compose .event car ast:trigger*) o))
        (port ((compose .port car ast:trigger*) o)))
    (not (or (is-a? event <modeling-event>) (and port (ast:requires? port))))))
(define (trigger-expected-reply o)
  (if (trigger-expected-reply? o)
      o
      ""))
(define (trigger-no-expected-reply o)
  (if (trigger-expected-reply? o)
      ""
      o))
(define (separate-trigger-type o)
  (let ((model (parent <model> o)))
   (match (mcrl2:on-event-trigger o)
     ('optional (clone (make <optional>) #:parent model))
     ('inevitable (clone (make <inevitable>) #:parent model))
     (_ o))))
(define (mcrl2:on-event-trigger o)
  (match o
    (($ <on>) ((compose .event.name car .elements .triggers) o))
    (($ <action>) (.event.name o))
    (($ <the-end>) ((compose .event.name .trigger) o))
    (($ <illegal>) (.event o))))
(define (mcrl2:on-event-trigger-dir o)
  (match o
    (($ <on>) ((compose .direction .event car .elements .triggers) o))
    (($ <action>) ((compose .direction .event) o))
    (($ <the-end>) ((compose .direction .event .trigger) o))
    (($ <illegal>) (.event o))))
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

(define-method (mcrl2:block-illegals (o <on>))
  (let* ((port ((compose .port car .elements .triggers) o))
         (statement ((compose car .elements .statement) o))
         (parent (parent <model> o)))
    (if (or (and port (ast:provides? port) (is-a? statement <illegal>))
            (and (is-a? parent <interface>) (is-a? statement <illegal>) (not (.incomplete statement))))
        o
        "")))

(define-method (required-ports-with-out (o <component>))
  (let ((required-ports (om:required o)))
    (filter
     (lambda (p) (not (null? (filter om:out? ((compose .elements .events .type) p)))))
     required-ports)))
(define-method (normal-assign? o)
  (let ((e (.expression o)))
    (if (not (or (is-a? e <call>) (is-a? e <action>)))
        o
        "")))
(define-method (assign-by-call? (o <assign>))
  (let ((e (.expression o)))
    (if (is-a? e <call>)
        o
        "")))
(define-method (assign-by-action? (o <assign>))
  (let ((e (.expression o)))
    (if (is-a? e <action>)
        o
        "")))

(define-method (var-decl-by-call? (o <variable>))
  (let ((e (.expression o)))
    (if (is-a? e <call>)
        o
        "")))
(define-method (var-decl-by-action? (o <variable>))
  (let ((e (.expression o)))
    (if (is-a? e <action>)
        o
        "")))

(define-method (action-type (o <ast>))
  ((compose mcrl2-type .type .signature .event .action) o))

(define-method (mcrl2:range-error (o <behaviour>))
  (filter (lambda (o) (is-a? (.type o) <int>)) (ast:variable* o)))

(define-method (mcrl2:range-error (o <function>))
  (filter (lambda (o) (is-a? (.type o) <int>)) ((compose ast:formal* .signature) o)))
(define-method (mcrl2:range-error (o <event>))
  (if (is-a? (.type (.signature o)) <int>)
      o
      ""))

(define-method (mcrl2:range-error (o <variable>))
  (if (is-a? (.type o) <int>)
      o
      ""))

(define-method (mcrl2:range-error (o <assign>))
  (if (is-a? (.type (.variable o)) <int>)
      o
      ""))

(define-method (constrain-action-range (o <assign>))
  (constrain-action-range (.expression o)))
(define-method (constrain-action-range (o <variable>))
  (constrain-action-range (.expression o)))
(define-method (constrain-action-range (o <action>))
  (let ((type ((compose .type .signature .event) o)))
    (if (is-a? type <int>)
        type
        "")))

(define-method (check-integer-bounds (o <assign>))
  (let ((type ((compose .type .variable) o)))
    (if (is-a? type <int>)
        type
        "")))
(define-method (check-integer-bounds (o <variable>))
  (check-integer-bounds (.expression o)))
(define-method (check-integer-bounds (o <action>))
  (check-integer-bounds (.event o)))
(define-method (check-integer-bounds (o <event>))
  (let ((type ((compose .type .signature) o)))
    (if (is-a? type <int>)
        type
        "")))
(define-method (mcrl2:range-from (o <formal>))
  (mcrl2:range-from (.type o)))
(define-method (mcrl2:range-from (o <event>))
  (mcrl2:range-from (.type (.signature o))))
(define-method (mcrl2:range-from (o <variable>))
  (mcrl2:range-from (.type o)))
(define-method (mcrl2:range-from (o <assign>))
  (mcrl2:range-from (.variable o)))
(define-method (mcrl2:range-from (o <int>))
  ((compose ->string .from .range) o))
(define-method (mcrl2:range-to (o <event>))
  (mcrl2:range-to (.type (.signature o))))
(define-method (mcrl2:range-to (o <assign>))
  (mcrl2:range-to (.variable o)))
(define-method (mcrl2:range-to (o <formal>))
  (mcrl2:range-to (.type o)))
(define-method (mcrl2:range-to (o <variable>))
  (mcrl2:range-to (.type o)))
(define-method (mcrl2:range-to (o <int>))
  ((compose ->string .to .range) o))

(define-method (dzn-type (o <call>))
 ((compose mcrl2-type dzn-type .function) o))
(define-method (dzn:expression (o <call-parameter>))
  (.expression o))

(define-method (mcrl2:enum-literal (o <enum-literal>))
  (string-append ((compose ->string .scope .name .type) o) "'" ((compose ->string .name .name .type) o) "'" ((compose ->string .field) o)))

(define-method (mcrl2:variable-in-scope? (o <assign>))
  (let* ((cont (process-continuation o))
         (cont-scope (variables-in-scope cont)))
    (if (member (.variable o) cont-scope (lambda (a b) (eq? (.name a) (.name b)))) ;; FIXME: fix resolving: too many <variable> clones made!!
        o
        "")))
(define-method (mcrl2:variable-in-scope? (o <variable>))
  (let* ((cont (process-continuation o))
         (cont-scope (variables-in-scope cont)))
    (if (member o cont-scope (lambda (a b) (eq? (.name a) (.name b)))) ;; FIXME: fix resolving: too many <variable> clones made!!
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
(define-method (mcrl2:statement-process (o <return>)) o)
(define-method (mcrl2:child-identifier (o <behaviour>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <function>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <guard>)) (mcrl2:process-identifier (.statement o)))
(define-method (mcrl2:child-identifier (o <on>)) (mcrl2:process-identifier (first-process (.statement o))))
(define-method (mcrl2:child-identifier (o <if>)) (mcrl2:process-identifier (first-process (.then o))))

(define-templates-macro define-templates mcrl2)
(include "../templates/dzn.scm")
(include "../templates/code.scm")
(include "../templates/mcrl2.scm")
