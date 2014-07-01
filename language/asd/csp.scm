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
	   csp-transform-on
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
    ((component deadlock)  . "assert #.component _#.behaviour _Component :[deadlock free]\n")
    ((component deterministic) . "assert #.component _#.behaviour(true,true) :[deterministic]\n")
    ((component illegal) . "assert STOP [T= #.component _#.behaviour _Component \\ diff(Events,{illegal})\n")
    ((component compliance) . ,(gulp-file 'templates/asserts/component-compliance.csp.scm))
    ((interface deadlock) . ,(gulp-file 'templates/asserts/interface-deadlock.csp.scm))
    ((interface livelock) . ,(gulp-file 'templates/asserts/interface-livelock.csp.scm))))

(define (ast-norm module-name)
  (ast:ast module-name normstate))

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
	      (module-define! module '.port (ast:identifier (ast:port comp))))
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
                     (.optional-chaos . ,optional-chaos)
                     (.interface . ,ast:type) ;; FIXME
                     (.name . ,ast:identifier)
                     (.port . ,ast:identifier)
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

(define* (map-statements-on string statements :optional (separator ""))
  (display
   ((->join separator)
    (map
     (lambda (on-statement)
       (with-output-to-string
         (lambda ()
           (let* ((module (current-module))
                  (.interface (module-ref module '.interface))
                  (interface (ast-norm .interface))
                  (component (module-ref module 'component))
                  (events (ast:events on-statement))
                  (.event (car events))
                  (interface? (not (pair? (car events))))
                  (module-ast (if interface? interface component))
                  (statement (ast:statement on-statement))
                  (assignments (assign-prefix statement (ast:type (ast:port component)) events))
                  (names (var-names module-ast))
                  (actuals (state-vector assignments (map (lambda (x) (cons x x)) names))))
             (animate-string
              string
              (animate-module-populate
               (current-module)
               on-statement
               `((.channel . ,(module-ref module '.port))
                 (.events . ,(comma-join (map ->string events)))
                 (actions . ,(compose prefix-actions ast:statement))
                 (actuals . ,actuals)
                 (channel . ,(module-ref module '.port))
                 (events . ,ast:events)
                 (.event . ,(compose car ast:events))
                 (illegal? . ,(compose prefix-illegal? ast:statement))
                 (inevitable-optional? . ,(or (member 'inevitable events)
                                              (member 'optional events)))
		 (interface . ,interface)
                 (.module . ,(ast:name module-ast))
                 (.event-port . ,(if interface? (car events) (cadar events)))
                 (names . ,names)
                 (provides-event? . ,(compose (provides? (if interface? interface component)) car ast:events))
                 (statement . ,ast:statement))))))))
     statements))))

(define (csp-expression->string expression)
  (match expression
    (('field type identifier) (list type " == " identifier))
    ((? symbol?) expression)
    (('and lhs rhs) (->string (list (csp-expression->string lhs) " and " (csp-expression->string rhs))))
    (('! expression) (->string (list "not " (csp-expression->string expression))))
    (_ (format #f "~a:NO MATCH: ~a" (current-source-location) expression))))

(define (port-triggers port)
  (sort ((ast:find-events) (ast-norm (ast:type port))) symbol<))

(define (enum-values comp)
  (let ((comp-values (apply append (map ast:elements (ast:body (ast:types (ast:behaviour comp)))))))
    (let loop ((ports (ast:body (ast:ports comp))) (values comp-values))
      (if (null? ports)
          values
          (loop (cdr ports) (append values (apply append (map ast:elements (ast:body (ast:types (ast:behaviour (ast-norm (ast:type (car ports))))))))))))))

(define (assign-prefix statement channel event . key-vals)
  (match statement
    (('compound tail ...) (apply append (map (lambda (statement) (assign-prefix statement channel event)) tail)))
    (('assign key val) (cons (cons key (value val)) key-vals))
    (_ '())))

(define (var-names module)
  (map ast:identifier (ast:body (ast:variables (ast:behaviour module)))))

(define ((statement-on-p/r predicate) statement-on)
  (let* ((events (ast:events statement-on))
         (events-predicate (filter predicate events))
         (statement (ast:statement statement-on)))
  (if (pair? events-predicate)
      (ast:make 'on events-predicate statement)
      #f)))

(define (event->string event)
  (if (pair? event) (caddr event) event))

(define (prefix-actions statement)
  (match statement
    (('compound tail ...) (let loop ((statements tail))
                            (if (null? statements)
                                '()
                                (let ((action (prefix-actions (car statements))))
                                  (if (null? action)
                                      (loop (cdr statements))
                                      (cons action (loop (cdr statements))))))))
    ('(action illegal) '())
    (('action name) name)
    (_ '())))

(define (prefix-illegal? statement)
  (match statement
    (('compound tail ...) (let loop ((statements tail))
                            (if (null? statements)
                                #f
                                (or (prefix-illegal? (car statements)) (loop (cdr statements))))))
    ('(action illegal) #t)
    (_ #f)))

(define (((provides-or-requires? type) component) event)
  (if (ast:component? component)
      (pair?
       (filter
	(lambda (port) (and (equal? type (car port)) (equal? (if (pair? event) (cadr event) event) (caddr port))))
	((compose ast:body ast:ports) component)))
      #f))

(define ((provides? component) event)
  (((provides-or-requires? 'provides) component)  event))

(define ((requires? component) event)
  (((provides-or-requires? 'requires) component)  event))

(define (state-vector assignments formals)
  (let loop ((assignments assignments) (formals formals))
    (if (null? assignments)
	(map cdr formals)
	(let* ((assign (car assignments))
	       (name (car assign))
	       (value (cdr assign)))
	  (loop (cdr assignments) (assoc-set! formals name value))))))

(define (value ast)
  (match ast
    ((? ast:field?) (caddr ast))
    (_ ast)))

(define (optional-chaos port)
  (let ((interface (ast:type port)))
    (if (member 'optional ((ast:find-events) (ast-norm (ast:type port))))
        (list "[|{" interface " .optional}|] " "CHAOS({" interface " .optional})")
        "")))

(define (->string src)
  (match src
    (('field struct name) (->string (list struct "." name)))
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

(define* (csp-transform-on ast src :optional (return #t))
  (let ((variables (var-names (ast:interface ast))))
    (match src
      (('compound t ...) 
       (let loop ((statements (map (lambda (x) (csp-transform-on ast x #f)) t)))
	 (if (null? statements)
	     '()
	     (if (>1 (length statements))
		 (list 'semi (car statements) (loop (cdr statements)))
		 (car statements)))))
      (('on events stat) 
       (let ((result (csp-transform-on ast stat)))
      	 (if (null? result)
      	     (list 'on events (list 'return variables))
      	     (list 'on events result (list 'return variables)))))
      (('assign var ('field type val)) (list 'assign variables (map (lambda (x) (if (eq? x var ) val x)) variables)))
      (('assign var exp) (list 'assign variables (map (lambda (x) (if (eq? x var ) exp x)) variables)))
      (('if pred then) (list 'if variables (list 'expression pred) (csp-transform-on ast then return) '()))
      (('if pred then else) (list 'if variables (list 'expression pred) (csp-transform-on ast then return) (csp-transform-on ast else return)))
      (_ src))))
