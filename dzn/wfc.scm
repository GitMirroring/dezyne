;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2014, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn wfc)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn display)
  #:use-module (dzn goops)
  #:use-module (dzn ast)

  #:use-module (dzn misc)
  #:use-module (dzn parse)

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
   (append-map wfc (ast:model* o))
   (append-map wfc (ast:type* o))))

(define-method (wfc (o <model>))
  '())

(define-method (wfc (o <interface>)) ;; is-a <model>
  (append
   (re-declaration o)
   (append-map wfc (ast:type* o))
   (append-map wfc (ast:event* o))
   (if (.behaviour o) (wfc (.behaviour o))
       `(,(wfc-error o "interface must have a behaviour")))))

(define-method (wfc (o <component-model>)) ;; is-a <model>
  (append-map wfc (ast:port* o)))

(define-method (wfc (o <component>)) ;; is-a <component-model>
  (append
   (re-declaration o)
   (if (>0 (length (ast:provides-port* o))) '()
       `(,(wfc-error o "component with behaviour must have a provides port")))
   (append-map wfc (ast:port* o))
   (or (and=> (.behaviour o) wfc) '())))

(define-method (wfc (o <system>)) ;; is-a <component-model>
  (append
   (re-declaration o)
   (append-map wfc (ast:port* o))
   (append-map wfc (ast:instance* o))
   (recursive o)
   (let ((errors (binding-declaration o)))
     (if (pair? errors) errors
         (let ((errors (append
                         (binding-direction o)
                         (double-bindings o)
                         (missing-bindings o))))
           (if (pair? errors) errors
               (cyclic-bindings o)))))))

(define-method (wfc (o <type>))
  (re-declaration o))

(define-method (wfc (o <enum>)) ;; is-a <type>
  (append
   (re-declaration o)
   (let loop ((fields (ast:field* o)) (result '()))
     (if (null? fields) result
         (let* ((field (car fields))
                (wf (if (find (cut equal? <> field) (cdr fields))
                        `(,(wfc-error o (format #f "duplicate enum field `~a' in enum `~a'" field (type-name (.name o)))))
                        '())))
           (loop (cdr fields) (append wf result)))))
   (if (and (parent o <model>) (ast:name-equal? (.name (parent o <model>)) (.name o)))
       `(,(wfc-error o (format #f "enum `~a' must not have the same name as the model it is declared in" (type-name (.name o)))))
       '())
   '()))

(define-method (wfc (o <int>)) ;; is-a <type>
  (append (re-declaration o)
   (let ((range (.range o)))
     (if (<= (.from range) (.to range)) '()
         `(,(wfc-error o (format #f "subint ~a has empty range" (type-name (.name o)))))))))

(define-method (wfc (o <port>))
  (append
   (re-declaration o)
   (if (ast:name-equal? (.name (parent o <model>)) (.name o))
       `(,(wfc-error o (format #f "port `~a' must not have the same name as the model it is declared in" (.name o))))
       '())
   (let ((interface (.type o)))
     (cond ((not interface)
            `(,(wfc-error o (format #f "undefined interface `~a'" (type-name (.type.name o))))))
           ((not (is-a? interface <interface>))
            `(,(wfc-error o (format #f "interface expected, found `~a ~a'" (ast-name interface) (type-name interface)))))
           ((and (.injected o)
                 (let ((out-events (filter ast:out? (ast:event* o))))
                   (and (pair? out-events)
                        `(,(wfc-error o (format #f "injected port `~a' has out events: ~a" (.name o)
                                                (string-join (map .name out-events) ", ")))
                          ,@(map (cut wfc-error <> (format #f "defined here")) out-events))))))
           (else '())))
   ;; TODO; do include async port in behaviour
   ))


(define-method (wfc (o <event>))
  (append
   (re-declaration o)
   (cond ((and (ast:out? o) (ast:type o) (not (is-a? (ast:type o) <void>)))
          `(,(wfc-error o (format #f "out-event `~a' must be void, found `~a'" (.name o) (type-name (ast:type o))))))
         (else '()))
   (wfc (.signature o))))

(define-method (wfc (o <signature>))
  (append
   (let ((type (ast:type o)))
     (cond ((not type)
            `(,(wfc-error o (format #f "unknown type name `~a'" (type-name (.type.name o))))))
           ((is-a? type <extern>)
            `(,(wfc-error o (format #f "extern type `~a' is not allowed as return type" (type-name (.type.name o))))))
           (else '())))
   (append-map wfc (ast:formal* o))))

(define-method (wfc (o <formal>))
  (append
   (re-declaration o)
   (let ((type (ast:type o))
         (event (parent o <event>)))
     (append
      (cond ((not type)
             `(,(wfc-error o (format #f "unknown type name `~a'" (type-name (.type.name o))))))
            ((and event (not (is-a? type <extern>)))
             `(,(wfc-error o (format #f "type mismatch: parameter `~a'; expected extern, found `~a'" (.name o) (type-name type)))))
            (else '()))
      (cond
       ((and event (ast:out? event) (or (ast:out? o) (ast:inout? o)))
        `(,(wfc-error o (format #f "~a-parameter not allowed on out-event `~a'" (.direction o) (.name event)))))
       (else '()))))))

(define-method (wfc (o <behaviour>))
  (append
   (append-map wfc (ast:type* o))
   (append-map wfc (ast:port* o))
   (append-map wfc (ast:variable* o))
   (append-map
    (lambda (variable)
      (if (ast:name-equal? (.name (parent o <model>)) (.name variable))
          `(,(wfc-error variable (format #f "variable `~a' must not have the same name as the model it is declared in" (.name variable))))
          '()))
    (ast:variable* o))
   (append-map wfc (ast:function* o))
   (wfc (.statement o))))

(define-method (wfc (o <variable>))
  (append
   (re-declaration o)
   (assign o)))

(define-method (wfc (o <function>))
  (append
   (re-declaration o)
   (wfc (.signature o))
   (wfc (.statement o))
   (missing-return o)))

;;;;;;;;;;;;;;;;;;;;;;; statements

(define-method (wfc (o <statement>))
  '())

(define-method (wfc (o <compound>)) ;; is-a <statement>
  (append
   (call-context o)
   (mixing-declarative-imperative o)
   (append-map wfc (ast:statement* o))))

(define-method (wfc (o <declarative>)) ;; is-a <statement>
  '())

(define-method (wfc (o <declarative-compound>)) ;; is-a <declarative>
  (append
   (mixing-declarative-imperative o)
   (append-map wfc (ast:statement* o))))

(define-method (wfc (o <guard>)) ;; is-a <declarative>
  (define (otherwise-guard? o)
  (and (is-a? o <guard>)
       (is-a? (.expression o) <otherwise>)))
  (define (otherwise o)
    (let ((compound (parent o <compound>)))
      (if (not compound) '()
          (let ((non-guards (filter (negate (is? <guard>)) (ast:statement* compound)))
                (otherwises (filter (conjoin otherwise-guard? (negate (cut ast:eq? <> o)))
                                    (member o (ast:statement* compound) ast:eq?))))
            (append
             (if (pair? non-guards)
                 `(,(wfc-error o "cannot use otherwise with non-guard statements")
                   ,(wfc-error (car non-guards) "non-guard statement here"))
                 '())
             (if (pair? otherwises)
                  `(,(wfc-error o "cannot use otherwise guard more than once")
                    ,(wfc-error (car otherwises) "second otherwise here"))
                  '()))))))
  (append
   (wfc (.expression o))
   (if (is-a? (.expression o) <otherwise>) (otherwise o) '())
   (wfc (.statement o))))

(define-method (wfc (o <declarative-illegal>)) ;; is-a <declarative>
  ;; TODO; in source??
  '())

(define-method (wfc (o <incomplete>)) ;; is-a <declarative>
  ;; TODO; in source??
  '())

(define-method (wfc (o <blocking>)) ;; is-a <declarative>
  (define (blocking o)
    (let ((model (parent o <model>)))
      (cond ((is-a? model <interface>)
             `(,(wfc-error o "cannot use blocking in an interface")))
            ((parent (.parent o) <blocking>)
             `(,(wfc-error o "nested blocking used")
               ,(wfc-error (parent (.parent o) <blocking>) "within blocking here")))
            ((> (length (ast:provides-port* model)) 1)
             `(,(wfc-error o "blocking with multiple provide ports not supported")))
            (else '()))))
  (append (blocking o) (wfc (.statement o))))

(define-method (wfc (o <on>)) ;; is-a <declarative>
  (define (on o)
    (append
     (let ((parent (parent (.parent o) <on>)))
       (if parent `(,(wfc-error o "nested on used")
                    ,(wfc-error parent "within on here"))
           '()))
     (if (is-a? (parent o <model>) <interface>) (modeling-silent o)
         '())))
  (append
   (on o)
   (append-map wfc (ast:trigger* o))
   (wfc (.statement o))))

(define-method (wfc (o <imperative>)) ;; is-a <statement>
  '())

(define-method (wfc (o <out-bindings>)) ;; is-a <imperative>
  ;; TODO: ??
  '())

(define-method (wfc (o <variable>)) ;; is-a <imperative>
  ;; (assign o):
  ;;   (.type o) defined?
  ;;   (.expression o) wfc?
  ;;   .expression matches .type
  (append
   (call-context o)
   (re-declaration o)
   (assign o)))

(define-method (wfc (o <action>)) ;; is-a <imperative>
  (append
   (action o)
   (call-context o)))

(define-method (wfc (o <action-or-call>)) ;; is-a <imperative>
  (append
   (call-context o)
   '()))

(define-method (wfc (o <assign>)) ;; is-a <imperative>
  ;; (.variable o) defined?

  ;; (assign o):
  ;;   (.type o) defined?
  ;;   (.expression o) wfc?
  ;;   .expression matches .type
  (append
   (assign o)
   (call-context o)))

(define-method (wfc (o <call>)) ;; is-a <imperative>
  (append
   (call-context o)
   (tail-recursion o)))

(define-method (wfc (o <if>)) ;; is-a <imperative>
  (let* ((expression (.expression o))
         (wfce (wfc expression)))
    (append wfce
            (if (pair? wfce) '()
                (typed-expression expression <bool>))
            (call-context o)
            (wfc (.then o))
            (if (.else o) (wfc (.else o)) '()))))

(define-method (wfc (o <illegal>)) ;; is-a <imperative>
  (define (illegal o)
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
  (append
   (call-context o)
   (illegal o)))

(define-method (wfc (o <reply>)) ;; is-a <imperative>
  (append
   (call-context o)
   (reply o)
   (reply-without-port o)
   (let* ((expr (.expression o))
          (wfc-expr (wfc expr)))
     (append wfc-expr
             (if (and expr (null? wfc-expr)) (wfc-reply-type expr)
                 '())))))

(define-method (wfc-reply-type (o <expression>))
  (let* ((reply-type (ast:type o))
         (interface (parent o <interface>))
         (interfaces
          (if interface (list interface)
              (let* ((ports (ast:port* (parent o <component-model>))))
                (filter identity (map ast:type ports)))))
         (interfaces (filter (cut is-a? <> <interface>) interfaces))
         (events (append-map ast:event* interfaces))
         (types (map (compose ast:type .signature) events))
         (matching-types (filter (cut ast:equal? <> reply-type) types)))
    (if (pair? matching-types) '()
        `(,(wfc-error o (format #f "type mismatch: no event with reply type `~a'"
                                (type-name reply-type)))))))

(define-method (wfc (o <return>)) ;; is-a <imperative>
  (let* ((wfce (if (.expression o) (wfc (.expression o)) '()))
         (function (parent o <function>))
         (function-type (and function (ast:type function)))
         (return-type (and (null? wfce) (ast:type o))))
    (append wfce
            (cond ((not function)
                   `(,(wfc-error o "cannot use return outside of function")))
                  ((pair? wfce) '())
                  ((and (not (ast:equal? function-type return-type))
                        (not (and (is-a? function-type <int>)
                                  (is-a? return-type <int>)))
                        (not (and (is-a? function-type <extern>)
                                  (is-a? return-type <data>))))
                   `(,(wfc-error o (format #f "type mismatch: expected `~a', found `~a'"
                                           (type-name function-type)
                                           (type-name return-type)))))
                  (else '())))))

(define-method (wfc (o <the-end>))  ;; is-a <statement> ;; not in source
  '())
(define-method (wfc (o <the-end-blocking>))  ;; is-a <statement> ;; not in source
  '())
(define-method (wfc (o <voidreply>))  ;; is-a <statement> ;; not in source
  '())

(define-method (wfc (o <trigger>))
  (let ((port (.port o))
        (model (parent o <model>)))
    (cond ((and (is-a? model <component>) (not port))
           `(,(wfc-error o (format #f "undefined port `~a'" (.port.name o)))))
          ((and (is-a? model <component>) (not (is-a? port <port>)))
           `(,(wfc-error o (format #f "`~a' is not a port" (.port.name o)))
             ,(wfc-error (.port o) (format #f "`~a' declared here" (.port.name o)))))
          (else (let ((event (.event o)))
                  (cond
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
                   (else '())))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; expressions

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
                                              (string-join fields ", ")))
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
           `(,(wfc-error o (format #f "type mismatch: expected enum, found `~a'"
                                   (type-name type)))))
          ((not (member field fields))
           `(,(wfc-error o (format #f "no field `~a' in enum `~a'; expected ~a"
                                   field
                                   (type-name type)
                                   (string-join fields ", ")))
             ,(wfc-error type "enum declared here")))
          (else '()))))

(define-method (wfc (o <otherwise>)) '())

(define-method (wfc (o <var>))
  (let ((variable (.variable o)))
    (cond ((not variable)
           `(,(wfc-error o (format #f "undefined variable  `~a'" (.name o)))))
          (else '()))))


(define-method (wfc (o <data>)) '())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-method (wfc (o <ast>))
  ;;  (warn 'wfc:--------------UNCOVERED-------------- o)
  '())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; helper functions

(define* (recurses? call #:optional (seen '()))
  (define (call-statement ast)
    (match ast
      (($ <call>) ast)
      ((and ($ <assign>) (? (compose (is? <call>) .expression)) (= .expression call)) call)
      ((and ($ <variable>) (? (compose (is? <call>) .expression)) (= .expression call)) call)
      (_ #f)))
  (define (.function-name call)
    (or (and=> (as (.function call) <function>) .name) (.function call)))
  (or (and (member (.function.name call) seen) seen)
      (let ((function (.function call)))
        (and function
             (let* ((compound (.statement function))
                    (call-statements (tree-collect call-statement compound))
                    (calls (delete-duplicates (map call-statement call-statements)
                                              (lambda (a b) (string< (or (.function.name a) "")
                                                                     (or (.function.name b) ""))))))
               (any identity
                    (map (lambda (c)
                           (recurses? c (cons (.function.name call) seen)))
                         calls)))))))

(define-method (tail-recursion (o <call>))
  (let ((function (parent o <function>))
        (called-function (.function o)))
    (if (or (not function)
            (not (and=> (recurses? o) (cut member (.name function) <>)))) '()
            (let* ((continuation ((compose car wfc:continuation) o))
                   (continuation (if (or (parent o <assign>) (parent o <variable>)) ((compose car (@@ (dzn makreel) makreel:continuation)) continuation) continuation))
                   (continuation (and continuation
                                      (not (ast:eq? continuation (.statement (parent o <function>))))
                                      continuation)))
              (cond ((is-a? continuation <return>)
                     `(,(wfc-error o "valued recursive functions not supported yet")
                       ,(wfc-error continuation "statement after call")))
                    (continuation `(,(wfc-error o "no statement allowed after recursive function call")
                                    ,(wfc-error continuation "statement after call")))
                    (else '()))))))

(define-method (mixing-declarative-imperative (o <compound>))
  (if (ast:declarative? o)
      (or (and-let* ((imperative
                      (null-is-#f (filter ast:imperative? (ast:statement* o))))
                     (ast (car imperative)))
            (list (wfc-error ast "declarative statement expected")))
          '())
      (or (and-let* ((declarative
                      (null-is-#f (filter ast:declarative? (ast:statement* o))))
                     (ast (car declarative)))
            (list (wfc-error ast "imperative statement expected")))
          '())))

(define-method (modeling-silent (o <on>))
  (if (and (or (eq? (.silent? o) *unspecified*)
               (is-a? (.silent? o) <ast>)) ((@@ (dzn parse silence) any-modeling?) o))
      `(,(wfc-error o (format #f "cannot determine silence"))
        ,@(if (is-a? (.silent? o) <ast>) `(,(wfc-error (.silent? o) (format #f "may communicate or be silent")))
              '()))
      '()))

(define-method (re-declaration (o <declaration>))
  (let* ((name (ast:name o))
         (scope (decl-scope o))
         (previous (and scope (ast:lookup scope name)))
         (previous-scope (and previous (decl-scope previous))))
    (if (and scope
             previous
             (ast:eq? scope previous-scope)
             (not (ast:eq? previous o))
             (not (is-a? previous <namespace>)))
        `(,(wfc-error o (format #f "identifier `~a' declared before" (ast:name o)))
          ,(wfc-error previous (format #f "previous `~a' declared here" (ast:name previous))))
        '())))


(define-method (decl-scope (o <declaration>))
  (and=> (.parent o) (cut parent <> <scope>)))

(define-method (decl-scope (o <event>))
  (parent o <interface>))

(define-method (decl-scope (o <instance>))
  (parent o <system>))

(define-method (decl-scope (o <port>))
  (parent o <component-model>))

(define-method (decl-scope (o <formal>))
  (.parent o))

(define-method (decl-scope (o <function>))
  (parent o <behaviour>))

(define-method (decl-scope (o <variable>))
  (or (parent o <compound>) (parent o <behaviour>)))

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
               `(,(wfc-error o (format #f "uninitialized variable `~a'" (.name o))))))
          ((and (not (ast:equal? expression-type assign-type))
                (not (and (is-a? assign-type <extern>)
                          (is-a? expression <data>)))
                (not (and (is-a? assign-type <int>)
                          (is-a? expression-type <int>)))
                `(,(wfc-error o (format #f "type mismatch: expected `~a', found `~a'"
                                        (type-name assign-type)
                                        (type-name expression-type))))))
          (else '()))))

(define-method (type-name (o <ast>))
  (string-join (ast:full-name o) "."))

(define-method (type-name (o <scope.name>))
  (string-join (.ids o) "."))

(define-method (reply (o <reply>))
  (let ((on (parent o <on>)))
    (if (not on) '() ;; FIXME: handled elsewhere?
        (append-map (cut reply o <>) (ast:trigger* on)))))

(define-method (reply (o <reply>) (trigger <trigger>))
  (let* ((component (parent o <component>))
         (port (and (.port.name o) (.port o)))
         (event (if (and component
                         (ast:requires? trigger)
                         (pair? (tree-collect-filter (disjoin (is? <declarative>) (is? <compound>)) (is? <blocking>) component)))
                    (car (ast:event* (ast:provides-port component)))
                    (.event trigger)))
         (event-type (and event (ast:type event)))
         (reply-type (ast:type o)))
    (cond ((and port (not (is-a? (.type port) <interface>)))
           `(,(wfc-error o (format #f "invalid type for port `~a', interface expected, found `~a ~a'"
                                   (.port.name o) (ast-name (.type port)) (type-name (.type port))))
             ,(wfc-error (.port o) (format #f "`~a' declared here" (.port.name o)))))
          ((not event) '())         ; already covered in trigger check
          ((and (or (not (.port.name o))
                    (equal? (.port.name o) (.port.name trigger)))
                (not (ast:equal? event-type reply-type))
                (not (and (is-a? event-type <int>)
                          (is-a? reply-type <int>)))
                `(,(wfc-error o (format #f "type mismatch: expected `~a', found `~a'"
                                        (and event-type (type-name event-type))
                                        (type-name reply-type)))
                  ,@(if event `(,(wfc-error event "event defined here"))
                        '()))))
          (else '()))))

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

(define-method (binding-declaration (o <system>))
  (append-map binding-declaration (ast:binding* o)))

(define-method (binding-declaration (o <end-point>))
  (let* ((instance-error (if (not (.instance.name o)) '()
                             (let ((instance (.instance o)))
                               (cond ((not instance)
                                      `(,(wfc-error o (format #f "undefined identifier `~a'" (.instance.name o)))))
                                     ((not (is-a? instance <instance>))
                                      `(,(wfc-error o (format #f "instance expected, found ~a" (type-name (.name instance))))))
                                     ((not (is-a? (.type instance) <component-model>))
                                      `(,(wfc-error o (format #f "instance expected, found `~a'" (.instance.name o)))
                                        ,(wfc-error instance (format #f "defined here"))))
                                     (else '())))))
         (port-error (if (or (pair? instance-error) (ast:wildcard? (.port.name o))) '()
                         (let ((port (.port o)))
                           (if port '()
                               (let* ((component (if (.instance.name o) (.type (.instance o))
                                                     (parent o <system>)))
                                      (cname (type-name (.name component))))
                                      `(,(wfc-error o (format #f "undefined port `~a' for `~a'" (.port.name o) cname))
                                        ,(wfc-error component (format #f "`~a' defined here" cname)))))))))
    (append instance-error port-error))
)

(define-method (binding-declaration (o <binding>))
  (append (binding-declaration (.left o)) (binding-declaration (.right o))))

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
                (not (equal? (.external (.port left))
                             (.external (.port right)))))
               (and
                (or (and (.instance.name left) (not (.instance.name right)))
                    (and (.instance.name right) (not (.instance.name left))))
                (.port left)
                (.port right)
                (not (equal? (.external (.port left))
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

(define-method (call-context (o <ast>))
  (let ((p (.parent o))
        (class (ast-name (class-of o)))
        (is-aorc (or (is-a? o <action>) (is-a? o <call>)))
        (global-var? (lambda (o) (and (is-a? o <variable>) (is-a? (.parent (.parent o)) <behaviour>)))))
    (cond
     ((global-var? o) '())
     ((is-a? p <behaviour>)  '())
     ((and is-aorc (not (if (is-a? o <action>) (.event o) (.function o))))
      (let ((name (if (is-a? o <action>) (.event.name o) (.function.name o))))
        `(,(wfc-error o (format #f "undefined identifier `~a'" name)))))
     ((and (not (is-a? p <variable>))
           (or (is-a? p <expression>)
               (and (is-a? p <if>)
                    (not (ast:eq? o (.then p)))
                    (not (ast:eq? o (.else p))))))
      `(,(wfc-error o (format #f "~a in expression" class))))
     ((and is-aorc (parent o <variable>) (global-var? (parent o <variable>)))
        `(,(wfc-error o (format #f "~a in variable declaration" class))))
     ((and (not (parent o <on>))
           (not (parent o <function>))
           (not (and (equal? class "compound") (ast:declarative? o))))
      `(,(wfc-error o (format #f "~a outside on" (if (equal? class "compound") "imperative compound" class)))))
     ((and is-aorc
           (is-a? (ast:type o) <void>)
           (is-a? p <variable>))
      `((wfc-error o "void value not ignored as it ought to be")))
     ((and is-aorc
           (not (is-a? (ast:type o) <void>))
           (not (is-a? p <assign>))
           (not (is-a? p <variable>)))
      `(,(wfc-error o (format #f "valued ~a must be used in variable assignment" class))))
     (else '()))))

(define-method (wfc:continuation (o <ast>))
  ((@@ (dzn makreel) makreel:continuation) o))

(define-method (wfc:continuation (o <if>))
  (cons ((@@ (dzn makreel) makreel:then-continuation) o)
        ((@@ (dzn makreel) makreel:else-continuation) o)))

(define-method (reply-without-port (o <reply>))
  (define (trigger->string o)
    (format #f "~a.~a" (.port.name o) (.event.name o)))
  (let ((model (parent o <model>))
        (on (parent o <on>)))
    (cond ((.port o) '())
          ((or (not (is-a? model <component>))
               (<= (length (ast:provides-port* model)) 1)) '())
          ((not on)
           `(,(wfc-error o "must specify a provides-port with reply")))
          ((let ((out-triggers (filter (compose ast:requires? .port) (ast:trigger* on))))
             (and (pair? out-triggers)
                  `(,(wfc-error o (format #f "must specify a provides-port with out-event: ~a"
                                          (string-join (map trigger->string out-triggers) ", ")))))))
          (else '()))))

(define-method (subsystems (o <system>))
  (let loop ((todo (list o)) (found '()))
    (if (null? todo) found
        (let ((first (car todo))
              (rest (cdr todo)))
          (if (find (cut ast:eq? first <>) found) (loop rest found)
              (let* ((instances (ast:instance* first))
                     (components (filter-map .type instances))
                     (systems (filter (is? <system>) components)))
                (loop (append systems rest) (cons first found))))))))

(define-method (subsystems (o <system>))
  (define (systems o)
    (let* ((instances (ast:instance* o))
           (components (filter-map .type instances)))
      (filter (is? <system>) components)))
  (define (subs o found) ;; includes o
    (if (find (cut ast:eq? o <>) found) found
        (let ((found (cons o found)))
          (append-map (cut subs <> found) (systems o)))))
  (append-map (cut subs <> '()) (systems o)))

(define-method (recursive (o <system>))
  (let* ((sub (subsystems o)))
    (if (find (cut ast:eq? o <>) sub)
        `(,(wfc-error o (format #f "system composition of `~a' is recursive" (type-name (.name o)))))
        '())))


(define-method (required-instances (o <instance>) (s <system>))
  (let* ((instances (ast:instance* s))
         (bindings (ast:binding* s))
         (component (.type o))
         (required-ports (and component (ast:requires-port* component)))
         (left-bindings (filter (lambda (b) (equal? (.name o) (.instance.name (.left b))))
                                bindings))
         (right-bindings (filter (lambda (b) (equal? (.name o) (.instance.name (.right b))))
                                 bindings))
         (left-required-bindings (filter (lambda (b) (find (lambda (p) (equal? (.name p) (.port.name (.left b)))) required-ports))
                                         left-bindings))
         (right-required-bindings (filter (lambda (b) (find (lambda (p) (equal? (.name p) (.port.name (.right b)))) required-ports))
                                          right-bindings))
         (left-instances (filter (lambda (i) (find (lambda (b) (equal? (.name i) (.instance.name (.right b)))) left-required-bindings))
                                 instances))
         (right-instances (filter (lambda (i) (find (lambda (b) (equal? (.name i) (.instance.name (.left b)))) right-required-bindings))
                                  instances)))
    (append left-instances right-instances)))

(define-method (all-required (o <instance>) (s <system>))
  (define (all-req o found)
    (if (find (cut ast:eq? o <>) found) found
        (let ((found (cons o found)))
          (append-map (cut all-req <> found) (required-instances o s)))))
  (append-map (cut all-req <> '()) (required-instances o s)))

(define-method (cyclic-bindings (o <system>))
  (append-map (lambda (i) (if (find (cut ast:eq? i <>) (all-required i o))
                              `(,(wfc-error i (format #f "instance `~a' is in a cyclic binding" (.name i))))
                              '()))
              (ast:instance* o)))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    ast:wfc)
   ast))
