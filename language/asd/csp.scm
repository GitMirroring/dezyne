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
	      (module-define! module '.interface (ast:name (ast:interface ast)))
	      (module-define! module '.behaviour (ast:name (ast:behaviour comp)))
              (module-define! module '.interface-behaviour (ast:name (ast:behaviour (ast:interface ast))))
	      (module-define! module '.port (ast:identifier (ast:port comp))))
    module))

(define (bracket-join lst) (string-join (map ->string lst) "[]\n"))

(define (map-guards string guards)
  (display
   (bracket-join (map (lambda (guard)
			(with-output-to-string
			  (lambda ()
			    (let ((module (current-module)))
			      (module-define! module 'guard guard)
			      (module-define! module '*guard-def* guard)
;;; FIXME
			      (module-define! (resolve-module '(language asd csp)) '*guard* (lambda () (guard-name guard)))
			      (module-define! (resolve-module '(language asd csp)) '*guard-def* guard)
			      (animate-string string module))))) guards))))

(define (map-on-events string events)
  (display
   (bracket-join (map
		  (lambda (event)
		    (with-output-to-string
		      (lambda ()
			(let* ((module (current-module))
			       (.interface (module-ref module '.interface))
			       (interface (ast:interface (module-ref module 'ast)))
			       (guard (module-ref module 'guard)))
			  (module-define! module '.event (car event))
			  (module-define! module '.csp-transition (csp-transition interface guard event ))
			  (animate-string string module))))) events))))

(define (symbol< a b) (string< (symbol->string a) (symbol->string b)))
(define-public (flatten x)
  "Unnest list."
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

(define (action-bla statement channel event)
(stderr "bla: ~a\n" statement)
  (match statement
    (('statements tail ...) (map (lambda (statement) (action-bla statement channel event)) tail))
    ('(action illegal) (->string (list "IG & " channel "?x:{" (comma-join event)  "} -> illegal -> STOP \n")))
    (('action name) (->string (list channel "?x:{" (comma-join event)  "} -> " channel "." name " -> " "\n")))
    (('assign name) '())
    (_ (->string (list channel "?x:{" (comma-join event)  "} -> \n")))))

(define (assign-bla statement channel event . key-vals)
(stderr "bla: ~a\n" statement)
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
	(assign-key-vals (assign-bla statement (ast:name module) event))
)
   (action-bla statement (ast:name module) event)))
 
(define (underscore-join lst) (string-join (map ->string lst) "_"))

(define (value ast)
  (match ast
    ((? ast:field?) (caddr ast))
    (_ ast)))
