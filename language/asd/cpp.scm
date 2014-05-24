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

(define-module (language asd cpp)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)
  :use-module (language asd misc)
  :use-module (language asd ast)
  :use-module (language asd format-keys)
  :export (asd->cpp))

(define (gulp-snippet name)
  (gulp-text-file (string-join (map symbol->string `(snippets cpp ,name)) "/")))

(define (format-snippet name pairs) 
  (format-keys (gulp-snippet name) pairs))

(define (generate-component-header component)
  (dump-file 
   (format #f "~aComponent.h" (component-name component))
   (format-keys (gulp-snippet 'component-header-bottom)
                `((component . ,(component-name component))
                  (includes . ,(string-map-format-keys
                                (gulp-snippet 'component-header-include)
                                `((interface . ,(lambda (port) (cadr port))))
                                (component-ports component)))
                  (interface . ,(component-interface component))
                  (ports . "")))))


(define (generate-component-implementation component)
  (dump-file 
   (format #f "~aComponent.cpp" (component-name component))
   (format-keys (gulp-snippet 'component-header-bottom)
                `((component . ,(component-name component))
                  (includes . ,(string-map-format-keys
                                (gulp-snippet 'component-header-include)
                                `((interface . ,(lambda (port) (cadr port))))
                                (component-ports component)))
                  (interface . ,(component-interface component))
                  (ports . "")))))

(define (API port)
    (if (eq? 'provides (port-direction port))
      'API 'CB))

(define (CB port)
  (if (eq? 'provides (port-direction port))
      'CB 'API))

(define (format-ports component snippet)
  (string-map-format-keys
   (gulp-snippet snippet)
   `((api . ,(lambda (port) (API port)))
     (callback . ,(lambda (port) (CB port)))
     (component . ,(lambda (x) (component-name component)))
     (interface . ,(lambda (port) (port-interface port)))
     (port . ,(lambda (port) (port-name port))))
   (component-ports component)))

(define (generate-context-class component)
  (format-keys (gulp-snippet 'component-context-class)
               `((behaviour . "/*behaviour*/")
                 (component . ,(component-name component))
                 (enums . "/*enums*/")
                 (interface . "/*(getImplIntfNamecomp)*/")
                 (no-dpc . ,(if (assoc 'required (component-ports component)) "" "NoDpc"))
                 (ports . ,(format-ports component 'component-context-class-port)))))

(define (generate-component-implementation component)
  (dump-file 
   (format #f "~aComponent.cpp" (component-name component))
   (format-keys (gulp-snippet 'component-implementation)
                `((component . ,(component-name component))
                  (interface . ,(component-interface component))
                  (includes . "")
                  (ports . "")
                  (context-class . ,(generate-context-class component))
                  (component-class . "")
                  (state-classes . "")
                  (proxy-methods . "")
                  (context-methods . "")
                  (component-methods . "")
                  (state-methods . "")))))

(define (generate-component component)
    (generate-component-header component)
    (generate-component-implementation component))

(define (asd->cpp ast)
  (let ((interface (interface ast))
        (component (component ast)))
    (if component 
      (generate-component component))))
