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

(define-module (gaiag code)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag indent)
  :use-module (gaiag mangle)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
  :use-module (gaiag wfc)

  :use-module (oop goops)
  :use-module (oop goops describe)
  :use-module (gaiag gom)

  :export (enum-type
           ->code))

(define-method (declare-replies (o <interface>))
  (map (lambda (x) (->string (list "        " "self.reply_" (.name o) "_" (.name x) " = None\n"))) (gom:interface-enums o)))

(define (scope-type o)
  (match o
    (($ <expression> ($ <literal> scope type field)) (->string (list "interface." scope)))))

(define (enum-type o)
  (match o
    (($ <expression> ($ <literal> scope type field)) (->string (list (scope-type o) "." type)))))

(define (declare-enum enum)
  (let ((fields (.elements (.fields enum))))
    (->string
     (list
      "    class " (.name enum) " ():\n"
      "        " (comma-space-join fields) " = range (" (length fields) ")\n"))))

(define (declare-integer integer)
  (->string (list "typedef int " (.name integer) ";\n")))

(define statements.src (make-parameter #f))
(define statements.port (make-parameter #f))
(define statements.event (make-parameter #f))

(define-method (enum->identifier (model <model>) (o <expression>) locals)
  ;; FIXME: c&p (resolve-model-)
  (define (enum? identifier) (gom:enum model identifier))
  (define (member? identifier) (gom:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (match o
    (($ <expression> ($ <literal> scope type field))
     (->string (list scope "_" type)))
    (($ <expression> ($ <var> name))
     (or (and-let* ((decl (var? name))
                    (type (.type decl)))
                   (->string (list (.scope type) "_" (.name type))))
         ""))))

(define (enum->type) "todo")

(define (snippet name pairs) "boo")

(define* (statements->string model src :optional (locals '()) (indent 1) (compound? #t))
  (define (enum? identifier) (gom:enum model identifier))

  (let ((port (statements.port))
        (event (statements.event))
        (space (make-string (* indent 4) #\space)))
    (->string
     (match src
       (() "")

       (($ <guard> expression statement)
        (list space (parameterize ((statements.src src))
                      (expr->clause model expression))
              "\n" (statements->string model statement locals (1+ indent))))
       (($ <if> expression then ($ <statement> '()))
        (list space "if (" (expression->string model expression locals) "):\n" (statements->string model then locals (1+ indent))))
       (($ <if> expression then ($ <statement> '()))
        (snippet 'if
                 `((expression (expression->string model expression locals))
                   (then (statements->string model then locals))))
        (list "if ("  ")\n" ))
       (($ <if> expression then #f) ;; FIXME
        (list space "if (" (expression->string model expression locals) "):\n" (statements->string model then locals (1+ indent))))
       (($ <if> expression then else)
        (list space "if (" (expression->string model expression locals) "):\n" (statements->string model then locals (1+ indent)) space "else:\n" (statements->string model else locals (1+ indent))))
       (($ <assign> name (and ($ <action>) (get! action)))
        (list space "self." name " = " (statements->string model (action) locals 0)))
       (($ <assign> name (and ($ <call>) (get! call)))
        (list space "self." name " = " (statements->string model (call) locals 0)))
       (($ <assign> identifier expression)
        (list space "self." (statements->string model identifier locals 0) " = " (expression->string model expression locals) "\n"))
       (($ <on> triggers statement)
        (if (find (lambda (t) (and (eq? (.port t) (.name port))
                                   (eq? (.event t) (.name event))))
                  (.elements triggers))
            (statements->string model statement locals indent)
            ""))
       (($ <call> function ($ <arguments> '())) (list space "self." function " ()\n"))
       (($ <call> function ($ <arguments> arguments))
        (let ((arguments ((->join ", ") (map (lambda (o) (expression->string model o locals)) arguments))))
          (list space "self." function  " (" arguments ")\n")))

       ;; c&p resolve/CSP/
       (($ <compound> '()) (list space "pass\n"))
       (($ <compound> statements)
        (list ;;(if compound? "\n")
              (let loop ((statements statements) (locals locals))
                (if (null? statements)
                    '()
                    (let* ((statement (car statements))
                           (locals (match statement
                                     (($ <variable> name type expression)
                                      (acons name statement locals))
                                     (_ locals))))
                      (let ((str (statements->string model (car statements) locals indent compound?)))
                        (cons str (loop (cdr statements) locals))))))
              ;;(if compound? "\n")
              ))
       (($ <illegal>) (list space "assert (False)\n"))
       (($ <action> trigger)
        (let* ((port-name (.port trigger))
               (event-name (.event trigger))
               (port (gom:port model port-name))
               (name (.type port))
               (interface (python:import name))
               (event (gom:event interface event-name)))
          (list space "self." port-name '. (.direction event) 's. event-name " ()\n")))
       (($ <reply> expression)
        (let* ((name (enum->identifier model expression locals)))
          (statements->string
           model
           (list space "self.reply_" name " = " (expression->string model expression locals) "\n")
           locals)))
       (($ <return> #f)
        (list space "return\n"))
       (($ <return> expression)
        (list space 'return " " (expression->string model expression locals) "\n"))
       (($ <signature> type)
        (list (if (and (not (.scope type)) (enum? (.name type)))
                  (list (.name model) "."))
              (statements->string model type locals)))
       (($ <type> name #f) (if (enum? name) (->string (list name "")) name))
       (($ <type> name scope) (list "interface." scope "." name ""))
       (($ <variable> name type (and ($ <action>) (get! action)))
        (statements->string model (list space name " = " (statements->string model (action) locals 0)) locals indent))
       (($ <variable> name type expression)
        (statements->string model (list space name " = " (expression->string model expression locals) "\n") locals indent))
       (($ <parameters> parameters)
        ((->join ", ") (map (lambda (x) (statements->string model x)) parameters)))
       (($ <gom:parameter> name) name)
       ((? char?) (make-string 1 src))
       ((? string?) src)
       ('true 'True)
       ('false 'False)
       ((? symbol?) src)
       (#t 'True)
       (#f 'False)
       ((h t ...) (map (lambda (x) (statements->string model x locals indent)) src))
       (_ (throw 'match-error (format #f "~a:python:statements->string: no match: ~a\n" (current-source-location) src)))))))

(define (expr->clause model expression)
  (let* ((c-expression (bool-expression->string model expression))
         (if-clause (list "if (" c-expression "):"))
         (else-if-clause (list "elif (" c-expression "):"))
         (else-clause "else:")
         (guards ((compose .elements .statement .behaviour) model))
         (first? (eq? (statements.src) (car guards)))
         (top? (find (lambda (guard) (eq? guard (statements.src))) guards)))
    (->string (list (if (is-a? expression <otherwise>) else-clause
                        (if (or first? (not top?)) if-clause else-if-clause))))))

(define (bool-expression->string model o)
  (match o
    (($ <field> identifier field)
     (list "(self." identifier " == " field ")"))
    (($ <literal> #f type field) (->string (list "self." type "." field)))
    (($ <literal> scope type field) (->string (list type "." field)))
    (_ (expression->string model o))))

;; FIXME: c&p from csp.scm
(define* (expression->string model o :optional (locals '()))

  (define (paren expression)
    (list "(" (expression->string model expression locals) ")"))

  ;; FIXME: c&p (resolve-model-)
  (define (enum? identifier) (gom:enum model identifier))
  (define (member? identifier) (gom:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))

  (define (enum-type o)
    (or (and-let* ((decl (var? o))
                   (type (.type decl))
                   (scope (if (.scope type) (list (.scope type) ".") "self.")))
                  (list scope (.name type) "."))
        ""))

  (match o
    (($ <expression>) (expression->string model (.value o) locals))
    (($ <var> (and (? member?) (get! identifier))) (list "self." (identifier)))
    (($ <var> identifier) identifier)
    (($ <field> identifier field)
     (list "self." identifier " == " (enum-type identifier) field))

    (($ <call> function ($ <arguments> '())) (->string (list "self." function " ()")))
    (($ <call> function ($ <arguments> arguments))
     (let ((arguments ((->join ", ") (map (lambda (o) (expression->string model o locals)) arguments))))
       (->string (list "self." function  " (" arguments ")"))))

    (($ <literal> #f type field) (list "self." type "." field))
    (($ <literal> scope type field)
     (->string (list "interface." scope "." type "." field)))
    ((? number?) (number->string o))
    ((? string?) o)
    ('true 'True)
    ('false 'False)
    ((? symbol?) o)
    (('! expression)
     (->string (list "not " (paren expression))))

    (('group expression) (paren expression))

    (('or lhs rhs) (let ((lhs (expression->string model lhs locals))
                         (rhs (expression->string model rhs locals)))
                     (list "(" lhs " " 'or " " rhs ")")))

    (((or 'and '== '!= '< '<= '> '>= '+ '-) lhs rhs)
     (let ((lhs (expression->string model lhs locals))
           (rhs (expression->string model rhs locals))
           (op (car o)))
       (list lhs " " op " " rhs )))

    (_ (format #f "~a:no match: ~a" (current-source-location) o))))

(define (return-type-text port)
  (or (and-let* ((event (null-is-#f (gom:typed? port))))
                (.type (.type (car event))))
      'void))

(define (binding-name model bind)
  (let ((instance (gom:instance model bind))
        (port (gom:port model bind)))
    (list
     (match instance
       (($ <instance>) (.name instance))
       (($ <interface>) (.name instance))
       )
     "."
     (match port
       (($ <gom:port>) (.name port))
       (($ <interface>) (list "x" (.name port)))))))

(define (bind-port? bind)
  (or (not (.instance (.left bind))) (not (.instance (.right bind)))))

(define (return-type port event)
  (let ((type ((compose .type .type) event)))
    (->string (if (not (eq? 'void (.name type)))
                  (list "interface" "." (.type port) "." (.name type) "")
                  'void))))
