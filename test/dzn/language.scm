;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; Tests for the language module.
;;;
;;; Code:

;; USAGE:
;;  * ./pre-inst-env guile test/dzn/language.scm
;;  * make check TESTS=test/dzn/language

(define-module (test dzn language)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)
  #:use-module (srfi srfi-71)
  #:use-module (dzn parse)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse complete)
  #:use-module (dzn parse lookup)
  #:use-module (dzn parse tree)
  #:use-module (dzn parse util)
  #:use-module (test dzn automake))

(define (file-name->text file-name)
  (let ((dir "test/language"))
    (with-input-from-file (string-append dir "/" file-name)
      read-string)))

(define (file-name->parse-tree file-name)
  (let ((text (file-name->text file-name)))
    (parameterize ((%peg:fall-back? #t))
      (string->parse-tree text #:file-name file-name))))

(define* (test-context #:key file-name text line (column 0) offset)
  (let* ((text   (or text (file-name->text file-name)))
         (root   (parameterize ((%peg:fall-back? #t))
                   (string->parse-tree text)))
         (offset (or offset
                     (and line (line-column->offset line column text))
                     (string-length text))))
    (values (complete:context root offset) offset)))

(define* (test-complete #:key file-name text line (column 0) offset)
  (let* ((ctx offset (test-context #:file-name file-name #:text text
                                   #:line line #:column column
                                   #:offset offset))
         (token      (.tree ctx)))
    (complete token ctx offset)))

(define* (test-lookup #:key file-name text line (column 0) offset
                      (file-name->parse-tree (const '())))
  (let* ((ctx   (test-context #:file-name file-name #:text text
                              #:line line #:column column
                              #:offset offset))
         (token (.tree ctx))
         (loc   (lookup-location token ctx
                                 #:file-name file-name
                                 #:file-name->text file-name->text
                                 #:file-name->parse-tree file-name->parse-tree)))
    (location->string loc)))

(test-begin "language")

(test-begin "completion")

(define %completion-top '("component" "interface"))
(define %completion-interface '("bool" "enum" "in" "out"))
(define %completion-component '("behaviour" "provides" "requires" "system"))

(test-equal "completion empty" ;0
  %completion-top
  (test-complete #:text ""))

(test-equal "language interf_" ;1
  %completion-top
  (test-complete #:text "interf"))

(test-equal "language interface _" ;1b
  '()
  (test-complete #:text "interface "))

(test-equal "language interface-I" ;2
  %completion-top
  (test-complete #:file-name "interface-I.dzn"))

(test-equal "language interface I {" ;3
  %completion-interface
  (test-complete #:file-name "interface-I-open.dzn"))

(test-equal "language interface I { in _" ;4
  '("bool" "void")
  (test-complete #:file-name "interface-I-in.dzn"))

(test-equal "language interface I { ..; in _" ;5
  '("bool" "void")
  (test-complete #:file-name "interface-I-in2.dzn"))

;;; XXX TODO: devise a better test naming scheme and remove all
;;; numbering (or revert to numbering above?)
(test-equal "language interface I { enum E; in _" ;5b
  '("bool" "void" "E")
  (test-complete #:file-name "interface5b.dzn"))

(test-equal "language interface6"
  '("behaviour" "bool" "enum" "in" "out")
  (test-complete #:file-name "interface6.dzn"))

(test-equal "language interface7"
  '()
  (test-complete #:file-name "interface7.dzn"))

(test-equal "language interface8"
  '("on")
  (test-complete #:file-name "interface8.dzn"))

(test-equal "language interface9"
  '("foo")
  (test-complete #:file-name "interface9.dzn"))

(test-equal "language interface9b"
  '("foo" "bar")
  (test-complete #:file-name "interface9b.dzn"))

(test-equal "language component1"
  %completion-component
  (test-complete #:file-name "component1.dzn"))

(test-equal "language component2"
  '("p.e" "r.f")
  (test-complete #:file-name "component2.dzn"))

(test-equal "language component3"
  '("p.f" "r.e")
  (test-complete #:file-name "component3.dzn"))

(test-equal "language component4"
  '("p.f" "r.e")
  (test-complete #:file-name "component4.dzn"))

(test-equal "language component5"
  '("p.f" "r.e")
  (test-complete #:file-name "component5.dzn"))

(test-equal "language component6"
  '("p.f" "r.e")
  (test-complete #:file-name "component6.dzn"))

(test-equal "language component7"
  '("on")
  (test-complete #:file-name "component7.dzn"))

(test-equal "language component8"
  '("provides" "requires")
  (test-complete #:file-name "component8.dzn" #:offset 170))

(test-equal "language typo"
  '("provides" "requires")
  (test-complete #:file-name "typo.dzn" #:offset 219))

(test-end)

(test-begin "lookup")

(test-equal "lookup port->interface"
  "lookup.dzn:56:10"
  (test-lookup #:file-name "lookup.dzn" #:line 46 #:column 11))

(test-equal "lookup instance->component"
  "lookup.dzn:26:10"
  (test-lookup #:file-name "lookup.dzn" #:line 77 #:column 6))

(test-equal "lookup port->imported-interface"
  #f
  (test-lookup #:file-name "lookup.dzn" #:line 28 #:column 13))

(test-equal "lookup port->imported-interface, with fallback"
  "ilookup.dzn:24:10"
  (test-lookup #:file-name "lookup.dzn" #:line 28 #:column 13
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup trigger->event"
  "ilookup.dzn:26:10"
  (test-lookup #:file-name "ilookup.dzn" #:line 32 #:column 7))

(test-equal "lookup action->event"
  "ilookup.dzn:27:11"
  (test-lookup #:file-name "ilookup.dzn" #:line 33 #:column 29))

(test-equal "lookup enum variable->type"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 34 #:column 4))

(test-equal "lookup enum-literal->type"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 28))

(test-equal "lookup enum-literal->field"
  "lookup.dzn:33:14"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 30))

(test-equal "lookup trigger->event"
  "ilookup.dzn:26:10"
  (test-lookup #:file-name "ilookup.dzn" #:line 32 #:column 7))

(test-equal "lookup trigger->port"
  "lookup.dzn:46:25"
  (test-lookup #:file-name "lookup.dzn" #:line 52 #:column 12))

(test-equal "lookup action->port"
  "lookup.dzn:46:25"
  (test-lookup #:file-name "lookup.dzn" #:line 51 #:column 24))

(test-equal "lookup action->event"
  "lookup.dzn:58:10"
  (test-lookup #:file-name "lookup.dzn" #:line 51 #:column 27))

(test-equal "lookup end-point->port"
  "lookup.dzn:72:18"
  (test-lookup #:file-name "lookup.dzn" #:line 79 #:column 6))

(test-equal "lookup end-point->component.port"
  "lookup.dzn:28:18"
  (test-lookup #:file-name "lookup.dzn" #:line 79 #:column 14))

(test-equal "lookup end-point->instance"
  "lookup.dzn:77:17"
  (test-lookup #:file-name "lookup.dzn" #:line 79 #:column 12))

(test-equal "lookup var->enum variable"
  "lookup.dzn:34:6"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 26))

(test-equal "lookup var->int variable"
  "int.dzn:8:8"
  (test-lookup #:file-name "int.dzn" #:line 9 #:column 5))

(test-equal "lookup variable->enum-type"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 34 #:column 4))

(test-equal "lookup variable->int-type"
  "int.dzn:1:7"
  (test-lookup #:file-name "int.dzn" #:line 8 #:column 4))

(test-equal "lookup field-test->var"
  "lookup.dzn:34:6"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 5))

(test-equal "lookup field-test->enum-field"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 7))

(test-equal "lookup variable-type->interface enum"
  "interface-enum.dzn:3:7"
  (test-lookup #:file-name "interface-enum.dzn" #:line 18 #:column 4))

(test-equal "lookup variable-type->namespace enum"
  "namespace-enum.dzn:1:22"
  (test-lookup #:file-name "namespace-enum.dzn" #:line 8 #:column 4))

(test-equal "lookup variable-type->deep.space enum"
  "deep-space-enum.dzn:1:39"
  (test-lookup #:file-name "deep-space-enum.dzn" #:line 8 #:column 4))

(test-end)

(test-end)
