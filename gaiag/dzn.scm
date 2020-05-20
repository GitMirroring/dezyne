;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018,2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

  #:use-module (gaiag command-line)
  #:use-module (gaiag config)
  #:use-module (gaiag misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)

  #:use-module (gaiag indent)
  #:use-module (gaiag shell-util)
  #:use-module (gaiag templates)

  #:export (ast->dzn
            dzn-async?
            dzn:annotate-shells
            dzn:dir
            dzn:data
            dzn:class-member?
            dzn:dump
            dzn:extension
            dzn:expression
            dzn:indent
            dzn:om
            dzn:file2file
            dzn:expand-statement
            dzn:expression-expand
            dzn:action-arguments
            dzn:annotate-shells
            dzn:direction
            dzn:enum-literal
            dzn:expand-blocking
            dzn:=expression
            dzn:external
            dzn:formal-type
            dzn:global
            dzn:injected
            dzn:model
            dzn:model-name
            dzn:open-namespace
            dzn:port-prefix
            dzn:reply-port
            dzn:signature
            dzn:statement
            dzn:->string
            dzn:from
            dzn:to
            dzn:type
            %x:source
            %dzn:indenter))

(define %x:source (make-parameter #f))

(define (dzn:file2file root)
  (dzn:dump root))

(define-public (dzn-async? o)
  (and (is-a? o <interface>)
       (equal? (ast:full-name o) '("dzn" "async"))))

(define (dzn:extension o)
  (match o
    (($ <interface>)
     (assoc-ref '(("cd" . ".yah")
                  ("c" . ".h")
                  ("c++" . ".hh")
                  ("c++03" . ".hh")
                  ("c++-msvc11" . ".hh")
                  ("dzn" . ".dzn")
                  ("html" . ".html")
                  ("scheme" . ".scm")
                  ("java" . ".java")
                  ("java7" . ".java")
                  ("javascript" . ".js")
                  ("cs" . ".cs")
                  ("python" . ".py"))
                (language)))
    ((or ($ <foreign>) ($ <component>) ($ <system>))
     (assoc-ref '(("cd" . ".yll")
                  ("c" . ".c")
                  ("c++" . ".cc")
                  ("c++03" . ".cc")
                  ("c++-msvc11" . ".cc")
                  ("dzn" . ".dzn")
                  ("html" . ".html")
                  ("scheme" . ".scm")
                  ("java" . ".java")
                  ("java7" . ".java")
                  ("javascript" . ".js")
                  ("cs" . ".cs")
                  ("python" . ".py"))
                (language)))))

(define (dzn:om ast)
  ast)

(define (dzn:language)
  (let ((language (command-line:get 'language "dzn")))
    (if (member language '("dzn" "html")) language
        "dzn")))

(define-method (ast->dzn (o <root>))
  (parameterize ((language "dzn"))
    (with-output-to-string (dzn:indent (cut x:source o)))))
(define-method (ast->dzn (o <statement>))
  (parameterize ((language "dzn"))
    (with-output-to-string (dzn:indent (cut x:statement o)))))
(define-method (ast->dzn (o <function>))
  (parameterize ((language "dzn"))
    (with-output-to-string (dzn:indent (cut x:source o)))))

;;; dzn: generic templates
(define-method (dzn:model (o <root>))
  (topological-sort
   (map dzn:annotate-shells
        (filter (negate (disjoin (is? <data>) (is? <type>) (is? <namespace>) dzn-async?
                                 (conjoin ast:imported? (negate (is? <foreign>)))))
                (ast:model* o)))))

(define-method (dzn:model (o <namespace>))
  (ast:top* o))

(define-method (dzn:model (o <ast>))
  o)

(define-method (dzn:model-name (o <ast>))
  (ast:name (parent o <model>)))

(define (dzn:global o) ;; TODO: REPLACEME with ???
  (filter (is? <type>) (ast:top* o)))

(define (dzn:annotate-shells o)
  (if (and (is-a? o <system>)
           (equal? (command-line:get 'shell #f) (string-join (ast:full-name o) ".")))
      (clone (make <shell-system> #:ports (.ports o) #:name (.name o) #:instances (.instances o) #:bindings (.bindings o)) #:parent (.parent o))
      o))

(define-method (dzn:data (o <data>))
  (if (.value o) ((compose dzn:->string .value) o)
      '()))

(define-method (dzn:=expression (o <ast>))
  o)

(define-method (dzn:=expression (o <literal>))
  (let ((value (.value o)))
    (if (equal? value "void") (make <void>)
        o)))

(define-method (dzn:=expression (o <variable>))
  ((compose dzn:=expression .expression) o))

(define-method (dzn:=expression (o <extern>))
  (if (.value o) (.value o)
      '()))

(define-method (dzn:type o)
  (if (as o <model>)
      (ast:full-name o)
      (let* ((type (or (as o <type>) (.type o)))
             (scope (ast:full-scope type))
             (model-scope (parent o <model>))
             (model-scope (or (and model-scope (ast:full-name model-scope)) '()))

             (common (or (list-index (negate equal?) scope model-scope) (min (length scope) (length model-scope)))))
        (drop (ast:full-name type) common))))

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

(define-method (dzn:expression-expand (o <expression>))
  o)

(define-method (dzn:expression-expand (o <group>))
  (.expression o))

(define-method (dzn:class-member? (o <variable>))
  (let ((p (.parent o)))
    (and (is-a? p <variables>)
         (is-a? (.parent p) <behaviour>))))

(define-method (dzn:enum-literal (o <enum-literal>))
  (dzn:scope+name o))

(define-method (dzn:scope+name (o <enum-literal>))
  (append (dzn:type o) (list (.field o))))

(define-method (dzn:type (o <event>))
  ((compose dzn:type .type .signature) o))

(define-method (dzn:type (o <function>))
  ((compose dzn:type .type .signature) o))

(define (unspecified? o)
  (eq? o *unspecified*))

(define (dzn:->string o)
  (match o
    ((? number?) (number->string o))
;;    ((? symbol?) (symbol->string o))
    ((? string?) o)
    ((? (is? <data>)) (dzn:->string (.value o)))
    ((? unspecified?) "")
    (#f "")))

(define-method (dzn:formal-type (o <formal>)) o)
(define-method (dzn:formal-type (o <event>)) ((compose ast:formal* .signature) o))
(define-method (dzn:formal-type (o <trigger>)) ((compose dzn:formal-type .event) o))
(define-method (dzn:formal-type (o <port>)) ((compose dzn:formal-type car ast:event*) o))

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
  (if (not (.port.name o)) '()
      (list (.port.name o))))

(define-method (dzn:port-prefix (o <end-point>))
  (if (not (.port.name o)) '()
      (list (.port.name o))))

(define-method (dzn:port-prefix (o <trigger>))
  (if (not (.port.name o)) '()
      (list (.port.name o))))

(define-method (dzn:signature (o <event>))
  (.signature o))
(define-method (dzn:signature (o <port>))
  (list ((compose ast:name .type) o) "t"))

(define-method (dzn:action-arguments (o <action>)) ; MORTAL SIN HERE!!?
  (if (not (.port.name o)) '()
      (if (null? (ast:argument* o)) (list "")
          (ast:argument* o))))

(define-method (dzn:signature (o <event>))
  (.signature o))

(define-method (dzn:statement (o <statement>))
  o)

(define-method (dzn:statement (o <compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      o))

(define-method (dzn:statement (o <guard>)) ;; FIXME: for code, do in normalization!
  (cond ((is-a? (.expression o) <otherwise>) (clone (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o))
                                                    #:parent (.parent o)))
        ((ast:literal-true? (.expression o))(.statement o))
        ((ast:literal-false? (.expression o)) '())
        (else o)))

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
(define %dzn:indenter (make-parameter indent))

(define (pipe producer consumer)
  (with-input-from-string (with-output-to-string producer) consumer))

(define (dzn:indent thunk)
  (if (%dzn:indenter)
      (lambda () (pipe thunk (lambda () ((%dzn:indenter)))))
      thunk))

(define (dzn:dir o)
  (if (member (language) '("javascript")) "dzn/"
      ""))

(define-method (dzn:from (o <expression>))
  ((compose dzn:from ast:expression->type) o))

(define-method (dzn:from (o <type>))
  ((compose .from .range) o))

(define-method (dzn:to (o <expression>))
  ((compose dzn:to ast:expression->type) o))

(define-method (dzn:to (o <type>))
  ((compose .to .range) o))

(define-method (dzn:open-namespace (o <ast>))
  (cdr (reverse (ast:path (parent o <namespace>)))))

(define-method (dzn:dump (o <ast>))
  (let* ((dir (command-line:get 'output "."))
         (stdout? (equal? dir "-"))
         (dir (string-append dir "/" (dzn:dir o)))
         (base (basename (ast:source-file o) ".dzn")))
    (let* ((ext (dzn:extension (make <component>)))
           (file-name (string-append dir base ext)))
      (if stdout? ((dzn:indent (cut (%x:source) o)))
          (begin
            (mkdir-p dir)
            (with-output-to-file file-name
             (dzn:indent (cut (%x:source) o))))))))

(define-templates-macro define-templates dzn)
(include "templates/dzn.scm")

(define (ast-> ast)
  (let ((root (dzn:om ast)))
    (dzn:root-> root))
  "")

(define (dzn:root-> root)
  (parameterize ((language (dzn:language))
                 (%x:source x:source))
    (dzn:file2file root)))
