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

(define (->string src) 
  (match src
    (#f "false")
    (#t "true")
    ((? string?) src)
    ((? symbol?) (symbol->string src))
    ((h ... t) (apply string-append (map ->string src)))
    (_ "")))

(define (asd-> ast)
  (let* ((module (make-module 31 (list 
                                  (resolve-module '(ice-9 match))
                                  (resolve-module '(language asd ast))))))
    (module-define! module 'ast ast)
    (module-define! module '->string ->string)
    (string-eval (gulp-text-file "examples/interface.hh.scm") module)))

(define (string-eval string module)
  (let ((escape (string-index string #\%)))
    (display (if escape (string-take string escape) string))
    (if escape
        (let* ((port (open-input-string (string-drop string (1+ escape))))
               (expression (read port))
               (skip (ftell port)))
          (close-input-port port)
          ;;(stderr "found expression: >>>>~a\n<<<" expression)
          (display (->string (eval expression module)))
          (string-eval (string-drop string (+ escape skip 1)) module))
        "")))
