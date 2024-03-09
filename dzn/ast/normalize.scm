;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020, 2021, 2022, 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2018, 2020, 2022, 2023 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
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

(define-module (dzn ast normalize)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module (dzn ast ast)
  #:use-module (dzn tree util)
  #:use-module (dzn ast)
  #:use-module (dzn misc)

  #:export (%normalize:short-circuit?
            add-defer-end
            add-determinism-temporaries
            add-explicit-temporaries
            add-void-function-return
            add-reply-port
            binding-into-blocking
            extract-call
            not-or-guards
            normalize:event
            normalize:event+illegals
            normalize:state
            normalize:state+illegals
            purge-data
            purge-data+add-defer-end
            remove-behavior
            remove-location
            remove-otherwise
            simplify-guard-expressions
            split-complex-expressions
            split-variable
            tag-imperative-blocks))

;; Should add-explicit-temporaries only cater for deterministic ordering
;; of noisy expressions?
(define %noisy-ordering? (make-parameter #f))

;; Should transformation stop here?
(define %normalize:short-circuit? (make-parameter (const #f)))


;;;
;;; Utilities and predicates.
;;;
(define-method (split-variable (o <variable>))
  (let* ((default (ast:default-value o))
         (variable (clone o #:expression default))
         (name (.name o))
         (location (.location o))
         (assign (graft o (make <assign>
                            #:variable.name name
                            #:expression (.expression o)
                            #:location location))))
    (values variable assign)))

(define temp-name
  (let ((count -1))
    (lambda (o)
      (set! count (1+ count))
      (format #f "dzn_tmp~a" count))))

(define (temporaries o)
  (define typed-action/call?
    (conjoin (disjoin (is? <action>) (is? <call>))
             (disjoin tree:parent (cute throw 'no-parent <>))
             ast:typed?))
  (define add-temporary?
    (conjoin (disjoin (is? <action>)
                      (is? <binary>)
                      (is? <call>))
             (disjoin tree:parent (cute throw 'no-parent <>))
             ast:typed?
             (compose pair?
                      (cute tree:collect <> typed-action/call?))
             (disjoin
              (cute as <> <arguments>)
              (cute tree:ancestor <> <arguments>)
              (compose (cute as <> <binary>) tree:parent)
              (compose (cute tree:ancestor <> <binary>) tree:parent))))
  (cond ((is-a? o <call>)
         (tree:collect o add-temporary?))
        ((or (is-a? o <assign>) (is-a? o <variable>))
         (append
          (tree:collect o add-temporary?)
          (map .expression
               (tree:collect
                o
                (conjoin
                 (is? <not>)
                 (compose pair? (cute tree:collect <> typed-action/call?)))))))
        ((is-a? o <if>)
         (tree:collect (.expression o) typed-action/call?))
        ((or (as o <expression>)
             (and (is-a? o <reply>) (.expression o))
             (and (is-a? o <return>) (.expression o)))
         =>
         (cute tree:collect <> typed-action/call?))
        (else
         '())))

(define (noisy-temporaries o)
  (define noisy-call?
    (conjoin (is? <call>)
             (compose .noisy? .function)))
  (define typed-action/call?
    (conjoin (disjoin (is? <action>)
                      noisy-call?)
             ast:typed?))
  (define >1-argument-typed-action/call?
    (compose (cute > <> 1)
             length
             (cute filter (compose pair?
                                   (cute tree:collect <> typed-action/call?))
                   <>)
             ast:argument*))
  (define >1-typed-action/call?
    (compose (cute > <> 1)
             length
             (cute tree:collect <> typed-action/call?)))
  (let* ((arguments (tree:collect
                     o
                     (conjoin (is? <arguments>)
                              (compose (cute > <> 1) length .elements)
                              >1-typed-action/call?)))
         (arguments (filter >1-argument-typed-action/call? arguments))
         (arguments (append-map ast:argument* arguments))
         (expressions (tree:collect
                       o
                       (conjoin (disjoin (is? <minus>) (is? <plus>))
                                >1-typed-action/call?)))
         (expressions (append-map
                       (lambda (x)
                         (let ((expressions (list (.left x) (.right x))))
                           (filter
                            (compose pair?
                                     (cute tree:collect <> typed-action/call?))
                            expressions)))
                       expressions)))
    (append arguments expressions)))

(define (add-temporary? o)
  (cond ((%noisy-ordering?)
         (let ((temporaries (noisy-temporaries o)))
           (match temporaries
             ((one two rest ...)
              one)
             (_
              #f))))
        (else
         (match (temporaries o)
           ((h t ...)
            (let ((p (tree:parent h)))
              (and (not (or (as p <and>) (tree:ancestor p <and>)
                            (as p <or>) (tree:ancestor p <or>)))
                   h)))
           (_
            #f)))))

(define (complex? o)
  (pair? (tree:collect o (disjoin (is? <and>) (is? <or>)))))

(define (split-complex? o)
  (and (not (%noisy-ordering?))
       (complex? o)
       (pair? (temporaries o))
       (not (add-temporary? o))))


;;;
;;; Expressions.
;;;
(define-method (group-expression (o <binary>))
  (make <group> #:expression o))


(define-method (group-expression (o <field-test>))
  (make <group> #:expression o))

(define-method (group-expression (o <expression>))
  o)

(define (and-expressions expressions)
  (reduce (cute make <and> #:left <> #:right <>)
          (make <literal> #:value "true")
          (map group-expression expressions)))

(define (or-expressions expressions)
  (reduce (cute make <or> #:left <> #:right <>)
          (make <literal> #:value "false")
          (map group-expression expressions)))

(define (not-or-guards guards)
  (let* ((expressions (map .expression guards))
         (others (remove (is? <otherwise>) expressions))
         (expression (or-expressions others)))
    (match expression
      ((and ($ <not>) (= .expression expression)) expression)
      (_ (make <not> #:expression expression)))))

(define (and-not-guards guards)
  (let* ((expression
          (match guards
            (()
             (make <literal> #:value "true"))
            ((guard)
             (make <not> #:expression (.expression guard)))
            ((h t ...)
             (let ((expressions (map (compose (cute make <not> #:expression <>)
                                              .expression)
                                     guards)))
               (and-expressions expressions))))))
    (make <guard> #:expression expression)))

(define-method (simplify-expression (o <bool-expr>))
  (define (static? o)
    (null? (tree:collect o (disjoin (is? <action>) (is? <call>)))))
  (match o
    (($ <not>)
     (let* ((expression (.expression o))
            (e (simplify-expression expression)))
       (cond ((is-a? expression <not>)
              (simplify-expression (.expression expression)))
             ((and (is-a? expression <group>)
                   (as (simplify-expression (.expression expression))
                       <not>))
              =>
              .expression)
             ((ast:literal-true? e) (clone e #:value "false"))
             ((ast:literal-false? e) (clone e #:value "true"))
             (else (clone o #:expression e)))))
    (($ <and>)
     (let ((left (simplify-expression (.left o)))
           (right (simplify-expression (.right o))))
       (cond ((and (is-a? left <not>)
                   (static? left)
                   (ast:equal? (.expression left) right))
              (make <literal> #:value "false"))
             ((and (is-a? right <not>)
                   (static? left)
                   (ast:equal? (.expression right) left))
              (make <literal> #:value "false"))
             ((and (static? left)
                   (ast:equal? left right))
              left)
             ((ast:literal-true? left) right)
             ((ast:literal-false? left) left)
             ((ast:literal-true? right) left)
             ((and (static? left)
                   (ast:literal-false? right)) right)
             (else (clone o #:left left #:right right)))))
    (($ <or>)
     (let ((left (simplify-expression (.left o)))
           (right (simplify-expression (.right o))))
       (cond ((and (is-a? left <not>)
                   (static? left)
                   (ast:equal? (.expression left) right))
              (make <literal> #:value "true"))
             ((and (is-a? right <not>)
                   (static? left)
                   (ast:equal? (.expression right) left))
              (make <literal> #:value "true"))
             ((and (static? left)
                   (ast:equal? left right))
              left)
             ((ast:literal-true? left) left)
             ((ast:literal-false? left) right)
             ((and (static? left)
                   (ast:literal-true? right)) right)
             ((ast:literal-false? right) left)
             (else (clone o #:left left #:right right)))))
    ((? (is? <binary>))
     (clone o
            #:left (simplify-expression (.left o))
            #:right (simplify-expression (.right o))))
    (_
     o)))

(define-method (simplify-expression (o <group>))
  (let* ((expression (.expression o))
         (expression (simplify-expression expression)))
    (if (or (is-a? expression <unary>)
            (is-a? expression <field-test>)) expression
            (clone o #:expression expression))))

(define-method (simplify-expression (o <expression>))
  o)

(define-method (simplify-toplevel-expression (o <expression>))
  (let ((expression (simplify-expression o)))
    (if (is-a? expression <group>) (.expression expression)
        expression)))

(define-method (simplify-guard (o <guard>))
  (clone o #:expression (simplify-toplevel-expression (.expression o))))

(define-method (simplify-guard (o <canonical-on>))
  (clone o #:guard (simplify-guard (.guard o))))


;;;
;;; Canonical-on.
;;;
(define-method (statement->canonical-on (o <compound>))
  (define (imperative->canonical-ons imperative)
    (let* ((path (tree:path imperative (compose (is? <behavior>) tree:parent)))
           (blocking (find (is? <blocking>) path))
           (guards (filter (is? <guard>) path))
           (expression (and-expressions (map .expression guards)))
           (guard (make <guard> #:expression expression))
           (on (find (is? <on>) path))
           (triggers (ast:trigger* on))
           (behavior (tree:ancestor o <behavior>)))
      (define (make-on trigger)
        (graft behavior (make <canonical-on>
                          #:blocking (and (ast:provides? trigger) blocking)
                          #:guard guard
                          #:trigger trigger
                          #:statement imperative
                          #:location (.location on))))
      (map make-on triggers)))
  (if (null? (ast:statement* o)) '()
      (let ((imperatives (tree:collect
                          o
                          ast:imperative?
                          #:stop?
                          (conjoin (is? <ast>)
                                   (disjoin ast:declarative?
                                            (compose ast:declarative?
                                                     tree:parent))))))
        (append-map imperative->canonical-ons imperatives))))

(define-method (canonical-on->guard (o <canonical-on>))
  (let* ((guard (.guard o))
         (trigger (.trigger o))
         (triggers (make <triggers> #:elements (list trigger)))
         (blocking (.blocking o))
         (statement (.statement o))
         (statement (if (not blocking) statement
                        (clone blocking #:statement statement)))
         (statement (make <on> #:triggers triggers #:statement statement
                          #:location (.location o))))
    (clone guard #:statement statement)))

(define (sort-canonical-ons ons)
  (match ons
    (() '())
    ((on rest ...)
     (let* ((trigger (.trigger on))
            (shared rest (partition
                          (compose (cute ast:equal? <> trigger) .trigger)
                          ons)))
       (cons shared (sort-canonical-ons rest))))))

(define* (canonical-ons->on ons #:key otherwise?)
  (define (canonical-on->guard on)
    (let* ((statement (.statement on))
           (blocking (.blocking on))
           (statement (if blocking (clone blocking #:statement statement)
                          statement))
           (guard (.guard on)))
      (clone guard #:statement statement)))
  (let* ((on (car ons))
         (guards (map canonical-on->guard ons))
         (otherwise (make <guard>
                      #:expression (make <otherwise>)
                      #:statement (make <illegal>)))
         (true-guard? (find (compose ast:literal-true? .expression) guards))
         (otherwise? (and otherwise? (not true-guard?)))
         (guards (if (not otherwise?) guards
                     `(,@guards ,otherwise)))
         (trigger (.trigger on))
         (triggers (make <triggers> #:elements (list trigger)))
         (location (.location on))
         (on (make <on> #:triggers triggers #:location location))
         (statement (make <compound> #:elements guards #:location location)))
    (clone on #:statement statement)))


;;;
;;; Canonical-on normalizations.
;;;
(define (make-declarative-illegal/illegal trigger)
  (make (cond ((or (tree:ancestor trigger <interface>)
                   (ast:provides? trigger))
               <declarative-illegal>)
              (else
               <illegal>))))

(define* (implicit-illegal->explicit-illegal
          trigger ons #:key (make-illegal (const (make <illegal>))))
  (let* ((ons (filter (compose (cute ast:equal? <> trigger) .trigger) ons))
         (guard (and-not-guards (map .guard ons)))
         (guard (simplify-guard guard)))
    (if (ast:literal-false? (.expression guard)) ons
        (let* ((provides? (and=> (.port trigger) ast:provides?))
               (model (tree:ancestor trigger <model>))
               (location (or (and (pair? ons) (car ons))
                             model))
               (on (graft model (make <canonical-on>
                                  #:guard guard
                                  #:trigger trigger
                                  #:statement (make-illegal trigger)
                                  #:location (.location location)))))
          (append ons (list on))))))

(define-method (model->triggers (o <interface>))
  (define (event->trigger o)
    (graft o (make <trigger> #:event.name (.name o))))
  (map event->trigger (ast:in-event* o)))

(define-method (model->triggers (o <component-model>))
  (define (port+event->trigger port event)
    (graft o (make <trigger>
               #:port.name (.name port)
               #:event.name (.name event))))
  (define (port->triggers o)
    (map (cute port+event->trigger o <>)
         ((if (ast:provides? o) ast:in-event*
              ast:out-event*)
          (.type o))))
  (append-map port->triggers (ast:port* o)))

(define* (implicit-illegals->explicit-illegals
          model ons #:key (make-illegal (const (make <illegal>))))


  (let ((modeling (filter (compose ast:modeling? .trigger) ons))
        (triggers (model->triggers model)))
    (append
     (append-map (cut implicit-illegal->explicit-illegal <> ons
                      #:make-illegal make-illegal)
                 triggers)
     modeling)))

(define-method (add-the-end (o <compound>))
  (let* ((elements (.elements o))
         (the-end (make <the-end>))
         (return-index (list-index (is? <return>) elements)))
    (if (not return-index) (clone o #:elements `(,@elements ,the-end))
        (clone o #:elements `(,@(take elements (1+ return-index))
                              ,the-end
                              ;;,@(drop elements (1- return-index)) ;;TODO FIXME
                              )))))

(define-method (add-the-end (o <statement>))
  (make <compound> #:elements (list o (make <the-end>))))

(define-method (add-the-end (o <canonical-on>))
  (let ((statement (.statement o)))
    (if (ast:illegal? statement) o
        (let ((statement (add-the-end statement)))
          (clone o #:statement statement)))))

(define-method (add-void-return (o <canonical-on>))
  (let* ((trigger (.trigger o))
         (port (.port trigger))
         (statement (.statement o))
         (provides? (and port (ast:provides? port)))
         (model (tree:ancestor o <model>))
         (reply? (and (not (ast:typed? trigger))
                      (not (.blocking o))
                      (or (and (is-a? model <interface>)
                               (not (ast:modeling? trigger)))
                          (and provides?
                               (null? (tree:collect
                                       statement
                                       (conjoin
                                        (is? <reply>)
                                        (disjoin (negate .port)
                                                 (compose (cute eq? port <>)
                                                          .port))))))))))
    (if (not reply?) o
        (let ((statement (ast:add-statement (.statement o) (make <return>))))
          (clone o #:statement statement)))))

(define-method (illegal->declarative-illegal (o <canonical-on>))
  (let ((declarative? (and (ast:illegal? (.statement o))
                           (or (is-a? (tree:ancestor o <model>) <interface>)
                               (ast:provides? (.trigger o))))))
    (if (not declarative?) o
        (graft o #:statement (make <declarative-illegal>)))))

(define-method (with-behavior (o <behavior>) procedure)
  (lambda (x)
    (let ((x (procedure x)))
      (match x
        ((ons ...) (map (cute graft* o <>) ons))
        (o (graft* o x))))))

(define (normalize:state o)
  "Push guards up, thereby splitting the body of a trigger into multiple
guarded occurrences."
  (match o
    (($ <behavior>)
     (clone o
            #:statement
            ((compose
              (cute make <declarative-compound> #:elements <>)
              (cute map canonical-on->guard <>)
              (cute map (cute group-expressions <>
                              (list <and> <field-test> <or>))
                    <>)
              (with-behavior o (cute map simplify-guard <>))
              statement->canonical-on
              .statement
              ) o)
            #:functions
            (group-expressions (.functions o) (list <and> <field-test> <or>))))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree:shallow-map normalize:state o))
    (_
     o)))

(define (normalize:state+illegals o)
  (match o
    (($ <behavior>)
     (let ((model (tree:ancestor o <model>)))
       (clone o
              #:statement
              ((compose
                (cute make <declarative-compound> #:elements <>)
                (cute map canonical-on->guard <>)
                (cute map (cute group-expressions <>
                                (list <and> <field-test> <or>))
                      <>)
                (with-behavior o (cute map simplify-guard <>))
                (cut implicit-illegals->explicit-illegals model <>
                     #:make-illegal make-declarative-illegal/illegal)
                (cute map add-the-end <>)
                (cute map add-void-return <>)
                (cute map illegal->declarative-illegal <>)
                statement->canonical-on
                .statement
                ) o)
              #:functions
              (group-expressions (.functions o) (list <and> <field-test> <or>)))))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree:shallow-map normalize:state+illegals o))
    (_
     o)))

(define (normalize:event o)
  "Merge all occurrences of a trigger into a single unguarded `on',
i.e., pushing guards into the body of the trigger."
  (match o
    (($ <behavior>)
     (clone o
            #:statement
            ((compose
              (cute make <compound> #:elements <>)
              (cute map canonical-ons->on <>)
              sort-canonical-ons
              (cute map (cute group-expressions <>
                              (list <and> <field-test> <or>))
                    <>)
              (with-behavior o (cute map simplify-guard <>))
              (cute map alpha-rename <>)
              (with-behavior o (cute map formal-dereference <>))
              statement->canonical-on
              .statement
              ) o)
            #:functions
            (group-expressions (.functions o) (list <and> <field-test> <or>))))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree:shallow-map normalize:event o))
    (_
     o)))

(define (normalize:event+illegals o)
  (match o
    (($ <behavior>)
     (let ((model (tree:ancestor o <model>)))
       (clone o
              #:statement
              ((compose
                (cute make <compound> #:elements <>)
                (cute map (cut canonical-ons->on <> #:otherwise? #t) <>)
                sort-canonical-ons
                (cute map (cute group-expressions <>
                                (list <and> <field-test> <or>))
                      <>)
                (with-behavior o (cute map simplify-guard <>))
                (cute map alpha-rename <>)
                (cute implicit-illegals->explicit-illegals model <>)
                (with-behavior o (cute map formal-dereference <>))
                statement->canonical-on
                .statement
                ) o)
              #:functions
              (group-expressions (.functions o) (list <and> <field-test> <or>)))))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree:shallow-map normalize:event+illegals o))
    (_
     o)))

(define-method (alpha-rename (o <canonical-on>))
  "Rewrite names of formals and locals for event-first normalization.

Event-first normalization groups all guarded event handling blocks for a
specific event in one @code{on EVENT @{@dots{}@}} clause.  Before
normalization each block can use its own naming for the parameters as
formally declared in the interface.  Normalization implies that these
specific parameter names have to be unified.

We follow the following renaming strategy:

@itemize
@item
formals are rewritten to their name as declared in the interface

@item
when the formal name clashes with a member variable, append as many
'x's to the formal name to avoid clashes

@item
if the new formal name clashes with a local, append an 'x' to the local
to prevent unintended shadowing
@end itemize"

  (define (pair-equal? p) (equal? (car p) (cdr p)))

  (define ((rename mapping) o)
    (define (formal-or-local? o)
      (or (is-a? o <formal>)
          (and (is-a? o <variable>)
               (not (is-a? (tree:parent o) <variables>)))))
    (define (rename-string o)
      (or (assoc-ref mapping o) o))
    (match o
      ((and ($ <trigger>) (? (compose null? ast:formal*)))
       o)
      (($ <trigger>)
       (let ((elements (map (rename mapping) (ast:formal* o))))
         (clone o #:formals (clone (.formals o) #:elements elements))))
      (($ <action>)
       (clone o #:arguments ((rename mapping) (.arguments o))))
      (($ <arguments>)
       (clone o #:elements (map (rename mapping) (ast:argument* o))))
      (($ <reference>)
       (if (not (formal-or-local? (.variable o))) o
           (clone o #:name (rename-string (.name o)))))
      (($ <assign>)
       (let ((expression ((rename mapping) (.expression o)))
             (name (if (not (formal-or-local? (.variable o))) (.variable.name o)
                       (rename-string (.variable.name o)))))
         (clone o #:variable.name name #:expression expression)))
      (($ <variable>)
       (let ((name (if (formal-or-local? o) (rename-string (.name o))
                       (.name o))))
         (clone o #:name name #:expression ((rename mapping) (.expression o)))))
      (($ <field-test>)
       (if (not (formal-or-local? (.variable o))) o
           (clone o #:name (rename-string (.variable.name o)))))
      (($ <formal>)
       (clone o #:name (rename-string (.name o))))
      (($ <formal-binding>)
       (clone o #:name (rename-string (.name o))))
      (($ <interface>)
       o)
      ((? (%normalize:short-circuit?))
       o)
      ((? (is? <ast>))
       (tree:shallow-map (rename mapping) o))
      (_
       o)))

  (let* ((trigger (.trigger o))
         (event (.event trigger))
         (formals ((compose ast:formal* .signature) event))
         (formals-ok? (or (pair? (ast:formal* trigger))
                          (null? formals)))
         (model (tree:ancestor o <model>))
         (o (if formals-ok? o
                (let* ((formals (clone (.formals trigger) #:elements formals))
                       (trigger (clone trigger #:formals formals)))
                  (clone o #:trigger trigger))))
         (trigger (.trigger o))
         (trigger (if (pair? (ast:formal* trigger)) trigger
                      (let* ((formals (ast:formal* event))
                             (formals (clone (.formals trigger)
                                             #:elements formals)))
                        (clone trigger #:formals formals))))
         (formals (map .name ((compose .elements .formals .signature) event)))
         (members (map .name (ast:variable* model)))
         (locals (map .name (tree:collect (.statement o) (is? <variable>))))
         (occupied members)
         (fresh (letrec ((fresh (lambda (occupied name)
                                  (if (member name occupied)
                                      (fresh occupied (string-append name "x"))
                                      name))))
                  fresh)) ;; occupied name -> namex
         (refresh (lambda (occupied names)
                    (fold-right (lambda (name o)
                                  (cons (fresh o name) o))
                                ;; occupied names -> (append namesx occupied)
                                occupied names)))
         (fresh-formals (list-head (refresh occupied formals) (length formals)))
         (mapping (filter
                   (negate pair-equal?)
                   (map cons
                        (map .name ((compose .elements .formals) trigger))
                        fresh-formals)))
         (occupied (append (map cdr mapping) members))
         (mapping (append (map cons
                               locals
                               (list-head (refresh occupied locals)
                                          (length locals)))
                          mapping)))
    (if (null? mapping) o
        (clone o
               #:trigger ((rename mapping) trigger)
               #:statement ((rename mapping) (.statement o))))))


;;;
;;; Root normalizations.
;;;

(define-method (purge-data+add-defer-end (o <root>))
  ;;purge-data
  (define data?
    (disjoin (is? <extern>)
             (is? <data-expr>)
             (conjoin (disjoin (is? <assign>)
                               (is? <formal>)
                               (is? <formal-reference>)
                               (is? <reference>)
                               (is? <variable>))
                      (compose (is? <extern>) ast:type))))
  (define (parent-location o)
    (or (.location o)
        (parent-location (tree:parent o))))
  (define data->skip-or-#f
    (conjoin (is? <statement>)
             (compose not (is? <variables>) tree:parent)
             (compose not (is? <compound>) tree:parent)
             (compose (cute make <skip> #:location <>)
                      parent-location
                      tree:parent)))
  ;;add-defer-end
  (define (add-end o)
    (let* ((end (graft o (make <defer-end>)))
           (statement (ast:add-statement* (.statement o) end)))
      (graft o #:statement statement)))

  (tree:transform o `((,data? . ,data->skip-or-#f)
                      (,(is? <defer>) . ,add-end))))

(define-method (purge-data (o <root>))
  "Remove every `extern' data variable and reference."
  (define (parent-location o)
    (or (.location o)
        (parent-location (tree:parent o))))
  (let* ((data? (disjoin (is? <extern>)
                         (is? <data-expr>)
                         (conjoin (disjoin (is? <assign>)
                                           (is? <formal>)
                                           (is? <formal-reference>)
                                           (is? <reference>)
                                           (is? <variable>))
                                  (compose (is? <extern>) ast:type))))
         (data->skip-or-#f (conjoin (is? <statement>)
                                    (compose not (is? <variables>) tree:parent)
                                    (compose not (is? <compound>) tree:parent)
                                    (compose (cute make <skip> #:location <>)
                                             parent-location
                                             tree:parent))))
    (tree:transform o data? data->skip-or-#f)))

(define-method (add-void-function-return (o <root>))
  "Make implicit returns explicit for void functions."
  (define* (add-return o #:key (loc o))
    (match o
      (($ <function>)
       (clone o #:statement (add-return (.statement o) #:loc o)))
      (($ <compound>)
       (clone o #:elements (add-return (ast:statement* o) #:loc o)))
      ((statement ... t)
       (append o (list (make <return> #:location (.location (tree:parent t))))))
      ((statement ...)
       (append o (list (make <return> #:location (.location loc)))))))
  (define void-function-with-implicit-return?
    (conjoin (is? <function>)
             (compose (is? <void>) ast:type)))
  (tree:transform o void-function-with-implicit-return? add-return))

(define-method (extract-call (o <root>))
  "Move typed function calls from variable initialization and assignment
to a separate statement, for mCRL2."
  (define (extract-assign/variable-call o)
    (let ((expression (make <literal> #:value "return_value"))
          (call (.expression o)))
      (match o
        (($ <assign>)
         (let ((assign (clone o #:expression expression)))
           (list call assign)))
        (($ <variable>)
         (let* ((default (ast:default-value o))
                (variable (clone o #:expression default))
                (parent (tree:parent o))
                (assign (graft parent (make <assign>
                                        #:variable.name (.name variable)
                                        #:expression expression))))
           (list variable call assign))))))

  (define (extract-call+compound o)
    (let* ((statements (extract-assign/variable-call o))
           (compound (make <compound> #:elements statements)))
      (graft (tree:parent o) compound)))

  (define (compound-extract-call o)
    (let ((elements (append-map
                     (lambda (o)
                       (if (not (assign/variable-call? o)) (list o)
                           (extract-assign/variable-call o)))
                     (.elements o))))
      (graft o #:elements elements)))

  (define assign/variable-call?
    (conjoin
     (disjoin (is? <assign>)
              (is? <variable>))
     (compose (is? <call>) .expression)))

  (define compound-call?
    (conjoin (is? <compound>)
             (compose (cute any assign/variable-call? <>)
                      .elements)))

  (define single-call?
    (conjoin assign/variable-call?
             (compose not (is? <compound>) tree:parent)))

  (tree:transform
   o
   `((,single-call? . ,extract-call+compound)
     (,compound-call? . ,compound-extract-call))))

(define-method (add-defer-end (o <root>))
  (define (add-end o)
    (let* ((end (graft o (make <defer-end>)))
           (statement (ast:add-statement* (.statement o) end)))
      (graft o #:statement statement)))
  (tree:transform o (is? <defer>) add-end))

(define (formal-dereference o)
  (let ((model (tree:ancestor o <model>)))
    (define (rescope o orig interface-formal)
      (let* ((o (graft* (tree:parent interface-formal) o))
             (o (ast:rescope o model)))
        (graft* (tree:parent orig) o)))
    (define (replace-formal-reference o)
      (let* ((interface-formal (.formal o))
             (formal (clone interface-formal #:name (.name o))))
        (rescope formal o interface-formal)))
    (define (replace-formal-reference-binding o)
      (let* ((interface-formal (.formal o))
             (formal (make <formal-binding>
                       #:name (.name o)
                       #:direction (.direction interface-formal)
                       #:type.name (.type.name interface-formal)
                       #:variable.name (.variable.name o))))
        (rescope formal o interface-formal)))
    (tree:transform
     o
     `((,(is? <formal-reference-binding>) . ,replace-formal-reference-binding)
       (,(is? <formal-reference>) . ,replace-formal-reference)))))

(define* (add-reply-port o #:optional (port #f) (block? #f))
  (match o
    (($ <reply>)
     (let ((port? (.port o)))
       (if (and port? (not (string? port?))) o
           (clone o #:port.name (.name port)))))
    (($ <blocking>)
     (if (not block?) (add-reply-port (.statement o) port block?)
         (let ((elements
                (let ((s (.statement o)))
                  (if (not (is-a? s <compound>))
                      (list (add-reply-port s port block?))
                      (map (cute add-reply-port <> port block?)
                           (ast:statement* s))))))
           (make <blocking-compound> #:port port #:elements elements))))
    (($ <on>)
     (let ((statement (add-reply-port
                       (.statement o)
                       (if port port ((compose .port car ast:trigger*) o))
                       ((compose ast:provides? .port car ast:trigger*) o))))
       (clone o #:statement statement)))
    (($ <guard>)
     (clone o #:statement (add-reply-port (.statement o) port block?)))
    (($ <compound>)
     (let ((elements (map (cute add-reply-port <> port block?)
                          (ast:statement* o))))
       (clone o #:elements elements)))
    (($ <behavior>)
     (clone o #:statement (add-reply-port (.statement o) port block?)
            #:functions (add-reply-port (.functions o) port block?)))
    ((? (%normalize:short-circuit?)) o)
    (($ <component>)
     (let ((behavior (add-reply-port (.behavior o)
                                     (and (= 1 (length (ast:provides-port* o)))
                                          (ast:provides-port o))
                                     block?)))
       (clone o #:behavior behavior)))
    (($ <interface>)
     o)
    ((? (is? <ast>))
     (tree:shallow-map (cut add-reply-port <> port block?) o))
    (_
     o)))

(define* ((binding-into-blocking #:optional (locals '())) o)

  (define (formal-binding->formal o)
    (match o
      (($ <formal-binding>)
       (make <formal> #:name (.name o) #:type.name (.type.name o)
             #:direction (.direction o)))
      (_
       o)))

  (define ((passdown-formal-bindings formal-bindings) o)
    (match o
      ((and ($ <compound>) (? ast:declarative?))
       (let ((elements (map (passdown-formal-bindings formal-bindings)
                            (ast:statement* o))))
         (clone o #:elements elements)))
      (($ <declarative-illegal>) o)
      ((? ast:declarative?)
       (let ((statement ((passdown-formal-bindings formal-bindings) (.statement o))))
         (clone o #:statement statement)))
      (($ <compound>)
       (clone o #:elements (cons formal-bindings (ast:statement* o))))
      (_
       (make <compound> #:elements (cons formal-bindings (list o))))))

  (match o
    (($ <on>)
     (let* ((trigger ((compose car ast:trigger*) o))
            (on-formals (ast:formal* trigger))
            (formal-bindings (filter (is? <formal-binding>) on-formals))
            (formal-bindings (and (pair? formal-bindings)
                                  (make <out-bindings>
                                    #:elements formal-bindings
                                    #:port (.port trigger))))
            (on-formals (map formal-binding->formal on-formals)))
       (if (not formal-bindings) o
           (let* ((formals (make <formals> #:elements on-formals))
                  (trigger (clone trigger #:formals formals))
                  (triggers (clone (.triggers o) #:elements (list trigger)))
                  (statement ((passdown-formal-bindings formal-bindings)
                              (.statement o))))
             (clone o #:triggers triggers #:statement statement)))))
    (($ <behavior>)
     (clone o #:statement ((binding-into-blocking '()) (.statement o))))
    ((? (%normalize:short-circuit?))
     o)
    (($ <component>)
     (clone o #:behavior ((binding-into-blocking) (.behavior o))))
    (($ <interface>)
     o)
    ((? (is? <ast>))
     (tree:shallow-map (binding-into-blocking locals) o))
    (_ o
       )))

(define* (remove-otherwise o #:optional (keep-annotated? #t) (statements '()))
  "Replace otherwise with the negated conjunction of every other guard at
the same level."
  (define (virgin-otherwise? x)
    (or (equal? x "otherwise") (eq? x *unspecified*)))
  (match o
    ((? ast:imperative?)
     o)
    ((and ($ <guard>)
          (= .expression (and ($ <otherwise>) (= .value value)))
          (= .statement statement)) (=> failure)
          (if (or (and keep-annotated?
                       (not (virgin-otherwise? value)))
                  (null? statements))
              (failure)
              (clone o
                     #:expression (not-or-guards statements)
                     #:statement (remove-otherwise statement keep-annotated?))))
    ((and ($ <compound>) (= ast:statement* (statements ...)))
     (let ((elements (map (cute remove-otherwise <> keep-annotated? statements)
                          statements) ))
       (clone o #:elements elements)))
    (($ <skip>)
     o)
    (($ <functions>)
     o)
    ((? (%normalize:short-circuit?))
     o)
    ((and (? (is? <component>) (= .behavior behavior)))
     (let ((behavior (remove-otherwise behavior keep-annotated? statements)))
       (clone o #:behavior behavior)))
    ((and (? (is? <interface>) (= .behavior behavior)))
     (let ((behavior (remove-otherwise behavior keep-annotated? statements)))
       (clone o #:behavior behavior)))
    ((? (is? <ast>))
     (tree:shallow-map (cute remove-otherwise <> keep-annotated? statements) o))
    (_
     o)))

(define (remove-location o)
  "Remove locations from types, events, formals, signatures, ports."
  (match o
    (($ <interface>)
     (clone o #:events (remove-location (.events o))))
    (($ <component>)
     (clone o #:ports (remove-location (.ports o))))
    (($ <foreign>)
     (clone o #:ports (remove-location (.ports o))))
    (($ <instance>)
     o)
    (($ <system>)
     (clone o
            #:ports (remove-location (.ports o))
            #:bindings (remove-location (.bindings o))))
    (($ <event>)
     (clone o
            #:location #f
            #:signature (remove-location (.signature o))))
    (($ <port>)
     (clone o
            #:formals (remove-location (.formals o))))
    (($ <binding>)
     (clone o
            #:left (remove-location (.left o))
            #:right (remove-location (.right o))))
    (($ <signature>)
     (clone o
            #:location #f
            #:formals (remove-location (.formals o))))
    (($ <root>)
     (tree:shallow-map remove-location o))
    ((? (is? <namespace>))
     (tree:shallow-map remove-location o))
    ((? (is? <tree:locationed>))
     (clone o #:location #f))
    ((? (is? <ast>))
     (tree:shallow-map remove-location o))
    (_
     o)))

(define (remove-behavior o)
  "Remove behavior from models."
  (match o
    (($ <interface>)
     (clone o #:behavior #f))
    (($ <component>)
     (clone o #:behavior #f))
    ((? (is? <namespace>))
     (tree:shallow-map remove-behavior o))
    (_
     o)))

(define (add-explicit-temporaries o)
  "Make implicit temporary values in action, call, if, reply, and return
expressions explicit."

  (define (replace-expression old o reference)
    (cond ((eq? old o)
           reference)
          ((is-a? o <expression>)
           (tree:shallow-map (cute replace-expression old <> reference) o))
          ((is-a? o <arguments>)
           (tree:shallow-map (cute replace-expression old <> reference) o))
          (else
           o)))

  (define (add-temporary o)
    (let* ((expression (.expression o))
           (variable-expression (add-temporary? o))
           (type (ast:type variable-expression))
           (local-type? (eq? (tree:ancestor type <model>)
                             (tree:ancestor o <model>)))
           (type-name (cond
                       ((is-a? type <subint>) (.name (ast:type (make <int>))))
                       (local-type? (.name type))
                       (else (ast:dotted-name type))))
           (name (temp-name o))
           (location (.location o))
           (behavior (tree:ancestor o <behavior>))
           (parent (or (tree:ancestor o <statement>)
                       (tree:ancestor o <behavior>)))
           (temporary (make <variable>
                        #:name name
                        #:type.name type-name
                        #:expression variable-expression
                        #:location location))
           (reference (make <reference> #:name name #:location location))
           (o (tree:shallow-map
               (cute replace-expression variable-expression <> reference)
               o)))
      (graft parent (make <compound>
                      #:elements (list temporary o)
                      #:location (.location o)))))

  (define (split+add-temporaries o)
    (if (not (split-complex? o)) (add-temporary o)
        (let ((o (split-complex-expressions o)))
          (if (add-temporary? o) (add-explicit-temporaries o)
              o))))

  (match o
    (($ <if>)
     (let* ((expression (.expression o))
            (model (tree:ancestor expression <model>))
            (split-expression? (or (add-temporary? (.expression o))
                                   (split-complex? (.expression o)))))
       (if split-expression? (let ((o (split+add-temporaries o)))
                               (add-explicit-temporaries o))
           (let* ((then (add-explicit-temporaries (.then o)))
                  (else (add-explicit-temporaries (.else o)))
                  (location (.location o))
                  (o (graft o
                            #:expression expression
                            #:then then
                            #:else else)))
             (if (add-temporary? o) (split+add-temporaries o)
                 o)))))
    ((or ($ <assign>) ($ <call>) ($ <reply>) ($ <return>) ($ <variable>))
     (let ((split? (or (split-complex? o) (add-temporary? o))))
       (if (not split?) o
           (let ((o (split+add-temporaries o)))
             (add-explicit-temporaries o)))))
    (($ <defer>)
     (let* ((statement (.statement o))
            (statement (add-explicit-temporaries statement)))
       (clone o #:statement statement)))
    ((and ($ <compound>) (? ast:declarative?))
     (clone o #:elements (map add-explicit-temporaries (ast:statement* o))))
    (($ <compound>)
     (let ((statements
            (let loop ((statements (ast:statement* o)))
              (match statements
                (()
                 '())
                ((statement rest ...)
                 (match statement
                   ((or ($ <compound>) ($ <defer>) ($ <if>))
                    (cons (add-explicit-temporaries statement) (loop rest)))
                   ((or (? add-temporary?) (? split-complex?))
                    (let ((split (add-explicit-temporaries statement)))
                      (match split
                        (($ <compound>)
                         (append (.elements split) (loop rest)))
                        ((? (is? <statement>))
                         (cons split (loop rest))))))
                   (_
                    (cons statement (loop rest)))))))))
       (clone o #:elements statements)))
    (($ <function>)
     (clone o #:statement (add-explicit-temporaries (.statement o))))
    (($ <behavior>)
     (clone o
            #:functions (add-explicit-temporaries (.functions o))
            #:statement (add-explicit-temporaries (.statement o))))
    ((? (%normalize:short-circuit?))
     o)
    (($ <interface>)
     (clone o #:behavior (add-explicit-temporaries (.behavior o))))
    (($ <component>)
     (clone o #:behavior (add-explicit-temporaries (.behavior o))))
    ((? (is? <ast>))
     (tree:shallow-map add-explicit-temporaries o))
    (_
     o)))

(define (add-determinism-temporaries o)
  "Make evaluation order of noisy expressions deterministic by adding
explitic temporaries."
  (parameterize ((%noisy-ordering? #t))
    (add-explicit-temporaries o)))

(define (split-complex-expressions o)
  "Split && and || into an if with a simple expression.  Depends on the
add-explicit-temporaries transformation for splitting argument lists."

  (define* (split o #:key not-e)
    (let* ((parent (tree:parent o))
           (expression (.expression o))
           (expression (simplify-expression expression))
           (o (graft* parent o #:expression expression)))
      (match expression
        ((and ($ <and>) (= .left left) (= .right right))
         (let* ((then (cond (not-e
                             (.then o))
                            (else
                             (clone o #:expression right))))
                (false (make <literal> #:value "false"))
                (left (if (not not-e) left
                          (clone not-e #:expression left)))
                (left (simplify-expression left))
                (else (cond ((and not-e (is-a? o <if>))
                             (clone o #:expression
                                    (clone not-e #:expression right)))
                            ((is-a? o <if>)
                             (.else then))
                            (else
                             (clone o #:expression false))))
                (simple (graft parent (make <if>
                                        #:expression left
                                        #:then then
                                        #:else else
                                        #:location (.location o)))))
           (split-complex-expressions simple)))
        ((and (? (const not-e))
              ($ <or>) (= .left left) (= .right right))
         (let* ((then (cond (not-e
                             (clone o #:expression
                                    (clone not-e #:expression right)))
                            (else
                             (clone o #:expression right))))
                (false (make <literal> #:value "false"))
                (left (if (not not-e) left
                          (clone not-e #:expression left)))
                (left (simplify-expression left))
                (else (cond ((is-a? o <if>)
                             (.else then))
                            (else
                             (clone o #:expression false))))
                (simple (graft parent (make <if>
                                        #:expression left
                                        #:then then
                                        #:else else
                                        #:location (.location o)))))
           (split-complex-expressions simple)))
        ((and ($ <or>) (= .left left) (= .right right))
         (let* ((true (make <literal> #:value "true"))
                (then (cond ((is-a? o <if>)
                             (.then o))
                            (else
                             (clone o #:expression true))))
                (else (clone o #:expression right))
                (left (simplify-expression left))
                (simple (graft parent (make <if>
                                        #:expression left
                                        #:then then
                                        #:else else
                                        #:location (.location o)))))
           (split-complex-expressions simple)))
        (($ <group>)
         (let* ((expression-expression (.expression expression))
                (o (graft o #:expression expression-expression)))
           (split o #:not-e not-e)))
        (($ <not>)
         (let* ((expression-expression (.expression expression))
                (o (graft o #:expression expression-expression)))
           (split o #:not-e expression)))
        ((? (const not-e))
         (let* ((expression (.expression o))
                (group? (or (is-a? expression <binary>)
                            (is-a? expression <field-test>)))
                (expression (if (not group?) expression
                                (make <group> #:expression expression)))
                (expression (clone not-e #:expression expression)))
           (graft o #:expression expression)))
        (_
         o))))

  (define split?
    (conjoin (disjoin (is? <if>)
                      (is? <assign>)
                      (is? <reply>)
                      (is? <return>)
                      (is? <variable>))
             split-complex?))

  (define (split+ o)
    (match o
      (($ <variable>)
       (let* ((parent (tree:parent o))
              (expression (.expression o))
              (expression (simplify-expression expression))
              (o (graft* parent o #:expression expression))
              (variable assign (split-variable o))
              (o (split (graft assign #:expression expression)))
              (parent (tree:ancestor o <statement>)))
         (graft parent (make <compound>
                         #:elements (list variable o)
                         #:location (.location o)))))
      (_ (split o))))

  (tree:transform o split? split+))

(define* (group-expressions o #:optional (group (list)))
  (match o
    ((? (const (find (cute is-a? o <>) group)))
     (let* ((parent (tree:parent o))
            (o (tree:shallow-map (cute group-expressions <> group) o))
            (o (graft* parent o)))
       (match (tree:parent o)
         (($ <group>) o)
         ((? (is? <expression>)) (make <group> #:expression o))
         (else o))))
    ((and (? (is? <not>))
          (= .expression (and expression (or (? (is? <binary>))
                                             (? (is? <field-test>))))))
     (let ((expression (tree:shallow-map (cute group-expressions <> group) expression)))
       (graft o #:expression (make <group> #:expression expression))))
    (($ <canonical-on>)
     (let* ((guard (group-expressions (.guard o) group))
            (statement (group-expressions (.statement o) group)))
       (graft o #:guard guard #:statement statement)))
    (($ <function>)
     (clone o #:statement (group-expressions (.statement o) group)))
    (($ <behavior>)
     (clone o
            #:functions (group-expressions (.functions o) group)
            #:statement (group-expressions (.statement o) group)))
    ((? (%normalize:short-circuit?))
     o)
    (($ <interface>)
     (clone o #:behavior (group-expressions (.behavior o) group)))
    (($ <component>)
     (clone o #:behavior (group-expressions (.behavior o) group)))
    ((? (is? <ast>))
     (tree:shallow-map (cute group-expressions <> group) o))
    (_
     o)))

(define (simplify-guard-expressions o)
  "Simplify guard expressions by using static analysis."
  (match o
    (($ <behavior>)
     (clone o
            #:statement
            ((compose
              (cute make <declarative-compound> #:elements <>)
              (cute map canonical-on->guard <>)
              (cute map (cute group-expressions <>
                              (list <and> <field-test> <or>))
                    <>)
              (cute map simplify-guard <>)
              statement->canonical-on
              .statement
              ) o)))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree:shallow-map simplify-guard-expressions o))
    (_
     o)))

;; (define-method (tag-imperative-blocks (o <root>))
;;   (define (location o)
;;     (or (.location o)
;;         (location (tree:parent o))))
;;   (define (add-tag o)
;;     (match o
;;       ((? ast:illegal?)
;;        o)
;;       (($ <compound>)
;;        (let ((tag (make <tag> #:location (location o))))
;;          (graft o #:elements (cons tag (ast:statement* o)))))
;;       (_
;;        (let* ((location (location o))
;;               (tag (make <tag> #:location location))
;;               (elements (list tag o)))
;;          (graft (tree:parent o) (make <compound>
;;                               #:elements elements
;;                               #:location location))))))

;;   (define compound? (is? <compound>))
;;   (define (compound:add-tag o)
;;     (let ((tag (make <tag> #:location (location o))))
;;       (graft o #:elements (cons tag (ast:statement* o)))))

;;   (define other? (negate (disjoin (is? <compound>) ast:illegal?)))
;;   (define (other:add-tag o)
;;     (let* ((location (location o))
;;            (tag (make <tag> #:location location))
;;            (elements (list tag o)))
;;       (graft (tree:parent o) (make <compound>
;;                            #:elements elements
;;                            #:location location))))


;;   (define return?
;;     (disjoin
;;      (conjoin (is? <compound>)
;;               (compose (cute any (disjoin (is? <return>) return?) <>)
;;                        .elements))
;;      (conjoin (is? <if>)
;;               (disjoin (compose return? .then)
;;                        (compose (and=> <> return?) .else)))))
;;   (define (return:add-tag o)
;;     (let* ((location (location o))
;;            (tag (make <tag> #:location location)))
;;       (list o tag)))

;;   (tree:transform o `((,compound? . ,compound:add-tag)
;;                       (,other? . ,other:add-tag)
;;                       (,return? . ,compound:add-return-tag))))

(define (tag-imperative-blocks o)
  "Mark imperative statement blocks with a unique tag for unreachable
code check."
  (define (location o)
    (or (.location o)
        (location (tree:parent o))))
  (define (add-tag-imperative o)
    (if (ast:imperative? o)
        (match o
          ((? ast:illegal?)
           o)
          (($ <compound>)
           (let ((tag (make <tag> #:location (location o))))
             (graft o #:elements (cons tag (ast:statement* o)))))
          (_
           (let* ((location (location o))
                  (tag (make <tag> #:location location))
                  (elements (list tag o)))
             (graft (tree:parent o)
                    (make <compound>
                      #:elements elements #:location location)))))
        o))

  (match o
    ((or ($ <blocking>) ($ <defer>) ($ <function>) ($ <guard>) ($ <on>))
     (let* ((statement (.statement o))
            (statement (add-tag-imperative (tag-imperative-blocks statement))))
       (graft o #:statement statement)))
    (($ <if>)
     (let ((then (add-tag-imperative (tag-imperative-blocks (.then o))))
           (else (and=> (tag-imperative-blocks (.else o)) add-tag-imperative)))
       (graft o #:then then #:else else)))
    (($ <compound>)
     (graft o #:elements (map tag-imperative-blocks (ast:statement* o))))
    ((? (is? <statement>))
     o)
    (($ <behavior>)
     (clone o #:statement (tag-imperative-blocks (.statement o))
            #:functions (tag-imperative-blocks (.functions o))))
    ((? (%normalize:short-circuit?))
     o)
    (($ <component>)
     (clone o #:behavior (tag-imperative-blocks (.behavior o))))
    (($ <interface>)
     (clone o #:behavior (tag-imperative-blocks (.behavior o))))
    ((? (is? <type>))
     o)
    ((? (is? <ast>))
     (tree:shallow-map tag-imperative-blocks o))
    (_ o)))
