;;; dzn-runtime -- Dezyne runtime library
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
            dzn:remove))

(define-class <dzn:pump> ()
  (timers #:accessor .timers #:init-form (list))
  (canceled #:accessor .canceled #:init-form (list))
  (release #:accessor .release #:init-value #f)
  (stack #:accessor .stack #:init-form (list))
  (prompt-tag #:accessor .prompt-tag #:init-form (make-prompt-tag "pump")))

(define-method (dzn:finalize (o <dzn:pump>))
  (dzn:pump o (const *unspecified*)))

(define (%debug . rest)
  (when (getenv "PUMP_DEBUG")
    (apply format (cons (current-error-port) rest)))  )

(define-method (dzn:pump (o <dzn:pump>) (event <procedure>) (next-event <procedure>))
  (define (worker cont request port)
    (%debug "worker! cont: ~a, request:~a, port:~a\n" cont request port)
    (let ((port-cont (assoc-ref (.stack o) port)))
      (case request
        ((block)
         (when port-cont
           (throw 'pump-invalid "port already blocked" (.name (.in port))))
         (set! (.stack o) (acons port cont (.stack o)))
         (if (.release o) (throw 'pump-invalid "release set" (.release o))
             (let ((event (next-event)))
               (when (and event (not (eof-object? event)))
                 (dzn:pump o event next-event)))))
        ((release)
         (if port-cont
             (begin
               (set! (.stack o) (assoc-remove! (.stack o) port))
               (when (.release o)
                 (throw 'pump-invalid "release already set" (.release o)))
               (set! (.release o) cont)
               (port-cont))
             (begin
               (%debug "release fall-through: ~a\n" cont)
               (set! (.release o) cont)
               (cont))))
        (else (throw 'pump-invalid "unknown request" request (.name (.in port)))))))

  (call-with-prompt (.prompt-tag o) event worker)

  (let ((release (.release o)))
    (when release
      (set! (.release o) #f)
      (%debug "release: ~a\n" release)
      (release)))

  (let ((timers (.timers o)))
    (set! (.timers o) '())
    (let loop ((timers timers))
      (when (and (pair? timers))
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
        (loop timers)))))

(define-method (dzn:pump (o <dzn:pump>) (event <procedure>))
  (dzn:pump o event (lambda _ #t)))

(define-method (dzn:handle (o <dzn:pump>) x deadline event rank) ;; FIXME: deadline ignored
  (set! (.timers o) (acons rank (cons x event) (.timers o)))
  (%debug "dzn:handle: timers: ~a\n" (.timers o)))

(define-method (dzn:remove (o <dzn:pump>) x)
  (set! (.canceled o) (cons x (.canceled o)))
  (%debug "dzn:remove: timers: ~a\n" (.canceled o)))

(define-method (dzn:block (o <dzn:pump>) (port <dzn:interface>))
  (%debug "dzn:block: port: ~a\n" (.name (.in port)))
  (if (.release o) (begin
                     (%debug "dzn:release: fall-through\n")
                     (set! (.release o ) #f))
      (abort-to-prompt (.prompt-tag o) 'block port))
  (%debug "dzn:block: continue: ~a\n" (.name (.in port))))

(define-method (dzn:release (o <dzn:pump>) (port <dzn:interface>))
  (%debug "dzn:release: port: ~a\n" (.name (.in port)))
  (abort-to-prompt (.prompt-tag o) 'release port)
  (%debug "dzn:release: continue: ~a\n" (.name (.in port))))
