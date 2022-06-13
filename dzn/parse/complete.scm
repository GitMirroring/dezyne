;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (dzn misc)
  #:use-module (dzn parse lookup)
  #:use-module (dzn parse tree)
  #:use-module (dzn shell-util)

  #:export (complete
            complete:context))

;;;
;;; Parse tree context.
;;;

(define (tree:at-location-incomplete? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((from (.pos end))
                        (to (.end end)))
                    (and (<= from at)
                         (or (<= at to)
                             (incomplete? o))))))
           (find (cute tree:at-location-incomplete? <> at) o))))

(define (tree:at-location? o at)
  (and (pair? o)
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((from (.pos end))
                        (to (.end end)))
                    (and (<= from at)
                         (<= at to)))))
           (find (cute tree:at-location? <> at) o))))

(define (tree:after-location? o at)
  (and (pair? o)
       (not (tree:at-location? o at))
       (or (let ((end (last o)))
             (and ((is? 'location) end)
                  (let ((to (.end end)))
                    (and (> to at) o))))
           (find (cute tree:after-location? <> at) o))))

(define (tree:around-location? o at)
  (and (pair? o)
       (or (tree:at-location? o at)
           (let* ((after before
                         (partition (cute tree:after-location? <> at) (cdr o))))
             (and (pair? before) (pair? after))))))

(define (tree:before-location? o at)
  (and (pair? o)
       (not (tree:at-location? o at))
       (let ((after before
                    (partition (cute tree:after-location? <> at) (cdr o))))
         (and (pair? before)
              (let ((result (filter (negate (disjoin symbol? tree:location?)) before)))
                (and (pair? result) (last result)))))))


;;;
;;; Context accessors.
;;;

(define (context:locals o)
  (let loop ((scope (context:parent o tree:scope?)))
    (if (or (not scope) (is-a? (.tree scope) 'behavior-statements)) '()
        (append (context:formal* scope)
                (context:variable* scope)
                (loop (context:parent scope tree:scope?))))))

(define (context:members o)
  (let ((scope (context:parent o 'behavior-statements)))
    (or (and scope (context:variable* scope)) '())))


;;;
;;; Completion names.
;;;

(define %completion-top
  '("component" "enum" "extern" "import" "interface" "namespace" "subint"))
(define %completion-interface '("behavior" "enum" "extern" "in" "out" "subint"))
(define %completion-component '("behavior" "provides" "requires" "system"))
(define %completion-behavior '("bool" "enum" "extern" "on" "subint" "void"))

(define (complete:type-names context)
  (let* ((types (context:type* context))
         (type-names (map (cute context:stripped-dotted-name <> context)
                          types)))
    (delete-duplicates
     (sort (cons* "bool" "void"
                  type-names)
           string<))))

(define* (complete:event-names o event-dir #:key (predicate identity))
  (let* ((events (context:event* (context:parent o 'interface)))
         (events (filter (conjoin
                          predicate
                          (compose (cute eq? event-dir <>) tree:direction .tree))
                         events)))
    (map (compose tree:dotted-name .tree) events)))

(define* (complete:interface-names context)
  (sort (delete-duplicates
         (map (cute context:stripped-dotted-name <> context)
              (context:interface* (context:parent context 'root))))
        string<))

(define (port-dir->event-dir port-dir dir)
  (cond ((and (eq? 'provides port-dir) (eq? 'trigger dir)) 'in)
        ((and (eq? 'provides port-dir) (eq? 'action dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'trigger dir)) 'out)
        ((and (eq? 'requires port-dir) (eq? 'action dir)) 'in)))

(define* (complete:port-event-names o   ;context
                                    dir ;'trigger or 'action
                                    #:key (event-predicate identity))
  (let* ((component (context:parent o 'component))
         (ports     (context:port* component)))
    (define (port->event-names port)
      (let* ((port-dir (tree:direction (.tree port)))
             (interface (.type port))
             (events (filter
                      (compose tree:dotted-name .tree)
                      (filter (conjoin event-predicate
                                       (compose (cute eq? (port-dir->event-dir port-dir dir) <>)
                                                tree:direction
                                                .tree))
                              (context:event* interface)))))
        (define (event->name event)
          (let* ((port (tree:dotted-name (.tree port)))
                 (formals (map tree:dotted-name (tree:formal* event)))
                 (formals (string-join formals ", "))
                 (event (tree:dotted-name event)))
            (format #f "~a.~a(~a)" port event formals)))
        (map (compose event->name .tree) events)))
    (append-map port->event-names ports)))

(define* (complete:trigger-names o #:key (event-predicate identity))
  (let* ((interface? (parent o 'interface))
         (on (parent o 'on))
         (statements (and on (tree:statement* on)))
         (triggers (and statements (tree:trigger* on)))
         (trigger (and (pair? triggers) (last triggers)))
         (trigger-complete? (and trigger
                                 (or (and interface? (.event-name trigger))
                                     (and (.port-name trigger)
                                          (.event-name trigger)))))
         (triggers (if interface?
                       (append '("inevitable" "optional")
                               (complete:event-names
                                o 'in #:predicate event-predicate))
                       (complete:port-event-names
                        o 'trigger #:event-predicate event-predicate))))
    (sort (append (if (and (null? statements) trigger-complete?) '("illegal")
                      '())
           triggers)
     string<)))

(define* (complete:action-names o #:key (event-predicate identity))
  (cond ((slot o 'component) (complete:port-event-names o 'action #:event-predicate event-predicate))
        ((slot o 'interface) (complete:event-names o 'out #:predicate event-predicate))
        (else '())))

(define* (complete:function-names o #:key (type-predicate identity))
  (let* ((functions (context:function* o))
         (functions (filter type-predicate functions)))
    (define (function->name f)
      (let* ((name (tree:dotted-name f))
             (formals (map (const "_") (tree:formal* f)))
             (formals (string-join formals ", ")))
        (format #f "~a(~a)" name formals)))
    (map (compose function->name .tree) functions)))

(define* (complete:enum-literal-names o #:key (context o))
  (assert-type (.tree o) 'enum)
  (let ((fields (tree:field* (.tree o))))
    (map (cute string-append (context:stripped-dotted-name o context) "." <>)
         (map tree:dotted-name fields))))

(define (complete:int-literal-names o)
  (assert-type o 'int)
  (let* ((range (.range o))
         (from (.from range)))
    (map number->string (iota (1+ (- (.to range) from)) from))))

(define (complete:field-test-names o name)
  (assert-type o 'enum)
  (let ((fields (tree:field* o)))
    (map (cute string-append (tree:dotted-name name) "." <>)
         (map tree:dotted-name fields))))

(define* (complete:type-literal-names o #:key (context o))
  (cond ((is-a? (.tree o) 'enum) (complete:enum-literal-names o #:context context))
        ;;((is-a? (.tree o) 'int) (context:int-value-names o))
        ((is-a? (.tree o) 'bool) '("false" "true"))
        (else '())))

(define (type-equal? o type)
  (assert-type o tree:type?)
  (assert-type type tree:type?)
  (tree:name-equal? (.name o) (.name type)))

(define (context:type-equal? o type)
  (assert-type type 'bool 'enum 'extern 'int 'void)
  (cond ((eq? type tree:extern)
         (is-a? (.tree (.type o)) 'extern))
        ((eq? type tree:int)
         (is-a? (.tree (.type o)) 'int))
        (else
         (type-equal? (.tree (.type o)) type))))

(define (complete:variable-names type context)
  (let* ((variables (append (context:locals context)
                            (context:members context)))
         (variables (if (not type) variables
                        (filter
                         (cute context:type-equal? <> type)
                         variables))))
    (map (compose tree:dotted-name .tree) variables)))


;;;
;;; Completion helpers.
;;;

(define* (complete:type context #:key (actions? #t) type)
  ;;(assert-type (.tree type) 'bool 'enum 'extern 'int)
  (let ((type (or type
                  (and (is-a? (.tree context) 'assign) (.type context))
                  (and (is-a? (.tree context) 'variable) (.type context))
                  (and=> (context:parent context 'var) .type)
                  (and=> (context:parent context 'variable) .type))))
    (if (not type) (complete:type-names context)
        (let* ((type-predicate (cute context:type-equal? <> (.tree type)))
               (actions   (if (not actions?) '()
                              (complete:action-names
                               context
                               #:event-predicate type-predicate)))
               (functions (complete:function-names
                           (context:parent context 'behavior)
                           #:type-predicate type-predicate))
               (literals  (complete:type-literal-names type #:context context))
               (variables (complete:variable-names (.tree type) context)))
          (sort (append actions
                        variables
                        functions
                        literals)
                string<)))))

(define (complete:enum-literal name context)
  (assert-type (.tree context) 'enum-literal)
  (let* ((field (.field (.tree context)))
         (enum  (.type context)))
    (cond
     ((not enum)
      (complete:type-names context))
     ((equal? field name)
      (complete:type-literal-names enum #:context context))
     ((and (not (parent context 'function))
           (not (parent context 'on)))
      (complete:type-literal-names enum #:context context))
     (else
      (complete:type context #:type enum)))))

(define (complete:literal o context)
  (assert-type o 'literal)
  (let* ((type (tree:type? o))
         (actions? (parent context 'variable)))
    (complete:type context
                   #:type (tree->context type context)
                   #:actions? actions?)))

(define (.type-of-on context)
  (let* ((triggers (context:trigger* context))
         (types (map .type triggers)))
    (find (negate (cute equal? <> context:void)) types)))

(define (complete:reply context)
  (assert-type context context?)
  (let* ((on   (context:parent context 'on))
         (type (and=> on .type-of-on)))
    (if (or (not type) (eq? type context:void)) '()
        (complete:type context #:type type #:actions? #f))))

(define (complete:return context)
  (assert-type context context?)
  (let* ((function (context:parent context 'function))
         (type (and=> function .type)))
    (if (or (not type) (eq? type context:void)) '()
        (complete:type context #:type type #:actions? #f))))

(define (complete:boolean-expression context)
  (sort (cons* "true" "false"
               (complete:variable-names #f context))
        string<))

(define (instance-ports-alist context)
  (define (instance-ports instance)
    (let ((component (.type instance)))
      (context:port* component)))
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

(define (complete:other-end-point o context)
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
        (system (context:parent context 'system)))
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

(define (complete:behavior context)
  (sort (append '("enum" "extern" "on" "subint")
                (complete:type-names context))
        string<))

(define (complete:component context offset)
  (let ((o (or (is-a? (.tree context) 'component)
               (parent context 'component))))
    (cond ((null? (tree:port* o))
           '("provides" "requires"))
          ((and (not (.behavior o))
                (not (.system o)))
           %completion-component)
          ((tree:after-location? (.behavior o) offset)
           '("provides" "requires"))
          ((tree:after-location? (.system o) offset)
           '("provides" "requires"))
          (else
           '()))))

(define (complete:statements context offset)
  (let* ((statements (tree:statement* (.tree context)))
         (illegal?   (and (null? statements)
                          (not (is-a? (.tree context) 'compound))
                          (not (parent context 'compound))))
         (before     (filter-map (cute tree:before-location? <> offset) statements))
         (before     (and (pair? before) (last before)))
         (else?      (and (is-a? before 'if-statement)
                          (.then before)
                          (not (.else before))))
         (statements (cond
                      ((parent context 'function)
                       '("return"))
                      ((or (and (is-a? (.tree context) 'on) context)
                           (context:parent context 'on))
                       =>
                       (lambda (on)
                         (let ((type (.type-of-on on)))
                           (if type '("reply(_)")
                               '()))))
                      (else
                       '())))
         (statements (if illegal? (cons "illegal" statements) statements))
         (statements (cons* "defer" "if" statements))
         (statements (if else? (cons "else" statements) statements))
         (actions    (complete:action-names context))
         (types      (complete:type-names context))
         (variables  (complete:variable-names #f context)))
    (sort (append actions statements types variables)
          string<)))

(define (complete:system context)
  (let* ((root       (context:parent context 'root))
         (component  (parent context 'component))
         (alist      (instance-ports-alist context))
         (bindings   (append-map instance-binding alist))
         (components (map (cute context:stripped-dotted-name <> context)
                          (context:component* root)))
         (instances  (map tree:dotted-name (tree:instance* (.tree context))))
         (ports      (map tree:dotted-name (tree:port* component))))
    (sort
     (delete-duplicates (append bindings components instances ports))
     string<)))

(define (annotate-dir file-name)
  (if (or (not (directory-exists? file-name))
          (string-suffix? file-name "/"))
      file-name
      (string-append file-name "/")))

(define (dzn-file? file-name)
  (and (string? file-name)
       (not (directory-exists? file-name))
       (string-suffix? ".dzn" file-name)))

(define* (list-dir dir #:key (prefix dir))
  (let ((dir (annotate-dir dir))
        (prefix (annotate-dir prefix)))
    (map (compose (cute strip-prefix prefix <>) annotate-dir)
         (list-directory dir
                         (disjoin
                          dzn-file?
                          (conjoin (negate (cute member <> '("." "..")))
                                   (compose
                                    directory-exists?
                                    (cute string-append dir "/" <>))))))))

(define (strip-prefix prefix string)
           (if (and (string? string) (string-prefix? prefix string))
               (substring string (string-length prefix))
               string))

(define* (complete:imports o context #:key (imports '()))
  (let* ((file-name (.file-name o))
         (root (parent context 'root))
         (root-file (.file-name root))
         (dir (dirname root-file))
         (full-name (string-append (annotate-dir dir) file-name))
         (path (cons dir imports))
         (found (search-path path file-name))
         (found-dir (or (and full-name (directory-exists? full-name))
                        (and found (directory-exists? found))
                        (and (directory-exists? (dirname full-name)))))
         (found-dir (and (not (equal? found-dir ".")) found-dir)))
    (if found-dir (list-dir found-dir #:prefix dir)
        (sort (delete-duplicates
               (append-map list-dir path))
              string<))))

(define (filter-self context list)
  (let* ((variable (or (is-a? (.tree context) 'formal)
                       (is-a? (.tree context) 'variable)
                       (parent context 'formal)
                       (parent context 'variable)))
         (name (and=> variable tree:dotted-name)))
    (filter (negate (cute equal? <> name)) list)))

(define* (complete:root o context offset #:key debug? (imports '()))
  (when debug?
    (format (current-error-port) "tree:~a\n" o))
  (match o
    ('types-and-events
     '("in" "out" "enum" "extern" "subint"))
    ((? symbol?)
     '())
    ;; parse-tree damage: move up
    ((or #f (? (negate tree?)))
     (let ((context (and (pair? context)
                         (drop-while (negate tree?) (cdr context)))))
       (cond ((context? context)
              (complete:root (.tree context) context offset #:debug? debug?))
             (else
              '()))))
    ((? (is? 'root))
     %completion-top)
    ((? (is? 'file-name))
     (complete:root (.tree (.parent context)) (.parent context) offset))
    ((? (is? 'import))
     (complete:imports o context #:imports imports))
    ((and (? (is? 'interface))
          (? complete?))
     (cond ((not (.behavior o))
            %completion-interface)
           ((tree:after-location? (.behavior o) offset)
            '("in" "out" "enum" "extern" "subint"))
           (else '())))
    ((and (? (is? 'component))
          (? complete?))
     (complete:component context offset))
    ((or (? (is? 'port-qualifiers))
         (? (is? 'provides))
         (? (is? 'requires)))
     (let ((context (context:parent context 'port)))
       (complete:root (.tree context) context offset)))
    ((? (is? 'port))
     (cond ((and (not (slot o 'provides))
                 (not (slot o 'requires)))
            '("provides" "requires"))
           ((slot o 'provides)
            (complete:interface-names (context:parent context 'component)))
           (else
            (let* ((qualifiers (tree:port-qualifier* o))
                   (blocking? (find (is? 'blocking-q) qualifiers))
                   (external? (find (is? 'external) qualifiers))
                   (injected? (find (is? 'injected) qualifiers)))
              (append (if blocking? '() '("blocking"))
                      (if external? '() '("external"))
                      (if injected? '() '("injected"))
                      (complete:interface-names (context:parent context 'component)))))))
    ((? (is? 'types-and-events))
     (let* ((interface (parent context 'interface))
            (name (and=> interface .name)))
       (cond ((or (not name)
                  (incomplete? name))
              '())
             ((null? (tree:event* o))
              '("in" "out" "enum" "extern" "subint"))
             (else
              %completion-interface))))
    ((and (? (is? 'event)) (? incomplete?))
     (let ((direction (.direction o))
           (type-name (.type-name o))
           (type (.type context))
           (name (.name o)))
       (cond ((and direction (or (not type) (not name)))
              (complete:type-names context))
             (else
              '()))))
    ((and (? (is? 'direction)) (? complete?))
     (complete:root (.tree (.parent context)) (.parent context) offset #:debug? debug?))
    ('type-name
     (complete:type-names context))
    ((? (is? 'type-name))
     (complete:type-names context))
    ((and (? (is? 'ports)) (? complete?))
     (complete:component context offset))
    ((or 'body
         (? (is? 'ports)))
     ;;%completion-component
     (complete:component context offset))
    ('behavior
     %completion-interface)
    ('behaviour
     %completion-interface)
    ((? (is? 'behavior-statements))
     (match context
       ((o ('BRACE-OPEN b ...) t ...)
        '())
       (_
        (complete:behavior context))))
    ((? (is? 'behavior-compound))
     (cond ((tree:after-location? o offset)
            '("provides" "requires"))
           ((tree:before-location? o offset)
            '())
           (else
            (complete:behavior context))))
    ((? (is? 'system))
     (complete:system context))
    ((? (is? 'instances-and-bindings))
     (complete:system context))
    ((and (? (is? 'binding)) (? incomplete?))
     (let ((left (.left o))
           (right (.right o)))
       (cond ((and left (not right))
              (complete:other-end-point left context))
             ((and left (.port-name left) (not (.instance-name left)))
              (complete:other-end-point left context))
             (else
              '()))))
    ((? (is? 'binding))
     (let ((left (.left o))
           (right (.right o)))
       (cond ((and left (.port-name left)
                   right (.port-name right)
                   (not (.instance-name left))
                   (not (.instance-name right)))
              (complete:other-end-point left context))
             (else
              '()))))
    ((? (is? 'end-point))
     (complete:root (.tree (.parent context)) (.parent context) offset #:debug? debug?))
    ((? (is? 'dollars))
     (filter-self context (complete:type context)))
    ((? (is? 'literal))
     (cond ((is-a? (tree:type? o) 'bool)
            (filter-self context (complete:literal o context)))
           ((is-a? (tree:type? o) 'int)
            (filter-self context (complete:literal o context)))
           (else
            '())))
    ((? (is? 'enum-literal))
     (complete:enum-literal o context))
    ((and (? (is? 'name)) (? complete?))
     (cond ((context:parent context 'enum-literal)
            => (compose (cute filter-self context <>)
                        (cute complete:enum-literal o <>)))
           ((parent context 'reply)
            (complete:reply context))
           ((parent context 'return)
            (complete:return context))
           (else
            (complete:root (.tree (.parent context)) (.parent context) offset
                           #:debug? debug?))))
    ((and (? (is? 'compound-name)) (? complete?))
     (complete:root (.tree (.parent context)) (.parent context) offset
                    #:debug? debug?))
    ((and (? (is? 'scope) (? complete?)))
     (complete:root (.tree (.parent context)) (.parent context) offset
                    #:debug? debug?))
    ((and (? (is? 'reply)) (? (negate .expression)))
     (complete:reply context))
    ((and (? (is? 'return)) (? (negate .expression)))
     (complete:return context))
    ((? (is? 'var))
     (cond ((let* ((variable (.variable context))
                   (type (and=> variable .type))
                   (enum (and=> type .tree)))
              (is-a? enum 'enum))
            => (cute complete:field-test-names <> (.name o)))
           ((let* ((variable (.variable context))
                   (type (and=> variable .type)))
              (context? type))
            (filter-self context (complete:type context)))
           (else
            '())))
    ((and (? (is? 'formal)) (? incomplete?))
     (let ((type-name (.type-name o))
           (type (.type context))
           (name (.name o)))
       (cond ((or (not type) (not name))
              (complete:type-names context))
             (else
              '()))))
    ((? (is? 'arguments))
     (cond ((and (parent context 'component)
                 (context:parent context 'action))
            =>
            (lambda (action)
              (let ((type context:extern))
                (complete:type context #:type type))))
           ((context:parent context 'call)
            =>
            (lambda (call)
              (let ((function (.function call)))
                (if (not function) '()
                    (let ((arguments (tree:argument* (.tree call)))
                          (formals (tree:formal* (.tree function))))
                      (if (< (length formals) (length arguments)) '()
                          (let* ((formal (list-ref formals (length arguments)))
                                 (type (.type (cons formal function))))
                            (complete:type context #:type type))))))))
           (else
            '())))
    ((? (is? 'field-test))
     (cond ((let* ((var (.var o))
                   (variable (.variable (cons var context)))
                   (type (and=> variable .type)))
              (and (is-a? (.tree variable) 'variable)
                   (is-a? (.tree type) 'enum)
                   variable))
            =>
            (lambda (variable)
              (let* ((enum (.type variable))
                     (var (.var o))
                     (name (.name var)))
                (complete:field-test-names (.tree enum) name))))
           ((context:parent context 'variable)
            =>
            (lambda (context)
              (complete:root (.tree context) context offset #:debug? debug?)))
           (else
            (complete:boolean-expression context))))
    ((? (is? 'triggers))
     (complete:trigger-names context))
    ((? (is? 'trigger))
     (complete:trigger-names context))
    ((? (is? 'on))
     (cond ((null? (tree:trigger* o))
            (complete:trigger-names context))
           ((.statement o)
            =>
            (lambda (statement)
              (if (complete? statement) (complete:statements context offset)
                  (complete:root statement (tree->context statement context) offset #:debug? debug?))))
           (else
            (complete:statements context offset))))
    ((? (is? 'if-statement))
     (cond ((is-a? (.then o) 'skip-statement)
            (complete:statements context offset))
           (else
            '())))
    ((and (? (is? 'variable)) (? incomplete?))
     (let* ((type (.type context))
            (expression (false-if-exception (.expression o)))
            (expression (and expression (.value expression))))
       (cond ((not type)
              (complete:type-names context))
             (type
              (filter-self context (complete:type context)))
             (else
              '()))))
    ((? (is? 'assign))
     (filter-self context (complete:type context)))
    ((? (is? 'variable))
     (filter-self context (complete:type context)))
    ((? (is? 'guard))
     (cond ((incomplete? o) (complete:root (.expression o) (cons (.expression o) context) offset
                                           #:debug? debug?))
           ((not (parent context 'on)) (complete:behavior context))
           (else '())))
    (('expression 'PAREN-CLOSE x ...)
     (cond ((parent context 'if-statement)
            (complete:boolean-expression context))
           (else
            '())))
    ((and (? (is? 'expression)) (? incomplete?))
     (let ((value (.value o)))
       (cond ((complete? value)
              (complete:root (.value o) (cons (.value o) context) offset #:debug? debug?))
             (else
              '()))))
    ((? (is? 'expression))
     (let ((parent (or (is-a? (and=> (.parent context) .tree) 'if-statement)
                       (is-a? (and=> (.parent context) .tree) 'guard))))
       (cond ((and parent
                   (tree:after-location? parent offset))
              '())
             ((and parent
                   (tree:before-location? parent offset))
              '())
             (parent
              (complete:boolean-expression context))
             (else
              '()))))
    (('or 'otherwise 'expression)
     (sort (cons "otherwise" (complete:boolean-expression context)) string<))
    ((? (is? 'statement))
     (cond ((parent context 'on) (complete:statements context offset))
           ((parent context 'function) (complete:statements context offset))
           (else (complete:behavior context))))
    ((and (? (is? 'compound)) (? incomplete?))
     (cond ((parent context 'on) (complete:statements context offset))
           ((parent context 'function) (complete:statements context offset))
           (else (complete:behavior context))))
    ((? (is? 'compound))
     (cond ((or (and=> (parent context 'on)
                       (cute tree:after-location? <> offset))
                (and=> (parent context 'on)
                       (cute tree:before-location? <> offset)))
            (complete:behavior context))
           ((and=> (parent context 'behavior)
                   (cute tree:before-location? <> offset))
            '(""))
           ((parent context 'on) (complete:statements context offset))
           ((parent context 'function) (complete:statements context offset))
           (else (complete:behavior context))))
    ((? (is? 'action))
     (cond ((and=> (parent context 'behavior)
                   (cute tree:before-location? <> offset))
            '())
           ((or (and=> (parent context 'on)
                       (cute tree:after-location? <> offset))
                (and=> (parent context 'on)
                       (cute tree:before-location? <> offset)))
            (complete:behavior context))
           ((or (context:parent context 'assign))
            => (lambda (context)
                 (complete:root (.tree context) context offset #:debug? debug?)))
           ((or (context:parent context 'variable))
            => (lambda (context)
                 (complete:root (.tree context) context offset #:debug? debug?)))
           ((or (context:parent context 'compound)
                (context:parent context 'on))
            => (cute complete:statements <> offset))
           ((or (context:parent context 'behavior-statements)
                (context:parent context 'behavior-compound))
            => complete:behavior)
           (else
            '())))
    ((? (is? 'comment))
     (complete:root (parent context tree?)
                    (context:parent context tree?) offset #:debug? debug?))
    ((? (is? 'unknown-identifier))
     (complete:root (parent context tree?)
                    (context:parent context tree?) offset #:debug? debug?))
    ((and (? complete?) (? (negate (is? 'comment))))
     '())
    ((and (? (is? 'or)) (? incomplete?))
     (cond ((context:parent context 'on)
            => complete:trigger-names)))
    (_
     (or (and (pair? o)
              (and=> (find incomplete? (cdr o))
                     (cut complete:root <> context offset #:debug? debug?)))
         (complete:root (tree:before-location? o offset) context offset
                        #:debug? debug?)))))


;;;
;;; Entry points.
;;;

(define (complete:context o at)
  (let ((narrow (conjoin incomplete? (negate symbol?) (negate tree:location?)))
        (context (reverse (tree:collect o (cute tree:at-location-incomplete? <> at)))))
    (if (null? context) `(,o)
        (let ((narrow (find narrow (cdar context))))
          (if narrow (cons narrow context)
              context)))))

(define* (complete o context offset #:key
                   debug?
                   (file-name->parse-tree (const '()))
                   (imports '())
                   (resolve-file (lambda args (car args))))
  (parameterize ((%file-name->parse-tree file-name->parse-tree)
                 (%resolve-file resolve-file))
    (complete:root o context offset #:debug? debug? #:imports imports)))
