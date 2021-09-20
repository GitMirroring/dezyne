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

;;; Tests for the language module.
;;;
;;; USAGE:
;;;  * ./pre-inst-env guile test/dzn/language.scm
;;;  * make check TESTS=test/dzn/language

;;; Code:

(define-module (test dzn language)
  #:use-module (dzn commands language)
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

(test-equal "interface0"
  %completion-top
  (test-complete #:file-name "interface0.dzn"))

(test-equal "interface1"
  %completion-top
  (test-complete #:file-name "interface1.dzn"))

(test-equal "interface1b"
  '()
  (test-complete #:file-name "interface1b.dzn"))

(test-equal "interface2"
  %completion-top
  (test-complete #:file-name "interface2.dzn"))

(test-equal "interface3"
  '("in" "out" "enum" "extern" "subint")
  (test-complete #:file-name "interface3.dzn"))

(test-equal "interface4.dzn"
  '("bool" "void")
  (test-complete #:file-name "interface4.dzn"))

(test-equal "interface5"
  '("bool" "void")
  (test-complete #:file-name "interface5.dzn"))

(test-equal "interface5b"
  '("E" "bool" "void")
  (test-complete #:file-name "interface5b.dzn"))

(test-equal "interface6"
  %completion-interface
  (test-complete #:file-name "interface6.dzn"))

(test-equal "interface7"
  '()
  (test-complete #:file-name "interface7.dzn"))

(test-equal "interface8"
  %completion-behaviour
  (test-complete #:file-name "interface8.dzn"))

(test-equal "interface8a"
  %completion-behaviour
  (test-complete #:file-name "interface8a.dzn"))

(test-equal "interface8b"
  %completion-behaviour
  (test-complete #:file-name "interface8b.dzn"))

(test-equal "interface9"
  '("foo" "inevitable" "optional")
  (test-complete #:file-name "interface9.dzn"))

(test-equal "interface9a"
  '("bar" "foo" "inevitable" "optional")
  (test-complete #:file-name "interface9a.dzn"))

(test-equal "interface9b"
  '("foo" "inevitable" "optional")
  (test-complete #:file-name "interface9b.dzn"))

(test-equal "interface9c"
  '("foo" "inevitable" "optional")
  (test-complete #:file-name "interface9c.dzn" #:line 10))

(test-equal "interface9d"
  '("bar" "foo" "inevitable" "optional")
  (test-complete #:file-name "interface9d.dzn" #:line 10))

(test-equal "interface10"
  '("b" "e" "false" "otherwise" "true")
  (test-complete #:file-name "interface10.dzn"))

(test-equal "interface10a"
  '("b" "e" "false" "otherwise" "true")
  (test-complete #:file-name "interface10a.dzn" #:line 11 #:column 5))

(test-equal "interface11"
  '("e.False" "e.True")
  (test-complete #:file-name "interface11.dzn"))

(test-equal "interface11a"
  '("e.False" "e.True")
  (test-complete #:file-name "interface11a.dzn" #:line 11 #:column 6))

(test-equal "interface12"
  '("e.False" "e.True")
  (test-complete #:file-name "interface12.dzn"))

(test-equal "interface12a"
  '("e.False" "e.True")
  (test-complete #:file-name "interface12a.dzn" #:line 11 #:column 7))

(test-equal "interface13"
  '("e.False" "e.True")
  (test-complete #:file-name "interface13.dzn"))

(test-equal "interface13a"
  '("e.False" "e.True")
  (test-complete #:file-name "interface13a.dzn" #:line 11 #:column 10))

(test-equal "interface-behaviour before"
  '("in" "out" "enum" "extern" "subint")
  (test-complete #:file-name "interface-behaviour.dzn" #:line 3))

(test-equal "interface-behaviour after"
  '("in" "out" "enum" "extern" "subint")
  (test-complete #:file-name "interface-behaviour.dzn" #:line 5))

(test-equal "interface-behaviour before on"
  %completion-behaviour
  (test-complete #:file-name "interface-behaviour.dzn" #:line 8))

(test-equal "interface-behaviour between on"
  %completion-behaviour
  (test-complete #:file-name "interface-behaviour.dzn" #:line 10))

(test-equal "interface-behaviour after on"
  %completion-behaviour
  (test-complete #:file-name "interface-behaviour.dzn" #:line 12))

(test-equal "component0"
  %completion-top
  (test-complete #:file-name "component0.dzn"))

(test-equal "component1"
  '("provides" "requires")
  (test-complete #:file-name "component1.dzn"))

(test-equal "component1a --point=15,10"
  '("Ihello" "Iworld")
  (test-complete #:file-name "component1a.dzn" #:line 15 #:column 10))

(test-equal "component1a --point=15,11"
  '("Ihello" "Iworld")
  (test-complete #:file-name "component1a.dzn" #:line 15 #:column 11))

(test-equal "component1a --point=15,12"
  '("Ihello" "Iworld")
  (test-complete #:file-name "component1a.dzn" #:line 15 #:column 12))

(test-equal "component1a --point=16,0"
  '("Ihello" "Iworld")
  (test-complete #:file-name "component1a.dzn" #:line 16 #:column 0))

(test-equal "component1b"
  '("Ihello" "Iworld")
  (test-complete #:file-name "component1b.dzn"))

(test-equal "component1b --point=15,11"
  '("Ihello" "Iworld")
  (test-complete #:file-name "component1b.dzn" #:line 15 #:column 11))

(test-equal "component1c"
  '("provides" "requires")
  (test-complete #:file-name "component1c.dzn"))

(test-equal "component2"
  %completion-behaviour
  (test-complete #:file-name "component2.dzn"))

(test-equal "component2a"
  %completion-behaviour
  (test-complete #:file-name "component2a.dzn"))

(test-equal "component2b"
  %completion-behaviour
  (test-complete #:file-name "component2b.dzn"))

(test-equal "component2c"
  %completion-behaviour
  (test-complete #:file-name "component2c.dzn" #:line 20))

(test-equal "component3"
  '("p.e()" "r.f()")
  (test-complete #:file-name "component3.dzn"))

(test-equal "component3a"
  '("p.e()" "r.f()")
  (test-complete #:file-name "component3a.dzn"))

(test-equal "component4"
  '("illegal" "p.e()" "r.f()")
  (test-complete #:file-name "component4.dzn"))

(test-equal "component5"
  '("bool" "if" "illegal" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component5.dzn"))

(test-equal "component5a"
  '("illegal" "p.e()" "r.f()")
  (test-complete #:file-name "component5a.dzn"))

(test-equal "component6"
  '("bool" "if" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component6.dzn"))

(test-equal "component6a"
  '("bool" "if" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component6a.dzn" #:line 24))

(test-equal "component6b"
  '("bool" "if" "p.f()" "r.e()" "void")
  (test-complete #:file-name "component6b.dzn"))

(test-equal "component7"
  '("J.E" "bool" "enum" "extern" "on" "subint" "void")
  (test-complete #:file-name "component7.dzn"))

(test-equal "component8"
  '("provides" "requires")
  (test-complete #:file-name "component8.dzn" #:offset 170))

(test-equal "component9"
  '("i.e0()" "i.e1()")
  (test-complete #:file-name "component9.dzn" #:offset 142))

(test-equal "component9a"
  '("i.e0()" "i.e1()" "illegal")
  (test-complete #:file-name "component9a.dzn" #:offset 145))

(test-equal "component10"
  '("bool" "i.a0()" "i.a1()" "if" "illegal" "void")
  (test-complete #:file-name "component10.dzn" #:offset 185))

(test-equal "component10a"
  '("bool" "i.a0()" "i.a1()" "if" "void")
  (test-complete #:file-name "component10a.dzn" #:offset 188))

(test-equal "component11"
  '("false" "j.e1()" "m" "true")
  (test-complete #:file-name "component11.dzn"))

(test-equal "component11a"
  '("false" "j.e1()" "m" "true")
  (test-complete #:file-name "component11a.dzn" #:line 24 #:column 18))

(test-equal "component12"
  '("false" "j.e1()" "m" "true")
  (test-complete #:file-name "component12.dzn"))

(test-equal "component12a"
  '("false" "j.e1()" "m" "true")
  (test-complete #:file-name "component12a.dzn" #:line 24 #:column 23))

(test-equal "component-requires provides"
  '( "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 13 #:column 11))

(test-equal "component-requires requires"
  '("external" "injected" "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 14 #:column 11))

(test-equal "component-requires external"
  '("injected" "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 15 #:column 20))

(test-equal "component-requires injected"
  '("external" "ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 16 #:column 20))

(test-equal "component-requires external injected"
  '("ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 17 #:column 29))

(test-equal "component-requires injected external"
  '("ihello")
  (test-complete #:file-name "component-requires.dzn" #:line 18 #:column 29))

(test-equal "component-empty"
  '("behaviour" "provides" "requires" "system")
  (test-complete #:file-name "component-empty.dzn" #:line 13))

(test-equal "component-provides before"
  '("behaviour" "provides" "requires" "system")
  (test-complete #:file-name "component-provides.dzn" #:line 13))

(test-equal "component-provides inside"
  '("IHello")
  (test-complete #:file-name "component-provides.dzn" #:line 14 #:column 10))

(test-equal "component-provides after"
  '("behaviour" "provides" "requires" "system")
  (test-complete #:file-name "component-provides.dzn" #:line 16))

(test-equal "component-behaviour before"
  '("provides" "requires")
  (test-complete #:file-name "component-behaviour.dzn" #:line 13))

(test-equal "component-behaviour after"
  '("provides" "requires")
  (test-complete #:file-name "component-behaviour.dzn" #:line 15))

(test-equal "component-behaviour behaviour"
  %completion-behaviour
  (test-complete #:file-name "component-behaviour.dzn" #:line 19))

(test-equal "component-behaviour end"
  %completion-behaviour
  (test-complete #:file-name "component-behaviour.dzn" #:line 21))

(test-equal "component-state"
  '("State.Active" "State.Inactive" "State.Initialized" "State.Uninitialized")
  (test-complete #:file-name "component-state.dzn" #:line 18 #:column 24))

(test-equal "component-on"
  '("p.hello(foo, bar)")
  (test-complete #:file-name "component-on.dzn" #:line 17 #:column 7))

(test-equal "component-enum member"
  '("Bool.False" "Bool.True" "fun()" "r.hello()")
  (test-complete #:file-name "component-enum-member.dzn" #:line 25 #:column 18))

(test-equal "component-enum local"
  '("Bool.False" "Bool.True" "fun(_)" "r.hello()")
  (test-complete #:file-name "component-enum-local.dzn" #:line 27 #:column 20))

(test-equal "interface-enum"
  '("bool" "enum" "extern" "ihello.Bool" "on" "subint" "void")
  (test-complete #:file-name "interface-enum.dzn" #:line 20))

(test-equal "typo"
  '("provides" "requires")
  (test-complete #:file-name "typo.dzn" #:offset 219))

(test-equal "bool literal"
  '("false" "true")
  (test-complete #:file-name "component-bool.dzn" #:line 10 #:column 13))

(test-equal "bool local"
  '("false" "fun(_)" "m" "true" "w.hello()")
  (test-complete #:file-name "component-bool.dzn" #:line 36 #:column 15))

(test-equal "bool reply"
  '("b" "false" "fun(_)" "m" "true")
  (test-complete #:file-name "component-bool.dzn" #:line 37 #:column 13))

(test-equal "bool formal"
  '("b" "false" "fun(_)" "m" "true")
  (test-complete #:file-name "component-bool.dzn" #:line 31 #:column 13))

(test-equal "enum literal"
  '("Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum.dzn" #:line 10 #:column 13))

(test-equal "enum field"
  '("Bool.False" "Bool.True")
  (test-complete #:file-name "component-enum.dzn" #:line 10 #:column 19))

(test-equal "enum local"
  '("Bool.False" "Bool.True" "fun(_)" "m" "w.hello()")
  (test-complete #:file-name "component-enum.dzn" #:line 36 #:column 15))

(test-equal "enum reply"
  '("Bool.False" "Bool.True" "b" "fun(_)" "m")
  (test-complete #:file-name "component-enum.dzn" #:line 37 #:column 13))

(test-equal "enum formal"
  '("Bool.False" "Bool.True" "b" "fun(_)" "m")
  (test-complete #:file-name "component-enum.dzn" #:line 31 #:column 13))

(test-equal "int literal"
  '()
  (test-complete #:file-name "component-int.dzn" #:line 10 #:column 13))

(test-equal "int local"
  '("fun(_)" "m" "w.hello()")
  (test-complete #:file-name "component-int.dzn" #:line 36 #:column 15))

(test-equal "int reply"
  '("b" "fun(_)" "m")
  (test-complete #:file-name "component-int.dzn" #:line 37 #:column 13))

(test-equal "int formal"
  '("b" "fun(_)" "m")
  (test-complete #:file-name "component-int.dzn" #:line 31 #:column 13))

(test-equal "data literal"
  '()
  (test-complete #:file-name "component-data.dzn" #:line 10 #:column 13))

(test-equal "data local"
  '("m")
  (test-complete #:file-name "component-data.dzn" #:line 36 #:column 15))

(test-equal "data formal"
  '("b" "m")
  (test-complete #:file-name "component-data.dzn" #:line 31 #:column 13))

(test-equal "field-test field"
  '("e.False" "e.True")
  (test-complete #:file-name "enum.dzn" #:line 9 #:column 7))

(test-equal "enum-literal with comment"
  '("Tri_bool.False" "Tri_bool.True" "Tri_bool.Whatever")
  (test-complete #:file-name "enum.dzn" #:line 10 #:column 17))

(test-equal "import requires"
  '("external" "injected" "ihello" "ihello_enum" "ihello_int")
  (test-complete #:file-name "import.dzn" #:line 8 #:column 10
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "import statemement"
  '("Bool" "bool" "if" "int" "m" "p.world()" "r.hello()" "s.hello()" "void")
  (test-complete #:file-name "import.dzn" #:line 27 #:column 18
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "import event assign expression"
  '("Bool.False" "Bool.True" "b" "fun(_)" "m" "s.hello()")
  (test-complete #:file-name "import.dzn" #:line 23 #:column 10
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "import event variable expression"
  '("r.hello()")
  (test-complete #:file-name "import.dzn" #:line 27 #:column 27
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "on imported triggers"
  '("p.hello()" "r.world()" "s.world()")
  (test-complete #:file-name "import.dzn" #:line 20 #:column 9
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "space-ihello space nest types"
  '("Bool" "bool" "data_t" "enum" "extern" "ihello.Bool" "int" "on" "subint" "void")
  (test-complete #:file-name "space-ihello.dzn" #:line 31))

(test-equal "space-ihello space types"
  '("Bool" "bool" "data_t" "enum" "extern" "ihello.Bool" "int" "nest.iworld.Bool" "on" "subint" "void")
  (test-complete #:file-name "space-ihello.dzn" #:line 43))

(test-equal "space-ihello types"
  '("bool" "enum" "extern" "on" "space.Bool" "space.data_t" "space.ihello.Bool" "space.int" "space.nest.iworld.Bool" "subint" "void")
  (test-complete #:file-name "space-ihello.dzn" #:line 54))

(test-equal "space-ihello space interfaces"
  '("ihello" "nest.iworld")
  (test-complete #:file-name "space-ihello.dzn" #:line 39 #:column 12))

(test-equal "space-ihello interfaces"
  '("space.ihello" "space.nest.iworld")
  (test-complete #:file-name "space-ihello.dzn" #:line 50 #:column 10))

(test-equal "space-hello space interfaces"
  '("ihello" "iworld" "nest.iworld")
  (test-complete #:file-name "space-hello.dzn" #:line 27 #:column 12
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "space-hello interfaces"
  '("iworld" "space.ihello" "space.iworld" "space.nest.iworld")
  (test-complete #:file-name "space-hello.dzn" #:line 38 #:column 10
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "space-hello space types"
  '("Bool" "bool" "data_t" "enum" "extern" "ihello.Bool" "int" "nest.iworld.Bool" "on" "subint" "void")
  (test-complete #:file-name "space-hello.dzn" #:line 31
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "space-hello types"
  '("bool" "enum" "extern" "on" "space.Bool" "space.data_t" "space.ihello.Bool" "space.int" "space.nest.iworld.Bool" "subint" "void")
  (test-complete #:file-name "space-hello.dzn" #:line 42
                 #:file-name->parse-tree file-name->parse-tree))

(test-equal "system before ports"
  '("provides" "requires")
  (test-complete #:file-name "system.dzn" #:line 26))

(test-equal "system between ports"
  '("provides" "requires")
  (test-complete #:file-name "system.dzn" #:line 28))

(test-equal "system after ports"
  '("provides" "requires")
  (test-complete #:file-name "system.dzn" #:line 30))

(test-equal "system before instance"
  '("c" "c.hh" "c.ww" "d" "d.hh" "d.ww" "h" "hello" "system_hello" "w")
  (test-complete #:file-name "system.dzn" #:line 33))

(test-equal "system after instance"
  '("c" "c.hh" "c.ww" "d" "d.hh" "d.ww" "h" "hello" "system_hello" "w")
  (test-complete #:file-name "system.dzn" #:line 35))

(test-equal "system after binding"
  '("c" "c.hh" "c.ww" "d" "d.hh" "d.ww" "h" "hello" "system_hello" "w")
  (test-complete #:file-name "system.dzn" #:line 37))

(test-equal "system binding port provides"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 50 #:column 12))

(test-equal "system binding port requires"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 51 #:column 12))

(test-equal "system binding instance provides"
  '("d.ww" "h")
  (test-complete #:file-name "system-binding.dzn" #:line 52 #:column 12))

(test-equal "system binding instance requires"
  '("d.hh" "w")
  (test-complete #:file-name "system-binding.dzn" #:line 53 #:column 12))

(test-equal "system end-point provides instance."
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 54 #:column 14))

(test-equal "system end-point provides instance. on"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 54 #:column 13))

(test-equal "system end-point require instance."
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 55 #:column 14))

(test-equal "system end-point requires instance. on"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 55 #:column 13))

(test-equal "system end-point provides instance"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 56 #:column 13))

(test-equal "system end-point provides instance on"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 56 #:column 12))

(test-equal "system end-point requires instance"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 57 #:column 13))

(test-equal "system end-point requires instance on"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 57 #:column 12))

(test-equal "system end-point provides instance incomplete"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 56 #:column 13))

(test-equal "system end-point provides instance on incomplete"
  '("c.hh" "d.hh")
  (test-complete #:file-name "system-binding.dzn" #:line 56 #:column 12))

(test-equal "system end-point requires instance incomplete"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 57 #:column 13))

(test-equal "system end-point requires instance on incomplete"
  '("c.ww" "d.ww")
  (test-complete #:file-name "system-binding.dzn" #:line 57 #:column 12))

(test-equal "component-incomplete-port before port"
  '("provides" "requires")
  (test-complete #:file-name "component-incomplete-port.dzn" #:line 13))

(test-equal "component-incomplete-port after port"
  '("provides" "requires")
  (test-complete #:file-name "component-incomplete-port.dzn" #:line 18))

(test-expect-fail 1)
(test-equal "component-incomplete-port after behaviour"
  '()
  (test-complete #:file-name "component-incomplete-port.dzn" #:line 30))

(test-equal "component-incomplete-port behaviour"
  %completion-behaviour
  (test-complete #:file-name "component-incomplete-port.dzn" #:line 21))

(test-expect-fail 1)
(test-equal "component-incomplete-port behaviour end"
  %completion-behaviour
  (test-complete #:file-name "component-incomplete-port.dzn" #:line 28))

(test-equal "component-incomplete-port on"
  '("bool" "if" "void" "w.hello()")
  (test-complete #:file-name "component-incomplete-port.dzn" #:line 26))

(test-equal "component-incomplete-action before port"
  '("provides" "requires")
  (test-complete #:file-name "component-incomplete-action.dzn" #:line 13))

(test-equal "component-incomplete-action after port"
  '("provides" "requires")
  (test-complete #:file-name "component-incomplete-action.dzn" #:line 18))

(test-equal "component-incomplete-action after behaviour"
  '()
  (test-complete #:file-name "component-incomplete-action.dzn" #:line 30))

(test-equal "component-incomplete-action behaviour"
  %completion-behaviour
  (test-complete #:file-name "component-incomplete-action.dzn" #:line 21))

(test-equal "component-incomplete-action behaviour end"
  %completion-behaviour
  (test-complete #:file-name "component-incomplete-action.dzn" #:line 28))

(test-equal "component-incomplete-action on"
  '("bool" "if" "void" "w.hello()" "w_o_w.hello()")
  (test-complete #:file-name "component-incomplete-action.dzn" #:line 26))

(test-equal "variable-incomplete"
  '()
  (test-complete #:file-name "variable-incomplete.dzn" #:line 7 #:column 9))

(test-equal "partial-type-name"
  '("bool" "void")
  (test-complete #:file-name "partial-type-name.dzn"))

(test-equal "partial-type-name on"
  '("bool" "void")
  (test-complete #:file-name "partial-type-name.dzn" #:line 3 #:column 6))

(test-equal "partial-enum-literal"
  '("E.A" "E.B")
  (test-complete #:file-name "partial-enum-literal.dzn" #:line 7 #:column 12))

(test-equal "partial-enum-literal on"
  '("E.A" "E.B")
  (test-complete #:file-name "partial-enum-literal.dzn" #:line 7 #:column 11))

(test-equal "enum-variable-expression missing"
  '("Bool.False" "Bool.True")
  (test-complete #:file-name "enum-variable-expression-missing.dzn" #:line 8 #:column 13))

(test-equal "partial-trigger-name"
  '("hello" "inevitable" "option" "optional")
  (test-complete #:file-name "partial-trigger-name.dzn"))

(test-end)

(test-begin "lookup")

(test-equal "port->interface"
  "lookup.dzn:56:10"
  (test-lookup #:file-name "lookup.dzn" #:line 46 #:column 11))

(test-equal "instance->component"
  "lookup.dzn:26:10"
  (test-lookup #:file-name "lookup.dzn" #:line 77 #:column 6))

(test-equal "port->imported-interface, with fallback"
  "ilookup.dzn:24:10"
  (test-lookup #:file-name "lookup.dzn" #:line 28 #:column 13
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "trigger->event"
  "ilookup.dzn:26:10"
  (test-lookup #:file-name "ilookup.dzn" #:line 32 #:column 7))

(test-equal "action->event"
  "ilookup.dzn:27:11"
  (test-lookup #:file-name "ilookup.dzn" #:line 33 #:column 29))

(test-equal "enum variable->type"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 34 #:column 4))

(test-equal "variable-expression->variable"
  "lookup.dzn:50:9"
  (test-lookup #:file-name "lookup.dzn" #:line 52 #:column 54))

(test-equal "enum-literal->type"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 28))

(test-equal "enum-literal->field"
  "lookup.dzn:33:14"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 30))

(test-equal "trigger->event"
  "ilookup.dzn:26:10"
  (test-lookup #:file-name "ilookup.dzn" #:line 32 #:column 7))

(test-equal "trigger->port"
  "lookup.dzn:46:25"
  (test-lookup #:file-name "lookup.dzn" #:line 52 #:column 12))

(test-equal "action->port"
  "lookup.dzn:46:25"
  (test-lookup #:file-name "lookup.dzn" #:line 51 #:column 24))

(test-equal "action->event"
  "lookup.dzn:58:10"
  (test-lookup #:file-name "lookup.dzn" #:line 51 #:column 27))

(test-equal "end-point->port"
  "lookup.dzn:72:18"
  (test-lookup #:file-name "lookup.dzn" #:line 79 #:column 6))

(test-equal "end-point->component.port"
  "lookup.dzn:28:18"
  (test-lookup #:file-name "lookup.dzn" #:line 79 #:column 14))

(test-equal "end-point->instance"
  "lookup.dzn:77:17"
  (test-lookup #:file-name "lookup.dzn" #:line 79 #:column 12))

(test-equal "var->enum variable"
  "lookup.dzn:34:6"
  (test-lookup #:file-name "lookup.dzn" #:line 35 #:column 26))

(test-equal "var->int variable"
  "int.dzn:8:8"
  (test-lookup #:file-name "int.dzn" #:line 9 #:column 5))

(test-equal "bool var->formal"
  "component-bool.dzn:29:19"
  (test-lookup #:file-name "component-bool.dzn" #:line 31 #:column 13))

(test-equal "enum var->formal"
  "component-enum.dzn:29:19"
  (test-lookup #:file-name "component-enum.dzn" #:line 31 #:column 13))

(test-equal "int var->formal"
  "component-int.dzn:29:19"
  (test-lookup #:file-name "component-int.dzn" #:line 31 #:column 13))

(test-equal "data var->formal"
  "component-data.dzn:29:19"
  (test-lookup #:file-name "component-data.dzn" #:line 31 #:column 13))

(test-equal "data var->formal"
  "component-data.dzn:34:16"
  (test-lookup #:file-name "component-data.dzn" #:line 37 #:column 13))

(test-equal "data arg->formal"
  "component-data.dzn:34:16"
  (test-lookup #:file-name "component-data.dzn" #:line 38 #:column 14))

(test-equal "variable->enum-type"
  "lookup.dzn:33:9"
  (test-lookup #:file-name "lookup.dzn" #:line 34 #:column 4))

(test-equal "variable->int-type"
  "int.dzn:1:7"
  (test-lookup #:file-name "int.dzn" #:line 8 #:column 4))

(test-equal "field-test->var"
  "enum.dzn:8:9"
  (test-lookup #:file-name "enum.dzn" #:line 9 #:column 5))

(test-equal "field-test->enum-field"
  "enum.dzn:1:17"
  (test-lookup #:file-name "enum.dzn" #:line 9 #:column 7))

(test-equal "enum-literal->field with comment"
  "enum.dzn:18:2"
  (test-lookup #:file-name "enum.dzn" #:line 10 #:column 26))

(test-equal "variable-type->interface enum"
  "interface-enum.dzn:3:7"
  (test-lookup #:file-name "interface-enum.dzn" #:line 18 #:column 4))

(test-equal "variable-type->namespace enum"
  "namespace-enum.dzn:1:22"
  (test-lookup #:file-name "namespace-enum.dzn" #:line 8 #:column 4))

(test-equal "variable-type->deep.space enum"
  "deep-space-enum.dzn:1:39"
  (test-lookup #:file-name "deep-space-enum.dzn" #:line 8 #:column 4))

(test-equal "call->function"
  "function.dzn:7:9"
  (test-lookup #:file-name "function.dzn" #:line 12 #:column 16))

(test-equal "on->imported trigger-port"
  "import.dzn:7:23"
  (test-lookup #:file-name "import.dzn" #:line 20  #:column 7
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "port->imported-interface"
  "ihello-int.dzn:3:10"
  (test-lookup #:file-name "import.dzn" #:line 8 #:column 11
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "type->imported enum"
  "ienum.dzn:1:5"
  (test-lookup #:file-name "import.dzn" #:line 13 #:column 4
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "type->imported enum"
  "ienum.dzn:1:5"
  (test-lookup #:file-name "ihello-enum.dzn" #:line 10 #:column 4
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "enum-literal->imported enum field"
  "ienum.dzn:1:11"
  (test-lookup #:file-name "ihello-enum.dzn" #:line 13 #:column 20
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "port->namespace-interface"
  "space-ihello.dzn:7:12"
  (test-lookup #:file-name "space-hello.dzn" #:line 27 #:column 13
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "illegal interface trigger->event"
  "illegal.dzn:3:10"
  (test-lookup #:file-name "illegal.dzn" #:line 7 #:column 7))

(test-equal "illegal trigger->port"
  "illegal.dzn:14:18"
  (test-lookup #:file-name "illegal.dzn" #:line 17 #:column 7))

(test-equal "illegal trigger->event"
  "illegal.dzn:3:10"
  (test-lookup #:file-name "illegal.dzn" #:line 17 #:column 9))

(test-equal "import"
  "test/language/ihello.dzn:1:0"
  (test-lookup #:file-name "import.dzn" #:line 1))

(test-equal "import nonexistent"
  #f
  (test-lookup #:file-name "import-nonexistent.dzn" #:line 1))

(test-equal "global.space global"
  "global.space.dzn:4:9"
  (test-lookup #:file-name "global.space.dzn" #:line 7 #:column 7))

(test-equal "global.space namespaced"
  "global.space.dzn:1:7"
  (test-lookup #:file-name "global.space.dzn" #:line 8 #:column 7))

(test-equal "double.space"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "double.space.dzn" #:line 11 #:column 9))

(test-equal "double.space prefix"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "double.space.dzn" #:line 11 #:column 9))

(test-equal "import-double.space"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "import-double.space.dzn" #:line 7 #:column 9
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "import-double.space prefix"
  "double.space.dzn:3:9"
  (test-lookup #:file-name "import-double.space.dzn" #:line 8 #:column 9
               #:file-name->parse-tree file-name->parse-tree))

(test-equal "reply-port->port"
  "blocking.dzn:16:18"
  (test-lookup #:file-name "blocking.dzn" #:line 24 #:column 27))

(test-equal "out-binding->variable"
  "blocking.dzn:21:8"
  (test-lookup #:file-name "blocking.dzn" #:line 23 #:column 37))

(test-end)

(test-end)
