;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
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

(define-module (language asd test)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (srfi srfi-1)
  :use-module (language asd ast)
  :use-module (language asd misc)
  :use-module (language asd format-keys)
  :use-module (language asd snippets)
  :export (asd->))

(define (->string-map-format-keys ast) 
  (string-map-format-keys
   "%{port}---%{interface} %{ports}---%{direction}*****%{events} %{event-direction}\n"
   `((interface . ,port-interface)
     (port . ,port-name))
   (component-ports (component ast))))

(define (->format-at ast) 
  (format-at-keys
   "class foo\n{\n @{ports}---void %{name} %{direction}();\n@{ports}\n};\n"
   `((ports . (((name . ,identity)
                (direction . ,port-direction))
               . ,(component-ports (component ast)))))))

(define (asd-> ast)
  ;; (module-define! (current-module) 'ast ast) ;; FIXME
  (module-define! (resolve-module '(language asd test)) 'ast ast)  ;; FIXME
  (if (interface ast)
      (animate-string (gulp-text-file "examples/interface.hh.scm") (c++-module ast)))
  (if (component ast)
      (animate-string (gulp-text-file "examples/component.cc.scm") (c++-module ast)))
  "")

(define (c++-module ast)
  (let ((module (make-module 31 (list 
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(language asd ast))
                                 (resolve-module '(language asd test))))))
    (module-define! module 'ast ast)
    module))

(define (animate-string string module)
  (let ((escape (string-index string #\%)))
    (display (if escape (string-take string escape) string))
    (if escape
        (let* ((port (open-input-string (string-drop string (1+ escape))))
               (expression (read port))
               (skip (ftell port)))
          (close-input-port port)
          ;;(stderr "found expression: >>>>~a\n<<<" expression)
          (display (->string (eval expression module)))
          (animate-string (string-drop string (+ escape skip 1)) module))
        "")))





;;;;;;;;;;FIXME experimental C++ output
(define ast '())



;;;; INTERFACE

(define (*module*)
  (if (interface ast) (*interface*) (*component*)))

(define (*interface*) (interface-name (interface ast)))

(define (*api*) (or (and (or (not (defined? '*port-def*)) (port-provides? *port-def*)) 'API) 'CB))
(define (*callback*) (stderr "*callback*: port-def: ~a\n" (or (and (defined? '*port-def*) *port-def*) "no port" ))
  (or (and (or (not (defined? '*port-def*)) (port-provides? *port-def*)) 'CB) 'API)
  )
(define (*ap*) (or (and (or (not (defined? '*port-def*)) (port-provides? *port-def*)) 'api) 'cb))
(define (*cb*) (or (and (or (not (defined? '*port-def*)) (port-providesc? *port-def*)) 'cb) 'api))

(define (*if-type*) (if (port-typed-event? *port-def*) "" "#if 0"))
(define (*else-type*) (if (port-typed-event? *port-def*) "" "#else"))
(define (*endif-type*) (if (port-typed-event? *port-def*) "" "#endif"))

(define (->join lst infix) (string-join (map ->string lst) infix))
(define (comma-join lst) (->join lst ", "))
(define (double-colon-join lst) (->join lst "::"))

(define (enum->string enum)
  (->string (list "enum "  (enum-name enum) " { " (comma-join (enum-elements enum)) " };\n")))

;;;; COMPONENT
(define (*component*) (component-name (component ast)))

(for-each 
 (lambda (x) (module-define! (current-module) x (lambda () (->string (list "/" x "/")))))
 '(
   *proxy-classes*
   *state-class*
   *context-class*
   *component-class*
   *proxy-methods*
   *context-methods*
   *component-methods*
   *state-methods*
   *function-definitions*
   *function-declarations*

  *type*
   *return-interface-type*
   *instances*
   *behaviour*
   *no-dpc*
   *state-type*
   *name*
   *value*
   ))

(define (return-type-text port)
  (or (and-let* ((event (null-is-#f (port-typed-event? *port-def*))))
                (event-type event))
      'void))

(define (map-ports string ports)
  (map (lambda (port)
         (let ((module (c++-module ast)))
           (module-define! module '*interface* (lambda () (port-interface port)))
           (module-define! module 'port port)
           (module-define! module '*port* (lambda () (port-name port)))
           (module-define! module '*port-def* port)
           (module-define! module '*type* (lambda () (return-type-text port)))

           ;;; FIXME
           (module-define! (resolve-module '(language asd test)) '*port* (lambda () (port-name port)))
           (module-define! (resolve-module '(language asd test)) '*port-def* port)
           (animate-string string module))) ports))

(define (string-if condition then else)
  (animate-string (if condition then else) (current-module)))

(define (variable-value->string v)
  (case (variable-type v)
    ((bool) (->string (variable-initial-value v)))
    (;;(enum)
     else
     (double-colon-join (append (list (*module*)) 
                                (cdr (variable-initial-value v)))))))

(define (variable-state-type v)
  (case (variable-type v)
    ((bool) (->string (variable-type v)))
    (;;(enum)
     else (double-colon-join (list 'State (variable-type v))))))

(define (map-events string events)
  (map (lambda (event)
         (let ((module (c++-module ast)))
           (module-define! module '*event* (lambda () (event-name event)))
           (module-define! module '*interface* (lambda () (port-interface port)))
           (if (defined? '*port*)
               (module-define! module '*port* *port*)
               (stderr "map-events: *port* not defined?"))
           (if (defined? '*port-def*)
               (module-define! module '*port-def* *port-def*)
               (stderr "map-events: *port-def* not defined?"))
           (module-define! module '*type* (lambda () (event-type event)))
           (animate-string string module))) events))

(define (map-port-events string port events)
  (map (lambda (event)
         (let ((module (c++-module ast)))
           (module-define! module '*event* (lambda () (event-name event)))
           (module-define! module '*interface* (lambda () (port-interface port)))
           (module-define! module '*port* (lambda () (port-name  port)))
           (module-define! module '*port-def* port)
           (module-define! module '*type* (lambda () (event-type event)))
           (animate-string string module))) events))

(define (map-variables string variables)
  (map (lambda (variable)
         (let ((module (c++-module ast))
               (behaviour (component-behaviour (component ast)))
               (name (variable-name variable)))

           (stderr "map-variables: variable: ~a\n" variable)
           (module-define! module '*interface* (lambda () *module*))
           (module-define! module 'variable variable)
           (module-define! module '*variable* (lambda () name))
           (module-define! module '*variable-def* variable)
           (module-define! module '*type* (lambda () (return-type-text variable)))


           (module-define! module '*state-type* (lambda () (variable-state-type variable)))           
           (module-define! module '*name* (lambda () (return-type-text variable)))           
           (module-define! module '*value* (lambda () (variable-value->string variable)))




           ;;; FIXME
           (module-define! (resolve-module '(language asd test)) '*variable* (lambda () (variable-name variable)))
           (module-define! (resolve-module '(language asd test)) '*variable-def* variable)
           (animate-string string module))) variables))

