;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; Tests for the makreel module.
;;;
;;; Code:

(define-module (test dzn makreel)
  #:use-module (srfi srfi-64)
  #:use-module (oop goops)
  #:use-module (test dzn automake)

  #:use-module (dzn code makreel)
  #:use-module (dzn parse)
  #:use-module (dzn goops))

(test-begin "makreel")

(test-assert "dummy"
  #t)

(test-assert "parse"
  (string->ast "interface i {in void e();behaviour {on e: {}}}"))

(test-assert "tail-call self"
  (let* ((ast (string->ast "interface i {in void e();behaviour {void f () {f ();} on e: {}}}"))
         (ast (makreel:om ast))
         (call (car (tree-collect (is? <call>) ast))))
    (.last? call)))

(test-assert "tail-call other"
  (let* ((ast (string->ast "interface i {in void e();behaviour {void g () {} void f () {g ();} on e: {}}}"))
         (ast (makreel:om ast))
         (call (car (tree-collect (is? <call>) ast))))
    (.last? call)))

(test-assert "non tail-call"
  (let* ((ast (string->ast "interface i {in void e();behaviour {void f () {g (); bool b = true;} void g () {} on e: {}}}"))
         (ast (makreel:om ast))
         (call (car (tree-collect (is? <call>) ast))))
    (not (.last? call))))

(test-assert "non tail-call valued"
  (let* ((ast (string->ast "interface i {in void e();behaviour {void f () {bool b = g ();} bool g () {return true;} on e: {}}}"))
         (ast (makreel:om ast))
         (call (car (tree-collect (is? <call>) ast))))
    (not (.last? call))))

(test-end)
