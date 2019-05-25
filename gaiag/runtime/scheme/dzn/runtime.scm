;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn runtime)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 q)
  #:use-module (oop goops)
  #:export (<dzn:locator>
            <dzn:interface>
            <dzn:component>
            <dzn:port>
            <dzn:system>
            <dzn:runtime>
            dzn:flush
            .name
            .self
            .locator
            .rank
            .runtime
            .in
            .out
            .handling?
            .illegal
            action
            call-in
            call-out
            stderr

            ;; locator
            dzn:set!
            dzn:get
            dzn:clone

            dzn:connect
            dzn:rank!
            dzn:set-state!
            dzn:trace
            dzn:trace-out
            dzn:trace-qout
            dzn:trace-qin
            dzn:return-value))

(define-syntax-rule (assert e)
  (or e (throw 'assert 'e)))

(define-class <v> ()
  (v #:accessor .v #:init-value 0 #:init-keyword #:v))

(define (stderr . args)
  (apply format (cons* (current-error-port) args)))

(define (assoc-xref alist value)
  (define (cdr-equal? x) (equal? (cdr x) value))
  (and=> (find cdr-equal? alist) car))

(define-class <dzn:model> ())

(define-class <dzn:port> ()
  (name #:accessor .name #:init-value (symbol) #:init-keyword #:name)
  (self #:accessor .self #:init-value #f #:init-keyword #:self))

(define-class <dzn:interface> (<dzn:model>)
  (in #:accessor .in #:init-value #f #:init-keyword #:in)
  (out #:accessor .out #:init-value #f #:init-keyword #:out))

(define-class <dzn:component-model> (<dzn:model>)
  (locator #:accessor .locator #:init-value #f #:init-keyword #:locator)
  (runtime #:accessor .runtime #:init-value #f)
  (parent #:accessor .parent #:init-value #f #:init-keyword #:parent)
  (name #:accessor .name #:init-value (symbol) #:init-keyword #:name)
  (rank #:accessor .rank #:init-value 0 #:init-keyword #:rank))

(define-method (initialize (o <dzn:component-model>) args)
  (next-method)
  (set! (.runtime o) (dzn:get (.locator o) <dzn:runtime>))
  (set! (.components (.runtime o)) (append (.components (.runtime o)) (list o))))

(define-class <dzn:component> (<dzn:component-model>)
 (handling? #:accessor .handling? #:init-value #f #:init-keyword #:handling?)
 (flushes? #:accessor .flushes? #:init-value #f #:init-keyword #:flushes?)
 (deferred? #:accessor .deferred? #:init-value #f #:init-keyword #:deferred?)
 (dzn-q #:accessor .dzn-q #:init-form (make-q) #:init-keyword #:dzn-q))

(define-class <dzn:system> (<dzn:component-model>))

(define-method (dzn:connect (provides <dzn:interface>) (requires <dzn:interface>))
  (set! (.out provides) (.out requires))
  (set! (.in requires) (.in provides)))

(define-method (dzn:member* (o <dzn:component-model>))
  (let ((slots (map slot-definition-name (class-slots (class-of o)))))
    (map (cut slot-ref o <>) slots)))

(define-method (dzn:instance* (o <dzn:component-model>))
  (filter (cut is-a? <> <dzn:component-model>) (dzn:member* o)))

(define-method (dzn:interface* (o <dzn:component-model>))
  (filter (cut is-a? <> <dzn:interface>) (dzn:member* o)))

(define-method (dzn:provides* (o <dzn:system>))
  (let ((instances (dzn:instance* o)))
    (filter (compose (cut and=> <> (cute memq <> instances)) .self .in) (dzn:interface* o))))

(define-method (dzn:requires* (o <dzn:system>))
  (let ((instances (dzn:instance* o)))
    (filter (compose (cut and=> <> (cute memq <> instances)) .self .out) (dzn:interface* o))))

(define-method (dzn:provides* (o <dzn:component>))
  (filter (compose (cut and=> <> (cute eq? <> o)) .self .in) (dzn:interface* o)))

(define-method (dzn:requires* (o <dzn:component>))
  (filter (compose (cut and=> <> (cute eq? <> o)) .self .out) (dzn:interface* o)))

(define-method (dzn:rank! (o <dzn:interface>) r)
  (dzn:rank! ((compose .self .in) o) r))

(define-method (dzn:rank! (o <dzn:component-model>) r)
  (when (> r (.rank o))
    (set! (.rank o) r))
  (format (current-error-port) "rank: ~a ~a ~a\n" (.name o) (class-name (class-of o)) (.rank o))
  ;; (format (current-error-port) "prov: ~a\n" (dzn:provides* o))
  ;; (format (current-error-port) "req:  ~a\n" (dzn:requires* o))
  (for-each (lambda (i) (dzn:rank! ((compose .self .in) i) (1+ (.rank o)))) (dzn:requires* o)))

(define-method (dzn:rank! (o <boolean>) r)
  ;;(format (current-error-port) "rank: #f\n")
  #t)

(define-method (dzn:set-state! (o <dzn:component>) state)
  (define (state->value o)
    (cond ((eq? o 'true) #t)
          ((eq? o 'false) #f)
          (else o)))
  (for-each (lambda (v) (slot-set! o (car v) (state->value (cdr v)))) state))

(define (dzn:type-name o)
  (string->symbol (string-drop-right (string-drop (symbol->string (class-name (class-of o))) 1) 1)))

(define (dzn:path o)
  (let* ((path (let loop ((o o))
                (if (not o) '()
                    (cons o (loop (.parent o))))))
         (path (reverse path)))
    (cons (dzn:type-name (car path)) (map .name (cdr path)))))

(define-method (dzn:set-state! (o <dzn:system>) state)
  (let* ((path (dzn:path o))
         (instance-state (filter identity
                                 (map (lambda (x)
                                        (and (pair? (car x))
                                             (equal? path (list-head (car x) (length path)))
                                             (cons (list-ref (car x) (length path)) (cdr x))))
                                      state))))
    (for-each (lambda (i) (dzn:set-state! (slot-ref o (car i)) (cdr i))) instance-state)))

(define (illegal) (throw 'assert 'illegal))

(define-method (action-method (o <dzn:component>) (port <accessor>) (dir <accessor>) (event <accessor>) . args)
  (apply (event (dir (port o))) args))

(define (action o port dir event . args)
  (apply ((compose event dir port) o) args))

(define-class <dzn:runtime> ()
  (components #:accessor .components #:init-form (list) #:init-keyword #:components)
  (illegal #:accessor .illegal #:init-value illegal #:init-keyword #:illegal))

(define (external? o)
  (not (member o (.components (.runtime o)))))

(define (dzn:flush o)
  (when (not (external? o))
    (while (not (q-empty? (.dzn-q o)))
      (handle o (deq! (.dzn-q o))))
    (and=> (.deferred? o)
           (lambda (target)
             (set! (.deferred? o) #f)
             (if (not (.handling? target))
                 (dzn:flush target))))))

(define (defer i o f)
  (if (and (not (and i (.flushes? i))) (not (.handling? o)))
      (handle o f)
      (begin
        (enq! (.dzn-q o) f)
        (if i
            (set! (.deferred? i) o)))))

(define-method (valued-helper o f m)
  (if (.handling? o) (throw 'defer "a valued event cannot be deferred"))
  (set! (.handling? o) #t)
  (let ((r (f)))
    (set! (.handling? o) #f)
    (dzn:flush o)
    r))

(define (handle o f)
  (if (not (.handling? o))
      (begin
        (set! (.handling? o) #t)
        (let ((r (f)))
          (set! (.handling? o) #f)
          (dzn:flush o)
          r))
      (throw 'handle "component already handling an event")))

(define (dzn:return-value r)
  (cond ((boolean? r) (if r 'true 'false))
        ((number? r) r)
        ((symbol? r) r)
        (else 'return)))

(define-method (call-in (o <dzn:component>) f m)
  (let ((log (dzn:get (.locator o) <procedure> 'trace)))
    (apply dzn:trace (cons log (take m 2)))
    (let ((r (handle o f)))
      (dzn:trace-out log (car m) (dzn:return-value r))
      r)))

(define-method (call-out (o <dzn:component>) f m)
  (let ((log (dzn:get (.locator o) <procedure> 'trace)))
    (apply dzn:trace-qin (cons log m)))
  (defer (.self (.in (car m))) o f))

(define* (path o #:optional (p ""))
  (let* ((name (or (and o (symbol->string (.name o))) ""))
         (pp (string-append name
                            (if (and (not (string-null? name))
                                     (not (string-null? p))) "." "") p)))
    (cond
     ((not o) (string-append "<external>" (if (string-null? p) "" ".") p))
     ((is-a? o <dzn:port>) (path (.self o) pp))
     ((and (is-a? o <dzn:model>) (.parent o)) (path (.parent o) pp))
     (else pp))))

(define (dzn:trace-qin log i e)
  (log "~a.~a <- ~a.~a\n" (path (.out i)) '<q> (path (.in i)) e))

(define (dzn:trace-qout log i e)
  (log "~a.~a <- ~a.~a\n" (path (.out i)) e (path (.in i)) '<q>))

(define (dzn:trace log i e)
  (log "~a.~a -> ~a.~a\n" (path (.out i)) e (path (.in i)) e))

(define (dzn:trace-out log i e)
  (log "~a.~a <- ~a.~a\n" (path (.out i)) e (path (.in i)) e))

(define-class <dzn:locator> ()
  (services #:accessor .services #:init-form (list (cons (locator-key stderr 'trace) stderr)) #:init-keyword #:services))

(define-method (locator-key (type <class>) (key <symbol>))
  (symbol-append (class-name type) key))

(define-method (locator-key (type <top>))
  (locator-key (class-of type) 'key))

(define-method (locator-key (key <symbol>))
  key)

(define-method (locator-key (key <string>))
  (locator-key (string->symbol key)))

(define-method (locator-key (type <top>) (key <symbol>))
  (locator-key (class-of type) key))

(define-method (locator-key (type <class>) (key <string>))
  (locator-key type (string->symbol key)))

(define-method (locator-key type (key <string>))
  (locator-key type (string->symbol key)))

(define-method (locator-key type key)
  (locator-key key))

(define-method (dzn:set! (o <dzn:locator>) (x <object>))
  (dzn:set! o x 'key))

(define-method (dzn:set! (o <dzn:locator>) x key)
  (set! (.services o) (assoc-set! (.services o) (locator-key x key) x))
  o)

(define-method (dzn:set! (o <dzn:locator>) (x <object>) key)
  (set! (.services o) (assoc-set! (.services o) (locator-key x key) x))
  o)

(define-method (dzn:get (o <dzn:locator>) (key <symbol>))
  (assoc-ref (.services o) (locator-key key)))

(define-method (dzn:get (o <dzn:locator>) (type <class>))
  (dzn:get o type 'key))

(define-method (dzn:get (o <dzn:locator>) (type <object>))
  (dzn:get o type 'key))

(define-method (dzn:get (o <dzn:locator>) (x <class>) key)
  (assoc-ref (.services o) (locator-key x key)))

(define-method (dzn:get (o <dzn:locator>) (x <object>) key)
  (assoc-ref (.services o) (locator-key x key)))

(define-method (dzn:clone (o <dzn:locator>))
  (make <dzn:locator> #:services (list-copy (.services o))))
