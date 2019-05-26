;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag step json)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (peg)
  #:use-module (peg cache)
  #:use-module (peg codegen)
  #:use-module (peg string-peg)

  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag serialize)
  #:use-module (gaiag runtime)
  #:use-module (gaiag step)
  #:use-module (gaiag step goops)
  #:export (
            <step:alist>
            <step:instance+state-alist>
            <step:state-alist>
            <step:node-alist>
            <step:list>
            <step:transition-list>
            <step:event-list>
            <step:instance+state>
            <step:transition>
            <step:event>
            <step:lts-link>
            <step:lts>
            step:.alist
            step:.from
            step:.from-location
            step:.instance+state
            step:.kind
            step:.link
            step:.list
            step:.name
            step:.node
            step:.state
            step:.to
            step:.to-location
            step:.event
            step:.type
            step:goopify
            step:deserialize
            step:serialize
            ))

(define (for-each-sep func sep lst)
  (let loop ((lst lst))
    (unless (null? lst)
      (func (car lst))
      (when (pair? (cdr lst))
        (sep) (loop (cdr lst))))))

(define-class <step:alist> ()
  (alist #:getter step:.alist #:init-form '() #:init-keyword #:alist))

(define-class <step:instance+state-alist> (<step:alist>))
(define-class <step:state-alist> (<step:alist>))
(define-class <step:node-alist> (<step:alist>))

(define-class <step:list> ()
  (list #:getter step:.list #:init-form '() #:init-keyword #:list))

(define-class <step:transition-list> (<step:list>))
(define-class <step:event-list> (<step:list>))

(define-class <step:instance+state> ()
  (type #:getter step:.type #:init-form #f #:init-keyword #:type)
  (kind #:getter step:.kind #:init-form #f #:init-keyword #:kind)
  (state #:getter step:.state #:init-form (make <step:state-alist>) #:init-keyword #:state))
(define-method (step:serialize (o <step:instance+state>) port)
  (display "{" port)
  (display "\"type\":\"" port) (step:serialize (step:.type o) port) (display "\"," port)
  (display "\"kind\":\"" port) (step:serialize (step:.kind o) port) (display "\"," port)
  (display "\"state\":" port) (step:serialize (step:.state o) port)
  (display "}" port))
;; state: (list variable ...)
;; variable: (name . value)

(define-class <step:transition> ()
  (instance+state #:getter step:.instance+state #:init-form #f #:init-keyword #:instance+state)
  (event #:getter step:.event #:init-form (make <step:list>) #:init-keyword #:event))
(define-method (step:serialize (o <step:transition>) port)
  (display "{" port)
  (display "\"instance+state\":" port) (step:serialize (step:.instance+state o) port) (display "," port)
  (display "\"event\":" port) (step:serialize (step:.event o) port)
  (display "}" port))
;; step:event: (list step:event ...)

(define-class <step:event> ()
  (from #:getter step:.from #:init-form #f #:init-keyword #:from)
  (from-location #:getter step:.from-location #:init-form #f #:init-keyword #:from-location)
  (to #:getter step:.to #:init-form #f #:init-keyword #:to)
  (to-location #:getter step:.to-location #:init-form #f #:init-keyword #:to-location)
  (name #:getter step:.name #:init-form #f #:init-keyword #:name))
(define-method (step:serialize (o <step:event>) port)
  (display "{" port)
  (when (step:.from-location o) (display "\"from_location\":" port) (step:serialize (step:.from-location o) port) (display "," port))
  (display "\"from\":" port) (step:serialize (step:.from o) port) (display "," port)
  (when (step:.to-location o) (display "\"to_location\":" port) (step:serialize (step:.to-location o) port) (display "," port))
  (display "\"to\":" port) (step:serialize (step:.to o) port) (display "," port)
  (display "\"name\":" port) (step:serialize (step:.name o) port)
  (display "}" port))
;; trace: (list transition ...)

;; lts-node: (id . instance+state)

(define-class <step:lts-link> ()
  (from #:getter step:.from #:init-form #f #:init-keyword #:from)
  (to #:getter step:.to #:init-form #f #:init-keyword #:to)
  (event #:getter step:.event #:init-form #f #:init-keyword #:event))
(define-method (step:serialize (o <step:lts-link>) port)
  (display "{" port)
  (display "\"from\":" port) (step:serialize (step:.from o) port) (display "," port)
  (display "\"to\":" port) (step:serialize (step:.to o) port) (display "," port)
  (display "\"event\":" port) (step:serialize (step:.event o) port)
  (display "}" port))
;; lts-node: (list lts-node ...)
;; lts-link: (list lts-link ...)

(define-class <step:lts> ()
  (node #:getter step:.node #:init-form (make <step:node-alist>) #:init-keyword #:node)
  (link #:getter step:.link #:init-form (make <step:list>) #:init-keyword #:link))
(define-method (step:serialize (o <step:lts>) port)
  (display "{" port)
  (display "\"node\":" port) (step:serialize (step:.node o) port) (display "," port)
  (display "\"link\":" port) (step:serialize (step:.link o) port)
  (display "}" port))

(define-method (step:serialize (o <step:alist>) port)
  (display "{" port)
  (for-each-sep (lambda (a)
                  (display "\"" port)
                  (step:serialize (car a) port)
                  (display "\"" port)
                  ;; (catch #t (lambda ()
                  ;;             (step:serialize (car a) port)
                  ;;             (display ":" port)
                  ;;             (step:serialize (cdr a) port))
                  ;;   (lambda (key . args)
                  ;;     (format #t "FOO: #~a => ~a#\n" a (is-a? a <step:alist>))))
                  (display ":" port)
                  (step:serialize (cdr a) port))
                (cut display "," port)
                (step:.alist o))
  (display "}" port))

(define-method (step:serialize (o <step:list>) port)
  (display "[" port)
  (for-each-sep (cut step:serialize <> port)
                (cut display "," port)
                (step:.list o))
  (display "]" port))

(define-method (step:serialize (o <top>) port)
  (write o port))

(define (step:deserialize ascii)
  (define-peg-string-patterns
    "top <- sp (event-list / instance-state-alist / state / transition-list / lts / trace) sp

  trace <-- LBRACK sp (transition sp (!RBRACK COMMA sp / !COMMA &RBRACK))* sp RBRACK

  lts <-- LBRACE sp NODE sp COLON sp node-alist COMMA sp LINK sp COLON sp link-list sp RBRACE
  node-alist <-- LBRACE sp (number sp COLON sp instance-state-alist sp (!RBRACE COMMA sp / !COMMA &RBRACE))* RBRACE
  link-list <-- LBRACK sp (link sp (!RBRACK COMMA sp / !COMMA &RBRACK))* sp RBRACK
  link <-- LBRACE sp FROM sp COLON sp number COMMA TO sp COLON sp number sp COMMA sp EVENT sp COLON sp event-list sp RBRACE
  instance-state <-- LBRACE sp TYPE sp COLON sp type sp COMMA sp KIND sp COLON sp kind sp (COMMA sp STATE sp COLON sp state sp)? RBRACE
  instance-state-alist <-- LBRACE sp (name sp COLON sp instance-state sp (!RBRACE COMMA sp / !COMMA &RBRACE))* RBRACE
  state <-- LBRACE sp (name sp COLON sp value sp (!RBRACE COMMA sp / !COMMA &RBRACE))* RBRACE
  event-list <-- LBRACK sp ( event sp (!RBRACK COMMA sp / !COMMA &RBRACK))* RBRACK
  transition <-- LBRACE sp INSTANCE-STATE sp COLON sp instance-state-alist sp (COMMA sp EVENT sp COLON sp event-list sp)? RBRACE
  transition-list <-- LBRACK sp (transition (!RBRACK COMMA sp / !COMMA &RBRACK))* RBRACK
  event <-- LBRACE sp FROM sp COLON sp from sp COMMA sp TO sp COLON sp  to sp COMMA sp NAME sp COLON sp name sp RBRACE

  from <-- dotted-name
  to <-- dotted-name
  dotted-name <- q identifier (DOT identifier)* q
  name <--  q identifier (DOT identifier)* q
  kind <-- q ('provides' / 'requires' / 'component' / 'system' / 'foreign') q
  type <-- dotted-name
  value <-- number / dotted-name
  number <-- [0-9]+ / q [0-9]+ q
  identifier <- [<a-zA-Z_][>a-zA-Z_0-9]*
  sp < [ \n\t]*
  LBRACK < '['
  RBRACK < ']'
  LBRACE < '{'
  RBRACE < '}'
  COMMA < ','
  COLON < ':'
  DOT <- '.'
  FROM < q 'from' q
  TO < q 'to' q
  NAME < q 'name' q
  TYPE < q 'type' q
  KIND < q 'kind' q
  STATE < q 'state' q
  NODE < q 'node' q
  LINK < q 'link' q
  INSTANCE-STATE < q 'instance+state' q
  EVENT < q 'event' q
  q < [\"]?
")
  (parameterize ((%peg:debug? #f)) (peg:tree (match-pattern top ascii))))

(define (step:goopify o)
  (match o
    (('trace transition ...) (make <step:list> #:list (map step:goopify transition)))

    (('lts node link) (make <step:lts> #:node (step:goopify node) #:link (step:goopify link)))

    ('node-alist (make <step:node-alist>))
    (('node-alist ('number n) ('instance-state body ...)) (make <step:node-alist> #:alist (list (cons (step:goopify (list 'number n)) (step:goopify (cons 'instance-state body))))))
    (('node-alist nodes ...) (make <step:node-alist> #:alist (map step:goopify nodes)))
    ((('number n) ('instance-state body ...)) (cons (step:goopify (list 'number n)) (step:goopify (cons 'instance-state body))))

    ('link-list (make <step:list>))
    (('link-list link) (make <step:list> #:list (list (step:goopify link))))
    (('link-list links ...) (make <step:list> #:list (map step:goopify links)))
    (('link from to event-list) (make <step:lts-link> #:from (step:goopify from) #:to (step:goopify to) #:event (step:goopify event-list)))

    (('event from to name) (make <step:event> #:from (step:goopify from) #:to (step:goopify to) #:name (step:goopify name)))
    (('from name) (step:goopify name))
    (('to name) (step:goopify name))
    (('name n) (step:goopify n))

    ('event-list (make <step:event-list>))
    (('event-list event) (make <step:event-list> #:list (list (step:goopify event))))
    (('event-list events ...) (make <step:event-list> #:list (map step:goopify events)))

    ('state (make <step:state-alist>))
    (('state ('name n) ('value v)) (make <step:state-alist> #:alist (list (cons (step:goopify n) (step:goopify v)))))
    (('state states ...) (make <step:state-alist> #:alist (map step:goopify states)))
    ((('name n) ('value v)) (cons (step:goopify n) (step:goopify v)))

    (('instance-state ('type type) ('kind kind) state)
     (make <step:instance+state> #:type (step:goopify type) #:kind (step:goopify kind) #:state (step:goopify state)))

    ('instance-state-alist (make <step:instance+state-alist>))
    (('instance-state-alist ('name name) ('instance-state body ...)) (make <step:instance+state-alist> #:alist (list (cons (step:goopify name) (step:goopify (cons 'instance+state body))))))
    (('instance-state-alist instance+states ...) (make <step:instance+state-alist> #:alist (map step:goopify instance+states)))
    ((('name name) ('instance-state body ...)) (cons (step:goopify name) (step:goopify (cons 'instance-state body))))

    (('transition instance-state-alist event)
     (make <step:transition> #:instance+state (step:goopify instance-state-alist) #:event (step:goopify event)))

    ('transition-list (make <step:transition-list>))
    (('transition-list transition) (make <step:transition-list> #:list (list (step:goopify transition))))
    (('transition-list transitions ...) (make <step:transition-list> #:list (map step:goopify transitions)))

    ((? string?) (string->symbol o))
    (('number n) (string->number n))))

(define (transition-test . args)
  (let* ((pstate (make <step:state-alist> #:alist '((a . true) (b . 1))))
         (p (make <step:instance+state> #:type 'ihello #:kind 'provides #:state pstate))
         (r (make <step:instance+state> #:type 'ihello #:kind 'provides #:state (make <step:state-alist> #:alist '((a . true) (b . 1)))))
         (c (make <step:instance+state> #:type 'hello #:kind 'component #:state (make <step:state-alist> #:alist '((ca . true) (cb . 10)))))
         (s (make <step:instance+state> #:type 'hello_system #:kind 'system))
         (instance+state-alist (make <step:instance+state-alist> #:alist (list (cons 'p p) (cons 's s) (cons 'r r))))
         (event (make <step:event-list>))
         (transition (make <step:transition> #:instance+state instance+state-alist))
         (foo (begin (display 'INPUT) (newline)
                     (display transition) (newline)))
         (json (with-output-to-string (cut display transition)))
         (foo (begin (display 'PARSED) (newline)
                     (display (step:deserialize json))(newline)))
         (foo (begin (display 'GOOPIFIED) (newline)
                     (display (step:goopify (step:deserialize json)))(newline))))
    #t))


(define (lts-test . args)
  (let* ((pstate (make <step:state-alist> #:alist '((a . true) (b . 1))))
         (p (make <step:instance+state> #:type 'ihello #:kind 'provides #:state pstate))
         (r (make <step:instance+state> #:type 'ihello #:kind 'provides #:state (make <step:state-alist> #:alist '((a . true) (b . 1)))))
         (c (make <step:instance+state> #:type 'hello #:kind 'component #:state (make <step:state-alist> #:alist '((ca . true) (cb . 10)))))
         (s (make <step:instance+state> #:type 'hello_system #:kind 'system))
         (instance+state-alist (make <step:instance+state-alist> #:alist (list (cons 'p p) (cons 's s) (cons 'r r))))
         (node (make <step:node-alist> #:alist (list (cons 0 instance+state-alist) (cons 1 instance+state-alist))))
         (event (make <step:event> #:from 'a.b #:to 'c.d #:name 'e))
         (link (make <step:list> #:list (list (make <step:lts-link> #:from 0 #:to 0 #:event (make <step:event-list> #:list (list event))))))
         (lts (make <step:lts> #:node node #:link link))
         (json (with-output-to-string (cut display lts)))
         (foo (begin (display 'LTS) (newline)
                     (display json) (newline)))
         (parsed (step:deserialize json)))
    (display 'PARSED) (newline)
    (display parsed) (newline)
    (display 'GOOPIFIED) (newline)
    (display (step:goopify parsed)) (newline)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; JSON
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-method (json:create-initial-node (o <step:transition-list>))
  (define (external-event s n)
    (let ((lst (string-split (symbol->string s) #\.)))
      (and (pair? lst)
           (equal? "<external>" (car lst))
           (string->symbol (string-join (append (cdr lst) (list (symbol->string n))) ".")))))

  (let* ((transitions (step:.list o))
         (transition? (and (pair? transitions) (last transitions)))
         (initial-state (if transition? (json:get-initial-state (step:.instance+state transition?))
                            (get-initial-state '())))
         (node (make-initial-node (%instances) initial-state))
         (node (record-state node (%sut)))
         (trail (if (not transition?) '()
                    (filter-map (lambda (event)
                                  (or (external-event (step:.from event) (step:.name event))
                                      (external-event (step:.to event) (step:.name event))))
                                (step:.list (step:.event transition?))))))
    (clone node #:trail trail)))

(define-method (symbol->value v) ;; FIXME: see sexp->value in step
  (match v
    ('true (make <literal> #:value 'true))
    ('false (make <literal> #:value 'false))
    ((? number?) (make <literal> #:value v))
    (_ (let* ((enum (reverse (symbol-split v #\.)))
              (scope (reverse (cddr enum)))
              (type.name (second enum))
              (field (first enum)))
         (make <enum-literal> #:type.name (make <scope.name> #:scope scope #:name type.name) #:field field))) ;; FIXME: what about resolving
    ))

(define-method (json:get-initial-state (o <step:instance+state-alist>))
  (let ((initial-state (fold create-initial-state '() (%instances))))
    (map (lambda (inst)
           (let* ((state (assoc-ref (step:.alist o) (symbol-join (runtime:instance->path inst) '.)))
                  (initial-inst-state (assoc-ref initial-state inst))
                  (state (if state (map (lambda (s)
                                          (cons (car s)
                                                (clone (symbol->value (cdr s))
                                                       #:parent (.parent (assoc-ref initial-inst-state (car s))))))
                                        (step:.alist (step:.state state)))
                             initial-inst-state)))
             (cons inst state)))
         (%instances))))

(define (group pred elements)
  "Returns a list of lists from ELEMENTS split by PRED"
  (if (null? elements) '()
      (let ((groups (let loop ((elements (cdr elements)) (groups '()) (group (list (car elements))))
                      (if (null? elements) (cons group groups)
                          (let ((element (car elements)))
                            (if (pred element)
                                (loop (cdr elements) (cons group groups) (list element))
                                (loop (cdr elements) groups (cons element group))))))))
        (map reverse (reverse groups)))))

(define (runtime:type-name o)
  ((compose (cut symbol-join <> ".") ast:full-name .type .instance) o))

(define (state->pair state)
  (cons (car state) (format #f "~a" (ast:value (cdr state)))))

(define (all-relevant-steps-for-now)
  (conjoin (negate eligible-step?)
           (disjoin state-step? (trigger-step? #f))))

(define* (json:print-trace nodes)
  (if (= 1 (length nodes))
      (let* ((instances (filter (disjoin (negate (is? <runtime:port>)) runtime:boundary-port?) (%instances)))
             (node (car nodes))
             (steps (.steps node))
             (steps (filter (all-relevant-steps-for-now) steps))
             (blocks (group state-step? steps))
             (step->state (lambda (step)
                            (let ((instance+state (filter (compose (disjoin (negate (is? <runtime:port>)) runtime:boundary-port?) car) (cdr step))))
                              (make <step:instance+state-alist> #:alist
                                    (map (lambda (i) (cons (symbol-join (runtime:instance->path i) ".")
                                                           (make <step:instance+state>
                                                             #:type (runtime:type-name i)
                                                             #:kind (runtime:kind i)
                                                             #:state (make <step:state-alist> #:alist (map state->pair (.vars (assoc-ref instance+state i)))))))
                                         instances))))))

        ((@@ (gaiag step-serialize) step:serialize)
         (make <step:list>
           #:list (map (lambda (block)
                         (make <step:transition>
                           #:instance+state (step->state (car block))
                           #:event (make <step:event-list> #:list (steps->events (cdr block)))))
                       blocks))
         (current-output-port)))
      (throw 'too-many-traces)))

(define (steps->events steps)
  (let* ((events
          (fold
           (lambda (step result)
             (if (or (null? result) (is-a? (car result) <step:event>))
                 (cons step result)
                 (let* ((from-strings (string-split (side->string (car result)) #\.))
                        (from (string-join (drop-right from-strings (if (equal? "<q>" (last from-strings)) 0 1)) "."))
                        (from-location (and (command-line:get 'locations #f) (step->location (cdr (car result)))))
                        (to-strings (string-split (side->string step) #\.))
                        (to (string-join (drop-right to-strings (if (equal? "<q>" (last to-strings)) 0 1)) "."))
                        (to-location (and (command-line:get 'locations #f) (step->location (cdr step))))
                        (name (if (equal? (last from-strings) "<q>") (last to-strings) (last from-strings)))
                        (result (cdr result)))
                   (cons (make <step:event>
                           #:from-location from-location
                           #:from from
                           #:to-location to-location
                           #:to to
                           #:name name) result)))) '() steps))
         (events (if (or (null? events) (is-a? (car events) <step:event>)) events (cdr events))))
    (reverse events)))

(define (json->trail o)
  (let ((str (string-trim-both o)))
    (if (string-null? str) (make <step:list>) (step:goopify (step:deserialize str)))))

(export
 all-relevant-steps-for-now
 steps->events
 json:create-initial-node
 json:get-initial-state
 json:print-trace
 json->trail)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
