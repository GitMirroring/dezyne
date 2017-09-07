;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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
  #:use-module (gaiag code)
  #:use-module (gaiag util)

  #:use-module (gaiag command-line)
  #:use-module (gaiag compare)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag xpand)

  #:use-module (language dezyne location)

  #:export (ast->dzn))

(define (ast-> ast)
  (let ((root (dzn:om ast)))
    (ast:set-scope root (dzn:root-> root)))
  "")

(define (dzn:root-> root)
  (parameterize ((language (dzn:language)))
    (if (dzn:model2file?) (dzn:model2file root)
        (dzn:file2file root))))

(define (dzn:file2file root)
  (let* ((objects (filter (disjoin (is? <data>)
                                   (negate (disjoin dzn-async? om:imported? (is? <foreign>))))
                          (ast:model* root)))
         (root* (clone root #:elements objects)))
    (dzn:dump root*)
    (when (code:foreign?)
      (for-each dzn:dump (filter (is? <foreign>) (ast:model* root))))))

(define (dzn:model2file root)
  (let* ((models (map (is? <model>) (ast:model* root)))
         (models (filter (negate om:imported?) models))
         ;; Generator-synthesized models look non-imported, filter harder
         (models (filter (negate dzn-async?) models)))
    (for-each dzn:dump models)))

(define (dzn:om ast)
  ((compose-root
    ast:resolve
    parse->om
    ) ast))

(define (dzn:language)
  (let ((language (string->symbol (command-line:get 'language "dzn"))))
    (if (member language '(dzn html)) language
        'dzn)))

(define* ((ast->dzn #:optional (model #f) (dzn:language (dzn:language))) o)
  (parameterize ((language dzn:language))
    (ast:set-scope o ((dzn:x:pand-display o 'source))))
  "")

;;; dzn: generic templates

;;(define-template x:source code:source)

(define-template x:type dzn:type 'type-infix)
(define-method (dzn:type o)
  (let* ((type (or (as o <model>) (as o <type>) (.type o)))
         (scope (om:scope type))
         (model-scope (om:scope+name (ast:model-scope))))
    (if (equal? scope model-scope) (list (om:name type))
        (om:scope+name type))))

(define-template x:dzn-enum-literal dzn:enum-literal 'type-infix)
(define-method (dzn:enum-literal (o <literal>))
  (dzn:scope+name o))

(define-method (dzn:scope+name (o <literal>))
  (append (dzn:type o) (list (.field o))))

(define-method (dzn:type (o <event>))
  ((compose dzn:type .type .signature) o))

(define-template x:define-type ast:type* 'newline-infix)
(define-template x:field ast:field* 'field-infix)
(define-template x:in-event (lambda (o) (filter om:in? (om:events o))) 'newline-infix)
(define-template x:out-event (lambda (o) (filter om:out? (om:events o))) 'newline-infix)
(define-template x:provided-port (lambda (o) (filter om:provides? (om:ports o))) 'newline-infix)
(define-template x:required-port (lambda (o) (filter om:requires? (om:ports o))) 'newline-infix)

(define-template x:behaviour .behaviour)
(define-template x:async-port ast:port* 'newline-infix)
(define-template x:declare-variable ast:variable* 'newline-infix)
(define-template x:range (lambda (o) (list ((compose .from .range) o) ((compose .to .range) o))) 'range-infix)

(define-template x:trigger ast:trigger* 'comma-infix)
(define-method (dzn:formal-type (o <formal>)) o)
(define-method (dzn:formal-type (o <port>)) ((compose ast:formal* .signature car om:events) o))
(define-template x:formal-type dzn:formal-type)

(define-template x:direction dzn:direction)
(define-method (dzn:direction (o <formal>)) ; MORTAL SIN HERE!!?
  (case (.direction o)
    ((#f) "")
    ((in) "in ")
    ((inout) "inout ")
    ((out) "out ")))

(define-template x:port-prefix dzn:port-prefix 'port-suffix)
(define-method (dzn:port-prefix (o <action>))
  (if (not (.port o)) ""
      (list (.port o))))

(define-method (dzn:port-prefix (o <binding>))
  (if (not (.port o)) ""
      (list (.port o))))

(define-method (dzn:port-prefix (o <trigger>))
  (if (not (.port o)) ""
      (list (.port o))))

(define-template x:signature dzn:signature 'space-infix)
(define-method (dzn:signature (o <event>))
  (.signature o))
(define-method (dzn:signature (o <port>))
  (list ((compose om:name .type) o) 't))

(define-template x:formal ast:formal* 'formal-infix)

(define-template x:trigger-signature (lambda (o) (if (not (.port o)) "" o)))
(define-template x:trigger-formal (lambda (o) (ast:formal* o)) 'formal-infix)

(define-template x:argument ast:argument* 'argument-infix <expression>)
(define-template x:action-arguments dzn:action-arguments 'argument-grammar <expression>)
(define-method (dzn:action-arguments (o <action>)) ; MORTAL SIN HERE!!?
  (if (not (.port o)) ""
      (if (null? (ast:argument* o)) (list "")
          (ast:argument* o))))

(define-method (dzn:signature (o <event>))
  (.signature o))

(define-class <skip> (<statement>))

(define-template x:dzn-statement dzn:statement)
(define-method (dzn:statement (o <statement>))
  o)

(define-method (dzn:statement (o <compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      o))

(define-method (dzn:statement (o <behaviour>))
  ((compose dzn:expand-statement .statement) o))

(define-template x:expand-statement dzn:expand-statement #f <statement>)
(define-method (dzn:expand-statement (o <statement>))
  o)

(define-method (dzn:expand-statement (o <compound>))
  (if (null? (ast:statement* o)) (make <skip>)
      (ast:statement* o)))

(define-method (dzn:expand-statement (o <blocking>))
  (.statement o))

(define-method (dzn:expand-statement (o <on>))
  (.statement o))

(define-method (dzn:expand-statement (o <guard>))
  (.statement o))

(define-template x:reply-port dzn:reply-port 'dot-suffix)
(define-method (dzn:reply-port (o <reply>))
  (if (not (.port o)) '()
      (list (.port o))))

(define-template x:expand-blocking dzn:expand-blocking #f <statement>)
(define-method (dzn:expand-blocking (o <blocking>))
  (.statement o))

(define-template x:system identity)
(define-template x:declare-instance ast:instance* 'newline-infix)
(define-template x:instance (lambda (o) (if (not (.instance o)) "" (list (.instance o)))) 'dot-suffix)
(define-template x:binding ast:binding* 'newline-infix)

(define code:dir (@@ (gaiag code) code:dir))
(define code:foreign? (@@ (gaiag code) code:foreign?))
(define code:header? (@@ (gaiag code) code:foreign?))

;;; dump to file
(define-method (dzn:x:pand (o <ast>) template file-name)
  (let ((file-name (if (and file-name (symbol? file-name)) (symbol->string file-name) file-name))) ;; FIXME
    (dump-output (string-append (if (eq? template 'main) "" (code:dir o)) ;; FIXME AAARRRGH
                                file-name)
                 (dzn:x:pand-display o template))))

(define-method (dzn:x:pand-display (o <ast>) template)
  (let ((module (make-module 31 `(,(resolve-module '(gaiag code))
                                  ,(resolve-module `(gaiag ,(language)))))))
    (module-define! module 'root (ast:root-scope))
    (code:indent
     (lambda _
       (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
        (if (not (is-a? o <model>)) (x:pand (symbol-append template '@ (ast-name o)) o module)
            (ast:set-model-scope o (x:pand (symbol-append template '@ (ast-name o)) o module))))))))

(define-method (dzn:dump (o <root>))
  (let ((name (basename (symbol->string (source-file o)) ".dzn")))
    (when (code:header?)
      (dzn:x:pand o 'header (string-append name (symbol->string (code:extension (make <interface>))))))
    (when (pair? (filter (negate (disjoin (is? <data>) (is? <interface>))) (ast:model* o)))
      (dzn:x:pand o 'source (string-append name (symbol->string (code:extension (make <component>))))))))

(define-method (dzn:dump (o <interface>))
  (let ((name ((om:scope-name) o)))
    (if (code:header?) (dzn:x:pand o 'header (symbol-append name (code:extension (make <interface>))))
        (dzn:x:pand o 'source (symbol-append name (code:extension (make <interface>)))))))

(define-method (dzn:dump (o <component>))
  (let ((name ((om:scope-name) o)))
    (when (code:header?)
      (dzn:x:pand o 'header (symbol-append name (code:extension (make <interface>)))))
    (dzn:x:pand o 'source (symbol-append name (code:extension (make <component>))))))

(define-method (dzn:dump (o <foreign>))
  (let ((name (code:skel-file o)))
    (when (code:header?)
      (dzn:x:pand o 'foreign-header (symbol-append name (code:extension (make <interface>)))))
    (dzn:x:pand o 'foreign-source (symbol-append name (code:extension (make <component>))))))

(define-method (dzn:dump (o <system>))
  (let* ((name ((om:scope-name) o))
         (shell (command-line:get 'shell #f))
         (template (if (and shell (eq? name (string->symbol shell))) 'shell- (symbol))))
    (when (code:header?)
      (dzn:x:pand o (symbol-append template 'header) (symbol-append name (code:extension (make <interface>)))))
    (dzn:x:pand o (symbol-append template 'source) (symbol-append name (code:extension (make <component>))))))

(define (dzn:model2file?)
  (and=> (or (command-line:get 'deprecated #f) (getenv "DZN_DEPRECATED"))
         (cut string-contains <> "model2file")))
