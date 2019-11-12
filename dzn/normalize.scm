;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (dzn normalize)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn command-line)
  #:use-module (dzn misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn display)

  #:use-module (dzn ast)

  #:export (root->
            triples:state-traversal
            triples:event-traversal
            triples:->compound-guard-on
            triples:->triples
            triples:add-illegals
            triples:mark-the-end
            triples:compound->triples
            triples:fix-empty-interface
            triples:on-compound
            triples:split-multiple-on

            add-reply-port
            binding-into-blocking
            purge-data
            remove-otherwise
            ))

(define (t-triple on guard blocking statement) (list on guard blocking statement))
(define (t-on triple) (first triple))
(define (t-guard triple) (second triple))
(define (t-blocking triple) (third triple))
(define (t-statement triple) (fourth triple))


(define (triples:->compound-guard-on triples)
  (let* ((st (map (lambda (t)
                    (let* ((on (t-on t))
                           (guard (t-guard t))
                           (statement (t-statement t))
                           (blocking (t-blocking t))
                           (statement (if blocking (clone blocking #:statement statement)
                                          statement)))
                      (clone guard #:statement (clone on #:statement statement))))
                  triples)))
    (make <declarative-compound> #:elements st)))

(define (declarative-illegal? o)
    (match o
      (($ <illegal>) o)
      (($ <declarative-illegal>) o)
      ((and ($ <compound>) (= ast:statement* (? null?))) #f)
      (($ <compound>) (declarative-illegal? ((compose car ast:statement*) o)))
      (_ #f)))

(define ((triples:fix-empty-interface model) triples)
  (if (and (is-a? model <interface>) (null? triples))
      (let* ((on (make <on> #:triggers (make <triggers> #:elements (list (make <trigger> #:event.name "inevitable")))))
             (guard (make <guard> #:expression (make <literal> #:value "false")))
             (statement (make <compound> #:elements (list (make <illegal>)))))
        (list (t-triple on guard #f statement)))
      triples))

(define (trigger-equal? a b)
  (and (equal? (.port.name a) (.port.name b))
       (equal? (.event.name a) (.event.name b))))

(define (combine-not guards)
  (cond ((null? guards) (make <guard> #:expression (make <literal> #:value "true")))
	((= 1 (length guards)) (make <guard>
				 #:expression (make <not>
						#:expression (.expression (car guards)))))
	(else (make <guard> #:expression (reduce (lambda (elem prev)
						   (make <and> #:left elem #:right prev))
					    (make <literal> #:value "true")
					    (map (compose (cut make <not> #:expression <>) .expression) guards))))))

(define (add-illegals model triples trigger)
  (let* ((triples (filter (lambda (t) (trigger-equal? ((compose car ast:trigger* t-on) t) trigger)) triples))
         (on (clone (make <on> #:triggers (make <triggers> #:elements (list trigger))) #:parent (.parent trigger)))
         (guard (combine-not (map t-guard triples)))
         (provides? (and=> (.port trigger) ast:provides?))
         (statement (make (cond (provides? <declarative-illegal>)
                                ((is-a? model <interface>) <incomplete>)
                                (else <illegal>)))))
    (append triples (list (t-triple on guard #f statement)))))

(define ((triples:add-illegals model) triples)
  (append (append-map (cut add-illegals model triples <>) (ast:in-triggers model))
          (filter (compose ast:modeling? car ast:trigger* t-on) triples)))

(define (triples:mark-the-end triples)
  (define (mark-the-end t)
    (let* ((on (t-on t))
           (illegal? (declarative-illegal? (t-statement t)))
           (blocking? (t-blocking t))
           (valued-trigger? (ast:typed? ((compose car ast:trigger*) on)))
           (modeling? (is-a? ((compose .event car ast:trigger*) on) <modeling-event>))
           (port ((compose .port car ast:trigger*) on))
           (provides? (and port (ast:provides? port))))
      (if (parent on <interface>)
          (if (or valued-trigger? illegal?) t
              (let* ((statement (t-statement t))
                     (end (make (if modeling? <the-end> <reply>)))
                     (elements (if (is-a? statement <compound>)
                                   (append (ast:statement* statement) (list end))
                                   (list statement end)))
                     (statement (make <compound> #:elements elements)))
                (t-triple on (t-guard t) (t-blocking t) statement)))
          (let ((t (if (or valued-trigger? illegal? blocking?) t
                       (let* ((statement (t-statement t))
                              (reply (if provides? (list (make <reply>)) '()))
                              (elements (if (is-a? statement <compound>)
                                            (ast:statement* statement)
                                            (list statement)))
                              (elements (append elements reply))
                              (statement (make <compound> #:elements elements)))
                         (t-triple on (t-guard t) (t-blocking t) statement)))))
            (if illegal? t (add-the-end t))))))
  (map mark-the-end triples))

(define (add-the-end t)
  (let* ((statement (t-statement t))
         (elements (if (is-a? statement <compound>)
                       (ast:statement* statement)
                       (list statement)))
         (elements (append elements (list (make <the-end>))))
         (statement (make <compound> #:elements elements)))
    (t-triple (t-on t) (t-guard t) (t-blocking t) statement)))

(define ((triples:declarative-illegals model) triples)
  (define (illegal? o)
    (match o
      (($ <illegal>) o)
      ((and ($ <compound>) (= ast:statement* (statement))) (illegal? statement))
      (_ #f)))
  (define (foo t)
    (let* ((on (t-on t))
           (trigger ((compose car ast:trigger*) on))
           (provides? (and=> (.port trigger) ast:provides?))
           (statement (t-statement t)))
      (if (and (or (is-a? model <interface>) provides?) (illegal? statement)) (t-triple on (t-guard t) (t-blocking t) (make <declarative-illegal>))
          t)))
  (map foo triples))

(define (triples:split-multiple-on triples)
  (define (split-on t)
    (let* ((on (t-on t))
           (triggers (ast:trigger* on))
           (ons (if (= (length triggers) 1) (list on)
                    (map (lambda (t) (clone on #:triggers (make <triggers> #:elements (list t)))) triggers))))
      (map (lambda (on)
             (let* ((trigger ((compose car ast:trigger*) on))
                    (provides? (and=> (.port trigger) ast:provides?)))
               (t-triple on (t-guard t) (and provides? (t-blocking t)) (t-statement t)))) ons)))
  (append-map split-on triples))

(define (combine guards)
  (make <guard> #:expression (reduce (cut make <and> #:left <> #:right <>)
                                     (make <literal> #:value "true")
                                     (map .expression guards))))

(define (triples:->triples o)
  (define (triple o)
    (let ((path (ast:path o (lambda (p) (is-a? (.parent p) <behaviour>)))))
      (t-triple (find (is? <on>) path)
                (combine (filter (is? <guard>) path))
                (find (is? <blocking>) path)
                o)))
  (if (and (is-a? o <compound>) (null? (ast:statement* o))) '()
      (map triple (tree-collect-shallow ast:imperative? o))))

(define (triples:on-compound triples)
  (define (foo t)
    (let* ((statement (t-statement t))
           (statement (if (is-a? statement <compound>) statement
                          (make <compound> #:elements (list statement)))))
      (t-triple (t-on t) (t-guard t) (t-blocking t) statement)))
  (map foo triples))

(define (triples:state-traversal o)
  (match o
    (($ <behaviour>) (clone o #:statement
                            ((compose
                              triples:->compound-guard-on
                              (triples:fix-empty-interface (parent o <model>))
                              (triples:add-illegals (parent o <model>))
                              triples:mark-the-end
                              (triples:declarative-illegals (parent o <model>))
                              triples:split-multiple-on
                              triples:->triples
                              .statement
                              ) o)))
    ((? (is? <ast>)) (tree-map triples:state-traversal o))
    (_ o)))

(define (triples:->on-guard* triples)
  (define ((trigger-equal? trigger) triple)
    (let ((t ((compose car ast:trigger* t-on) triple)))
      (and (equal? (.port.name t) (.port.name trigger)) (equal? (.event.name t) (.event.name trigger)))))
  (let* ((sorted-triples (let loop ((triples triples))
                           (if (null? triples) '()
                               (let ((trigger ((compose car ast:trigger* t-on car) triples)))
                                 (receive (shared rest)
                                     (partition (trigger-equal? trigger) triples)
                                   (cons shared (loop rest)))))))
         (ons (map
               (lambda (triples)
                 (let* ((on ((compose t-on car) triples))
                        (guards (map (lambda (t)
                                       (let* ((statement (t-statement t))
                                              (blocking (t-blocking t))
                                              (statement (if blocking (clone blocking #:statement statement)
                                                             statement)))
                                         (clone (t-guard t) #:statement statement)))
                                     triples))
                        ;; code need <otherwise>
                        (otherwise (list (make <guard> #:expression (make <otherwise>) #:statement (make <illegal> #:incomplete #t))))
                        (otherwise? (not (find (compose ast:literal-true? .expression) guards)))
                        (guards (if otherwise? (append guards otherwise)
                                    guards)))
                   ;; FIXME: up code to use <declarative-compound>
                   ;;(clone on #:statement (make <declarative-compound> #:elements guards))
                   (clone on #:statement (make <compound> #:elements guards))))
               sorted-triples)))
    ons))

(define (triples:event-traversal o)
  (match o
    (($ <behaviour>) (clone o #:statement
                            ((compose
                              (cut make <compound> #:elements <>)
                              triples:->on-guard*
                              triples:simplify-guard
                              (rewrite-formals (parent o <model>))
                              (triples:add-illegals (parent o <model>))
                              triples:split-multiple-on
                              triples:->triples
                              .statement
                              ) o)))
    ((? (is? <ast>)) (tree-map triples:event-traversal o))
    (_ o)))

(define ((rewrite-formals model) triples)

  (define (pair-equal? p) (equal? (car p) (cdr p)))

  (define ((rename mapping) o)
    (match o
      ((and ($ <trigger>) (? (compose null? ast:formal*))) o)
      (($ <trigger>)
       (clone o #:formals (clone (.formals o) #:elements (map (rename mapping) ((compose .elements .formals) o)))))
      (($ <action>) (clone o #:arguments ((rename mapping) (.arguments o))))
      (($ <arguments>) (clone o #:elements (map (rename mapping) (.elements o))))
      ((? string?) (or (assoc-ref mapping o) o))
      ((? (is? <ast>)) (tree-map (rename mapping) o))
      (_ o)))

  (define (foo t)
    (let ((o (t-on t)))
      (match o
        ((and ($ <on>) (? (compose null? ast:formal* .event car ast:trigger*)))
         (let* ((trigger ((compose car .elements .triggers) o))
                (formals ((compose .elements .formals .signature) (.event trigger))))
           (if (null? formals) t
               (t-triple (clone o #:triggers (clone (.triggers o) #:elements (list (clone trigger #:formals (clone (.formals trigger) #:elements formals)))))
                         (t-guard t)
                         (t-blocking t)
                         (t-statement t)))))

        (($ <on>)
         (let* ((trigger ((compose car .elements .triggers) o))
                (trigger (if (pair? (ast:formal* trigger)) trigger
                             (clone trigger #:formals (clone (.formals trigger) #:elements (ast:formal* (.event trigger))))))
                (formals (map .name ((compose .elements .formals .signature) (.event trigger))))
                (members (map .name (ast:variable* model)))
                (locals (map .name (tree-collect (is? <variable>) (t-statement t))))
                (occupied members)
                (fresh (letrec ((fresh (lambda (occupied name)
                                         (if (member name occupied)
                                             (fresh occupied (string-append name "x"))
                                             name))))
                         fresh)) ;; occupied name -> namex
                (refresh (lambda (occupied names)
                           (fold-right (lambda (name o)
                                         (cons (fresh o name) o))
                                       occupied names))) ;; occupied names -> (append namesx occupied)

                (fresh-formals (list-head (refresh occupied formals) (length formals)))
                (mapping (filter (negate pair-equal?) (map cons (map .name ((compose .elements .formals) trigger)) fresh-formals)))

                (occupied (append (map cdr mapping) members))

                (mapping (append (map cons locals (list-head (refresh occupied locals) (length locals))) mapping)))

           (if (null? mapping) t
               (t-triple
                (clone o #:triggers (clone (.triggers o) #:elements (list ((rename mapping) trigger))))
                (t-guard t)
                (t-blocking t)
                ((rename mapping) (t-statement t)))))))))
  (map foo triples))

(define-method (is-data? (o <ast>))
  (or (is-a? o <data>) (and (is-a? o <var>) (is-a? ((compose .type .variable) o) <extern>))))

(define (purge-data o)
  (match o
    (($ <data>) #f)
    (($ <action>)
     (clone o #:arguments (make <arguments>)))

    (($ <trigger>)
     (clone o #:formals (make <formals>)))

    ((? (is? <ast-list>))
     (clone o #:elements (filter-map purge-data (.elements o))))

    (($ <extern>) #f)
    (($ <assign>)
     (let* ((variable (.variable o))
            (type (and variable (.type variable))))
       (if (and type (not (is-a? type <extern>))) (clone o #:expression (purge-data (.expression o)))
         (clone (make <compound>) #:parent (.parent o)))))
    (($ <formal>)
     (let ((type (.type o)))
       (and type (not (is-a? type <extern>)) o)))
    (($ <call>) (clone o #:arguments (make <arguments> #:elements (filter (negate is-data?) (ast:argument* o)))))
    (($ <variable>)
     (let ((type (.type o)))
       (and type (not (is-a? type <extern>))
            (clone o #:expression (purge-data (.expression o))))))

    (($ <var>)
     (let* ((variable (.variable o))
            (type (and variable (.type variable))))
       (and type (not (is-a? type <extern>)) o)))

    ((and ($ <return>) (= .expression ($ <data-expr>))) (clone o #:expression #f))
    ((? (is? <ast>)) (tree-map purge-data o))
    (_ o)))

(define (triples:simplify-guard triples)
  (map (lambda (t)
         (t-triple
          (t-on t)
          (clone (t-guard t) #:expression ((compose simplify .expression t-guard) t))
          (t-blocking t)
          (t-statement t)))
       triples))

;; simplify exp
(define-method (simplify (o <bool-expr>))
  (match o
    (($ <not>)(let ((e (simplify (.expression o))))
                (cond ((ast:literal-true? e) (clone e #:value "false"))
                          ((ast:literal-false? e) (clone e #:value "true"))
                          (else (clone o #:expression e)))))
    (($ <and>)(let ((left (simplify (.left o)))
                    (right (simplify (.right o))))
                (cond ((ast:literal-true? left) right)
                      ((ast:literal-false? left) left)
                      ((ast:literal-true? right) left)
                      ((ast:literal-false? right) right)
                      (else (clone o #:left left #:right right)))))
    (($ <or>)(let ((left (simplify (.left o)))
                   (right (simplify (.right o))))
               (cond ((ast:literal-true? left) left)
                     ((ast:literal-false? left) right)
                     ((ast:literal-true? right) right)
                     ((ast:literal-false? right) left)
                     (else (clone o #:left left #:right right)))))
    (_ o)))

(define* (add-reply-port o #:optional (port #f) (block? #f)) ;; requires (= 1 (length (.triggers on)))
  ;(stderr "add-reply-report o = ~a; port = ~a: model = ~a\n" o port model)
  (match o
    (($ <reply>) (let ((port? (.port o))) (if (and port? (not (string? port?))) o (clone o #:port.name (.name port)))))
    (($ <blocking>)
     (if block?
         (make <blocking-compound>
           #:port port
           #:elements (let ((s (.statement o)))
                        (if (is-a? s <compound>) (map (cut add-reply-port <> port block?) (ast:statement* s))
                            (list (add-reply-port s port block?)))))
         (add-reply-port (.statement o) port block?)))
    (($ <on>)
     (clone o #:statement (add-reply-port (.statement o)
                                          (if port port ((compose .port car ast:trigger*) o))
                                          (eq? 'provides ((compose .direction .port car ast:trigger*) o)))))
    (($ <guard>) (clone o #:statement (add-reply-port (.statement o) port block?)))
    (($ <compound>) (clone o #:elements (map (cut add-reply-port <> port block?) (ast:statement* o))))
    (($ <behaviour>) (clone o #:statement (add-reply-port (.statement o) port block?)))
    (($ <component>) (clone o #:behaviour (add-reply-port (.behaviour o) (if (= 1 (length (ast:provides-port* o))) (car (ast:provides-port* o)) #f) block?)))
    (($ <system>) o)
    (($ <foreign>) o)
    (($ <interface>) o)
    ((? (is? <ast>)) (tree-map (cut add-reply-port <> port block?) o))
    (_ o)))

(define* ((binding-into-blocking #:optional (locals '())) o)

  (define (formal-binding->formal o)
    (match o
      (($ <formal-binding>) (make <formal> #:name (.name o) #:type.name (.type.name o) #:direction (.direction o)))
      (_ o)))

  (define ((passdown-formal-bindings formal-bindings) o)
    (match o
      ((and ($ <compound>) (? ast:declarative?))
       (clone o #:elements (map (passdown-formal-bindings formal-bindings) (ast:statement* o))))
      ((? ast:declarative?) (clone o #:statement ((passdown-formal-bindings formal-bindings) (.statement o))))
      (($ <compound>) (clone o #:elements (cons formal-bindings (ast:statement* o))))
      (_ (make <compound> #:elements (cons formal-bindings (list o))))))

  (match o
    (($ <on>)
     (let* ((trigger ((compose car ast:trigger*) o))
            (on-formals (ast:formal* trigger))
            (formal-bindings (filter (is? <formal-binding>) on-formals))
            (formal-bindings (and (pair? formal-bindings) (make <out-bindings> #:elements formal-bindings #:port (.port trigger))))
            (on-formals (map formal-binding->formal on-formals)))
       (if (not formal-bindings) o
           (clone o
                  #:triggers (clone (.triggers o)
                                    #:elements (list (clone trigger #:formals (make <formals> #:elements on-formals))))
                  #:statement ((passdown-formal-bindings formal-bindings) (.statement o))))))

    (($ <component>)
     (clone o #:behaviour ((binding-into-blocking) (.behaviour o))))

    (($ <behaviour>)
     (clone o #:statement ((binding-into-blocking '()) (.statement o))))

    (($ <interface>) o)
    (($ <system>) o)
    (($ <foreign>) o)
    ((? (is? <ast>)) (tree-map (binding-into-blocking locals) o))
    (_ o)))

(define* ((remove-otherwise #:optional (keep-annotated? #t) (statements '())) o)
  (define (virgin-otherwise? x) (or (equal? x "otherwise") (eq? x *unspecified*))) ;; FIXME *unspecified*
  (match o
    ((? ast:imperative?) o)
    ((and ($ <guard>) (= .expression (and ($ <otherwise>) (= .value value))) (= .statement statement)) (=> failure)
     (if (or (and keep-annotated?
                  (not (virgin-otherwise? value)))
             (null? statements))
         (failure)
         (clone o #:expression (guards-not-or statements)
                #:statement ((remove-otherwise keep-annotated?) statement))))
    ((and ($ <compound>) (= ast:statement* (statements ...)))
     (clone o #:elements (map (remove-otherwise keep-annotated? statements) statements)))
    (($ <skip>) o)
    (($ <functions>) o)
    ((and (? (is? <component>) (= .behaviour behaviour)))
     (clone o #:behaviour ((remove-otherwise keep-annotated? statements) behaviour)))
    ((and (? (is? <interface>) (= .behaviour behaviour)))
     (clone o #:behaviour ((remove-otherwise keep-annotated? statements) behaviour)))
    ((? (is? <component-model>)) o)
    ((? (is? <ast>)) (tree-map (remove-otherwise keep-annotated? statements) o))
    (_ o)))

(define (guards-not-or o)
  (let* ((expressions (map .expression o))
         (others (remove (is? <otherwise>) expressions))
         (expression (reduce (lambda (g0 g1)
                               (if (ast:equal? g0 g1) g0 (make <or> #:left g0 #:right g1)))
                             '() others)))
    (match expression
      ((and ($ <not>) (= .expression expression)) expression)
      (_ (make <not> #:expression expression)))))

(define-method (simplify (o <ast>))
  o)

(define-method (root-> (o <root>))
  ((compose
    triples:event-traversal
    ) o))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    root->)
   ast))
