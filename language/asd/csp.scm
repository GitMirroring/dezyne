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
  :use-module (ice-9 optargs)
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (language asd animate)
  :use-module (language asd ast:)
  :use-module (language asd c++)
  :use-module (language asd misc)
  :use-module (language asd reader)
  :export (
           asd->
           port-triggers
           ))

(define *ast* '())

(define (asd-> ast)
  (set! *ast* ast)
  (module-define! (resolve-module '(language asd csp)) 'ast ast)  ;; FIXME
  (module-define! (resolve-module '(language asd c++)) 'ast ast)  ;; FIXME
  (and-let* ((comp (ast:component ast))
             (name (ast:name comp)))
            (animate-file 'templates/component.csp.scm (list name '.csp) (csp-module ast)))
  "")

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
			      (module-define! module '*guard-def* guard)
;;; fixme
			      (module-define! (resolve-module '(language asd csp)) '*guard* (lambda () (guard-name guard)))
			      (module-define! (resolve-module '(language asd csp)) '*guard-def* guard)
			      (animate-string string module))))) guards))))

(define (map-on-events string events)
  (display
   (externalchoice-join (map
		  (lambda (event)
		    (with-output-to-string
		      (lambda ()
			(let* ((module (current-module))
			       (.interface (module-ref module '.interface))
			       (interface (ast:ast .interface))
			       (component (module-ref module 'component))
			       (channel (module-ref module '.port))
			       (guard (module-ref module 'guard)))
			  (module-define! module '.event (car event))
			  (module-define! module '.csp-transition (csp-transition interface guard event))
			  (module-define! module '.csp-transition-component (csp-transition-component component channel guard event ))
			  (animate-string string module))))) events))))

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
  (interface-triggers (ast:ast (ast:type port))))

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
          (loop (cdr ports) (append values (apply append (map ast:elements (ast:body (ast:types (ast:behaviour (ast:ast (ast:type (car ports))))))))))))))

(define (interface-triggers interface)
  (delete-duplicates (sort (append (map ast:identifier (ast:body (ast:events interface))) (apply append (map behaviour-triggers (ast:body (ast:statements (ast:behaviour interface)))))) symbol<)))

(define* (behaviour-triggers src :optional (triggers '()))
  (match src
   (('statements t ...) (append (apply append (map behaviour-triggers t)) triggers))
    (('on triggers statements) triggers)
    (('guard expression statements) (behaviour-triggers statements triggers))))

(define* (action-bla statement module event actuals :optional (top? #t))
  (let* ((channel (ast:name module))
	 (behaviour(ast:name (ast:behaviour module)))
	 (start (list channel "?x:{" (comma-join event)  "} -> "))
	 (return (if (or (member 'inevitable event) (member 'optional event)) "" (list channel ".return -> ")))
	 (end (list return channel "_" behaviour "_((" (comma-join actuals) "))\n"))
	 (illegal? #f)
	 (body 
	  (match statement
	    (('statements tail ...) (map (lambda (statement) (action-bla statement module event actuals #f)) tail))
	    ('(action illegal) (set! illegal? #t) (->string (list "illegal -> STOP \n")))
	    (('action name) (->string (list channel "." name " -> " )))
	    (('assign name value) "")
	    (_ (stderr "catch-all: foobar!~a\n" statement) ""))))
    (if top? 
	(list (if illegal? "IG & " "") start body (if (not illegal?) end ""))
	(list body))))

(define (assign-bla statement channel event . key-vals)
  (match statement
    (('statements tail ...) (apply append (map (lambda (statement) (assign-bla statement channel event)) tail)))
    (('assign key val) (cons (cons key (value val)) key-vals))
    (_ '())))

(define (var-names module) 
  (map ast:identifier (ast:body (ast:variables (ast:behaviour module)))))

(define (csp-transition module guard event)
  (let* ((on (ast:statements-on (ast:body (ast:statements guard))))
	 (event-on (find (lambda (x) (let ((triggers (cadr x)))
				       (equal? event triggers))) on))
	 (statement (ast:statements event-on))
	 (names (var-names module))
	 (assignments (assign-bla statement (ast:name module) event))
	 (actuals (state-vector assignments (map (lambda (x) (cons x x)) names))))
   (action-bla statement module event actuals)))

(define* (action-bla-component statement module channel event actuals :optional (top? #t))
  (let* ((behaviour(ast:name (ast:behaviour module)))
         (thing (if (pair? (car event)) (cadar event) (car event)))
	 (start (list thing "?x:{" (comma-join (map (lambda (x) (if (pair? x) (caddr x) x)) event))  "} -> "))
	 (xreturn (if (provides? (car event)) (->string (list channel ".return -> ")) ""))
	 (return (if (or (member 'inevitable event) (member 'optional event)) "" (list xreturn "transition_end -> ")))
	 (end (list return (ast:name module) "_" behaviour "_((" (comma-join actuals) "))\n"))
	 (illegal? #f)
	 (body
	  (match statement
	    (('statements tail ...) (map (lambda (statement) (action-bla-component statement module channel event actuals #f)) tail))
	    ('(action illegal) (set! illegal? #t) (->string (list "illegal -> STOP \n")))
	    (('action name) (->string (list (->string name) " -> " (if (provides? name) "" (list (if (pair? name) (cadr name) name) ".return -> ")))))
	    (('assign name value) "")
	    (_ (stderr "catch-all: foobar!~a\n" statement) ""))))
    (if top? 
	(list (if illegal? (if (provides? (car event)) "IIG & " "IG & ") "") start body (if (not illegal?) (->string end) ""))
	(list body))))

(define (provides? x) (and (pair? x) (eq? (cadr x) 'console)))

(define (csp-transition-component module channel guard event)
  (let* ((on (ast:statements-on (ast:body (ast:statements guard))))
         (foobar1 (stderr "on:~a\n" on))
	 (event-on (find (lambda (x) (let ((triggers (cadr x)))
				       (equal? event triggers))) on))
	 (foobar2 (stderr "event-on~a\n" event-on))
	 (statement (ast:statements event-on))
	 (foobar3 (stderr "statement:~a\n" statement))
	 (names (var-names module))
	 (assignments (assign-bla statement (ast:name module) event))
	 (actuals (state-vector assignments (map (lambda (x) (cons x x)) names))))
    (receive (provides requires) (partition provides? event) 
      (if (and (null? provides) (null? requires)) 
	  (action-bla-component statement module channel event actuals)
	  (append (if (pair? provides) (action-bla-component statement module channel provides actuals) '())
		  (if (and (pair? provides) (pair? requires)) (list "\n  []\n  ") (list ""))
		  (if (pair? requires) (action-bla-component statement module channel requires actuals) '()))))))

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
    (if (member 'optional (interface-triggers (ast:ast (ast:type port))))
        (list "[|{" interface " .optional}|] " "CHAOS({" interface " .optional})")        
        "")))

(define (->string src)
  (match src
    (('field struct name) (->string (list struct "." name)))
    (_ ((@ (language asd misc) ->string) src))))
