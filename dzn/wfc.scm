;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2014, 2017, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn wfc)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn ast)
  #:use-module (dzn display)
  #:use-module (dzn goops)

  #:use-module (dzn misc)

  #:export (ast:wfc
            type-name
            wfc:report-message))

;;; Commentary:
;;;
;;; The well-formednes check.
;;;
;;; Parsing is implemented in three stages:
;;;   1) PEG creates a parse-tree
;;;   2) the parse tree is converted to an AST root
;;;   3) the AST root is checked for well-formedness errors
;;;
;;; Code:

(define (ast:wfc o)
  (let* ((messages (wfc o))
         (errors (filter (is? <error>) messages))
         (messages (filter (is? <message>) messages)))
    (when (pair? errors)
      (apply throw 'well-formedness-error messages))
    (when (pair? messages)
       (for-each wfc:report-message messages)))
  o)

(define-method (wfc:report-message (o <message>))
  (let* ((ast (.ast o))
         (loc (.location ast)))
    (if (not loc) (format (current-error-port) "error: ~a\n" (.message o))
        (format (current-error-port)
                "~a:~a:~a: ~a: ~a\n"
                (.file-name loc) (.line loc) (.column loc)
                (ast-name o) (.message o)))))

(define (wfc-error o message)
  (make <error> #:ast o #:message message))

(define (wfc-info o message)
  (make <info> #:ast o #:message message))

(define (wfc-warning o message)
  (make <warning> #:ast o #:message message))

(define-method (wfc (o <model>))
  '())

(define-method (wfc (o <interface>))
  (append
   (re-definition o)
   (append-map wfc (ast:type* o))
   (append-map wfc (ast:event* o))
   (if (pair? (ast:event* o)) '()
       `(,(wfc-error o "interface must define an event")))
   (if (.behavior o) (wfc (.behavior o))
       `(,(wfc-error o "interface must define a behavior")))))

(define-method (wfc (o <foreign>))
  (append
   (re-definition o)
   (append-map wfc (ast:port* o))
   (let* ((root (parent o <root>))
          (basename (ast:base-name root)))
     (if (not (equal? (string-join (ast:full-name o) "_") basename)) '()
         `(,(wfc-error
             o
             (format
              #f
              "foreign component cannot have the same name as its file: `~a'"
              basename)))))
   (blocking-ports o)))

(define-method (wfc (o <component>)) ;; is-a <component-model>
  (append
   (re-definition o)
   (blocking-ports o)
   (if (> (length (ast:provides-port* o)) 0) '()
       `(,(wfc-error o "component with behavior must define a provides port")))
   (let ((port-errors (append-map wfc (ast:port* o)))
         (trigger-events (wfc:trigger-event* o)))
     (if (or (pair? port-errors) (pair? trigger-events)) port-errors
         `(,(wfc-error o "component with behavior must have a trigger"))))
   (or (and=> (.behavior o) wfc) '())))

(define-method (wfc (o <system>)) ;; is-a <component-model>
  (append
   (re-definition o)
   (append-map wfc (ast:port* o))
   (append-map wfc (ast:instance* o))
   (recursive o)
   (let ((errors (binding-declaration o)))
     (if (pair? errors) errors
         (let ((errors (append
                        (binding-type o)
                        (binding-direction o)
                        (double-bindings o)
                        (missing-bindings o))))
           (if (pair? errors) errors
               (cyclic-bindings o)))))))

(define-method (wfc (o <instance>))
  (append
   (re-definition o)
   (let ((component (.type o)))
     (cond ((not component)
            `(,(wfc-error o (format #f "undefined component `~a'" (type-name (.type.name o))))))
           ((not (is-a? component <component-model>))
            `(,(wfc-error o (format #f "component expected, found: `~a ~a'" (ast-name component) (type-name component)))))
           (else '()))))
  )

(define-method (wfc (o <type>))
  (re-definition o))

(define-method (wfc (o <enum>))
  (append
   (re-definition o)
   (let loop ((fields (ast:field* o)) (result '()))
     (if (null? fields) result
         (let* ((field (car fields))
                (wf (if (find (cut equal? <> field) (cdr fields))
                        `(,(wfc-error o (format #f "duplicate enum field `~a' in enum `~a'" field (type-name (.name o)))))
                        '())))
           (loop (cdr fields) (append wf result)))))
   (if (and (parent o <model>) (ast:name-equal? (.name (parent o <model>)) (.name o)))
       `(,(wfc-error o (format #f "enum `~a' must not have the same name as the model it is defined in" (type-name (.name o)))))
       '())
   '()))

(define-method (wfc (o <int>))
  (append (re-definition o)
          (let ((range (.range o)))
            (if (<= (.from range) (.to range)) '()
                `(,(wfc-error o (format #f "subint `~a' has empty range" (type-name (.name o)))))))))

(define-method (wfc (o <port>))
  (append
   (re-definition o)
   (if (and (ast:provides? o) (ast:external? o))
       `(,(wfc-error o (format #f "provides port `~a' cannot be external" (.name o))))
       '())
   (if (and (ast:provides? o) (ast:injected? o))
       `(,(wfc-error o (format #f "provides port `~a' cannot be injected" (.name o))))
       '())
   (if (ast:name-equal? (.name (parent o <model>)) (.name o))
       `(,(wfc-error o (format #f "port `~a' must not have the same name as the model it is defined in" (.name o))))
       '())
   (let ((interface (.type o)))
     (cond ((not interface)
            `(,(wfc-error o (format #f "undefined interface `~a'" (type-name (.type.name o))))))
           ((not (is-a? interface <interface>))
            `(,(wfc-error o (format #f "interface expected, found: `~a ~a'" (ast-name interface) (type-name interface)))))
           ((and (.injected? o)
                 (let ((out-events (filter ast:out? (ast:event* o))))
                   (and (pair? out-events)
                        `(,(wfc-error o (format #f "injected port `~a' has out events: ~a" (.name o)
                                                (string-join (map .name out-events) ", ")))
                          ,@(map (cut wfc-info <> (format #f "port defined here")) out-events))))))
           (else '())))
   (if (not (ast:async? o)) '()
       (list
        (wfc-warning o "dzn.async is deprecated, please update to defer.")))))


(define-method (wfc (o <event>))
  (append
   (re-definition o)
   (cond ((and (ast:out? o) (ast:type o) (not (is-a? (ast:type o) <void>)))
          `(,(wfc-error o (format #f "out-event `~a' must be void, found `~a'" (.name o) (type-name (ast:type o))))))
         (else '()))
   (wfc (.signature o))))

(define-method (wfc (o <signature>))
  (define (check-formal function formal)
    (let ((message
           (format
            #f
            "type `~a' cannot be used for `~a' parameter `~a' in function `~a'"
            (ast:name (.type.name formal))
            (.direction formal)
            (.name formal)
            (.name function))))
      (wfc-error formal message)))
  (append
   (let ((type (ast:type o)))
     (cond ((not type)
            `(,(wfc-error o (format #f "unknown type name `~a'" (type-name (.type.name o))))))
           ((is-a? type <extern>)
            `(,(wfc-error o (format #f "cannot use extern type `~a' as return type" (type-name (.type.name o))))))
           (else '())))
   (append-map wfc (ast:formal* o))
   (let ((function (parent o <function>)))
     (if (not function) '()
         (let ((formals (filter (conjoin (disjoin ast:out? ast:inout?)
                                         (negate (compose (is? <extern>) .type)))
                                (ast:formal* o))))
           (map (cute check-formal function <>) formals))))))

(define ((argument-type-check o) argument formal)
  (let ((argument-type (ast:type argument))
        (formal-type (ast:type formal)))
    (cond ((or (not formal-type) (not argument-type))
           '())
          ((equal-type? argument-type formal-type)
           '())
          (else
           `(,(wfc-error argument (format #f "type mismatch: expected `~a', found: `~a'"
                                          (type-name formal-type)
                                          (type-name argument-type)))
             ,(wfc-info formal (format #f "for formal `~a' defined here" (.name formal))))))))

(define-method (wfc (o <arguments>))
  (let ((arguments (ast:argument* o)))
    (append
     (append-map wfc arguments)
     (cond
      ((and (parent o <component>)
            (parent o <action>))
       =>
       (lambda (ast)
         (let* ((count (length arguments))
                (event (.event ast)))
           (if (not (is-a? event <event>)) '()
               (let* ((formals (ast:formal* event))
                      (event-count (length formals)))
                 (append
                  (if (= count event-count) '()
                      `(,(wfc-error ast (format #f "argument count mismatch, expected ~a, found: ~a" event-count count))
                        ,(wfc-info event (format #f "for formals of event `~a' defined here" (.name event)))))
                  (append-map (argument-type-check o) arguments formals)))))))
      ((let ((ast (parent o <call>)))
         (and ast
              (.function ast)
              ast))
       =>
       (lambda (ast)
         (let* ((count (length arguments))
                (function (.function ast))
                (formals (if function (ast:formal* function) '()))
                (function-count (length formals)))
           (append
            (if (= count function-count) '()
                `(,(wfc-error ast (format #f "argument count mismatch, expected ~a, found: ~a" function-count count))
                  ,(wfc-info function (format #f "for formals of function `~a' defined here" (.name function)))))
            (append-map (argument-type-check o) arguments formals)))))
      (else
       '())))))

(define-method (wfc (o <formals>))
  (cond
   ((and (parent o <component>)
         (parent o <trigger>))
    =>
    (lambda (ast)
      (let* ((count (length (ast:formal* o)))
             (event (.event ast)))
        (append
         (let* ((formals (ast:formal* o))
                (formal-bindings (filter (is? <formal-binding>) formals)))
           (append-map wfc formal-bindings))
         (if (not event) '()
             (let* ((formals (ast:formal* event))
                    (event-count (length formals))
                    (on (parent o <on>))
                    (statement (.statement on))
                    (illegal? (or (is-a? statement <illegal>)
                                  (and (is-a? statement <compound>)
                                       (match (ast:statement* statement)
                                         ((($ <illegal>)) #t)
                                         (_ #f))))))
               (if (or illegal? (= count event-count)) '()
                   `(,(wfc-error ast (format #f "parameter count mismatch, expected ~a, found: ~a" event-count count))
                     ,(wfc-info event (format #f "for formals of event `~a' defined here" (.name event)))))))))))
   (else
    '())))

(define-method (wfc (o <formal>))
  (append
   (re-definition o)
   (let ((type (ast:type o))
         (event (parent o <event>)))
     (append
      (cond ((not type)
             `(,(wfc-error o (format #f "unknown type name `~a'" (type-name (.type.name o))))))
            ((and event (not (is-a? type <extern>)))
             `(,(wfc-error o (format #f "type mismatch: parameter `~a'; expected extern, found: `~a'" (.name o) (type-name type)))))
            (else '()))
      (cond
       ((and event (ast:out? event) (or (ast:out? o) (ast:inout? o)))
        `(,(wfc-error o (format #f "cannot use ~a-parameter on out-event `~a'" (.direction o) (.name event)))))
       (else '()))))))

(define-method (wfc (o <formal-binding>))
  (let ((variable (.variable o)))
    (if (is-a? (ast:type variable) <extern>) '()
        `(,(wfc-error o (format #f "formal binding `~a' is not a data member variable" (.variable.name o)))))))

(define-method (model-blocking? (o <model>))
  (and (is-a? o <component>)
       (pair? (tree-collect-filter (disjoin (is? <declarative>) (is? <compound>)) (is? <blocking>) (.statement (.behavior o))))))

(define %model-event-types (make-parameter '()))
(define %model-blocking? (make-parameter #f))

(define-method (wfc (o <behavior>))
  (let ((model (parent o <model>)))
    (parameterize ((%model-event-types
                    (if (is-a? model <interface>) (ast:return-types model)
                        (ast:return-types-provides model)))
                   (%model-blocking? (model-blocking? model)))
      (append
       (append-map wfc (ast:type* o))
       (append-map wfc (ast:port* o))
       (append-map wfc (ast:variable* o))
       (append-map (cute wfc model <>) (ast:variable* o))
       (append-map wfc (ast:function* o))
       (wfc (.statement o))))))

(define-method (wfc (o <variable>))
  (append
   (re-definition o)
   (assign o)))

(define-method (wfc (model <model>) (o <variable>))
  (if (ast:name-equal? (.name model) (.name o))
      `(,(wfc-error o
                    (format #f
                            "variable `~a' must not have the same name as the model it is defined in"
                            (.name o))))
      '()))

(define-method (wfc (o <function>))
  (append
   (re-definition o)
   (wfc (.signature o))
   (wfc (.statement o))
   (missing-return o)))


;;;
;;; Statements
;;;
(define-method (wfc (o <statement>))
  '())

(define-method (wfc (o <compound>))
  (append
   (imperative-context o)
   (mixing-declarative-imperative o)
   (append-map wfc (ast:statement* o))))

(define-method (wfc (o <declarative>))
  '())

(define-method (wfc (o <declarative-compound>))
  (append
   (mixing-declarative-imperative o)
   (append-map wfc (ast:statement* o))))

(define-method (wfc (o <guard>))
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
                 `(,(wfc-error o "cannot use otherwise guard with non-guard statements")
                   ,(wfc-info (car non-guards) "non-guard statement here"))
                 '())
             (if (pair? otherwises)
                 `(,(wfc-error (car otherwises) "cannot use otherwise guard more than once")
                   ,(wfc-info o "first otherwise here"))
                 '()))))))
  (let* ((expression (.expression o))
         (otherwise? (is-a? expression <otherwise>))
         (wfce (wfc expression)))
    (append wfce
            (if (or otherwise? (pair? wfce)) '()
                (typed-expression expression <bool>))
            (if otherwise? (otherwise o) '())
            (if (is-a? (.statement o) <statement>) (wfc (.statement o))
                `(,(wfc-error o "statement expected"))))))

(define-method (wfc (o <declarative-illegal>))
  ;; TODO; in source??
  '())

(define-method (wfc (o <blocking>))
  (define (blocking o)
    (let ((model (parent o <model>)))
      (cond ((is-a? model <interface>)
             `(,(wfc-error o "cannot use blocking in an interface")))
            ((parent (.parent o) <blocking>)
             `(,(wfc-error o "nested blocking used")
               ,(wfc-info (parent (.parent o) <blocking>) "within blocking here")))
            (else '()))))
  (append (blocking o) (wfc (.statement o))))

(define (wfc-defer-argument var)
  (if (is-a? var <undefined>)
      `(,(wfc-error var (format #f "undefined identifier `~a'" (.name var))))
      (let* ((variable (.variable var))
             (name (.variable.name var))
             (type (and=> variable .type)))
        (cond
         ((not (ast:member? variable))
          `(,(wfc-error var (format
                             #f
                             "cannot use local variable `~a' as defer argument"
                             name))
            ,(wfc-info var (format #f "variable `~a' defined here" name))))
         ((is-a? type <extern>)
          `(,(wfc-error var (format
                             #f
                             "cannot use data variable `~a' as defer argument"
                             name))
            ,(wfc-info var (format #f "variable `~a' defined here" name))))
         (else
          '())))))

(define-method (wfc (o <defer>))
  (let ((arguments (ast:argument* o)))
    (append
     (if (not arguments) '()
         (append-map wfc-defer-argument arguments))
     (wfc (.statement o)))))

(define-method (wfc (o <on>))
  (define (on o)
    (append
     (let ((parent (parent (.parent o) <on>)))
       (if parent `(,(wfc-error o "nested on used")
                    ,(wfc-info parent "within on here"))
           '()))))
  (append
   (on o)
   (append-map wfc (ast:trigger* o))
   (if (is-a? (.statement o) <statement>) (wfc (.statement o))
       `(,(wfc-error o "statement expected")))))

(define-method (wfc (o <imperative>))
  '())

(define-method (wfc (o <variable>))
  (append
   (imperative-context o)
   (re-definition o)
   (assign o)))

(define-method (wfc (o <action>))
  (append
   (action o)
   (call-context o)))

(define-method (wfc (o <action-or-call>))
  (append
   (call-context o)
   '()))

(define-method (wfc (o <assign>))
  (append
   (assign o)
   (imperative-context o)))

(define-method (wfc (o <call>))
  (append
   (defined-function o)
   (call-context o)
   (tail-recursion o)
   (wfc (.arguments o))))

(define-method (wfc (o <if>))
  (let* ((expression (.expression o))
         (wfce (wfc expression)))
    (append wfce
            (if (pair? wfce) '()
                (typed-expression expression <bool>))
            (imperative-context o)
            (wfc (.then o))
            (if (.else o) (wfc (.else o)) '()))))

(define-method (wfc (o <illegal>))
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
                                      ,(wfc-info (car (filter (negate (cut member <> (ast:path o) ast:eq?)) statements))
                                                  "imperative statement here")))))
                        (loop (parent (.parent compound) <compound>))))))
            (else '()))))
  (append
   (imperative-context o)
   (illegal o)))

(define-method (wfc (o <reply>))
  (append
   (imperative-context o)
   (if (.expression o) (wfc (.expression o)) '())
   (if (.port.name o) (reply-with-port o) (reply-without-port o))))

(define-method (reply-with-port (o <reply>))
  "pre: (.port.name o)"
  (let ((port (.port o))
        (on (parent o <on>)))
    (cond ((not port)
           `(,(wfc-error o (format #f "undefined port `~a'" (.port.name o)))))
          ((not (is-a? (.type port) <interface>)) '()) ; reported before
          ((ast:requires? port)
           `(,(wfc-error o (format #f "cannot use requires port `~a' in reply"
                                   (.name port)))
             ,(wfc-info port "port defined here")))
          (on (reply-in-on o))
          (else (wfc-reply-expression o port)))))

(define-method (reply-without-port (o <reply>))
  "pre: (not (.port.name o))"
  (define (trigger->string o)
    (format #f "~a.~a" (.port.name o) (.event.name o)))
  (let ((model (parent o <model>))
        (on (parent o <on>)))
    (cond ((or (not (is-a? model <component>))
               (<= (length (ast:provides-port* model)) 1))
           (if on (reply-in-on o) (wfc-reply-expression o #f)))
          ((not on)
           `(,(wfc-error o "must specify a provides-port with reply")))
          ((let ((out-triggers (filter (compose ast:requires? .port) (ast:trigger* on))))
             (and
              (pair? out-triggers)
              `(,(wfc-error
                  o
                  (format #f "must specify a provides-port with reply on requires out-trigger: ~a"
                          (string-join
                           (map (compose single-quote trigger->string)
                                out-triggers)
                           ", ")))))))
          (else (reply-in-on o)))))

(define-method (wfc-reply-expression (o <reply>) port)
  (let* ((expression (.expression o))
         (error? (and expression (pair? (wfc expression)))))
    (if error? '() ;; reported before
        (let* ((reply-type (and expression (ast:type expression)))
               (reply-type-name (if reply-type (type-name reply-type) "void"))
               (interface (and port (.type port)))
               (types (if interface (ast:return-types interface) (%model-event-types)))
               (matching-types (filter (cut ast:equal? <> reply-type) types)))
          (cond
           ((pair? matching-types) '())
           (port
            `(,(wfc-error o (format #f "type mismatch: no event with reply type `~a' for port `~a'"
                                    reply-type-name (.name port)))
              ,(wfc-info port "port defined here")))
           (else
            `(,(wfc-error o (format #f "type mismatch: no event with reply type `~a'"
                                    reply-type-name)))))))))

(define-method (wfc (o <return>))
  (let* ((wfce (if (.expression o) (wfc (.expression o)) '()))
         (function (parent o <function>))
         (function-type (and function (ast:type function)))
         (return-type (and (null? wfce) (ast:type o))))
    (append wfce
            (cond ((not function)
                   `(,(wfc-error o "cannot use return outside of function")))
                  ((pair? wfce) '())
                  ((not (equal-type? function-type return-type))
                   `(,(wfc-error o (format #f "type mismatch: expected `~a', found: `~a'"
                                           (type-name function-type)
                                           (type-name return-type)))))
                  (else '())))))

(define-method (wfc (o <the-end>))
  '())
(define-method (wfc (o <the-end-blocking>))
  '())
(define-method (wfc (o <voidreply>))
  '())

(define-method (wfc (o <trigger>))
  (let ((port (.port o))
        (model (parent o <model>)))
    (append
     (cond ((and (is-a? model <component>) (not port))
            `(,(wfc-error o (format #f "undefined port `~a'" (.port.name o)))))
           ((and (is-a? model <component>) (not (is-a? port <port>)))
            `(,(wfc-error o (format #f "`~a' is not a port" (.port.name o)))
              ,(wfc-info (.port o) (format #f "`~a' declared here" (.port.name o)))))
           (else (let ((event (.event o)))
                   (cond
                    ((and (is-a? model <interface>) (not event))
                     `(,(wfc-error o (format #f "event `~a' not defined"
                                             (.event.name o)))))
                    ((and (is-a? model <component>) (not event))
                     `(,(wfc-error o (format #f "event `~a' not defined for port `~a'"
                                             (.event.name o) (.port.name o)))
                       ,(wfc-info (.port o) (format #f "port `~a' defined here" (.port.name o)))))
                    ((and (is-a? model <interface>) (ast:out? event))
                     `(,(wfc-error o (format #f "cannot use ~a-event `~a' as trigger" (.direction event) (.event.name o)))
                       ,(wfc-info event (format #f "event `~a' defined here" (.event.name o)))))
                    ((and (is-a? model <component>)
                          (or (and (ast:out? event) (ast:provides? (.port o)))
                              (and (ast:in? event) (ast:requires? (.port o)))))
                     `(,(wfc-error o (format #f "cannot use ~a ~a-event `~a' as trigger"
                                             (.direction (.port o)) (.direction event) (.event.name o)))
                       ,(wfc-info (.port o) (format #f "port `~a' defined here" (.port.name o)))
                       ,(wfc-info event (format #f "event `~a' defined here" (.event.name o)))))
                    (else '())))))
     (wfc (.formals o)))))


;;;
;;; Expressions.
;;;
(define-method (wfc (o <enum-literal>))
  (let ((type (.type o)))
    (cond ((not type)
           `(,(wfc-error o (format #f "undefined identifier `~a'" (type-name (.type.name o))))))
          ((not (is-a? type <enum>))
           `(,(wfc-error o (format #f "enum type expected, found: `~a'" (type-name (.name type))))))
          (else (let ((field (.field o))
                      (fields (ast:field* type)))
                  (if (not (member field fields))
                      `(,(wfc-error o (format #f "no field `~a' in enum `~a'; expected: ~a"
                                              field
                                              (type-name o)
                                              (string-join (map single-quote fields) ", ")))
                        ,(wfc-info type "enum defined here"))
                      '()))))))

(define-method (wfc (o <literal>)) '())

(define-method (wfc (o <group>))
  (wfc (.expression o)))

(define-method (equal-type? t1 t2)
  (or (and (is-a? t1 <int>) (is-a? t2 <int>))
      (and (is-a? t1 <extern>) (is-a? t2 <extern>))
      (ast:equal? t1 t2)))

(define-method (typed-expression (o <expression>) (type <class>))
  (or (as (wfc o) <pair>)
      (let ((expr-type (ast:type o)))
        (cond
         ((and (not expr-type)
               (not (is-a? o <named>)))
          `(,(wfc-error o (format #f "typed expression expected `~a'" (ast-name o)))))
         ((not expr-type)
          `(,(wfc-error o (format #f "undefined identifier `~a'" (.name o)))))
         ((not (is-a? expr-type type))
          `(,(wfc-error o (format #f "~a expression expected" (class-name type)))))
         (else '())))))

(define-method (no-extern-expression (o <expression>))
  (or (as (wfc o) <pair>)
      (let ((type (ast:type o)))
        (cond
         ((and (not type)
               (not (is-a? type <named>)))
          `(,(wfc-error o (format #f "typed expression expected `~a'" (ast-name o)))))
         ((not type)
          `(,(wfc-error o (format #f "undefined identifier `~a'" (.name o)))))
         ((is-a? type <extern>)
          `(,(wfc-error
              o
              (format #f "extern data-type `~a' expression in binary operator"
                      (type-name type)))))
         (else '())))))

(define-method (wfc (o <not>))
  (typed-expression (.expression o) <bool>))

(define-method (typed-binary (o <binary>) (type <class>))
  (let* ((left (.left o))
         (left-wfc (typed-expression left type))
         (right (.right o))
         (right-wfc (typed-expression right type)))
    (append left-wfc right-wfc)))

(define-method (binary-equal-no-extern-type (o <binary>))
  (let* ((left (.left o))
         (left-wfc (no-extern-expression left))
         (left-type (ast:type left))
         (right (.right o))
         (right-wfc (no-extern-expression right))
         (right-type (ast:type right)))
    (cond ((or (pair? left-wfc) (pair? right-wfc)) (append left-wfc right-wfc))
          ((not (equal-type? left-type right-type))
           `(,(wfc-error o (format #f "type mismatch in binary operator: `~a' versus `~a'"
                                   (type-name left-type)
                                   (type-name right-type)))))
          (else '()))))

(define-method (wfc (o <and>)) (typed-binary o <bool>))
(define-method (wfc (o <or>)) (typed-binary o <bool>))

(define-method (wfc (o <equal>)) (binary-equal-no-extern-type o))
(define-method (wfc (o <not-equal>)) (binary-equal-no-extern-type o))

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
         (fields (and (is-a? type <enum>) (and=> type ast:field*))))
    (cond ((not variable)
           `(,(wfc-error o (format #f "undefined variable `~a'" (.variable.name o)))))
          ((not type)
           '()) ;; already covered (?)
          ((not (is-a? type <enum>))
           `(,(wfc-error o (format #f "type mismatch: expected enum, found: `~a'"
                                   (type-name type)))))
          ((not (member field fields))
           `(,(wfc-error o (format #f "no field `~a' in enum `~a'; expected: `~a'"
                                   field
                                   (type-name type)
                                   (string-join (map single-quote fields) ", ")))
             ,(wfc-info type "enum defined here")))
          (else '()))))

(define-method (wfc (o <otherwise>)) '())

(define-method (wfc (o <var>))
  (append
   (if (ast:member? (parent o <variable>))
       (let ((class "variable reference"))
         `(,(wfc-error o (format #f "~a in member variable initializer" class))))
       '())
   (let ((variable (.variable o)))
     (cond ((not variable)
            `(,(wfc-error o (format #f "undefined variable `~a'" (.name o)))))
           (else '())))))

(define-method (wfc (o <undefined>))
  `(,(wfc-error o (format #f "undefined identifier `~a'" (.name o)))))

(define-method (wfc (o <data>)) '())

(define-method (wfc (o <ast>))
  ;;  (warn 'wfc:--------------UNCOVERED-------------- o)
  '())


;;;
;;; helper functions
;;;
(define-method (defined-function (o <call>))
  (if (find (compose (cute ast:equal? (.function.name o) <>) .name)
            (ast:function* (parent o <behavior>))) '()
            `(,(wfc-error o (format #f "undefined function call: ~s" (.function.name o))))))

(define (single-quote string)
  (format #f "`~a'" string))

(define-method (tail-recursion (o <call>))
  (let ((function (parent o <function>)))
    (if (or (not function) (not (.recursive? function))) '()
        (let* ((continuation ((compose car wfc:continuation) o))
               (continuation (if (or (parent o <assign>)
                                     (parent o <reply>)
                                     (parent o <return>)
                                     (parent o <variable>))
                                 ((compose car (@@ (dzn code makreel) makreel:continuation)) continuation)
                                 continuation))
               (continuation (and continuation
                                  (not (ast:eq? continuation (.statement (parent o <function>))))
                                  continuation)))
              (cond ((is-a? continuation <return>)
                     `(,(wfc-error o "cannot use valued function in recursion")
                       ,(wfc-info continuation "statement after call")))
                    (continuation `(,(wfc-error o "cannot use statement after recursive call")
                                    ,(wfc-info continuation "statement after call")))
                    (else '()))))))

(define-method (mixing-declarative-imperative (o <compound>))
  (if (ast:declarative? o)
      (or (let* ((imperative (filter ast:imperative? (ast:statement* o)))
                 (ast (and (pair? imperative) (car imperative))))
            (and ast
                 (list (wfc-error ast "declarative statement expected"))))
          '())
      (or (let* ((declarative (filter ast:declarative? (ast:statement* o)))
                 (ast (and (pair? declarative) (car declarative))))
            (and ast
                 (list (wfc-error ast "imperative statement expected"))))
          '())))

(define-method (re-definition (o <declaration>))
  (let* ((name (ast:name o))
         (scope (parent (.parent o) <scope>))
         (previous (and scope (ast:lookup scope name)))
         (previous-scope (and previous (parent (.parent previous) <scope>))))
    (if (and scope
             previous
             (ast:eq? scope previous-scope)
             (not (ast:eq? previous o))
             (not (is-a? previous <namespace>)))
        `(,(wfc-error o (format #f "identifier `~a' defined before" (ast:name o)))
          ,(wfc-info previous (format #f "previous `~a' definition here" (ast:name previous))))
        '())))

(define-method (assign (o <ast>))
  (let* ((assign-type (ast:type o))
         (expression (.expression o))
         (wfce (wfc expression))
         (expression-type (ast:type expression)))
    (cond ((pair? wfce) wfce)
          ((not expression-type)
           `(,(wfc-error o (format #f "undefined identifier `~a'" (.name expression)))))
          ((and (not assign-type) (is-a? o <variable>))
           `(,(wfc-error o (format #f "unknown type name `~a'" (type-name (.type.name o))))))
          ((and (is-a? o <variable>) (is-a? expression-type <void>))
           (if (is-a? assign-type <extern>) '()
               `(,(wfc-error o (format #f "uninitialized variable `~a'" (.name o))))))
          ((not assign-type) '()) ;; reported before
          ((not (equal-type? expression-type assign-type))
           `(,(wfc-error o (format #f "type mismatch: expected `~a', found: `~a'"
                                   (type-name assign-type)
                                   (type-name expression-type)))))
          (else '()))))

(define-method (type-name (o <boolean>))
  "<unknown type>")

(define-method (type-name (o <string>))
  o)

(define-method (type-name (o <ast>))
  (or (and=> (ast:full-name o) (cut string-join <> "."))
      "<unknown type>"))

(define-method (type-name (o <scope.name>))
  (string-join (.ids o) "."))

(define-method (reply-in-on (o <reply>))
  "pre: in <on> clause"
  (let ((on (parent o <on>)))
    (append-map (cut reply-in-on o <>) (ast:trigger* on))))

(define-method (reply-in-on (o <reply>) (trigger <trigger>))
  (let* ((component (parent o <component>))
         (unblock? (and component
                        (ast:requires? trigger)
                        (%model-blocking?)))
         (provides* (and component (ast:provides-port* component)))
         (port (and (.port.name o) (.port o)))
         (port (or port (and unblock? (pair? provides*) (car provides*))))
         (interface (and port (.type port)))
         (event (and (not unblock?) (.event trigger)))
         (event-type (and event (ast:type event)))
         (reply-type (ast:type o)))
    (cond ((and (not (%model-blocking?)) port (ast:provides? trigger)
                (not (equal? (.port.name o) (.port.name trigger))))
           `(,(wfc-error o (format #f "port `~a' does not match with trigger port `~a'"
                                   (.port.name o) (.port.name trigger)))))
          ((and (not unblock?) (not event)) '()) ; already covered in trigger check
          ((and (not unblock?) (not event-type)) '()) ; reported before
          ((and (not unblock?) (ast:in? event)) ; also covers interfaces
           (if (and reply-type (not (equal-type? event-type reply-type)))
               `(,(wfc-error o (format #f "type mismatch: expected `~a', found: `~a'"
                                       (type-name event-type)
                                       (type-name reply-type)))
                 ,(wfc-info event "event defined here"))
               '()))
          (else (wfc-reply-expression o port)))))

(define-method (action (o <action>))
  (let ((event (.event o))
        (model (parent o <model>)))
    (append
     (cond ((and (is-a? model <interface>) (not event))
            `(,(wfc-error o (format #f "undefined event `~a'" (.event.name o)))))
           ((and (is-a? model <interface>) (ast:in? event))
            `(,(wfc-error o (format #f "cannot use ~a-event `~a' as action" (.direction event) (.event.name o)))
              ,(wfc-info event (format #f "event `~a' defined here" (.event.name o)))))
           ((and (is-a? model <component>)
                 (not (is-a? event <event>)))
            (let ((port (.port o)))
              (if (not port)
                  `()
                  `(,(wfc-error o (format #f "event `~a' not defined for port `~a'"
                                          (.event.name o) (.port.name o)))
                    ,(wfc-info (.port o) (format #f "port `~a' defined here" (.port.name o)))))))
           ((and (is-a? model <component>)
                 (or (and (ast:in? event) (ast:provides? (.port o)))
                     (and (ast:out? event) (ast:requires? (.port o)))))
            `(,(wfc-error o (format #f "cannot use ~a ~a-event `~a' as action"
                                    (.direction (.port o)) (.direction event) (.event.name o)))
              ,(wfc-info (.port o) (format #f "port `~a' defined here" (.port.name o)))
              ,(wfc-info event (format #f "event `~a' defined here" (.event.name o)))))
           (else '()))
     (wfc (.arguments o)))))

(define-method (binding-declaration (o <system>))
  (append-map binding-declaration (ast:binding* o)))

(define-method (binding-declaration (o <end-point>))
  (let* ((instance-error (if (not (.instance.name o)) '()
                             (let ((instance (.instance o)))
                               (cond ((not instance)
                                      `(,(wfc-error o (format #f "undefined identifier `~a'" (.instance.name o)))))
                                     ((not (is-a? instance <instance>))
                                      `(,(wfc-error o (format #f "instance expected, found: `~a'" (type-name (.name instance))))))
                                     ((not (is-a? (.type instance) <component-model>))
                                      `(,(wfc-error o (format #f "instance expected, found: `~a'" (.instance.name o)))
                                        ,(wfc-info instance (format #f "defined here"))))
                                     (else '())))))
         (port-error (if (or (pair? instance-error) (ast:wildcard? (.port.name o))) '()
                         (let ((port (.port o)))
                           (if (and port (is-a? port <port>)) '()
                               (let* ((component (if (.instance.name o) (.type (.instance o))
                                                     (parent o <system>)))
                                      (cname (type-name (.name component))))
                                      `(,(wfc-error o (format #f "undefined port `~a' for `~a'" (.port.name o) cname))
                                        ,(wfc-info component (format #f "`~a' defined here" cname)))))))))
    (append instance-error port-error))
)

(define-method (binding-declaration (o <binding>))
  (append (binding-declaration (.left o)) (binding-declaration (.right o))))

(define-method (binding-direction (o <system>))
  (append-map binding-direction (ast:binding* o)))

(define-method (binding-direction (o <binding>))
  (let* ((o (ast:normalize o))
         (left (.left o))
         (right (.right o)))
    (cond ((and (ast:wildcard? (.port.name left))
                (ast:wildcard? (.port.name right)))
           `(,(wfc-error o "cannot bind two wildcards")))
          ((and (ast:wildcard? (.port.name left))
                (ast:requires? (.port right)))
           `(,(wfc-error o (format #f "cannot bind wildcard to ~a port `~a'" (.direction (.port right)) (.port.name right)))
             ,(wfc-info (.port right) (format #f "port `~a' defined here" (.port.name right)))))
          ((and (ast:wildcard? (.port.name right))
                (ast:requires? (.port left)))
           `(,(wfc-error o (format #f "cannot bind wildcard to ~a port `~a'" (.direction (.port left)) (.port.name left)))
             ,(wfc-info (.port left) (format #f "port `~a' defined here" (.port.name left)))))
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
             ,(wfc-info (.port left) (format #f "port `~a' defined here" (.port.name left)))
             ,(wfc-info (.port right) (format #f "port `~a' defined here" (.port.name right)))))
          ((and
            (.port left)
            (.port right)
            (ast:requires? (.port left))
            (ast:requires? (.port right))
            (not (.external? (.port left)))
            (.external? (.port right)))
           `(,(wfc-error o (format #f "cannot bind ~a port `~a' to ~a port `~a'"
                                   (or (.external? (.port left)) 'non-external) (.port.name left)
                                   (or (.external? (.port right)) 'non-external) (.port.name right)))
             ,(wfc-info (.port left) (format #f "port `~a' defined here" (.port.name left)))
             ,(wfc-info (.port right) (format #f "port `~a' defined here" (.port.name right)))))
          ((and
            (.port left)
            (.port right)
            (not (.blocking? (.port left)))
            (.blocking? (.port right)))
           `(,(wfc-error o (format #f "cannot bind non-blocking port `~a' to blocking port `~a'"
                                   (.port.name left) (.port.name right)))
             ,(wfc-info (.port left) (format #f "non-blocking port `~a' defined here" (.port.name left)))
             ,(wfc-info (.port right) (format #f "blocking port `~a' defined here" (.port.name right)))))
          ((and
            (.port left)
            (.port right)
            (ast:provides? (.port left))
            (.blocking? (.port left))
            (not (.blocking? (.port right))))
           `(,(wfc-error (.port left) (format #f "superfluous blocking annotation on provides port `~a'"
                                              (.port.name left)))))
          (else '()))))

(define-method (binding-type (o <system>))
  (append-map binding-type (ast:binding* o)))

(define-method (binding-type (o <binding>))
  (let ((left (.left o))
        (right (.right o)))
    (if (and
         (.port left)
         (.port right)
         (.type (.port left))
         (.type (.port right))
         (not (equal-type? (.type (.port left)) (.type (.port right)))))
        `(,(wfc-error o (format #f "type mismatch: cannot bind port `~a' of type `~a' to port ~a of type `~a'"
                                (.port.name left) (type-name (.type (.port left)))
                                (.port.name right) (type-name (.type (.port right)))))
          ,(wfc-info (.port left) (format #f "port `~a' defined here" (.port.name left)))
          ,(wfc-info (.port right) (format #f "port `~a' defined here" (.port.name right))))
        '())))

(define-method (blocking-ports (o <component-model>))
  (let ((blocking-provides? (find .blocking? (ast:provides-port* o)))
        (non-blocking-provides? (find (negate .blocking?) (ast:provides-port* o)))
        (blocking-implementation? (or (model-blocking? o)
                                      (find .blocking? (ast:requires-port* o)))))
    (cond
      ((and blocking-implementation? non-blocking-provides?)
        `(,(wfc-error o "all provides ports should be defined as blocking")
          ,(wfc-info non-blocking-provides?
                    (format #f "non-blocking provides port `~a' define here"
                            (.name non-blocking-provides?)))))
      ((and (is-a? o <component>) (not blocking-implementation?) blocking-provides?)
        `(,(wfc-error blocking-provides? (format #f "superfluous blocking annotation on provides port `~a'"
                                                 (.name blocking-provides?)))))
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
  (define (binding->end-points binding)
    `(,(.left binding) ,(.right binding)))
  (define (port->end-point port)
    (make <end-point> #:location (.location port) #:port.name (.name port)))
  (define (instance->end-point instance)
    (map (compose (cute make <end-point>
                        #:location (.location instance)
                        #:instance.name (.name instance)
                        #:port.name <>)
                  .name)
         (filter (negate .injected?) (ast:port* (ast:type instance)))))
  (define (end-point=? a b)
    (and (equal? (.instance.name a) (.instance.name b))
         (equal? (.port.name a) (.port.name b))))
  (define (missing-end-point->wfc-error end-point)
    (wfc-error (or (.instance end-point) (.port end-point))
               (format #f "port `~a' of type `~a' not bound"
                       (.port.name end-point)
                       (type-name (.type.name (.port end-point))))))
  (let* ((bound-end-points (append-map binding->end-points
                                       (ast:binding* o)))
         (end-points
          (append (map port->end-point (ast:port* o))
                  (append-map instance->end-point (ast:instance* o))))
         (missing (lset-difference end-point=? end-points bound-end-points)))
    (map missing-end-point->wfc-error missing)))

(define-method (missing-return (o <function>))
  (define (function-body? s)
    (ast:eq? s (.statement o)))
  (define (step o continuation)
    (cond
     ((is-a? o <illegal>)
      '())
     ((is-a? o <return>)
      (list o))
     ((function-body? continuation)
      (list o))
     (else
      (run continuation))))
  (define (run o)
    (let ((continuations (wfc:continuation o)))
      (if (is-a? o <if>)
          (append-map (cute step o <>) continuations)
          (step o (car continuations)))))
  (define (collapse-if statements)
    (let loop ((statements statements))
      (if (null? statements) '()
          (let* ((statement (car statements))
                 (parent-if (parent statement <if>))
                 (rest (cdr statements))
                 (dupe (find (compose
                              (cute ast:eq? <> parent-if)
                              (cute parent <> <if>))
                             rest)))
            (if dupe (cons parent-if (loop (delete dupe rest)))
                (cons statement rest))))))
  (if (is-a? (ast:type o) <void>) '()
      (let* ((statements (run (.statement o)))
             (missing (filter (negate (is? <return>)) statements))
             (missing (delete-duplicates missing ast:eq?))
             (missing (collapse-if missing)))
        (map (cute wfc-error <> "missing return") missing))))

(define-method (call-context (o <ast>))
  (let* ((p (.parent o))
         (grand-parent (.parent p))
         (great-grand-parent (.parent grand-parent))
         (class (ast-name (class-of o))))
    (cond
     ((and (is-a? o <action>) (not (.event o)))
      (let ((name (.event.name o)))
        `(,(wfc-error o (format #f "undefined identifier `~a'" name)))))
     ((and (parent o <variable>)
           (ast:member? (parent o <variable>)))
      (let ((class (if (equal? class "var") "variable reference" class)))
        `(,(wfc-error o (format #f "~a in member variable initializer" class)))))
     ((and (not (parent o <on>))
           (not (parent o <function>))
           (not (and (equal? class "compound") (ast:declarative? o))))
      (let ((class (if (equal? class "compound") "imperative compound" class)))
        `(,(wfc-error o (format #f "~a outside on" class)))))
     ((and (is-a? (ast:type o) <void>)
           (is-a? p <variable>))
      `(,(wfc-error o "void value not ignored as it ought to be")))
     ((and (not (is-a? (ast:type o) <void>))
           (or (is-a? p <compound>)
               (is-a? p <guard>)
               (is-a? p <on>)
               (and (is-a? p <if>)
                    (not (ast:eq? o (.expression p))))))
      `(,(wfc-error o (format #f "~a value discarded" class))))
     (else
      '()))))

(define-method (imperative-context (o <ast>))
  (let* ((p (.parent o))
         (class (ast-name (class-of o))))
    (cond
     ((ast:member? o) '())
     ((is-a? p <behavior>)  '())
     ((and (not (parent o <on>))
           (not (parent o <function>))
           (not (and (equal? class "compound") (ast:declarative? o))))
      (let ((class (if (equal? class "compound") "imperative compound" class)))
        `(,(wfc-error o (format #f "~a outside on" class)))))
     (else '()))))

(define-method (wfc:continuation (o <ast>))
  ((@@ (dzn code makreel) makreel:continuation) o))

(define-method (wfc:continuation (o <if>))
  (append ((@@ (dzn code makreel) makreel:then-continuation) o)
          ((@@ (dzn code makreel) makreel:else-continuation) o)))

(define-method (recursive? (o <system>))
  (ast:graph-cyclic? ast:system* o))

(define-method (recursive (o <system>))
  (if (recursive? o)
      `(,(wfc-error o (format #f "system composition of `~a' is recursive" (type-name (.name o)))))
      '()))

(define-method (requires-instances (o <instance>) (s <system>))
  (let* ((instances (ast:instance* s))
         (bindings (ast:binding* s))
         (component (.type o))
         (requires-ports (and component (ast:requires-port* component)))
         (left-bindings (filter (lambda (b) (equal? (.name o) (.instance.name (.left b))))
                                bindings))
         (right-bindings (filter (lambda (b) (equal? (.name o) (.instance.name (.right b))))
                                 bindings))
         (left-required-bindings (filter (lambda (b) (find (lambda (p) (equal? (.name p) (.port.name (.left b)))) requires-ports))
                                         left-bindings))
         (right-required-bindings (filter (lambda (b) (find (lambda (p) (equal? (.name p) (.port.name (.right b)))) requires-ports))
                                          right-bindings))
         (left-instances (filter (lambda (i) (find (lambda (b) (equal? (.name i) (.instance.name (.right b)))) left-required-bindings))
                                 instances))
         (right-instances (filter (lambda (i) (find (lambda (b) (equal? (.name i) (.instance.name (.left b)))) right-required-bindings))
                                  instances)))
    (cons (.node o) (append left-instances right-instances))))

(define-method (all-required (o <instance>) (s <system>) required-alist)
  (define (req i) (or (assq-ref required-alist (.node i)) '()))
  (define (all-req o found)
    (if (find (cut ast:eq? o <>) found) found
        (let ((found (cons o found)))
          (append-map (cut all-req <> found) (req o)))))
  (append-map (lambda (r) (cons r (all-req r '()))) (req o)))

(define-method (cyclic-bindings (o <system>))
  (let* ((instances (ast:instance* o))
         (required-alist (map (cut requires-instances <> o) instances)))
    (append-map (lambda (i) (if (find (cut ast:eq? i <>) (all-required i o required-alist))
                                `(,(wfc-error i (format #f "instance `~a' is in a cyclic binding" (.name i))))
                                '()))
                instances)))

(define-method (wfc:provides-in-event* (o <component>))
  (let* ((ports (ast:provides-port* o))
         (interfaces (map .type ports))
         (interfaces (filter (is? <interface>) interfaces))
         (interfaces (delete-duplicates interfaces ast:eq?))
         (events (append-map ast:event* interfaces))
         (events (filter (is? <event>) events)))
    (filter ast:in? events)))

(define-method (wfc:requires-out-event* (o <component>))
  (let* ((ports (ast:requires-port* o))
         (interfaces (map .type ports))
         (interfaces (filter (is? <interface>) interfaces))
         (interfaces (delete-duplicates interfaces ast:eq?))
         (events (append-map ast:event* interfaces))
         (events (filter (is? <event>) events)))
    (filter ast:out? events)))

(define-method (wfc:trigger-event* (o <component>))
  (append (wfc:provides-in-event* o)
          (wfc:requires-out-event* o)))


;;;
;;; Entry points.
;;;
(define-method (wfc (o <root>))
  (append
   (append-map wfc (ast:model* o))
   (append-map wfc (ast:type* o))))
