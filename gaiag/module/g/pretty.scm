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
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (g pretty)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)

  :use-module (g animate)
  :use-module (g ast-colon)
  :use-module (g indent)
  :use-module (g misc)
  :use-module (g reader)

  :export (ast-> ast->dzn ast->pretty))

(define (ast->dzn ast)
  (indent-string
   (match ast
     (('root models ...) (apply string-append (map ->string models)))
     (_ (->string ast)))))

(define ast-> ast->dzn)
(define ast->pretty ast->dzn)

(define (->string src)
  (match src
    (#f "false")
    (#t "true")
    ('() "")
    (('behaviour) "")
    (('compound s ...) (string-join (append '("{\n") (map ->string (cdr src)) '("}\n") ) ""))
    (('if expr statement else) (->string (cons 'if-then-else (cdr src))))
    (('if expr statement) (->string (cons 'if-then (cdr src))))

    (('assign var ('call function))
     (->string (list 'assign var (list 'assign-call function))))
    (('assign var ('call function arguments))
     (->string (list 'assign var (list 'assign-call function arguments))))

    (('assign var ('action trigger))
     (->string (list 'assign var (list 'assign-action trigger))))

    (('variable var type ('call function))
     (->string (list 'variable var type (list 'assign-call function))))
    (('variable var type ('call function arguments))
     (->string (list 'variable var type (list 'assign-call function arguments))))

    (('variable name type ('action trigger))
     (->string (list 'variable name (->string type) (list 'assign-action trigger))))

;;    (('trigger #f event) (->string event))
;;    (('trigger #f event arguments) (->string event))    
    ((? dzn-template?) (apply dzn-template->string src))
    ((? join?) (apply join-all (cdr src)))
    ((? symbol?) (symbol->string src))
    ((? string?) src)
    ((? integer?) (number->string src))
    ((? ast:parameters?) (->string (list (comma-join (map ->string (ast:body src))))))
    ((? ast:triggers?) (comma-join (map ->string (ast:body src))))
    (('parameter name type (or #f 'in) ...) (->string (list type " " name)))
    (('parameter name type dir) (->string (list (symbol->string dir) " " type " " name)))
    ((? ast:enum?) ((->join ".") (cdr src)))
    (('signature type)
     (list (cons (->string type) "")))
    (('signature type parameters)
     (list (cons (->string type) (->string parameters))))
    ;;((? ast:type?) (->string (ast:name src)))
    (('type name) (->string name))
    (('type name #f) (->string name))
    (('type name scope) (->string (list scope '. name)))
    (('otherwise) (->string 'otherwise))
    (('otherwise value) (->string value))    
    ;; FIXME: c&p from csp.scm (and...TODO: c++.scm) grmbl
    (('group expression) (expression->string (list "(" (expression->string expression) ")")))
    (('expression) #f)
    (('expression expression) (expression->string expression))
    (('var identifier) (->string identifier))
    (('data data) (->string (list "$" data "$")))
    (('literal #f type field) (->string (list type "." field)))
    (('literal scope type field) (->string (list scope "." (->string type) "." field)))
    (('field type field) (->string (list (->string type) "." field)))
    (('! expression)
     (->string (list "!" (paren expression))))
    (('or lhs rhs) (let ((lhs (->string lhs))
                         (rhs (->string rhs)))
                     (->string (list "(" lhs " || " rhs ")")))) ;; FIXME: do we need to add gratituous parens?
    (((or '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (->string lhs))
           (rhs (->string rhs))
           (op (car src)))
       (->string (list lhs " " op " " rhs ))))

    ((h ...) (apply string-append (map ->string h)))
    (_ (format #f "~a:->string:no match:~a\n" (current-source-location) src))))

(define (paren expression)
  (if (or (number? expression) (symbol? expression)
          (ast:field? expression) (ast:literal? expression) (ast:var? expression))
      (->string expression)
      (->string (list "(" (->string expression) ")"))))

(define (expression->string src)
  (let ((unparen (lambda (s) (if (and s
                                      (string-prefix? "(" s)
                                      (string-postfix? ")" s))
                                 (string-drop (string-drop-right s 1) 1)
                                 s))))
    (unparen (->string src))))

(define (arguments->string arguments)
  (comma-space-join (map ->string (ast:body arguments))))

(define (dzn-template? x) (parameterize ((templates dzn-templates)) (template? x)))

(define (dzn-template->string . x)
  (parameterize ((template-dir dzn-template-dir) (templates dzn-templates))
    (apply template->string x)))

(define (comma-space-join lst) (string-join (map ->string lst) ", "))

(define dzn-template-dir (append (prefix-dir) '(templates dzn)))
(define dzn-templates
  `((component . ((name . ,identity)
                  (ports . ,->string)
                  (behaviour . ,->string)))
    (interface . ((name . ,identity)
                  (types . ,->string)
                  (events . ,->string)
                  (behaviour . ,->string)))
    (requires . ((type . ,->string)
                 (name . ,identity)
                 (injected . ,(lambda (x) (and=> x ->string)))))
    (provides . ((type . ,->string)
                 (name . ,identity)))
    (behaviour . ((name . ,(lambda (name) (if name name "")))
                  (types . ,->string)
                  (variables . ,->string)
                  (functions . ,->string)
                  ;; TOP level compound does *not* have braces
                  (compound . ,(lambda (x) (apply string-append (map ->string (cdr x)))))))
    (enum . ((name . ,identity)
             (elements . ,comma-space-join)))
    (extern . ((name . ,identity)
               ;; TODO (scope . ,identity)
               (value . ,identity)))
    (int . ((name . ,identity)
            (range . ,->string)))
    (range . ((from . ,->string)
              (to . ,->string)))
    (variable . ((var . ,identity)
                 (type . ,->string)
                 (value . ,->string)))
    (trigger . ((port . ,identity)
                (event . ,identity)
                (arguments . ,arguments->string)))
    (value . ((type . ,identity)
              (field . ,identity)))
    (function . ((name . ,identity)
                 (signature . ,->string)
                 (recurse? . ,identity)
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
    (if-then . ((expression . ,->string)
                (statement . ,->string)))
    (if-then-else . ((expression . ,->string)
                     (statement . ,->string)
                     (else . ,->string)))
    (in . ((signature . ,->string)
           (name . ,->string)))
    (out . ((signature . ,->string)
            (name . ,->string)))
    (or . ((left . ,->string)
           (right . ,->string)))
    (and . ((left . ,->string)
            (right . ,->string)))
    (import . ((file . ,->string)))))

(define (join-all . rest) (string-join (map ->string rest) ""))
(define join '(events functions imports ports types variables))
(define (join? x) (and (list? x) (member (car x) join)))
