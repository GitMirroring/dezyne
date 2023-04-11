;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2019, 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018, 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018, 2019, 2020 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn code language makreel)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module (dzn ast display)
  #:use-module (dzn ast equal)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast normalize)
  #:use-module (dzn ast)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code scmackerel makreel)
  #:use-module (dzn code)
  #:use-module (dzn code scmackerel makreel)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn verify constraint)

  #:export (%model-name
            makreel:.name
            makreel:arguments
            makreel:call-continuation*
            makreel:called-function*
            makreel:constraint
            makreel:defer*
            makreel:defer-skip?
            makreel:enum-fields
            makreel:full-name
            makreel:get-model
            makreel:init-process
            makreel:line-column
            makreel:locals
            makreel:model->makreel
            makreel:name
            makreel:om
            makreel:process-parameters
            makreel:process-parens
            makreel:stack-empty?
            makreel:switch-context?
            makreel:tick-names
            makreel:unticked-dotted-name
            makreel:proc-list
            makreel:process-identifier
            makreel:variables-in-scope
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
  (let* ((model-name (ast:dotted-name model))
         (root' (tree-filter (disjoin (negate (is? <component>))
                                      (cut ast:eq? <> model))
                             root)))
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
(define-method (makreel:arguments (o <ast>))
  (let ((parameters (makreel:process-parameters o)))
    (map .name parameters)))

(define-method (makreel:defer*-unmemoized (o <ast>))
  (tree-collect (is? <defer>) o))

(define makreel:defer*
  (ast:perfect-funcq makreel:defer*-unmemoized))

(define-method (makreel:defer-skip? (o <model>))
  (and (is-a? o <component>)
       (pair? (makreel:defer* o))))

(define-method (makreel:switch-context? (o <action>))
  (and (ast:requires? o)
       (ast:blocking? o)))

(define-method (makreel:full-name (o <named>))
  (string-join (ast:full-name o) ""))

(define-method (makreel:full-name (o <shared-variable>))
  (string-append (.port.name o) "port_" (.name o)))

(define (reachable calls)
  (let ((nested direct (partition (cute ast:parent <> <function>) calls)))
    (let loop ((nested nested) (direct direct))
      (let ((reached rest (partition
                           (lambda (call)
                             (find (cut ast:eq? (ast:parent call <function>) <>)
                                   (map .function direct))) nested)))
        (let* ((reached (append reached direct)))
          (if (equal? direct reached) direct
              (loop rest reached)))))))

(define (reachable-calls-unmemoized root o)
  (let* ((calls (tree-collect-filter
                 (disjoin (is? <behavior>)
                          (is? <declarative>)
                          (is? <functions>)
                          (is? <function>)
                          (is? <statement>))
                 (is? <call>) o))
         (calls (reachable calls)))
    calls))

(define (reachable-calls o)
  ((ast:pure-funcq reachable-calls-unmemoized) (ast:parent o <root>) o))

(define-method (is-called? (o <function>))
  (let ((calls (reachable-calls (ast:parent o <behavior>))))
    (find (compose (cut equal? <> (.name o)) .function.name) calls)))

(define-method (makreel:called-function* (o <behavior>))
  (filter is-called? (ast:function* o)))

(define-method (makreel:called-function* (o <model>))
  ((compose makreel:called-function* .behavior) o))

(define-method (makreel:process-index (o <statement>))
  (makreel:process-identifier o))

(define-method (makreel:process-index (o <action>))
  (let ((parent (.parent o)))
    (makreel:process-identifier
     (if (or (is-a? parent <assign>)
             (is-a? parent <variable>)) parent
             o))))

(define-method (makreel:process-index (o <behavior>))
  ((compose makreel:process-index .statement) o))

(define-method (makreel:locals-unmemoized root (o <ast>))
  (if (is-a? o <behavior>) '()
      (let* ((p (.parent o)))
        (cond ((is-a? p <compound>)
               (let ((pre (cdr (member o (reverse (ast:statement* p)) ast:eq?))))
                 (append (filter (is? <variable>) pre) (makreel:locals p))))
              ((is-a? p <defer>)
               (let ((model (ast:parent p <model>)))
                 (makreel:locals p)))
              ((is-a? o <function>)
               ((compose ast:formal* .signature) o))
              (else
               (makreel:locals p))))))

(define-method (makreel:locals (o <ast>))
  (let* ((model (ast:parent o <model>))
         (root (ast:parent model <root>)))
    ((ast:pure-funcq makreel:locals-unmemoized) (list root model) o)))

(define-method (makreel:member* (o <ast>))
  (ast:member* (ast:parent o <model>)))

(define-method (makreel:variables-in-scope (o <model>))
  (ast:member* o))

(define-method (makreel:variables-in-scope (o <ast>))
  (let ((stack (and (or (as o <function>)
                        (ast:parent o <function>))
                    (not (ast:parent o <defer>))
                    (clone (make <stack>) #:parent o))))
    (append (makreel:member* o)
            (makreel:locals o)
            (if (not stack) '()
                (list stack)))))

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

(define-method (makreel:enum-fields (o <enum>))
  (map (compose (cut clone <> #:parent o)
                (cut make <enum-literal> #:type.name (.name o) #:field <>))
       (ast:field* o)))

(define-method (makreel:call-continuation*-unmemoized (o <behavior>))
  (let* ((calls (tree-collect (disjoin
                               (is? <call>)
                               (conjoin
                                (disjoin (is? <variable>)
                                         (is? <assign>))
                                (compose (is? <call>)
                                         .expression)))
                              o))
         (called (makreel:called-function* o))
         (calls (filter (compose
                         (disjoin not
                                  (cute member <> called ast:eq?))
                         (cute ast:parent <> <function>))
                        calls)))
    (cons (map (compose car ast:continuation*) calls)
          calls)))

(define-method (makreel:call-continuation* (o <behavior>))
  (match ((ast:perfect-funcq makreel:call-continuation*-unmemoized) o)
    ((continuations . calls)
     (values continuations calls))))

(define-method (makreel:call-continuation* (o <model>))
  (let ((behavior (.behavior o)))
    (makreel:call-continuation* behavior)))

(define-method (makreel:call-continuation* (o <ast>))
  (let ((behavior (ast:parent o <behavior>)))
    (makreel:call-continuation* behavior)))

(define-method (makreel:stack-empty? (o <call>))
  (or (is-a? o <defer>)
      (ast:parent o <defer>)
      (not (ast:parent o <function>))))


;;;
;;; Helpers.
;;;
(define-method (makreel:init (o <root>))
  (let* ((model-name (%model-name)))
    (define (named? o)
      (equal? (makreel:unticked-dotted-name o) model-name))
    (let ((model (and model-name
                      (find named? (ast:model* o)))))
      (or model
          (find (is? <component>) (ast:model* o))
          (find (is? <interface>) (ast:model* o))))))

(define (makreel:init-process process)
  (format #f "init ~a;\n" process))

(define-method (makreel:line-column (o <tag>))
  (let ((location (.location o)))
    (format #f "~a, ~a" (.line location) (.column location))))

(define (makreel:process-identifier o)
  (let* ((model-key ((compose .id (cute ast:parent <> <model>)) o))
         (path (ast:path o))
         (key (map .id path))
	 (next (assq-ref (%next-alist) model-key))
	 (next (or next -1)))
    (number->string (or (assoc-ref (%id-alist) key)
			(let ((next (1+ next)))
                          (%id-alist (acons key next (%id-alist)))
                          (%next-alist (assoc-set! (%next-alist) model-key next))
                          next)))))

(define-method (makreel:process-parens (o <ast>))
  (and (or (pair? (makreel:variables-in-scope o))
           (ast:parent o <function>))
       '()))

(define-method (makreel:process-parameters (o <ast>))
  (makreel:variables-in-scope o))


;;;
;;; Normalizations.
;;;
(define %count (make-parameter 0))
(define (makreel:tick-names o)
  (parameterize ((%count 0))
    ((tick-names- '()) o)))
(define* ((tick-names- #:optional (names '())) o)
  (define* ((append-tick #:optional (names '())) o)
    (if (or (not o) (ast:wildcard? o) (ast:empty-namespace? o)) o
        (let ((count (or (assoc-ref names o) 0)))
          (string-append o "'"
                         (if (zero? count) ""
                             (string-append (number->string count) "'"))))))
  (match o
    (($ <root>)
     (tree-map (tick-names-) o))
    ((? (is? <model>))
     (clone (tree-map (tick-names-) o)
            #:name ((compose (tick-names-) .name) o)))
    (($ <int>)
     o)
    (($ <bool>)
     o)
    (($ <void>)
     o)
    ((and ($ <scope.name>)
          (or (= .ids '("<int>")) (= .ids '("void")) (= .ids '("bool"))))
     o)
    ((? (is? <type>))
     (clone o #:name ((compose (tick-names-) .name) o)))
    (($ <scope.name>)
     (clone o #:ids (map (append-tick) (.ids o))))
    (($ <port>)
     (clone o
            #:name ((compose (append-tick) .name) o)
            #:type.name ((compose (tick-names-) .type.name) o)))
    (($ <trigger>)
     (clone o #:port.name ((compose (append-tick) .port.name) o)))
    (($ <action>)
     (clone o #:port.name ((compose (append-tick) .port.name) o)))
    (($ <behavior>)
     (let ((names (map (cut cons <> 0) (map .name (ast:variable* o)))))
       (fold (lambda (field method o)
               (clone o field ((compose (tick-names- names) method) o)))
             o
             (list #:types #:ports #:variables #:functions #:statement)
             (list .types .ports .variables .functions .statement))))
    (($ <var>)
     (clone o #:name ((compose (append-tick names) .name) o)))
    (($ <shared-var>)
     (clone o #:port.name ((compose (append-tick names) .port.name) o)
            #:name ((compose (append-tick names) .name) o)))
    (($ <field-test>)
     (clone o #:variable.name ((compose (append-tick names) .variable.name) o)))
    (($ <shared-field-test>)
     (clone o
            #:port.name ((compose (append-tick names) .port.name) o)
            #:variable.name ((compose (append-tick names) .variable.name) o)))
    (($ <formal>)
     (clone o
            #:name ((compose (append-tick names) .name) o)
            #:type.name ((compose (tick-names-) .type.name) o)))
    (($ <formal-binding>)
     (clone o
            #:name ((compose (append-tick) .name) o)
            #:type.name ((compose (tick-names-) .type.name) o)
            #:variable.name ((compose (append-tick names) .variable.name) o)))
    (($ <function>)
     (let* ((signature (.signature o))
            (type-name ((compose (tick-names- names) .type.name) signature))
            (names
             formals
             (let loop ((formals (ast:formal* signature)) (bumped '())
                        (names names))
               (define (bump-tick name)
                 (%count (1+ (%count)))
                 (acons name (%count) names))
               (if (null? formals) (values names bumped)
                   (let* ((formal (car formals))
                          (names (bump-tick (.name formal)))
                          (formal ((tick-names- names) formal)))
                     (loop (cdr formals) (append bumped (list formal))
                           names)))))
            (formals (clone (.formals signature) #:elements formals))
            (signature (clone signature
                              #:type.name type-name
                              #:formals formals)))
       (clone o
              #:name ((compose (append-tick names) .name) o)
              #:signature signature
              #:statement ((compose (tick-names- names) .statement) o))))
    (($ <call>)
     (clone o
            #:function.name ((compose (append-tick names) .function.name) o)
            #:arguments ((compose (tick-names- names) .arguments) o)))
    (($ <assign>)
     (clone o
            #:variable.name ((compose (append-tick names) .variable.name) o)
            #:expression ((compose (tick-names- names) .expression) o)))
    (($ <reply>)
     (clone o
            #:port.name ((compose (append-tick) .port.name) o)
            #:expression ((compose (tick-names- names) .expression) o)))
    (($ <variable>)
     (clone o
            #:name ((compose (append-tick names) .name) o)
            #:type.name ((compose (tick-names-) .type.name) o)
            #:expression ((compose (tick-names- names)
                                   .expression) o)))
    (($ <shared-variable>)
     (clone o
            #:port.name ((compose (append-tick names) .port.name) o)
            #:name ((compose (append-tick names) .name) o)
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
    ((? (is? <ast>))
     (tree-map (tick-names- names) o))
    (_ o)))

(define (makreel:mark-tail-call o)
  (match o
    (($ <call>)
     (let ((continuation ((compose car ast:continuation*) o)))
       (if (and (is-a? continuation <return>)
                (is-a? (ast:type (.expression continuation)) <void>))
           (clone o #:last? #t)
           o)))
    (($ <expression>)
     o)
    (($ <location>)
     o)
    ((? (is? <ast>))
     (tree-map makreel:mark-tail-call o))
    (_ o)))

(define (makreel:short-circuit? o)
  (match o
    ((or ($ <foreign>) ($ <system>))
     o)
    ((and ($ <component>) (? ast:imported?))
     o)
    (_
     #f)))

(define (makreel:om ast)
  (parameterize ((%normalize:short-circuit? makreel:short-circuit?))
    (let ((root ((compose
                  makreel:add-shared-variables
                  makreel:mark-tail-call
                  add-function-return
                  extract-call
                  normalize:state+illegals
                  remove-otherwise
                  makreel:tick-names
                  add-explicit-temporaries
                  add-defer-end
                  (if (%no-unreachable?) identity tag-imperative-blocks)
                  purge-data
                  ) ast)))
      (when (> (dzn:debugity) 1)
        (ast:pretty-print root (current-error-port)))
      root)))


;;;
;;; Constraint
;;;
(define (makreel:constraint o)
  (interface->constraint o))


;;;
;;; Shared state
;;;
(define-method (makreel:shared* (o <behavior>))
  (delete-duplicates
   (tree-collect (disjoin (is? <shared-var>)
                          (is? <shared-field-test>)) o)
   (lambda (a b)
     (and
      (equal? (.port.name a)
              (.port.name b))
      (equal? (.variable.name a)
              (.variable.name b))))))

(define (makreel:add-shared-variables o)
  (define (shared-var->shared-variable var)
    (let ((variable (.variable var)))
      (make <shared-variable>
        #:port.name (.port.name var)
        #:name (.name variable)
        #:type.name (.type.name variable)
        #:expression (.expression variable))))
  (match o
    (($ <interface>) o)
    (($ <variables>)
     (let* ((behavior (ast:parent o <behavior>))
            (shared (makreel:shared* behavior))
            (shared (delete-duplicates shared ast:equal?))
            (shared (map shared-var->shared-variable shared)))
       (clone o #:elements (append (ast:variable* o) shared))))
    ((? (is? <ast>)) (tree-map makreel:add-shared-variables o))
    (_ o)))

(define-method (makreel:shared-var* (o <behavior>))
  (let ((shared (makreel:shared* o)))
    (delete-duplicates shared ast:equal?)))

(define-method (print-ast (o <shared-var>) port)
  (let ((lst (ast:full-name o)))
    (display (string-join lst "") port)))

(define-method (print-ast (o <shared-field-test>) port)
  (let* ((variable (.variable o))
         (type (.type variable))
         (type-name (make <scope.name> #:ids (ast:full-name type)))
         (enum-literal (make <enum-literal>
                         #:type.name type-name
                         #:field (.field o)))
         (enum-literal (clone enum-literal #:parent (.parent o)))
         (var (make <var> #:name (makreel:full-name (.variable o))))
         (expression (make <equal>
                       #:left var
                       #:right enum-literal))
         (expression (clone expression)))
    (print-ast expression port)))


;;;
;;; Entry points.
;;;
(define (root-> o)
  (parameterize ((%id-alist '())
                 (%next-alist '())

                 (%member-prefix #f)
                 (%name-infix "")
                 (%type-infix "")
                 (%type-prefix ""))
    (root->scmackerel o)))

(define* (ast-> ast #:key dir model)
  (let ((root (makreel:om ast))
        (init (command-line:get 'init)))
    (if model (makreel:model->makreel root (makreel:get-model root model))
        (root-> root))
    (when init
      (display (makreel:init-process init)))))
