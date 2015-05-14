;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (g resolve)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 getopt-long)  
  :use-module (ice-9 match)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)
  :use-module (language dezyne location)

  :use-module (g ast-colon)
  :use-module (g g)  
  :use-module (g misc)
  :use-module (g reader)

  :export (
           ast->
           ast:imported?
           ast:reorder-for-gaiag-equiv
           ast:resolve
           ast:resolve-model
           ))

(define (ast:resolve ast)
  (let ((resolved ((ast:resolve- ast) ast)))
    (if (and (pair? ast)
             (not (ast:root? ast))
             (or (find ast:interface? ast)
                 (find ast:component? ast)
                 (find ast:system? ast)))
        (cons 'root resolved)
        resolved)))

(define (source-file o)
  (and-let* (((supports-source-properties? o))
             (loc (source-property o 'loc))
             (properties (source-location->user-source-properties loc))
             (file-name (assoc-ref properties 'filename)))
            (string->symbol file-name)))

(define (basename- o)
  (string->symbol (basename (symbol->string o))))

(define (in-file? o file)
  (let ((file (if (string? file) (string->symbol file) file)))
    (and-let* ((model-file (source-file o))
               (model-file (if (string? model-file) (string->symbol model-file) model-file)))
              (eq? (basename- file) (basename- model-file)))))

;; (define (parse-opts x)  ((@@ (g g) parse-opts) x))

(define (ast:imported? o)
  (if (assoc 'imported? (source-properties o))
      (source-property o 'imported?)
      (and-let* (((>2 (length (command-line))))
                 (file (car (option-ref (parse-opts (command-line)) '() '(#f))))
                 ((not (string-suffix? ".scm" file))))
                (not (in-file? o file)))))

(define (mark-imported o imported?)
  (set-source-property! o 'imported? imported?)
  o)

(define ((ast:resolve- ast) src)
  (match src
    (('interface body ... (and ('imported . imported)))
     (mark-imported ((ast:resolve- #f) (cons 'interface body)) imported))
    (('component body ... (and ('imported . imported)))
     (mark-imported ((ast:resolve- #f) (cons 'component body)) imported))
    (('system body ... (and ('imported . imported)))
     (mark-imported ((ast:resolve- #f) (cons 'system body)) imported))    
    (('interface name body ... ) ((ast:resolve-model src) src))
    (('component name ports (no-behaviour)) (list 'component name ports))
    (('component name body ...) ((ast:resolve-model src) src))
    ((h ...) (map (lambda (x) ((ast:resolve- ast) x)) src))
    (_ src)))

(define (enum-type enum)
  (let ((name (ast:name enum)))
    (if (pair? name)
        (list 'type (car name) (cons 'type (cdr name)))
        (list 'type name))))

(define (interface-enums port)
  (map (lambda (enum)
         (list 'enum (list (ast:type port) (ast:name enum)) (ast:fields enum)))
       ((compose ast:enums ast:ast ast:type) port)))

(define* ((ast:resolve-model model) src :optional (locals '()))
  (let ((resolved ((ast:resolve-model- model) src locals)))
    (and-let* (((supports-source-properties? src))
               (loc (source-property src 'loc))
               ((supports-source-properties? resolved)))
              (set-source-property! resolved 'loc loc))
    resolved))

(define* ((ast:resolve-model- model) src :optional (locals '()))
  (let* ((port? (lambda (port)
                  (if (eq? (ast:class model) 'interface)
                      #f
                      (member port (map ast:name (ast:ports model))))))
         (enum? (lambda (identifier)
                  (member identifier
                          (append (map ast:name
                                       (append (ast:enums model)
                                               (filter ast:enum? (ast:globals))))))))
         (enum-field? (lambda (identifier)
                        (lambda (field)
                            (and-let* ((enum (find (lambda (x) (eq? (ast:name x) identifier))
                                                   (append (ast:enums model)
                                                           (filter ast:enum? (ast:globals))))))
                                      (member field (ast:fields enum))))))
         (member? (lambda (identifier)
                    (member identifier (ast:member-names model))))
         (member-field? (lambda (identifier)
                          (lambda (field)
                            (and-let* ((variable (or (ast:variable model identifier)
                                                     (ast:variable (map cdr locals) identifier)))
                                       (type (ast:type variable))
                                       (enums (append
                                               (ast:enums model)
                                               (apply append
                                                      (map interface-enums (ast:ports model)))))
                                       (enum (find (lambda (enum)
                                                     (equal? (enum-type enum) type)) enums)))
                                      (member field (ast:fields enum))))))
         (local?  (lambda (identifier) (assoc identifier locals)))
         (global? (lambda (identifier) (member identifier (map ast:name (ast:globals)))))
         (var? (lambda (identifier) (or (local? identifier) (member? identifier) (global? identifier)))))
    (match src
      (('action identifier)
       (if (member identifier (map ast:name (ast:functions (ast:behaviour model))))
           (list 'call identifier)
           src))

      (('variable identifier type ('expression ('value (and (? port?) (get! port)) event)))
       (list 'variable identifier type (list 'action (list 'trigger (port) event))))

      (('variable identifier type ('expression (and ('call function ...) (get! call))))
       (list 'variable identifier type ((ast:resolve-model model) (call) locals)))

      (('assign identifier ('expression (and ('call function ...) (get! call))))
       (list 'assign identifier ((ast:resolve-model model) (call) locals)))

      (('variable identifier type expression)
       (list 'variable identifier type ((ast:resolve-model model) expression locals)))

      (('assign identifier ('expression ('value (and (? port?) (get! port)) event)))
       (list 'assign identifier (list 'action (list 'trigger (port) event))))

      (('value (? var?) (? (member-field? (cadr src))))
       (cons 'field (cdr src)))

      (('value (? enum?) (? (enum-field? (cadr src))))
       (append '(literal #f) (cdr src)))

      (('value foo bar)
       (stderr "NO VALUE: ~a\n" src)
       (stderr "members: ~a\n" (ast:member-names model))
       (stderr "locals: ~a\n" locals)
       (stderr "globals: ~a\n" (ast:globals))
       (stderr "var: ~a f: ~a\n"(var? foo) ((member-field? foo) bar))
       (stderr "enum: ~a f: ~a\n"(enum? foo) ((enum-field? foo) bar))       
       src)

      (('assign identifier expression)
       (list 'assign identifier ((ast:resolve-model model) expression locals)))

      (('field identifier field) src)

      (('var identifier) src)

      ;; expressions
      (('expression expression)
       (list 'expression ((ast:resolve-model model) expression locals)))

      (('trigger port event) src)

      ((and (? symbol?) (? var?)) (list 'var src))

      (('function identifier ('signature type parameters ...) statement)
       ((ast:resolve-model model)
        (list 'function identifier (ast:signature src) #f statement) locals))

      (('function identifier ('signature type) recursive? statement)
         (list 'function identifier (ast:signature src) recursive?
               ((ast:resolve-model model) statement locals)))

      (('function identifier ('signature type ('parameters parameters ...)) recursive? statement)
       (let ((locals (let loop ((parameters parameters) (locals locals))
                       (if (null? parameters)
                           locals
                           (loop (cdr parameters)
                                 (acons (ast:name (car parameters)) (car parameters) locals))))))
         (list 'function identifier (ast:signature src) recursive?
               ((ast:resolve-model model) statement locals))))

      (('compound statements ...)
       (cons 'compound
             (let loop ((statements statements) (locals locals))
               (if (null? statements)
                   '()
                   (let* ((statement (car statements))
                          (locals (match statement
                                    (('variable identifier type expression)
                                     (acons identifier statement locals))
                                    (_ locals))))
                     (let ((resolved ((ast:resolve-model model) (car statements) locals)))
                       (cons resolved (loop (cdr statements) locals))))))))
      ((h ...) (map (lambda (x) ((ast:resolve-model model) x locals)) src))

      (_ src))))

(define (ast:reorder-for-gaiag-equiv o)
  (match o
    (('root models ...)
     (cons 'root
           (append
            (filter ast:import? models)
            (filter ast:user-type? models)
            (filter ast:interface? models)
            (filter ast:component? models)
            (filter ast:system? models))))
    (_ o)))

(define ast-> ast:resolve)
