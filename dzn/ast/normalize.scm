;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2021, 2022, 2023, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
;;; Copyright © 2018, 2020, 2022, 2023, 2024 Paul Hoogendijk <paul@dezyne.org>
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
  #:use-module (dzn ast)
  #:use-module (dzn misc)

  #:export (%normalize:short-circuit?
            add-defer-end
            add-explicit-temporaries
            add-function-return
            add-reply-port
            binding-into-blocking
            extract-call
            inline-expression-functions
            invariant:include-guard-expressions
            make-a=>b-expression
            not-or-guards
            normalize:event
            normalize:event+illegals
            normalize:state
            normalize:state+illegals
            purge-data
            remove-behavior
            remove-location
            remove-invariant
            remove-otherwise
            simplify-guard-expressions
            split-variable
            tag-imperative-blocks))

;; Should transformation stop here?
(define %normalize:short-circuit? (make-parameter (const #f)))

;; A prefix is a normalized combination of the declarative statements
;; that ... the imperative statement.  It is a triple that combines
;; "guard", "on", and "blocking" leading to the statement.
(define-immutable-record-type <triple>
  (make-triple on guard blocking? statement)
  triple?
  (on triple-on)
  (guard triple-guard)
  (blocking? triple-blocking?)
  (statement triple-statement))

(define (write-triple triple port)
  "Write TRIPLE on PORT."
  (display "#<triple " port)
  (format port "on: ~a" (triple-on triple))
  (format port "guard: ~a" (triple-guard triple))
  (format port "blocking?: ~a" (triple-blocking? triple))
  (format port "statement: ~a" (triple-statement triple))
  (format port " >"))


;;;
;;; Utilities and predicates.
;;;
(define-method (split-variable (o <variable>))
  (let* ((default (ast:default-value o))
         (variable (clone o #:expression default))
         (name (.name o))
         (assign (make <assign> #:variable.name name
                       #:expression (.expression o)))
         (location (.location o))
         (assign (clone assign #:location location)))
    (values variable assign)))

(define temp-name
  (let ((count -1))
    (lambda (o)
      (set! count (1+ count))
      (format #f "dzn_tmp~a" count))))

(define (temporaries o)
  "The mCRL2 has no support for anonymous temporary variables, Dezyne does
as do all programming languages, so we must determine which statements
require a temporary variable."
  (define action/call?
    (disjoin (is? <action>) (is? <call>)))
  (define temporary?
    (conjoin (disjoin (is? <action>)
                      (is? <binary>)
                      (is? <call>))
             (compose pair?
                      (cute tree-collect action/call? <>))
             (disjoin
              (cute as <> <arguments>)
              (cute ast:parent <> <arguments>)
              (compose (cute as <> <binary>) .parent)
              (compose (cute ast:parent <> <binary>) .parent))))
  (cond ((or (is-a? o <action>) (is-a? o <call>))
         (tree-collect temporary? o))
        ((or (is-a? o <assign>) (is-a? o <variable>))
         (append
          (tree-collect temporary? o)
          (map .expression
               (tree-collect
                (conjoin
                 (is? <not>)
                 (compose pair? (cute tree-collect action/call? <>)))
                o))))
        ((is-a? o <if>)
         (tree-collect action/call? (.expression o)))
        ((or (as o <expression>)
             (and (is-a? o <reply>) (.expression o))
             (and (is-a? o <return>) (.expression o)))
         =>
         (cute tree-collect action/call? <>))
        (else
         '())))

(define (add-temporary? o)
  (match (temporaries o)
    ((h t ...)
     (let ((p (.parent h)))
       (and (not (or (as p <and>) (ast:parent p <and>)
                     (as p <or>) (ast:parent p <or>)))
            h)))
    (_
     #f)))

(define (temporaries* o)
  "In C derived languages the evaluation order of the arguments is
implementation defined, in Dezyne we assume a left to right order. This
requires the introduction of temporaries for function calls."
  (define action/call?
    (disjoin (is? <action>) (is? <call>)))
  (define >1-argument-action/call?
    (compose (cute > <> 1)
             length
             (cute filter (compose pair?
                                   (cute tree-collect action/call? <>))
                   <>)
             ast:argument*))
  (define >1-action/call?
    (compose (cute > <> 1)
             length
             (cute tree-collect action/call? <>)))
  (let* ((arguments (tree-collect
                     (conjoin (is? <arguments>)
                              (compose (cute > <> 1) length .elements)
                              >1-action/call?)
                     o))
         (arguments (filter >1-argument-action/call? arguments))
         (arguments (append-map ast:argument* arguments))
         (expressions (tree-collect
                       (conjoin (disjoin (is? <minus>) (is? <plus>))
                                >1-action/call?)
                       o))
         (expressions (append-map
                       (lambda (x)
                         (let ((expressions (list (.left x) (.right x))))
                           (filter
                            (compose pair?
                                     (cute tree-collect action/call? <>))
                            expressions)))
                       expressions)))
    (append arguments expressions)))

(define (add-temporary*? o)
  (let ((temporaries (temporaries o)))
    (match temporaries
      ((h t ...)
       (let ((p (.parent h)))
         (and (not (or (as p <and>) (ast:parent p <and>)
                       (as p <or>) (ast:parent p <or>)))
              h)))
      (_
       #f))))


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
    (null? (tree-collect (disjoin (is? <action>) (is? <call>)) o)))
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
     (clone o #:left (simplify-expression (.left o))
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
;;; Normalizations.
;;;
(define (triples:->compound-guard-on triples)
  (let* ((st (map (lambda (t)
                    (let* ((on (triple-on t))
                           (guard (triple-guard t))
                           (statement (triple-statement t))
                           (blocking (triple-blocking? t))
                           (statement (if blocking (clone blocking #:statement statement)
                                          statement)))
                      (clone guard #:statement (clone on #:statement statement))))
                  triples)))
    (make <declarative-compound> #:elements st)))

(define-method (statement->canonical-on (o <compound>))
  (define (imperative->canonical-ons imperative)
    (let* ((path (ast:path imperative (compose (is? <behavior>) .parent)))
           (blocking (find (is? <blocking>) path))
           (guards (filter (is? <guard>) path))
           (expression (and-expressions (map .expression guards)))
           (guard (make <guard> #:expression expression))
           (on (find (is? <on>) path))
           (triggers (ast:trigger* on)))
      (define (make-on trigger)
        (let ((canonical-on (make <canonical-on>
                              #:blocking (and (ast:provides? trigger) blocking)
                              #:guard guard
                              #:trigger trigger
                              #:statement imperative)))
          (clone canonical-on #:parent (.parent on))))
      (map make-on triggers)))
  (if (null? (ast:statement* o)) '()
      (let ((imperatives (tree-collect-filter
                          (conjoin (is? <ast>)
                                   (disjoin ast:declarative?
                                            (compose ast:declarative? .parent)))
                          ast:imperative?
                          o)))
        (append-map imperative->canonical-ons imperatives))))

(define-method (canonical-on->triple (o <canonical-on>))
  (let* ((blocking (.blocking o))
         (guard (.guard o))
         (trigger (.trigger o))
         (triggers (make <triggers> #:elements (list trigger)))
         (statement (.statement o))
         (on (make <on> #:statement statement #:triggers triggers)))
    (make-triple on guard blocking statement)))

(define (make-declarative-illegal/illegal trigger)
  (make (cond ((or (ast:parent trigger <interface>)
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
               (model (ast:parent trigger <model>))
               (on (make <canonical-on>
                     #:guard guard
                     #:trigger trigger
                     #:statement (make-illegal trigger)))
               (on (clone on #:parent model)))
          (append ons (list on))))))

(define-method (model->triggers (o <interface>))
  (define (event->trigger event)
    (let ((trigger (make <trigger> #:event.name (.name event)
                         #:location (.location o))))
      (clone trigger #:parent (.parent event))))
  (map event->trigger (ast:in-event* o)))

(define-method (model->triggers (o <component-model>))
  (define (port+event->trigger port event)
    (let ((trigger (make <trigger>
                     #:port.name (.name port)
                     #:event.name (.name event)
                     #:location (.location o))))
      (clone trigger #:parent o)))
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

(define-method (add-the-end (o <canonical-on>))
  (let ((statement (.statement o)))
    (if (ast:illegal? statement) o
        (let ((statement (ast:add-statement statement (make <the-end>))))
          (clone o #:statement statement)))))

(define-method (add-void-reply (o <canonical-on>))
  (let* ((trigger (.trigger o))
         (port (.port trigger))
         (statement (.statement o))
         (provides? (and port (ast:provides? port)))
         (model (ast:parent o <model>))
         (reply? (and (not (ast:typed? trigger))
                      (not (.blocking o))
                      (or (and (is-a? model <interface>)
                               (not (ast:modeling? trigger)))
                          (and provides?
                               (null? (tree-collect
                                       (conjoin
                                        (is? <reply>)
                                        (disjoin (negate .port)
                                                 (compose (cute ast:eq? port <>)
                                                          .port)))
                                       statement)))))))
    (if (not reply?) o
        (let ((statement (ast:add-statement* (.statement o) (make <reply>))))
          (clone o #:statement statement)))))

(define-method (illegal->declarative-illegal (o <canonical-on>))
  (let ((declarative? (and (ast:illegal? (.statement o))
                           (or (is-a? (ast:parent o <model>) <interface>)
                               (ast:provides? (.trigger o))))))
    (if (not declarative?) o
        (clone o #:statement (make <declarative-illegal>)))))

(define (remove-invariant o)
  "Remove invariants from behavior."
  (match o
    ((? (is? <ast-list>))
     (clone o #:elements (filter-map remove-invariant (.elements o))))
    (($ <invariant>)
     #f)
    (($ <guard>)
     (if (is-a? (.statement o) <invariant>) #f
         o))
    ((? (%normalize:short-circuit?))
     o)
    (($ <component>)
     (clone o #:behavior (remove-invariant (.behavior o))))
    ((? (is? <ast>)) (tree-map remove-invariant o))
    (_ o)))

(define-method (make-a=>b-expression (a <expression>) (b <expression>))
  (make <or> #:left (make <not> #:expression a) #:right b))

(define-method (invariant:include-guard-expressions (o <invariant>))
  "Include guard expression into invariants."
  (let ((guards (filter (is? <guard>) (ast:path o))))
    (if (null? guards) o
        (let* ((expressions (map .expression guards))
               (parent (.parent o))
               (expression (make-a=>b-expression (and-expressions expressions)
                                                 (.expression o))))
          (clone o #:expression expression)))))

(define-method (make-behavior-invariant (o <behavior>))
  (let* ((invariants (tree-collect (is? <invariant>) o))
         (invariants (map invariant:include-guard-expressions invariants))
         (invariants (map (cute group-expressions <>
                                (list <and> <field-test> <or>))
                          invariants))
         (expression (and-expressions (map .expression invariants))))
    (make <invariant> #:expression expression)))

(define (normalize:state o)
  "Push guards up, thereby splitting the body of a trigger into multiple
guarded occurrences."
  (match o
    (($ <behavior>)
     (clone o
            #:statement
            ((compose
              triples:->compound-guard-on
              (cute map canonical-on->triple <>)
              (cute map (cute group-expressions <>
                              (list <and> <field-test> <or>))
                    <>)
              (cute map simplify-guard <>)
              statement->canonical-on
              remove-invariant
              .statement
              ) o)
            #:functions
            (group-expressions (.functions o) (list <and> <field-test> <or>))
            #:invariant (make-behavior-invariant o)))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree-map normalize:state o))
    (_
     o)))

(define (normalize:state+illegals o)
  (match o
    (($ <behavior>)
     (let ((model (ast:parent o <model>)))
       (clone o
              #:statement
              ((compose
                triples:->compound-guard-on
                (cute map canonical-on->triple <>)
                (cute map (cute group-expressions <>
                                (list <and> <field-test> <or>))
                      <>)
                (cute map simplify-guard <>)
                (cut implicit-illegals->explicit-illegals model <>
                     #:make-illegal make-declarative-illegal/illegal)
                (cute map add-the-end <>)
                (cute map add-void-reply <>)
                (cute map illegal->declarative-illegal <>)
                statement->canonical-on
                remove-invariant
                .statement
                ) o)
              #:functions
              (group-expressions (.functions o) (list <and> <field-test> <or>))
              #:invariant (make-behavior-invariant o))))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree-map normalize:state+illegals o))
    (_
     o)))

(define* (triples:->on-guard* triples #:key otherwise?)
  (define ((trigger-equal? trigger) triple)
    (let ((t ((compose car ast:trigger* triple-on) triple)))
      (and (equal? (.port.name t) (.port.name trigger)) (equal? (.event.name t) (.event.name trigger)))))
  (let* ((sorted-triples
          (let loop ((triples triples))
            (if (null? triples) '()
                (let* ((trigger ((compose car ast:trigger* triple-on car)
                                 triples))
                       (shared rest
                               (partition (trigger-equal? trigger) triples)))
                  (cons shared (loop rest))))))
         (ons (map
               (lambda (triples)
                 (let* ((on ((compose triple-on car) triples))
                        (guards (map (lambda (t)
                                       (let* ((statement (triple-statement t))
                                              (blocking (triple-blocking? t))
                                              (statement (if blocking (clone blocking #:statement statement)
                                                             statement)))
                                         (clone (triple-guard t) #:statement statement)))
                                     triples))
                        ;; code need <otherwise>
                        (otherwise (list (make <guard> #:expression (make <otherwise>) #:statement (make <illegal>))))
                        (otherwise? (and otherwise?
                                         (not (find (compose ast:literal-true? .expression) guards))))
                        (guards (if otherwise? (append guards otherwise)
                                    guards)))
                   ;; FIXME: up code to use <declarative-compound>
                   ;;(clone on #:statement (make <declarative-compound> #:elements guards))
                   (clone on #:statement (make <compound> #:elements guards))))
               sorted-triples)))
    ons))

(define (normalize:event o)
  "Merge all occurrences of a trigger into a single unguarded `on',
i.e., pushing guards into the body of the trigger."
  (match o
    (($ <behavior>)
     (clone o #:statement
            ((compose
              (cute make <compound> #:elements <>)
              triples:->on-guard*
              (cute map canonical-on->triple <>)
              (cute map (cute group-expressions <>
                              (list <and> <field-test> <or>))
                    <>)
              (cute map simplify-guard <>)
              (cute map alpha-rename <>)
              statement->canonical-on
              .statement
              ) o)
            #:functions
            (group-expressions (.functions o) (list <and> <field-test> <or>))))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree-map normalize:event o))
    (_
     o)))

(define (normalize:event+illegals o)
  (match o
    (($ <behavior>)
     (let ((model (ast:parent o <model>)))
       (clone o
              #:statement
              ((compose
                (cute make <compound> #:elements <>)
                (cut triples:->on-guard* <> #:otherwise? #t)
                (cute map canonical-on->triple <>)
                (cute map (cute group-expressions <>
                                (list <and> <field-test> <or>))
                      <>)
                (cute map simplify-guard <>)
                (cute map alpha-rename <>)
                (cute implicit-illegals->explicit-illegals model <>)
                statement->canonical-on
                .statement
                ) o)
              #:functions
              (group-expressions (.functions o) (list <and> <field-test> <or>)))))
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast>))
     (tree-map normalize:event+illegals o))
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
               (not (is-a? (.parent o) <variables>)))))
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
      (($ <var>)
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
       (tree-map (rename mapping) o))
      (_
       o)))

  (let* ((trigger (.trigger o))
         (event (.event trigger))
         (formals ((compose ast:formal* .signature) event))
         (formals-ok? (or (pair? (ast:formal* trigger))
                          (null? formals)))
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
         (model (ast:parent o <model>))
         (members (map .name (ast:variable* model)))
         (locals (map .name (tree-collect (is? <variable>) (.statement o))))
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

(define (purge-data o)
  "Remove every `extern' data variable and reference."
  (define (parent-location o)
    (or (.location o) (parent-location (.parent o))))
  (match o
    (($ <out-bindings>)
     (clone o #:elements '()))
    ((? (is? <ast-list>))
     (clone o #:elements (filter-map purge-data (.elements o))))
    (($ <data>)
     #f)
    (($ <event>)
     (clone o #:signature (purge-data (.signature o))))
    (($ <function>)
     (clone o
            #:signature (purge-data (.signature o))
            #:statement (purge-data (.statement o))))
    (($ <signature>)
     (let ((type (.type o)))
       (clone o #:type.name (if (is-a? type <extern>) "void" (.type.name o))
              #:formals (purge-data (.formals o)))))
    (($ <reply>)
     (let* ((expression (and=> (.expression o) purge-data))
            (expression (or expression (make <literal>)))
            (void? (compose (disjoin (is? <void>) (is? <extern>)) ast:type))
            (remove? (conjoin void? (negate (is? <literal>)))))
       (if (remove? expression) expression
           (clone o #:expression expression))))
    (($ <return>)
     (let* ((expression (and=> (.expression o) purge-data))
            (expression (or expression (make <literal>))))
       (clone o #:expression expression)))
    (($ <action>)
     (clone o #:arguments (purge-data (.arguments o))))
    (($ <call>)
     (clone o #:arguments (purge-data (.arguments o))))
    (($ <trigger>)
     (clone o #:formals (make <formals>)))
    (($ <extern>)
     #f)
    (($ <formal>)
     (let ((type (.type o)))
       (and type (not (is-a? type <extern>)) o)))
    ((or ($ <assign>) ($ <variable>))
     (let* ((type (ast:type o))
            (expression (and=> (.expression o) purge-data)))
       (if (not (is-a? type <extern>)) (clone o #:expression expression)
           (let ((actions/calls (tree-collect
                                 (disjoin (is? <action>) (is? <call>))
                                 expression)))
             (if (pair? actions/calls) expression
                 (let* ((skip? (negate (disjoin (is? <compound>)
                                                (is? <variables>))))
                        (parent (.parent o)))
                   (and (skip? parent)
                        (make <skip> #:location (parent-location o)))))))))
    (($ <var>)
     (let* ((variable (.variable o))
            (type (and variable (.type variable))))
       (and type (not (is-a? type <extern>)) o)))
    ((? (%normalize:short-circuit?))
     o)
    (($ <interface>)
     (clone o
            #:types (purge-data (.types o))
            #:events (purge-data (.events o))
            #:behavior (purge-data (.behavior o))))
    (($ <component>)
     (clone o #:behavior (purge-data (.behavior o))))
    ((? (is? <ast>)) (tree-map purge-data o))
    (_ o)))

(define (add-function-return o)
  "For each void function make implicit returns explicit."
  (define* (add-return o #:key (loc o))
    (match o
      (($ <compound>)
       (clone o #:elements (add-return (ast:statement* o) #:loc o)))
      ((statement ... ($ <return>)) o)
      ((statement ... t) (append o (list (make <return> #:location (.location (.parent t))))))
      ((statement ...) (append o (list (make <return> #:location (.location loc)))))))
  (match o
    (($ <behavior>)
     (clone o #:functions (add-function-return (.functions o))))
    (($ <functions>)
     (clone o #:elements (map add-function-return (ast:function* o))))
    (($ <function>)
     (if (not (is-a? (ast:type o) <void>)) o
         (clone o #:statement (add-return (.statement o)))))
    ((? (%normalize:short-circuit?))
     o)
    (($ <interface>)
     (clone o #:behavior (add-function-return (.behavior o))))
    (($ <component>)
     (clone o #:behavior (add-function-return (.behavior o))))
    ((? (is? <ast>)) (tree-map add-function-return o))
    (_ o)))

(define (extract-call o)
  "Move typed function calls from variable initialization and assignment
to a separate statement, for mCRL2."
  (define (extract-assign/variable-call o call)
    (let ((expression (make <literal> #:value "return_value")))
      (match o
        (($ <assign>)
         (let ((assign (clone o #:expression expression)))
           (list call assign)))
        (($ <variable>)
         (let* ((default (ast:default-value o))
                (variable (clone o #:expression default))
                (assign (make <assign> #:variable.name (.name variable)
                              #:expression expression)))
           (list variable call assign))))))
  (match o
    (($ <behavior>)
     (clone o
            #:functions (extract-call (.functions o))
            #:statement (extract-call (.statement o))))
    (($ <defer>)
     (clone o #:statement (extract-call (.statement o))))
    (($ <blocking>)
     (clone o #:statement (extract-call (.statement o))))
    (($ <on>)
     (clone o #:statement (extract-call (.statement o))))
    (($ <guard>)
     (clone o #:statement (extract-call (.statement o))))
    (($ <functions>)
     (clone o #:elements (map extract-call (ast:function* o))))
    ((and (or ($ <assign>)
              ($ <variable>))
          (= .expression (and ($ <call>) call)))
     (let* ((statements (extract-assign/variable-call o call))
            (compound (make <compound> #:elements statements)))
       (clone compound #:parent (.parent o))))
    (($ <compound>)
     (let ((statements
            (let loop ((statements (ast:statement* o)))
              (match statements
                (()
                 '())
                ((statement rest ...)
                 (match statement
                   ((and (or ($ <assign>)
                             ($ <variable>))
                         (= .expression (and ($ <call>) call)))
                    (let ((statements (extract-assign/variable-call
                                       statement call)))
                      (append
                       statements
                       (loop rest))))
                   (_
                    (cons (extract-call statement)
                          (loop rest)))))))))
       (clone o #:elements statements)))
    ((? (%normalize:short-circuit?))
     o)
    (($ <interface>)
     (clone o #:behavior (extract-call (.behavior o))))
    (($ <component>)
     (clone o #:behavior (extract-call (.behavior o))))
    ((? (is? <ast>)) (tree-map extract-call o))
    (_ o)))

(define-method (inline-expression-functions (o <top>))
  "Inline expression-functions calls."
  (match o
    ((? (%normalize:short-circuit?))
     o)
    ((? (is? <ast-list>))
     (clone o #:elements (map inline-expression-functions (.elements o))))
    (($ <call>)
     (let ((function (.function o)))
       (if (not (is-a? function <expression-function>)) o
           (let* ((expression (.expression function))
                  (expression (inline-expression-functions expression))
                  (parent (.parent o)))
             (clone expression #:parent parent)))))
    (($ <interface>)
     (clone o #:behavior (inline-expression-functions (.behavior o))))
    (($ <component>)
     (clone o #:behavior (inline-expression-functions (.behavior o))))
    ((? (is? <ast>)) (tree-map inline-expression-functions o))
    (_ o)))

(define* (add-defer-end o)
  (match o
    (($ <defer>)
     (let* ((statement (add-defer-end (.statement o)))
            (end (make <defer-end>))
            (statement (ast:add-statement* statement end)))
       (clone o #:statement statement)))
    (($ <blocking>)
     (clone o #:statement (add-defer-end (.statement o))))
    (($ <on>)
     (clone o #:statement (add-defer-end (.statement o))))
    (($ <guard>)
     (clone o #:statement (add-defer-end (.statement o))))
    (($ <compound>)
     (let ((elements (map add-defer-end (ast:statement* o))))
       (clone o #:elements elements)))
    (($ <behavior>)
     (clone o #:statement (add-defer-end (.statement o))
            #:functions (add-defer-end (.functions o))))
    ((? (%normalize:short-circuit?))
     o)
    (($ <component>)
     (clone o #:behavior (add-defer-end (.behavior o))))
    (($ <interface>)
     o)
    ((? (is? <ast>))
     (tree-map add-defer-end o))
    (_ o)))

(define* (add-reply-port o #:optional (port #f) (block? #f)) ;; requires (= 1 (length (.triggers on)))
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
    (($ <behavior>) (clone o #:statement (add-reply-port (.statement o) port block?)
                           #:functions (add-reply-port (.functions o) port block?)))
    ((? (%normalize:short-circuit?)) o)
    (($ <component>) (clone o #:behavior (add-reply-port (.behavior o) (if (= 1 (length (ast:provides-port* o))) (car (ast:provides-port* o)) #f) block?)))
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
      (($ <declarative-illegal>) o)
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

    (($ <behavior>)
     (clone o #:statement ((binding-into-blocking '()) (.statement o))))
    ((? (%normalize:short-circuit?))
     o)
    (($ <component>)
     (clone o #:behavior ((binding-into-blocking) (.behavior o))))
    (($ <interface>) o)
    ((? (is? <ast>)) (tree-map (binding-into-blocking locals) o))
    (_ o)))

(define* (remove-otherwise o #:optional (keep-annotated? #t) (statements '()))
  "Replace otherwise with the negated conjunction of every other guard at
the same level."
  (define (virgin-otherwise? x) (or (equal? x "otherwise") (eq? x *unspecified*))) ;; FIXME *unspecified*
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
              (clone o #:expression (not-or-guards statements)
                     #:statement (remove-otherwise statement keep-annotated?))))
    ((and ($ <compound>) (= ast:statement* (statements ...)))
     (clone o #:elements (map
                          (cute remove-otherwise <> keep-annotated? statements)
                          statements)))
    (($ <skip>)
     o)
    (($ <functions>)
     o)
    ((? (%normalize:short-circuit?))
     o)
    ((and (? (is? <component>) (= .behavior behavior)))
     (clone o #:behavior (remove-otherwise behavior keep-annotated? statements)))
    ((and (? (is? <interface>) (= .behavior behavior)))
     (clone o #:behavior (remove-otherwise behavior keep-annotated? statements)))
    ((? (is? <ast>))
     (tree-map (cute remove-otherwise <> keep-annotated? statements) o))
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
     (tree-map remove-location o))
    ((? (is? <namespace>))
     (tree-map remove-location o))
    ((? (is? <locationed>))
     (clone o #:location #f))
    ((? (is? <ast>))
     (tree-map remove-location o))
    (_ o)))

(define (remove-behavior o)
  "Remove behavior from models."
  (match o
    (($ <interface>)
     (clone o #:behavior #f))
    (($ <component>)
     (clone o #:behavior #f))
    ((? (is? <namespace>))
     (tree-map remove-behavior o))
    (_
     o)))

(define (replace-expression old o var)
  (cond ((ast:eq? old o)
         var)
        ((is-a? o <expression>)
         (tree-map (cute replace-expression old <> var) o))
        ((is-a? o <arguments>)
         (let* ((arguments (ast:argument* o))
                (arguments (filter-map (cute replace-expression old <> var)
                                       arguments)))
           (clone o #:elements arguments)))
        ((is-a? o <arguments>)
         (tree-map (cute replace-expression old <> var) o))
        (else
         o)))

;; FIXME: add-explicit-temporaries
;; this function is overly complicated:
;; - it has too many nested helper functions
;; - which are too dependend
;; - there is too much duplication
;; - and too much (mutual) recursion

(define ((split-complex? temporaries add-temporary?) o)
  (and (pair? (tree-collect (disjoin (is? <and>) (is? <or>)) o))
       (pair? (temporaries o))
       (not (add-temporary? o))))

(define ((split-complex-expressions split-complex?) o)
  "Split && and || into an if with a simple expression.  Depends on the
add-explicit-temporaries transformation for splitting argument lists."
  (let ((split-complex-expressions (split-complex-expressions split-complex?)))
    (define* (split o #:key not-e)
      (let* ((expression (.expression o))
             (expression (simplify-expression expression))
             (o (clone o #:expression expression)))
        (match expression
          ((and ($ <and>) (= .left left) (= .right right))
           (let* ((then (cond (not-e
                               (deep-clone (.then o)))
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
                               (deep-clone (.else then)))
                              (else
                               (clone o #:expression false))))
                  (simple (make <if> #:expression left
                                #:then then
                                #:else else
                                #:location (.location o)))
                  (simple (clone simple #:parent (.parent o))))
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
                               (deep-clone (.else then)))
                              (else
                               (clone o #:expression false))))
                  (simple (make <if> #:expression left
                                #:then then
                                #:else else
                                #:location (.location o)))
                  (simple (clone simple #:parent (.parent o))))
             (split-complex-expressions simple)))
          ((and ($ <or>) (= .left left) (= .right right))
           (let* ((true (make <literal> #:value "true"))
                  (then (cond ((is-a? o <if>)
                               (deep-clone (.then o)))
                              (else
                               (clone o #:expression true))))
                  (else (clone o #:expression right))
                  (left (simplify-expression left))
                  (simple (make <if> #:expression left
                                #:then then
                                #:else else
                                #:location (.location o)))
                  (simple (clone simple #:parent (.parent o))))
             (split-complex-expressions simple)))
          (($ <group>)
           (let ((expression-expression (.expression expression)))
             (split (clone o #:expression expression-expression)
                    #:not-e not-e)))
          (($ <not>)
           (let ((expression-expression (.expression expression)))
             (split (clone o #:expression expression-expression)
                    #:not-e expression)))
          ((? (const not-e))
           (let* ((expression (.expression o))
                  (group? (or (is-a? expression <binary>)
                              (is-a? expression <field-test>)))
                  (expression (if (not group?) expression
                                  (make <group> #:expression expression))))
             (clone o #:expression (clone not-e #:expression expression))))
          (_
           o))))
    (match o
      (($ <if>)
       (let* ((then (split-complex-expressions (.then o)))
              (else-clause (split-complex-expressions (.else o)))
              (o (clone o #:then then #:else else-clause)))
         (if (split-complex? o) (split o)
             o)))
      ((or ($ <assign>) ($ <call>) ($ <reply>) ($ <return>))
       (if (split-complex? o) (split o)
           o))
      (($ <variable>)
       (if (not (split-complex? o)) o
           (let* ((expression (.expression o))
                  (expression (simplify-expression expression))
                  (o (clone o #:expression expression))
                  (variable assign (split-variable o))
                  (o (split (clone assign #:expression expression)))
                  (compound (make <compound> #:location (.location o)))
                  (parent (ast:parent o <statement>))
                  (compound (clone compound #:parent parent)))
             (clone compound #:elements (list variable o)))))
      ((and ($ <compound>) (? ast:declarative?))
       (clone o #:elements (map split-complex-expressions (ast:statement* o))))
      (($ <compound>)
       (let ((statements
              (let loop ((statements (ast:statement* o)))
                (match statements
                  (()
                   '())
                  ((statement rest ...)
                   (match statement
                     (($ <compound>)
                      (cons (split-complex-expressions statement) (loop rest)))
                     ((? split-complex?)
                      (let* ((split (split-complex-expressions statement))
                             (split (match split
                                      (($ <compound>) (.elements split))
                                      (_ (list split)))))
                        (append split (loop rest))))
                     (else
                      (cons statement (loop rest)))))))))
         (clone o #:elements statements)))
      ((or ($ <expression-function>) ($ <invariant>))
       o)
      (($ <behavior>)
       (clone o
              #:functions (split-complex-expressions (.functions o))
              #:statement (split-complex-expressions (.statement o))))
      ((? (%normalize:short-circuit?))
       o)
      (($ <interface>)
       (clone o #:behavior (split-complex-expressions (.behavior o))))
      (($ <component>)
       (clone o #:behavior (split-complex-expressions (.behavior o))))
      ((? (is? <ast>)) (tree-map split-complex-expressions o))
      (_ o))))

(define ((add-temporary add-temporary?) o)
  (let* ((expression (.expression o))
         (variable-expression (add-temporary? o))
         (type (ast:type variable-expression))
         (void? (is-a? type <void>))
         (local-type? (ast:eq? (ast:parent type <model>)
                               (ast:parent o <model>)))
         (type-name (cond
                     ((is-a? type <subint>) (.name (ast:type (make <int>))))
                     (local-type? (.name type))
                     (else (make <scope.name> #:ids (ast:full-name type)))))
         (name (temp-name o))
         (location (.location o))
         (temporary (make <variable> #:name name
                          #:type.name type-name
                          #:expression variable-expression
                          #:location location))
         (temporary (if void? variable-expression temporary))
         (temporary (clone temporary #:parent (ast:parent o <behavior>)))
         (var (make <var> #:name name #:location location))
         (var (if void? #f var))
         (o (tree-map
             (cute replace-expression variable-expression <> var)
             o))
         (compound (make <compound> #:location (.location o)))
         (parent (ast:parent o <statement>))
         (compound (clone compound #:parent parent)))
    (clone compound #:elements (list temporary o))))

(define ((split+add-temporaries split-complex? split-complex-expressions
                                add-temporary add-explicit-temporaries) o)
  (let ((split+add-temporaries (split+add-temporaries
                                split-complex? split-complex-expressions
                                add-temporary add-explicit-temporaries)))
    (if (not (split-complex? o)) (add-temporary o)
        (let ((o (split-complex-expressions o)))
          (if (add-temporary? o) (add-explicit-temporaries o)
              o)))))

(define* ((add-explicit-temporaries #:key call-only?) o)
  "Make implicit temporary values in action, call, if, reply, and return
expressions explicit."
  (let* ((add-explicit-temporaries (add-explicit-temporaries
                                    #:call-only? call-only?))
         (add-temporary? (if call-only? add-temporary*? add-temporary?))
         (temporaries (if call-only? temporaries* temporaries))
         (split-complex? (split-complex? temporaries add-temporary?))
         (split-complex-expressions (split-complex-expressions split-complex?))
         (add-temporary (add-temporary add-temporary?))
         (split+add-temporaries (split+add-temporaries
                                 split-complex? split-complex-expressions
                                 add-temporary add-explicit-temporaries)))
    (match o
      (($ <if>)
       (let* ((expression (.expression o))
              (split-expression? (or (add-temporary? (.expression o))
                                     (split-complex? (.expression o)))))
         (if split-expression? (let ((o (split+add-temporaries o)))
                                 (add-explicit-temporaries o))
             (let* ((then (add-explicit-temporaries (.then o)))
                    (else-clause (add-explicit-temporaries (.else o)))
                    (location (.location o))
                    (o (clone o #:then then #:else else-clause)))
               (if (not (add-temporary? o)) o
                   (split+add-temporaries o))))))
      ((or ($ <action>) ($ <call>))
       (let ((split? (or (split-complex? o) (add-temporary? o))))
         (if (not split?) o
             (let ((o (split+add-temporaries o)))
               (add-explicit-temporaries o)))))

      ((or ($ <assign>) ($ <reply>) ($ <return>) ($ <variable>))
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
      ((or ($ <expression-function>) ($ <invariant>))
       o)
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
      ((? (is? <ast>)) (tree-map add-explicit-temporaries o))
      (_ o))))

(define* (group-expressions o #:optional (group (list)))
  (match o
    ((? (const (find (cute is-a? o <>) group)))
     (let ((o (tree-map (cute group-expressions <> group) o)))
       (match (.parent o)
         (($ <group>) o)
         ((? (is? <expression>)) (make <group> #:expression o))
         (else o))))
    ((and (? (is? <not>))
          (= .expression (and expression (or (? (is? <binary>))
                                             (? (is? <field-test>))))))
     (let ((expression (tree-map (cute group-expressions <> group) expression)))
       (clone o #:expression (make <group> #:expression expression))))
    (($ <canonical-on>)
     (let* ((guard (group-expressions (.guard o) group))
            (statement (group-expressions (.statement o) group)))
       (clone o #:guard guard #:statement statement)))
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
     (tree-map (cute group-expressions <> group) o))
    (_ o)))

(define (simplify-guard-expressions o)
  "Simplify guard expressions by using static analysis."
  (match o
    (($ <behavior>)
     (clone o
            #:statement
            ((compose
              triples:->compound-guard-on
              (cute map canonical-on->triple <>)
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
     (tree-map simplify-guard-expressions o))
    (_
     o)))

(define (tag-imperative-blocks o)
  "Mark imperative statement blocks with a unique tag for unreachable
code check."
  (define (location o)
    (or (.location o)
        (location (.parent o))))
  (define (add-tag-imperative o)
    (if (ast:imperative? o)
        (match o
          ((? ast:illegal?)
           o)
          ;; FIXME: make $ goops base class aware
          ;; to derive <declarative-compound> from <component>
          ((or ($ <compound>) ($ <declarative-compound>))
           ;; FIXME: (car (ast:trigger* ...
           (let* ((location (location (if (not (is-a? (.parent o) <on>)) o
                                          (car (ast:trigger* (.parent o))))))
                  (tag (make <tag> #:location location)))
             (clone o #:elements (cons tag (ast:statement* o)))))
          (_
           (let* ((location (location o))
                  (tag (make <tag> #:location location)))
             (make <compound> #:elements (list tag o) #:location location))))
        o))

  (match o
    ((or ($ <blocking>) ($ <defer>) ($ <function>) ($ <guard>) ($ <on>))
     (let* ((statement (.statement o))
            (statement (add-tag-imperative (tag-imperative-blocks statement))))
       (clone o #:statement statement)))
    (($ <if>)
     (let ((then (add-tag-imperative (tag-imperative-blocks (.then o))))
           (else (and=> (tag-imperative-blocks (.else o)) add-tag-imperative)))
       (clone o #:then then #:else else)))
    ((or ($ <compound>) ($ <declarative-compound>))
     (clone o #:elements (map tag-imperative-blocks (ast:statement* o))))
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
     (tree-map tag-imperative-blocks o))
    (_ o)))
