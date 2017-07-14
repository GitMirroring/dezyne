;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;; Copyright © 2015 Jan Nieuwenhuizen <jan@avatar.nl>
;; Copyright © 2014, 2015, 2016, 2017 Paul Hoogendijk <paul.hoogendijk@verum.com>
;; Copyright © 2014, 2015, 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gaiag csp)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (gaiag animate)
  #:use-module (gaiag asserts)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag command-line)
;;  #:use-module (gaiag mangle)
  #:use-module (gaiag misc)
  #:use-module (gaiag norm)
  #:use-module (gaiag norm-state)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)
;; #:use-module (gaiag wfc)


  #:export (
           ast->
           behaviour->csp
           csp:import
           csp-comma-list
           csp-component
           ast-transform
           on->csp
           csp:norm
           csp-queue-size
           ast->csp
           om->csp
           csp:ast->om
           demangle
           csp-asserts

           animate-pairs
           assign
           provides?
           requires?
           string-if
           dzn-async?

           <skip>
           <the-end>
           <the-end-blocking>
           <voidreply>
           ))

(define-class <skip> (<ast>))
(define-class <the-end> (<ast>))
(define-class <the-end-blocking> (<ast>))
(define-class <voidreply> (<ast>))

(define* (om->csp om #:key file-name (separate-asserts? (command-line:get 'assert #f)))
  (ast:set-scope om
    (or (and-let* ((models (om:filter (lambda (x) (or (as x <interface>) (as x <component>))) om))
                   (models (null-is-#f (filter .behaviour models)))
                   (c-i (append (filter (is? <component>) models) models))
                   ((pair? c-i))
                   (model (car c-i))
                   (name ((om:scope-name '.) model))
                   (file-name (or file-name (command-line:get 'output (list name '.csp)))))
          (generate-csp model #:file-name file-name #:separate-asserts? separate-asserts?))
        (let* ((models (om:filter (is? <model>) om))
               (models (comma-join (map .name models)))
               (message "gaiag: no model with behaviour\n"))
          (stderr message)
          (throw 'csp message)))))

(define (csp:ast->om ast)
  ((om:register csp:norm #t) ast))

(define* (ast->csp ast #:key file-name (separate-asserts? (command-line:get 'assert #f)))
  (om->csp (csp:ast->om ast) #:file-name file-name #:separate-asserts? separate-asserts?))

(define (ast-> ast)
  (ast->csp ast)
  "")

(define* (generate-csp o #:key (file-name "-") (separate-asserts? (command-line:get 'assert #f)))
  (match o
    (($ <interface>)
     (and-let* ((root (make <root> #:elements (list o))))
       (ast:set-scope root (model-generate-csp root o #:file-name file-name #:separate-asserts? separate-asserts?))))
    (($ <component>)
     (and-let* ((root (make <root> #:elements (list o)))
                (interfaces (map .type ((compose .elements .ports) o)))
                (root (make <root> #:elements (append interfaces (list o)))))
       (and-let* ((no-behaviour (null-is-#f (filter (negate .behaviour) interfaces)))
                  (message (format #f "gaiag: interface without behaviour: ~a\n"
                                   (comma-join (map .name no-behaviour)))))
         (stderr message)
         (throw 'csp message))
       (ast:set-scope root (model-generate-csp root o #:file-name file-name #:separate-asserts? separate-asserts?))))))

(define* (model-generate-csp root model #:key (file-name "-") (separate-asserts? (command-line:get 'assert #f)))
  (dump-output file-name (lambda ()
                           (csp-file 'combinators.csp.scm (csp:module model))
                           (csp-model model)
                           (if separate-asserts?
                               (if (equal? file-name "-") ""
                                   (animate-string "\ninclude \"asserts.csp\"\n"))
                               (csp-asserts model))
                           (if (command-line:get 'lts #f)
                               (let ((models (append (interfaces model) (list model))))
                                 (map csp-lts models)
                                 (assembly-lts model)))))
  (if (and separate-asserts? (not (equal? file-name "-")))
      (dump-output "asserts.csp" (lambda () (csp-asserts model)))))

(define (csp:import name)
  (om:import name csp:norm))

(define (csp:norm ast)
  ((compose-root
    csp-norm-state
    internal-libs
    ast:resolve
    ast->om
    ) ast))

(define ((demangle-var model) var)
  (or (and-let* (((member (.name model) '(co_mangle co_argument2 if_I)))
                 (svar (symbol->string var))
                 ((string-prefix? "va_" svar)))
                (string->symbol (string-drop svar 3)))
      var))

(define (interfaces o)
  (match o
    (($ <interface>) '())
    (($ <component>)
     (delete-duplicates (map .type ((compose .elements .ports) o)) om:scope.name-equal?))))

(define (assembly-lts o)
  (match o
    (($ <interface>) *unspecified*)
    (($ <component>)
     (csp-file 'assembly-lts.csp.scm (csp:module o)))))

(define (csp-lts o)
  (match o
    (($ <interface>)
     (csp-file 'interface-lts.csp.scm (csp:module o)))
    (($ <component>)
     (csp-file 'component-lts.csp.scm (csp:module o)))))

(define (csp-model o)
  (match o
    (($ <interface>)
     (csp-file 'both.csp.scm (csp:module o))
     (csp-file 'interface.csp.scm (csp:module o)))
    (($ <component>)
     (for-each csp-model (interfaces o))
     (csp-file 'both.csp.scm (csp:module o))
     (csp-file 'component.csp.scm (csp:module o)))))

(define (csp-asserts o)
  (match o
    (($ <interface>)
     (for-each (csp-assert o) (assert-list o)))
    (($ <component>)
     (for-each csp-asserts (interfaces o))
     (for-each (csp-assert o) (assert-list o)))))

(define (csp-assert o)
  (lambda (assert)
    (let* ((class (car assert))
           (model (cadr assert))
           (check (caddr assert))
           (template (assoc-ref asserts-alist (list class check))))
      (animate-string template (csp:module o)))))

(define asserts-alist
  `(
    ((component illegal) . "assert STOP [T= AS_#.scope_model _(false) \\ diff(Events,{illegal,queue_full})\n")
    ((component deterministic) . "assert CO_#.scope_model _(true,true) :[deterministic [F]]\n")
    ((component deadlock)  . "assert AS_#.scope_model _(false) :[deadlock free [F]]\n")
    ((component compliance) . ,(gulp-template 'asserts/component-compliance.csp.scm))
    ((component livelock)  .  "assert AS_#.scope_model _(true) \\ diff(Events,{|#(comma-join (append (required-modeling-triggers model) (list \"illegal\") (append-map (lambda (port) (map (cut symbol-append (.name port) <>) (map string->symbol (if (not (null? (filter om:out? (om:events port)))) (list \"\" \"_'\" \"_''\") (list \"\" \"_'\"))))) (om:provided model))))|}) :[livelock free]\n")
    ((interface completeness) . ,(gulp-template 'asserts/interface-completeness.csp.scm))
    ((interface deadlock) . ,(gulp-template 'asserts/interface-deadlock.csp.scm))
    ((interface livelock) . ,(gulp-template 'asserts/interface-livelock.csp.scm))))

(define (csp:module o)
  (let ((module (make-module 31 (list
                                 (resolve-module '(gaiag csp))
                                 (resolve-module '(oop goops))
                                 (resolve-module '(gaiag resolve))
                                 (resolve-module '(gaiag goops))
                                 (resolve-module '(gaiag compare))
                                 (resolve-module '(gaiag util))))))
    (module-define! module 'model o)
    (module-define! module '.model (om:name o))
    (module-define! module '.scope_model ((om:scope-name) o))
    module))

(define (csp-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) '(templates csp))))
    (animate-file file-name module)))

(define (valued? model o)
  (om:typed? model (car ((compose .elements .triggers) o))))

(define (unspecified? x) (eq? x *unspecified*))

(define (guards->trigger-to-guards-alist guards)
  "collect alist of ((trigger . (guards))), e.g.
   (((<trigger> port1 event1) . ((<guard1> expr1) (<guard2> expr2)))
    ((<trigger> port2 event2) . ((<guard1> expr1) (<guard3> expr3)))
    ...)
   - the statement of the guard is discarded
   - the arguments on the trigger are discarded, only port-name event-name"
   (let loop ((guards guards) (alist '()))
    (if (null? guards) alist
        (let* ((guard (car guards))
               (statement (.statement guard))
               (guard (make <guard> #:expression (.expression guard)))
               (ons (match statement
                      (($ <on>) (list statement))
                      (($ <compound> (statements ...)) statements)))
               (triggers (append-map (compose .elements .triggers) ons))
               (triggers (map om:remove-formals triggers))
               (triggers (delete-duplicates triggers)))
          (loop (cdr guards)
                (let loop2 ((triggers triggers) (alist alist))
                  (if (null? triggers) alist
                      (let* ((trigger (car triggers))
                             (entry (or (assoc-ref alist (om2list trigger)) '())))
                        (loop2 (cdr triggers)
                               (assoc-set! alist
                                           (om2list trigger) (cons guard entry)))))))))))

(define (dump-me x)
  (let ((foo (stderr "dump me: ~a\n" x)))
    x))

(define (behaviour->csp model)

  (define (list-of-ons statement)
    (if (is-a? statement <on>) (list statement)
        (om:filter (is? <on>) statement)))

  (define (guard->csp guard)
    (let* ((expression (csp-expression->string model (.expression guard) '()))
           (ons (list-of-ons (.statement guard))))
      (list
       "(" expression ") & (\n"
       (or (null-is-#f
            ((->list-join "\n []\n  ")
             (map (lambda (on) (on->csp model (ast-transform model on))) ons)))
           "STOP")
       ")")))

  (define (list-of-triggers-port ports predicate)
    (append-map (lambda (port) (map (lambda (event) (make <trigger> #:port (.name port) #:event event)) (filter predicate (om:events port)))) ports))

  (define (list-of-triggers-provides model)
    (list-of-triggers-port (filter om:provides? (om:ports model)) om:in?))

  (define (list-of-triggers-requires model)
    (list-of-triggers-port (filter om:requires? (om:ports model)) om:out?))

  (define (not-ored-guards guards)
;    (stderr "not-ored-guards ~a\n" guards)
    (let* ((guards (if guards guards (list)))
           (expressions (map (lambda (guard) (csp-expression->string model (.expression guard) '())) guards)))
      (if (null? expressions)
          (list "true")
          (list "not ((" ((->list-join ") or (") expressions) "))"))))

  (define (channel-suffix model port)

     (if (equal? (.direction (car (filter (lambda (p) (equal? (.name p) port)) (.elements (.ports model))))) 'provides)
         (list "")
         (list "_''")))

  (let* ((default "STOP")
         (guards (let ((statement ((compose .statement .behaviour) model)))
                   (if (is-a? statement <guard>)
                       (list statement)
                       (om:filter (is? <guard>) statement))))
         (trigger-to-guards-alist (guards->trigger-to-guards-alist guards)))
    (or (null-is-#f
         ((->list-join "\n[]\n")
          (append
           (map guard->csp guards)
           (let ((statement ((compose .statement .behaviour) model)))
             (if (is-a? model <interface>)
                 (list)
                 (append
                  (map (lambda (t) (list "(" (not-ored-guards (assoc-ref trigger-to-guards-alist (om2list t))) ") & ill." (.port.name t) (channel-suffix model (.port.name t)) "?" (.event.name t) "-> illegal -> STOP"))
                       (list-of-triggers-provides model))
                  (map (lambda (t) (list "IG & (" (not-ored-guards (assoc-ref trigger-to-guards-alist (om2list t))) ") & " (.port.name t) (channel-suffix model (.port.name t)) "?" (.event.name t) "-> illegal -> STOP"))
                      (list-of-triggers-requires model))))))))
        "STOP")))

(define (behaviour-component->csp model)
  (let* ((behaviour (behaviour->csp model))
         (lets (collect-def behaviour))
         (inside #f))
    (list
     (if (not inside)
         (if (pair? lets)
             (list
              ((->join "\n") lets))))
         (list ((om:scope-name) model) "_(" (comma-space-join (om:member-names model)) ")" " =\n")
     (if inside
         (if (pair? lets)
             (list
              "let\n"
              ((->join "\n") lets)
              "within\n")))
     "(\n"
     (check-range (om:member-names model) behaviour model)
     ")")))

(define (behaviour-interface->csp model)
  (let* ((behaviour (behaviour->csp model))
         (lets (collect-def behaviour))
         (inside #f))
    (list
     (if (not inside)
         (if (pair? lets)
             (list
              ((->join "\n") lets))))
     (list ((om:scope-name) model) "_(" (comma-space-join (om:member-names model))")" " =\n")
     (if inside
         (if (pair? lets)
             (list
              "let\n"
              ((->join "\n") lets)
              "within\n")))
     "("
     (check-range (om:member-names model) behaviour model)
     "\n[]\n"
     (list "cs_" ((om:scope-name) model) "." ((om:scope-name) model) "_'''?x:{|" (comma-join (delete-duplicates (map .event.name (modeling-triggers model)))) "|} -> illegal -> STOP\n")
     ")")))

(define (csp-expression->string model o locals)
  (define (member? identifier) (om:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (define (paren expression)
    (let ((value (if (is-a? expression <value>) (.value expression) expression)))
      (if (or (number? value) (symbol? value) (as value <var>))
          (csp-expression->string model expression locals)
          (list "(" (csp-expression->string model expression locals) ")"))))

  (let* ((model-name ((om:scope-name) model))
         (model- (symbol-append model-name '_)))
    (match o
      ((and ($ <var>) (= .variable.name identifier))
       (list (->string identifier)))
      (($ <value>) (csp-expression->string model (.value o) locals))
      ((or (? number?) (? string?) (? symbol?)) (list o))
      (($ <field> variable field)
       (let* ((type (.type variable))
              (name (om:name type)))
         (list "("
               (.name variable) " == " name "_" field ")")))
      ((and ($ <literal>) (= .type type) (= .field field))
       ((->symbol-join '_) `(,(.name (.name type)) ,field)))
      (($ <group> expression) (list "(" (csp-expression->string model expression locals) ")"))
      (($ <not> expression) (->string (list "(" "not " (paren expression) ")")))
      ((and (or ($ <and>) ($ <or>)) (= .left left) (= .right right))
       (let ((left (csp-expression->string model left locals))
             (right (csp-expression->string model right locals))
             (op (ast-name (class-of o))))
         (list "(" left " " op " " right ")")))
      ((? (is? <binary>))
       (let ((lhs (csp-expression->string model (.left o) locals))
             (rhs (csp-expression->string model (.right o) locals))
             (op (.operator o)))
         (list "(" lhs " " op " " rhs ")")))
      (($ <data> value) (list "false"))
      (*unspecified* #f)
      (_ (throw 'match-error (format #f "~a:no match: ~a" (current-source-location) o))))))

(define* (port-events port #:optional (predicate? identity)) ;; FIXME: no test
  (let ((interface (.type port)))
    (interface-events interface predicate?)))

(define (interface-events o predicate?) ;; FIXME: no test
  (match o
    (($ <interface>)
     (let* ((events ((compose .elements .events) o))
            (events (filter predicate? events))
            (events (map .name events)))
       (delete-duplicates (sort (append events) symbol<))))
    (($ <component>)
     (apply append (map (compose (lambda (x) (interface-events x predicate?)) .type) ((compose .elements .ports) o))))))

(define (om:member-names model)
  (map .name (filter (lambda (x) (not (is-a? (.type x) <extern>))) (om:variables model))))

(define (om:member-types model)
  (map (om:type model) (filter (lambda (x) (not (is-a? (.type x) <extern>))) (om:variables model))))

(define (om:member-values model)
  (map (compose (cut csp-expression->string model <> '()) .expression) (filter (lambda (x) (not (is-a? (.type x) <extern>))) (om:variables model))))

(define (modeling-triggers o)
  (filter om:modeling? (om:find-triggers o)))

(define (required-modeling-triggers o)
  (apply append
         (map (lambda (port)
                (map (lambda (trigger)
                       (->string (list (.name port) '_'''. (.event.name trigger))))
                     (modeling-triggers (.type port))))
              (filter (compose not dzn-async? .name .type) (filter om:requires? (om:ports o))))))

(define (async-reqackclrmods o)
  (map (lambda (port) (list "("  (.name port) "." (.name (car (.elements (.events (.type port))))) ","
                            (.name port) "_''" "." (.name (cadr (.elements (.events (.type port))))) ","
                            (.name port) "." (.name (caddr (.elements (.events (.type port))))) ","
                            (.name port) "_'''" "." "inevitable.false" ")"))
       (filter (compose dzn-async? .name .type) (filter om:requires? (om:ports o)))))

(define (async-reqclrs o)
  (append-map (lambda (port) (list
                              (list (.name port) "." (.name (car (.elements (.events (.type port))))))
                              (list (.name port) "." (.name (caddr (.elements (.events (.type port))))))))
              (filter (compose dzn-async? .name .type) (filter om:requires? (om:ports o)))))

(define (typed-elements o)
  (match o
    (($ <bool>)
     (list 'bool.false 'bool.true))
    (($ <int> name ($ <range> from to))
     (map (lambda (i) (symbol-append 'int. (number->symbol i))) (iota (1+ (- to from)) from)))
    (($ <enum> name fields)
     (map (lambda (x)
            ((->symbol-join '_) (append (cons (om:name o) (list x))))) (.elements fields)))
    (_ 'barf)
    ))

(define (type-values o)
  (match o
    (($ <interface>)
      (apply append (map typed-elements (types o))))
    (($ <component>)
      (apply append (map typed-elements (types o))))
    (($ <component>)
     (delete-duplicates
      (append
       (apply append (map (compose type-values .type) ((compose .elements .ports) o)))
       (apply append (map typed-elements (types o))))))))

(define (types o)
  (filter
   (negate (is? <extern>))
   (match o
     (($ <interface>) (append (om:types o) (om:types)))
     (($ <component>)
      (append
       (apply append
              (map types
                   (map .type ((compose .elements .ports) o))))
       (append (om:types o) (om:types)))))))

(define (return-values-port port) ;; FIMXE: no test
  (let ((interface (.type port)))
    (return-values interface)))

(define (return-values o) ;; FIMXE: no test
  (match o
    (($ <interface>)
     (add-return-if-empty (map (return-value o) (om:reply-types o))))
    (($ <component>)
     (apply append (map (compose return-values .type) ((compose .elements .ports) o))))))

(define ((return-value model) o)
  (match o
    (($ <bool>) (list 'bool.false 'bool.true))
    ((and ($ <enum>) (= .fields fields))
     (map (lambda (field) (symbol-append ((om:scope-join model) (om:scope+name o)) '_ field)) (.elements fields)))
    (($ <int> name ($ <range> from to))
     (map (lambda (i) (symbol-append 'int. (number->symbol i))) (iota (1+ (- to from)) from)))))

(define (add-return-if-empty returns)
  (if (null? returns)
      '(return)
      (append (apply append returns) (list 'return)))) ;; FIXME: add only return when needed

(define ((statement-on-p/r predicate) o)
  (let* ((triggers (.elements (.triggers o)))
         (filtered-triggers (filter predicate triggers))
         (statement (.statement o)))
    (if (pair? filtered-triggers)
        (make <on> #:triggers (make <triggers> #:elements filtered-triggers)
              #:statement statement)
        #f)))

(define (prefix-illegal? statement)
  (match statement
    (($ <compound> (statements ...))
     (let loop ((statements statements))
       (if (null? statements)
           #f
           (or (prefix-illegal? (car statements)) (loop (cdr statements))))))
    (($ <blocking> statement) (prefix-illegal? statement))
    (($ <illegal>) #t)
    (_ #f)))

(define (((provides-or-requires? direction) component) trigger)
  (if (is-a? component <component>)
      (pair?
       (filter
	(lambda (port)
          (and (equal? (.direction port) direction)
               (equal? (.port.name trigger) (.name port))))
	(.elements (.ports component))))
      #f))

(define ((provides? component) trigger)
  (((provides-or-requires? 'provides) component) trigger))

(define ((requires? component) trigger)
  (((provides-or-requires? 'requires) component) trigger))

(define ((provides-trigger? model) trigger)
  (and (is-a? model <component>)
       ((provides? model) trigger)))

(define ((requires-trigger? model) trigger)
  (and (is-a? model <component>)
       ((requires? model) trigger)))

(define (hide-modeling model)
  (and-let* (((is-a? model <interface>))
             (name (.name model))
             (modeling (null-is-#f (delete-duplicates (map .event.name (modeling-triggers model))))))
            (string-append " \\ {|"
                           (comma-join
                            (append (map (lambda (x) (->string (list name "." x)))
                                 modeling) (list (->string (list name "_'''")))))
                           "|} ")))

(define (optional-chaos o) ;; FIXME: no test
  (let ((name ((om:scope-name) o)))
    (if (member 'optional (map .event.name (om:find-triggers o)))
        (list " [|{|" name "_'''.optional|}|] " "CHAOS({|" name "_'''.optional|})")
        "")))

(define (ast-transform ast src)
  (ast-transform-return ast (purge-data ast (tail-call src))))

(define (purge-data root o)
  (let ((model (or (om:component root) (om:interface root))))
    (ast:set-model-scope model (model-purge-data model o))))

(define* (model-purge-data model o #:optional (locals '()))
  (define (member? identifier) (om:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (extern-type? type) (om:extern model type))
  (define (extern? variable) (extern-type? (.type variable)))
  (define (purge-formal-list function arguments)
    (let ((types (map .type ((compose .elements .formals .signature) function))))
      (let loop ((arguments arguments) (types types))
        (if (null? arguments)
                arguments
                (append
                 (if (extern-type? (car types))
                     '()
                     (list (car arguments)))
                 (loop (cdr arguments) (cdr types)))))))

  (match o

    (($ <compound> (statements ...))
     (clone o
       #:elements
       (let loop ((statements statements) (locals locals))
         (if (null? statements)
             '()
             (let* ((statement (car statements))
                    (locals (match statement
                              (($ <variable> name type expression)
                               (acons name statement locals))
                              (_ locals))))
               (let ((purged (model-purge-data model statement locals)))
                 (cons purged (loop (cdr statements) locals))))))))

    (($ <call> function-name ($ <arguments> (arguments ...)) last?)
     (clone o #:arguments (make <arguments> #:elements (purge-formal-list (.function o) arguments))))

    (($ <on> triggers statement)
     (let* ((t (filter (negate om:modeling?) (.elements triggers)))
            (events (map .event t))
            (formals (apply append (map (compose .elements .formals .signature) events)))
            (on-formals (apply append (map (compose .elements .formals) t)))
            (on-formals (if (pair? on-formals)
                            (map .name on-formals)
                            (map .name formals)))
            (locals (let loop ((formals formals)
                               (on-formals on-formals)
                               (locals locals))
                      (if (null? formals)
                          locals
                          (loop (cdr formals)
                                (cdr on-formals)
                                (acons (car on-formals) (car formals) locals))))))
       (clone o #:statement (model-purge-data model statement locals))))

    (($ <function> name ($ <signature> type ($ <formals> (formals ...))) recursive? statement)
     (let* ((locals (let loop ((formals formals) (locals locals))
                      (if (null? formals)
                          locals
                          (loop (cdr formals)
                                (acons (.name (car formals)) (car formals) locals))))))
       (clone o
         #:signature (make <signature>
                      #:type type
                      #:formals (make <formals> #:elements (purge-formal-list o formals)))
         #:statement (model-purge-data model statement locals))))

    (($ <assign> (? extern?) expression) (make <skip>))

    (($ <variable> name (? extern-type?) expression) (make <skip>))

    (($ <return> ($ <expression> ($ <data>))) (make <skip>))

    ((? (is? <event>)) o)
    (($ <event>) o)
    (($ <field>) o)
    (($ <literal>) o)
    (($ <otherwise>) o)
    (($ <port>) o)
    (($ <trigger>) o)
    (($ <type>) o)
    (($ <var>) o)

    ((? (is? <ast>)) (om:map (lambda (o) (model-purge-data model o locals)) o))
    ((h t ...) (map (lambda (o) (model-purge-data model o locals)) o))
    (_ o)))

(define (tail-call o)
  (match o
    (($ <function> name signature recursive? statement)
     (clone o #:statement (or (mark-last statement) statement)))
    (_ o)))

(define (mark-last o)

  (match o

    (($ <compound> (statements ...))
     (and-let* ((statements
                 (let loop ((statements (reverse statements)) (collect '()))
                   (if (null? statements)
                       #f
                       (let* ((statement (car statements))
                              (marked? (mark-last statement)))
                         (if marked?
                             (reverse (append collect (cons marked? (cdr statements))))
                             (loop (cdr statements) (cons statement collect))))))))
               (clone o #:elements statements)))

    (($ <call> function-name arguments)
     (clone o #:last? #t))

    (($ <if> expression then else)
     (let ((then- (mark-last then))
           (else- (and else (mark-last else))))
       (if (and (not then-) (not else-))
           #f
           (clone o
             #:then (or then- then)
             #:else (or else- else)))))

    (($ <assign> variable (and ($ <call>) (get! call)))
     (clone o #:expression (mark-last (call))))

    (($ <variable> name type (and ($ <call>) (get! call)))
     (clone o #:expression (mark-last (call))))

    (($ <skip>) #f)

    (($ <return> #f) #f)

    (_ o)))

(define (ast-transform-return ast o)
  (match o
    (($ <compound> (statements ...))
     (let ((result
            (let loop ((statements (map (lambda (x) (ast-transform-return ast x)) statements)))
              (if (null? statements)
                  '()
                  (cons (car statements) (loop (cdr statements)))))))
       (if (=1 (length result))
           (car result)
           (clone o #:elements result))))
    (($ <on> triggers statement)
     (let* ((model (or (om:component ast) (om:interface ast)))
            (members (om:member-names model))
            (valued-triggers? (lambda (x) (om:typed? model ((compose car .elements) triggers)))))
       (let ((result (ast-transform-return ast statement)))
         (match result
           (($ <blocking> statement)
            (clone o #:statement result))
           (($ <compound> ())
            (clone o #:statement (make <compound> #:elements (list (make <voidreply>)))))
           ((? valued-triggers?)
            (clone o #:statement (make <compound> #:elements (list result))))
           (_ (clone o #:statement (make <compound> #:elements (list result (make <voidreply>)))))))))
    (_ o)))

(define (qualify-modelling-events ast o)
  (match o
    (($ <on> triggers statement)
      (clone o #:statement statement))
    ((? (is? <ast>)) (om:map qualify-modelling-events o))
    ((h t ...) (map qualify-modelling-events o))
    (_ o)))



(define* (on->csp model o #:optional (inevitable-optional? #f) (channel #f) (provided-on? #t) (locals '()) (indent 0) (tail '()) (function #f))

  (define (member? identifier) (and (not (local? identifier))
                                    (om:variable model identifier)))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (bool? identifier) (and (var? identifier) (is-a? (.type (var? identifier)) <bool>)))

  (define (communicate events)
    (if (or (not (pair? events)) (eq? (length events) 1))
        (list "." events)
        (list "?x:{" (comma-join events) "}")))

  (define (expression-type o locals)
    (let ((type (ast:expression-type o)))
      (om:type-name type)))

  (let* ((model (or (om:component model) (om:interface model)))
         (model-name ((om:scope-name) model))
         (model- (symbol-append model-name '_))
         (channel (or channel (if (is-a? model <interface>) model-name (.name (om:port model)))))
         (space (make-string (* indent 2) #\space))
         (member-name-list (comma-join (om:member-names model))))

    (if (null? o)
        tail
        (match o

          ;; Entry points
          (($ <on> ($ <triggers> (triggers ...)) (and (? prefix-illegal?) (get! statement)))
           (let* ((inevitable-optional?
                   (or (member 'inevitable (map .event.name triggers))
                       (member 'optional (map .event.name triggers))))
                  (provided-on?
                   (or (and (is-a? model <interface>) (not inevitable-optional?))
                       (or (as model <interface>) ((provides-trigger? model) (car triggers)))))
                  (the-end (if (and (is-a? statement <blocking>) provided-on?) (make <the-end-blocking>) (make <the-end>)))
                  (channel (if (is-a? model <interface>) model-name (.port.name (car triggers))))
                  (transformed-end (on->csp model the-end inevitable-optional? channel provided-on? locals (1+ indent)))
                  (tail (on->csp model (statement) inevitable-optional? channel provided-on? locals (1+ indent) transformed-end function))
                  (real-triggers (filter (negate om:modeling?) triggers))
                  (modeling-triggers (filter om:modeling? triggers))
                  (modeling-triggers (qualify-modeling-event (map .event.name modeling-triggers) statement))
                  (trigger-in? (lambda (trigger) (om:in? (.event trigger)))))
             (receive (ins outs) (partition trigger-in? real-triggers)
                 ((->list-join "\n[]\n")
                  (append
                   (if (pair? ins)
                       (list
                        (list
                         (if (is-a? model <interface>) (list "IG & " model-name) (list "ill." (.port.name (car ins))))
                         (list (communicate (append modeling-triggers (map .event ins))) " -> (\n")
                         tail
                         ")"))
                       (if (pair? modeling-triggers)
                           (list
                            (list
                             "IG & "
                             model-name
                             (list "_'''" (communicate modeling-triggers) " -> (\n")
                             tail
                             ")"))
                           '()))
                   (if (pair? outs)
                       (list
                        (list
                         (list "IG & " (.port.name (car outs)))
                         (list "_''" (communicate (map .event.name outs)) " -> (\n")
                         tail
                         ")"))
                        '()))))))

          (($ <on> ($ <triggers> (triggers ...)) statement)
           (let* ((inevitable-optional?
                   (or (member 'inevitable (map .event.name triggers))
                       (member 'optional (map .event.name triggers))))
                  (provided-on?
                   (or (and (is-a? model <interface>) (not inevitable-optional?))
                       (or (as model <interface>) ((provides-trigger? model) (car triggers)))))
                  (the-end (if (and (is-a? statement <blocking>) provided-on?) (make <the-end-blocking>) (make <the-end>)))
                  (channel (if (is-a? model <interface>) model-name (.port.name (car triggers))))
                  (transformed-end (on->csp model the-end inevitable-optional? channel provided-on? locals (1+ indent)))
                  (tail (on->csp model statement inevitable-optional? channel provided-on? locals (1+ indent) transformed-end function))
                  (real-triggers (filter (negate om:modeling?) triggers))
                  (modeling-triggers (filter om:modeling? triggers))
                  (modeling-triggers (qualify-modeling-event (map .event.name modeling-triggers) statement))
                  (trigger-in? (lambda (trigger) (om:in? (.event trigger)))))
             (receive (ins outs) (partition trigger-in? real-triggers)
                 ((->list-join "\n[]\n")
                  (append
                   (if (pair? ins)
                       (list
                        (list
                         (if (is-a? model <interface>) model-name (.port.name (car ins)))
                         (list (communicate (append modeling-triggers (map .event.name ins))) " -> (\n")
                         tail
                         ")"))
                       (if (pair? modeling-triggers)
                           (list
                            (list
                             (if (is-a? model <interface>) model-name channel)
                             (list "_'''" (communicate modeling-triggers) " ->(\n")
                             tail
                             ")"))
                            '()))
                   (if (pair? outs)
                       (list
                        (list
                         (if (is-a? model <interface>) model-name (.port.name (car outs)))
                         (list "_''" (communicate (map .event.name outs)) " -> (\n")
                         tail
                         ")"))
                       '()))))))

          (($ <function> name ($ <signature> type ($ <formals> (formals ...))) recursive? statement)
           (let* ((locals (let loop ((formals formals) (locals locals))
                            (if (null? formals)
                                locals
                                (loop (cdr formals)
                                      (acons (.name (car formals)) (car formals) locals)))))
                  (tail (list (list "    " "P'(" (comma-space-join (om:member-names model)) ")\n" )))
                  (transformed (on->csp model statement inevitable-optional? channel provided-on? locals 2 tail name))
                  (lets (collect-def transformed)))
             (list
              (list name "(" "P'" ")" "(" (comma-space-join (append (om:member-names model) (map .name formals))) ") = \n")
              (check-range
               (map .name formals)
               (list
                (if (pair? lets)
                    (list
                     "let\n"
                     ((->join "\n") lets)
                     "within\n"))
                transformed)
               model
               locals
               indent))))

          ;; compound statements
          (($ <compound> (statements ...))
           (on->csp model statements inevitable-optional? channel provided-on? locals indent tail function))

          (($ <if> expression then else)
           (let* ((expression (csp-expression->string model expression locals))
                  (s (make-string 2 #\space))
                  (tail (map (lambda (x) (if (def? x) x (if (pair? x) (cons s x) (list s x)))) tail))
                  (then (on->csp model then inevitable-optional? channel provided-on? locals (1+ indent) tail function))
                  (else (on->csp model (or else '()) inevitable-optional? channel provided-on? locals (1+ indent) tail function)))
             (list
               (list space "(if " expression " then \n")
               (list then "\n")
               (list space "else\n")
               (list else ")\n")
              )))

          (($ <blocking> stat)
           (let* ((stat (on->csp model stat inevitable-optional? channel provided-on? locals (1+ indent) tail function)))
             (list
               (list stat "\n")
              )))

          ;; simple statements
          (($ <call> function-name arguments last?)
           (let* ((arguments (on->csp model arguments inevitable-optional? channel provided-on? locals))
                  (s (make-string 2 #\space))
                  (tail (map (lambda (x) (if (def? x) x (if (pair? x) (cons s x) (list s x)))) tail))
                  (continuation (list (list "Cont_" (fresh-number) "'"))))
             (if last?
                 (list space function-name "(" "P'" ")" "(" (comma-space-join (append (om:member-names model) arguments (list ))) ") -- tail recursion" "\n")
                 (list
                  (def-cont
                   space
                   (list
                    (list continuation "(" (comma-space-join (om:member-names model)) ")" " =\n")
                    tail))
                  (list space function-name "(" continuation ")" "(" (comma-space-join (append (om:member-names model) arguments)) ")" "\n")))))

          (($ <assign> variable (and ($ <action>) (= .port.name port-name) (= .event event)))
           (let* ((type ((compose .type .signature) event))
                  (event-name (.name event))
                  (variable-name (and=> variable .name))
                  (values (if (is-a? type <void>) 'return (comma-join (typed-elements type))))
                  (constructor (if (is-a? type <bool>) "bool." ""))
                  (constructor (if (is-a? type <int>) "int." constructor)))
             (list
              (list space (or port-name channel) (if (om:out? event) "_''") "!" event-name " ->\n")
              (list space (or port-name channel) "_'?" constructor variable-name ":{" values "} ->\n")
              (check-range (list variable-name) tail model locals indent))))

          (($ <assign> variable ($ <call> function-name arguments))
           (let* ((arguments (on->csp model arguments inevitable-optional? channel provided-on? locals))
                  (variable-name (and=> variable .name))
                  (s (make-string 2 #\space))
                  (tail (map (lambda (x) (if (def? x) x (if (pair? x) (cons s x) (list s x)))) tail))
                  (continuation (list (list "Cont_" (fresh-number) "'"))))
             (list
              (def-cont
               space
               (list
                (list continuation "(" (comma-space-join (append (om:member-names model) (list "res'"))) ")" " =\n")
                (list space "let " variable-name " = res' within\n")
                (check-range (list variable-name) tail model locals indent)))
              (list space function-name "(" continuation ")" "(" (comma-space-join (append (om:member-names model) arguments)) ")" "\n"))))

          (($ <assign> variable expression)
           (let* ((expression (csp-expression->string model expression locals))
                  (variable-name (and=> variable .name)))
             (list
              (list space "let " "tmp'" " = " expression " within\n")
              (list space "let " variable-name " = " "tmp'" " within\n")
              (check-range (list variable-name) tail model locals indent))))

          (($ <variable> identifier type (and ($ <action>) (= .port.name port-name) (= .event event)))
           (let* ((type ((compose .type .signature) event))
                  (event-name (.name event))
                  (values (if (is-a? type <void>) 'return (comma-join (typed-elements type))))
                  (constructor (if (is-a? type <bool>) "bool." ""))
                  (constructor (if (is-a? type <int>) "int." constructor)))
             (list
             (list space (or port-name channel) (if (om:out? event) "_''") "!" event-name " ->\n")
             (list space (or port-name channel) "_'?" constructor identifier ":{" values "} ->\n")
             (check-range (list identifier) tail model locals indent))))

          (($ <variable> name type ($ <call> function-name arguments))
           (let* ((arguments (on->csp model arguments inevitable-optional? channel provided-on? locals))
                  (s (make-string 2 #\space))
                  (tail (map (lambda (x) (if (def? x) x (if (pair? x) (cons s x) (list s x)))) tail))
                  (continuation (list (list "Cont_" (fresh-number) "'"))))
             (list
              (def-cont
               space
               (list
                (list continuation "(" (comma-space-join (append (om:member-names model) (list "res'"))) ")" " =\n")
                (list space "let " name " = res' within\n")
                (check-range (list name) tail model locals indent)))
              (list space function-name "(" continuation ")" "(" (comma-space-join (append (om:member-names model) arguments)) ")" "\n"))))

          (($ <variable> name type expression)
           (let* ((expression (csp-expression->string model expression locals)))
             (list
              (list space "let " name " = " expression " within\n")
              (check-range (list name) tail model locals indent))))

          (($ <reply> expression port)
           (let* ((type (expression-type expression locals))
                  (csp (csp-expression->string model expression locals))
                  (csp (match type
                         ('bool (->string "bool." csp))
                         ('int (->string "int." csp))
                         (_ csp)))
                  (port (if port
                            port
                            (if (or provided-on? (as model <interface>))
                                channel
                                (.name (om:port model))))))
             (if csp
                 (list
                  (list space "if not member(" csp "," "extensions(" port "_')) then type_error -> illegal -> STOP else\n")
                  (list space port "_'!" csp " -> \n")
                 tail)
                 (list
                  (list space port "_'.return -> \n")
                  tail))))

          ((and ($ <action>) (= .port.name port-name) (= .event event))
           (let* ((event-name  (.name event))
                  (suffix (if (om:out? event) "_''" ""))
                  (channel (if (is-a? model <interface>) model-name port-name))
                  (trigger (make <trigger> #:port port-name #:event event))
                  (channel-return (if ((requires-trigger? model) trigger) (list " -> " channel "_'.return")))
                  (channel (list channel suffix)))
             (list
              (list space channel "!" event-name channel-return " ->\n")
              tail)))

          (($ <illegal>)
           (list
            (list space "illegal -> STOP\n")))

          (($ <return> #f)
           (list (list "    " "P'(" (comma-space-join (om:member-names model)) ")\n" )))

          (($ <return> expression)
           (let ((expression (csp-expression->string model expression locals)))
             (list (list "    " "P'(" (comma-space-join (append (om:member-names model) (list expression)) ) ")\n" ))))

          (($ <skip>) tail)

          (($ <voidreply>)
           (let ((channel-return
                  (if (and (not inevitable-optional?) provided-on?)
                      (list
                       (list space channel "_'.return ->\n")))))
             (list
              (list space channel-return)
              tail)))

          ;; other bits
          (($ <arguments> (arguments ...))
           (map (lambda (x) (on->csp model x inevitable-optional? channel provided-on? locals)) arguments))

          (($ <expression> (and ($ <call>) (get! call))) (on->csp model (call) inevitable-optional? channel))
          ((? (is? <expression>)) (csp-expression->string model o locals))

          (($ <the-end>)
           (let ((component? (as model <component>)))
             (if component?
                 (list
                  (list space "transition_end ->\n")
                  (list space model-name "_(" (comma-join (om:member-names model)) ")\n"))
                 (list
                  (list space channel ".the_end' ->\n")
                  (list space model-name "_(" (comma-join (om:member-names model)) ")\n"))
                 )))

          (($ <the-end-blocking>)
            (list
             (list space channel "_'.blocked ->\n")
             (list space "transition_end ->\n")
             (list space model-name "_(" (comma-join (om:member-names model)) ")\n")))

          (#f (list space "SKIP\n"))
          (#t (list space "SKIP\n")) ;; FIXME: who produces #t?

          ((h t ...)
           (let* ((locals (match h
                                 (($ <variable> name) (acons name h locals))
                                 (_ locals)))
                  (tail (on->csp model t inevitable-optional? channel provided-on? locals indent tail function)))
             (on->csp model h inevitable-optional? channel provided-on? locals indent tail function)))

          (_ (stderr "TODO: ~a\n" o)
             (list
              (format #f "-- TODO: ~a\n" o)))))))

(define (qualify-modeling-event events statement)
  (map (lambda (e) (list e (if (pair? ((om:collect <action>) statement))
                               ".false"
                               ".true")))
       events))

(define (csp-queue-size) (command-line:get 'queue_size 3))

(define* (check-range identifiers statement model #:optional (locals '()) (indent 0))
  (define (member? identifier) (om:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (local? identifier) (member? identifier)))
  (define (int-type? type) (om:integer model type))
  (define (int? identifier) (and=> (var? identifier)
                                   (lambda (var) (int-type? (.type var)))))
  (define (range-guard identifier)
    (if (int? identifier)
        (let* ((range (.range (int? identifier)))
               (lo (.from range))
               (hi (.to range)))
          (list
           (list "(" lo " <= " identifier " and " identifier " <= " hi ")")))
        '()))
  (let* ((space (make-string (* indent 2) #\space))
         (guards (apply append (map (lambda(x) (range-guard x)) identifiers))))
    (if (pair? guards)
        (list
         (list space "if not (" ((->join (string-append " and\n" space)) guards) ") then range_error -> illegal -> STOP else\n")
         statement)
        statement)))

(define (def? x) (and (pair? x) (eq? (car x) 'def)))
(define (def-delete o) (match o (('def t ...) '()) ((h t ...) (map def-delete o)) (_ o)))

(define-syntax string-if
  (syntax-rules ()
    ((_ condition then)
     (animate-string (if (null-is-#f condition) then "") (current-module)))
    ((_ condition then else)
     (animate-string (if (null-is-#f condition) then else) (current-module)))))

(define (csp-comma-list x)
  (let ((s ((->join ",") x)))
    (if (>1 (length x))
        (->string "(" s ")")
        s)))

(define fresh-number #f)
(let ((counter 0))
  (set! fresh-number (lambda () (set! counter (1+ counter)) counter)))

(define ((->list-join str) l)
  (let ((x (apply append (map (lambda (x) (list str x)) l))))
    (if (pair? x)
        (->string (cdr x))
        "STOP"))) ;; FIXME: JCN??

(define (collect-def l)
  (match l
         (('def t ...) (remove-def (append (list t) (apply append (map collect-def t)))))
         ((h t ...) (remove-def (apply append (map collect-def l))))
         (_ '())))

(define (remove-def l)
  (match l
         (('def t ...) '())
         ((h t ...) (map remove-def l))
         (_ l)))

(define (def-cont space l)
  (let ((inline #t))
    (if inline
        (append
         (list space "let ")
         l
         (list space "within\n")
         )
        (append (list 'def) l))))

(define* (csp-channels port #:optional (op .name))
  (map (cut symbol-append (op port) <>)
       (map string->symbol
            (if (not (null? (filter om:out? (om:events port)))) (list "" "_'" "_''" "_'''") (list "" "_'")))))

(define* (pairs->module key-procedure-pairs #:optional (parameter #f))
  (let ((module (csp:module (and=> (module-variable (current-module) 'model)
                                    variable-ref))))
    (populate-module module key-procedure-pairs parameter)))

(define* ((animate-pairs pairs string) #:optional parameter)
  (animate string (pairs->module pairs parameter)))

(define (move-internal-ports o)
  (match o
    ((and ($ <component>) (= .ports ports) (= .behaviour behaviour))
     (if (not behaviour)
         o
         (clone o
                #:ports (make <ports> #:elements (append (om:port* ports) (om:ports behaviour)))
                #:behaviour (clone behaviour #:ports (make <ports>)))))
    ((? (is? <ast>)) (om:map move-internal-ports o))
    (_ o)))

(define (add-internal-libs-behaviour o)

  (define ((rename-behaviour events) o)
    (define (rename events event)
      (if (null? events) event
          (if (eq? (.name event) (demangle (.name (car events))))
              (clone event #:name (.name (car events)))
              (rename (cdr events) event))))
    (match o
      ((and ($ <action>) (= .event event))
       (clone o #:event (rename events event)))
      ((and ($ <trigger>) (= .event event))
       (clone o #:event (rename events event)))
      ((? (is? <ast>)) (om:map (rename-behaviour events) o))
      ((h t ...) (map (rename-behaviour events) o))
      (_ o)))

  (match o
    (($ <interface> name types events behaviour)
     (if (dzn-async? name)
         (clone o #:behaviour ((rename-behaviour (.elements events)) (async-behaviour)))
         o))
     ((? (is? <ast>)) (om:map add-internal-libs-behaviour o))
     (_ o)))

(define (demangle o)
  (define (generator-mangled? o)
    (string-match "^i[0-9]+_" (symbol->string o)))
  (match o
    ((? symbol?) (let ((m (generator-mangled? o)))
                   (if (not m) o
                       (let* ((s (regexp-substitute #f m 'post))
                              (m (string-match "_i_" s)))
                         (if (not m) (string->symbol s)
                             (string->symbol (regexp-substitute #f m 'pre "_i" 'post)))))))
    ((and ($ <scope.name>) (= .scope scope) (= .name name))
     ((->symbol-join '.) (map demangle (append scope (list name)))))))

(define-method (dzn-async? (o <scope.name>))
  (let ((scope (.scope o)))
    (and (pair? scope)
         (eq? (demangle (car scope)) 'dzn))))

(define (async-behaviour)
  ((compose .behaviour car .elements ast:resolve ast->om dzn->ast)
"interface dzn.async {
  in void req();
  in void clr();
  out void ack();

  behaviour {
    bool dzn_idle = true;
    [dzn_idle] {
      on req: dzn_idle = false;
      on clr: {}
    }
    [!dzn_idle] {
      on req: illegal;
      on clr: dzn_idle = true;
      on inevitable: { ack; dzn_idle = true; }
    }
  }
}"))

(define-method (internal-libs (o <root>))
  ((compose-root
    add-internal-libs-behaviour
    move-internal-ports
    ) o))
