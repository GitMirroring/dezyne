;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (dzn vm report)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn command-line)
  #:use-module (dzn ast)
  #:use-module (dzn code dzn)
  #:use-module (dzn misc)
  #:use-module (dzn wfc)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm util)
  #:export (%modeling?
            debug:lts->alist
            display-trace-n
            display-trails
            label->string
            step->location
            trace->trail
            trace->string-trail
            report))

;;;
;;; Trail (a.k.a. events, named event trace)
;;;

;; Show modeling events on trail?
(define %modeling? (make-parameter #F))

(define (display-trails traces)
  (when (pair? traces)
    (display-trail-n (car traces) 0)))

(define (display-trail-n t i)
  (when (> i 0)
    (format (current-error-port) "\ntrace [~a]:\n" i))
  (display-trail t))

(define-method (display-trail (o <list>))
  (display (string-join (map cdr (trace->trail o)) "\n" 'suffix)))

(define-method (trace->trail (o <list>))
  (filter-map trace->trail (reverse o)))

(define-method (trace->trail (o <program-counter>))
  (and (pc-event? o) (pc->event o)))

(define (trace->string-trail trace)
  (let ((trail (map cdr (trace->trail trace))))
    (define (strip-sut-prefix o)
      (if (string-prefix? "sut." o) (substring o 4) o))
    (map strip-sut-prefix trail)))

(define (debug:lts->alist pc->state-number lts)
  (define (entry->pair from pc+traces)
    (match pc+traces
      ((pc traces ...)
       (cons from
             (map (lambda (trace)
                    (append (trace->string-trail trace)
                            (list (pc->state-number (car trace)))))
                  traces)))))
  (let ((alist (hash-map->list entry->pair lts)))
    (sort alist (match-lambda* (((from-a traces ...) (from-b traces ...))
                                (< from-a from-b))))))

;;; events predicate

(define-method (pc-event? (o <program-counter>))
  (or (and=> (.status o) (negate (is? <end-of-trail>)))
      (pc-event? o (.statement o))))

(define-method (pc-event? (pc <program-counter>) (o <statement>))
  (pc-event? (.instance pc) o))

(define-method (pc-event? (pc <program-counter>) (o <initial-compound>))
  (pc-event? (.instance pc) (.trigger pc)))

(define-method (pc-event? (o <runtime:port>) (trigger <trigger>))
  (and (eq? o (%sut))
       (or (%modeling?)
           (not (ast:modeling? trigger)))))

(define-method (pc-event? (o <runtime:component>) (trigger <trigger>))
  (let ((port (.port trigger)))
    (and port
         (let ((r:other-port (runtime:other-port (runtime:port o port))))
           (runtime:boundary-port? r:other-port)))))

(define-method (pc-event? (o <runtime:component>) (trigger <q-trigger>))
  #f)

(define-method (pc-event? (o <runtime:port>) (action <action>))
  (or (ast:in? action)
      (is-a? (%sut) <runtime:port>)
      (and (ast:requires? o)
           (not (ast:external? o)))))

(define-method (pc-event? (o <runtime:component>) (action <action>))
  (and (not (ast:async? action))
       (let* ((port (.port action))
              (r:port (runtime:port o port))
              (r:other-port (runtime:other-port r:port)))
         (or (ast:injected? port)
             (runtime:boundary-port? r:other-port)))))

(define-method (pc-event? (o <runtime:component>) (q-out <q-out>))
  (let* ((trigger (.trigger q-out))
         (port (.port trigger)))
    (or (ast:provides? port)
        (ast:external? port))))

(define-method (pc-event? (pc <program-counter>) (o <trigger-return>))
  (and (not (is-a? (.event (.trigger pc)) <modeling-event>))
       (pc-event? (.instance pc) o)))

(define-method (pc-event? (o <runtime:port>) (return <trigger-return>))
  (or (is-a? (%sut) <runtime:port>)
      (and (runtime:boundary-port? o)
           (ast:requires? o))))

(define-method (pc-event? (o <runtime:component>) (return <trigger-return>))
  (let ((port (.port return)))
    (and port
         (not (ast:async? port))
         (let* ((r:port (runtime:port o port))
                (r:other-port (and r:port (runtime:other-port r:port))))
           (or (eq? r:port r:other-port) ;The other port is injected, no
                                         ;chance to find our way back
                                         ;and use ast:injected?
               (and r:other-port
                    (runtime:boundary-port? r:other-port)
                    (ast:provides? r:other-port)))))))

(define-method (pc-event? x y)
  #f)

;;; events formatting

(define-method (trace-name (o <runtime:instance>))
  (cond ((is-a? (%sut) <runtime:port>) #f)
        ((null? (runtime:instance->path o)) "sut")
        (else (string-join (runtime:instance->path o) "."))))

(define-method (pc->event (o <program-counter>))
  (if (and=> (.status o) (negate (is? <end-of-trail>))) (pc->event (.status o))
      (pc->event o (.statement o))))

(define-method (pc->event (o <error>))
  (cons #f (format #f "<~a>" (or (.message o) "error"))))

(define-method (pc->event (o <blocked-error>))
  (cons #f "<deadlock>"))

(define-method (pc->event (o <match-error>))
  (cons #f "<match>"))

(define-method (pc->event (o <postponed-match>))
  (cons #f "<postponed-match>"))

(define-method (pc->event (pc <program-counter>) (o <statement>))
  (pc->event (.instance pc) o))

(define-method (pc->event (pc <program-counter>) (o <initial-compound>))
  (pc->event (.instance pc) o (.trigger pc)))

(define-method (pc->event (o <runtime:port>) (compound <initial-compound>) (trigger <trigger>))
  (cons trigger (format #f "~a" (.event.name trigger))))

(define-method (pc->event (o <runtime:component>) (compound <initial-compound>) (trigger <trigger>))
  (cons trigger
        (let* ((port (.port trigger))
               (r:other-port (runtime:other-port (runtime:port o port))))
          (format #f "~a.~a" (trace-name r:other-port) (.event.name trigger)))))

(define-method (pc->event (o <runtime:port>) (action <action>))
  (cons action
        (if (ast:out? action)
            (format #f "~a~a" (or (and=> (trace-name o) (cut format #f "~a." <>)) "") (trigger->string action))
            (format #f "~a" (trigger->string action)))))

(define-method (pc->event (o <runtime:component>) (action <action>))
  (cons action
        (let* ((port (.port action))
               (r:port (runtime:port o port))
               (r:other-port (runtime:other-port r:port)))
          (if (ast:injected? port)
              (format #f "~a.~a" (.name (.ast r:other-port)) (.event.name action))
              (let ((trigger (action->trigger r:other-port action)))
                (format #f "~a.~a" (trace-name r:other-port) (trigger->string trigger)))))))

(define-method (pc->event (o <runtime:component>) (q-out <q-out>))
  (let ((trigger (.trigger q-out)))
    (cons q-out (trigger->string trigger))))

(define-method (pc->event (pc <program-counter>) (o <trigger-return>))
  (let* ((value (->sexp (.reply pc)))
         (value (and (not (equal? value "void")) value)))
    (pc->event (.instance pc) (clone o #:event.name (or value (format #f "~a" (.event.name o)))))))

(define-method (pc->event (o <runtime:port>) (return <trigger-return>))
  (cons return
        (let ((value (or (.expression return) (.event.name return))))
          (if (or (eq? o (%sut)) (not (trace-name o))) (format #f "~a" value)
              (format #f "~a.~a" (trace-name o) value)))))

(define-method (pc->event (o <runtime:component>) (return <trigger-return>))
  (cons return
        (let ((port (.port return)))
          (let* ((r:port (runtime:port o port))
                 (r:other-port (and r:port (runtime:other-port r:port))))
            (if (eq? r:port r:other-port) ;The other port is injected,
                                          ;no chance to find our way back
                                          ;and use ast:injected?
                (format #f "~a.~a" (.name port) (.event.name return))
                (let ((value (or (.expression return) (.event.name return))))
                  (format #f "~a.~a" (trace-name r:other-port) value)))))))

(define-method (pc->event x y)
  #f)


;;;
;;; Trace (a.k.a. arrows, broken arrows)
;;;

(define-method (trace->arrows (o <list>))
  (filter-map trace->arrows (reverse o)))

(define-method (trace->arrows (o <program-counter>))
  (and (pc-arrow? o) (pc->arrow o)))

;;; arrow predicate

(define-method (pc-arrow? (o <program-counter>))
  (if (and=> (.status o) (negate (is? <end-of-trail>))) (pc-event? o)
      (pc-arrow? o (.statement o))))

(define-method (pc-arrow? (pc <program-counter>) (o <statement>))
  (pc-arrow? (.instance pc) o))

(define-method (pc-arrow? (pc <program-counter>) (o <initial-compound>))
  (pc-arrow? (.instance pc) (.trigger pc)))

(define-method (pc-arrow? (o <runtime:port>) (trigger <trigger>))
  (not (ast:modeling? trigger)))

(define-method (pc-arrow? (o <runtime:component>) (trigger <trigger>))
  #t)

(define-method (pc-arrow? (o <runtime:component>) (trigger <q-trigger>))
  #f)

(define-method (pc-arrow? (o <runtime:component>) (q-in <q-in>))
  #t)

(define-method (pc-arrow? (o <runtime:port>) (action <action>))
  #t)

(define-method (pc-arrow? (o <runtime:component>) (action <action>))
  (not (ast:async? (.port action))))

(define-method (pc-arrow? (o <runtime:port>) (q-out <q-out>))
  #t)

(define-method (pc-arrow? (o <runtime:component>) (q-out <q-out>))
  #t)

(define-method (pc-arrow? (pc <program-counter>) (o <trigger-return>))
  (and (not (is-a? (.event (.trigger pc)) <modeling-event>))
       (pc-arrow? (.instance pc) o)))

(define-method (pc-arrow? (o <runtime:port>) (return <trigger-return>))
  (let ((on (parent return <on>)))
    (and on
         (let ((trigger (car (ast:trigger* on))))
           (or (is-a? (%sut) <runtime:port>)
               (not (ast:modeling? trigger)))))))

(define-method (pc-arrow? (o <runtime:component>) (return <trigger-return>))
  #t)

(define-method (pc-arrow? x y)
  (pc-event? x y))

;;; arrow formatting

(define-method (pc->arrow (o <program-counter>))
  (cons o
        (if (and=> (.status o) (negate (is? <end-of-trail>))) (pc->event (.status o))
            (pc->arrow o (.statement o)))))

(define-method (pc->arrow (pc <program-counter>) (o <statement>))
  (pc->arrow (.instance pc) o))

(define-method (pc->arrow (pc <program-counter>) (o <initial-compound>))
  (pc->arrow (.instance pc) o (.trigger pc)))

(define-method (pc->arrow (o <runtime:port>) (compound <initial-compound>) (trigger <trigger>))
  (cons trigger
        (if (or (ast:provides? o)
                (and (is-a? (%sut) <runtime:port>)
                     (not (eq? o (%sut)))))
            (format #f "~a.~a -> ..." (runtime:instance->string o) (.event.name trigger))
            (format #f "... -> ~a.~a" (runtime:instance->string o) (.event.name trigger)))))

(define-method (pc->arrow (o <runtime:component>) (compound <initial-compound>) (trigger <trigger>))
  (cons trigger
        (let* ((port (.port trigger))
               (r:port (runtime:port o port))
               (r:other-port (runtime:other-port r:port)))
          (cond
           ((eq? r:port r:other-port) ; injected
            (format #f "... -> ~a.~a" (runtime:instance->string r:port) (.event.name trigger)))
           (else
            (format #f "... -> ~a.~a" (runtime:instance->string r:port) (.event.name trigger)))))))

(define-method (pc->arrow (o <runtime:port>) (action <action>))
  (cons action
        (if (or (ast:provides? o)
                (and (is-a? (%sut) <runtime:port>)
                     (not (eq? o (%sut)))))
            (format #f "~a.~a <- ..." (runtime:instance->string o) (.event.name action))
            (format #f "... <- ~a.~a" (runtime:instance->string o) (.event.name action)))))

(define-method (pc->arrow (o <runtime:component>) (action <action>))
  (cons action
        (let* ((port (.port action))
               (r:port (runtime:port o port))
               (r:other-port (runtime:other-port r:port))
               (trigger (action->trigger r:other-port action)))
          (cond
           ((ast:injected? port)
            (format #f "~a.~a -> ..." (runtime:instance->string r:port) (.event.name action)))
           ((ast:out? action)
            (format #f "... <- ~a.~a" (runtime:instance->string r:port) (.event.name trigger)))
           (else
            (format #f "~a.~a -> ..." (runtime:instance->string r:port) (.event.name trigger)))))))

(define-method (pc->arrow (o <runtime:component>) (q-in <q-in>))
  (cons q-in (format #f "~a.<q> <- ..." (runtime:instance->string o))))

(define-method (pc->arrow (o <runtime:port>) (q-out <q-out>))
  (cons q-out
        (let* ((r:other-port (runtime:other-port o))
               (r:other-instance (.container r:other-port)))
          (format #f "... <- ~a.<q>" (runtime:instance->string r:other-instance)))))

(define-method (pc->arrow (o <runtime:component>) (q-out <q-out>))
  (cons q-out
        (let* ((trigger (.trigger q-out))
               (r:port (runtime:port o (.port trigger))))
          (format #f "~a.~a <- ..." (runtime:instance->string r:port) (.event.name trigger)))))

(define-method (pc->arrow (pc <program-counter>) (o <trigger-return>))
  (let* ((value (->sexp (.reply pc)))
         (value (and (not (equal? value "void")) value)))
    (pc->arrow (.instance pc) (clone o #:event.name (or value (format #f "~a" (.event.name o)))))))

(define-method (pc->arrow (o <runtime:port>) (return <trigger-return>))
  (cons return
        (let ((value (or (.expression return) (.event.name return))))
          (cond ((ast:eq? o (%sut))
                 (format #f "... <- ~a.~a" (runtime:instance->string o) value))
                ((or (ast:provides? o)
                     (and (is-a? (%sut) <runtime:port>)
                          (not (eq? o (%sut)))))
                 (format #f "~a.~a <- ..." (runtime:instance->string o) value))
                (else
                 (format #f "... <- ~a.~a" (runtime:instance->string o) value))))))

(define-method (pc->arrow (o <runtime:component>) (return <trigger-return>))
  (cons return
        (let ((port (.port return)))
          (let* ((r:port (and port (runtime:port o port)))
                 (r:other-port (and r:port (runtime:other-port r:port)))
                 (value (or (.expression return) (.event.name return)))                 )
            (cond
             ((ast:injected? port)
              (format #f "~a.~a <- ..." (runtime:instance->string r:port) (.event.name return)))
             ((and r:port (eq? r:port r:other-port)) ;injected
              (format #f "... <- ~a.~a" (runtime:instance->string r:port) (.event.name return)))
             ((ast:provides? port)
              (format #f "... <- ~a.~a" (runtime:instance->string r:port) value))
             (else
              (format #f "~a.~a <- ..." (runtime:instance->string r:port) value)))))))

(define-method (pc->arrow x y)
  #f)

(define-method (pc->arrow x)
  #f)


;;;
;;; Steps (a.k.a. micro steps, arrows with assignments, calls, ...
;;;

(define-method (trace->steps (o <list>))
  (filter-map trace->steps (reverse o)))

(define-method (trace->steps (o <program-counter>))
  (and (pc-step? o) (pc->step o)))

;;; step predicate

(define-method (pc-step? (o <program-counter>))
  (if (and=> (.status o) (negate (is? <end-of-trail>))) (pc-event? (.status o))
      (pc-step? o (.statement o))))

(define-method (pc-step? (pc <program-counter>) (o <initial-compound>))
  (pc-arrow? (.instance pc) (.trigger pc)))

(define-method (pc-step? (pc <program-counter>) (o <statement>))
  #t)

(define-method (pc-step? (pc <program-counter>) (o <compound>))
  #f)

(define-method (pc-step? (pc <program-counter>) (o <declarative-compound>))
  #f)

(define-method (pc-step? (pc <program-counter>) (o <on>))
  #f)

(define-method (pc-step? (pc <program-counter>) (o <end-of-on>))
  #f)

(define-method (pc-step? (pc <program-counter>) (o <flush-return>))
  #f)

(define-method (pc-step? x y)
  (pc-arrow? x y))

(define-method (pc-step? x)
  (pc-arrow? x))

;;; step formatting

(define-method (pc->step (o <program-counter>))
  (if (and=> (.status o) (negate (is? <end-of-trail>))) (pc->event (.status o))
      (pc->step o (.statement o))))

(define-method (pc->step (pc <program-counter>) (o <guard>))
  (cons o (format #f "[~a]" (string-trim-both (ast->dzn (.expression o))))))

(define-method (pc->step (pc <program-counter>) (o <statement>))
  (or (pc->arrow pc o)
      (cons o (string-trim-both (ast->dzn o)))))

(define-method (pc->step x y)
  (pc->arrow x y))


;;;
;;; Report
;;;

(define (complete-split-arrows-pcs trace)
  "The split-arrows format needs a PC for both ends of the arrow.
Add (synthesize) missing PCs for <q-in>, <q-out> and <trigger-return>."

  (define (external-triggers pc)
    (append-map cdr (.external-q pc)))

  (define (injected-port-name component interface)
    (let* ((ports (filter ast:injected? (ast:port* component)))
           (port (find (compose (cute ast:eq? <> interface) .type) ports)))
      (.name port)))

  (let loop ((trace trace) (result '()))
    (if (null? trace) (reverse result)
        (let* ((next (and (pair? result) (car result)))
               (pc (car trace))
               (pc-instance (.instance pc))
               (statement (.statement pc)))
          (cond
           ((and (is-a? (%sut) <runtime:port>)
                 (is-a? statement <initial-compound>))
            (let ((client-pc (clone pc #:instance (car (%instances)))))
              (loop (cdr trace) (cons* client-pc pc result))))
           ((and (is-a? (%sut) <runtime:port>)
                 (is-a? statement <action>))
            (let ((client-pc (clone pc #:instance (car (%instances)))))
              (loop (cdr trace) (cons* pc client-pc result))))
           ((and (is-a? (%sut) <runtime:port>)
                 (is-a? statement <trigger-return>))
            (let ((client-pc (clone pc #:instance (car (%instances)))))
              (loop (cdr trace) (cons* pc client-pc result))))
           ((and next
                 (is-a? statement <action>)
                 (is-a? (.trigger next) <q-trigger>)
                 (is-a? pc-instance <runtime:component>)
                 (let* ((port (.port statement))
                        (r:port (runtime:port pc-instance port))
                        (r:other-port (and r:port (runtime:other-port r:port))))
                   (and r:other-port
                        (ast:provides? r:other-port))))
            (let* ((port (.port statement))
                   (r:port (runtime:port pc-instance port))
                   (r:other-port (and r:port (runtime:other-port r:port)))
                   (action (clone statement #:port.name #f))
                   (action (clone action #:parent (.ast r:other-port)))
                   (action-pc (clone pc #:instance r:other-port #:statement action)))
              (loop (cdr trace) (cons*  pc action-pc result))))
           ((and next
                 (is-a? statement <action>)
                 (ast:out? statement)
                 (.instance next)
                 (.deferred (get-state next))
                 (pair? (.q (get-state next (.deferred (get-state next))))))
            (let* ((deferred (.deferred (get-state next)))
                   (trigger (car (.q (get-state next deferred))))
                   (q-in (make <q-in> #:trigger trigger #:location (.location trigger)))
                   (q-in (clone q-in #:parent (.ast deferred)))
                   (q-pc (clone pc #:instance deferred #:statement q-in)))
              (loop (cdr trace) (cons* pc q-pc result))))
           ((and (is-a? statement <q-out>)
                 (is-a? pc-instance <runtime:component>))
            (let* ((trigger (.trigger statement))
                   (port (.port trigger))
                   (r:port (runtime:port pc-instance port))
                   (r:other-port (and r:port (runtime:other-port r:port)))
                   (q-trigger (clone trigger #:port.name #f))
                   (on (find (compose (is? <on>) .statement) result))
                   (on (and on (.statement on)))
                   (location (if on (.location on) (.location statement)))
                   (pc (clone pc #:statement (clone statement #:location location)))
                   (q-out (clone statement #:trigger q-trigger #:location location))
                   (q-out (clone q-out #:parent (.ast r:other-port)))
                   (q-pc (clone pc #:instance r:other-port #:statement q-out)))
              (loop (cdr trace) (cons* q-pc pc result))))
           ((and (is-a? statement <action>)
                 (ast:out? statement)
                 (is-a? pc-instance <runtime:port>)
                 (ast:external? pc-instance)
                 (> (length (external-triggers next)) (length (external-triggers pc))))
            (let* ((trigger (car (external-triggers next)))
                   (port (.port trigger))
                   (r:port (runtime:port pc-instance port))
                   (r:other-port (and r:port (runtime:other-port r:port)))
                   (r:other-instance (.container r:other-port))
                   (q-in (make <q-in> #:trigger trigger #:location (.location trigger)))
                   (q-in (clone q-in #:parent (.ast r:other-instance)))
                   (q-pc (clone pc #:instance r:other-instance #:statement q-in)))
              (loop (cdr trace) (cons* pc q-pc result))))
           ((and next
                 (not (is-a? (%sut) <runtime:port>))
                 (is-a? statement <trigger-return>)
                 (is-a? (.instance next) <runtime:component>)
                 (or (and (is-a? pc-instance <runtime:port>)
                          (ast:requires? pc-instance))
                     (and (is-a? pc-instance <runtime:component>)
                          (let* ((port (.port statement))
                                 (r:port (if (is-a? pc-instance <runtime:port>) pc-instance
                                             (runtime:port pc-instance port)))
                                 (r:other-port (runtime:other-port r:port)))
                            (or (ast:requires? r:other-port)
                                (eq? r:port r:other-port))))) ; injected
                 (not (ast:modeling? (car (ast:trigger* (parent statement <on>))))))
            (let* ((next-statement (.statement next)) ;; XXX statement *after* action
                   (next-instance (.instance next))
                   (port (.port statement))
                   (r:port (if (is-a? pc-instance <runtime:port>) pc-instance
                               (runtime:port pc-instance port)))
                   (r:other-port (runtime:other-port r:port))
                   (interface (and port (.type port)))
                   (component (.type (.ast next-instance)))
                   (port-name (if (eq? r:port r:other-port) (injected-port-name component interface)
                                  (.name (.ast r:other-port))))
                   (return (clone statement
                                  #:port.name port-name
                                  #:location (.location statement)))
                   (return (clone return #:parent component))
                   (return-pc (clone pc #:instance next-instance #:statement return)))
              (loop (cdr trace) (cons* pc return-pc result))))
           (else
            (loop (cdr trace) (cons pc result))))))))

(define (set-trigger-locations trace)
  "The trigger in the TRACEs PCs are synthesized; set their location to
the location of the executed <on>-statement."
  (let loop ((trace trace))
    (if (null? trace) '()
        (let* ((pc (car trace))
               (trigger (.trigger pc))
               (model (and trigger (parent trigger <model>)))
               (on (and=> (find (conjoin (compose (is? <on>) .statement)
                                         (compose (cute ast:eq? <> model)
                                                  (cute parent <> <model>)
                                                  .statement))
                                trace)
                          .statement))
               (trigger (and trigger on (clone trigger #:location (.location on))))
               (pc (if (not trigger) pc (clone pc #:trigger trigger))))
          (cons pc (loop (cdr trace)))))))

(define (step->location o)
  (let ((location (ast:location o)))
    (and location
         (format #f "~a:~a:~a: "
                 (.file-name location)
                 (.line location)
                 (.column location)))))

(define* (display-trace trace #:key locations? state? verbose?)
  "Write TRACE as split-arrows trace to stdout.  When LOCATIONS?,
prepend every line with its location.  When VERBOSE?, also show
intermediate steps such as assignments, function calls, replies,
... (aka micro-trace)."
  (let* ((trace (complete-split-arrows-pcs trace))
         (trace (reverse (set-trigger-locations (reverse trace))))
         (steps (if verbose? (trace->steps trace)
                    (trace->arrows trace))))
    (define write-step
      (match-lambda*
        (((pc ast . string) i)
         (when (and ast locations?)
           (let ((location (step->location ast)))
             (when location
               (display location))))
         (write-line string)
         (when (and state?
                    (odd? i)
                    (< i (1- (length steps))))
           (serialize (.state pc) (current-output-port))
           (newline)))))
    (for-each write-step steps (iota (length steps)))))

(define (label->string o)
  (match o
    (($ <action>)
     (trigger->string o))
    (($ <enum-literal>)
     (string-append (ast:name (.type.name o)) ":" (.field o)))
    (($ <literal>)
     (label->string (.value o)))
    ((? (is? <trigger>))
     (trigger->string o))
    ((and ($ <trigger-return>) (= .expression #f))
     "return")
    ((and ($ <trigger-return>) (= .expression expression) (= .port.name #f))
     (string-append (label->string expression)))
    ((and ($ <trigger-return>) (= .expression #f) (= .port.name port))
          (string-append port "." "return"))
    ((and ($ <trigger-return>) (= .expression expression) (= .port.name port))
     (string-append port "." (label->string expression)))
    ((? (is? <model>))
     #f)
    ((? string?)
     o)
    (#f
     "false")
    (#t
     "true")))

(define (initial-error-message traces)
  (let* ((pcs (map car traces))
         (status (.status (car pcs))))
    (match status
      (($ <compliance-error>)
       (let* ((component-acceptance (.component-acceptance status))
              (port-acceptances (.port-acceptance status))
              (port-acceptances (and port-acceptances
                                     (ast:acceptance* port-acceptances)))
              (port-acceptance (and (pair? port-acceptances) (car port-acceptances)))
              (location (or (step->location (or component-acceptance
                                                port-acceptance))
                            "<unknown-file>:")))
         (format #f "~aerror: non-compliance\n" location)))
      (($ <fork-error>)
       (let ((location (or (and=> (.ast status) step->location)
                           "<unknown-file>:")))
         (format #f "~aerror: non-compliance\n" location)))
      (($ <refusals-error>)
       (let ((location (or (and=> (.ast status) step->location)
                           "<unknown-file>:")))
         (format #f "~aerror: non-compliance\n" location)))
      ((and (? (is? <determinism-error>)))
       (let ((locations (map (lambda (pc)
                               (or (step->location (.ast (.status pc)))
                                   "<unknown-file>:"))
                             pcs)))
         (string-join
          (map (cut format #f "~aerror: non-deterministic\n" <>) locations) "")))
      (($ <queue-full-error>)
       (let* ((model ((compose  ast:dotted-name .type .ast .instance) status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: queue-full in component ~s\n" location model)))
      (($ <range-error>)
       (let* ((variable (.variable status))
              (name (.name variable))
              (type (.type variable))
              (value (.value status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: range-error: invalid value `~a' for variable `~a'\n" location value name)))
      ((and (? (is? <missing-reply-error>)))
       (let* ((type (.type status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: missing-reply: ~a reply expected\n" location (type-name type))))
      (($ <second-reply-error>)
       (let* ((previous (.previous status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~aerror: second-reply\n" location)))
      ((and (? (is? <match-error>)) (= .ast ast))
       (let ((location (or (step->location ast)
                           "<unknown-file>:")))
         (format #f "~aerror: ~a\n" location (.input status))))
      ((and (? (is? <error>)) (= .ast ast) (= .message message))
       (let ((location (or (step->location ast)
                           "<unknown-file>:")))
         (format #f "~aerror: ~a\n" location message)))
      (($ <end-of-trail>) #f)
      (_ #f #f))))

(define (final-error-messages traces)
  (let* ((pcs (map car traces))
         (pc (car pcs))
         (status (.status pc)))
    (match status
      (($ <compliance-error>)
       (let* ((component-acceptance (.component-acceptance status))
              (port-acceptances (.port-acceptance status))
              (port-acceptances (and port-acceptances
                                     (ast:acceptance* port-acceptances)))
              (port-acceptance (and (pair? port-acceptances) (car port-acceptances)))
              (location (or (step->location (or component-acceptance
                                                port-acceptance))
                            "<unknown-file>:"))
              (acceptance (if component-acceptance (trigger->string component-acceptance)
                              "-"))
              (r:port (.port status))
              (port-name (and r:port (string-join (runtime:instance->path r:port) ".")))
              (component-name (string-join (runtime:instance->path (or (.instance (car pcs)) (%sut))) "."))
              (trigger (.trigger status)))
         (string-join
          (append
           (if (not trigger) '()
               (let ((location (step->location (.event trigger))))
                (list (format #f "~atrigger: ~a\n" location (trigger->string trigger)))))
           (list (format #f "~acomponent accept: ~a\n" location acceptance))
           (if (not port-acceptances)
               (let* ((interface (.type (.ast r:port)))
                      (ast (.behaviour interface)))
                 (list (format #f "~aport accept: -\n" (step->location ast))))
               (map
                (lambda (ast)
                  (if ast
                      (format #f "~aport accept: ~a\n" (step->location ast) (trigger->string ast))
                      (let* ((ast ((compose .statement .behaviour .type .ast .port) status))
                             (location (step->location ast)))
                        (format #f "~aport accept: ~a\n"  location "-"))))
                port-acceptances)))
          "")))
      (($ <fork-error>)
       (let* ((action (.ast status))
              (location (step->location action))
              (action-port (.port action))
              (action-port-name (.name action-port))
              (trigger (.trigger pc))
              (trigger-location (step->location (parent action <on>)))
              (trigger-port (.port trigger))
              (trigger-port-name (.name trigger-port)))
         (string-join
          (list
           (format #f "~aforking not allowed, action on port: ~a\n" location action-port-name)
           (format #f "~afor trigger on port ~a\n" trigger-location trigger-port-name))
          "")))
      (($ <refusals-error>)
       (let ((refusals (sort (.refusals status) equal?))
             (location (or (and=> (.ast status) step->location)
                           "<unknown-file>:")))
         (string-join
          (map (compose
                (cute format #f "~aerror: component refusal: ~a\n" location <>)
                string-join)
               refusals)
          "")))
      (($ <range-error>)
       (let* ((variable (.variable status))
              (name (.name variable))
              (type (.type variable))
              (value (.value status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (string-join
          (list
           (format #f "~ainfo: ~a `~a' defined here\n" (step->location variable) (ast-name variable) name)
           (format #f "~ainfo: of type `~a' defined here\n" (step->location type) (ast:name type)))
          "")))
      (($ <second-reply-error>)
       (let* ((previous (.previous status))
              (location (or (step->location (.ast status))
                            "<unknown-file>:")))
         (format #f "~ainfo: reply previously set here\n" (step->location previous))))
      ((and (? (is? <match-error>)) (= .ast #f))
       (let ((location "<unknown-file>:"))
         (format #f "~aerror: no match; got input `~s'\n" location (.input status))))
      ((and (? (is? <match-error>)) (= .ast ast))
       (let ((location (or (step->location ast)
                           "<unknown-file>:"))
             (label (label->string ast)))
         (if (not label)
             (format #f "~aerror: no match; got input `~s'\n"
                     location (.input status))
             (format #f "~aerror: no match; at ast `~s', got input `~s'\n"
                     location (label->string ast) (.input status)))))
      ((and ($ <end-of-trail> ) (and (= .ast ast)))
       (and ast
            (let* ((instance (.instance (car pcs)))
                   (port-name (if instance (string-join (runtime:instance->path instance) ".")
                                  (.port.name ast)))
                   (instance (if instance (runtime:instance->string instance)
                                 port-name))
                   (location (or (step->location (.ast status))
                                 "<unknown-file>:"))
                   (ast (trigger->string (clone ast #:port.name #f))))
              (format #f "~ainfo: end of trail; stopping here: ~a.~a\n" location instance ast))))
      (_ #f))))

(define (end-of-trail-labels pc)
  (let* ((status (.status pc))
         (instance (.instance pc))
         (ast (.ast status))
         (port-name (if instance (string-join (runtime:instance->path instance) ".")
                        (.port.name ast)))
         (location (or (step->location (.ast status))
                       "<unknown-file>:"))
         (ast (trigger->string (clone ast #:port.name #f)))
         (labels (ast:label* status))
         (labels (map label->string labels))
         (labels (map (cut string-append port-name "." <>) labels)))
    labels))

(define* (report traces #:key eligible (trace "event") locations? state? verbose?)
  (let* ((pcs (and (pair? traces) (map car traces)))
         (pc (and pcs (car pcs)))
         (status (and pc (.status pc)))
         (initial-message (and status (initial-error-message traces))))
    (when initial-message
      (display initial-message)
      (display initial-message (current-error-port)))

    ;; XXX TODO: handle set of (non-deterministic) traces.
    ;;(for-each display-trace-n traces (iota (length traces)))
    (cond ((null? traces))
          ((equal? trace "event")
           (display-trails traces))
          ((equal? trace "trace")
           (display-trace (car traces)
                          #:locations? locations? #:state? state? #:verbose? verbose?)))

    (when pc
      (serialize (.state pc) (current-output-port))
      (newline))

    (when (and (equal? trace "trace") initial-message)
      (display initial-message))
    (when (pair? traces)
      (let ((final-messages (final-error-messages traces)))
        (when final-messages
          (display final-messages (current-error-port)))
        (when (equal? trace "trace")
          (let* ((trail (trace->trail (car traces)))
                 (trail (map cdr trail)))
            (when (pair? trail)
              (format #t "~s\n" (cons 'trail trail)))))))

    (when (and (equal? trace "trace")
               eligible)
      (let* ((eligible (if (and (is-a? status <end-of-trail>) (.ast status)) (end-of-trail-labels pc)
                           eligible))
             (labels (labels))
             (labels (if (and (pair? eligible) (not (member (car eligible) labels))) eligible
                         labels)))
        (format #t "~s\n" (cons 'labels labels))
        (format #t "~s\n" (cons 'eligible eligible))))

    status))
