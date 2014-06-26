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
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (ice-9 receive)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (language asd animate)
  :use-module (language asd ast:)
  :use-module (language asd c++)
  :use-module (language asd misc)
  :use-module (language asd reader)
  :use-module (language asd normstate)
  :export (
           asd->
           port-triggers
           ))

(define (asd-> ast)
  (let ((norm (normstate ast)))
    (module-define! (resolve-module '(language asd csp)) 'ast norm)  ;; FIXME
    (module-define! (resolve-module '(language asd c++)) 'ast norm)  ;; FIXME
    (and-let* ((comp (ast:component norm))
	       (name (ast:name comp)))
	      (animate-file 'templates/component.csp.scm (list name '.csp) (csp-module norm))))
  "")

(define (ast-norm module-name) (let ((ast (car (ast:read-ast module-name)))) (normstate ast)))

(define (csp-module ast)
  (let ((module (make-module 31 (list
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(language asd ast:))
                                 (resolve-module '(language asd c++))
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

(define (externalchoice-join lst) (string-join (map ->string lst) "[]\n"))
(define (separator-join lst separator) (string-join (map ->string (filter (negate string-null?) lst)) separator))

(define* (csp-map-ports string ports :optional (separator ""))
  (display
   (separator-join (map (lambda (port)
			(with-output-to-string
			  (lambda ()
			    (save-module-excursion
			     (lambda ()
			       (let ((module (csp-module ast)))
				 (module-define! module 'port port)
				 (module-define! module '.optional-chaos (optional-chaos port))
				 (module-define! module '.interface (ast:type port)) ;; fixme
				 (module-define! module '.name (ast:identifier port))
				 (module-define! module '.port (ast:identifier port))
				 (module-define! module '.behaviour (ast:name (ast:behaviour port)))
				 (animate-string string module))))))) ports) separator)))

(define (map-guards string guards)
  (display
   (externalchoice-join (map (lambda (guard)
			(with-output-to-string
			  (lambda ()
			    (let ((module (current-module)))
			      (module-define! module 'guard guard)
			      (animate-string string module))))) guards))))


(define (map-on-events string events)
  (display
   (externalchoice-join (map
		  (lambda (event)
		    (with-output-to-string
		      (lambda ()
			(let* ((module (current-module))
			       (.interface (module-ref module '.interface))
			       (interface (ast-norm .interface))
			       (component (module-ref module 'component))
			       (channel (module-ref module '.port))
			       (guard (module-ref module 'guard)))
			  (module-define! module '.event (car event))
			  (module-define! module 'event event)
			  (module-define! module 'channel channel) ;; d'oh
			  ;;(module-define! module '.csp-transition (csp-transition interface guard event))
			  (module-define! module '.csp-transition (->string (csp-transition interface guard event)))
			  (animate-string string module))))) events))))

(define* (map-statements-on string statements :optional (separator ""))
  (display
   (separator-join
    (map
     (lambda (on-statement)
       (with-output-to-string
         (lambda ()
           (let* ((module (current-module))
                  (.interface (module-ref module '.interface))
                  (interface (ast-norm .interface))
                  (component (module-ref module 'component))
                  (channel (module-ref module '.port))
                  (.channel (module-ref module '.port))
                  (guard (module-ref module 'guard))
                  (events (ast:events on-statement))
                  (.event-port (if (pair? (car events)) (cadar events) (car events)))
                  (statement (ast:statement on-statement))
                  (module-ast (if (eq? .channel .interface) interface component))
                  (module-name (ast:name module-ast))
                  (assignments (assign-prefix statement (ast:type (ast:port component )) events))
                  (names (var-names component))
                  (actuals (state-vector assignments (map (lambda (x) (cons x x)) names)))
;;                  (action-prefix (action-prefix-component statement component channel events actuals))
                  (illegal? (prefix-illegal? statement))
                  (actions (prefix-actions statement)))

             (module-define! module '.channel channel)
             (module-define! module '.events (comma-join (map ->string events)))
             (module-define! module 'actions actions)
             (module-define! module 'actuals actuals)
             (module-define! module 'channel channel)
             (module-define! module 'events events)
             (module-define! module 'illegal? illegal?)
             (module-define! module '.module module-name)
             (module-define! module '.event-port .event-port)
             (module-define! module 'names names)
             (module-define! module 'provides-event? (provides? (car events)))
             (module-define! module 'statement statement)
             (animate-string string module))))) statements) separator)))

(define (csp-expression->string expression)
  (match expression
    (('field type identifier) (list type " == " identifier))
    ((? symbol?) expression)
    (('and lhs rhs) (->string (list (csp-expression->string lhs) " and " (csp-expression->string rhs))))
    (('! expression) (->string (list "not " (csp-expression->string expression))))
    (_ (format #f "~a:NO MATCH: ~a" (current-source-location) expression))))

(define (symbol< a b) (string< (symbol->string a) (symbol->string b)))
(define-public (flatten x)
  "unnest list."
  (let loop ((x x) (tail '()))
    (cond ((list? x) (fold-right loop tail x))
          ((not (pair? x)) (cons x tail))
          (else (loop (car x) (loop (cdr x) tail))))))

(define (->join lst infix) (string-join (map ->string lst) infix))
(define (pipe-join lst) (->join lst " | "))

(define (port-triggers port)
  (interface-triggers (ast-norm (ast:type port))))

(define (event-names ports)
  (let loop ((ports ports) (events '()))
    (if (null? ports)
        events
        (loop (cdr ports) (append events (map ast:identifier (ast:body (ast:events (car ports)))))))))

(define (enum-values comp)
  (let ((comp-values (apply append (map ast:elements (ast:body (ast:types (ast:behaviour comp)))))))
    (let loop ((ports (ast:body (ast:ports comp))) (values comp-values))
      (if (null? ports)
          values
          (loop (cdr ports) (append values (apply append (map ast:elements (ast:body (ast:types (ast:behaviour (ast-norm (ast:type (car ports))))))))))))))

(define (interface-triggers interface)
  (delete-duplicates (sort (append (map ast:identifier (ast:body (ast:events interface))) (apply append (map behaviour-triggers (ast:body (ast:statement (ast:behaviour interface)))))) symbol<)))

(define* (behaviour-triggers src :optional (triggers '()))
  (match src
   (('compound t ...) (append (apply append (map behaviour-triggers t)) triggers))
    (('on triggers statements) triggers)
    (('guard expression statements) (behaviour-triggers statements triggers))
    (_ (stderr "~a: NO MATCH: ~a\n" (current-source-location) src) "")))

(define* (action-prefix statement module event actuals :optional (top? #t))
  (let* ((channel (ast:name module))
	 (behaviour(ast:name (ast:behaviour module)))
	 (start (list channel "?x:{" (comma-join event)  "} -> "))
	 (return (if (or (member 'inevitable event) (member 'optional event)) "" (list channel ".return -> ")))
	 (end (list return channel "_" behaviour "_((" (comma-join actuals) "))\n"))
	 (illegal? #f)
	 (body
	  (match statement
	    (('compound tail ...) (map (lambda (statement) (action-prefix statement module event actuals #f)) tail))
	    ('(action illegal) (set! illegal? #t) (->string (list "illegal -> STOP\n")))
	    (('action name) (->string (list channel "." name " -> " )))
	    (('assign name value) "")
	    (_ ""))))
    (if top?
	(list (if illegal? "IG & " "") start body (if (not illegal?) end ""))
	(list body))))

(define (assign-prefix statement channel event . key-vals)
  (match statement
    (('compound tail ...) (apply append (map (lambda (statement) (assign-prefix statement channel event)) tail)))
    (('assign key val) (cons (cons key (value val)) key-vals))
    (_ '())))

(define (var-names module)
  (map ast:identifier (ast:body (ast:variables (ast:behaviour module)))))

(define (csp-transition module guard event)
  (let* ((on ((ast:statements-of-type 'on) (ast:statement guard)))
	 (event-on (find (lambda (x) (let ((triggers (cadr x)))
				       (equal? event triggers))) on))
	 (statement (ast:statement event-on))
	 (names (var-names module))
	 (assignments (assign-prefix statement (ast:name module) event))
	 (actuals (state-vector assignments (map (lambda (x) (cons x x)) names))))
   (action-prefix statement module event actuals)))

(define (toplevel-define! name val)
  (module-define! (current-module) name val)
  (export name))

(define ((statement-on-p/r predicate) statement-on)
  (let* ((events (ast:events statement-on))
         (events-predicate (filter predicate events))
         (statement (ast:statement statement-on)))
  (if (pair? events-predicate)
      (ast:make 'on events-predicate statement)
      #f)))

(define (action->string action)
  (let ((name (cadr action)))
    (if (pair? name) (cadr name) name)))

(define (event->string event)
  (if (pair? event) (caddr event) events))

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

(define (provides? x) (and (pair? x) (eq? (cadr x) 'console)))
(define (requires? x) (not (provides? x)))

(define (state-vector assignments formals)
  (let loop ((assignments assignments) (formals formals))
    (if (null? assignments)
	(map cdr formals)
	(let* ((assign (car assignments))
	       (name (car assign))
	       (value (cdr assign)))
	  (loop (cdr assignments) (assoc-set! formals name value))))))

(define (underscore-join lst) (string-join (map ->string lst) "_"))

(define (value ast)
  (match ast
    ((? ast:field?) (caddr ast))
    (_ ast)))

(define (optional-chaos port)
  (let ((interface (ast:type port)))
    (if (member 'optional (interface-triggers (ast-norm (ast:type port))))
        (list "[|{" interface " .optional}|] " "CHAOS({" interface " .optional})")
        "")))

(define (->string src)
  (match src
    (('field struct name) (->string (list struct "." name)))
;;    (_ (stderr "NO MATCH: ~a\n" src) (format #f "~a" src))
    (_ ((@ (language asd misc) ->string) src))))
