;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


(define (main . args)
  ((@@ (dezyne) main) (command-line)))

(read-set! keywords 'prefix)

(define-module (dezyne)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (ice-9 rdelim)
  :use-module (ice-9 q)
  :use-module (oop goops)
  :use-module (srfi srfi-1))

(define-syntax assert
  (syntax-rules ()
    ((assert e)
     (or e (throw 'assert 'e)))))

(define-class <v> ()
  (v :accessor .v :init-value 0 :init-keyword :v))

(define (stderr . args)
  (apply format (cons* (current-error-port) args)))

(define (assoc-xref alist value)
  (define (cdr-equal? x) (equal? (cdr x) value))
  (and=> (find cdr-equal? alist) car))

(define-class <model> ())

(define-class <port-base> ())

(define-class <interface> (<model>)
  (in :accessor .in :init-value #f :init-keyword :in)
  (out :accessor .out :init-value #f :init-keyword :out))

(define-class <component-base> (<model>)
 (runtime :accessor .runtime :init-form (make <runtime>) :init-keyword :runtime)
 (parent :accessor .parent :init-value #f :init-keyword :parent)
 (name :accessor .name :init-value (symbol) :init-keyword :name))

(define-class <component> (<component-base>)
 (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
 (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
 (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
 (q :accessor .q :init-form (make-q) :init-keyword :q))

(define-class <system> (<component-base>))

(define-method (connect-ports (provided <interface>) (required <interface>))
  (set! (.out provided) (.out required))
  (set! (.in required) (.in provided)))

(define (illegal) (throw 'assert 'illegal))

(define-method (action (o <component>) (port <accessor>) (dir <accessor>) (event <accessor>) . args)
  (apply ((compose event dir port) o) args))

(define-method (action (o <interface>) (dir <accessor>) (event <accessor>) . args)
  (apply ((compose event dir) o) args))

(define-class <runtime> ()
  (components :accessor .components :init-form (list) :init-keyword :components)
  (illegal :accessor .illegal :init-value illegal :init-keyword :illegal))

(define (external? o)
  (not (member o (.components (.runtime o)))))

(define (flush o)
  (when (not (external? o))
    (while (not (q-empty? (.q o)))
      (handle o (deq! (.q o))))
    (and-let* ((t (.deferred? o)))
              (set! (.deferred? o) #f)
              (if (not (.handling? t))
                  (flush t)))))

(define (defer i o f)
  (if (or (not i) (and (not (.flushes? i)) (not (.handling? o))))
      (handle o f)
      (begin
        (set! (.deferred? i) o)
        (enq! (.q o) f))))

(define (handle o f)
  (if (not (.handling? o))
      (begin
        (set! (.handling? o) #t)
        (f)
        (set! (.handling? o) #f)
        (flush o))
      (throw 'handle "component already handling an event")))

(define (return-value? r m)
  (and-let* (((number? r))
             (type (car m))
             (alist (cadr m))
             (field (assoc-xref alist r)))
            (symbol-append type '_ field)))
  
(define-method (call-in (o <component>) f m)
  (apply trace-in (take m 2))
  (let ((handle (.handling? o)))
    (set! (.handling? o) #t)
    (let ((r (f)))
      (if handle (throw 'defer "a valued event cannot be deferred"))
      (set! (.handling? o) #f)
      (flush o)
      (trace-out (car m) (or (return-value? r (cddr m)) 'return))
      r)))

(define-method (call-out (o <component>) f m)
  (apply trace-out m)
  (defer (.self (.in (car m))) o f))

(define* (path o :optional (p ""))
  (let ((pp (and o (string-append (symbol->string (.name o))
                                  (if (string-null? p) p ".") p))))
    (cond
     ((not o) (string-append "<external>." p))
     ((is-a? o <port-base>) (path (.self o) pp))
     ((and (is-a? o <model>) (.parent o)) (path (.parent o) pp))
     (else pp))))

(define (trace-in i e)
  (stderr "~a.~a -> ~a.~a\n" (path (.out i)) e (path (.in i)) e))

(define (trace-out i e)
  (stderr "~a.~a -> ~a.~a\n" (path (.in i)) e (path (.out i)) e))
