;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2018, 2020, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn normalize)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn display)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn display)

  #:use-module (dzn ast)

  #:export (%no-unreachable?
            add-defer-end
            add-determinism-temporaries
            add-explicit-temporaries
            add-function-return
            add-reply-port
            binding-into-blocking
            not-or-guards
            normalize:event
            normalize:event+illegals
            normalize:state
            normalize:state+illegals
            purge-data
            remove-behavior
            remove-location
            remove-otherwise
            simplify-guard-expressions
            split-complex-expressions
            split-variable))

;; Should add-explicit-temporaries only cater for deterministic ordering
;; of noisy expressions?
(define %noisy-ordering? (make-parameter #f))

;; Should unreachable-code tags be omitted?
(define %no-unreachable? (make-parameter #f))

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
  (define typed-action/call?
    (conjoin (disjoin (is? <action>) (is? <call>))
             ast:typed?))
  (define add-temporary?
    (conjoin (disjoin (is? <action>)
                      (is? <binary>)
                      (is? <call>))
             ast:typed?
             (compose pair?
                      (cute tree-collect typed-action/call? <>))
             (disjoin
              (cute parent <> <arguments>)
              (compose (cute parent <> <binary>) .parent))))
  (cond ((is-a? o <call>)
         (tree-collect add-temporary? o))
        ((or (is-a? o <assign>) (is-a? o <variable>))
         (append
          (tree-collect add-temporary? o)
          (map .expression
               (tree-collect
                (conjoin
                 (is? <not>)
                 (compose pair? (cute tree-collect typed-action/call? <>)))
                o))))
        ((is-a? o <if>)
         (tree-collect typed-action/call? (.expression o)))
        ((or (as o <expression>)
             (and (is-a? o <reply>) (.expression o))
             (and (is-a? o <return>) (.expression o)))
         =>
         (cute tree-collect typed-action/call? <>))
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
                                   (cute tree-collect typed-action/call? <>))
                   <>)
             ast:argument*))
  (define >1-typed-action/call?
    (compose (cute > <> 1)
             length
             (cute tree-collect typed-action/call? <>)))
  (let* ((arguments (tree-collect
                     (conjoin (is? <arguments>)
                              (compose (cute > <> 1) length .elements)
                              >1-typed-action/call?)
                     o))
         (arguments (filter >1-argument-typed-action/call? arguments))
         (arguments (append-map ast:argument* arguments))
         (expressions (tree-collect
                       (conjoin (disjoin (is? <minus>) (is? <plus>))
                                >1-typed-action/call?)
                       o))
         (expressions (append-map
                       (lambda (x)
                         (let ((expressions (list (.left x) (.right x))))
                           (filter
                            (compose pair?
                                     (cute tree-collect typed-action/call? <>))
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
            (let ((p (.parent h)))
              (and (not (or (parent p <and>) (parent p <or>)))
                   h)))
           (_
            #f)))))

(define (complex? o)
  (pair? (tree-collect (disjoin (is? <and>) (is? <or>)) o)))

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
        (list (make-triple on guard #f statement)))
      triples))

(define (trigger-equal? a b)
  (and (equal? (.port.name a) (.port.name b))
       (equal? (.event.name a) (.event.name b))))

(define (add-illegals model triples trigger)
  (let* ((triples (filter (lambda (t) (trigger-equal? ((compose car ast:trigger* triple-on) t) trigger)) triples))
         (on (clone (make <on> #:triggers (make <triggers> #:elements (list trigger))) #:parent (.parent trigger)))
         (behavior (.behavior model))
         (guard (and-not-guards (map triple-guard triples)))
         (guard (clone guard #:parent behavior))
         (guard (simplify-guard guard)))
    (if (ast:literal-false? (.expression guard)) triples
        (let* ((provides? (and=> (.port trigger) ast:provides?))
               (statement (make (cond (provides?
                                       <declarative-illegal>)
                                      ((is-a? model <interface>)
                                       <declarative-illegal>)
                                      (else
                                       <illegal>))))
               (illegal-triple (make-triple on guard #f statement)))
          (append triples (list illegal-triple))))))

(define ((triples:add-illegals model) triples)
  (append (append-map (cut add-illegals model triples <>) (ast:in-triggers model))
          (filter (compose ast:modeling? car ast:trigger* triple-on) triples)))

(define (add-tag statement)
  (define (location statement)
    (let ((loc (.location statement)))
      (if loc loc (location (.parent statement)))))
  (if (declarative-illegal? statement) statement
      (let* ((tag (make <tag> #:location (location statement)))
             (elements (if (is-a? statement <compound>)
                           (append (list tag) (ast:statement* statement))
                           (list tag statement)))
             (statement (make <compound> #:elements elements)))
      statement)))

(define (tag-blocks o)
  (cond ((not (is-a? o <ast>)) o)
    ((is-a? o <if>)
      (let* ((then (add-tag (tag-blocks (.then o))))
                   (else (tag-blocks (.else o)))
                   (else (if else (add-tag else) else)))
        (clone o #:then then #:else else)))
    ((or (is-a? o <function>) (is-a? o <defer>))
      (clone o #:statement (add-tag (tag-blocks (.statement o)))))
    (else (tree-map tag-blocks o))))

(define (triples:tag-blocks triples)
  (define (tag-blocks-triple t)
    (make-triple (triple-on t)
                 (triple-guard t)
                 (triple-blocking? t)
                 (add-tag (tag-blocks (triple-statement t)))))
  (map tag-blocks-triple triples))

(define (triples:mark-the-end triples)
  (define (mark-the-end t)
    (let* ((on (triple-on t))
           (illegal? (declarative-illegal? (triple-statement t)))
           (blocking? (triple-blocking? t))
           (valued-trigger? (ast:typed? ((compose car ast:trigger*) on)))
           (modeling? (is-a? ((compose .event car ast:trigger*) on) <modeling-event>))
           (port ((compose .port car ast:trigger*) on))
           (provides? (and port (ast:provides? port))))
      (if (parent on <interface>)
          (if (or valued-trigger? illegal?) t
              (let* ((statement (triple-statement t))
                     (end (make (if modeling? <the-end> <reply>)))
                     (elements (if (is-a? statement <compound>)
                                   (append (ast:statement* statement) (list end))
                                   (list statement end)))
                     (statement (make <compound> #:elements elements)))
                (make-triple on (triple-guard t) (triple-blocking? t) statement)))
          (let ((t (if (or valued-trigger? illegal? blocking?) t
                       (let* ((statement (triple-statement t))
                              (reply (if provides? (list (make <reply>)) '()))
                              (elements (if (is-a? statement <compound>)
                                            (ast:statement* statement)
                                            (list statement)))
                              (elements (append elements reply))
                              (statement (make <compound> #:elements elements)))
                         (make-triple on (triple-guard t) (triple-blocking? t) statement)))))
            (if illegal? t (add-the-end t))))))
  (map mark-the-end triples))

(define (add-the-end t)
  (let* ((statement (triple-statement t))
         (elements (if (is-a? statement <compound>)
                       (ast:statement* statement)
                       (list statement)))
         (elements (append elements (list (make <the-end>))))
         (statement (make <compound> #:elements elements)))
    (make-triple (triple-on t) (triple-guard t) (triple-blocking? t) statement)))

(define ((triples:declarative-illegals model) triples)
  (define (illegal? o)
    (match o
      (($ <illegal>) o)
      ((and ($ <compound>) (= ast:statement* (statement))) (illegal? statement))
      (_ #f)))
  (define (foo t)
    (let* ((on (triple-on t))
           (trigger ((compose car ast:trigger*) on))
           (provides? (and=> (.port trigger) ast:provides?))
           (statement (triple-statement t)))
      (if (and (or (is-a? model <interface>) provides?) (illegal? statement)) (make-triple on (triple-guard t) (triple-blocking? t) (make <declarative-illegal>))
          t)))
  (map foo triples))

(define (triples:split-multiple-on triples)
  (define (on->triple t on)
    (let* ((trigger ((compose car ast:trigger*) on))
           (provides? (and=> (.port trigger) ast:provides?)))
      (make-triple on
                   (triple-guard t)
                   (and provides? (triple-blocking? t))
                   (triple-statement t))))
  (define (split-triple-on t)
    (let* ((on (triple-on t))
           (triggers (ast:trigger* on))
           (ons (if (= (length triggers) 1) (list on)
                    (map (compose
                          (cut clone on #:triggers <>)
                          (cut make <triggers> #:elements <>)
                          list)
                         triggers))))
      (map (cute on->triple t <>) ons)))
  (append-map split-triple-on triples))

(define (triples:->triples o)
  (define (triple o)
    (let* ((path (ast:path o (lambda (p) (is-a? (.parent p) <behavior>))))
           (guards (filter (is? <guard>) path))
           (expression (and-expressions (map .expression guards))))
      (make-triple (find (is? <on>) path)
                   (make <guard> #:expression expression)
                   (find (is? <blocking>) path)
                   o)))
  (if (and (is-a? o <compound>) (null? (ast:statement* o))) '()
      (map triple (tree-collect-filter
                   (conjoin (is? <ast>) (disjoin ast:declarative? (compose ast:declarative? .parent)))
                   ast:imperative? o))))

(define (triples:on-compound triples)
  (define (foo t)
    (let* ((statement (triple-statement t))
           (statement (if (is-a? statement <compound>) statement
                          (make <compound> #:elements (list statement)))))
      (make-triple (triple-on t) (triple-guard t) (triple-blocking? t) statement)))
  (map foo triples))

(define (normalize:state o)
  "Push guards up, thereby splitting the body of a trigger into multiple
guarded occurrences."
  (match o
    (($ <behavior>)
     (clone o
            #:statement
            ((compose
              triples:->compound-guard-on
              (cute triples:group-expressions <> (list <and> <field-test> <or>))
              triples:simplify-guard
              (triples:fix-empty-interface (parent o <model>))
              triples:split-multiple-on
              triples:->triples
              .statement
              ) o)
            #:functions
            (group-expressions (.functions o) (list <and> <field-test> <or>))))
    ((? (is? <ast>))
     (tree-map normalize:state o))
    (_
     o)))

(define (normalize:state+illegals o)
  (match o
    (($ <behavior>)
     (clone o #:statement
            ((compose
              triples:->compound-guard-on
              (cute triples:group-expressions <> (list <and> <field-test> <or>))
              triples:simplify-guard
              (triples:fix-empty-interface (parent o <model>))
              (triples:add-illegals (parent o <model>))
              triples:mark-the-end
              (if (%no-unreachable?) identity triples:tag-blocks)
              (triples:declarative-illegals (parent o <model>))
              triples:split-multiple-on
              triples:->triples
              .statement
              ) o)
            #:functions
            ((compose
              (if (%no-unreachable?) identity tag-blocks)
              (cute group-expressions <> (list <and> <field-test> <or>))
             ) (.functions o))))
    ((? (is? <ast>))
     (tree-map normalize:state+illegals o))
    (_
     o)))

(define* (triples:->on-guard* triples #:key otherwise?)
  (define ((trigger-equal? trigger) triple)
    (let ((t ((compose car ast:trigger* triple-on) triple)))
      (and (equal? (.port.name t) (.port.name trigger)) (equal? (.event.name t) (.event.name trigger)))))
  (let* ((sorted-triples (let loop ((triples triples))
                           (if (null? triples) '()
                               (let ((trigger ((compose car ast:trigger* triple-on car) triples)))
                                 (receive (shared rest)
                                     (partition (trigger-equal? trigger) triples)
                                   (cons shared (loop rest)))))))
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
              (cute triples:group-expressions <> (list <and> <field-test> <or>))
              triples:simplify-guard
              (rewrite-formals-and-locals (parent o <model>))
              triples:split-multiple-on
              triples:->triples
              .statement
              ) o)
            #:functions
            (group-expressions (.functions o) (list <and> <field-test> <or>))))
    ((? (is? <ast>))
     (tree-map normalize:event o))
    (_
     o)))

(define (normalize:event+illegals o)
  (match o
    (($ <behavior>)
     (clone o #:statement
            ((compose
              (cute make <compound> #:elements <>)
              (cut triples:->on-guard* <> #:otherwise? #t)
              (cute triples:group-expressions <> (list <and> <field-test> <or>))
              triples:simplify-guard
              (rewrite-formals-and-locals (parent o <model>))
              (triples:add-illegals (parent o <model>))
              triples:split-multiple-on
              triples:->triples
              .statement
              ) o)
            #:functions
            (group-expressions (.functions o) (list <and> <field-test> <or>))))
    ((? (is? <ast>))
     (tree-map normalize:event+illegals o))
    (_
     o)))

(define ((rewrite-formals-and-locals model) triples)
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
      (or (is-a? o <formal>) (and (is-a? o <variable>) (not (is-a? (.parent o) <variables>)))))
    (define (rename-string o)
      (or (assoc-ref mapping o) o))
    (match o
      ((and ($ <trigger>) (? (compose null? ast:formal*))) o)
      (($ <trigger>)
       (clone o #:formals (clone (.formals o) #:elements (map (rename mapping) (ast:formal* o)))))
      (($ <action>) (clone o #:arguments ((rename mapping) (.arguments o))))
      (($ <arguments>) (clone o #:elements (map (rename mapping) (ast:argument* o))))
      (($ <var>)
       (if (formal-or-local? (.variable o)) (clone o #:name (rename-string (.name o)))
           o))
      (($ <assign>)
       (let ((expression ((rename mapping) (.expression o)))
             (name (if (formal-or-local? (.variable o)) (rename-string (.variable.name o))
                       (.variable.name o))))
         (clone o #:variable.name name #:expression expression)))
      (($ <variable>)
       (let ((name (if (formal-or-local? o) (rename-string (.name o))
                       (.name o))))
         (clone o #:name name #:expression ((rename mapping) (.expression o)))))
      (($ <field-test>) (if (formal-or-local? (.variable o)) (clone o #:variable.name (rename-string (.variable.name o)))
                            o))
      (($ <formal>) (clone o #:name (rename-string (.name o))))
      (($ <formal-binding>) (clone o #:name (rename-string (.name o))))
      ((? (is? <ast>)) (tree-map (rename mapping) o))
      (_ o)))

  (define (foo t)
    (let* ((o (triple-on t))
           (trigger ((compose car .elements .triggers) (triple-on t)))
           (event (.event trigger))
           (formals ((compose ast:formal* .signature) event))
           (formals-ok? (or (pair? (ast:formal* trigger))
                            (null? formals)))
           (t (if formals-ok? t
                  (let* ((formals (clone (.formals trigger) #:elements formals))
                         (trigger (clone trigger #:formals formals))
                         (triggers (clone (.triggers o)
                                          #:elements (list trigger))))
                    (make-triple (clone o #:triggers triggers)
                                 (triple-guard t)
                                 (triple-blocking? t)
                                 (triple-statement t)))))
           (trigger ((compose car .elements .triggers) (triple-on t)))
           (trigger (if (pair? (ast:formal* trigger)) trigger
                        (let* ((formals (ast:formal* event))
                               (formals (clone (.formals trigger) #:elements formals)))
                          (clone trigger #:formals formals))))
           (formals (map .name ((compose .elements .formals .signature) event)))
           (members (map .name (ast:variable* model)))
           (locals (map .name (tree-collect (is? <variable>) (triple-statement t))))
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
          (make-triple
           (clone o #:triggers (clone (.triggers o) #:elements (list ((rename mapping) trigger))))
           (triple-guard t)
           (triple-blocking? t)
           ((rename mapping) (triple-statement t))))))
  (map foo triples))

(define-method (is-data? (o <ast>))
  (or (is-a? o <data>) (and (is-a? o <var>) (is-a? ((compose .type .variable) o) <extern>))))

(define (purge-data o)
  "Remove every `extern' data variable and reference."
  (match o
    (($ <interface>)
     (clone o
            #:types (purge-data (.types o))
            #:events (purge-data (.events o))))
    (($ <component>)
     (clone o #:behavior (purge-data (.behavior o))))
    (($ <system>)
     o)
    ((? (is? <ast-list>))
     (clone o #:elements (filter-map purge-data (.elements o))))
    (($ <data>) #f)
    (($ <action>)
     (clone o #:arguments (make <arguments>)))

    (($ <trigger>)
     (clone o #:formals (make <formals>)))

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
         (make-triple
          (triple-on t)
          (simplify-guard (triple-guard t))
          (triple-blocking? t)
          (triple-statement t)))
       triples))

(define* (triples:group-expressions triples #:optional (group (list)))
  (map (lambda (t)
         (make-triple
          (triple-on t)
          (group-expressions (triple-guard t) group)
          (triple-blocking? t)
          (group-expressions (triple-statement t) group)))
       triples))

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
    (($ <interface>)
     (clone o #:behavior (add-function-return (.behavior o))))
    (($ <component>)
     (clone o #:behavior (add-function-return (.behavior o))))
    (($ <behavior>)
     (clone o #:functions (add-function-return (.functions o))))
    (($ <functions>)
     (clone o #:elements (map add-function-return (ast:function* o))))
    (($ <function>)
     (if (not (is-a? (ast:type o) <void>)) o
         (clone o #:statement (add-return (.statement o)))))
    ((? (is? <ast>)) (tree-map add-function-return o))
    (_ o)))

(define* (add-defer-end o)
  (define* (add-end o #:key (loc o))
    (match o
      (($ <compound>)
       (clone o #:elements (add-end (ast:statement* o) #:loc o)))
      ((statement ... t)
       (append o (list (make <defer-end> #:location (.location (.parent t))))))
      ((statement ...)
       (append o (list (make <defer-end> #:location (.location loc)))))
      (_ (let* ((location (.location o))
                (end (make <defer-end>)))
           (make <compound>
             #:elements (cons o (list end))
             #:location location)))))
  (match o
    (($ <defer>)
     (let ((statement (add-defer-end (.statement o))))
      (clone o #:statement (add-end statement))))
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
    (($ <component>)
     (clone o #:behavior (add-defer-end (.behavior o))))
    (($ <system>)
     o)
    (($ <foreign>)
     o)
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
    (($ <component>) (clone o #:behavior (add-reply-port (.behavior o) (if (= 1 (length (ast:provides-port* o))) (car (ast:provides-port* o)) #f) block?)))
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
     (clone o #:behavior ((binding-into-blocking) (.behavior o))))

    (($ <behavior>)
     (clone o #:statement ((binding-into-blocking '()) (.statement o))))

    (($ <interface>) o)
    (($ <system>) o)
    (($ <foreign>) o)
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
    ((and (? (is? <component>) (= .behavior behavior)))
     (clone o #:behavior (remove-otherwise behavior keep-annotated? statements)))
    ((and (? (is? <interface>) (= .behavior behavior)))
     (clone o #:behavior (remove-otherwise behavior keep-annotated? statements)))
    ((? (is? <component-model>)) o)
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

(define (add-explicit-temporaries o)
  "Make implicit temporary values in action, call, if, reply, and return
expressions explicit."

  (define (replace-expression old o var)
    (cond ((ast:eq? old o)
           var)
          ((is-a? o <expression>)
           (tree-map (cute replace-expression old <> var) o))
          ((is-a? o <arguments>)
           (tree-map (cute replace-expression old <> var) o))
          (else
           o)))

  (define (add-temporary o)
    (let* ((expression (.expression o))
           (variable-expression (add-temporary? o))
           (type (ast:type variable-expression))
           (local-type? (ast:eq? (parent type <model>)
                                 (parent o <model>)))
           (type-name (if local-type? (.name type)
                          (make <scope.name> #:ids (ast:full-name type))))
           (name (temp-name o))
           (location (.location o))
           (temporary (make <variable> #:name name
                            #:type.name type-name
                            #:expression variable-expression
                            #:location location))
           (temporary (clone temporary #:parent (parent o <behavior>)))
           (var (make <var> #:name name #:location location))
           (o (tree-map
               (cute replace-expression variable-expression <> var)
               o))
           (compound (make <compound> #:location (.location o)))
           (parent (parent (.parent o)  <statement>))
           (compound (clone compound #:parent parent)))
      (clone compound #:elements (list temporary o))))

  (define (split+add-temporaries o)
    (if (not (split-complex? o)) (add-temporary o)
        (let ((o (split-complex-expressions o)))
          (if (add-temporary? o) (add-explicit-temporaries o)
              o))))

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
    (($ <defer>)
     (let* ((statement (.statement o))
            (split? (or (split-complex? statement) (add-temporary? statement))))
       (if (not split?) o
           (let* ((statement (split+add-temporaries statement))
                  (statement (add-explicit-temporaries statement)))
             (clone o #:statement statement)))))
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
    (($ <interface>)
     (clone o #:behavior (add-explicit-temporaries (.behavior o))))
    (($ <component>)
     (clone o #:behavior (add-explicit-temporaries (.behavior o))))
    (($ <foreign>) o)
    (($ <system>) o)
    ((? (is? <ast>)) (tree-map add-explicit-temporaries o))
    (_ o)))

(define (add-determinism-temporaries o)
  "Make evaluation order of noisy expressions deterministic by adding
explitic temporaries."
    (parameterize ((%noisy-ordering? #t))
    (add-explicit-temporaries o)))

(define (split-complex-expressions o)
  "Split && and || into an if with a simple expression.  Depends on the
add-explicit-temporaries transformation for splitting argument lists."

  (define (replace-argument o old new)
    (define (replace o)
      (if (eq? (.node o) (.node old)) new
          o))
    (let* ((arguments (ast:argument* o))
           (arguments (map replace arguments))
           (arguments (clone (.arguments o) #:elements arguments)))
      (clone o #:arguments arguments)))

  (define* (split o #:key not-e)
    (let* ((expression (.expression o))
           (expression (simplify-expression expression))
           (o (clone o #:expression expression)))
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
                             (.else then))
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
                             (.then o))
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
                (parent (parent (.parent o) <statement>))
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
    (($ <behavior>)
     (clone o
            #:functions (split-complex-expressions (.functions o))
            #:statement (split-complex-expressions (.statement o))))
    (($ <interface>)
     (clone o #:behavior (split-complex-expressions (.behavior o))))
    (($ <component>)
     (clone o #:behavior (split-complex-expressions (.behavior o))))
    (($ <foreign>) o)
    (($ <system>) o)
    ((? (is? <ast>)) (tree-map split-complex-expressions o))
    (_ o)))

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
    (($ <function>)
     (clone o #:statement (group-expressions (.statement o) group)))
    (($ <behavior>)
     (clone o
            #:functions (group-expressions (.functions o) group)
            #:statement (group-expressions (.statement o) group)))
    (($ <interface>)
     (clone o #:behavior (group-expressions (.behavior o) group)))
    (($ <component>)
     (clone o #:behavior (group-expressions (.behavior o) group)))
    (($ <foreign>) o)
    (($ <system>) o)
    ((? (is? <ast>)) (tree-map (cute group-expressions <> group) o))
    (_ o)))

(define (simplify-guard-expressions o)
  "Simplify guard expressions by using static analysis."
  (match o
    (($ <behavior>)
     (clone o
            #:statement
            ((compose
              triples:->compound-guard-on
              (cute triples:group-expressions <> (list <and> <field-test> <or>))
              triples:simplify-guard
              triples:->triples
              .statement
              ) o)))
    ((? (is? <ast>))
     (tree-map simplify-guard-expressions o))
    (_
     o)))

(define-method (root-> (o <root>))
  ((compose
    normalize:event
    ) o))

(define (ast-> ast)
  ((compose
    ast:pretty-print
    root->)
   ast))
