;;; dzn-runtime -- Dezyne runtime library
;;;
;;; Copyright © 2017, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of dzn-runtime.
;;;
;;; dzn-runtime is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Lesser General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; dzn-runtime is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Lesser General Public License for more details.
;;;
;;; You should have received a copy of the GNU Lesser General Public
;;; License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn runtime)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 q)
  #:use-module (oop goops)
  #:use-module (dzn locator)
  #:export (<dzn:interface>
            <dzn:component>
            <dzn:port>
            <dzn:runtime-pump>
            <dzn:system>
            <dzn:runtime>
            %dzn:id
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

            dzn:blocked?
            dzn:collateral-block
            dzn:connect
            dzn:defer
            dzn:flush
            dzn:handle
            dzn:path
            dzn:prune-deferred
            dzn:rank
            dzn:return-value
            dzn:runtime-locator
            dzn:trace
            dzn:trace-out
            dzn:trace-qin
            dzn:trace-qout
            dzn:type-name)
  #:re-export (<dzn:locator>
               stderr
               dzn:clone
               dzn:get
               dzn:set!))

(define %dzn:id (make-parameter -1))

(define-syntax-rule (assert e)
  (or e (throw 'assert 'e)))

(define-class <v> ()
  (v #:accessor .v #:init-value 0 #:init-keyword #:v))

(define-class <dzn:model> ())

(define-class <dzn:port> ()
  (name #:accessor .name #:init-value "" #:init-keyword #:name)
  (self #:accessor .self #:init-value #f #:init-keyword #:self))

(define-class <dzn:interface> (<dzn:model>)
  (in #:accessor .in #:init-value #f #:init-keyword #:in)
  (out #:accessor .out #:init-value #f #:init-keyword #:out))

(define (dzn:runtime-locator)
  (let* ((locator (make <dzn:locator>))
         (runtime (make <dzn:runtime>)))
    (dzn:set! locator runtime)))

(define-class <dzn:component-model> (<dzn:model>)
  (locator #:accessor .locator #:init-form (dzn:runtime-locator) #:init-keyword #:locator)
  (runtime #:accessor .runtime #:init-value #f)
  (parent #:accessor .parent #:init-value #f #:init-keyword #:parent)
  (name #:accessor .name #:init-value "" #:init-keyword #:name)
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

(define-method (dzn:rank (o <dzn:interface>) r)
  (dzn:rank ((compose .self .in) o) r))

(define-method (dzn:rank (o <dzn:component-model>) r)
  (when (> r (.rank o))
    (set! (.rank o) r))
  (for-each (lambda (i) (dzn:rank ((compose .self .in) i) (1+ (.rank o)))) (dzn:requires* o)))

(define-method (dzn:rank (o <boolean>) r)
  #t)

(define (dzn:type-name o)
  (string-drop-right (string-drop (symbol->string (class-name (class-of o))) 1) 1))

(define (dzn:path o)
  (let* ((path (let loop ((o o))
                (if (not o) '()
                    (cons o (loop (.parent o))))))
         (path (reverse path)))
    (cons (dzn:type-name (car path)) (map .name (cdr path)))))

(define (illegal) (throw 'assert 'illegal))

(define-method (action-method (o <dzn:component>) (port <accessor>) (dir <accessor>) (event <accessor>) . args)
  (apply (event (dir (port o))) args))

(define (action o port dir event . args)
  (apply ((compose event dir port) o) args))


;;;
;;; Runtime.
;;;
(define-class <dzn:runtime> ()
  (components #:accessor .components #:init-form (list) #:init-keyword #:components)
  (illegal #:accessor .illegal #:init-value illegal #:init-keyword #:illegal))

(define-class <dzn:runtime-pump> ())

(define (external? o)
  (not (member o (.components (.runtime o)))))

(define (dzn:flush o)
  (set! (.handling? o) #f)
  (when (not (external? o))
    (while (not (q-empty? (.dzn-q o)))
      (dzn:handle o (deq! (.dzn-q o)))
      (set! (.handling? o) #f))
    (and=> (.deferred? o)
           (lambda (target)
             (set! (.deferred? o) #f)
             (when (not (.handling? target))
               (dzn:flush target))))))

(define (enqueue i o f)
  (cond ((and (not (and i (.flushes? i))) (not (.handling? o)))
         (dzn:handle o f)
         (dzn:flush o))
        (else
         (enq! (.dzn-q o) f)
         (when i
           (set! (.deferred? i) o)))))

(define-method (dzn:handle (o <dzn:component>) f)
  (when (.handling? o)
    (throw 'handle "component already handling an event"))
  (set! (.handling? o) (%dzn:id))
  (f))

(define (dzn:return-value r)
  (cond ((boolean? r) (if r 'true 'false))
        ((number? r) r)
        ((symbol? r) r)
        (else 'return)))

(define-method (dzn:blocked? (o <dzn:component>) (port <dzn:interface>))
  (let ((pump (dzn:get (.locator o) <dzn:runtime-pump>)))
    (when pump
      (dzn:blocked? pump port))))

(define-method (dzn:collateral-block (o <dzn:component>) (port <dzn:interface>))
  (let ((pump (dzn:get (.locator o) <dzn:runtime-pump>)))
    (when pump
      (dzn:collateral-block pump o port))))

(define-method (dzn:defer (o <dzn:component>) (p <procedure>) (f <procedure>))
  (let ((f (lambda (coroutine-id)
             (set! (.handling? o) coroutine-id)
             (f)
             (dzn:flush o))))
    (let ((pump (dzn:get (.locator o) <dzn:runtime-pump>)))
      (when pump
        (dzn:defer pump p f)))))

(define-method (dzn:prune-deferred (o <dzn:component>))
  (let ((pump (dzn:get (.locator o) <dzn:runtime-pump>)))
    (when pump
      (dzn:prune-deferred pump))))

(define-method (call-in (o <dzn:component>) f m)
  (let ((log (dzn:get (.locator o) <procedure> "trace"))
        (port (car m)))
    (when (or (.handling? o)
              (dzn:blocked? o port))
      (dzn:collateral-block o port))
    (apply dzn:trace (cons log (take m 2)))
    (set! (.handling? o) (%dzn:id))
    (let ((r (f)))
      (dzn:trace-out log (car m) (dzn:return-value r))
      (dzn:prune-deferred o)
      (set! (.handling? o) #f)
      r)))

(define-method (call-out (o <dzn:component>) f m)
  (let ((log (dzn:get (.locator o) <procedure> "trace")))
    (apply dzn:trace-qin (cons log m))
    (enqueue (.self (.in (car m))) o
      (lambda _
        (apply dzn:trace-qout (cons log m))
        (f)))
    (dzn:prune-deferred o)))

(define* (path o #:optional (p ""))
  (let* ((name (or (and o (.name o)) ""))
         (pp (string-append name
                            (if (and (not (string-null? name))
                                     (not (string-null? p))) "." "") p)))
    (cond
     ((not o) (string-append "<external>" (if (string-null? p) "" ".") p))
    ((is-a? o <dzn:port>) (path (.self o) pp))
     ((and (is-a? o <dzn:model>) (.parent o)) (path (.parent o) pp))
     (else pp))))

(define (dzn:trace-qin log i e)
  (if (not (.out i))
      (dzn:trace-out log i e)
      (let* ((q-path (path (.out i)))
             (q-prefix (substring q-path 0 (string-rindex q-path #\.))))
        (log "~a.~a <- ~a.~a\n" q-prefix "<q>" (path (.in i)) e))))

(define (dzn:trace-qout log i e)
  (when (.out i)
    (let* ((q-path (path (.out i)))
           (q-prefix (substring q-path 0 (string-rindex q-path #\.))))
      (log "~a.~a <- ~a.~a\n" (path (.out i)) e q-prefix "<q>"))))

(define (dzn:trace log i e)
  (log "~a.~a -> ~a.~a\n" (path (.out i)) e (path (.in i)) e))

(define (dzn:trace-out log i e)
  (log "~a.~a <- ~a.~a\n" (path (.out i)) e (path (.in i)) e))
