;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (language asd csp)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (ice-9 receive)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language asd animate)
  :use-module (language asd asserts)
  :use-module (language asd ast:)
  :use-module (language asd gaiag)
  :use-module (language asd misc)
  :use-module (language asd reader)
  :use-module (language asd normstate)
  :export (
           ast->
           csp-component
           csp-module
	   ast-transform
	   ast-transform-function-call
	   ast-transform-return
	   csp-transform
           ))

(define (ast-> ast)
  (let ((norm (normstate ast)))
    (ast:register norm #t)
    (module-define! (resolve-module '(language asd csp)) 'ast norm)  ;; FIXME
    (and-let* ((comp (ast:component norm))
	       (name (ast:name comp))
	       (module (csp-module norm)))
	      (dump-output (list name '.csp)
                           (lambda ()
                             (csp-component module)
			     (csp-asserts module)))))
  "")

(define (csp-component module)
  (animate-file 'templates/component.csp.scm module))

(define (csp-asserts module)
  (let* ((asserts-string (option-ref (parse-opts (command-line)) 'assert #f))
	 (asserts (if asserts-string (with-input-from-string asserts-string read)
		      (assert-list (module-ref module 'ast)))))
    (for-each (csp-assert module) asserts)))

(define ((csp-assert module) assert)
  (let* ((class (car assert))
	 (model (cadr assert))
	 (check (caddr assert))
	 (template (assoc-ref asserts-alist (list class check))))
    (module-define! module '.model model)
    (animate-string template module)))

(define asserts-alist
  `(
    ((component deterministic) . "assert #.component _#.behaviour(true,true) :[deterministic]\n")
    ((component illegal) . "assert STOP [T= #.component _#.behaviour _Component(false) \\ diff(Events,{illegal})\n")
    ((component deadlock)  . "assert #.component _#.behaviour _Component(false) :[deadlock free]\n")
    ((component compliance) . ,(gulp-file 'templates/asserts/component-compliance.csp.scm))
    ((interface deadlock) . ,(gulp-file 'templates/asserts/interface-deadlock.csp.scm))
    ((interface livelock) . ,(gulp-file 'templates/asserts/interface-livelock.csp.scm))))

(define (ast-norm model-name)
  (ast:ast model-name normstate))

(define (csp-module ast)
  (let ((module (make-module 31 (list
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(ice-9 curried-definitions))
                                 (resolve-module '(language asd ast:))
                                 (resolve-module '(language asd csp))))))
    (module-define! module 'ast ast)
    (and-let* ((comp (ast:component ast)))
              (module-define! module '.component (ast:name comp))
              (module-define! module 'component comp)
	      (module-define! module '.interface (ast:name (ast:interface ast)))
	      (module-define! module '.behaviour (ast:name (ast:behaviour comp)))
              (module-define! module '.interface-behaviour (ast:name (ast:behaviour (ast:interface ast))))
	      (module-define! module '.port (ast:name (ast:port comp))))
    module))

(define* (map-ports string ports :optional (separator ""))
  ((->join separator)
   (map (lambda (port)
          (with-output-to-string
            (lambda ()
              (save-module-excursion
               (lambda ()
                 (animate-string
                  string
                  (animate-module-populate
                   (csp-module ast)
                   port
                   `((port . ,identity)
                     (interface . ,(ast-norm (ast:type port)))
                     (.optional-chaos . ,optional-chaos)
                     (.interface . ,ast:type) ;; FIXME
                     (.name . ,ast:name)
                     (.port . ,ast:name)
                     (.behaviour . ,(compose ast:name ast:behaviour))))))))))
        ports)))

(define (map-guards string guards)
  (display
   ((->join "[]\n")
    (map (lambda (guard)
           (with-output-to-string
             (lambda ()
               (animate-string
                string
                (animate-module-populate
                 (current-module)
                 guard
                 `((guard . ,identity))))))) guards))))

(define (csp-expression->string expression)
  (match expression
    (('value type field) (list type " == " field))
    ((? symbol?) expression)
    (('and lhs rhs) (->string (list (csp-expression->string lhs) " and " (csp-expression->string rhs))))
    (('! expression) (->string (list "not " (csp-expression->string expression))))
    (_ (format #f "~a:NO MATCH: ~a" (current-source-location) expression))))

(define (port-triggers port)
  (sort ((ast:find-events) (ast-norm (ast:type port))) symbol<))

(define (enum-values comp)
  (let ((comp-values (apply append (map ast:elements (ast:types (ast:behaviour comp))))))
    (let loop ((ports (ast:ports comp)) (values comp-values))
      (if (null? ports)
          values
          (loop (cdr ports) (append values (apply append (map ast:elements (ast:types (ast:behaviour (ast-norm (ast:type (car ports)))))))))))))

(define (return-value enum)
  (map (lambda (value) (symbol-append (ast:name enum) '_ value)) (ast:elements enum)))

(define (add-return-if-empty returns)
  (if (null? returns)
      '(return)
      (apply append returns)))

(define (return-values-port port)
  (add-return-if-empty (map return-value (ast:types (ast-norm (ast:type port))))))

(define (return-values comp)
    (let loop ((ports (ast:ports comp)) (result '()))
      (if (null? ports)
          result
          (loop (cdr ports) (append result (return-values-port (car ports)))))))

(define (var-names model)
  (map ast:name (ast:variables (ast:behaviour model))))

(define ((statement-on-p/r predicate) statement-on)
  (let* ((events (ast:triggers statement-on))
         (events-predicate (filter predicate events))
         (statement (ast:statement statement-on)))
  (if (pair? events-predicate)
      (ast:make 'on events-predicate statement)
      #f)))

(define (event->string event)
  (if (pair? event) (caddr event) event))

(define (prefix-illegal? statement)
  (match statement
    (('compound tail ...) (let loop ((statements tail))
                            (if (null? statements)
                                #f
                                (or (prefix-illegal? (car statements)) (loop (cdr statements))))))
    ('(action illegal) #t)
    (_ #f)))

(define (prefix-reply? statement)
  (match statement
    (('compound stat ...) (let loop ((statements stat))
                            (if (null? statements)
                                #f
                                (or (prefix-reply? (car statements)) (loop (cdr statements))))))
    (('guard expr stat)
     (prefix-reply? stat))
    (('on events stat)
     (prefix-reply? stat))
    (('if expression then else)
     (or (prefix-reply? then) (prefix-reply? else)))
    (('reply value) #t)
    (_ #f)
    (_ (throw 'match-error (format #f "~a:prefix-reply?: no match: ~a\n" (current-source-location) statement)))))

(define (((provides-or-requires? type) component) event)
  (if (ast:component? component)
      (pair?
       (filter
	(lambda (port) (and (equal? type (car port)) (equal? (if (pair? event) (cadr event) event) (caddr port))))
	(ast:ports component)))
      #f))

(define ((provides? component) event)
  (((provides-or-requires? 'provides) component)  event))

(define ((requires? component) event)
  (((provides-or-requires? 'requires) component)  event))

(define (value ast)
  (match ast
    ((? ast:trigger?) (ast:event-name ast))
    ((? ast:value?) (ast:field ast))
    (_ ast)))

(define (optional-chaos port)
  (let ((interface (ast:type port)))
    (if (member 'optional ((ast:find-events) (ast-norm (ast:type port))))
        (list "[|{" interface " .optional}|] " "CHAOS({" interface " .optional})")
        "")))

(define (->string src)
  (match src
    (('value type field) (->string (list type "." field)))
    (('trigger port event) (->string (list port "." event)))
;;    (_ (stderr "NO MATCH: ~a\n" src) (format #f "~a" src))
    (_ ((@ (language asd misc) ->string) src))))

(define (action-name action)
  (if (pair? action)
      (let ((name (cadr action)))
        (if (pair? name) (cadr name) name))
      action))

(define ((action->string ast inevitable-optional?) action)
  (->string (list (if (ast:interface? ast) (list (ast:name ast) ".") "") (->string action) " -> "
                  (when (and (not (ast:interface? ast)) ((requires? ast) action) (not inevitable-optional?))
                    (list (action-name action) ".return -> ")))))

(define* (ast-transform ast src)
  (ast-transform- ast (ast-transform-return ast (ast-transform-function-call ast src))))

(define (ast-transform-function-call ast src)
  (let ((model (or (ast:interface ast) (ast:component ast))))
    (match src
      (('action name)
       (if (member name (map ast:name (ast:functions (ast:behaviour model))))
           (list 'call name)
           src))
      ((h ...) (map (lambda (x) (ast-transform-function-call ast x)) src))
      (_ src))))

(define* (ast-transform-return ast src :optional (top? #t))
  (let* ((model (or (ast:interface ast) (ast:component ast)))
	 (variables (var-names model)))
    (match src
      (('compound t ...)
       (let ((result
	      (let loop ((statements (map (lambda (x) (ast-transform-return ast x #f)) t)))
		(if (null? statements)
		    '()
		    (cons (car statements) (loop (cdr statements)))))))
	 (if (=1 (length result))
	     (car result)
	     (cons 'compound result))))
      (('on events stat)
       (let ((result (ast-transform-return ast stat)))
	 (if (>1 (length result))
	     (list 'on events (if (prefix-reply? result)
                                  (list 'compound result)
                                  (list 'compound result (list 'return))) `(the-end ,variables))
	     (list 'on events (list 'compound (list 'return)) `(the-end ,variables)))))
      (_ src))))

(define ((assignment var exp) x)
  (if (eq? x var ) exp x))

(define* (ast-transform- ast src :optional (return #t) (locals '()) (frame '()) (last? #f))
  (let* ((model (or (ast:interface ast) (ast:component ast)))
	 (members (var-names model))
         (variables (cons members locals))
         (port? (lambda (port) (member port (map ast:name (ast:ports model))))))
    (match src
      (('compound tail ...)
       (let loop ((statements tail) (frame '()))
	 (if (null? statements)
	     '()
             (let* ((statement (car statements))
                    (frame (append frame (if (ast:variable? statement) (list (ast:name statement)) '())))
                    (last? #f)
                    (transformed (ast-transform- ast statement #f locals frame last?)))
               (if (>1 (length statements))
                   (if (equal? transformed '(action illegal))
                       transformed
                       (list (if (ast:variable? statement) 'context 'semi) transformed (loop (cdr statements) frame)))
                   transformed)))))
      (('on events stat the-end)
       (let ((result (ast-transform- ast stat)))
	 (if (prefix-illegal? stat)
	     (list 'on events 'IG result)
	     (list 'on events result the-end))))
      (('variable type var (and ('value (? port?) action) (get! value)))
       (list variables var (list 'valued-action (value))))
      (('variable type var expr)
       (list variables var (list 'expression expr)))
      (('assign var ('value type field))
       (list 'assign variables frame last? (cons (map (assignment var field) members)
                                                 (map (assignment var field) locals))))
      (('assign var exp)
       (list 'assign variables frame last? (cons (map (assignment var exp) members)
                                                 (map (assignment var exp) locals))))
      (('if pred then)
       (list 'if variables frame last? (list 'expression (if (prefix-illegal? then)
                                                             (list 'and 'IG pred)
                                                             pred))
             (ast-transform- ast then return locals frame last?) '()))
      (('if expr then else)
       (let* ((then-illegal? (prefix-illegal? then))
	      (else-illegal? (prefix-illegal? else))
	      (pred-then (if then-illegal? (list 'and 'IG expr) expr))
	      (pred (if else-illegal? (list 'and '(! IG) pred-then) pred-then)))
	 (list 'if variables frame last? (list 'expression pred)
               (ast-transform- ast then return locals frame last?)
               (ast-transform- ast else return locals frame last?))))
      (('function name type statement)
       (let ((transformed (ast-transform- ast statement return locals frame last?)))
         (list 'function name type transformed)))
      (_ src))))

(define ((provides-event? model) event)
  (and (ast:component? model)
       ((provides? model) event)))

(define ((requires-event? model) event)
  (and (ast:component? model)
       ((requires? model) event)))

(define* (csp-transform ast src :optional (inevitable-optional? #f) (channel #f) (provided-on? #t))
  (let* ((model (or (ast:interface ast) (ast:component ast)))
	 (model-name (ast:name model))
	 (behaviour (ast:name (ast:behaviour model)))
         (component? (ast:component? model)))
    (->string
     (match src
       ;;(('on events stat) (animate-string "#model-name ?x:{#events } -> "))
       (('on events stat ...)
        (let* ((inevitable-optional? (or (member 'inevitable (map ast:event-name events))
                                         (member 'optional (map ast:event-name events))))
               (ig? (and (pair? stat) (eq? (car stat) 'IG)))
               (channel (if (ast:interface? model) model-name (ast:port-name (car events))))
               (provided-on? (or (and (ast:interface? model) (not inevitable-optional?)) (or (ast:interface? model) ((provides-event? model) (car events)))))
               (IG? (if ig? (if ((provides-event? model) (car events)) "IIG & "  "IG & ")))
               (event-names (comma-join (map ast:event-name events)))
	       (stat (if ig? (cdr stat) stat))
	       (transformed-stat (map (lambda (x) (csp-transform ast x inevitable-optional? channel provided-on?)) stat)))
          (list IG? channel "?x:{" event-names "}" " ->\n" transformed-stat)))
       (('reply expr) (let ((expr (csp-transform ast expr inevitable-optional? channel provided-on?)))
                        (list "(\\P',V' @ " channel "." expr " -> P'(V'))")))
       (('return expression) (csp-transform ast expression))
       (('return) (let ((channel-return (if (and (not inevitable-optional?) provided-on?) (list "(\\P',V' @ " channel ".return -> P'(V'))") (list "(\\P',V' @ P'(V'))"))))
                    (list channel-return)))
       (('the-end vars) (let* ((transition-end (if component? "transition_end -> "))
                               (vars (comma-join vars))
                               (end (if (not inevitable-optional?) (list transition-end))))

			  (list "(\\V' @ " end model-name "_" behaviour "_" "(V'),((" vars ")))")))
       (('action 'illegal) "illegal -> STOP")
       (('action event)
        (let* ((channel (if (ast:interface? model) model-name (ast:port-name event)))
               (event-name (ast:event-name event))
               (channel-return (if ((requires-event? model) event) (list " -> " channel ".return"))))
          (list "(\\P',V' @ " channel "!" event-name channel-return " -> P'(V'))")))
       (('function name type statement)
        (let ((transformed (csp-transform ast statement inevitable-optional? channel provided-on?)))
          (list name "(P',V') =\n" transformed "(P',V')\n")))
       (('call function) `(,function))
       (('assign ('variable type var action))
        (list "(\\P',V' @ " (cadr action) "!" (caddr action) " -> " (cadr action) "?" var " -> P'((V'," var ")))"))
       (('assign vars frame last? (expressions locals ...))
        (let* ((var-members (comma-join (map (lambda (x) (csp-transform ast x)) (car vars))))
               (var-locals (comma-join (map (lambda (x) (csp-transform ast x)) (append (cdr vars) frame))))
               (comma (if (string-null? var-locals) "" ","))
               (expressions (comma-join
                             (append (map (lambda (x) (csp-transform ast x)) expressions)
                                     (map (lambda (x) (csp-transform ast x)) locals)))))
          (list "assign(\\((" var-members ")" comma var-locals ") @ (" expressions "))")))
       (('if vars frame last? expression then else)
        (let* ((var-members (comma-join (map (lambda (x) (csp-transform ast x)) (car vars))))
               (var-locals (comma-join (map (lambda (x) (csp-transform ast x)) (append (cdr vars) frame))))
               (comma (if (string-null? var-locals) "" ","))
               (var-locals-last (if last?
                                    (comma-join (map (lambda (x) (csp-transform ast x)) (cdr vars)))
                                    var-locals))
               (comma-last (if last?
                               (if (string-null? var-locals-last) "" ",")
                               comma))
               (expression (csp-transform ast expression))
               (then (csp-transform ast then inevitable-optional? channel provided-on?))
               (else (csp-transform ast else inevitable-optional? channel provided-on?)))
          (list "\\P',((" var-members ")" comma var-locals ") @ ifthenelse(" expression ",\n" then ",\n" else "\n)(P',((" var-members ")" comma-last var-locals-last "))")))
       (('expression e) (csp-transform ast e))
       (('! e) (let ((e (csp-transform ast e)))
                 (list "not (" e ")")))
       (('or lhs rhs) (let ((lhs (csp-transform ast lhs))
                            (rhs (csp-transform ast rhs)))
                        (list "(" lhs  " or " rhs ")")))
       (((or 'and '== '!=) lhs rhs) (let ((lhs (csp-transform ast lhs))
                                          (rhs (csp-transform ast rhs))
                                          (op (car src)))
                                      (list lhs " " op " " rhs )))
       (('value type field) (list type "_" field))
       (('literal scope type value) (list type "_" value))
       (('context (vars var ('valued-action ('value port event))) stat)
        (let ((stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list port "!" event "  -> " port "?" var " -> " 'context "(\\(" (comma-join vars) ") @ " var ",\n" stat ")" )))
       (('context (vars var expression) stat)
        (let ((expression (csp-transform ast expression))
              (stat (csp-transform ast stat inevitable-optional? channel provided-on?)))
          (list 'context "(\\(" (comma-join vars) ") @ " expression "," stat ")" )))
       (('semi stat1 stat2)
        (let ((first (csp-transform ast stat1 inevitable-optional? channel provided-on?))
              (second (csp-transform ast stat2 inevitable-optional? channel provided-on?)))
          (list "semi(" first ",\n" second ")")))
       ('() "(\\P',V' @ P'(V'))")
       ((? symbol?) src)
       (_ (throw 'match-error (format #f "~a:csp-transform: no match: ~a\n" (current-source-location) src)))))))
