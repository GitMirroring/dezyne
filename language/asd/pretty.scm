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

(define-module (language asd pretty)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)

  :use-module (language asd animate)
  :use-module (language asd ast:)
  :use-module (language asd indent)
  :use-module (language asd misc)
  :use-module (language asd reader)

  :export (ast-> ast->asd ast->pretty))

(define (ast->asd ast)
  (indent-string (apply string-append (map ->string ast))))

(define ast-> ast->asd)
(define ast->pretty ast->asd)

(define (->string src)
  (match src
    (#f "false")
    (#t "true")
    ('() "")
    (('behaviour) "")
    (('compound s ...) (string-join (append '("{\n") (map ->string (cdr src)) '("}\n") ) ""))
    (('if expr statement else) (->string (cons 'if-then-else (cdr src))))
    (('if expr statement) (->string (cons 'if-then (cdr src))))
    (('assign var ('call function arguments ...))
     (->string (list 'assign var (list 'assign-call function arguments))))
    (('variable type var ('call function arguments ...))
     (->string (list 'variable type var (list 'assign-call function arguments))))
    (('trigger #f event) (->string event))
    ((? asd-template?) (apply asd-template->string src))

    ((? join?) (apply join-all (cdr src)))
    ((? symbol?) (symbol->string src))
    ((? string?) src)
    ((? integer?) (number->string src))
    ((? ast:parameters?) (comma-join (map ->string (ast:body src))))
    ((? ast:triggers?) (comma-join (map ->string (ast:body src))))
    ((? ast:parameter?) (->string (list (ast:name (ast:type src)) " " (ast:name src))))
    ((? ast:enum?) ((->join ".") (cdr src)))
    ((? ast:signature?) (->string (ast:name (ast:type src))))
    ((? ast:type?) (->string (ast:name ast)))

    ;; FIXME: c&p from csp.scm (and...TODO: c++.scm) grmbl
    (('group expression) (list "(" (->string expression) ")"))
    (('expression expression) (->string expression))
    (('! expression) (->string (list "!" (paren expression))))
    (('or lhs rhs) (let ((lhs (->string lhs))
                         (rhs (->string rhs)))
                     (list "(" lhs " " 'or " " rhs ")"))) ;; FIXME: do we need to add gratituous parens?
    (((or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (->string lhs))
           (rhs (->string rhs))
           (op (car src)))
       (list lhs " " op " " rhs )))

    ((h ...) (string-join (map ->string h)))
    (_ (format #f "~a:->string:no match:~a\n" (current-source-location) src))))

(define (paren expression)
  (if (or (number? expression) (symbol? expression))
      (->string expression)
      (->string (list "(") (->string expression) ")")))

(define (expression->string src)
  (let ((unparen (lambda (s) (if (and (string-prefix? "(" s)
                                      (string-postfix? ")" s))
                                 (string-drop (string-drop-right s 1) 1)
                                 s))))
    (unparen (->string src))))

(define (arguments->string arguments)
  (comma-space-join (ast:body (car arguments))))

(define (asd-template? x) (parameterize ((templates asd-templates)) (template? x)))

(define (asd-template->string . x)
  (parameterize ((template-dir asd-template-dir) (templates asd-templates))
    (apply template->string x)))

(define (comma-space-join lst) (string-join (map ->string lst) ", "))

(define asd-template-dir '(templates asd))
(define asd-templates
  `((component . ((name . ,identity)
                  (ports . ,->string)
                  (behaviour . ,->string)))
    (interface . ((name . ,identity)
                  (types . ,->string)
                  (ports . ,->string)
                  (behaviour . ,->string)))
    (requires . ((type . ,->string)
                 (name . ,identity)))
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
    (int . ((name . ,identity)
            (range . ,->string)))
    (range . ((from . ,->string)
              (to . ,->string)))
    (variable . ((type . ,->string)
                 (var . ,identity)
                 (value . ,->string)))
    (trigger . ((port . ,identity)
                (event . ,identity)))
    (value . ((type . ,identity)
              (field . ,identity)))
    (function . ((name . ,identity)
                 (signature . ,identity)
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
    (if-then . ((expression . ,->string)
                (statement . ,->string)))
    (if-then-else . ((expression . ,->string)
                     (statement . ,->string)
                     (else . ,->string)))
    (or . ((left . ,->string)
           (right . ,->string)))
    (and . ((left . ,->string)
           (right . ,->string)))
    (in . ((type . ,->string)
           (identifier . ,->string)))
    (out . ((type . ,->string)
            (identifier . ,->string)))
    (type . ((name . ,identity)))
    (import . ((file . ,->string)))))

(define (join-all . rest) (string-join (map ->string rest) ""))
(define join '(events functions imports ports types variables))
(define (join? x) (and (list? x) (member (car x) join)))
