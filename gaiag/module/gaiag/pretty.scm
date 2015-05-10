;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (gaiag pretty)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag wfc)

  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast-> ast->dezyne ast->dzn ast->pretty pretty:gom))

(define-method (ast->dezyne (o <list>))
  (let ((gom ((gom:register pretty:gom) o #t)))
    (ast->dezyne gom)))

(define-method (ast->dezyne (o <null>)) "")

(define-method (ast->dezyne (o <root>))
  (indent-string (apply string-append (map ast->dezyne (.elements o)))))

(define-method (ast->dezyne (o <ast>))
  (indent-string (->string o)))

(define ast-> ast->dezyne)
(define ast->dzn ast->dezyne)
(define ast->pretty ast->dezyne)

(define (pretty:gom ast)
  ((compose ast:wfc ast:resolve ast->gom) ast))

(define-method (children (o <ast>))
  (map (lambda (slot) (slot-ref o (slot-definition-name slot))) ((compose class-slots class-of) o)))

(define (->string src)
  (define (unspecified? x) (eq? x *unspecified*))

  (match src
    (#f "false")
    (#t "true")
    ('() "")
    (($ <behaviour> "" ($ <types> '()) ($ <variables> '()) ($ <functions> '()) ($ <compound> '())) "")
    (($ <compound> elements) (string-join (append '("{\n") (map ->string elements) '("}\n") ) ""))
    (($ <assign> var ($ <call> function arguments))
     (->string (list 'assign var (list 'assign-call function arguments))))
    (($ <assign> var ($ <action> trigger))
     (->string (list 'assign var (list 'assign-action trigger))))
    (($ <variable> name type ($ <call> function arguments))
     (->string (list 'variable name (->string type) (list 'assign-call function arguments))))
    (($ <variable> name type ($ <action> trigger))
     (->string (list 'variable name (->string type) (list 'assign-action trigger))))

    ;; comment this out to get ol style system as system
    (($ <system> name ($ <ports> ports) ($ <instances> instances) ($ <bindings> bindings))
     (->string (list 'system-as-component name ports instances bindings)))
    ((and (? pair?) (? dezyne-template?)) (apply dezyne-template->string src))
    ((? dezyne-template?) (apply dezyne-template->string
                                 (cons (ast-name src) (children src))))
    
    ((? join?) (apply join-all (children src)))
    ((? symbol?) (symbol->string src))
    ((? string?) src)
    ((? integer?) (number->string src))
    (($ <arguments> '()) "")
    (($ <arguments> arguments) (->string (list "(" (comma-join (map ->string arguments)) ")")))
    (($ <parameters> parameters) (->string (list "(" (comma-join (map ->string parameters)) ")")))
    (($ <gom:parameter> name type #f) (->string (list type " " name)))
    (($ <gom:parameter> name type dir) (->string (list dir " " type " " name)))
    (($ <signature> type ($ <parameters> '()))
     (list (cons (->string (->string type)) "")))
    (($ <signature> type parameters)
     (list (cons (->string type) (->string parameters))))
    (($ <type> name #f) (->string name))
    (($ <type> name scope) (->string (list scope '. name)))
    (($ <otherwise> value) (->string value))    
    (($ <triggers> triggers) (comma-space-join (map ->string triggers)))

    ;; FIXME: c&p from csp.scm (and...TODO: c++.scm) grmbl
    (('group expression) (->string (list "(" (->string expression) ")")))
    (($ <expression> expression) (->string expression))
    (($ <var> identifier) (->string identifier))
    (($ <data> data) (->string (list "$" data "$")))
    (($ <literal> #f type field) (->string (list type "." field)))
    (($ <literal> scope type field) (->string (list scope "." (->string type) "." field)))
    (($ <field> type field) (->string (list (->string type) "." field)))
    (('! ($ <expression> expression)) (->string (list "!" (paren expression))))
    (('or lhs rhs) (let ((lhs (->string lhs))
                         (rhs (->string rhs)))
                     (list lhs " " 'or " " rhs)
                     ;;(list "(" lhs " " 'or " " rhs ")")
                     )) ;; FIXME: do we need to add gratituous parens?
    (((or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (->string lhs))
           (rhs (->string rhs))
           (op (car src)))
       (->string (list lhs " " op " " rhs ))))

    ((h ...) (apply string-append (map ->string h)))
    ((? unspecified?) #f)
    (_ (format #f "~a" src))
    (_ (format #f "~a:->string:no match:~a\n" (current-source-location) src))))

(define (paren expression)
  (if (or (number? expression) (symbol? expression))
      (->string expression)
      (->string (list "(" (->string expression) ")"))))

(define (expression->string src)
  (let ((unparen (lambda (s) (if (and (string-prefix? "(" s)
                                      (string-postfix? ")" s))
                                 (string-drop (string-drop-right s 1) 1)
                                 s))))
    (and=> src (compose unparen ->string))))

(define (arguments->string arguments)
  (comma-space-join (map ->string (.elements arguments))))

(define (dezyne-template? x) (parameterize ((templates dezyne-templates)) (template? x)))

(define (dezyne-template->string . x)
  (parameterize ((template-dir dezyne-template-dir) (templates dezyne-templates))
    (apply template->string x)))

(define (comma-space-join lst) (string-join (map ->string lst) ", "))
(define (clause->string o)
  (match o
    (($ <compound>) (->string o))
    (#f #f)
    (_ (->string (make <compound> :elements (list o))))))

(define dezyne-template-dir (append (prefix-dir) '(templates dezyne)))
(define dezyne-templates
  `((component . ((name . ,identity)
                  (ports . ,->string)
                  (behaviour . ,(lambda (x) (or (and=> x ->string) "")))))
    (system . ((name . ,identity)
               (ports . ,->string)
               (instances . ,->string)
               (bindings . ,->string)))
    (system-as-component . ((name . ,identity)
                            (ports . ,->string)
                            (instances . ,->string)
                            (bindings . ,->string)))
    (interface . ((name . ,identity)
                  (types . ,->string)
                  (ports . ,->string)
                  (behaviour . ,(lambda (x) (or (and=> x ->string) "")))))
    (port . ((name . ,identity)
                 (direction . ,->string)
                 (type . ,->string)))
    (bind . ((left . ,->string)
             (right . ,->string)))
    (binding . ((instance . ,identity)
                (port . ,identity)))
    (instance . ((name . ,->string)
                 (type . ,->string)))
    (behaviour . ((name . ,(lambda (name) (if name name "")))
                  (types . ,->string)
                  (variables . ,->string)
                  (functions . ,->string)
                  ;; TOP level compound does *not* have braces
                  (compound . ,(lambda (x)
                                 (apply string-append
                                        (map ->string (.elements x)))))))
    (enum . ((name . ,identity)
             (scope . ,identity)
             (elements . ,(compose comma-space-join .elements))))
    (extern . ((name . ,identity)
               (scope . ,identity)
               (value . ,identity)))
    (int . ((name . ,identity)
            (scope . ,identity)
            (range . ,->string)))
    (range . ((from . ,->string)
              (to . ,->string)))
    (variable . ((var . ,identity)
                 (type . ,->string)
                 (value . ,->string)))
    (trigger . ((port . ,identity)
                (event . ,identity)
                (arguments . ,->string)))
    (value . ((type . ,identity)
              (field . ,identity)))
    (function . ((name . ,identity)
                 (signature . ,identity)
                 (recursive? . ,identity)
                 (body . ,->string)))
    (return . ((expression . ,expression->string)))
    (reply . ((expression . ,expression->string)))
    (on . ((triggers . ,->string)
           (statement . ,->string)))
    (guard . ((expression . ,expression->string)
              (statement . ,->string)))
    (assign . ((identifier . ,identity)
               (expression . ,->string)))
    (action . ((expression . ,->string)))
    (assign-action . ((expression . ,->string)))
    (illegal . '())
    (call . ((identifier . ,identity)
             (arguments . ,arguments->string)))
    (assign-call . ((identifier . ,identity)
                    (arguments . ,arguments->string)))
    (if . ((expression . ,->string)
           (statement . ,clause->string)
           (else . ,clause->string)))
    (or . ((left . ,->string)
           (right . ,->string)))
    (and . ((left . ,->string)
           (right . ,->string)))
    (event . ((name . ,->string)
              (direction . ,->string)
              (signature . ,->string)))
    (import . ((file . ,->string)))))

(define (join-all . rest) (string-join (map ->string rest) ""))
(define join '(bindings events functions imports instances ports types variables))
(define (join? x) (and (is-a? x <ast>) (member (ast-name x) join)))
