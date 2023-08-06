;;; Snuik --- An IRC bot using guile-8sync
;;; Copyright © 2020, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Snuik.
;;;
;;; Snuik is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Snuik is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Snuik.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn goops goops)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (system foreign)
  #:use-module (ice-9 match)
  #:use-module (oop goops)
  #:export (child*
            class-bare-name
            clone
            define-class*
            define-class*-public
            define-class-public
            define-method-public
            deep-copy
            keyword+child*
            object:id)
  #:re-export (<top>
               <class> <object>
               <applicable> <procedure>
               <boolean> <char> <list> <pair> <null> <string> <symbol>
               <number>
               <unknown>

               class-name
               class-of
               define-class
               define-generic
               define-method
               is-a?
               make))

;;;
;;; Define-class-public.
;;;
(define-syntax define-class-public
  (lambda (x)
    "Like DEFINE-CLASS*, exporting <NAME> and getters."
    (define (slot->names slot)
      (syntax-case slot ()
        ((name #:accessor accessor) (list #'accessor))
        ((name #:accessor accessor t ...) (cons #'accessor (slot->names #'(name t ...))))
        ((name #:getter getter) (list #'getter))
        ((name #:getter getter t ...) (cons #'getter (slot->names #'(name t ...))))
        ((name #:setter setter) (list #'setter))
        ((name #:setter setter t ...) (cons #'setter (slot->names #'(name t ...))))
        ((name keyword value t ...) (slot->names #'(name t ...)))
        (_  '())))
    (syntax-case x ()
      ((_ name supers slot ...)
       #`(begin
           (define-class name supers slot ...)
           (export name
                   #,@(filter (compose not defined? syntax->datum)
                              (append-map slot->names #'(slot ...)))))))))

(define-syntax define-method-public
  (syntax-rules ()
    ((define-method-public (name . args) . body)
     (begin
       (define-method (name . args) . body)
       (export name)))))


;;;
;;; Class*
;;;
(define (getter-name name)
  (string->symbol (string-append "." (symbol->string name))))

(define-syntax define-class*
  (lambda (x)
    "Define a standardized class

  (define-class* <name> (<super>)
    (slot0)
    (slot1 #init-value 0)
    (slot2 #init-form (list))
    (slot2 #init-thunk (const #t)))

with init-keyword #:slot0 #:slot1 #:slot2
with initial values #f, 0, and list),
and with getters .slot0, slot1, .slot2. "
    (define (complete-slot slot)
      (define (create-slot name init-keyword init-value)
        (let ((getter (datum->syntax x (getter-name (syntax->datum name))))
              (keyword (datum->syntax x (symbol->keyword
                                         (syntax->datum name)))))
          #`(#,name #:getter #,getter #,init-keyword
                    #,init-value #:init-keyword #,keyword)))
      (syntax-case slot ()
        ((name)
         (create-slot #'name #:init-value #f))
        ((name #:init-form form)
         (create-slot #'name #:init-form #'form))
        ((name #:init-thunk thunk)
         (create-slot #'name #:init-thunk #'thunk))
        ((name #:init-value value)
         (create-slot #'name #:init-value #'value))))
    (syntax-case x ()
      ((_ name supers slot ...)
       (with-syntax (((slot' ...) (map complete-slot #'(slot ...))))
         #'(define-class name supers slot' ...))))))

(define-syntax define-class*-public
  (lambda (x)
    "Like DEFINE-CLASS*, exporting <NAME> and getters."
    (define (slot->getter-name slot)
      (let ((name (syntax-case slot ()
                    ((name) #'name)
                    ((name #:init-form form) #'name)
                    ((name #:init-thunk thunk) #'name)
                    ((name #:init-value value) #'name))))
        (datum->syntax x (getter-name (syntax->datum name)))))
    (syntax-case x ()
      ((_ name supers slot ...)
       #`(begin
           (define-class* name supers slot ...)
           (export name
                   #,@(filter (compose not defined? syntax->datum)
                              (map slot->getter-name #'(slot ...)))))))))


;;;
;;; Id, child*, clone, deep-copy.
;;;
(define-method (object:id (o <object>))
  (pointer-address (scm->pointer o)))

(define-method (keyword+child* (o <object>))
  (let* ((class (class-of o))
         (slots (class-slots class))
         (names (map slot-definition-name slots))
         (keywords (map symbol->keyword names))
         (children (map (cute slot-ref o <>) names)))
    (zip keywords children)))

(define-method (child* (o <object>))
  (append-map (match-lambda
                ((keyword (children ...)) children)
                ((keyword child) (list child)))
              (keyword+child* o)))

(define-method (keyword-values+mutate? (o <object>) . keyword-values)
  "Return multiple values; the full list of paired KEYWORD-VALUES to
create a fresh clone, and #true if any slots need mutation."
  (define (car-eq? a b)
    (eq? (car a) (car b)))
  (let* ((actual-keyword-values (keyword+child* o))
         (keyword-values
          (fold (lambda (elem previous)
                  (if (or (null? previous) (pair? (car previous)))
                      (cons elem previous)
                      (cons (list (car previous) elem) (cdr previous))))
                '()
                keyword-values))
         (invalid (lset-difference equal?
                                   (map car keyword-values)
                                   (map car actual-keyword-values)))
         (mutate (lset-difference equal?
                                  keyword-values
                                  actual-keyword-values))
         (missing (lset-difference car-eq?
                                   actual-keyword-values
                                   keyword-values))
         (keyword-values (append missing keyword-values)))
    (when (pair? invalid)
      (let ((slots (map car actual-keyword-values)))
        (error (format #f "invalid keyword arguments in ~a: ~a; slots = ~a\n"
                       o invalid slots))))
    (values keyword-values (pair? mutate))))

(define-method (clone (o <object>) . keyword-values)
  "Return fresh clone of O, mutating slots from KEYWORD-VALUES."
  (let ((paired-keyword-values
         (apply keyword-values+mutate? o keyword-values))
        (class (class-of o)))
    (apply make class (apply append paired-keyword-values))))

(define-method (deep-copy (o <object>))
  "Make a unique identical copy of O and of its children."
  (let* ((class (class-of o))
         (keyword-values (keyword+child* o))
         (keyword-copies (map (match-lambda
                                ((keyword (values ...))
                                 (list keyword (map deep-copy values)))
                                ((keyword value)
                                 (list keyword (deep-copy value))))
                              keyword-values))
         (keyword-copies (apply append keyword-copies)))
    (apply make class keyword-copies)))

(define-method (deep-copy (o <top>))
  "Do not copy objects without children."
  o)
