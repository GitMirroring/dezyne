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
;;; Code:

(define-module (dzn ast display)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 pretty-print)
  #:use-module ((oop goops) #:select (slot-ref))

  #:use-module (dzn goops display)
  #:use-module (dzn goops serialize)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast serialize)
  #:use-module (dzn ast util)
  #:use-module (dzn command-line) ;%locations?
  #:use-module (dzn misc)

  #:export (ast:display
            ast:pretty-print
            ast->string)
  #:re-export (write))

(define (ast:display-skip? o)
  ((disjoin ast:serialize-skip?
            (conjoin (is? <comment>)
                     (negate (const (%comments?))))
            (conjoin (disjoin (is? <location>)
                              (is? <file-name>))
                     (negate (const (%locations?)))))
   o))

(define-method (write (o <ast>) port)
  (parameterize ((%serialize:skip? ast:display-skip?))
    (next-method)))

(define ast:display write)


;;;
;;; Entry points.
;;;
(define (ast->string ast)
  (parameterize ((%serialize:skip? ast:display-skip?))
    (display:serialize ast)))

(define* (ast:pretty-print ast #:optional (port (current-output-port))
                           #:key (width 79))
  "Recursively print AST to PORT in a user-friendly debug format."
  (parameterize ((%serialize:skip? ast:display-skip?))
    (display:pretty-print ast port #:width width)))
