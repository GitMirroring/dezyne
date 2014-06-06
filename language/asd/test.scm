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
(define (*api-class*) (map ->string (list (*module*) (*api*))))
(define (*callback-class*) (map ->string (list (*module*) (*callback*))))

(define (*scoped-api*) (map ->string (list "port" (*module*) (*api*))))

(define (port-events port)  ;;; FIXME
  (case (port-name port) 
    ((console) '((in void arm) (in void disarm) (out void detected (out void deactivated))))
    ((sensor) '((in void enable) (in void disable) (out void triggered (out void disabled))))
    ((siren) '((in void turnon) (in void turnoff)))))

(define (*api*) 'API)
(define (*callback*) 'CB)
(define (*ap*) 'api)
(define (*cb*) 'cb)

(define (comma-join lst) (string-join (map symbol->string lst) ", "))

(define (enum->string enum)
  (->string (list " Enum {" (comma-join (enum-elements enum)) " };\n")))

(define (*enums*) (->string (map enum->string (interface-types (interface ast)))))


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

   ;;*scoped-api*
   *type*
   *return-interface-type*
   ))

(define (*instance-getters*)
   (map (lambda (x) (list "  virtual void " (port-name x) "() = 0;\n")) (filter port-provides? (component-ports (component ast))))
  )

(define (map-ports string ports)
  (map (lambda (port)
         (let ((module (c++-module ast)))
           (module-define! module '*interface* (lambda () (port-name port)))
           (module-define! module 'port port)
           (module-define! module '*port* (lambda () (port-name port)))
           (animate-string string module))) ports))

(define (map-events string events)
  (map (lambda (event)
         (let ((module (c++-module ast)))
           (module-define! module '*event* (lambda () (event-name event)))
           (module-define! module '*interface* (lambda () (port-name port)))
           (module-define! module '*type* (lambda () (event-type event)))
           (animate-string string module))) events))

(define (map-port-events string port events)
  (map (lambda (event)
         (let ((module (c++-module ast)))
           (module-define! module '*event* (lambda () (event-name event)))
           (module-define! module '*interface* (lambda () (port-name port)))
           (module-define! module '*type* (lambda () (event-type event)))
           (animate-string string module))) events))
