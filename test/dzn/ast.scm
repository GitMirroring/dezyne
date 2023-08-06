;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022, 2023 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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

(define-module (test dzn ast)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)
  #:use-module (srfi srfi-71)

  #:use-module (test dzn automake)

  #:use-module ((dzn ast) #:select (ast:imperative?))
  #:use-module (dzn ast accessor)
  #:use-module (dzn ast display)
  #:use-module (dzn ast equal)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast lookup)
  #:use-module (dzn ast util)
  #:use-module (dzn goops context)
  #:use-module (dzn goops goops)
  #:use-module (dzn goops tree)
  #:use-module ((dzn ast) #:select (ast:type))
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn parse peg))

(define-method (equal? (a <ast>) (b <ast>))
  (let ((class-a (class-of a))
        (class-b (class-of b)))
    (and (eq? class-a class-b)
         (let* ((keyword-values-a (keyword+child* a))
                (keyword-values-b (keyword+child* b)))
           (equal? keyword-values-a keyword-values-b)))))

(test-begin "ast")

(test-assert "dummy"
  #t)

(parameterize ((%peg:locations? 'none))
  (let* ((test "
interface ihello
{
  in void hello ();
  out void world ();
  behavior
  {
     on hello: world;
  }
}

component hello
{
  provides ihello h;
  behavior
  {
    on h.hello (): {h.world ();}
  }
}
")
         (root (parse:string->ast test)))

    (parameterize ((%context (tree:memoize-context root)))
      (let* ((interface (tree:get root (is? <interface>)))
             (in-component? (cute tree:ancestor <> <component>))
             (action (tree:get root (conjoin (is? <action>) in-component?)))
             (compound (tree:get root (conjoin (is? <compound>)
                                               ast:imperative?
                                               in-component?)))
             (port (tree:get root (is? <port>)))
             (event (tree:get root (conjoin (is? <event>)
                                            (compose (cute equal? <> "world")
                                                     .name))))
             (graft-synth (graft (tree:parent action)
                                 (make <action>
                                   #:port.name (.port.name action)
                                   #:event.name (.event.name action))))
             (graft'-synth (graft action
                                  #:port.name (.port.name action)
                                  #:event.name (.event.name action))))

        (test-eq "interface-context interface"
          interface
          (and=> (hashq-ref
                  (%context) interface)
                 car))

        (test-equal "interface-context full"
          (list interface root)
          (hashq-ref (%context) interface))

        (test-eq "tree:ancestor interface <root>"
          root
          (tree:ancestor interface <root>))

        (test-eq "tree:ancestor action <root>"
          root
          (tree:ancestor action <root>))

        (test-eq ".port action"
          port
          (.port action))

        (test-eq ".event action"
          event
          (.event action))

        (test-eq ".port graft-synth"
          (.port action)
          (.port graft-synth))

        (test-eq ".event graft-synth"
          (.event action)
          (.event graft-synth))

        (test-eq ".port graft'-synth"
          (.port action)
          (.port graft'-synth))

        (test-eq ".event graft-synth"
          (.event action)
          (.event graft'-synth))

        (test-assert "graft action unmutated"
          (not (eq? action
                    (graft action))))

        (test-assert "deep copy action"
          (not (eq? action
                    (deep-copy action))))

        (test-assert "deep copy compound"
          (not (eq? (car (ast:statement* compound))
                    (car (ast:statement* (deep-copy compound))))))

        (let* ((defer (make <defer> #:statement compound))
               (defer-copy (deep-copy defer))
               (defer-copy* (tree:copy (tree:parent compound) defer)))

          (test-assert "tree:copy'd has new id"
            (not (eq? (tree:id defer-copy)
                      (tree:id defer))))

          (test-assert "tree:copy'd child has new id"
            (not (eq? (tree:id compound)
                      (tree:id (.statement defer-copy)))))

          (test-eq "deep-copy'd child's parent"
            defer-copy*
            (tree:parent (.statement defer-copy*))))

        (let* ((context (tree:context action))
               (kloon kloon-root (clone+root action #:event.name "world"))
               (kloon-context (parameterize ((%context (tree:memoize-context kloon-root)))
                                (tree:context kloon))))

          (test-assert "root and kloon-root not eq?"
            (not (eq? (%root)
                      kloon-root)))

          (test-equal "root and kloon-root equal"
            (%root)
            kloon-root)

          (test-assert "original and clone not eq?"
            (not (eq? action
                      kloon)))

          (test-equal "action and kloon equal"
            action
            kloon)

          (test-assert "contexts not eq?"
            (not (eq? context
                      kloon-context)))

          (test-equal "context and kloon-context equal"
            context
            kloon-context))))

    (let ((mini-root (parse:string->ast "\
interface ihello {in void hello ();}"))
          (data-root (parse:string->ast "\
 extern int $int$; interface ihello {in void hello (int i);}")))
      (parameterize ((%context (tree:memoize-context data-root)))
        (test-equal "tree:transform"
          mini-root
          (tree:transform data-root
                          (disjoin (is? <extern>)
                                   (is? <data-expr>)
                                   (conjoin (is? <formal>)
                                            (compose (is? <extern>)
                                                     ast:type)))
                          (const #f)))))))

(test-end)
