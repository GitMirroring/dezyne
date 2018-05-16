;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

(define-module (gaiag dzn)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag ast)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag util)

  #:use-module (gaiag config)
  #:use-module (gaiag command-line)
  #:use-module (gaiag compare)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag shell-util)
  #:use-module (gaiag templates)

  #:use-module (gaiag location)

  #:export (ast->dzn
            dzn-async?
            dzn:annotate-shells
            dzn:dir
            dzn:dump
            dzn:extension
            dzn:expression
            dzn:indent
            dzn:->string
            dzn:om
            dzn:file2file
            dzn:model2file?
            dzn:model2file
            dzn:statement
            dzn:expand-statement
            dzn:expression-expand
            dzn:=expression
            dzn:action-arguments
            dzn:annotate-shells
            dzn:direction
            dzn:enum-literal
            dzn:expand-blocking
            dzn:expand-statement
            dzn:expression
            dzn:=expression
            dzn:expression-expand
            dzn:external
            dzn:formal-type
            dzn:global
            dzn:injected
            dzn:port-prefix
            dzn:reply-port
            dzn:signature
            dzn:source
            dzn:statement
            dzn:->string
            dzn:from
            dzn:to
            dzn:type
            %x:source
            ))

(define %x:source (make-parameter #f))

(define (dzn:file2file root)
  (for-each dzn:dump (filter (is? <foreign>) (.elements root)))
  (dzn:dump root))

(define-public (dzn-async? o)
  (or (gaiag-dzn-async? o)
      (generator-dzn-async? o)))

(define (gaiag-dzn-async? o)
  (equal? ((compose .scope .name) o) '(dzn async)))

(define (generator-dzn-async? o)
  (let* ((name (.name o))
         (scope (.scope name)))
    (and (pair? scope)
         (eq? (car scope) 'dzn)
         (symbol-prefix? 'async (.name name)))))

(define (dzn:extension o)
  (match o
    (($ <interface>)
     (assoc-ref '((c . .h)
                  (c++ . .hh)
                  (c++03 . .hh)
                  (c++-msvc11 . .hh)
                  (dzn . .dzn)
                  (html . .html)
                  (scheme . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))
    ((or ($ <foreign>) ($ <component>) ($ <system>))
     (assoc-ref '((c . .c)
                  (c++ . .cc)
                  (c++03 . .cc)
                  (c++-msvc11 . .cc)
                  (dzn . .dzn)
                  (html . .html)
                  (scheme . .scm)
                  (java . .java)
                  (java7 . .java)
                  (javascript . .js)
                  (cs . .cs)
                  (python . .py))
                (language)))))

(define (dzn:model2file root)
  (let* ((models (filter (negate ast:imported?) (ast:model* root)))
         ;; Generator-synthesized models look non-imported, filter harder
         (models (filter (negate dzn-async?) models)))
    (for-each dzn:dump models)))

(define (dzn:om ast)
  ((compose
    ast:resolve
    parse->om
    ) ast))

(define (dzn:language)
  (let ((language (string->symbol (command-line:get 'language "dzn"))))
    (if (member language '(dzn html)) language
        'dzn)))

(define-method (ast->dzn (o <root>))
  (parameterize ((language 'dzn))
    (with-output-to-string (dzn:indent (cut x:source o)))))
(define-method (ast->dzn (o <statement>))
  (parameterize ((language 'dzn))
    (with-output-to-string (dzn:indent (cut x:statement o)))))
(define-method (ast->dzn (o <function>))
  (parameterize ((language 'dzn))
    (with-output-to-string (dzn:indent (cut x:source o)))))

;;; dzn: generic templates
(define-method (dzn:source (o <root>))
  (topological-sort
   (map dzn:annotate-shells
        (filter (negate (disjoin (is? <foreign>) (is? <data>) (is? <type>) ast:imported? dzn-async?))
                (.elements o)))))

(define-method (dzn:source (o <ast>))
  o)

(define (dzn:global o)
  (filter (is? <type>) (.elements o)))

(define (dzn:annotate-shells o)
  (if (and (is-a? o <system>)
           (equal? (command-line:get 'shell #f) (symbol->string (.name (.name o)))))
      (make <shell-system> #:ports (.ports o) #:name (.name o) #:instances (.instances o) #:bindings (.bindings o))
      o))

(define-method (dzn:=expression (o <ast>))
  o)

(define-method (dzn:=expression (o <literal>))
  (let ((value (.value o)))
    (if (eq? value 'void) (make <void>)
        o)))

(define-method (dzn:=expression (o <variable>))
  ((compose dzn:=expression .expression) o))

(define-method (dzn:=expression (o <extern>))
  (.value o))

(define-method (dzn:type o)
  (if (or (as o <model>))
      (om:scope+name o)
      (let* ((type (or (as o <type>) (.type o)))
             (scope (om:scope type))
             (model-scope (parent o <model>))
             (model-scope (or (and model-scope (om:scope+name model-scope)) '()))

             (common (or (list-index (negate eq?) scope model-scope) (min (length scope) (length model-scope)))))
        (drop (om:scope+name type) common))))

(define-method (dzn:type (o <bool>))
  o)

(define-method (dzn:type (o <void>))
  o)

(define-method (dzn:external (o <port>))
  (if (not (.external o)) ""
      o))

(define-method (dzn:injected (o <port>))
  (if (not (.injected o)) ""
      o))

(define-method (dzn:expression (o <top>))
  o)
(define-method (dzn:expression (o <assign>))
  (.expression o))
(define-method (dzn:expression (o <if>))
  (.expression o))
(define-method (dzn:expression (o <guard>))
  (.expression o))
(define-method (dzn:expression (o <reply>))
  (.expression o))

(define-method (dzn:expression (o <return>))
  (let ((type (ast:type o)))
    (if (is-a? type <void>) type
        (.expression o))))

(define-method (dzn:expression (o <var>))
  (.variable o))

(define-method (dzn:expression-expand (o <not>))
  (.expression o))

(define-method (dzn:expression-expand (o <var>))
  (.variable o))

(define-method (dzn:expression-expand (o <field-test>))
  (clone (make <enum-literal> #:type.name ((compose .type.name .variable) o) #:field (.field o))
         #:parent (.parent o)))

(define-method (dzn:expression-expand (o <variable>))
  (let ((type ((compose ast:type .expression) o)))
    (if (is-a? type <void>) type
        (.expression o))))

(define-method (dzn:expression-expand (o <assign>))
  (.expression o))

(define-method (dzn:expression-expand (o <reply>))
  o)

(define-method (dzn:class-member? (o <variable>)) ; MORTAL SIN HERE!!?
  ;; FIXME: is (.variable o) a member?
  ;; checking name (as done now) is not good enough
  ;; we schould check .variable pointer equality
  ;; that does not work, however; someone makes a copy is clone
  ;;(memq o (om:variables (parent o <model>)))
  (memq (.name o) (map .name (om:variables (parent o <model>)))))

(define-method (dzn:enum-literal (o <enum-literal>))
  (dzn:scope+name o))

(define-method (dzn:scope+name (o <enum-literal>))
  (append (dzn:type o) (list (.field o))))

(define-method (dzn:type (o <event>))
  ((compose dzn:type .type .signature) o))

(define-method (dzn:type (o <function>))
  ((compose dzn:type .type .signature) o))

(define (dzn:->string o)
  (match o
    ((? number?) (number->string o))
    ((? symbol?) (symbol->string o))
    ((? string?) o)))

(define-method (dzn:formal-type (o <formal>)) o)
(define-method (dzn:formal-type (o <port>)) ((compose ast:formal* .signature car om:events) o))

(define-method (dzn:direction (o <ast>))
  (if (not (.direction o)) '()
      (make <direction> #:name (.direction o))))

(define-method (dzn:direction (o <trigger>))
  ((compose dzn:direction .event) o))

(define-method (dzn:direction (o <action>))
  ((compose dzn:direction .event) o))

(define-method (dzn:direction (o <on>))
  ((compose dzn:direction car ast:trigger*) o))

(define-method (dzn:port-prefix (o <action>))
  (if (not (.port o)) '()
      (list (.port o))))

(define-method (dzn:port-prefix (o <binding>))
  (if (not (.port o)) ""
      (list (.port o))))

(define-method (dzn:port-prefix (o <trigger>))
  (if (not (.port o)) ""
      (list (.port o))))

(define-method (dzn:signature (o <event>))
  (.signature o))
(define-method (dzn:signature (o <port>))
  (list ((compose om:name .type) o) 't))

(define-method (dzn:action-arguments (o <action>)) ; MORTAL SIN HERE!!?
  (if (not (.port o)) ""
      (if (null? (ast:argument* o)) (list "")
          (ast:argument* o))))

(define-method (dzn:signature (o <event>))
  (.signature o))

(define-method (dzn:statement (o <statement>))
  o)

(define-method (dzn:statement (o <compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      o))

(define-method (dzn:statement (o <guard>))
  (if (not (is-a? (.expression o) <otherwise>)) o
      (clone (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
             #:parent (.parent o))))

(define-method (dzn:statement (o <behaviour>))
  ((compose dzn:expand-statement .statement) o))

(define-method (dzn:statement (o <function>))
  (.statement o))

(define-method (dzn:expand-statement (o <statement>))
  o)

(define-method (dzn:expand-statement (o <function>))
  ((compose dzn:expand-statement .statement) o))

(define-method (dzn:expand-statement (o <compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      (ast:statement* o)))

(define-method (dzn:expand-statement (o <declarative-compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      (ast:statement* o)))

(define-method (dzn:expand-statement (o <blocking>))
  (.statement o))

(define-method (dzn:expand-statement (o <on>))
  (.statement o))

(define-method (dzn:expand-statement (o <guard>))
  (.statement o))

(define-method (dzn:reply-port (o <reply>))
  (if (not (.port o)) ""
      (list (.port o))))

(define-method (dzn:expand-blocking (o <blocking>))
  (.statement o))

;;; dump to file
(define dzn:indenter (make-parameter indent))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dzn:indent thunk)
  (if (dzn:indenter)
      (lambda () (pipe thunk (lambda () ((dzn:indenter)))))
      thunk))

(define (dzn:dir o)
  (if (memq (language) '(javascript)) "dzn/"
      ""))

(define (dzn:from o)
  ((compose .from .range ast:expression->type) o))

(define (dzn:to o)
  ((compose .to .range ast:expression->type) o))

(define-generic source-file)
(define-method (source-file (o <ast>)) ((compose source-file .node) o))

(define-method (dzn:dump (o <ast>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (dir (string-append dir "/" (dzn:dir o)))
         (base (basename (symbol->string (source-file o)) ".dzn")))
    (let* ((ext (symbol->string (dzn:extension (make <component>))))
           (file-name (string-append dir base ext)))
      (if stdout? ((dzn:indent (cut (%x:source) o)))
          (begin
            (mkdir-p dir)
            (with-output-to-file file-name
             (dzn:indent (cut (%x:source) o))))))))

(define (dzn:model2file?)
  (and=> (or (command-line:get 'deprecated #f) (getenv "DZN_DEPRECATED"))
         (cut string-contains <> "model2file")))

(define-templates-macro define-templates dzn)
(include "../templates/dzn.scm")

(define (ast-> ast)
  (let ((root (dzn:om ast)))
    (dzn:root-> root))
  "")

(define (dzn:root-> root)
  (parameterize ((language (dzn:language))
                 (%x:source x:source))
    (if (dzn:model2file?) (dzn:model2file root)
        (dzn:file2file root))))
