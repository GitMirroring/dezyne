;;; dzn-runtime -- Dezyne runtime library
;;;
;;; Copyright © 2019, 2020, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn pump)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (oop goops)
  #:use-module (dzn runtime)
  #:export (<dzn:pump>
            dzn:block
            dzn:finalize
            dzn:handle
            dzn:pump
            dzn:release
            dzn:remove
            dzn:run-defer)
  #:re-export (dzn:blocked?
               dzn:defer
               dzn:prune-deferred
               dzn:collateral-block))

(define-class <dzn:pump> (<dzn:runtime-pump>)
  (blocked #:accessor .blocked #:init-form (list))
  (canceled #:accessor .canceled #:init-form (list))
  (collateral #:accessor .collateral #:init-form (list))
  (deferred #:accessor .deferred #:init-form (list))
  (id #:accessor .id #:init-value 0)
  (prompt-tag #:accessor .prompt-tag #:init-form (make-prompt-tag "pump"))
  (released #:accessor .released #:init-form (list))
  (timers #:accessor .timers #:init-form (list)))

(define-class <coroutine> ()
  (cont #:accessor .cont #:init-form (const #f) #:init-keyword #:cont)
  (id #:accessor .id #:init-form (%dzn:id) #:init-keyword #:id))

(define-method (write (o <coroutine>) port)
  (display "#<coroutine " port)
  (display (.id o) port)
  (display ">" port))

(define-class <deferred> ()
  (predicate #:accessor .predicate #:init-form (const #t) #:init-keyword #:predicate)
  (procedure #:accessor .procedure #:init-form (const #f) #:init-keyword #:procedure))

(define-method (next-id (o <dzn:pump>))
  (set! (.id o) (1+ (.id o)))
  (.id o))

(define-method (set-id (o <dzn:pump>))
  (let* ((id (%dzn:id))
         (id (if (eq? id -1) (.id o) id)))
    (if (zero? id) (next-id o)
        id)))

(define-method (flush-defer (o <dzn:pump>))
  (dzn:run-defer o)
  (when (pair? (.deferred o))
    (flush-defer o)))

(define-method (dzn:finalize (o <dzn:pump>))
  (flush-defer o)
  (dzn:pump o (const *unspecified*)))

(define (%debug . rest)
  (when (getenv "PUMP_DEBUG")
    (format (current-error-port) "[~a] " (%dzn:id))
    (apply format (cons (current-error-port) rest))))

(define-method (enqueue! (o <dzn:pump>) (q <accessor>) (port <dzn:interface>) (coroutine <coroutine>))
  (set! (q o) (append (q o) (list (cons port coroutine)))))

(define-method (dzn:pump (o <dzn:pump>) (event <procedure>) (next-event <procedure>))
  (define* (worker cont request port #:optional component)
    (define blocked-port
      (match-lambda ((port . coroutine)
                     (and (eq? (.id coroutine) (.handling? component))
                          port))))
    (%debug "worker! cont: ~a, request:~a, port:~a\n" cont request port)
    (case request
      ((block)
       (let ((blocked (make <coroutine> #:cont cont)))
         (enqueue! o .blocked port blocked)
         (let ((event (next-event)))
           (when (procedure? event)
             (dzn:pump o event next-event)))))
      ((collateral-block)
       (let ((port (or (any blocked-port (.blocked o))
                       (any blocked-port (.collateral o)))))
         (let ((blocked (make <coroutine> #:cont cont)))
           (enqueue! o .collateral port blocked)))
       (let ((event (next-event)))
         (when (procedure? event)
           (dzn:pump o event next-event))))
      (else
       (throw 'pump-invalid "unknown request" request (.name (.in port))))))

  (parameterize ((%dzn:id (set-id o)))
    (call-with-prompt (.prompt-tag o) event worker)

    (let loop ()
      (match (.released o)
        (((port . coroutine) rest ...)
         (set! (.released o) rest)
         (let* ((collateral (filter (compose (cute eq? <> port) car) (.collateral o)))
                (collateral (map cdr collateral)))
           (for-each (cute enqueue! o .released port <>) collateral))
         (set! (.collateral o) (assoc-remove! (.collateral o) port))
         (parameterize ((%dzn:id (.id coroutine)))
           (call-with-prompt (.prompt-tag o) (.cont coroutine) worker))
         (loop))
        (_
         #f)))

    (let ((timers (.timers o)))
      (set! (.timers o) '())
      (let loop ((timers timers))
        (when (pair? timers)
          (%debug "timers: ~a\n" (.timers o))
          (%debug "canceled: ~a\n" (.canceled o))
          (let* ((deadline (apply min (map car timers)))
                 (x-e (assoc-ref (reverse timers) deadline))
                 (e (cdr x-e)))
            (%debug "found: ~a\n" (find (cut eq? <> (car x-e)) (.canceled o)))
            (set! timers (filter (negate (compose (cut equal? <> x-e) cdr)) timers))
            (if (find (cut eq? <> (car x-e)) (.canceled o))
                (set! (.canceled o) (filter (negate (cut eq? <> (car x-e))) (.canceled o)))
                (call-with-prompt (.prompt-tag o) e worker)))
          (loop timers))))))

(define-method (dzn:pump (o <dzn:pump>) (event <procedure>))
  (dzn:pump o event (const #t)))

(define-method (dzn:handle (o <dzn:pump>) x deadline event rank) ;; FIXME: deadline ignored
  (set! (.timers o) (acons rank (cons x event) (.timers o)))
  (%debug "dzn:handle: timers: ~a\n" (.timers o)))

(define-method (dzn:remove (o <dzn:pump>) x)
  (set! (.canceled o) (cons x (.canceled o)))
  (%debug "dzn:remove: timers: ~a\n" (.canceled o)))

(define-method (dzn:block (o <dzn:pump>) (port <dzn:interface>))
  (%debug "dzn:block: port: ~a\n" (.name (.in port)))
  (let ((entry (assoc port (.released o))))
    (cond (entry
           (%debug "dzn:block: fall-through 1\n")
           (set! (.released o) (alist-delete port (.released o))))
          (else
           (abort-to-prompt (.prompt-tag o) 'block port))))
  (set! (.blocked o) (alist-delete port (.blocked o)))
  (%debug "dzn:block: continue: ~a\n" (.name (.in port))))

(define-method (dzn:block (o <dzn:component>) (port <dzn:interface>))
  (set! (.handling? o) #f)
  (dzn:flush o)
  (dzn:block (dzn:get (.locator o) <dzn:pump>) port))

(define-method (dzn:release (o <dzn:pump>) (port <dzn:interface>))
  (%debug "dzn:release: port: ~a\n" (.name (.in port)))
  (let ((coroutine (or (assoc-ref (.blocked o) port)
                       (make <coroutine>))))
    (enqueue! o .released port coroutine))
  (%debug "dzn:release: continue: ~a\n" (.name (.in port))))

(define-method (dzn:release (o <dzn:component>) (port <dzn:interface>))
  (dzn:release (dzn:get (.locator o) <dzn:pump>) port))

(define-method (dzn:blocked? (o <dzn:pump>) (port <dzn:interface>))
  (or (assoc port (.blocked o))
      (assoc port (.collateral o))))

(define-method (dzn:collateral-block (o <dzn:pump>) (component <dzn:component>) (port <dzn:interface>))
  (%debug "dzn:collateral-block: port: ~a\n" (.name (.in port)))
  (abort-to-prompt (.prompt-tag o) 'collateral-block port component))

(define-method (dzn:defer (o <dzn:pump>) (p <procedure>) (f <procedure>))
  (let ((deferred (make <deferred> #:predicate p #:procedure f)))
    (set! (.deferred o) (append (.deferred o) (list deferred)))))

(define-method (dzn:run-defer (o <dzn:pump>))
  (dzn:prune-deferred o)
  (match (.deferred o)
    ((deferred rest ...)
     (set! (.deferred o) rest)
     ((.procedure deferred) #t))
    (_
     #f)))

(define-method (dzn:prune-deferred (o <dzn:pump>))
  (set! (.deferred o) (filter (compose (cute <>) .predicate) (.deferred o))))
