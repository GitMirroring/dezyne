;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2016, 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2016, 2017, 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag norm-event)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 match)
  #:use-module (ice-9 curried-definitions)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag location)
  #:use-module (gaiag misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag ast)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag norm)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)

  #:export (
           ast->
           code-norm-event
           norm-event
           table-norm-event
           trigger->incomplete
           ))

(define-syntax *match*
  (syntax-rules ... ()
    ((_ obj (pat exp ...) ...)
     (match obj (pat (begin (map display (list "match " 'pat ":")) (newline)
                            (measure-perf- '(exp ...) (lambda () exp ...)))) ...))))

(define (measure-perf- label thunk)
  (let ((t1 (get-internal-run-time))
        (result (thunk))
        (t2 (get-internal-run-time)))
    (stderr "~a: ~a\n" (- t2 t1) label)
    result))

(define-syntax measure-perf
  (syntax-rules ()
    ((_ label exp)
     (let ((t1 (get-internal-run-time))
           (result ((lambda () exp)))
           (t2 (get-internal-run-time)))
       (stderr "~a: ~a\n" (- t2 t1) label)
       result))))

(define-syntax *let*
  (syntax-rules ()
    ((_ ((var val) ...) exp exp* ...)
     (let* ((var (measure-perf 'var val)) ...)
       (measure-perf '*let* exp exp* ...)))))

(define g-time (get-internal-run-time))
(define* ((perf label) o)
  (let* ((time (get-internal-run-time))
;;         (foo (stderr "  TIME ~a: ~a ms\n" label (quotient (- time g-time) 1000000)))
         )
    (set! g-time time)
    o))

;; norm-event used for <root> and other <ast>
(define-method (norm-event (o <ast>))
  (((if (is-a? o <root>) compose compose)
    (perf 'remove-skip)
    remove-skip
    (perf 'aggregate-guard-s)
    aggregate-guard-s
    (perf 'group-ons)
    (group-ons)
    (perf 'aggregate-on-norm:on-statement-equal?)
    (aggregate-on norm:on-statement-equal?)
    (perf 'expand-on-norm:on-equal?)
    (expand-on norm:on-equal?)
    (perf 'aggregate-guard-s)
    aggregate-guard-s
    (perf 'flatten-compound)
    flatten-compound
    (perf 'combine-ons)
    combine-ons
    (perf 'passdown-guard)
    passdown-guard
    (perf 'passdown-blocking)
    (passdown-blocking)
    (perf 'remove-otherwise)
    (remove-otherwise)
    (perf 'add-skip)
    add-skip
    (perf 'identity)
    identity
    )
   o))

(define (table-norm-event o)
  ((compose
    remove-skip
    aggregate-guard-s
    (aggregate-on)
    flatten-compound
    (expand-on norm:on-equal?)
    aggregate-guard-s
    flatten-compound
    combine-ons
    passdown-guard
    (passdown-blocking)
    (remove-otherwise)
    add-skip
    )
   o))

(define-method (code-norm-event (o <root>))
  ((compose
    (perf 'add-reply-port)
    add-reply-port
    (perf 'add-illegals)
    (add-illegals)
    (perf 'remove-skip)
    remove-skip
    (perf 'on-compound)
    on-compound
    (perf 'flatten-compound)
    flatten-compound
    (perf 'combine-guards)
    combine-guards
    (perf 'aggregate-on-norm:triggers-equal?)
    (aggregate-on norm:triggers-equal?)
    (perf 'binding-into-blocking)
    (binding-into-blocking)
    (perf 'rewrite-formals)
    (rewrite-formals)
    (perf 'flatten-compound)
    flatten-compound
    (perf 'passdown-blocking)
    (passdown-blocking)
    (perf 'flatten-compound)
    flatten-compound
    (perf 'passdown-guard)
    passdown-guard
    (perf 'flatten-compound)
    flatten-compound
    (perf 'expand-on-norm:on-equal?)
    (expand-on norm:on-equal?)
    (perf 'aggregate-guard-s)
    aggregate-guard-s
    (perf 'flatten-compound)
    flatten-compound
    (perf 'combine-ons)
    combine-ons
    (perf 'passdown-blocking)
    (passdown-blocking)
    (perf 'passdown-guard)
    passdown-guard
    (perf 'remove-otherwise)
    (remove-otherwise)
    (perf 'add-skip)
    (interface-prepend-true-guard)
    add-skip
    (perf 'START))
   o)
  )

(define* ((interface-prepend-true-guard #:optional guard-seen?) o)
  (match o
    (($ <component>) o)
    (($ <guard>) o)
    (($ <on>) (if guard-seen? o
                  (rsp o (make <guard> #:expression (make <literal> #:value 'true) #:statement o))))
    ((? (is? <ast>)) (tree-map (interface-prepend-true-guard guard-seen?) o))
    (_ o)))

(define* ((group-ons #:optional (group? norm:triggers-equal?)) o)
  "stable place ons with same group? next to eachother"
  (match o
    ((and ($ <compound>) (= .elements (($ <on>) ..1)))
     (clone o #:elements
           (let loop ((ons (.elements o)))
             (if (null? ons)
                 '()
                 (receive (grouped-ons remainder)
                     (partition (lambda (x) (group? #f (car ons) x)) ons)
                   (append grouped-ons (loop remainder)))))))
     (($ <functions>) o)
     (($ <skip>) o)
     ((? (is? <ast>)) (tree-map (group-ons group?) o))
     (_ o)))

(define (aggregate-guard-s o)
  "Aggregate guards with matching statement into one guard-statement."
  ;; find all guands with matching statement
  ;; push all guards into first guard, discard the rest
  (define (or-guard-expressions shared-guards)
    (reduce (lambda (x y)
              (make <or> #:left x #:right y))
            '()
            (delete-duplicates (map (compose .expression) shared-guards) om:equal?)))
  (match o
    ((and ($ <compound>) (= .elements (($ <guard> ..1))))
     (clone o #:elements
            (let loop ((guards (.elements o)))
              (if (null? guards)
                  '()
                  (receive (shared-guards remainder)
                      (partition (lambda (x) (norm:guard-same-statement? #f (car guards) x)) guards)
                    (if (=1 (length shared-guards))
                        (append shared-guards (loop remainder))
                        (let* ((expression (or-guard-expressions shared-guards))
                               (statement (.statement (car guards)))
                               (aggregated-guard (clone (car guards)
                                                        #:expression expression
                                                        #:statement statement)))
                          (cons aggregated-guard (loop remainder)))))))))
    ((? (is? <component>))
     (clone o #:behaviour (aggregate-guard-s (.behaviour o))))
    ((? (is? <interface>))
     (clone o #:behaviour (aggregate-guard-s (.behaviour o))))
    ((? (is? <component-model>)) o)
    ((? om:imperative?) o)
    (($ <functions>) o)
    (($ <skip>) o)
    ((? (is? <ast>)) (tree-map aggregate-guard-s o))
    (_ o)))

(define (norm:guard-same-statement? model lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
       (om:equal? (.statement lhs) (.statement rhs))))

(define (combine-ons o)
  (match o
    (($ <on>) ((passdown-on- o) (.statement o)))
    (($ <skip>) o)
    (($ <functions>) o)
    ((? (is? <component>))
     (clone o #:behaviour (combine-ons (.behaviour o))))
    ((? (is? <interface>))
     (clone o #:behaviour (combine-ons (.behaviour o))))
    ((? (is? <component-model>)) o)
    ((? (is? <ast>)) (tree-map combine-ons o))
    (_ o)))

(define ((passdown-on- on) o)
  (match o
    ((and ($ <compound>) (? om:declarative?))
     (clone o #:elements (map (passdown-on- on) (.elements o))))
    (_
     (clone on #:statement o))))

(define (passdown-guard o)
  (match o
    ((and ($ <compound>) (? om:imperative?)) o)
    (($ <guard>) ((passdown-guard- o) (.statement o)))
    (($ <skip>) o)
    ((? (is? <component>))
     (clone o #:behaviour (passdown-guard (.behaviour o))))
    ((? (is? <interface>))
     (clone o #:behaviour (passdown-guard (.behaviour o))))
    ((? (is? <component-model>)) o)
    (($ <functions>) o)
    ((? (is? <ast>)) (tree-map passdown-guard o))
    (_ o)))

(define* ((passdown-guard- guard #:optional (seen-on? #f)) o)
  (define (make-guard o)
    (clone guard #:statement o))
  (match o
    (($ <on>)
     (clone o #:statement ((passdown-guard- guard #t) (.statement o))))
    ((and ($ <compound>) (= .elements (($ <guard>) ..1)) (? (const seen-on?)))
     (make-guard o))
    ((and ($ <compound>) (? om:declarative?))
     (clone o #:elements (map (passdown-guard- guard seen-on?) (.elements o))))
    (($ <compound>) (make-guard o))
    (($ <guard>)
     (let ((o ((passdown-guard- o seen-on?) (.statement o))))
       (match o
         (($ <on>)
          (clone o #:statement (make-guard (.statement o))))
         ((and ($ <compound>) (? om:declarative?))
          (clone o #:elements (map (passdown-guard- guard seen-on?) (.elements o))))
         (_ (make-guard o)))))
    (_ (make-guard o))))

(define-method (trigger->incomplete (o <trigger>))
  (make <on>
    #:triggers (make <triggers> #:elements (list o))
    #:statement (make <illegal> #:incomplete #t)))

(define* (add-reply-port o #:optional (port #f) (block? #f)) ;; requires (= 1 (length (.triggers on)))
  ;(stderr "add-reply-report o = ~a; port = ~a: model = ~a\n" o port model)
  (match o
    (($ <reply>) (let ((port? (.port o))) (if (and port? (not (symbol? port?))) o (clone o #:port (.name port)))))
    (($ <blocking>)
     (if block?
         (make <blocking-compound>
           #:port port
           #:elements (let ((s (.statement o)))
                        (if (is-a? s <compound>) (map (cut add-reply-port <> port block?) (.elements s))
                            (list (add-reply-port s port block?)))))
         (add-reply-port (.statement o) port block?)))
    (($ <on>)
     (clone o #:statement (add-reply-port (.statement o)
                                          (if port port ((compose .port car .elements .triggers) o))
                                          (eq? 'provides ((compose .direction .port car .elements .triggers) o)))))
    (($ <guard>) (clone o #:statement (add-reply-port (.statement o) port block?)))
    (($ <compound>) (clone o #:elements (map (cut add-reply-port <> port block?) (.elements o))))
    (($ <behaviour>) (clone o #:statement (add-reply-port (.statement o) port block?)))
    (($ <component>) (clone o #:behaviour (add-reply-port (.behaviour o) (if (= 1 (length (filter ast:provides? (om:ports o)))) (om:port o) #f) block?)))
    (($ <system>) o)
    (($ <foreign>) o)
    (($ <interface>) o)
    ((? (is? <ast>)) (tree-map (cut add-reply-port <> port block?) o))
    (_ o)))

(define* ((add-illegals #:optional model) o)
  (match o
    (($ <component>)
     (clone o #:behaviour ((add-illegals o) (.behaviour o))))
    (($ <behaviour>)
     (let* ((triggers (ast:in-triggers model))
            (ons (.elements (.statement o)))
            (on-triggers (append-map (compose .elements .triggers) ons))
            (triggers (filter
                       (lambda (trigger)
                         (not (find (lambda (on-trigger)
                                      (and (eq? (.port.name trigger) (.port.name on-trigger))
                                           (eq? (.event.name trigger) (.event.name on-trigger))))
                                    on-triggers)))
                       triggers)))
       (receive (modeling ons)
           (partition (compose (is? <modeling-event>) .event car ast:trigger*) ons)
         (let ((ons (append modeling (map (add-illegals model) ons) (map trigger->incomplete triggers))))
           (if (null? ons) o
               (clone o #:statement (clone (.statement o) #:elements ons)))))))
    ;; NOTE: not needed: on-compound asserts each on has a compound
    ;; (($ <guard>) (=> failure)
    ;;  (make <compound>
    ;;    #:elements (list o
    ;;                     (make <guard> #:expression (make <otherwise>) #:statement (make <illegal>)))))
    ((and ($ <compound>) (? om:declarative?)) (=> failure)
     (if (and (pair? (.elements o)) (is-a? (car (.elements o)) <guard>) (null? (filter (is? <otherwise>) (.elements o))))
         (clone o #:elements (append (.elements o) (list (make <guard> #:expression (make <otherwise>) #:statement (make <illegal> #:incomplete #t)))))
         (failure)))
    (($ <interface>)
     (clone o #:behaviour ((add-illegals o) (.behaviour o))))
    (($ <system>) o)
    (($ <foreign>) o)
    ((? (is? <ast>)) (tree-map (add-illegals model) o))
    (_ o)))

(define* ((rewrite-formals #:optional model (locals '())) o)

  (define (member? identifier) (resolve:variable model identifier))
  (define (pair-eq? p) (eq? (car p) (cdr p)))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (extern? identifier) (and=> (var? identifier) (cut as <> <extern>)))
  (define (extern-type? type) (as type <extern>))

  (define ((rename mapping) o)
    ;;(stderr "rename o=~a\n" o)
    (match o
      ((and ($ <trigger>) (? (compose null? ast:formal*))) o)
      (($ <trigger>)
       (clone o #:formals (clone (.formals o) #:elements (map (rename mapping) ((compose .elements .formals) o)))))
      ((? symbol?) (or (assoc-ref mapping o) o))
      ((? (is? <ast>)) (tree-map (rename mapping) o))
      (_ o)))

  (define (name->on-formal name)
    (make <formal> #:name name))

  ;;(stderr "rewrite o=~a\n" o)
  (match o
    ((and ($ <on>) (? (compose (cut equal? 1 <>) length ast:trigger*)) (? (compose null? ast:formal* car ast:trigger*)))
     (let* ((trigger ((compose car .elements .triggers) o))
            (formals ((compose .elements .formals .signature) (.event trigger))))
       (if (null? formals) o
           (clone o #:triggers (clone (.triggers o) #:elements (list (clone trigger #:formals (clone (.formals trigger) #:elements formals))))))))
    ((and ($ <on>) (? (compose (cut equal? 1 <>) length ast:trigger*)))
     (let* ((trigger ((compose car .elements .triggers) o))
            (members (map .name (om:variables model)))
            (formals (map .name ((compose .elements .formals .signature) (.event trigger))))
            (locals (map .name ((om:collect <variable>) o)))
            (occupied members)
            (fresh (letrec ((fresh (lambda (occupied name)
                                     (if (member name occupied)
                                         (fresh occupied (symbol-append name 'x))
                                         name))))
                     fresh)) ;; occupied name -> namex
            (refresh (lambda (occupied names)
                       (fold-right (lambda (name o)
                                     (cons (fresh o name) o))
                                   occupied names))) ;; occupied names -> (append namesx occupied)

            (fresh-formals (list-head (refresh occupied formals) (length formals)))
            (mapping (filter (negate pair-eq?) (map cons (map .name ((compose .elements .formals) trigger)) fresh-formals)))

            (occupied (append (map cdr mapping) members))

            (mapping (append (map cons locals (list-head (refresh occupied locals) (length locals))) mapping)))

       (if (null? mapping) o
           (clone o
                  #:triggers (clone (.triggers o) #:elements (list ((rename mapping) trigger)))
                  #:statement ((rename mapping) (.statement o))))))

    (($ <component>)
     (clone o #:behaviour ((rewrite-formals o) (.behaviour o))))

    (($ <behaviour>)
     (clone o #:statement ((rewrite-formals model '()) (.statement o))))

    (($ <interface>) o)
    (($ <system>) o)
    (($ <foreign>) o)
    ((? (is? <ast>)) (tree-map (rewrite-formals model locals) o))
    (_ o)))

(define* ((binding-into-blocking #:optional (locals '())) o)

  (define (formal-binding->formal o)
    (match o
      (($ <formal-binding>) (make <formal> #:name (.name o) #:type (.type o) #:direction (.direction o)))
      (_ o)))

  (define ((passdown-formal-bindings formal-bindings) o)
    (match o
    ((and ($ <compound>) (? om:declarative?))
     (clone o #:elements (map (passdown-formal-bindings formal-bindings) (.elements o))))
    ((? om:declarative?) (clone o #:statement ((passdown-formal-bindings formal-bindings) (.statement o))))
    (($ <compound>) (clone o #:elements (cons formal-bindings (.elements o))))
    (_ (make <compound> #:elements (cons formal-bindings (list o))))))

  (match o
    (($ <on>)
     (let* ((trigger ((compose car .elements .triggers) o))
            (on-formals ((compose .elements .formals) trigger))
            (formal-bindings (filter (is? <formal-binding>) on-formals))
            (formal-bindings (and (pair? formal-bindings) (make <out-bindings> #:elements formal-bindings #:port (.port trigger))))
            (on-formals (map formal-binding->formal on-formals)))
       (if (not formal-bindings) o
           (clone o
                  #:triggers (clone (.triggers o)
                                    #:elements (list (clone trigger #:formals (make <formals> #:elements on-formals))))
                  #:statement ((passdown-formal-bindings formal-bindings) (.statement o))))))

    (($ <component>)
     (clone o #:behaviour ((binding-into-blocking) (.behaviour o))))

    (($ <behaviour>)
     (clone o #:statement ((binding-into-blocking '()) (.statement o))))

    (($ <interface>) o)
    (($ <system>) o)
    (($ <foreign>) o)
    ((? (is? <ast>)) (tree-map (binding-into-blocking locals) o))
    (_ o)))


(define (on-compound o)
  (match o
    ((and ($ <on>) (= .statement ($ <compound>))) o)
    (($ <on>)
     (clone o #:statement (make <compound> #:elements (list (.statement o)))))

    (($ <component>)
     (clone o #:behaviour (on-compound (.behaviour o))))

    (($ <behaviour>)
     (clone o #:statement (on-compound (.statement o))))

    (($ <interface>)
     (clone o #:behaviour (on-compound (.behaviour o))))

    ((? (is? <component-model>)) o)
    (($ <functions>) o)

    ((? (is? <ast>)) (tree-map on-compound o))
    (_ o)))

(define (ast-> ast)
  ((compose
    pretty-print
    om->list
    code-norm-event
    ast:resolve
    parse->om
    ) ast))
