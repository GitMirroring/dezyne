;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define (resolve-file file-name)
  (let ((dir "test/language"))
    (if (string-prefix? dir file-name) file-name
        (string-append dir "/" file-name))))

(define (file-name->text file-name)
  (let ((file-name (resolve-file file-name)))
    (with-input-from-file file-name read-string)))

(define (file-name->parse-tree file-name)
  (let ((text (file-name->text file-name)))
    (parameterize ((%peg:fall-back? #t))
      (string->parse-tree text #:file-name file-name))))

(define* (test-context #:key file-name text line (column 0) offset)
  (let* ((text   (or text (file-name->text file-name)))
         (root   (parameterize ((%peg:fall-back? #t))
                   (string->parse-tree text #:file-name file-name)))
         (offset (or offset
                     (and line (line-column->offset line column text))
                     (string-length text))))
    (values (complete:context root offset) offset)))

(define* (test-complete #:key file-name text line (column 0) offset
                        (file-name->parse-tree (const '())))
  (let* ((ctx offset (test-context #:file-name file-name #:text text
                                   #:line line #:column column
                                   #:offset offset))
         (token      (.tree ctx)))
    (complete token ctx offset #:file-name->parse-tree file-name->parse-tree)))

(define* (test-lookup #:key file-name text line (column 0) offset
                      (file-name->parse-tree (const '())))
  (let* ((ctx   (test-context #:file-name file-name #:text text
                              #:line line #:column column
                              #:offset offset))
         (token (.tree ctx))
         (loc   (lookup-location token ctx
                                 #:file-name file-name
                                 #:file-name->text file-name->text
                                 #:file-name->parse-tree file-name->parse-tree
                                 #:resolve-file resolve-file)))
    (and=> loc location->string)))

(test-begin "language")

(test-begin "completion")

(define %completion-top (@@ (dzn parse complete) %completion-top))
(define %completion-interface (@@ (dzn parse complete) %completion-interface))
(define %completion-component (@@ (dzn parse complete) %completion-component))
(define %completion-behaviour(@@ (dzn parse complete) %completion-behaviour))

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
  '("in" "out" "enum" "extern" "subint")
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
  %completion-interface
  (test-complete #:file-name "interface6.dzn"))

(test-equal "language interface7"
  '()
  (test-complete #:file-name "interface7.dzn"))

(test-equal "language interface8"
  %completion-behaviour
  (test-complete #:file-name "interface8.dzn"))

(test-equal "language interface8a"
  %completion-behaviour
  (test-complete #:file-name "interface8a.dzn"))

(test-equal "language interface8b"
  %completion-behaviour
  (test-complete #:file-name "interface8b.dzn"))

(test-equal "language interface9"
  '("foo" "inevitable" "optional")
  (test-complete #:file-name "interface9.dzn"))

(test-equal "language interface9a"
  '("bar" "foo" "inevitable" "optional")
  (test-complete #:file-name "interface9a.dzn"))

(test-equal "language interface9b"
  '("bar" "foo" "inevitable" "optional")
  (test-complete #:file-name "interface9b.dzn"))

(test-equal "language interface9c"
  '("bar" "foo" "inevitable" "optional")
  (test-complete #:file-name "interface9c.dzn" #:line 10))

(test-equal "language interface9d"
  '("bar" "foo" "inevitable" "optional")
  (test-complete #:file-name "interface9d.dzn" #:line 10))

(test-equal "language interface10"
  '("b" "e" "false" "true")
  (test-complete #:file-name "interface10.dzn"))

(test-equal "language interface10a"
  '("b" "e" "false" "true")
  (test-complete #:file-name "interface10a.dzn" #:line 11 #:column 5))

(test-equal "language interface11"
  '("e.False" "e.True")
  (test-complete #:file-name "interface11.dzn"))

(test-equal "language interface11a"
  '("e.False" "e.True")
  (test-complete #:file-name "interface11a.dzn" #:line 11 #:column 6))

(test-equal "language interface12"
  '("e.False" "e.True")
  (test-complete #:file-name "interface12.dzn"))

(test-equal "language interface12a"
  '("e.False" "e.True")
  (test-complete #:file-name "interface12a.dzn" #:line 11 #:column 7))

(test-equal "language interface-behaviour before"
  '("in" "out" "enum" "extern" "subint")
  (test-complete #:file-name "interface-behaviour.dzn" #:line 3))

(test-equal "language interface-behaviour after"
  '("in" "out" "enum" "extern" "subint")
  (test-complete #:file-name "interface-behaviour.dzn" #:line 5))

(test-equal "language interface-behaviour before on"
  %completion-behaviour
  (test-complete #:file-name "interface-behaviour.dzn" #:line 8))

(test-equal "language interface-behaviour between on"
  %completion-behaviour
  (test-complete #:file-name "interface-behaviour.dzn" #:line 10))

(test-equal "language interface-behaviour after on"
  %completion-behaviour
  (test-complete #:file-name "interface-behaviour.dzn" #:line 12))

(test-equal "language component1"
  %completion-component
  (test-complete #:file-name "component1.dzn"))

(test-equal "language component1a"
  %completion-component
  (test-complete #:file-name "component1a.dzn"))

(test-equal "language component1b"
  '("I" "J")
  (test-complete #:file-name "component1b.dzn"))

(test-equal "language component1b --point=15,10"
  '("I" "J")
  (test-complete #:file-name "component1b.dzn" #:line 15 #:column 10))

(test-equal "language component1b --point=15,11"
  '("I" "J")
  (test-complete #:file-name "component1b.dzn" #:line 15 #:column 11))

(test-equal "language component1b --point=15,12"
  '("I" "J")
  (test-complete #:file-name "component1b.dzn" #:line 15 #:column 12))

(test-equal "language component1b --point=16,0"
  '("I" "J")
  (test-complete #:file-name "component1b.dzn" #:line 16 #:column 0))

(test-equal "language component2"
  %completion-behaviour
  (test-complete #:file-name "component2.dzn"))

(test-equal "language component2a"
  %completion-behaviour
  (test-complete #:file-name "component2a.dzn"))

(test-equal "language component2b"
  %completion-behaviour
  (test-complete #:file-name "component2b.dzn"))

(test-equal "language component2c"
  %completion-behaviour
  (test-complete #:file-name "component2c.dzn" #:line 20))

(test-equal "language component3"
  '("p.e()" "r.f()")
  (test-complete #:file-name "component3.dzn"))

(test-equal "language component3a"
  '("p.e()" "r.f()")
  (test-complete #:file-name "component3a.dzn"))

(test-equal "language component4"
  '("p.e()" "r.f()")
  (test-complete #:file-name "component4.dzn"))

(test-equal "language component5"
  '("bool" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component5.dzn"))

(test-equal "language component6"
  '("bool" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component6.dzn"))

(test-equal "language component6a"
  '("bool" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component6a.dzn" #:line 24))

(test-equal "language component6b"
  '("bool" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component6b.dzn"))

(test-equal "language component7"
  '("J.E" "bool" "enum" "extern" "on" "subint" "void")
  (test-complete #:file-name "component7.dzn"))

(test-equal "language component8"
  '("provides" "requires")
  (test-complete #:file-name "component8.dzn" #:offset 170))

(test-equal "language component9"
  '("i.e0()" "i.e1()")
  (test-complete #:file-name "component9.dzn" #:offset 142))

(test-equal "language component9a"
  '("i.e0()" "i.e1()")
  (test-complete #:file-name "component9a.dzn" #:offset 145))

(test-equal "language component10"
  '("bool" "i.a0()" "i.a1()" "void")
  (test-complete #:file-name "component10.dzn" #:offset 185))

(test-equal "language component10a"
  '("bool" "i.a0()" "i.a1()" "void")
  (test-complete #:file-name "component10a.dzn" #:offset 188))

(test-equal "completion component-requires provides"
  '( "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 13 #:column 11))

(test-equal "completion component-requires requires"
  '("external" "injected" "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 14 #:column 11))

(test-equal "completion component-requires external"
  '("injected" "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 15 #:column 20))

(test-equal "completion component-requires injected"
  '("external" "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 16 #:column 20))

(test-equal "completion component-requires external injected"
  '("ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 17 #:column 29))

(test-equal "completion component-requires injected external"
  '("ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 18 #:column 29))

(test-equal "completion component-empty"
  '("behaviour" "provides" "requires" "system")
  (test-complete #:file-name "component-empty.dzn" #:line 13))

(test-equal "completion component-provides before"
  '("behaviour" "provides" "requires" "system")
  (test-complete #:file-name "component-provides.dzn" #:line 13))

(test-equal "completion component-provides inside"
  '("IHello")
  (test-complete #:file-name "component-provides.dzn" #:line 14 #:column 10))

(test-equal "completion component-provides after"
  '("behaviour" "provides" "requires" "system")
  (test-complete #:file-name "component-provides.dzn" #:line 16))

(test-equal "completion component-behaviour before"
  '("provides" "requires")
  (test-complete #:file-name "component-behaviour.dzn" #:line 13))

(test-equal "completion component-behaviour after"
  '("provides" "requires")
  (test-complete #:file-name "component-behaviour.dzn" #:line 15))

(test-equal "completion component-behaviour behaviour"
  %completion-behaviour
  (test-complete #:file-name "component-behaviour.dzn" #:line 19))

(test-equal "completion component-behaviour end"
  %completion-behaviour
  (test-complete #:file-name "component-behaviour.dzn" #:line 21))

(test-equal "completion component-state"
  '("State.Uninitialized" "State.Initialized" "State.Active" "State.Inactive")
  (test-complete #:file-name "component-state.dzn" #:line 18 #:column 24))

(test-equal "completion component-on"
  '("p.hello(foo, bar)")
  (test-complete #:file-name "component-on.dzn" #:line 17 #:column 7))

(test-equal "completion component-enum member"
  '("fun()" "r.hello()" "Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum-member.dzn" #:line 25 #:column 18))

(test-equal "completion component-enum local"
  '("fun(_)" "r.hello()" "Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum-local.dzn" #:line 27 #:column 20))

(test-equal "completion interface-enum"
  '("bool" "enum" "extern" "ihello.Bool" "on" "subint" "void")
  (test-complete #:file-name "interface-enum.dzn" #:line 20))

(test-equal "language typo"
  '("provides" "requires")
  (test-complete #:file-name "typo.dzn" #:offset 219))

(test-equal "completion enum literal"
  '("Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum.dzn" #:line 10 #:column 13))

(test-equal "completion enum field"
  '("Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum.dzn" #:line 10 #:column 19))

(test-equal "completion enum local"
  '("m" "fun(_)" "Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum.dzn" #:line 35 #:column 15))

(test-equal "completion enum reply"
  '("b" "m" "fun(_)" "Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum.dzn" #:line 36 #:column 13))

(test-equal "completion enum formal"
  '("b" "m" "fun(_)" "Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum.dzn" #:line 30 #:column 13))

(test-equal "completion bool literal"
  '("false" "true")
  (test-complete #:file-name "component-bool.dzn" #:line 10 #:column 13))

(test-equal "completion bool local"
  '("m" "fun(_)" "false" "true")
  (test-complete #:file-name "component-bool.dzn" #:line 35 #:column 15))

(test-equal "completion bool reply"
  '("b" "m" "fun(_)" "false" "true")
  (test-complete #:file-name "component-bool.dzn" #:line 36 #:column 13))

(test-equal "completion bool formal"
  '("b" "m" "fun(_)" "false" "true")
  (test-complete #:file-name "component-bool.dzn" #:line 30 #:column 13))

(test-equal "completion int literal"
  '()
  (test-complete #:file-name "component-int.dzn" #:line 10 #:column 13))

(test-equal "completion int local"
  '("m" "fun(_)")
  (test-complete #:file-name "component-int.dzn" #:line 35 #:column 15))

(test-equal "completion int reply"
  '("b" "m" "fun(_)")
  (test-complete #:file-name "component-int.dzn" #:line 36 #:column 13))

(test-equal "completion int formal"
  '("b" "m" "fun(_)")
  (test-complete #:file-name "component-int.dzn" #:line 30 #:column 13))

(test-equal "completion data literal"
  '()
  (test-complete #:file-name "component-data.dzn" #:line 10 #:column 13))

(test-equal "completion data local"
  '("m")
  (test-complete #:file-name "component-data.dzn" #:line 35 #:column 15))

(test-equal "completion data formal"
  '("b" "m")
  (test-complete #:file-name "component-data.dzn" #:line 30 #:column 13))

(test-equal "completion field-test field"
  '("e.False" "e.True")
  (test-complete #:file-name "enum.dzn" #:line 9 #:column 7))

(test-equal "completion enum-literal with comment"
  '("Tri_bool.False" "Tri_bool.True" "Tri_bool.Whatever")
  (test-complete #:file-name "enum.dzn" #:line 10 #:column 17))

(test-equal "completion provides imported interfaces"
  '("external" "injected" "ihello" "ihello_enum" "ihello_int")
  (test-complete #:file-name "import.dzn" #:line 8 #:column 10
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "completion on imported triggers"
  '("p.hello()" "r.world()")
  (test-complete #:file-name "import.dzn" #:line 19 #:column 9
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "completion provides interfaces, imported, namespace"
  '("ihello" "igoodbye" "iworld")
  (test-complete #:file-name "space-hello.dzn" #:line 12 #:column 12
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "completion system before ports"
  '("provides" "requires")
  (test-complete #:file-name "system.dzn" #:line 26))

(test-equal "completion system between ports"
  '("provides" "requires")
  (test-complete #:file-name "system.dzn" #:line 28))

(test-equal "completion system after ports"
  '("provides" "requires")
  (test-complete #:file-name "system.dzn" #:line 30))

(test-equal "completion system before instance"
  '("c" "c.hh" "c.ww" "d" "d.hh" "d.ww" "h" "hello" "system_hello" "w")
  (test-complete #:file-name "system.dzn" #:line 33))

(test-equal "completion system after instance"
  '("c" "c.hh" "c.ww" "d" "d.hh" "d.ww" "h" "hello" "system_hello" "w")
  (test-complete #:file-name "system.dzn" #:line 35))

(test-equal "completion system after binding"
  '("c" "c.hh" "c.ww" "d" "d.hh" "d.ww" "h" "hello" "system_hello" "w")
  (test-complete #:file-name "system.dzn" #:line 37))

(test-equal "completion system binding port provides"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 50 #:column 12))

(test-equal "completion system binding port requires"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 51 #:column 12))

(test-equal "completion system binding instance provides"
  '("d.ww" "h")
  (test-complete #:file-name "system-binding.dzn" #:line 52 #:column 12))

(test-equal "completion system binding instance requires"
  '("d.hh" "w")
  (test-complete #:file-name "system-binding.dzn" #:line 53 #:column 12))

(test-equal "completion system end-point provides"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 54 #:column 14))

(test-equal "completion system end-point requires"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 55 #:column 14))

(test-end)

(test-begin "lookup")

(test-equal "lookup port->interface"
  "lookup.dzn:56:10"
  (test-lookup #:file-name "lookup.dzn" #:line 46 #:column 11))

(test-equal "lookup instance->component"
  "lookup.dzn:26:10"
  (test-lookup #:file-name "lookup.dzn" #:line 77 #:column 6))

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

(test-equal "lookup variable-expression->variable"
  "lookup.dzn:50:9"
  (test-lookup #:file-name "lookup.dzn" #:line 52 #:column 54))

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

(test-equal "lookup enum var->formal"
  "component-enum.dzn:28:19"
  (test-lookup #:file-name "component-enum.dzn" #:line 30 #:column 13))

(test-equal "lookup bool var->formal"
  "component-bool.dzn:28:19"
  (test-lookup #:file-name "component-bool.dzn" #:line 30 #:column 13))

(test-equal "lookup int var->formal"
  "component-int.dzn:28:19"
  (test-lookup #:file-name "component-int.dzn" #:line 30 #:column 13))

(test-equal "lookup data var->formal"
  "component-data.dzn:28:19"
  (test-lookup #:file-name "component-data.dzn" #:line 30 #:column 13))

(test-equal "lookup data var->formal"
  "component-data.dzn:33:16"
  (test-lookup #:file-name "component-data.dzn" #:line 36 #:column 13))

(test-equal "lookup data arg->formal"
  "component-data.dzn:33:16"
  (test-lookup #:file-name "component-data.dzn" #:line 37 #:column 14))

(test-equal "lookup variable->enum-type"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 34 #:column 4))

(test-equal "lookup variable->int-type"
  "int.dzn:1:7"
  (test-lookup #:file-name "int.dzn" #:line 8 #:column 4))

(test-equal "lookup field-test->var"
  "enum.dzn:8:9"
  (test-lookup #:file-name "enum.dzn" #:line 9 #:column 5))

(test-equal "lookup field-test->enum-field"
  "enum.dzn:1:17"
  (test-lookup #:file-name "enum.dzn" #:line 9 #:column 7))

(test-equal "lookup enum-literal->field with comment"
  "enum.dzn:18:2"
  (test-lookup #:file-name "enum.dzn" #:line 10 #:column 26))

(test-equal "lookup variable-type->interface enum"
  "interface-enum.dzn:3:7"
  (test-lookup #:file-name "interface-enum.dzn" #:line 18 #:column 4))

(test-equal "lookup variable-type->namespace enum"
  "namespace-enum.dzn:1:22"
  (test-lookup #:file-name "namespace-enum.dzn" #:line 8 #:column 4))

(test-equal "lookup variable-type->deep.space enum"
  "deep-space-enum.dzn:1:39"
  (test-lookup #:file-name "deep-space-enum.dzn" #:line 8 #:column 4))

(test-equal "lookup call->function"
  "function.dzn:7:9"
  (test-lookup #:file-name "function.dzn" #:line 12 #:column 16))

(test-equal "lookup on->imported trigger-port"
  "import.dzn:7:23"
  (test-lookup #:file-name "import.dzn" #:line 19  #:column 7
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup port->imported-interface"
  "ihello-int.dzn:3:10"
  (test-lookup #:file-name "import.dzn" #:line 8 #:column 11
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup type->imported enum"
  "ienum.dzn:1:5"
  (test-lookup #:file-name "import.dzn" #:line 12 #:column 4
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup type->imported enum"
  "ienum.dzn:1:5"
  (test-lookup #:file-name "ihello-enum.dzn" #:line 10 #:column 4
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup enum-literal->imported enum field"
  "ienum.dzn:1:11"
  (test-lookup #:file-name "ihello-enum.dzn" #:line 13 #:column 20
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup port->namespace-interface"
  "space-ihello.dzn:7:12"
  (test-lookup #:file-name "space-hello.dzn" #:line 12 #:column 13
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup illegal interface trigger->event"
  "illegal.dzn:3:10"
  (test-lookup #:file-name "illegal.dzn" #:line 7 #:column 7))

(test-equal "lookup illegal trigger->port"
  "illegal.dzn:14:18"
  (test-lookup #:file-name "illegal.dzn" #:line 17 #:column 7))

(test-equal "lookup illegal trigger->event"
  "illegal.dzn:3:10"
  (test-lookup #:file-name "illegal.dzn" #:line 17 #:column 9))

(test-equal "lookup import"
  "test/language/ihello.dzn:1:0"
  (test-lookup #:file-name "import.dzn" #:line 1 #:column 0))

(test-equal "lookup global.space global"
  "global.space.dzn:4:9"
  (test-lookup #:file-name "global.space.dzn" #:line 7 #:column 7))

(test-equal "lookup global.space namespaced"
  "global.space.dzn:1:7"
  (test-lookup #:file-name "global.space.dzn" #:line 8 #:column 7))

(test-equal "lookup double.space"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "double.space.dzn" #:line 11 #:column 9))

(test-equal "lookup double.space prefix"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "double.space.dzn" #:line 11 #:column 9))

(test-equal "lookup import-double.space"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "import-double.space.dzn" #:line 7 #:column 9
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup import-double.space prefix"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "import-double.space.dzn" #:line 8 #:column 9
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "lookup reply-port->port"
  "blocking.dzn:16:18"
  (test-lookup #:file-name "blocking.dzn" #:line 24 #:column 27))

(test-equal "lookup out-binding->variable"
  "blocking.dzn:21:8"
  (test-lookup #:file-name "blocking.dzn" #:line 23 #:column 37))

(test-end)

(test-end)
