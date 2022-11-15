;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016, 2017, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015, 2017, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2019 Rob Wieringa <rma.wieringa@gmail.com>
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

(define-module (dzn code language c)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code language dzn)
  #:use-module (dzn code)
  #:use-module (dzn code-util)
  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn templates))

(define-templates-macro define-templates c)
(include-from-path "dzn/templates/dzn.scm")
(include-from-path "dzn/templates/code.scm")
(include-from-path "dzn/templates/c.scm")

(define-method (c:models (o <root>))
  (filter (negate ast:imported?) (dzn:model o)))

(define-method (c:components (o <root>))
  (filter (negate (cute is-a? <> <interface>)) (c:models o)))

(define-method (c:file-name (o <ast>))
  (if (is-a? (.type o) <foreign>) (basename ((compose .file-name ast:location .type) o) ".dzn")
      (code:file-name o)))

(define %char-set:identifier (list->char-set '(#\_) char-set:letter+digit))
(define-method (c:file-name-identifier-upcase (o <ast>))
  (string-map (lambda (c)
                (if (char-set-contains? %char-set:identifier c) c #\_))
              ((compose string-upcase code:file-name) o)))

(define-method (c:get-trigger-port-type (o <trigger>))
  (c:name (ast:parent (.event o) <interface>)))

(define-method (c:comma (o <list>))
  (if (null? o) "" ", "))

(define-method (c:comma (o <action>))
  (c:comma (ast:argument* o)))

(define-method (c:comma (o <call>))
  (c:comma (ast:argument* o)))

(define-method (c:comma (o <trigger>))
  (c:comma (ast:formal* o)))

(define-method (c:arguments (o <trigger>))
  (define (formal->argument f)
    (let ((argument (make <argument>
                      #:name (.name f)
                      #:type.name (.type.name f)
                      #:direction (.direction f)
                      #:expression f)))
      (clone argument #:parent (.parent f))))
  (map formal->argument
       (code:add-calling-context-argument (ast:formal* o))))

(define-method (c:address/deref (o <top>))
  "")

(define-method (c:address/deref (o <argument>))
  (let ((variable (.variable o))
        (formal (ast:argument->formal o)))
    (cond ((and (is-a? variable <formal>)
                (not (ast:in? variable))
                (ast:in? formal))
           "")
          ((and (or (is-a? variable <variable>)
                    (and (is-a? variable <formal>)
                         (ast:in? variable)))
                (not (ast:in? formal)))
           "&")
          (else
           ""))))

(define-method (c:address/deref (o <variable>))
  (let ((variable o)
        (formal (ast:argument->formal o)))
    (cond  ((and (not formal)
                 (not (ast:in? o)))
            "*")
           ((not formal)
            "")
           ((and (is-a? variable <formal>)
                 (not (ast:in? variable))
                 (ast:in? formal))
            "")
           ((and (or (is-a? variable <variable>)
                     (and (is-a? variable <formal>)
                          (ast:in? variable)))
                 (not (ast:in? formal)))
            "&")
           (else
            ""))))

(define-method (c:address/deref (o <formal>))
  (let ((formal (ast:argument->formal o)))
    (cond ((and (not formal)
                (not (ast:in? o)))
           "*")
          ((not formal)
           "")
          ((and (not (ast:in? o))
                (ast:in? formal))
           "*")
          ((and (ast:in? o)
                (not (ast:in? formal)))
           "&")
          (else
           ""))))

(define-method (c:deref (o <top>))
  "")

(define-method (c:deref (o <formal>))
  (if (not (ast:in? o)) "*" ""))

(define-method (c:deref (o <out-formal>))
  "*")

(define-method (c:deref (o <var>))
  (let ((variable (.variable o)))
    (if (and (is-a? variable <formal>) (not (ast:in? variable))) "*"
        "")))

(define-method (c:ptr (o <formal>))
  (if (not (eq? 'in (.direction o))) "*" ""))

(define-method (c:ptr (o <argument>))
  "")

(define-method (c:self (o <variable>))
  (if (ast:member? o) "self->" ""))

(define-method (c:extract-variables-with-respect-to-enums (o <ast>))
  (let* ((non-literals (filter (lambda (u) (not (is-a? (.expression u) <literal>))) (ast:variable* o)))
         (literals (filter (lambda (u) (is-a? (.expression u) <literal>)) (ast:variable* o)))
         (filtered-literals (filter (lambda (u) (not (equal? ((compose .value .expression) u) "void"))) literals)))
    (append non-literals filtered-literals)))


(define-method (c:formal-data-type (o <formal>))
  (let ((type (.type o)))
    (match type
      (($ <enum>) "uint8_t")
      (($ <subint>) (c:range-type (.type o)))
      (($ <extern>) (list ((compose .value .value .type) o)))
      (_ (ast:name type)))))

(define-method (c:formal-data-type (o <argument>))
  (c:formal-data-type (.expression o)))

;; bidning stuff
(define-method (c:binding-instance (o <end-point>))
  (if (.instance.name o) o
      '()))

(define-method (c:foreign-instance (o <end-point>))
  (if (and (.instance o)
           (is-a? ((compose .type .instance) o) <foreign>)) o
           '()))

;; nameing stuff
(define-method (c:namespace-upcase o)
  (map string-upcase (c:name o)))

(define-method (c:name o)
  ((compose ast:full-name ast:type) o))

(define-method (c:name (o <model>))
  (ast:full-name o))

(define-method (c:model-parent-name (o <model>))
  (c:name o))

(define-method (c:model-parent-name (o <ast>))
  (c:model-parent-name (ast:parent o <model>)))

;; enum stuff
(define-method (c:enum-complete-name-upcase (o <enum>))
  (map string-upcase (c:name o)))

(define-method (c:get-enum-fields-of-enum (o <enum>))
  (map (string->enum-field o) (ast:field* o) (iota (length (ast:field* o)))))

;;enum main stuff
(define-method (c:get-all-enums (o <root>))
  (tree-collect (is? <enum>) o))

(define-method (c:get-all-enums (o <ast>))
  (let ((root (ast:parent o <root>)))
    (c:get-all-enums root)))

(define-method (c:get-all-local-enums (o <root>))
  (filter (negate ast:imported?) (c:get-all-enums o)))

(define-method (c:get-all-local-enums (o <ast>))
  (let ((root (ast:parent o <root>)))
    (c:get-all-local-enums root)))

(define-method (c:enum-printed-name (o <enum-field>))
  (ast:name (.type o)))

(define-method (c:enum-trigger-void (o <trigger>))
  (cond ((is-a? (ast:type o) <enum>) (ast:type o))
        ((ast:typed? o) o)
        (else (ast:type o))))

(define-method (c:void-trigger (o <trigger>))
  (if (not (ast:typed? o)) o
      '()))

(define-method (c:enum-or-trigger (o <trigger>))
  (if (is-a? (ast:type o) <enum>) (ast:type o)
      o))

(define-method (c:non-void-trigger (o <trigger>))
  (if (ast:typed? o) o
      (ast:type o)))

;; helper struct stuff
(define-method (c:equal? (a <type>) (b <type>))
  (and (is-a? a <enum>)
       (is-a? b <enum>)))

;; closure struct in triggers of all the components
(define-method (c:get-incoming-triggers-from-model (o <root>))
  (delete-duplicates (append-map ast:requires-out-triggers (filter (is? <component>) (ast:model* o)))
                     (lambda (a b)
                       (and (equal? (c:model-parent-name a) (c:model-parent-name b))
                            (or (c:equal? ((compose ast:type .type .signature .event) a)
                                          ((compose ast:type .type .signature .event) b))
                                (ast:equal? ((compose .signature .event) a)
                                            ((compose .signature .event) b)))))))

;; foreign closure struct and helper functions for foreign only
(define-method (c:get-incoming-triggers-from-model (o <foreign>))
  (delete-duplicates (ast:requires-out-triggers o)
                     (lambda (a b)
                       (and (equal? (c:model-parent-name a) (c:model-parent-name b))
                            (or (c:equal? ((compose ast:type .type .signature .event) a)
                                          ((compose ast:type .type .signature .event) b))
                                (ast:equal? ((compose .signature .event) a)
                                            ((compose .signature .event) b)))))))


(define-method (c:binding-provides (o <binding>))
  (if (ast:provides? (.port (.left o))) (.left o)
      (.right o)))

(define-method (c:binding-requires (o <binding>))
  (if (ast:requires? (.port (.left o))) (.left o)
      (.right o)))

(define (internal-binding? o)
  (and ((compose .instance.name .left) o)
       ((compose .instance.name .right) o)))

(define-method (c:external-binding (o <system>))
  (define (port-end-point-left b)
    (if ((compose .instance.name .right) b) b
        (make <binding> #:left (.right b)
              #:right (.left b))))
  (let ((bindings (filter (negate internal-binding?) (ast:binding* o))))
    (map port-end-point-left bindings)))

(define-method (c:internal-binding (o <system>))
  (filter internal-binding? (ast:binding* o)))

(define-method (c:type-name-different (o <ast>))
  (code:type-name o))

;; enum type name handling
(define-method (c:type-name (o <ast>))
  (let ((type (ast:type o)))
    (match type
      (($ <enum>) "uint8_t")
      (($ <subint>) (c:range-type (ast:type o)))
      (_ (code:type-name o)))))

(define-method (c:range-type (o <subint>))
  (let*((range (.range o))
        (from ( .from range))
        (to (.to range)))
    (if (and (>= from 0) (>= to 0))
        (c:uint-resolve from to)
        (c:int-resolve from to))))

(define (c:uint-resolve lower higher)
  (cond ((c:in-range lower higher 0 255) "uint8_t")
        ((c:in-range lower higher 0 65535) "uint16_t")
        ((c:in-range lower higher 0 4294967295) "uint32_t")
        (else "uint64_t")))

(define (c:int-resolve lower higher)
  (cond ((c:in-range lower higher -128 127) "int8_t")
        ((c:in-range lower higher -32768 32767) "int16_t")
        ((c:in-range lower higher -2147483648 2147483647) "int32_t")
        (else "int64_t")))

(define (c:in-range low high min max)
  (and (>= low min)
       (<= low max)
       (>= high min)
       (<= high max)))

(define-method (c:enum-name (o <ast>)) ;; enum for helper functions
  (if (is-a? (ast:type o) <enum>) "enum"
      (c:type-name o)))

(define-method (c:enum-literal (o <enum-literal>))
  (append (ast:full-name (.type o)) (list (.field o))))

(define-method (c:generate-foreign-skel? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (is? <foreign>))
        (ast:model* o)))

(define-method (c:generate-source? (o <root>))
  (find (conjoin (negate ast:imported?)
                 (disjoin (is? <component>)
                          (is? <enum>)
                          (conjoin (is? <interface>)
                                   (compose
                                    pair?
                                    code:enum-definer))
                          (is? <system>)))
        (ast:model* o)))

(define-method (c:connect-instance-name-right (o <binding>))
  (let* ((end-point (.right o))
         (instance (.instance end-point))
         (name (.name instance)))
    (if (not (is-a? (.type instance) <foreign>)) name
        (string-append name ".base"))))


;;;
;;; Entry points.
;;;

(define* (ast-> root #:key (dir ".") model)
  "Entry point."

  (code-util:foreign-conflict? root)

  (let ((root (code:om+determinism root)))
    (let ((generator (code-util:indenter (cute x:header root)))
          (file-name (code-util:root-file-name root dir ".h")))
      (code-util:dump root generator #:file-name file-name))

    (when (or (c:generate-source? root)
              (c:generate-foreign-skel? root))
      (let ((generator (code-util:indenter (cute x:source root)))
            (file-name (code-util:root-file-name root dir ".c")))
        (code-util:dump root generator #:file-name file-name)))

    (when model
      (let ((model (ast:get-model root model)))
        (when (is-a? model <component-model>)
          (let ((generator (code-util:indenter (cute x:main model)))
                (file-name (code-util:file-name "main" dir ".c")))
            (code-util:dump root generator #:file-name file-name)))))))
