;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (ast-> ast->asd ast->pretty pretty:gom))

(define (ast->asd ast)
  (let ((gom ((gom:register pretty:gom) ast #t)))
    (indent-string (apply string-append (map ->string (.elements gom))))))

(define ast-> ast->asd)
(define ast->pretty ast->asd)

(define (pretty:gom ast)
  ((compose ast->gom ast:resolve) ast))

(define-method (children (o <ast>))
  (map (lambda (slot) (slot-ref o (slot-definition-name slot))) ((compose class-slots class-of) o)))

(define (->string src)
  (match src
    (#f "false")
    (#t "true")
    ('() "")
    (($ <behaviour> "" ($ <types> '()) ($ <variables> '()) ($ <functions> '()) ($ <compound> '())) "")
    (($ <compound> elements) (string-join (append '("{\n") (map ->string elements) '("}\n") ) ""))
    (($ <assign> var ($ <call> function arguments))
     (->string (list 'assign var (list 'assign-call function arguments))))
    (($ <variable> name type ($ <call> function arguments))
     (->string (list 'variable name type (list 'assign-call function arguments))))
    (('type name) name)
    ((and (? pair?) (? asd-template?)) (apply asd-template->string src))
    ((? asd-template?) (apply asd-template->string
                              (cons (ast-name src) (children src))))

    ((? join?) (apply join-all (children src)))
    ((? symbol?) (symbol->string src))
    ((? string?) src)
    ((? integer?) (number->string src))
    (($ <parameters> parameters) (comma-join (map ->string parameters)))
    (($ <gom:parameter>) (->string (list (cdr (.type src)) " " (.identifier src))))
    (($ <signature> type) (->string (cdr type)))
    (($ <otherwise> otherwise) (->string otherwise))
    (($ <triggers> triggers) (comma-space-join (map ->string triggers)))

    ;; FIXME: c&p from csp.scm (and...TODO: c++.scm) grmbl
    (('group expression) (list "(" (->string expression) ")"))
    (($ <expression> expression) (->string expression))
    (($ <var> identifier) (->string identifier))
    (($ <literal> #f type field) (->string (list type "." field)))
    (($ <literal> scope type field) (->string (list scope "." type "." field)))
    (($ <field> type field) (->string (list type "." field)))
    (('! ($ <expression> expression)) (->string (list "!" (paren expression))))
    (('or lhs rhs) (let ((lhs (->string lhs))
                         (rhs (->string rhs)))
                     (list "(" lhs " " 'or " " rhs ")"))) ;; FIXME: do we need to add gratituous parens?
    (((or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (->string lhs))
           (rhs (->string rhs))
           (op (car src)))
       (list lhs " " op " " rhs )))

    ((h ...) (apply string-append (map ->string h)))
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
    (unparen (->string src))))

(define (arguments->string arguments)
  (comma-space-join (map ->string (.elements arguments))))

(define (asd-template? x) (parameterize ((templates asd-templates)) (template? x)))

(define (asd-template->string . x)
  (parameterize ((template-dir asd-template-dir) (templates asd-templates))
    (apply template->string x)))

(define (comma-space-join lst) (string-join (map ->string lst) ", "))

(define asd-template-dir (append (prefix-dir) '(templates asd)))
(define asd-templates
  `((component . ((name . ,identity)
                  (ports . ,->string)
                  (behaviour . ,(lambda (x) (or (and=> x ->string) "")))))
    (interface . ((name . ,identity)
                  (types . ,->string)
                  (ports . ,->string)
                  (behaviour . ,(lambda (x) (or (and=> x ->string) "")))))
    (port . ((name . ,identity)
             (direction . ,->string)
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
             (elements . ,(compose comma-space-join .elements))))
    (int . ((name . ,identity)
            (range . ,->string)))
    (range . ((from . ,->string)
              (to . ,->string)))
    (variable . ((var . ,identity)
                 (type . ,->string)
                 (value . ,->string)))
    (trigger . ((port . ,identity)
                (event . ,identity)))
    (value . ((type . ,identity)
              (field . ,identity)))
    (function . ((name . ,identity)
                 (signature . ,identity)
                 (recursive? . ,identity)
                 (body . ,->string)))
    (return . ((expression . ,expression->string)))
    (on . ((triggers . ,->string)
           (statement . ,->string)))
    (guard . ((expression . ,expression->string)
              (statement . ,->string)))
    (assign . ((identifier . ,identity)
               (expression . ,->string)))
    (action . ((expression . ,->string)))
    (illegal . '())
    (call . ((identifier . ,identity)
             (arguments . ,arguments->string)))
    (assign-call . ((identifier . ,identity)
                    (arguments . ,arguments->string)))
    (if . ((expression . ,->string)
           (statement . ,->string)
           (else . ,->string)))
    (or . ((left . ,->string)
           (right . ,->string)))
    (and . ((left . ,->string)
           (right . ,->string)))
    (event . ((name . ,->string)
              (direction . ,->string)
              (type . ,->string)))
    (type . ((name . ,identity)))
    (import . ((file . ,->string)))))

(define (join-all . rest) (string-join (map ->string rest) ""))
(define join '(events functions imports ports types variables))
(define (join? x) (and (is-a? x <ast>) (member (ast-name x) join)))
