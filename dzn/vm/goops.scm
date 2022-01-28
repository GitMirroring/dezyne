;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn vm goops)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn misc)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm runtime)
  #:export (<block>
            <end-of-on>
            <flush-async>
            <flush-return>
            <initial-compound>
            <q-in>
            <q-out>
            <q-trigger>
            <synth-trigger>
            <trigger-return>

            <program-counter>
            <state>
            <system-state>

            <acceptances>
            <blocked-error>
            <compliance-error>
            <determinism-error>
            <deadlock-error>
            <end-of-trail>
            <illegal-error>
            <implicit-illegal-error>
            <livelock-error>
            <match-error>
            <missing-reply-error>
            <postponed-match-error>
            <queue-full-error>
            <range-error>
            <refusals-error>
            <second-reply-error>

            .action
            .async
            .blocked
            .collateral
            .component-acceptance
            .deferred
            .external-q
            .handling
            .input
            .labels
            .port-acceptance
            .previous
            .q
            .refusals
            .released
            .reply
            .return
            .state
            .state-list
            .status
            .trail
            ->sexp
            external-q->string
            name
            pc:next-id
            rtc?)
  #:re-export (.ast
               .event.name
               .id
               .instance
               .port
               .port.name
               .statement
               .trigger
               .type
               .variable
               .variable.name
               .variables
               .value
               clone
               write))

(define-ast <block> (<imperative>))

(define-ast <end-of-on> (<imperative>))

(define-ast <flush-return> (<imperative>))

(define-ast <flush-async> (<statement>))

(define-ast <initial-compound> (<declarative-compound>))

(define-ast <q-in> (<imperative>)
  (trigger))

(define-ast <q-out> (<imperative>)
  (trigger))

(define-ast <q-trigger> (<trigger>))

(define-ast <silent-step> (<imperative>)
  (trigger))

(define-ast <synth-trigger> (<trigger>))

(define-ast <trigger-return> (<imperative>)
  (port.name)
  (event.name #:init-value "return"))

(define-ast <acceptances> (<ast-list>))

(define-ast <blocked-error> (<error>))

(define-ast <compliance-error> (<error>)
  (component-acceptance)
  (port-acceptance)
  (port)
  (trigger))

(define-ast <deadlock-error> (<error>))

(define-ast <determinism-error> (<error>))

(define-ast <labels> (<ast-list>))

(define-ast <end-of-trail> (<status>)
  (labels))

(define-ast <fork-error> (<error>)
  (action))

(define-ast <illegal-error> (<error>))

(define-ast <implicit-illegal-error> (<error>))

(define-ast <livelock-error> (<error>)
  (input))

(define-ast <match-error> (<error>)
  (input)
  (message))

(define-ast <missing-reply-error> (<error>)
  (type))

(define-ast <postponed-match> (<status>)
  (ast)
  (input))

(define-ast <queue-full-error> (<error>)
  (instance))

(define-ast <range-error> (<error>)
  (variable)
  (value))

(define-ast <refusals-error> (<error>)
  (refusals))

(define-ast <second-reply-error> (<error>)
  (previous))

(define-method (.variable.name (o <range-error>))
  (.name (.variable o)))

(define-class <program-counter> ()
  (instance #:getter .instance #:init-value #f #:init-keyword #:instance)
  (previous #:getter .previous #:init-value #f #:init-keyword #:previous)
  (return #:getter .return #:init-form #f #:init-keyword #:return)
  (state #:getter .state #:init-value #f #:init-keyword #:state)
  (status #:getter .status #:init-value #f #:init-keyword #:status)
  (statement #:getter .statement #:init-value #f #:init-keyword #:statement)
  (trail #:getter .trail #:init-value (list) #:init-keyword #:trail)
  (trigger #:getter .trigger #:init-value #f #:init-keyword #:trigger)

  (async #:getter .async #:init-form (list) #:init-keyword #:async)

  (id #:getter .id #:init-value 1 #:init-keyword #:id)
  (blocked #:getter .blocked #:init-form (list) #:init-keyword #:blocked)
  (collateral #:getter .collateral #:init-form (list) #:init-keyword #:collateral)
  (released #:getter .released #:init-form (list) #:init-keyword #:released)
  (external-q #:getter .external-q #:init-form (list) #:init-keyword #:external-q))

(define-class <state> ()
  (instance #:getter .instance #:init-form #f #:init-keyword #:instance)
  (deferred #:getter .deferred #:init-form #f #:init-keyword #:deferred)
  (handling #:getter .handling #:init-form #f #:init-keyword #:handling)
  (q #:getter .q #:init-form (list) #:init-keyword #:q)
  (reply #:getter .reply #:init-form #f #:init-keyword #:reply)
  (variables #:getter .variables #:init-form (list) #:init-keyword #:variables))

(define pc:next-id
  (let ((id 0))
    (lambda ()
      (set! id (1+ id))
      id)))

(define-method (clone (o <state>) . setters)
  (apply clone-base (cons o setters)))

(define-class <system-state> ()
  (state-list #:getter .state-list #:init-form (list) #:init-keyword #:state-list))

(define-method (clone (o <system-state>) . setters)
  (apply clone-base (cons o setters)))

(define-method (clone (o <program-counter>) . setters)
  (apply clone-base (cons o setters)))

(define-method (name (o <runtime:instance>))
  (cond ((and (is-a? (%sut) <runtime:port>)
              (> (length (%instances)) 1))
         (.name (.ast o)))
        ((null? (runtime:instance->path o)) "sut")
        (else (string-join (runtime:instance->path o) "."))))

(define-method (name (o <ast>))
  ((compose class-name class-of) o))

(define-method (name (o <boolean>))
  (name (%sut)))

(define-method (->sexp (o <top>))
  o)

(define-method (->sexp (o <enum-literal>))
  (string-append (last (.ids (.type.name o))) ":" (.field o)))

(define-method (->sexp (o <literal>))
  ((compose ->sexp .value) o))

(define-method (rtc? (pc <program-counter>))
  (or (.status pc)
      (not (.statement pc))))

(define-method (rtc? (trace <list>))
  (let ((pc (car trace)))
    (or (.status pc)
        (not (.statement pc)))))

(define (external-q->string external-q)
  (define q->string
    (match-lambda
      ((port q ...)
       (format #f "~s ~s" (name port) (map trigger->string q)))))
  (format #f "~a" (map q->string external-q)))

(define-method (write (o <program-counter>) port)
  (display "#<" port)
  (display (ast-name o) port)
  (when (rtc? o)
    (display " *rtc*: " port)
    (display ((compose ast:dotted-name .type .ast %sut)) port)
    (display " " port)
    (display ((compose class-name class-of .type .ast %sut)) port))
  (when (.status o)
    (display " status: " port)
    (display (.status o) port))
  (when (.instance o)
    (display " " port)
    (display ((compose name .instance) o) port))
  (when (.statement o)
    (display " " port)
    (display ((compose name .statement) o) port))
  (when (pair? (.async o))
    (display " async: " port)
    (display (map (compose runtime:dotted-name cadr) (.async o)) port))
  (when (pair? (.released o)) (display " *released*" port))
  (when (pair? (.collateral o)) (display " *collateral*" port))
  (when (pair? (.blocked o)) (display " *blocked*" port))
  (and=> (.return o) (cut format port " return: ~a" <>))
  (when (pair? (.external-q o))
    (format port " ext-q: ~a" (external-q->string (.external-q o))))
  (display " " port)
  (display (.state o) port)
  (display " trail: " port)
  (display (.trail o) port)
  (display ">" port))

(define-method (trigger->string o)
  (if (.port.name o) (format #f "~a.~a" (.port.name o) (.event.name o))
      (format #f "~a" (.event.name o))))

(define-method (write (o <state>) port)
  (display "#<" port)
  (display (ast-name o) port)
  (display " " port)
  (display ((compose name .instance) o) port)
  (display " " port)
  (when (pair? (.variables o)) (display (map (match-lambda ((x . y) (cons x (->sexp y)))) (.variables o)) port))
  (when (pair? (.q o)) (format port " q: ~s" (map trigger->string (.q o))))
  (and=> (.reply o) (cut format port " reply: ~a" <>))
  (display ">" port))

(define-method (write (o <system-state>) port)
  (display "#<" port)
  (display (ast-name o) port)
  (display " " port)
  (let* ((states (.state-list o))
         (states (filter (compose not (cute equal? <> '("client"))
                                  runtime:instance->path .instance)
                         states)))
    (display (filter (disjoin (compose pair? .variables)
                              (compose pair? .q))
                     states)
             port))
  (display ">" port))
