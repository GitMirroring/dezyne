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
  #:use-module (dzn parse)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse complete)
  #:use-module (dzn parse tree)
  #:use-module (dzn parse util)
  #:use-module (test dzn automake))

(define* (test-complete #:key file-name offset text)
  (let* ((dir    "test/language")
         (text   (or text
                     (with-input-from-file (string-append dir "/" file-name)
                       read-string)))
         (root   (parameterize ((%peg:fall-back? #t))
                   (string->parse-tree text)))
         (offset (or offset (string-length text)))
         (ctx    (complete:context root offset))
         (token  (.tree ctx)))
    (complete token ctx offset)))

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
  '("on")
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
(test-end)
