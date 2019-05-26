;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2014, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (gaiag wfc)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag display)
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)

  #:use-module (gaiag misc)
  #:use-module (gaiag parse)

  #:export (
           ast:wfc
           ))

(define (ast:wfc o)
  (let ((errors (wfc o)))
    (when (pair? errors)
      (for-each report-error errors)
      (exit 1)))
  o)

(define (report-error o)
  (let* ((ast (.ast o))
         (loc (.location ast)))
    (if loc
        (stderr "~a:~a:~a: error: ~a\n" (.file-name loc) (.line loc) (.column loc) (.message o))
        (stderr "error: ~a\n" (.message o)))))

(define (wfc-error o message)
  (make <error> #:ast o #:message message))

(define-method (wfc (o <root>))
  (append
   (append-map wfc (ast:type* o))
   (append-map wfc (ast:model* o))))

(define-method (wfc o)
  '())

(define-method (wfc (o <interface>))
  (append
   (append-map wfc (ast:type* o))
   (append-map wfc (ast:event* o))
   (if (.behaviour o) '()
       `(,(wfc-error o "interface must have a behaviour")))
   (or (and=> (.behaviour o) wfc) '())))

(define-method (wfc (o <component>))
  (append
   (if (>0 (length (ast:provides-port* o))) '()
       `(,(wfc-error o "component with behaviour must have a provides port")))
   (append-map wfc (ast:port* o))
   (or (and=> (.behaviour o) wfc) '())))

(define-method (wfc (o <component-model>))
  (append-map wfc (ast:port* o)))

(define-method (wfc (o <system>))
  (append
   (append-map wfc (ast:port* o))
   (binding-direction o)
   (double-bindings o)
   (missing-bindings o)))

(define-method (wfc (o <behaviour>))
  (append
   (append-map variable-re-declaration (tree-collect (is? <variable>) o))
   (append-map wfc (ast:type* o))
   (on o)
   (guard o)
   (mixing-declarative-imperative o)
   (trigger o)
   (action o)
   (assign o)
   (call-context o)
   (tail-recursion o)
   (missing-return o)
   (blocking o)
   (reply o)
   (return o)
   (illegal o)
   (otherwise o)))

(define-method (wfc (o <type>))
  '())

(define-method (wfc (o <enum>))
  (re-declaration o))

(define-method (re-declaration (o <declaration>) scope)
  (let* ((name (.name o))
         (name (if (is-a? name <scope.name>) (.name name) name))
         (previous (ast:lookup scope name)))
    (if (and previous
             (ast:eq? (parent previous <model>) (parent o <model>))
             (not (ast:eq? previous o))
             (not (is-a? previous <namespace>)))
        `(,(wfc-error o (format #f "identifier `~a' declared before" (ast:name o)))
          ,(wfc-error previous (format #f "previous `~a' declared here" (ast:name previous))))
        '())))

(define-method (re-declaration (o <declaration>))
  (let ((scope (or (and=> (parent o <model>) .parent)
                    (and=> (.parent o) (cut parent <> <scope>)))))
    (re-declaration o scope)))

(define-method (variable-re-declaration (o <variable>))
  (append (re-declaration o)
          (let ((scope (parent o <compound>)))
            (if scope (re-declaration o scope)
                '()))))

(define-method (wfc (o <int>))
  (let ((range (.range o)))
    (if (<= (.from range) (.to range)) '()
        `(,(wfc-error o (format #f "subint ~a has empty range" (type-name (.name o))))))))

;;;;;;;;;;;;;;; expressions

(define-method (wfc (o <enum-literal>))
  (let ((type (.type o)))
    (cond ((not type)
           `(,(wfc-error o (format #f "undefined identifier `~a'" (type-name (.type.name o))))))
          ((not (is-a? type <enum>))
           `(,(wfc-error o (format #f "enum type expected, found ~a" (type-name (.name type))))))
          (else (let ((field (.field o))
                      (fields (ast:field* type)))
                  (if (not (member field fields))
                      `(,(wfc-error o (format #f "no field `~a' in enum `~a`; expected ~a"
                                              field
                                              (type-name o)
                                              (string-join (map symbol->string fields) ", ")))
                        ,(wfc-error type "enum declared here"))
                      '()))))))

(define-method (wfc (o <literal>)) '())

(define-method (wfc (o <group>))
  (wfc (.expression o)))

(define-method (typed-expression (o <expression>) (type <class>))
  (let* ((expr-wfc (wfc o))
         (expr-type (ast:type o)))
    (cond ((pair? expr-wfc) expr-wfc)
          ((not (is-a? expr-type type))
           `(,(wfc-error o (format #f "~a expression expected" (class-name type)))))
          (else '()))))

(define-method (wfc (o <not>))
  (typed-expression (.expression o) <bool>))

(define-method (typed-binary (o <binary>) (type <class>))
  (let* ((expr1 (.left o))
         (expr1-wfc (typed-expression expr1 type))
         (expr2 (.right o))
         (expr2-wfc (typed-expression expr2 type)))
    (append expr1-wfc expr2-wfc)))

(define-method (binary-equal-type (o <binary>))
  (let* ((expr1 (.left o))
         (expr1-wfc (wfc  expr1))
         (expr1-type (ast:type expr1))
         (expr2 (.right o))
         (expr2-wfc (wfc expr2))
         (expr2-type (ast:type expr2)))
    (cond ((or (pair? expr1-wfc) (pair? expr2-wfc)) (append expr1-wfc expr2-wfc))
          ((and (not (ast:equal? expr1-type expr2-type))
                (not (and (is-a? expr1-type <extern>)
                          (is-a? expr2-type <data>)))
                (not (and (is-a? expr1-type <int>)
                          (is-a? expr2-type <int>)))
                `(,(wfc-error o (format #f "type mismatch in binary operator: `~a' versus `~a'"
                                        (type-name expr1-type)
                                        (type-name expr2-type))))))
          (else '()))))

(define-method (wfc (o <and>)) (typed-binary o <bool>))
(define-method (wfc (o <or>)) (typed-binary o <bool>))

(define-method (wfc (o <equal>)) (binary-equal-type o))
(define-method (wfc (o <not-equal>)) (binary-equal-type o))

(define-method (wfc (o <greater-equal>)) (typed-binary o <int>))
(define-method (wfc (o <greater>)) (typed-binary o <int>))
(define-method (wfc (o <less-equal>)) (typed-binary o <int>))
(define-method (wfc (o <less>)) (typed-binary o <int>))
(define-method (wfc (o <plus>)) (typed-binary o <int>))
(define-method (wfc (o <minus>)) (typed-binary o <int>))

(define-method (wfc (o <field-test>))
  (let* ((variable (.variable o))
         (type (and=> variable .type))
         (field (.field o))
         (fields (and=> type ast:field*)))
    (cond ((not variable)
           `(,(wfc-error o (format #f "undefined variable `~a'" (.variable.name o)))))
          ((not type)
           '()) ;; already covered (?)
          ((not (is-a? type <enum>))
           `(,(wfc-error o (format #f "type mismatch: expected enum, found '~a'"
                                   (type-name type)))))
          ((not (member field fields))
           `(,(wfc-error o (format #f "no field `~a' in enum `~a'; expected ~a"
                                   field
                                   (type-name type)
                                   (string-join (map symbol->string fields) ", ")))
             ,(wfc-error type "enum declared here")))
          (else '()))))

(define-method (wfc (o <otherwise>)) '())

(define-method (wfc (o <var>))
  (let ((variable (.variable o)))
    (cond ((not variable)
           `(,(wfc-error o (format #f "undefined variable  '~a'" (.variable.name)))))
          (else '()))))

(define-method (wfc (o <action>)) (action o))

(define-method (wfc (o <call>)) (call-context o))

(define-method (wfc (o <data>)) '())

(define-method (wfc (o <expression>))
;;  (warn 'wfc:--------------UNCOVERED-------------- o)
  '())

(define-method (assign (o <behaviour>))
  (append-map assign (tree-collect (disjoin (is? <assign>) (is? <variable>)) o)))

(define-method (assign (o <ast>))
  (let* ((assign-type (ast:type o))
         (expression (.expression o))
         (wfce (wfc expression))
         (expression-type (if (null? wfce) (ast:type expression) #f)))
    (cond ((pair? wfce) wfce)
          ((and (not assign-type) (is-a? o <variable>))
           `(,(wfc-error o (format #f "unknown type name `~a'" (type-name (.type.name o))))))
          ((and (is-a? o <variable>) (is-a? expression-type <void>))
           (if (is-a? assign-type <extern>) '()
               `(,(wfc-error o (format #f "uninitialized variable `~a' " (.name o))))))
          ((and (not (ast:equal? expression-type assign-type))
                (not (and (is-a? assign-type <extern>)
                          (is-a? expression <data>)))
                (not (and (is-a? assign-type <int>)
                          (is-a? expression-type <int>)))
                `(,(wfc-error o (format #f "type mismatch: expected `~a', found `~a'"
                                        (type-name assign-type)
                                        (type-name expression-type))))))
          (else '()))))

(define-method (blocking (o <behaviour>))
  (append-map blocking (tree-collect (is? <blocking>) o)))

(define-method (blocking (o <blocking>))
  (let ((model (parent o <model>)))
    (cond ((is-a? model <interface>)
           `(,(wfc-error o "cannot use blocking in an interface")))
          ((parent (.parent o) <blocking>)
           `(,(wfc-error o "nested blocking used")
             ,(wfc-error (parent (.parent o) <blocking>) "within blocking here")))
          ((> (length (ast:provides-port* model)) 1)
           `(,(wfc-error o "blocking with multiple provide ports not supported")))
          (else '()))))

(define-method (wfc (o <event>))
  (append
   (cond ((and (ast:out? o) (not (is-a? (ast:type o) <void>)))
          `(,(wfc-error o (format #f "out-event `~a' must be void, found `~a'" (.name o) (type-name (ast:type o))))))
         (else '()))
   (append-map event-formal (ast:formal* o))))

(define-method (event-formal (o <formal>))
  (let ((type (ast:type o)))
    (cond ((not type)
           `(,(wfc-error o (format #f "unknown type name `~a'" (type-name (.type.name o))))))
          ((not (is-a? type <extern>))
           `(,(wfc-error o (format #f "type mismatch: parameter `~a'; expected extern, found `~a'" (.name o) (type-name type)))))
          ((let ((event (parent o <event>)))
             (and (ast:out? event)
                  (or (ast:out? o) (ast:inout? o))
                  `(,(wfc-error o (format #f "~a-parameter not allowed on out-event `~a'" (.direction o) (.name event)))))))
          (else '()))))

(define-method (wfc (o <port>))
  (append
   (re-declaration o)
   (let ((interface (.type o)))
     (cond ((not interface)
            `(,(wfc-error o (format #f "undefined interface `~a'" (type-name (.type.name o))))))
           ((not (is-a? interface <interface>))
            `(,(wfc-error o (format #f "interface expected, found `~a ~a'" (ast-name interface) (type-name interface)))))
           ((and (.injected o)
                 (let ((out-events (filter ast:out? (ast:event* o))))
                   (and (pair? out-events)
                        `(,(wfc-error o (format #f "injected port `~a' has out events: ~a" (.name o)
                                                (string-join (map (compose symbol->string .name) out-events) ", ")))
                          ,@(map (cut wfc-error <> (format #f "defined here")) out-events))))))
           (else '())))))

(define-method (illegal (o <behaviour>))
  (append-map illegal (tree-collect (is? <illegal>) o)))

(define-method (illegal (o <illegal>))
  (let ((model (parent o <model>)))
   (cond ((and (is-a? model <interface>) (parent (.parent o) <function>))
          `(,(wfc-error o "cannot use illegal in function")))
         ((and (is-a? model <interface>) (parent (.parent o) <if>))
          `(,(wfc-error o "cannot use illegal in if-statement")))
         ((let loop ((compound (.parent o)))
            (and compound
                 (is-a? compound <compound>)
                 (ast:imperative? compound)
                 (or (and (let ((statements (ast:statement* compound)))
                            (and (> (length statements) 1)
                                 `(,(wfc-error o "cannot use illegal with imperative statements")
                                   ,(wfc-error (car (filter (negate (cut member <> (ast:path o) ast:eq?)) statements))
                                               "imperative statement here")))))
                     (loop (parent (.parent compound) <compound>))))))
         (else '()))))

(define (otherwise-guard? o)
  (and (is-a? o <guard>)
       (is-a? (.expression o) <otherwise>)))

(define-method (otherwise (o <behaviour>))
  (append-map otherwise (tree-collect otherwise-guard? o)))

(define-method (otherwise (o <guard>))
  (cond ((let ((compound (parent o <compound>)))
           (and compound
                (or (and (let ((statements (filter (negate (is? <guard>)) (ast:statement* compound))))
                           (and (pair? statements)
                                `(,(wfc-error o "cannot use otherwise with non-guard statements")
                                  ,(wfc-error (car statements)
                                              "non-guard statement here")))))
                    (and (let ((statements (filter (conjoin otherwise-guard? (negate (cut ast:eq? <> o)))
                                                   (member o (ast:statement* compound) ast:eq?))))
                           (and (pair? statements)
                                `(,(wfc-error o "cannot use otherwise guard more than once")
                                  ,(wfc-error (car statements)
                                              "second otherwise here")))))))))
        (else '())))

(define-method (type-name (o <ast>))
  (symbol-join (ast:full-name o) '.))

(define-method (type-name (o <scope.name>))
  (symbol-join (append (.scope o) (list (.name o))) '.))

(define-method (reply (o <behaviour>))
  (let ((replies (tree-collect (is? <reply>) o)))
    (append
     (append-map reply replies)
     (let ((model (parent o <model>)))
       (if (or (not (is-a? model <component>))
               (<= (length (ast:provides-port* model)) 1)) '()
               (append-map reply-without-port (filter (negate .port) replies)))))))

(define-method (reply (o <reply>))
  (let ((on (parent o <on>)))
    (if (not on) '() ;; FIXME: handled elsewhere?
        (append-map (cut reply o <>) (ast:trigger* on)))))

(define-method (reply (o <reply>) (trigger <trigger>))
  (let* ((component (parent o <component>))
         (event (if (and component (pair? (tree-collect (is? <blocking>) component)) (ast:requires? trigger)) (car (ast:event* (ast:provides-port component)))
                    (.event trigger)))
         (event-type (ast:type event))
         (reply-type (ast:type o)))
    (or (and (or (not (.port.name o))
                 (eq? (.port.name o) (.port.name trigger)))
             (not (ast:equal? event-type reply-type))
             (not (and (is-a? event-type <int>)
                       (is-a? reply-type <int>)))
             `(,(wfc-error o (format #f "type mismatch: expected `~a', found `~a'"
                                     (type-name event-type)
                                     (type-name reply-type)))
               ,(wfc-error event "event defined here")))
        '())))

(define-method (reply-without-port (o <reply>))
  (define (trigger->string o)
    (format #f "~a.~a" (.port.name o) (.event.name o)))
  (let ((on (parent o <on>)))
    (cond ((not on)
           `(,(wfc-error o "must specify a provides-port with reply")))
          ((let ((out-triggers (filter (compose ast:requires? .port) (ast:trigger* on))))
             (and (pair? out-triggers)
                  `(,(wfc-error o (format #f "must specify a provides-port with out-event: ~a"
                                          (string-join (map trigger->string out-triggers) ", ")))))))
          (else '()))))

(define-method (return (o <behaviour>))
  (append-map return (tree-collect (is? <return>) o)))

(define-method (return (o <return>))
  (let ((function (parent o <function>)))
    (cond ((not function)
           `(,(wfc-error o "cannot use return outside of function")))
          ((let ((function-type (ast:type function))
                 (return-type (ast:type o)))
             (and (not (ast:equal? function-type return-type))
                  (not (and (is-a? function-type <int>)
                            (is-a? return-type <int>)))
                  `(,(wfc-error o (format #f "type mismatch: expected `~a', found `~a'"
                                          (type-name function-type)
                                          (type-name return-type)))))))
          (else '()))))

(define-method (on (o <behaviour>))
  (append-map on (tree-collect (is? <on>) o)))

(define-method (on (o <on>))
  (append
   (let ((parent (parent (.parent o) <on>)))
     (if parent `(,(wfc-error o "nested on used")
                  ,(wfc-error parent "within on here"))
         '()))
   (if (is-a? (parent o <model>) <interface>) (modeling-silent o)
       '())))

(define-method (guard (o <behaviour>))
  (append-map guard (tree-collect (is? <guard>) o)))

(define-method (guard (o <guard>))
  (wfc (.expression o)))

(define-method (modeling-silent (o <on>))
  (if (and (or (eq? (.silent? o) *unspecified*)
               (is-a? (.silent? o) <ast>)) ((@@ (gaiag peg) any-modeling?) o))
      `(,(wfc-error o (format #f "cannot determine silentness"))
        ,@(if (is-a? (.silent? o) <ast>) `(,(wfc-error (.silent? o) (format #f "may communicate or be silent")))
              '()))
      '()))

(define-method (action-statement? o)
  (and (is-a? o <action>) (not (parent o <variable>)) (not (parent o <assign>))))

(define-method (call-statement? o)
  (and (is-a? o <call>) (not (parent o <variable>)) (not (parent o <assign>))))

(define-method (action (o <behaviour>))
  (append-map action (tree-collect action-statement? o)))

(define-method (action (o <action>))
  (let ((event (.event o))
        (model (parent o <model>)))
    (cond ((and (is-a? model <interface>) (not event))
           `(,(wfc-error o (format #f "undefined event `~a'" (.event.name o)))))
          ((and (is-a? model <interface>) (ast:in? event))
              `(,(wfc-error o (format #f "cannot use ~a-event `~a' as action" (.direction event) (.event.name o)))
                ,(wfc-error event (format #f "event `~a' declared here" (.event.name o)))))
          ((and (is-a? model <component>) (not event))
           (let ((port (.port o)))
             (if (not port)
                 `(,(wfc-error o (format #f "undefined port `~a'" (.port.name o))))
                 `(,(wfc-error o (format #f "event `~a' not defined for port `~a'"
                                         (.event.name o) (.port.name o)))
                   ,(wfc-error (.port o) (format #f "port `~a' declared here" (.port.name o)))))))
          ((and (is-a? model <component>)
                (or (and (ast:in? event) (ast:provides? (.port o)))
                    (and (ast:out? event) (ast:requires? (.port o)))))
           `(,(wfc-error o (format #f "cannot use ~a ~a-event `~a' as action"
                                   (.direction (.port o)) (.direction event) (.event.name o)))
             ,(wfc-error (.port o) (format #f "port `~a' declared here" (.port.name o)))
             ,(wfc-error event (format #f "event `~a' declared here" (.event.name o)))))
          (else '()))))

(define-method (trigger (o <behaviour>))
  (append-map trigger (tree-collect (is? <trigger>) o)))

(define-method (trigger (o <trigger>))
  (let ((port (.port o))
        (event (.event o))
        (model (parent o <model>)))
    (cond ((and (is-a? model <component>) (not port))
           `(,(wfc-error o (format #f "undefined port `~a'" (.port.name o)))))
          ((not event)
           `(,(wfc-error o (format #f "event `~a' not defined for port `~a'"
                                   (.event.name o) (.port.name o)))
             ,(wfc-error (.port o) (format #f "port `~a' declared here" (.port.name o)))))
          ((and (is-a? model <interface>) (ast:out? event))
           `(,(wfc-error o (format #f "cannot use ~a-event `~a' as trigger" (.direction event) (.event.name o)))
             ,(wfc-error event (format #f "event `~a' declared here" (.event.name o)))))
          ((and (is-a? model <component>)
                (or (and (ast:out? event) (ast:provides? (.port o)))
                    (and (ast:in? event) (ast:requires? (.port o)))))
           `(,(wfc-error o (format #f "cannot use ~a ~a-event `~a' as trigger"
                                   (.direction (.port o)) (.direction event) (.event.name o)))
             ,(wfc-error (.port o) (format #f "port `~a' declared here" (.port.name o)))
             ,(wfc-error event (format #f "event `~a' declared here" (.event.name o)))))
          (else '()))))

(define-method (call-context (o <behaviour>))
  (append-map call-context (tree-collect (disjoin action-statement? call-statement?) o)))

(define-method (call-context (o <ast>))
  (let ((p (.parent o))
        (class (ast-name (class-of o)))
        (name (if (is-a? o <action>) (.event.name o) (.function.name o)))
        (definition (if (is-a? o <action>) (.event o) (.function o))))
    (cond ((not definition)
           `(,(wfc-error o (format #f "undefined identifier `~a'" name))))
          ((and (not (is-a? p <variable>))
                (or (is-a? p <expression>)
                    (and (is-a? p <if>)
                         (not (ast:eq? o (.then p)))
                         (not (ast:eq? o (.else p))))))
           `(,(wfc-error o (format #f "~a in expression" class))))
          ((and (not (parent o <on>))
                (not (parent o <function>)))
           `(,(wfc-error o (format #f "~a outside on" class))))
          ((and (is-a? (ast:type o) <void>)
                (is-a? p <variable>))
           `((wfc-error o "void value not ignored as it ought to be")))
          ((and (not (is-a? (ast:type o) <void>))
                (not (is-a? p <assign>))
                (not (is-a? p <variable>)))
           `(,(wfc-error o (format #f "valued ~a must be used in variable assignment" class))))
          (else '()))))

(define-method (binding-direction (o <system>))
  (append-map binding-direction (ast:binding* o)))

(define-method (binding-direction (o <binding>))
  (let ((left (.left o))
        (right (.right o)))
    (cond ((and (ast:wildcard? (.port.name left))
                (ast:wildcard? (.port.name right)))
           `(,(wfc-error o "cannot bind two wildcards")))
          ((and (ast:wildcard? (.port.name left))
                (ast:requires? (.port right)))
           `(,(wfc-error o (format #f "cannot bind wildcard to ~a port `~a'" (.direction (.port right)) (.port.name right)))
             ,(wfc-error (.port right) (format #f "port `~a' declared here" (.port.name right)))))
          ((and (ast:wildcard? (.port.name right))
                (ast:requires? (.port left)))
           `(,(wfc-error o (format #f "cannot bind wildcard to ~a port `~a'" (.direction (.port left)) (.port.name left)))
             ,(wfc-error (.port left) (format #f "port `~a' declared here" (.port.name left)))))
          ((or (and
                (.instance.name left)
                (.instance.name right)
                (.port left)
                (.port right)
                (eq? (.direction (.port left))
                     (.direction (.port right))))
               (and
                (or (and (.instance.name left) (not (.instance.name right)))
                    (and (.instance.name right) (not (.instance.name left))))
                (.port left)
                (.port right)
                (not (eq? (.direction (.port left))
                          (.direction (.port right))))))
           `(,(wfc-error o (format #f "cannot bind ~a port `~a' to ~a port `~a'"
                                   (.direction (.port left)) (.port.name left)
                                   (.direction (.port right)) (.port.name right)))
             ,(wfc-error (.port left) (format #f "port `~a' declared here" (.port.name left)))
             ,(wfc-error (.port right) (format #f "port `~a' declared here" (.port.name right)))))
          ((or (and
                (.instance.name left)
                (.instance.name right)
                (.port left)
                (.port right)
                (not (eq? (.external (.port left))
                          (.external (.port right)))))
               (and
                (or (and (.instance.name left) (not (.instance.name right)))
                    (and (.instance.name right) (not (.instance.name left))))
                (.port left)
                (.port right)
                (not (eq? (.external (.port left))
                          (.external (.port right))))))
           `(,(wfc-error o (format #f "cannot bind ~a port `~a' to ~a port `~a'"
                                   (or (.external (.port left)) 'non-external) (.port.name left)
                                   (or (.external (.port right)) 'non-external) (.port.name right)))
             ,(wfc-error (.port left) (format #f "port `~a' declared here" (.port.name left)))
             ,(wfc-error (.port right) (format #f "port `~a' declared here" (.port.name right)))))
          (else '()))))

(define-method (double-bindings (o <system>))
  (append-map double-bindings (ast:binding* o)))

(define-method (double-bindings (o <binding>))
  (append
   (double-bindings (.left o) (.right o))
   (let ((bindings (member o (ast:binding* (parent o <system>)) ast:eq?)))
     (append-map (cute double-bindings o <>) bindings))))

(define-method (double-bindings (o <binding>) (x <binding>))
  (let ((left (.left o))
        (right (.right o))
        (xleft (.left x))
        (xright (.right x)))
    (if (or (ast:wildcard? (.port.name xleft))
                  (ast:wildcard? (.port.name xright))
                  (ast:eq? o x)) '()
                  (append (double-bindings left xleft)
                          (double-bindings left xright)
                          (double-bindings right xleft)
                          (double-bindings right xright)))))

(define-method (double-bindings (o <end-point>) (x <end-point>))
  (cond ((or (ast:wildcard? (.port.name o)) (ast:wildcard? (.port.name x))) '())
        ((ast:equal? o x) `(,(wfc-error o (format #f "port `~a' is bound more than once" (.port.name o)))
                            ,(wfc-error x (format #f "port `~a' is bound more than once"  (.port.name x)))))
        (else '())))

(define-method (missing-bindings (o <system>))
  (append (append-map missing-bindings (ast:port* o))
          (append-map missing-bindings (ast:instance* o))))

(define-method (missing-bindings (o <port>))
  (missing-bindings o (parent o <system>) #f))

(define-method (missing-bindings (o <port>) (system <system>) instance)
  (let* ((bindings (ast:binding* system))
         (ports (append (filter-map (compose .port .left) bindings)
                        (filter-map (compose .port .right) bindings))))
    (if (member o ports ast:eq?) '()
        `(,(wfc-error o (format #f "port `~a' not bound" (.name o)))
          ,@(if (not instance) '()
                `(,(wfc-error instance (format #f "of instance: `~a'" (.name instance)))))))))

(define-method (missing-bindings (o <instance>))
  (append-map
   (cute missing-bindings <> (parent o <system>) o)
   (filter (negate .injected) (ast:port* (.type o)))))

(define (mixing-declarative-imperative o)
  (match o
    (($ <behaviour>) (or (and=> (.statement o) mixing-declarative-imperative) '()))
    ((and ($ <compound>) (? ast:declarative?))
     (append
      (or (and-let* ((imperative
                      (null-is-#f (filter ast:imperative? (ast:statement* o))))
                     (ast (car imperative)))
            (list (wfc-error ast "declarative statement expected")))
          '())
      (append-map mixing-declarative-imperative (ast:statement* o))))
    (($ <compound>)
     (append
      (or (and-let* ((declarative
                      (null-is-#f (filter ast:declarative? (ast:statement* o))))
                     (ast (car declarative)))
            (list (wfc-error ast "imperative statement expected")))
          '())
      (append-map mixing-declarative-imperative (ast:statement* o))))
    (($ <on>) (mixing-declarative-imperative (.statement o)))
    (($ <guard>) (mixing-declarative-imperative (.statement o)))
    ((and ($ <if>) (= .then then) (= .else #f)) (mixing-declarative-imperative then))
    ((and ($ <if>) (= .then then) (= .else else)) (append (mixing-declarative-imperative then)
                                                          (mixing-declarative-imperative else)))
    (_ '())))

(define-method (tail-recursion (o <behaviour>))
  (append-map tail-recursion (ast:function* o)))

(define-method (tail-recursion (o <function>))
  (let ((calls (tree-collect (is? <call>) o)))
    (append-map tail-recursion calls)))

(define-method (tail-recursion (o <call>) ;;recursing
                               )
  (let ((function (parent o <function>)))
    (if (or (not function)
            (not (eq? (.name function) (.function.name o)))) '()
            (let* ((continuation ((compose car wfc:continuation) o))
                   (continuation (if (is-a? continuation <variable>) ((compose car (@@ (gaiag makreel) makreel:continuation)) continuation) continuation))
                   (continuation (and continuation
                                      (not (ast:eq? continuation (.statement (parent o <function>))))
                                      (not (is-a? continuation <return>))
                                      continuation)))
              (if continuation `(,(wfc-error o "recursive function not in tail call")
                                 ,(wfc-error continuation "next statement"))
                  '())))))

(define-method (missing-return (o <behaviour>))
  (append-map missing-return (ast:function* o)))

(define-method (wfc:continuation (o <ast>))
  ((@@ (gaiag makreel) makreel:continuation) o))

(define-method (wfc:continuation (o <if>))
  (cons ((@@ (gaiag makreel) makreel:then-continuation) o)
        ((@@ (gaiag makreel) makreel:else-continuation) o)))

(define-method (missing-return (o <function>))
  (if (is-a? (ast:type o) <void>) '()
      (let loop ((heads (list (.statement o))) (missing-returns '()))
        (if (null? heads) missing-returns
            (let loop2 ((heads heads) (continuations '()) (missing-returns '()))
              (if (null? heads) (loop continuations missing-returns)
                  (let* ((head (car heads))
                         (continuation (wfc:continuation head))
                         (continuation (filter (negate (is? <return>)) continuation))
                         (missing-return (filter (cut ast:eq? <> (.statement o)) continuation))
                         (continuation (filter (negate (cut ast:eq? <> (.statement o))) continuation)))
                    (loop2 (cdr heads) (append continuations continuation)
                           `(,@missing-returns
                             ,@(if (null? missing-return)  '()
                                   `(,(wfc-error head "error: missing return"))))))))))))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    ast:wfc)
   ast))
