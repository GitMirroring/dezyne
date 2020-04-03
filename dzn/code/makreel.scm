;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2019, 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018, 2019, 2020 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code makreel)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 hash-table)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 textual-ports)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn config)
  #:use-module (dzn command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn display)
  #:use-module (dzn misc)

  #:use-module (dzn ast)

  #:use-module (dzn code)
  #:use-module (dzn code dzn)
  #:use-module (dzn normalize)
  #:use-module (dzn templates)
  #:export (%model-name
            makreel:.name
            makreel:enum-fields
            makreel:get-model
            makreel:init-process
            makreel:model->makreel
            makreel:model-name
            makreel:name
            makreel:om
            makreel:reply-type-sort
            makreel:tick-names
            makreel:unticked-dotted-name
            root->))

(define %id-alist (make-parameter #f))
(define %model-name (make-parameter #f))
(define %next-alist (make-parameter #f))


;;;
;;; Ticked root.
;;;

(define (untick o)
  (string-drop-right o 1))

(define-method (makreel:.name (o <named>))
  (untick (.name o)))

(define-method (makreel:name (o <named>))
  (untick (ast:name o)))

(define-method (makreel:get-model (o <root>) model-name)
  "Find model of MODEL-NAME in ROOT.  MODEL-NAME is unticked, ROOT is ticked."
  (let ((models (ast:model* o)))
    (find (compose (cute equal? <> model-name) makreel:unticked-dotted-name) models)))

(define (makreel:model->makreel root model)
  (let* ((model-name (makreel:unticked-dotted-name model))
         (root' (tree-filter (disjoin (negate (is? <component>)) (cut ast:eq? <> model)) root)))
    (parameterize ((%model-name model-name))
      (root-> root'))))

(define (makreel:unticked-dotted-name o)
  "Return a full name of MODEL, separated with dots, with ticks removed."
  (string-join (map untick (ast:full-name o)) "."))

(define-method (makreel:get-model (o <root>))
  (define (named? o)
    (equal? (makreel:unticked-dotted-name o) (%model-name)))
  (let ((model (and (%model-name)
                    (find named? (ast:model* o)))))
    (or model
        (find (is? <component>) (ast:model* o))
        (filter (is? <interface>) (ast:model* o)))))



;;;
;;; Accessors.
;;;

(define-method (makreel:behavior->defer-qout (o <behavior>))
  (tree-collect (is? <defer>) o))

(define-method (makreel:interface-reorder (o <behavior>))
  (if (parent o <interface>) o
      '()))

(define-method (makreel:interface-reorder (o <ast>))
  '())

(define interface-alist '())

(define (makreel:interface-proc-memo o)
  (let* ((key (makreel:unticked-dotted-name o))
         (intf (assoc-ref interface-alist key)))
    (if intf
        (string-append "%% cache hit: \n" intf)
        (let* ((intf (with-output-to-string (cut x:interface-proc o)))
               (foo (set! interface-alist (acons key intf interface-alist))))
          (string-append "%% no cache hit found: \n" intf)))))

(define-method (x:interface-proc-memo (o <interface>))
 (makreel:interface-proc-memo o))

(define-method (x:interface-proc-memo (o <component>))
 (string-join (map makreel:interface-proc-memo  (ast:interface* o)) "\n"))

(define (mcrl2:process-identifier o)
  (let* ((model-key ((compose .id (cut parent <> <model>)) o))
         (path (ast:path o))
         (key (map .id path))
	 (next (assq-ref (%next-alist) model-key))
	 (next (or next -1)))
    (number->string (or (assoc-ref (%id-alist) key)
			(let ((next (1+ next)))
                          (%id-alist (acons key next (%id-alist)))
                          (%next-alist (assoc-set! (%next-alist) model-key next))
                          next)))))

(define-method (mcrl2:process-continuation (o <ast>))
  (let* ((parent (.parent o)))
    (match parent
      (($ <behavior>) parent)
      (($ <compound>) (let ((cont (cdr (member o (ast:statement* parent) (lambda (a b) (eq? (.node a) (.node b)))))))
			(if (pair? cont)
			    (car cont)
			    (mcrl2:process-continuation parent))))
      (_ (mcrl2:process-continuation parent)))))

(define (last-statement? o)
  (or (not (is-a? (.parent o) <compound>))
      (let* ((p (parent o <scope>))
             (statements (ast:statement* p)))
        (ast:eq? (last statements) o))))

(define-method (makreel:assign-call-parameter (o <variable>))
  (if (last-statement? o) '()
      o))

(define-method (makreel:assign-call-parameter (o <assign>))
  (if (and (last-statement? o)
           (not (let* ((cont (car (makreel:continuation o)))
                       (variables (variables-in-scope cont)))
                  (member (.variable o) variables ast:eq?))))
      '()
      o))

;; FIXME: non-compatible copy from mcrl2 scope vs model ticking:
;;  <scope-name (IConsole) State'> vs <interface IConsole'>
;; implications for trace format mcrl2, templates
(define %count (make-parameter 0))
(define (makreel:tick-names o)
  (parameterize ((%count 0))
    ((tick-names- '()) o)))
(define* ((tick-names- #:optional (names '())) o)
  (define* ((append-tick #:optional (names '())) o)
    (if (or (not o) (ast:wildcard? o) (ast:empty-namespace? o)) o
        (let ((count (or (assoc-ref names o) 0)))
          (string-append o (string-append "'" (if (zero? count) "" (number->string count)))))))
  (match o
    (($ <root>) (tree-map (tick-names-) o))
    ((? (is? <model>)) (clone (tree-map (tick-names-) o) #:name ((compose (tick-names-) .name) o)))
    (($ <bool>) o)
    (($ <void>) o)
    ((and ($ <scope.name>) (or (= .ids '("void")) (= .ids '("bool")))) o)
    ((? (is? <type>)) (clone o #:name ((compose (tick-names-) .name) o)))
    (($ <scope.name>) (clone o #:ids (map (append-tick) (.ids o))))
    (($ <port>) (clone o #:name ((compose (append-tick) .name) o) #:type.name ((compose (tick-names-) .type.name) o)))
    (($ <trigger>) (clone o #:port.name ((compose (append-tick) .port.name) o)))
    (($ <action>) (clone o #:port.name ((compose (append-tick) .port.name) o)))
    (($ <behavior>)
     (let ((names (map (cut cons <> 0) (map .name (ast:variable* o)))))
       (fold (lambda (field method o)
               (clone o field ((compose (tick-names- names) method) o)))
             o
             (list #:types #:ports #:variables #:functions #:statement)
             (list .types .ports .variables .functions .statement))))
    (($ <var>) (clone o #:name ((compose (append-tick names) .name) o)))
    (($ <field-test>) (clone o #:variable.name ((compose (append-tick names) .variable.name) o)))
    (($ <formal>) (clone o #:name ((compose (append-tick names) .name) o)
                         #:type.name ((compose (tick-names-) .type.name) o)))
    (($ <formal-binding>) (clone o
                                 #:name ((compose (append-tick) .name) o)
                                 #:type.name ((compose (tick-names-) .type.name) o)
                                 #:variable.name ((compose (append-tick names) .variable.name) o)))
    (($ <function>)
     (let* ((signature (.signature o))
            (type-name ((compose (tick-names- names) .type.name) signature)))
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
         (clone o #:name ((compose (append-tick names) .name) o)
                #:signature (clone signature #:type.name type-name #:formals (clone (.formals signature) #:elements formals))
                #:statement ((compose (tick-names- names) .statement) o)))))
    (($ <call>) (clone o
                       #:function.name ((compose (append-tick names) .function.name) o)
                       #:arguments ((compose (tick-names- names) .arguments) o)))
    (($ <assign>) (clone o #:variable.name ((compose (append-tick names) .variable.name) o)
                         #:expression ((compose (tick-names- names) .expression) o)))
    (($ <reply>) (clone o #:port.name ((compose (append-tick) .port.name) o)
                        #:expression ((compose (tick-names- names) .expression) o)))
    (($ <variable>) (clone o #:name ((compose (append-tick names) .name) o)
                           #:type.name ((compose (tick-names-) .type.name) o)
                           #:expression ((compose (tick-names- names)
                                                  .expression) o)))
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

(define (makreel:mark-tail-call o)
  (match o
    (($ <call>) (let ((continuation ((compose car makreel:continuation) o)))
                  (if (and (is-a? continuation <return>)
                           (is-a? (ast:type (.expression continuation)) <void>)) (clone o #:last? #t)
                      o)))
    (($ <expression>) o)
    (($ <location>) o)
    ((? (is? <ast>)) (tree-map makreel:mark-tail-call o))
    (_ o)))

(define-method (makreel:init (o <root>))
  (let* ((model-name (%model-name)))
    (define (named? o)
      (equal? (makreel:unticked-dotted-name o) model-name))
    (let ((model (and model-name
                      (find named? (ast:model* o)))))
      (or model
          (find (is? <component>) (ast:model* o))
          (find (is? <interface>) (ast:model* o))))))

(define-method (makreel:interface-name (o <interface>))
  (makreel:model-name o))

(define-method (makreel:interface-name (o <port>))
  ((compose makreel:interface-name .type) o))

(define-method (makreel:interface-name (o <on>))
  (makreel:interface-name (or (parent o <interface>)
                              (.type (.port (car (ast:trigger* o)))))))

(define-method (makreel:interface-name (o <event>))
  (makreel:interface-name (parent o <interface>)))

(define-method (makreel:interface-name (o <statement>))
  (makreel:interface-name (parent o <on>)))

(define-method (makreel:interface-name (o <action>))
  (makreel:interface-name
   (or (.port o) (parent o <on>)
       (let ((model (parent o <model>)))
         (if (is-a? model <interface>) model
             ((compose .type car ast:provides-port*) o))))))

(define-method (makreel:model-name (o <model>))
  (string-join (ast:full-name o) ""))

(define-method (makreel:model-name (o <ast>))
  (makreel:model-name (parent o <model>)))

(define-method (makreel:scope-name (o <ast>))
  (and=> (parent o <model>) makreel:model-name))

(define-method (makreel:multiple-provides? (o <port>))
  (if (< 1 (length (ast:provides-port* o))) o
      '()))

(define-method (makreel:negate-multiple-provides? (o <port>))
  (if (not (< 1 (length (ast:provides-port* o)))) o
      '()))

(define-method (ast:provides-interfaces (o <component>))
  (delete-duplicates (map .type (filter ast:provides? (ast:port* o)))))

(define-method (makreel:flush-provides-ports (o <port>))
  (ast:provides-port* (parent o <component>)))

(define-method (ast:async-port*? (o <component>))
  (if (pair? (ast:async-port* o)) o
      '()))

(define-method (ast:non-external-port* (o <component>))
  (filter (negate ast:external?) (filter ast:requires? (ast:port* o))))

(define-method (ast:external-port* (o <component>))
  (filter ast:external? (ast:port* o)))

(define-method (makreel:action-sort (o <component>))
  (ast:interface* o))

(define-method (makreel:action-sort (o <interface>))
  o)

(define-method (makreel:action-sort-event (o <interface>))
  (ast:event* o))

(define-method (makreel:action-sort-event (o <port>))
  (filter (compose (cut equal? (.name o) <>) .port.name)
          (ast:trigger* (parent o <component>))))

(define-method (enum-sort-global-public (o <root>))
  (filter (is? <enum>)
    (append
      (ast:type* o)
      (append-map ast:type* (filter (is? <interface>) (ast:model* o))))))

(define-method (makreel:enum-sort (o <interface>))
  (append
    (enum-sort-global-public (parent o <root>))
    (filter (is? <enum>) (ast:type* (.behavior o)))))

(define-method (makreel:enum-sort (o <component>))
  (append
    (enum-sort-global-public (parent o <root>))
    (append-map
      (lambda (o) (filter (is? <enum>) (ast:type* (.behavior o))))
      (append (list o) (ast:interface* o)))))

(define-method (makreel:reply-type-eq? (a <int>) (b <int>))
  #t)
(define-method (makreel:reply-type-eq? a b)
  (ast:eq? a b))

(define-method (makreel:reply-type-sort (o <interface>))
  (define (event-type-eq? a b)
    (or (makreel:reply-type-eq? (.type (.signature a)) (.type (.signature b)))
        (ast:equal? (.type.name (.signature a)) (.type.name (.signature b)))))
  (delete-duplicates
   (filter (compose (negate (is? <void>)) (compose .type .signature))
           (ast:event* o))
   event-type-eq?))

(define-method (makreel:type-constructor (o <ast>))
  (let ((type (ast:type o)))
    (match type
      (($ <bool>) o)
      (($ <int>) o)
      (($ <void>) o)
      (_ type))))

(define-method (makreel:type-constructor (o <port-pair>))
  (makreel:type-constructor (.port o)))

(define-method (makreel:modeling-sort (o <component>))
  (ast:interface* o))

(define-method (makreel:modeling-sort (o <interface>))
  o)

(define-method (makreel:event-type-name (o <event>))
  ((compose .type .signature) o))

(define-method (makreel:event-type-name (o <action>))
  ((compose makreel:event-type-name .event) o))

(define (reachable calls)
  (receive (nested direct) (partition (cut parent <> <function>) calls)
    (let loop ((nested nested) (direct direct))
      (receive (reached rest) (partition
                               (lambda (call)
                                 (find (cut ast:eq? (parent call <function>) <>)
                                       (map .function direct))) nested)
        (let* ((reached (append reached direct)))
          (if (equal? direct reached) direct
              (loop rest reached)))))))

(define (reachable-calls- o)
  (let* ((calls (tree-collect-filter
                  (disjoin (is? <behavior>) (is? <declarative>) (is? <functions>) (is? <function>) (is? <statement>))
                  (is? <call>) o))
         (calls (reachable calls)))
    calls))

(define (reachable-calls o)
  (define (calls root o)
    (reachable-calls- o))
 ((ast:pure-funcq calls) (parent o <root>) o))

(define-method (no-tail-call (o <call>))
  (not (.last? o)))

(define-method (call-continuations (o <behavior>) name)
  (delete-duplicates
   (map (compose car makreel:continuation)
        (let ((calls (filter no-tail-call (reachable-calls o))))
          (if name (filter (compose (cut equal? <> name) .function.name) calls)
              calls)))
   ast:eq?))

(define-method (call-continuations (o <behavior>))
  (call-continuations o #f))

(define-method (makreel:recurse? (o <call>))
  (if (.last? o) o
      '()))

(define-method (makreel:non-recurse? (o <call>))
  (if (.last? o) '()
      o))

(define-method (makreel:function-return-proc (o <model>))
  (if (pair? ((compose makreel:called-function* .behavior) o)) o
      '()))

(define-method (makreel:function-return (o <model>))
  (append-map makreel:function-return ((compose makreel:called-function* .behavior) o)))

(define-method (makreel:function-return (o <function>))
  (call-continuations (parent o <behavior>) (.name o)))

(define-method (is-called? (o <function>))
  (let ((calls (reachable-calls (parent o <behavior>))))
    (find (compose (cut equal? <> (.name o)) .function.name) calls)))

(define-method (makreel:called-function* (o <behavior>))
  (filter is-called? (ast:function* o)))

(define-method (makreel:called-function* (o <model>))
  ((compose makreel:called-function* .behavior) o))

(define-method (makreel:return-value (o <return>))
  (if (.expression o) o
      (clone o #:expression (make <void>))))

(define-method (makreel:return-type-sort (o <model>))
  (if (pair? ((compose makreel:called-function* .behavior) o)) o
      '()))

(define-method (ast:return-type-eq? (a <function>) (b <function>) )
  (apply ast:eq? (map (compose .type .signature) (list a b))))

(define-method (makreel:return-type (o <model>))
  (delete-duplicates (ast:function* (.behavior o)) ast:return-type-eq?))

(define-method (makreel:call-continuation-sort (o <behavior>))
  (call-continuations o))

(define-method (makreel:call-continuation-sort (o <model>))
  (if (null? (call-continuations (.behavior o))) '()
      (.behavior o)))

(define-method (ast:have-requires? (o <component>))
  (or (and (find ast:requires? (ast:port* o)) o) '()))

(define-method (ast:have-requires? (o <port>))
  (ast:have-requires? (parent o <component>)))

(define-method (ast:have-no-requires? (o <component>))
  (or (and (not (find ast:requires? (ast:port* o))) o) '()))

(define-method (ast:have-requires+async? (o <component>))
  (if (pair? (ast:requires+async-port* o)) o '()))

(define-method (ast:have-no-requires+async? (o <component>))
  (if (pair? (ast:requires+async-port* o)) '() o))

(define-method (makreel:queue-length (o <component>))
  (%queue-size))

(define-method (makreel:event-act (o <component>))
  (append
   (ast:interface* o)
   (ast:port* o)
   (ast:port* (.behavior o))))

(define-method (makreel:event-act-provides (o <port>))
  (or (ast:provides? o) '()))

(define-method (makreel:event-act-requires (o <port>))
  (or (ast:requires? o) '()))

(define-method (makreel:event-act (o <interface>))
  o)

(define-method (pretty-print-dzn (o <behavior>))
  (if (dzn:command-line:get 'debug) "\n%behavior"
      ""))

(define-method (pretty-print-dzn (o <statement>))
  (let ((debug? (dzn:command-line:get 'debug)))
    (if debug? (string-join (string-split (string-trim-right
                                           (ast->dzn o))
                                          #\newline) "\n% " 'prefix)
        "")))


(define-method (makreel:event-prefix (o <on>))
  (let ((model (parent o <model>)))
    (if (is-a? model <interface>) model
        (.port (car (ast:trigger* o))))))

(define-method (makreel:event-prefix (o <reply>))
  (or (.port o)
      (let ((model (parent o <model>)))
        (if (is-a? model <interface>) model
            (let ((trigger (and=> (parent o <on>) (compose car ast:trigger*))))
              (if (and trigger (ast:provides? trigger)) ((compose .port) trigger)
                  ((compose car ast:provides-port*) model)))))))

(define-method (makreel:event-prefix (o <port>))
  o)

(define-method (makreel:event-prefix (o <action>))
  (let ((port (.port o)))
    (or port (parent o <model>))))

(define-method (makreel:event-prefix (o <assign>))
  (ast:port-type-name o))

(define-method (makreel:event-prefix (o <statement>))
  (makreel:event-prefix (parent o <on>)))

(define-method (makreel:trigger-name (o <on>))
  (let ((trigger ((compose car ast:trigger*) o)))
    (.event trigger)))

(define-method (makreel:interface-proc (o <interface>))
  o)

(define-method (makreel:interface-proc (o <component>))
  (ast:interface* o))

(define-method (is-optional? (o <guard>))
  (is-optional? (.statement o)))

(define-method (is-optional? (o <on>))
  (is-optional? (car (ast:trigger* o))))

(define-method (is-optional? (o <trigger>))
  (equal? "optional" (.event.name o)))

(define-method (makreel:proc (o <model>))
  (makreel:proc-list o))

(define-method (makreel:proc (o <behavior>))
  (filter (negate (cut ast:eq? o <>)) (makreel:proc-list o)))

(define-method (makreel:proc (o <function>))
  (makreel:proc-list o))

(define-method (makreel:proc (o <defer>))
  (makreel:proc-list (.statement o)))

(define-method (makreel:proc-assign (o <assign>))
  (let ((expression (.expression o)))
    (if (or (is-a? expression <action>)
            (is-a? expression <call>)) expression
        o)))

(define-method (makreel:proc-variable (o <variable>))
  (let ((expression (.expression o)))
    (if (or (is-a? expression <action>)
            (is-a? expression <call>)) expression
        o)))

(define-method (makreel:else-proc (o <if>))
  (or (.else o) '()))

(define-method (makreel:reply-synchronization (o <action>))
  (let ((in? (eq? 'in (.direction (.event o)))))
    (if in? o '())))

(define (unspecified? x) (eq? x *unspecified*))

(define-method (makreel:on-proc (o <on>))
  (.statement o))

(define-method (makreel:on-proc (o <declarative-compound>))
  (ast:statement* o))

(define-method (makreel:on-proc (o <compound>))
  (ast:statement* o))

(define-method (makreel:process-index (o <statement>))
  (mcrl2:process-identifier o))

(define-method (makreel:process-index (o <action>))
  (let ((parent (.parent o)))
    (mcrl2:process-identifier
     (if (or (is-a? parent <assign>)
             (is-a? parent <variable>)) parent
             o))))

(define-method (makreel:process-index (o <behavior>))
  ((compose makreel:process-index .statement) o))

(define-method (members (o <ast>))
  (let* ((parent (parent o <model>))
	 (behavior (.behavior parent)))
    (ast:variable* behavior)))

(define-method (makreel:locals- (o <ast>))
  (if (is-a? o <behavior>) '()
      (let* ((p (.parent o)))
        (cond ((is-a? p <compound>)
               (let ((pre (cdr (member o (reverse (ast:statement* p)) ast:eq?))))
                 (append (filter (is? <variable>) pre) (makreel:locals p))))
              ((is-a? p <defer>)
               (makreel:locals- p))
              ((is-a? o <function>) ((compose ast:formal* .signature) o))
              (else (makreel:locals p))))))

(define (makreel:locals o)
  (define (locals root o)
    (makreel:locals- o))
  (let* ((model (parent o <model>))
         (root (parent model <root>)))
    ((ast:pure-funcq locals) (list root model) o)))

(define-method (variables-in-scope (o <model>)) (members o))
(define-method (variables-in-scope (o <ast>))
  (let ((stack (and (parent o <function>)
                    (not (parent (.parent o) <defer>))
                    (clone (make <stack>) #:parent o))))
    (append (members o) (makreel:locals o) (if stack (list stack) '()))))

(define-method (makreel:stack-parameters (o <ast>))
  ((compose makreel:locals car makreel:continuation) o))

(define-method (makreel:variable-parameter (o <ast>))
  (let ((v (match o
               (($ <variable>) o)
               (($ <assign>) (.variable o)))))
    (if (find (cut ast:eq? v <>) ((compose variables-in-scope car makreel:continuation) o)) o
        '())))

(define-method (makreel:function-name (o <ast>))
  (or (and=> (parent o <function>) .name) '()))

(define-method (makreel:process-parameters (o <ast>))
  (variables-in-scope o))

(define-method (makreel:process-parameters-return (o <model>))
  (append (members o) (list (clone (make <stack>) #:parent o) (clone (make <return-value>) #:parent o))))

(define-method (makreel:process-parameters-return (o <function>))
  (append (makreel:process-parameters o)
          (if (is-a? (ast:type o) <void>) '()
              (list o))))

(define-method (makreel:process-parameters-return (o <assign>))
  (append (makreel:process-parameters o)
          ((compose list .function .expression) o)))

(define-method (makreel:process-parameters-return (o <variable>))
  (append (makreel:process-parameters o)
          ((compose list .function .expression) o)))

(define-method (makreel:process-haakjes (o <ast>))
  (if (or (pair? (variables-in-scope o))
          (parent o <function>)) "()"
          ""))

(define-method (makreel:continuation-haakjes (o <ast>))
  (if (or (pair? ((compose variables-in-scope car makreel:continuation) o))
          (parent o <function>)) o
          '()))

(define-method (makreel:process-continuation (o <ast>))
  (mcrl2:process-continuation o))

(define-method (makreel:sum-helper-params (o <ast>))
  (let* ((locals (variables-in-scope o))
         (var (list (or (parent o <variable>) (.variable (parent o <assign>)))))
         (params (append locals var)))
    (delete-duplicates params ast:eq?)))

(define-method (makreel:the-end (o <ast>))
  (if (and (parent o <component>) (ast:eq? o (.statement (parent o <behavior>)))) o
      '()))

(define-method (makreel:continuation (o <ast>))
  (define (statement-continuation o)
    (let* ((p (.parent o))
           (cont (cdr (member o (ast:statement* p) (lambda (a b) (eq? (.node a) (.node b)))))))
      (if (pair? cont) (list (car cont))
          (let ((grandp (.parent p)))
            (match grandp
              (($ <compound>) (statement-continuation p))
              (($ <defer>) (list (parent o <behavior>)))
              ((? (is? <declarative>)) (list (parent o <behavior>)))
              (_  (makreel:continuation grandp)))))))

  (let* ((cont
          (match o
            ((and ($ <declarative-compound>) (= ast:statement* ())) (throw 'barf "unexpected empty declarative-compound"))
            ((and ($ <declarative-compound>) (= ast:statement* elements)) elements)
            ;;ASSUME normalized model <guard> <on> <compound>
            (($ <behavior>) (list (.statement o)))
            (($ <function>) (list (.statement o)))
            (($ <guard>) (list (.statement o)))
            (($ <blocking>) (list (.statement o)))
            (($ <on>) (list (.statement o)))
            ((and ($ <compound>) (= ast:statement* (? pair?)) (= ast:statement* elements)) (take elements 1))
            ((and ($ <call>) (= .parent ($ <assign>))) (list (.parent o))) ; 2
            ((and ($ <call>) (= .parent ($ <variable>))) (list (.parent o))) ; 2
            ((? (is? <statement>))      ; 3
             (let* ((p (.parent o)))
               (match p
                 (($ <compound>) (statement-continuation o))
                 ((? (is? <declarative>)) (list (parent o <behavior>)))
                 (($ <on>) (throw 'barf "unexpected on"))
                 (_ (makreel:continuation p)))))
            (_ (makreel:continuation (.parent o))))))
    (step-into-assign/variable o cont)))

(define (step-into-assign/variable o continuation)
  (let* ((c (car continuation))
         (e (and (or (is-a? c <assign>)
                     (is-a? c <variable>))
                 (.expression c))))
    (if (and e (is-a? e <call>) (not (ast:eq? o e))) (list e)
        continuation)))

(define-method (makreel:then-continuation (o <if>))
  (step-into-assign/variable o (list (.then o))))

(define-method (makreel:else-continuation (o <if>))
  (let ((else (.else o)))
    (if else (step-into-assign/variable o (list else))
        (makreel:continuation o))))

(define-method (makreel:proc-list (o <ast>))
  (let ((lst (proc-list o)))
    (map makreel:process-index lst) ;; side-effect!!
    lst))

(define (proc-list o)
  (match o
    ((? (is? <model>)) (proc-list (.behavior o)))
    (($ <behavior>) (append (list o) (proc-list (.statement o))))
    (($ <function>) (proc-list (.statement o)))
    (($ <declarative-compound>) (append (list o) (append-map proc-list (ast:statement* o))))
    (($ <compound>) (append (list o) (append-map proc-list (ast:statement* o))))
    (($ <guard>) (append (list o) (proc-list (.statement o))))
    (($ <on>) (append (list o) (proc-list (.statement o))))
    (($ <blocking>) (append (list o) (proc-list (.statement o))))
    (($ <if>) (append (list o) (proc-list (.then o)) (proc-list (.else o))))
    ((and ($ <assign>) (= .expression expression)
          (or (is-a? expression <action>) (is-a? expression <call>)))
     (append (list expression) (proc-list o)))
    ((and ($ <variable>)  (= .expression expression)
          (or (is-a? expression <action>) (is-a? expression <call>)))
     (append (list expression) (proc-list o)))
    ((? (is? <ast>)) (list o))
    (#f '())))

(define-method (makreel:member-init (o <component>))
  (ast:variable* o))

(define-method (makreel:member-init (o <interface>))
  (ast:variable* o))

(define-method (makreel:member-init (o <port>))
  (ast:variable* (.type o)))

(define-method (makreel:provides-proc (o <component>))
  (ast:provides-port* o))

(define-method (makreel:provides-pair* (o <port>))
  (map (cute make <port-pair> #:port o #:other <>) (ast:provides-port* o)))

(define-method (makreel:provides-reply (o <port-pair>))
  (let ((other (.other o)))
    (if (ast:eq? other (.port o)) "r"
        other)))

(define-method (makreel:provides-reply (o <port>))
  (ast:provides-port* o))

(define-method (makreel:provides-reset-reply (o <port-pair>))
  (let ((port (.port o))
        (other (.other o)))
    (if (ast:eq? other port) (format #f "~anil" (makreel:interface-name port))
        other)))

(define-method (makreel:rename-flush-provides (o <port>))
  (if (ast:provides? o) o
      '()))

(define-method (makreel:rename-flush-requires (o <port>))
  (if (ast:requires? o) o
      '()))

(define-method (makreel:allow-tau (o <component>))
  (delete-duplicates (append (map .type (ast:port* o))) ast:eq?))

(define-method (makreel:interface-action-proc (o <component>))
  (ast:port* o))

(define-method (makreel:action-proc (o <model>))
  o)

(define-method (makreel:switch-context (o <action>))
  (let* ((component (parent o <component>))
         (blocking? (and component
                         (ast:requires? o)
                         (find ast:blocking? (ast:requires-port* component)))))
    (if (or (not blocking?) (not (ast:blocking? o))) '()
        o)))

(define-method (ast:trigger* (o <model>)) ;; FIXME: maybe use ast:in-triggers
  (delete-duplicates (tree-collect-filter (is? <declarative>) (is? <trigger>) o)
                     (lambda (a b) (and (equal? (.port.name a) (.port.name b))
                                        (equal? (.event.name a) (.event.name b))))))

(define-method (ast:port-type-name (o <reply>)) ;; FIXME: return AST (interface/port) rather than string
  (let ((interface
            (or (and=> (.port o) .type)
                (let ((model (parent o <model>)))
                  (if (is-a? model <interface>) model
                      (let ((trigger (and=> (parent o <on>) (compose car ast:trigger*))))
                        (if (and trigger (ast:provides? trigger)) ((compose .type .port) trigger)
                            ((compose .type car ast:provides-port*) model))))))))
    (makreel:model-name interface)))

(define-method (ast:port-type-name (o <assign>))
  (let ((expression (.expression o)))
    (match expression
      (($ <action>)
       (let ((port (.port .expression)))
         (or port (parent o <model>))))
      (_ "BOO"))))

(define-method (ast:port-type-name (o <action>))
  (let ((port (.port o)))
    (or port (parent o <model>))))

(define-method (ast:port-type-name (o <port>))
  ((compose makreel:model-name .type) o))

(define-method (ast:port-type-name (o <expression>))
  (ast:port-type-name (parent o <reply>)))

(define-method (.event.name (o <assign>))
  (let ((expression (.expression o)))
    (match expression
      (($ <action>)
       (.event.name expression))
      (_ "BAH"))))

(define-method (makreel:enum-literal (o <enum-literal>))
  (append (ast:full-name (.type o)) (list (.field o))))

(define-method (makreel:enum-fields (o <enum>))
  (map (compose (cut clone <> #:parent o)
                (cut make <enum-literal> #:type.name (.name o) #:field <>))
       (ast:field* o)))

(define-method (makreel:type-bound (o <action>))
  (if (is-a? ((compose .type .signature .event) o) <int>) o
      '()))

(define-method (makreel:type-check (o <action>))
  (if (is-a? ((compose .type .signature .event) o) <int>)
      (let ((parent (.parent o)))
        (match parent
          (($ <assign>) (.variable parent))
          (($ <variable>) parent)))
      '()))

(define (as-int o)
  (or (and o (is-a? (ast:type o) <int>) o) '()))

(define-method (makreel:type-check (o <call>))
  (filter (compose (is? <int>) ast:type) (ast:argument* o)))

(define-method (makreel:type-check (o <return>))
  (as-int (.expression o)))

(define-method (makreel:type-check (o <variable>))
  (as-int (.expression o)))

(define-method (makreel:type-check (o <assign>))
  (as-int (.expression o)))

(define-method (makreel:type-check (o <model>))
  (map .expression (filter (compose (is? <int>) .type) (ast:member* o))))

(define-method (makreel:stack? (o <call>))
  (or (and (not (parent o <defer>)) (parent o <function>) o) '()))

(define-method (makreel:stack-empty? (o <call>))
  (or (and (or (parent o <defer>) (not (parent o <function>))) o) '()))

(define-method (makreel:stack-destructor (o <ast>))
  (let ((f (and (not (parent o <defer>))
                (parent o <function>)))
        (locals (makreel:locals o))
        (return-value (if (and (or (is-a? o <assign>) (is-a? o <variable>))
                               (is-a? (.expression o) <call>)) (list (ast:type o))
                          '())))
    (if f (append locals (list f)
                  return-value)
        (append locals return-value))))

(define-method (makreel:process-argument-stack? (o <call>))
  (let ((function (parent o <function>)))
    (cond ((and function (.last? o)) function)
          (else o))))

(define-method (makreel:enum-name (o <enum>))
  (ast:full-name o))

(define (makreel:init-process process)
  (format #f "init ~a;\n" process))

(define-method (makreel:line-column (o <tag>))
  (let ((location (.location o)))
    (format #f "~a, ~a" (.line location) (.column location))))

(define-templates-macro define-templates makreel)
(include-from-path "dzn/templates/dzn.scm")
(include-from-path "dzn/templates/makreel.scm")

(define (makreel:om ast)
  (let ((root ((compose
                makreel:mark-tail-call
                add-function-return
                normalize:state+illegals
                remove-otherwise
                makreel:tick-names
                add-explicit-temporaries
                add-defer-end
                purge-data
                ) ast)))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print root (current-error-port)))
    root))


;;;
;;; Entry points.
;;;
(define (root-> o)
  (let ((queue-size (or (%queue-size)
                        (command-line:get-number 'queue-size 3)))
        (init (command-line:get 'init)))
    (parameterize ((%queue-size queue-size)
                   (%id-alist '())
                   (%next-alist '()))
      (x:source o)
      (newline)
      (when init
        (display (makreel:init-process init))))))

(define* (ast-> ast #:key dir model)
  (let ((root (makreel:om ast)))
    (if model (makreel:model->makreel root (makreel:get-model root model))
        (root-> root))))
