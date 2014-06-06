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

(define-module (language asd c++)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)
  :use-module (language asd misc)
  :use-module (language asd ast)
  :use-module (language asd format-keys)
  :use-module (language asd snippets)
  :export (asd-> asd->c++))

(define hh "h")
(define cc "cpp")

(define (format-snippet name pairs) 
  (format-keys (gulp-snippet name) pairs))

(define (gulp-snippet name)
  (gulp-text-file (string-join (map symbol->string `(snippets c++ ,name)) "/")))

(define (generate-component-header component)
  (dump-file 
   (format #f "~aComponent.~a" (component-name component) hh)
   (let ((bottom? (component-bottom? component)))
     (format-keys (gulp-snippet (if bottom? 
                                    'component-header-bottom 'component-header))
                  `((component . ,(component-name component))
                    (port-includes . ,(string-map-format-keys
                                       (gulp-snippet 'component-header-includes-port)
                                       `((interface . ,(lambda (port) (cadr port))))
                                       (component-ports component)))
                    (interface . ,(component-interface component))
                    (port-methods . ,(if bottom?
                                         ""
                                         (format-ports component 'component-header-port))))))))

(define (API port)
    (if (eq? 'provides (port-direction port))
      'API 'CB))

(define (CB port)
  (if (eq? 'provides (port-direction port))
      'CB 'API))

(define (api port)
    (if (eq? 'provides (port-direction port))
      'api 'cb))

(define (cb port)
  (if (eq? 'provides (port-direction port))
      'cb 'api))

(define (format-ports component snippet)
  (string-map-format-keys
   (gulp-snippet snippet)
   `((api-class . ,(lambda (x) "%{interface}%{api}"))
     (callback-class . ,(lambda (x) "%{interface}%{callback}"))
     (ap . ,api)
     (cb . ,cb)
     (api . ,API)
     (callback . ,CB)
     (component . ,(lambda (x) (component-name component)))
     (interface . ,port-interface)
     (port . ,port-name))
   (component-ports component)))

(define (generate-enum component enum)
  (format-keys (gulp-snippet 'component-enum)
               `((state-type . ,(type-name-component enum component))
                 (elements . ,(string-map-format-keys 
                               (gulp-snippet 'enum-element)
                               `((name . ,identity))
                               (enum-elements enum))))))

(define (expression->string e)
  (match e
    ((? c++-snippet?) (apply c++-snippet->string e))
    ((? symbol?) (symbol->string e))
    (_ (format #f "\nNO MATCH:~a\n" e))))

(define (c++-snippet? x)
  (parameterize ((snippets c++-snippets)) (snippet? x)))

(define (c++-snippet->string . x)
  (parameterize ((snippet-dir c++-snippet-dir) (snippets c++-snippets))
    (apply snippet->string x)))

(define c++-snippet-dir '(snippets cpp))
(define c++-snippets
  `((field . ((struct . ,identity)
            (field . ,identity)))))

(define (generate-context-class component)
  (let* ((behaviour (one-is-#f (component-behaviour component)))
         (enums (if behaviour
                    (string-join (map (lambda (x) (generate-enum component x)) (behaviour-types behaviour)))
                    ""))
         (behaviour-format
          (if behaviour
              (let* ((predicates
                      (string-map-format-keys (gulp-snippet 'predicate-element)
                                              `((state-type . ,(lambda (x) (type-name-component x component)))
                                                (name . ,variable-name))
                                              (behaviour-variables behaviour)))
                     (predicates-2
                      (string-map-format-keys (gulp-snippet 'predicate-element-2)
                                              `((name . ,variable-name)
                                                (value . ,(lambda (x) (expression->string (variable-initial-value x)))))
                                              (behaviour-variables behaviour))))
                (format-keys (gulp-snippet 'component-context-class-behaviour)
                             `((component . ,(component-name component))
                               (predicates . ,predicates)
                               (predicates-2 . ,predicates-2))))
              "/* NO BEHAVIOUR */")))
    (format-keys (gulp-snippet 'component-context-class)
                 `((behaviour . ,behaviour-format)
                   (component . ,(component-name component))
                   (enums . ,enums)
                   (instances . "")
                   (interface . "/*(getImplIntfNamecomp)*/")
                   (no-dpc . ,(if (member 'requires (map port-direction (component-ports component))) "" "NoDpc"))
                   (ports . ,(format-ports component 'component-context-class-port))))))

(define (generate-component-implementation component)
  (dump-file 
   (format #f "~aComponent.~a" (component-name component) cc)
   (format-keys (gulp-snippet 'component)
                `((component . ,(component-name component))
                  (interface . ,(component-interface component))
                  (port-methods . "")
                  (proxy-classes . "")
                  (state-class . "")
                  (context-class . ,(generate-context-class component))
                  (component-class . "")
                  (proxy-methods . "")
                  (component-methods . "")
                  (state-methods . "")
                  (context-methods . "")
                  (instance-includes . "")
                  (function-definitions . "")
                  (instance-getters . "")))))

(define (generate-component component)
    (generate-component-header component)
    (generate-component-implementation component))

(define (asd->c++ ast)
  (let ((interface (interface ast))
        (component (component ast)))
    (if component 
      (generate-component component)))
  "")

(define asd-> asd->c++)
