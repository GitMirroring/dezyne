;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (test dzn serialize)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)

  #:use-module (ice-9 match)

  #:use-module (test dzn automake)

  #:use-module (dzn ast serialize)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast context)
  #:use-module (dzn ast util)
  #:use-module (dzn command-line) ;%locations?
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module ((dzn peg) #:select (%peg:locations?)))

;;(define equal? (@@ (test dzn ast) equal?))

(define ast:keyword+child* (@@ (dzn ast context) ast:keyword+child*))
(define-method (equal? (a <ast>) (b <ast>))
  (let ((class-a (class-of a))
        (class-b (class-of b)))
    (and (eq? class-a class-b)
         (let* ((keyword-values-a (ast:keyword+child* a))
                (keyword-values-b (ast:keyword+child* b)))
           (equal? keyword-values-a keyword-values-b)))))

(define round-trip (compose ast:unserialize
                            ;; (cute pke "...text..." <>)
                            ast:serialize))

(define-method (ast:get (o <ast>) (predicate <procedure>))
  (car (tree-collect predicate o)))

(define ihello-text
  "\
interface ihello
{
  in void hello ();
  out void world ();
  behavior
  {
     on hello: world;
  }
}
")

(define hello-text
  (string-append
   ihello-text
   "
component hello
{
  provides ihello h;
  behavior
  {
    on h.hello (): {h.world ();}
  }
}
"))

(test-begin "serialize")

(test-assert "dummy"
  #t)

(parameterize ((%peg:locations? 'none)
               (%locations? #t))

  (let ((name-ast (make <scope.name> #:ids '("void"))))
    (test-equal "name"
      name-ast
      (round-trip name-ast)))

  (let ((void-ast (make <void>)))
    (test-equal "void"
      void-ast
      (round-trip void-ast)))

  (let ((mini-root (make <root> #:elements (list (make <interface>)
                                                 (make <component>)))))
    (test-equal "mini-root"
      mini-root
      (round-trip mini-root)))

  (let* ((hello-root (parse:string->ast hello-text))
         (interface-action (ast:get hello-root
                                    (conjoin (is? <action>)
                                             (cute ast:parent <> <interface>))))
         (interface-trigger (ast:get hello-root
                                     (conjoin (is? <trigger>)
                                              (cute ast:parent <> <interface>))))
         (interface-on (ast:get hello-root
                                (conjoin (is? <on>)
                                         (cute ast:parent <> <interface>))))
         (component-action (ast:get hello-root
                                    (conjoin (is? <action>)
                                             (cute ast:parent <> <component>))))
         (component-trigger (ast:get hello-root
                                     (conjoin (is? <trigger>)
                                              (cute ast:parent <> <component>))))
         (component-on (ast:get hello-root
                                (conjoin (is? <on>)
                                         (cute ast:parent <> <component>)))))

    (test-equal "interface-action"
      interface-action
      (round-trip interface-action))

    (test-equal "interface-trigger"
      interface-trigger
      (round-trip interface-trigger))

    (test-equal "interface-on"
      interface-on
      (round-trip interface-on))

    (test-equal "component-action"
      component-action
      (round-trip component-action))

    (test-equal "component-trigger"
      component-trigger
      (round-trip component-trigger))

    (test-equal "component-on"
      component-on
      (round-trip component-on))

    (let ((empty-namespace (make <namespace>)))
      (test-equal "empty namespace"
        empty-namespace
        (round-trip empty-namespace)))

    (let ((empty-named-namespace (make <namespace> #:name "foo")))
      (test-equal "empty, named namespace"
        empty-named-namespace
        (round-trip empty-named-namespace)))

    (let ((empty-behavior (make <behavior>)))
      (test-equal "empty behavior"
        empty-behavior
        (round-trip empty-behavior)))

    (let ((empty-compound (make <compound>)))
      (test-equal "empty compound"
        empty-compound
        (round-trip empty-compound)))

    (test-equal "hello-root"
      hello-root
      (round-trip hello-root))))

(test-end)
