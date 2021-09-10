;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; Dezyne Language completion using parse trees.
;;;
;;; Code:

(define-module (dzn parse complete)
  #:use-module (ice-9 match)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)

  #:use-module (dzn misc)
  #:use-module (dzn parse lookup)
  #:use-module (dzn parse tree)

  #:export (complete
            complete:context))

;;;
;;; Parse tree context.
;;;

(define (at-location? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((from (.pos end))
                        (to (.end end)))
                    (and (<= from at)
                         (or (<= at to)
                             (incomplete? o))))))
           (find (cute at-location? <> at) o))))

(define (after-location? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((to (.end end)))
                    (> to at))))
           (find (cute after-location? <> at) o))))

(define (around-location? o at)
  (and (pair? o)
       (receive (after before)
           (partition (cute after-location? <> at) (cdr o))
         (and (pair? before) (pair? after)))))

(define (before-location? o at)
  (and (pair? o)
       (receive (after before)
           (partition (cute after-location? <> at) (cdr o))
         (and (pair? before)
              (let ((result (filter (negate (disjoin symbol? tree:location?)) before)))
                (and (pair? result) (last result)))))))

(define (complete:context o at)
  (let ((narrow (conjoin incomplete? (negate symbol?) (negate tree:location?)))
        (context (reverse (tree:collect o (cute at-location? <> at)))))
    (if (null? context) `(,o)
        (let ((narrow (find narrow (cdar context))))
          (if narrow (cons narrow context)
              context)))))


;;;
;;; Tree to (dotted) name string.
;;;

(define (context:type-names context)
  (let* ((types (context:type* context))
         (type-names (map (cute context:stripped-dotted-name <> context)
                          types)))
    (delete-duplicates
     (sort (cons* "bool" "void"
                  type-names)
           string<))))

(define* (context:event-names o event-dir #:key (predicate identity))
  (let* ((events (tree:event* (find (is? 'interface) o)))
         (events (filter (conjoin predicate (compose (cute eq? event-dir <>) tree:direction)) events)))
    (map tree:dotted-name events)))

(define* (context:interface-names o)
  (map tree:dotted-name (tree:interface* o)))

(define (port-dir->event-dir port-dir dir)
  (cond ((and (eq? 'provides port-dir) (eq? 'trigger dir)) 'in)
        ((and (eq? 'provides port-dir) (eq? 'action dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'trigger dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'action dir)) 'in)))

(define* (context:port-event-names o   ;context
                                   dir ;'trigger or 'action
                                   #:key (event-predicate identity))
  (let* ((component (parent-context o 'component))
         (ports  (context:port* component)))
    (define (port->event-names port)
      (let* ((port-dir (tree:direction (.tree port)))
             (interface (.type port))
             (events (filter
                      tree:dotted-name
                      (filter (conjoin event-predicate
                                       (compose (cute eq? (port-dir->event-dir port-dir dir) <>)
                                                tree:direction))
                              (tree:event* (.tree interface))))))
        (define (event->name event)
          (let* ((port (tree:dotted-name port))
                 (formals (map tree:dotted-name (tree:formal* event)))
                 (formals (string-join formals ", "))
                 (event (tree:dotted-name event)))
            (format #f "~a.~a(~a)" port event formals)))
        (map event->name events)))
    (append-map port->event-names ports)))

(define* (context:trigger-names o #:key (event-predicate identity))
  (cond ((slot o 'interface)
         (sort (cons* "inevitable" "optional"
                      (context:event-names o 'in #:predicate event-predicate))
               string<))
        ((slot o 'component)
         (sort (context:port-event-names o 'trigger #:event-predicate event-predicate)
               string<))
        (else
         '())))

(define* (context:action-names o #:key (event-predicate identity))
  (cond ((slot o 'interface) (context:event-names o 'out #:predicate event-predicate))
        ((slot o 'component) (context:port-event-names o 'action #:event-predicate event-predicate))
        (else '())))

(define* (tree:function-names o #:key (type-predicate identity))
  (let* ((functions (tree:function* o))
         (functions (filter (compose type-predicate .type-name) functions)))
    (define (function->name f)
      (let* ((name (tree:dotted-name f))
             (formals (map (const "_") (tree:formal* f)))
             (formals (string-join formals ", ")))
        (format #f "~a(~a)" name formals)))
    (map function->name functions)))

(define* (context:enum-value-names o #:key (context o))
  (assert-type (.tree o) 'enum)
  (let ((fields (tree:field* (.tree o))))
    (map (cute string-append (context:stripped-dotted-name o context) "." <>)
         (map tree:dotted-name fields))))

(define (tree:int-value-names o)
  (assert-type o 'int)
  (let* ((range (.range o))
         (from (.from range)))
    (map number->string (iota (1+ (- (.to range) from)) from))))

(define (tree:enum-field-tests o name)
  (assert-type o 'enum)
  (let ((fields (tree:field* o)))
    (map (cute string-append (tree:dotted-name name) "." <>)
         (map tree:dotted-name fields))))

(define* (context:type-value-names o #:key (context o))
  (cond ((is-a? (.tree o) 'enum) (context:enum-value-names o #:context context))
        ;;((is-a? (.tree o) 'int) (context:int-value-names o))
        ((is-a? (.tree o) 'bool) '("false" "true"))
        (else '())))

(define (context:locals o)
  (let loop ((scope (parent-context o tree:scope?)))
    (if (or (not scope) (is-a? (.tree scope) 'behaviour-statements)) '()
        (append (context:formal* scope)
                (context:variable* scope)
                (loop (parent-context scope tree:scope?))))))

(define (context:members o)
  (let ((scope (parent-context o 'behaviour-statements)))
    (or (and scope (context:variable* scope)) '())))

(define (type-equal? o type)
  (let ((type-name (and=> type .name)))
    (cond
     ((is-a? type 'int)
      #t)
     (else
      (tree:name-equal? type-name (.type-name o))))))

(define (complete:variable-names type context)
  (let* ((variables (append (context:locals context)
                            (context:members context)))
         (variables (if (not type) variables
                        (filter (compose (cute type-equal? <> type) .tree)
                                variables))))
    (map (compose tree:dotted-name .tree) variables)))

(define (complete-enum-literal name context)
  (assert-type (.tree context) 'enum-literal)
  (let* ((field (.field (.tree context)))
         (enum  (.type context)))
    (cond
     ((not enum)
      (context:type-names context))
     ((equal? field name)
      (context:type-value-names enum #:context context))
     ((and (not (parent context 'function))
           (not (parent context 'on)))
      (context:type-value-names enum #:context context))
     (else
      (sort
       (append
        (complete:variable-names (.tree enum) context)
        (tree:function-names
         (parent context 'behaviour)
         #:type-predicate (cute type-equal? <> (.tree enum)))
        (context:action-names
         context
         #:event-predicate (compose (cute type-equal? <> (.tree enum)) .type-name))
        (context:type-value-names enum #:context context))
       string<)))))

(define (complete-literal o context)
  (assert-type o 'literal)
  (let* ((type (tree:type? o))
         (name (and=> type .name)))
    (cond
     ((not type)
      (context:type-names context))
     (else
      (sort
       (append
        (complete:variable-names type context)
        (tree:function-names
         (parent context 'behaviour)
         #:type-predicate (cute type-equal? <> type))
        (context:type-value-names (cons type context)))
       string<)))))

(define (complete-for-type type context)
  (assert-type (.tree type) 'bool 'enum 'extern 'int)
  (sort
   (append
    (complete:variable-names (.tree type) context)
    (context:action-names
     context
     #:event-predicate (compose (cute type-equal? <> (.tree type)) .type-name))
    (tree:function-names
     (parent context 'behaviour)
     #:type-predicate (cute type-equal? <> (.tree type)))
    (context:type-value-names type #:context context))
   string<))

(define (context:complete-for-type context)
  (assert-type context tree:context?)
  (let ((type (cond
               ((parent-context context 'var)
                => .type)
               ((parent-context context 'variable)
                => .type)
               (else
                #f))))
    (cond
     ((not type)
      (context:type-names context))
     (else
      (complete-for-type type context)))))

(define (complete-function context)
  (assert-type context tree:context?)
  (let* ((function (parent-context context 'function))
         (type (and=> function .type)))
    (cond
     ((not type)
      (context:type-names context))
     (else
      (sort
       (append
        (complete:variable-names (.tree type) context)
        (tree:function-names
         (parent context 'behaviour)
         #:type-predicate (cute type-equal? <> (.tree type)))
        (context:type-value-names type #:context context))
       string<)))))

(define (complete-on context)
  (assert-type context tree:context?)
  (let* ((on (parent-context context 'on))
         (triggers  (and=> on context:trigger*))
         (trigger   (and (pair? triggers) (car triggers)))
         (type      (and=> trigger .type)))
    (cond
     ((not type)
      (context:type-names context))
     (else
      (sort
       (append
        (complete:variable-names (.tree type) context)
        (tree:function-names
         (parent context 'behaviour)
         #:type-predicate (cute type-equal? <> (.tree type)))
        (context:type-value-names type #:context context))
       string<)))))

(define (complete:boolean-expressions context)
  (sort (cons* "true" "false"
               (complete:variable-names #f context))
        string<))

(define (instance-ports instance)
  (let ((component (.type instance)))
    (context:port* component)))

(define (instance-ports-alist context)
  (let* ((system (.tree context))
         (instances (tree:instance* system))
         (instance-contexts (map (cute cons <> context) instances))
         (instance-names (map tree:dotted-name instances)))
    (map cons
         instance-names
         (map instance-ports instance-contexts))))

(define (instance-binding entry)
  (match entry
    ((instance ports ...)
     (map (cute string-append instance "." <>)
          (map (compose tree:dotted-name .tree) ports)))))

(define (complete-other-end-point o context)
  (define (filter-alist alist port predicate)
    (map
     (match-lambda
       ((instance ports ...)
        (let* ((ports (filter
                       (compose (cute tree:type-equal? <> (.tree port)) .tree)
                       ports))
               (ports (if (predicate (.tree port))
                          (filter (compose tree:provides? .tree) ports)
                          (filter (compose tree:requires? .tree) ports))))
          (cons instance ports))))
     alist))
  (let ((port (.port (cons o context)))
        (instance (.instance (cons o context)))
        (system (parent-context context 'system)))
    (cond
     ((and port (not instance))
      (let* ((alist (instance-ports-alist system))
             (alist (filter-alist alist port tree:provides?))
             (bindings (append-map instance-binding alist)))
        (sort (delete-duplicates bindings) string<)))
     (port
      (let* ((component (parent context 'component))
             (ports (tree:port* component))
             (ports (filter (cute tree:type-equal? <> (.tree port)) ports))
             (ports (if (tree:provides? (.tree port))
                        (filter tree:provides? ports)
                        (filter tree:requires? ports)))
             (alist (instance-ports-alist system))
             (alist (filter-alist alist port tree:requires?))
             (instance-name (tree:dotted-name (.tree instance)))
             (alist (filter
                     (compose (negate (cute equal? <> instance-name)) car)
                     alist))
             (bindings (append (map tree:dotted-name ports)
                               (append-map instance-binding alist))))
        (sort (delete-duplicates bindings) string<)))
     (else
      '()))))

(define (filter-self context list)
  (let* ((variable (or (is-a? (.tree context) 'formal)
                       (is-a? (.tree context) 'variable)
                       (parent context 'formal)
                       (parent context 'variable)))
         (name (and=> variable tree:dotted-name)))
    (filter (negate (cute equal? <> name)) list)))

(define (behaviour-top context)
  (sort (append
         '( "enum" "extern" "on" "subint")
         (context:type-names context))
        string<))

(define (context:on-type context)
  (let* ((triggers (context:trigger* context))
         (types (map .type triggers)))
    (find (negate (cute equal? <> context:void)) types)))

(define (context:statements context)
  (let ((statements (cond
                     ((parent context 'function)
                      '("return"))
                     ((or (and (is-a? (.tree context) 'on) context)
                          (parent-context context 'on))
                      =>
                      (lambda (on)
                        (let ((type (context:on-type on)))
                          (if type '("reply(_)")
                              '()))))
                     (else
                      '()))))
    (sort (append
           ;;'("if") ;;TODO
           statements
           (context:type-names context)
           (complete:variable-names #f context)
           (context:action-names context))
          string<)))

(define (system-top context)
  (let* ((root (parent context 'root))
         (component (parent context 'component))
         (alist (instance-ports-alist context))
         (bindings (append-map instance-binding alist)))

    (sort (append
           (delete-duplicates (map tree:dotted-name (tree:component* root)))
           (delete-duplicates (map tree:dotted-name (tree:instance* (.tree context))))
           (delete-duplicates (append bindings
                                      (map tree:dotted-name (tree:port* component)))))
          string<)))

(define %completion-top
  '("component" "enum" "extern" "import" "interface" "namespace" "subint"))
(define %completion-interface '("behaviour" "enum" "extern" "in" "out" "subint"))
(define %completion-component '("behaviour" "provides" "requires" "system"))
(define %completion-behaviour '("bool" "enum" "extern" "on" "subint" "void"))


;;;
;;; Entry points.
;;;

(define (context:complete o context offset)
  (match o
    (#f
     '())
    ((? (is? 'root))
     %completion-top)
    ((? (is? 'file-name))
     (context:complete (.tree (.parent context)) (.parent context) offset))
    ((and (? (is? 'interface))
          (? complete?))
     (cond ((not (.behaviour o))
            %completion-interface)
           ((after-location? (.behaviour o) offset)
            '("in" "out" "enum" "extern" "subint"))
           (else '())))
    ((and (? (is? 'component))
          (? complete?))
     (cond ((and (not (.behaviour o))
                 (not (.system o)))
            %completion-component)
           ((after-location? (.behaviour o) offset)
            '("provides" "requires"))
           ((after-location? (.system o) offset)
            '("provides" "requires"))
           (else '())))
    ((or (? (is? 'port-qualifiers))
         (? (is? 'provides))
         (? (is? 'requires)))
     (let ((context (parent-context context 'port)))
       (context:complete (.tree context) context offset)))
    ((? (is? 'port))
     (cond ((and (not (slot o 'provides))
                 (not (slot o 'requires)))
            '("provides" "requires"))
           ((slot o 'provides)
            (context:interface-names (parent context 'root)))
           (else
            (let* ((qualifiers (tree:port-qualifier* o))
                   (external? (find (is? 'external) qualifiers))
                   (injected? (find (is? 'injected) qualifiers)))
              (append (if external? '() '("external"))
                      (if injected? '() '("injected"))
                      (context:interface-names (parent context 'root)))))))
    ('types-and-events
     '("in" "out" "enum" "extern" "subint"))
    ((? (is? 'types-and-events))
     %completion-interface)
    ((and (? (is? 'event)) (? incomplete?))
     (let ((direction (.direction o))
           (type-name (.type-name o))
           (type (.type context))
           (name (.name o)))
       (cond ((and direction (or (not type) (not name)))
              (context:type-names context))
             (else
              '()))))
    ((and (? (is? 'direction)) (? complete?))
     (context:complete (.tree (.parent context)) (.parent context) offset))
    ('type-name
     (context:type-names context))
    ((and (? (is? 'ports)) (? (cute around-location? <> offset)))
     '("provides" "requires"))
    ((or 'body
         (? (is? 'ports)))
     %completion-component)
    ('behaviour
     %completion-interface)
    ((? (is? 'behaviour-statements))
     (match context
       ((o ('BRACE-OPEN b ...) t ...)
        '())
       (_
        (let ((incomplete (find incomplete? (cdr o))))
          (cond ((is-a? incomplete 'on)
                 (context:trigger-names context))
                (else
                 (behaviour-top context)))))))
    ((? (is? 'behaviour-compound))
     (behaviour-top context))
    ((? (is? 'system))
     (system-top context))
    ((? (is? 'instances-and-bindings))
     (system-top context))
    ((and (? (is? 'binding)) (? incomplete?))
     (let ((left (.left o))
           (right (.right o)))
       (cond ((and left (not right))
              (complete-other-end-point left context))
             (else
              '()))))
    ((? (is? 'binding))
     (let ((left (.left o))
           (right (.right o)))
       (cond ((and left (.port-name left)
                   right (.port-name right)
                   (not (.instance-name left))
                   (not (.instance-name right)))
              (complete-other-end-point left context))
             (else
              '()))))
    ((? (is? 'dollars))
     (filter-self context (context:complete-for-type context)))
    ((? (is? 'literal))
     (cond
      ((is-a? (tree:type? o) 'bool)
       (filter-self context (complete-literal o context)))
      ((is-a? (tree:type? o) 'int)
       (filter-self context (complete-literal o context)))
      (else
       '())))
    ((? (is? 'name))
     (cond
      ((parent-context context 'enum-literal)
       => (compose (cute filter-self context <>)
                   (cute complete-enum-literal o <>)))
      ((parent context 'reply)
       (complete-on context))
      ((parent context 'return)
       (complete-function context))
      (else
       (context:complete (.tree (.parent context)) (.parent context) offset))))
    ((and (? (is? 'reply)) (? (negate .expression)))
     (let* ((on (parent-context context 'on))
            (type (context:on-type on)))
       (if type (complete-for-type type context)
           '())))
    ((and (? (is? 'return)) (? (negate .expression)))
     (complete-function context))
    ((? (is? 'var))
     (cond ((not (parent context 'expression)) '())
           ((let* ((type (.type context))
                   (enum (and type .tree)))
              (is-a? (.tree enum) 'enum))
            => (lambda (enum)
                 (let* ((variable (or (parent context 'formal)
                                      (parent context 'variable)))
                        (name (and variable (tree:dotted-name variable))))
                   (filter-self context (complete-for-type enum context)))))
           ;; field test
           ((let* ((variable (.variable context))
                   (type (and=> variable .type))
                   (enum (and=> type .tree)))
              (is-a? enum 'enum))
            => (cute tree:enum-field-tests <> (tree:name o)))
           ((let* ((variable (.variable context))
                   (type (and=> variable .type)))
              (tree:context? type))
            => (lambda (type)
                 (filter-self context (complete-for-type type context))))
           (else
            '())))
    ((and (? (is? 'formal)) (? incomplete?))
     (let ((type-name (.type-name o))
           (type (.type context))
           (name (.name o)))
       (cond ((or (not type) (not name))
              (context:type-names context))
             (else
              '()))))
    ((? (is? 'arguments))
     (cond ((and (parent context 'component)
                 (parent-context context 'action))
            =>
            (lambda (action)
              (let ((type (.type action)))
                (complete-for-type type context))))
           ((parent-context context 'call)
            =>
            (lambda (call)
              (let ((function (.function call)))
                (if (not function) '()
                    (let ((arguments (tree:argument* (.tree call)))
                          (formals (tree:formal* (.tree function))))
                      (if (< (length formals) (length arguments)) '()
                          (let* ((formal (list-ref formals (length arguments)))
                                 (type (.type (cons formal function))))
                            (complete-for-type type context))))))))))
    ((? (is? 'field-test))
     (cond ((let* ((var (.var o))
                   (variable (.variable (cons var context))))
              (and (is-a? (.tree variable) 'variable) variable))
            =>
            (lambda (variable)
              (let* ((enum (.type variable))
                     (var (.var o))
                     (name (.name var)))
                (tree:enum-field-tests (.tree enum) name))))
           ((parent-context context 'variable)
            =>
            (lambda (context)
              (context:complete (.tree context) context offset)))
           (else
            (complete:boolean-expressions context))))
    ((? (is? 'triggers))
     (context:trigger-names context))
    ((? (is? 'trigger))
     (context:trigger-names context))
    ((? (is? 'on))
     (cond ((null? (tree:trigger* o))
            (context:trigger-names context))
           (else
            (context:statements context))))
    ((and (? (is? 'variable)) (? incomplete?))
     (let* ((type (.type context))
            (expression (false-if-exception (.expression o)))
            (expression (and expression (.value expression))))
       (cond ((not type)
              (context:type-names context))
             ((or (eq? type context:bool)
                  (and (not (is-a? type 'enum))
                       (not expression)
                       (not (parent context 'on))
                       (not (parent context 'function))))
              (filter-self context (context:type-value-names type #:context context)))
             (type
              (filter-self context (complete-for-type type context)))
             (else
              '()))))
    ((and (? (is? 'variable)))
     (let ((type (.type context)))
       (filter-self context (complete-for-type type context))))
    ((? (is? 'guard))
     (cond ((incomplete? o) (context:complete (.expression o) (cons (.expression o) context) offset))
           ((not (parent context 'on)) (behaviour-top context))
           (else '())))
    ((? (is? 'expression))
     (context:complete (.value o) (cons (.value o) context) offset))
    (('or 'otherwise 'expression)
     (sort (cons "otherwise" (complete:boolean-expressions context)) string<))

    ((? (is? 'statement))
     (cond ((parent context 'on) (context:statements context))
           ((parent context 'function) (context:statements context))
           (else (behaviour-top context))))

    ((? (is? 'compound))
     (cond ((parent context 'on) (context:statements context))
           ((parent context 'function) (context:statements context))
           (else (behaviour-top context))))

    ((? (is? 'action))
     (context:statements context))

    ((? (is? 'comment))
     (context:complete (parent context tree?)
                       (parent-context context tree?) offset))

    ((or 'BRACE-CLOSE
         'BRACE-OPEN
         (? symbol?))
     '())
    (_
     (if (and (complete? o)
              (not (is-a? o 'comment))) '()
              (or (and (pair? o)
                       (and=> (find incomplete? (cdr o))
                              (cute context:complete <> context offset)))
                  (context:complete (before-location? o offset) context offset))))))

(define* (complete o context offset #:key
                   (file-name->parse-tree (const '()))
                   (resolve-file (lambda args (car args))))
  (parameterize ((%file-name->parse-tree file-name->parse-tree)
                 (%resolve-file resolve-file))
    (context:complete o context offset)))
