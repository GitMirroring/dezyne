;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-syntax-rule (assert e)
  (or e (throw 'assert 'e)))

(define-class <v> ()
  (v :accessor .v :init-value 0 :init-keyword :v))

(define (stderr . args)
  (apply format (cons* (current-error-port) args)))

(define (assoc-xref alist value)
  (define (cdr-equal? x) (equal? (cdr x) value))
  (and=> (find cdr-equal? alist) car))

(define-class <dezyne:model> ())

(define-class <dezyne:port-base> ())

(define-class <dezyne:interface> (<dezyne:model>)
  (in :accessor .in :init-value #f :init-keyword :in)
  (out :accessor .out :init-value #f :init-keyword :out))

(define-class <dezyne:component-base> (<dezyne:model>)
  (locator :accessor .locator :init-value #f :init-keyword :locator)
  (runtime :accessor .runtime :init-value #f)
  (parent :accessor .parent :init-value #f :init-keyword :parent)
  (name :accessor .name :init-value (symbol) :init-keyword :name))

(define-method (initialize (o <dezyne:component-base>) args)
  (next-method)
  (set! (.runtime o) (get (.locator o) <dezyne:runtime>))
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o))))

(define-class <dezyne:component> (<dezyne:component-base>)
 (handling? :accessor .handling? :init-value #f :init-keyword :handling?)
 (flushes? :accessor .flushes? :init-value #f :init-keyword :flushes?)
 (deferred? :accessor .deferred? :init-value #f :init-keyword :deferred?)
 (q :accessor .q :init-form (make-q) :init-keyword :q))

(define-class <dezyne:system> (<dezyne:component-base>))

(define-method (connect-ports (provided <dezyne:interface>) (required <dezyne:interface>))
  (set! (.out provided) (.out required))
  (set! (.in required) (.in provided)))

(define (illegal) (throw 'assert 'illegal))

(define-method (action-method (o <dezyne:component>) (port <accessor>) (dir <accessor>) (event <accessor>) . args)
  (apply (event (dir (port o))) args))

(define (action o port dir event . args)
  (apply ((compose event dir port) o) args))

(define-class <dezyne:runtime> ()
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
  (if (and (not (and i (.flushes? i))) (not (.handling? o)))
      (handle o f)
      (begin
        (enq! (.q o) f)
        (if i
            (set! (.deferred? i) o)))))

(define-method (valued-helper o f m)
  (if (.handling? o) (throw 'defer "a valued event cannot be deferred"))
  (set! (.handling? o) #t)
  (let ((r (f)))
    (set! (.handling? o) #f)
    (flush o)
    r))

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
             (type (and (pair? m) (car m)))
             (alist (cadr m))
             (field (assoc-xref alist r)))
            (symbol-append type '_ field)))

(define-method (call-in (o <dezyne:component>) f m)
  (apply trace-in (take m 2))
  (handle o f)
  (trace-out (car m) 'return)
  #f)

(define-method (rcall-in (o <dezyne:component>) f m)
  (apply trace-in (take m 2))
  (let ((r (valued-helper o f m)))
    (trace-out (car m) (or (return-value? r (cddr m)) 'return))
    r))

(define-method (call-out (o <dezyne:component>) f m)
  (apply trace-out m)
  (defer (.self (.in (car m))) o f))

(define* (path o :optional (p ""))
  (let* ((name (or (and o (symbol->string (.name o))) ""))
         (pp (string-append name
                            (if (and (not (string-null? name))
                                     (not (string-null? p))) "." "") p)))
    (cond
     ((not o) (string-append "<external>" (if (string-null? p) "" ".") p))
     ((is-a? o <dezyne:port-base>) (path (.self o) pp))
     ((and (is-a? o <dezyne:model>) (.parent o)) (path (.parent o) pp))
     (else pp))))

(define (trace-in i e)
  (stderr "~a.~a -> ~a.~a\n" (path (.out i)) e (path (.in i)) e))

(define (trace-out i e)
  (stderr "~a.~a -> ~a.~a\n" (path (.in i)) e (path (.out i)) e))


(define-class <dezyne:locator> ()
  (services :accessor .services :init-form (list) :init-keyword :services))

(define-method (locator-key (type <class>) (key <symbol>))
  (symbol-append (class-name type) key))

(define-method (locator-key (type <object>))
  (locator-key (class-of type) 'key))

(define-method (locator-key (key <symbol>))
  key)

(define-method (locator-key (key <string>))
  (locator-key (string->symbol key)))

(define-method (locator-key (type <object>) (key <symbol>))
  (locator-key (class-of type) key))

(define-method (locator-key (type <class>) (key <string>))
  (locator-key type (string->symbol key)))

(define-method (locator-key type (key <string>))
  (locator-key type (string->symbol key)))

(define-method (locator-key x key)
  (locator-key key))

(define-method (set (o <dezyne:locator>) (x <object>))
  (set o x 'key))

(define-method (set (o <dezyne:locator>) x key)
  (set! (.services o) (assoc-set! (.services o) (locator-key x key) x))
  o)

(define-method (set (o <dezyne:locator>) (x <object>) key)
  (set! (.services o) (assoc-set! (.services o) (locator-key x key) x))
  o)

(define-method (get (o <dezyne:locator>) (key <symbol>))
  (assoc-ref (.services o) (locator-key key)))

(define-method (get (o <dezyne:locator>) (type <class>))
  (get o type 'key))

(define-method (get (o <dezyne:locator>) (type <object>))
  (get o type 'key))

(define-method (get (o <dezyne:locator>) (x <class>) key)
  (assoc-ref (.services o) (locator-key x key)))

(define-method (get (o <dezyne:locator>) (x <object>) key)
  (assoc-ref (.services o) (locator-key x key)))

(define-method (clone (o <dezyne:locator>))
  (make <dezyne:locator> :services (list-copy (.services o))))
