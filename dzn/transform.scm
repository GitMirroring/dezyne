;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; Export a list of AST transformations to be exposed to the user.
;;;
;;; Code:

(define-module (dzn transform)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)
  #:use-module (ice-9 match)
  #:use-module (dzn misc)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn normalize)
  #:use-module (dzn vm normalize)
  #:use-module (dzn goops)
  #:use-module (dzn ast)

  #:export (inline-functions
            normalize:compounds-wrap)
  #:re-export (add-function-return
               add-explicit-temporaries
               normalize:compounds
               normalize:event
               normalize:state
               purge-data
               remove-otherwise
               remove-behavior))

(define (normalize:compounds-wrap o)
  "Like normalize:compounds and wrap singleton top level imperative
statements in a compound."
  (normalize:compounds o #:wrap-imperative? #t))

(define* (inline-functions o #:optional names)
  "Expand the function body at each call location for each function, or
when using --transform=inline-functions(NAMES...) only for the functions
in NAMES."
  (define (substitute-arguments alist o)
    (match o
      (($ <compound>)
       (let ((statements
              (let loop ((alist alist) (statements (.elements o)))
                (match statements
                  (((and ($ <variable>) variable) tail ...)
                   (let* ((name (.name variable))
                          (formal (find
                                   (compose (cute equal? <> name) .name car)
                                   alist))
                          (alist (alist-delete formal alist ast:eq?)))
                     (if (null? alist) (cons variable tail)
                         (cons (substitute-arguments alist variable)
                               (loop alist tail)))))
                  ((h t ...)
                   (cons (substitute-arguments alist h)
                         (loop alist t)))
                  (()
                   '())))))
         (clone o #:elements statements)))
      (($ <var>)
       (or (and=> (assoc (.variable o) alist ast:eq?) cdr)
           o))
      ((? (is? <ast>))
       (tree-map (cute substitute-arguments alist <>) o))
      (_
       o)))
  (define (substitute-return assign o)
    (match o
      (($ <compound>)
       (let* ((name (.variable.name assign))
              (statements
               (let loop ((assign assign) (statements (.elements o)))
                 (match statements
                   (((and ($ <variable>) variable) tail ...)
                    (if (equal? (.name variable) name) (cons variable tail)
                        (cons (substitute-return assign variable)
                              (loop assign tail))))
                   ((h t ...)
                    (cons (substitute-return assign h)
                          (loop assign t)))
                   (()
                    '())))))
         (clone o #:elements statements)))
      (($ <return>)
       (clone assign #:expression (.expression o)))
      ((? (is? <ast>))
       (tree-map (cute substitute-return assign <>) o))
      (_
       o)))
  (define (skip? function)
    (or (.recursive? function)
        (match names
          (((? symbol?) ...)
           (member (.name function) (map symbol->string names)))
          (((? string?) ...)
           (member (.name function) names))
          (_
           #t))))
  (define (helper o)
    (match o
      (($ <call>)
       (let* ((function (.function o))
              (type (ast:type function)))
         (if (skip? function) o
             (let* ((formals (ast:formal* function))
                    (arguments (ast:argument* o))
                    (formal-alist (map cons formals arguments))
                    (statement (.statement function))
                    (statement (substitute-arguments formal-alist statement)))
               (helper statement)))))
      (($ <assign>)
       (let ((expression (.expression o)))
         (if (not (is-a? expression <call>)) o
             (let* ((statement (helper expression))
                    (statement (substitute-return o statement)))
               (helper statement)))))
      (($ <if>)
       (clone o #:then (helper (.then o))
              #:else (and=> (.else o) helper)))
      (($ <on>)
       (clone o #:statement (helper (.statement o))))
      (($ <guard>)
       (clone o #:statement (helper (.statement o))))
      (($ <compound>)
       (let* ((statements (ast:statement* o))
              (statements
               (let loop ((statements statements))
                 (match statements
                   (((and ($ <variable>) v) t ...)
                    (let ((expression (.expression v)))
                      (if (not (is-a? expression <call>)) (cons v (loop t))
                          (let ((variable assign (split-variable v)))
                            (cons* variable assign (loop t))))))
                   ((h t ...)
                    (cons h (loop t)))
                   (()
                    '())))))
         (clone o #:elements (map helper statements))))
      (($ <behavior>)
       (let* ((statement (helper (.statement o)))
              (functions (ast:function* o))
              (calls (tree-collect (is? <call>) statement))
              (called (map .function calls))
              (functions (filter (conjoin (cute member <> called ast:eq?)
                                          (negate .recursive?))
                                 functions))
              (functions (clone (.functions o) #:elements functions)))
         (clone o #:statement statement
                #:functions functions)))
      (($ <component>)
       (clone o #:behavior (helper (.behavior o))))
      (($ <interface>)
       (clone o #:behavior (helper (.behavior o))))
      (($ <system>)
       o)
      (($ <foreign>)
       o)
      ((? (is? <ast>))
       (tree-map helper o))
      (_
       o)))
  (helper o))
