;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2020, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2016, 2017, 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

(define-module (dzn code)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 string-fun)

  #:use-module (dzn ast display)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast lookup)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast)
  #:use-module (dzn code goops)
  #:use-module (dzn code language makreel)
  #:use-module (dzn command-line)
  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:use-module (dzn verify constraint)
  #:use-module (dzn vm goops)

  #:export (%calling-context
            %language
            %member-prefix
            %name-infix
            %no-constraint?
            %no-unreachable?
            %shell
            %type-infix
            %type-prefix

            code

            code:add-calling-context
            code:add-calling-context-argument
            code:add-calling-context-formal
            code:annotate-shells
            code:argument*
            code:blocking?
            code:capture-local
            code:capture-name
            code:component-binding*
            code:component-include*
            code:defer-condition
            code:defer-equality*
            code:direction
            code:end-point->string
            code:enum*
            code:event-name
            code:event-slot-name
            code:file-name
            code:file-name->string
            code:formal*
            code:injected-binding*
            code:injected-instance*
            code:instance*
            code:instance-end-point
            code:interface-include*
            code:member
            code:member-name
            code:model*
            code:normalize
            code:normalize+determinism
            code:number-argument
            code:number-formals
            code:on
            code:out-binding
            code:port-binding?
            code:port-end-point?
            code:port-release?
            code:provides+requires-end-point
            code:provides-end-point
            code:public-enum*
            code:pump?
            code:reply-types
            code:type-eq?
            code:reply-var
            code:requires-end-point
            code:requires-in-void-returns
            code:return-values
            code:shared
            code:shared-dzn-event-method
            code:shared-state
            code:shared-update
            code:shared-update-method
            code:shared-value
            code:short-circuit?
            code:type->string
            code:type-name
            code:wrap-compound))

;;;
;;; Parameters.
;;;

;; The calling-context to insert.
(define %calling-context (make-parameter #f))

;; The output language.
(define %language (make-parameter "c++"))

;; Prefix for member variable.
(define %member-prefix (make-parameter "this->"))

;; Should interface constraints be omitted?
(define %no-constraint? (make-parameter #f))

;; Infix for printing name elements.
(define %name-infix (make-parameter "."))

;; Should unreachable-code tags be omitted?
(define %no-unreachable? (make-parameter #f))

;; Prefix for printing compound types.
(define %type-prefix (make-parameter "::"))

;; Infix for printing type elements.
(define %type-infix (make-parameter "::"))

;; The name of the thread-safe shell.
(define %shell (make-parameter #f))


;;;
;;; Accessors.
;;;
(define-method (.port.name (o <instance>))
  (let ((component (.type o)))
    (.name (ast:provides-port component))))

(define-method (code:model* (o <root>))
  (let* ((models (ast:model* o))
         (models (filter (negate
                          (disjoin (is? <type>) (is? <namespace>)
                                   ast:imported?))
                         models))
         (models (ast:topological-model-sort models))
         (models (map code:annotate-shells models)))
    models))

(define-method (code:interface-include* (o <top>) source-file)
  (let* ((interfaces (ast:interface* o))
         (interfaces (filter (compose not
                                      (cute equal? source-file <>)
                                      ast:source-file)
                             interfaces))
         (file-names (map code:file-name interfaces))
         (file-names (delete-duplicates file-names)))
    (map (cut make <file-name> #:name <>) file-names)))

(define-method (code:interface-include* (o <top>))
  (code:interface-include* o (ast:source-file o)))

(define-method (code:interface-include* (o <foreign>))
  (code:interface-include* o (ast:source-file (ast:parent o <root>))))

(define (code:component-include* o)
  (let ((source-file (ast:source-file o)))
    (filter (disjoin
             (compose (is? <foreign>) .type)
             (conjoin (compose ast:imported? .type)
                      (compose not
                               (cute equal? <> source-file)
                               ast:source-file
                               .type)))
            (ast:instance* o))))

(define-method (code:pump? (o <component-model>))
  (and (pair? (tree-collect (disjoin (is? <blocking>)
                                     (is? <defer>)
                                     (is? <blocking-compound>))
                            o))
       o))

(define-method (code:pump? (o <system>))
  (let* ((components (ast:component-model* o))
         (components (filter (negate (cute ast:eq? <> o)) components)))
    (any code:pump? components)))

(define-method (code:pump? (o <shell-system>))
  #t)

(define-method (code:pump? (o <root>))
  (let ((components (filter (conjoin (negate ast:imported?) (is? <component>))
                            (ast:model* o))))
    (any code:pump? components)))

(define-method (code:public-enum* (o <interface>))
  (filter (is? <enum>) (ast:type* o)))

(define-method (code:public-enum* (o <root>))
  (filter (is? <enum>) (ast:type* o)))

(define-method (code:enum* (o <root>))
  (filter (conjoin (is? <enum>)
                   (negate ast:imported?))
          (ast:type* o)))

(define-method (code:file-name (o <foreign>))
  (if (ast:imported? o) (next-method)
      (ast:full-name o)))

(define-method (code:file-name (o <import>))
  (basename (.name o) ".dzn"))

(define-method (code:file-name (o <ast>))
  (basename (ast:source-file o) ".dzn"))

(define-method (code:enum* (o <model>))
  (filter (is? <enum>) (ast:type* (.behavior o))))

(define-method (code:enum* (o <foreign>))
  '())

(define-method (code:type-eq? (a <subint>) (b <subint>))
  #t)

(define-method (code:type-eq? a b)
  (ast:eq? a b))

(define (code:reply-types o)
  (let* ((types (ast:return-types o))
         (types (filter (negate (is? <void>)) types)))
    (delete-duplicates types code:type-eq?)))

(define-method (code:port-release o)
  (let ((trigger (and=> (ast:parent o <on>)
                        (compose car ast:trigger*))))
    (and (or (not trigger)
             (ast:requires? trigger)
             (or (not (ast:equal? (.port o) (.port trigger)))
                 (ast:parent o <blocking>)
                 (ast:parent o <blocking-compound>)))
         (code:blocking? o)
         o)))

(define (code:blocking? o)
  (pair? (tree-collect-filter
          (negate (disjoin (is? <imperative>)
                           (is? <expression>)
                           (is? <location>)))
          (disjoin (is? <blocking>) (is? <blocking-compound>))
          (ast:parent o <model>))))

(define-method (code:port-release? o)
  (let ((trigger (and=> (ast:parent o <on>)
                        (compose car ast:trigger*))))
    (and (or (not trigger)
             (ast:requires? trigger)
             (or (not (ast:equal? (.port o) (.port trigger)))
                 (ast:parent o <blocking>)
                 (ast:parent o <blocking-compound>)))
         (code:blocking? o))))

(define-method (code:direction (o <event>))
  (simple-format #f "~a" (.direction o)))

(define-method (code:direction (o <action>))
  (code:direction (.event o)))

(define-method (code:direction (o <trigger>))
  (code:direction (.event o)))

(define-method (code:direction (o <port>))
  (simple-format #f "~a" (.direction o)))

(define-method (code:event-slot-name o) ; <trigger> or <action>
  (string-append (.port.name o)
                 "_"
                 (.event.name o)))

(define-method (code:event-name (o <event>))
  (string-append
   (code:direction o)
   (match (%language) ("cs" "_port") (_ ""))
   "."
   (.name o)))

(define-method (code:event-name o) ; <trigger> or <action>
  (string-append (.port.name o)
                 "."
                 (code:event-name (.event o))))

(define-method (code:file-name (o <port>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <instance>))
  (code:file-name (.type o)))

(define-method (code:file-name (o <foreign>))
  (ast:full-name o))

(define-method (code:file-name (o <ast>))
  (basename (ast:source-file o) ".dzn"))

(define-method (code:member (o <string>))
  (string-append (%member-prefix) o))

(define-method (code:member-name (o <variable>))
  (code:member (.name o)))

(define-method (code:out-binding (o <port>))
  (string-append "dzn_out_" (.name o)))

(define-method (code:type-name (o <ast>))
  (match o
    (($ <bool>) "bool")
    (($ <int>) "int")
    (($ <subint>) "int")
    (($ <void>) "void")
    (_ (string-append
        (%type-prefix)
        (string-join (ast:full-name o) (%type-infix))))))

(define-method (code:type-name (o <data>))
  (let ((value (.value o)))
    (if (unspecified? value) "unspecified"
        value)))

(define-method (code:type-name (o <event>))
  ((compose code:type-name .type .signature) o))

(define-method (code:type-name (o <enum-field>))
  (string-append (code:type-name (.type o)) (%type-infix) (.field o)))

(define-method (code:type-name (o <enum-literal>))
  (string-append (code:type-name (.type o)) (%type-infix) (.field o)))

(define-method (code:type-name (o <extern>))
  (code:type-name (.value o)))

(define-method (code:type-name (o <formal>))
  (code:type-name (.type o)))

(define-method (code:type-name (o <string>))
  o)

(define-method (code:type-name (o <variable>))
  (code:type-name (.type o)))

(define-method (code:type->string (o <type>))
  (parameterize ((%type-infix "_")
                 (%type-prefix ""))
    (code:type-name o)))

(define-method (code:reply-var (o <type>))
  (let ((type (code:type->string o)))
    (simple-format #f "dzn_reply_~a" type)))

(define (code:file-name->string o)
  (let ((file-name (code:file-name o)))
    (match file-name
      ((h t ...)
       (string-join file-name "_"))
      ((? string?)
       file-name))))

(define-method (code:wrap-compound o)
  (let ((compound (make <compound> #:elements (list o))))
    (clone compound #:parent (.parent o))))


;;;
;;; Calling context.
;;;
(define-method (code:add-calling-context-formal (o <formals>))
  (if (not (%calling-context)) o
      (let* ((cc-formal (make <formal>
                          #:name "dzn_cc"
                          #:direction 'inout
                          #:type.name (make <scope.name>
                                        #:ids '("*calling-context*"))))
             (cc-formal (clone cc-formal #:parent o))
             (lst (cons cc-formal (ast:formal* o))))
        (clone o #:elements lst))))

(define-method (code:formal* (o <formals>))
  (ast:formal* (code:add-calling-context-formal o)))

(define-method (code:formal* (o <signature>))
  (code:formal* (.formals o)))

(define-method (code:formal* (o <function>))
  (code:formal* (.signature o)))

(define-method (code:formal* (o <event>))
  (code:formal* (.signature o)))

(define-method (code:formal* (o <action>))
  (code:formal* (.event o)))

(define-method (code:formal* (o <trigger>))
  (code:formal* (.formals o)))

(define-method (code:formal* (o <on>))
  (code:formal*
   (let* ((trigger ((compose car ast:trigger*) o))
          (formals ((compose .formals .signature) trigger))
          (event (.event trigger))
          (elements (map (cute clone <> #:name <>)
                         (ast:formal* event)
                         (map .name (ast:formal* formals)))))
     (clone formals #:elements elements))))

(define (code:add-calling-context-argument arguments)
  (if (%calling-context) (cons "dzn_cc" arguments)
      arguments))

(define-method (code:argument* (o <call>))
  (code:add-calling-context-argument (ast:argument* o)))

(define-method (code:argument* (o <action>))
  (code:add-calling-context-argument (ast:argument* o)))

(define-method (code:number-formals formals)
  (map (cute clone <> #:name <>)
       formals (iota (length formals))))

(define-method (code:number-argument (o <formal>))
  (if (ast:in? o) (.name o)
      (simple-format #f "_~a" (.name o))))

(define-method (code:on (o <trigger>))
  (or (ast:parent o <on>)
      (let ((model (ast:parent o <model>)))
        (and (is-a? model <component>)
             (let* ((behavior (.behavior model))
                    (trigger (car (tree-collect (cute ast:equal? <> o)
                                                behavior))))
               (ast:parent trigger <on>))))))


;;;
;;; Constraint.
;;;
(define-method (code:capture-name (o <variable>))
  (string-append "dzn"
                 "_"
                 "capture"
                 "_"
                 (.name o)))

(define-method (code:defer-condition (o <defer>))
  (not (or (and=> (.arguments o)(compose null? .elements))
           (null? (ast:variable* (ast:parent o <component>))))))

(define-method (code:capture-local (o <defer>))
  (let* ((references (tree-collect (disjoin(is? <assign>)
                                           (is? <argument>)
                                           (is? <var>))
                                   (.statement o)))
         (variables (map .variable references))
         (local? (compose
                  (cute ast:eq? <> o)
                  (cute ast:parent <> <defer>))))
    (filter (negate (disjoin ast:member? local?))
            variables)))

(define-method (code:defer-equality* (o <defer>))
  (filter (compose not (is? <extern>) .type) (ast:defer-variable* o)))


;;;
;;; Shared state.
;;;
(define-method (code:shared-lts-unmemoized (o <interface>))
  (let* ((debug (getenv "DZN_DEBUG_TEMPLATE"))
         (foo (unsetenv "DZN_DEBUG_TEMPLATE"))
         (debugity (dzn:debugity))
         (model-name (ast:dotted-name o))
         (root (ast:parent o <root>))
         (root' (makreel:normalize root))
         (interface' (makreel:get-model root' model-name))
         (lts (interface->constraint-lts interface'))
         (rtc-lts (lts->rtc-lts lts)))
    (when (> debugity 2)
      (display "rtc-lts:\n" (current-error-port))
      (for-each (cute write-line <> (current-error-port))
                (vector->list rtc-lts)))
    (when debug
      (setenv "DZN_DEBUG_TEMPLATE" debug))
    rtc-lts))

(define code:shared-lts
  (ast:perfect-funcq code:shared-lts-unmemoized))

(define-method (code:shared (o <event>))
  (define (trigger? o)
    (and (string? o)
         (and=> (string-match "'in\\(([^)]*\\))\\)" o)
                (cute match:substring <> 1))))
  (define (modeling? o)
    (and (string? o)
         (string-contains o "'internal(")))
  (define (action? o)
    (and (string? o)
         (and=> (string-match "'out\\(([^)]*\\))\\)" o)
                (cute match:substring <> 1))))
  (define (reply? o)
    (and (string? o)
         (and=> (string-match "'reply\\(([^)]*\\))\\)" o)
                (cute match:substring <> 1))))
  (define (state? o)
    (and (string? o)
         (and=> (string-match "'state\\(([^)]*\\))\\)" o)
                (cute match:substring <> 1))))
  (define (match-event edge)
    (let ((labels (edge-label edge)))
      (match labels
        (((and (? trigger?) trigger) tail ...)
         (string-contains trigger (string-append "in'" (.name o))))
        (((and (? action?) trigger) tail ...)
         (or (string-contains trigger (string-append "out'" (.name o)))
             (find (conjoin
                    action?
                    (cute string-contains <>
                          (string-append "out'" (.name o))))
                   tail)))
        (_
         #f))))
  (define (makreel->event o)
    (match (string-split o #\')
      ((scope ... enum field)
       (string-append enum ":" field))
      (_
       o)))
  (define (event->prefix event) ;; XXX vouw in trigger?, action?, reply?
    (or (and=> (string-match ".*'in'([^)]*)\\)" event)
               (cute match:substring <> 1))
        (and=> (string-match ".*'out'([^)]*)\\)" event)
               (cute match:substring <> 1))
        (and=> (string-match ".*'Bool\\(([^)]*)\\)" event)
               (cute match:substring <> 1))
        (and (string-match ".*'Void\\(([^)]*)\\)" event)
             "return")
        (and=> (string-match "\\(([^)]*)\\)" event)
               (compose makreel->event
                        (cute match:substring <> 1)))
        ;; HACK for debugging
        (pke "EVENT NOT FOUND" event)))
  (define (edge->prefix edge)
    (let* ((labels (edge-label edge))
           (events (filter-map (disjoin trigger? action? reply?) labels))
           (events (map event->prefix events))
           (values (map (cute make <shared-value> #:value <>) events)))
      (make <compound> #:elements values)))
  (define (edge->transition edge)
    (let ((from (edge-from edge))
          (to (edge-to edge))
          (prefix (edge->prefix edge)))
      (make <shared-transition> #:from from #:prefix prefix #:to to)))
  (let* ((debugity (dzn:debugity))
         (interface (ast:parent o <interface>))
         (lts (code:shared-lts interface))
         (nodes (vector->list lts))
         (edges (append-map node-edges nodes))
         (edges (filter match-event edges))
         (transitions (map edge->transition edges)))
    transitions))

(define-method (code:shared-state (o <interface>))
  ;;FIXME no duplicates
  (let* ((variables (ast:variable* o))
         (variable-names (map .name variables)))
    (define (state? o)
      (and (string? o)
           (and=> (string-match "'state\\(([^)]*\\))\\)" o)
                  (cute match:substring <> 1))))
    (define (edge->assign edge)
      (let* ((labels (edge-label edge))
             (state (any state? labels)))
        (and (pair? variables)
             state
             (let* ((to (edge-to edge))
                    (values (and=> (string-match "'variables\\(([^)]*)\\)" state)
                                   (cute match:substring <> 1)))
                    (values (string-split values #\,))
                    (values (map string-trim values))
                    (values (map (cute make <shared-value> #:value <>)
                                 values))
                    (statements (map (cute make <assign>
                                           #:variable.name <>
                                           #:expression <>)
                                     variable-names
                                     values))
                    (compound (make <compound> #:elements statements)))
               (make <shared-state> #:state to #:assign compound)))))
    (let* ((debugity (dzn:debugity))
           (lts (code:shared-lts o))
           (nodes (vector->list lts))
           (edges (append-map node-edges nodes))
           (assign (filter-map edge->assign edges)))
      (when (> debugity 2)
        (display "code:\n" (current-error-port))
        (display assign (current-error-port)))
      assign)))

(define-method (code:shared-value (o <shared-value>))
  (string-replace-substring (.value o) "'" (%type-infix)))

(define-method (code:shared-dzn-event-method (o <port>))
  (string-append (.name o) ".dzn_event"))

(define-method (code:shared-dzn-event-method o)
  (code:shared-dzn-event-method (.port o)))

(define-method (code:shared-update-method (o <event>))
  (string-append "dzn_" (code:direction o) "_" (.name o)))

(define-method (code:shared-update-method o)
  (string-append (.port.name o) "." (code:shared-update-method (.event o))))


;;;
;;; System.
;;;
(define-method (code:port-end-point? (o <binding>))
  (or (and (not (.instance.name (.left o)))
           (.left o))
      (and (not (.instance.name (.right o)))
           (.right o))))

(define-method (code:instance-end-point (o <binding>))
  (let ((left (.left o))
        (right (.right o)))
    (and (code:port-binding? o)
         (if (.instance.name left) left right))))

(define-method (code:injected-binding? (o <binding>))
  (or (ast:wildcard? (.port.name (.left o)))
      (ast:wildcard? (.port.name (.right o)))))

(define-method (code:port-binding? (o <binding>))
  (and (code:port-end-point? o)
       o))

(define-method (code:component-binding* (o <system>))
  (let ((bindings (ast:binding* o)))
    (filter (negate code:port-end-point?) bindings)))

(define-method (.instance.name (o <binding>))
  (.instance.name (code:instance-end-point o)))

(define-method (code:instance* (o <system>))
  (let ((injected (map .instance.name (code:injected-binding* o))))
    (partition (compose not (cute member <> injected) .name)
               (ast:instance* o))))

(define-method (code:injected-instance* (o <system>))
  (let ((instances injected (code:instance* o)))
    injected))

(define-method (code:injected-binding* (o <system>))
  (filter code:injected-binding? (ast:binding* o)))

(define-method (code:provides+requires-end-point (o <binding>))
  (let* ((model (ast:parent o <model>))
         (left (.left o))
         (left-port (.port left))
         (right (.right o))
         (right-port (.port right)))
    (if (and left-port (ast:provides? left-port)) (values left right)
        (values right left))))

(define-method (code:provides-end-point (o <binding>))
  (let ((provides requires (code:provides+requires-end-point o)))
    provides))

(define-method (code:requires-end-point (o <binding>))
  (let ((provides requires (code:provides+requires-end-point o)))
    requires))

(define-method (code:end-point->string (o <end-point>))
  (string-append (.instance.name o) "." (.port.name o)))


;;;
;;; Main.
;;;
(define-method (code:return-values (o <component-model>))
  (define (trigger->port-pairs trigger)
    (map (cute make
               <port-pair>
               #:port (.port.name trigger)
               #:other <>)
         (map ->sexp (ast:return-values trigger))))
  (let* ((triggers (filter (compose not (is? <void>) ast:type)
                           (ast:requires-in-triggers o)))
         (pairs (append-map trigger->port-pairs triggers)))
    (delete-duplicates pairs (lambda (a b)
                               (and (ast:eq? (.port a) (.port b))
                                    (equal? (.other a) (.other b)))))))

(define-method (code:requires-in-void-returns (o <component-model>))
  (let ((triggers (ast:requires-in-void-triggers o)))
    (delete-duplicates triggers
                       (lambda (a b)
                         (ast:eq? (.port a) (.port b))))))


;;;
;;; Transform.
;;;
(define-method (code:add-calling-context (o <root>))
  (if (not (%calling-context)) o
      (let* ((name (make <scope.name> #:ids '("*calling-context*")))
             (extern (make <extern>
                       #:name name
                       #:value (%calling-context))))
        (clone o #:elements (cons extern (ast:top* o))))))

(define (code:annotate-shells o)
  (let ((shell? (and (is-a? o <system>)
                     (equal? (%shell) (string-join (ast:full-name o) ".")))))
    (if (not shell?) o
        (let ((shell (make <shell-system>
                       #:ports (.ports o)
                       #:name (.name o)
                       #:instances (.instances o)
                       #:bindings (.bindings o))))
          (clone shell #:parent (.parent o))))))

(define (code:normalize- ast)
  (parameterize ((%normalize:short-circuit? code:short-circuit?))
    ((compose
      add-reply-port
      normalize:event+illegals
      remove-otherwise
      (binding-into-blocking)
      code:add-calling-context)
     ast)))

(define (code:normalize ast)
  (let ((root (code:normalize- ast)))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print root (current-error-port)))
    root))

(define (code:normalize+determinism ast)
  (parameterize ((%normalize:short-circuit? code:short-circuit?))
    (let ((root ((compose
                  add-determinism-temporaries
                  code:normalize-)
                 ast)))
      (when (> (dzn:debugity) 1)
        (ast:pretty-print root (current-error-port)))
      root)))

(define (code:short-circuit? o)
  (match o
    ((or ($ <foreign>) ($ <system>))
     o)
    ((and (or ($ <interface>) ($ <component>)) (? ast:imported?))
     o)
    (_
     #f)))


;;;
;;; Entry point.
;;;
(define* (code ast #:key (ast-> 'ast->) calling-context dir language locations?
               model shell)
  (let* ((module (resolve-module `(dzn code language ,(string->symbol language))))
         (ast-> (false-if-exception (module-ref module ast->))))
    (unless ast->
      (format (current-error-port) "code: no such language: ~a\n" language)
      (exit EXIT_OTHER_FAILURE))
    (parameterize ((%calling-context calling-context)
                   (%locations? locations?)
                   (%shell shell))
      (ast-> ast #:dir dir #:model model))))
