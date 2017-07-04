;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

  #:use-module (language dezyne location)
  #:use-module (gaiag misc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (eq? x '<port>) 'goops:<port> x)))
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag norm)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)

  #:export (
           ast->
           code-norm-event-auwe-meuk
           code-norm-event
           norm-event
           table-norm-event
           ast:direction
           ast:in-triggers
           ast:out-triggers
           ast:provided-in-triggers
           ast:provided-out-triggers
           ast:required-in-triggers
           ast:required-out-triggers
           ))

(define g-time (get-internal-run-time))
(define* ((perf label) o)
  (let* ((time (get-internal-run-time))
         ;(foo (stderr "TIME ~a: ~a\n" label (- time g-time)))
         )
    (set! g-time time)
    o))

;; norm-event used for <root> and other <ast>
(define-method (norm-event (o <ast>))
  (((if (is-a? o <root>) compose-root compose)
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

(define (code-norm-event-auwe-meuk o)
  ((compose
    (add-illegals-auwe-meuk)
    remove-skip
    on-compound
    flatten-compound
    combine-guards
    (aggregate-on norm:triggers-equal?)
    (binding-into-blocking)
    (rewrite-formals)
    flatten-compound
    (passdown-blocking)
    flatten-compound
    passdown-guard
    flatten-compound
    (expand-on norm:on-equal?)
    aggregate-guard-s
    flatten-compound
    combine-ons
    (passdown-blocking)
    passdown-guard
    (remove-otherwise)
    add-skip)
   o))

(define-method (code-norm-event (o <root>))
  ((compose-root
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
    add-skip
    (perf 'START))
   o))

(define* ((group-ons #:optional (group? norm:triggers-equal?)) o)
  "stable place ons with same group? next to eachother"
  (match o
    (($ <compound> (($ <on>) ..1))
     (if (=1 (length (.elements o)))
         o
         (clone o #:elements
           (let loop ((ons (.elements o)))
             (if (null? ons)
                 '()
                 (receive (grouped-ons remainder)
                     (partition (lambda (x) (group? #f (car ons) x)) ons)
                   (append grouped-ons (loop remainder))))))))
     (($ <functions> (functions ...)) o)
     (($ <skip>) o)
     ((? (is? <ast>)) (om:map (group-ons group?) o))
     (_ o)))

(define (aggregate-guard-s o)
  "Aggregate guards with matching statement into one guard-statement."
  ;; find all guands with matching statement
  ;; push all guards into first guard, discard the rest
  (match o
    (($ <compound> (($ <guard>) ..1))
     (clone o #:elements
       (let loop ((guards (.elements o)))
         (if (null? guards)
             '()
             (receive (shared-guards remainder)
                 (partition (lambda (x) (norm:guard-same-statement? #f (car guards) x)) guards)
               (if (=1 (length shared-guards))
                   (cons (car shared-guards) (loop remainder))
                   (let* ((expression
                           (reduce (lambda (x y)
                                     (make <or> #:left x #:right y))
                                   '()
                                   (delete-duplicates (map (compose .expression) shared-guards) om:equal?)))
                          (statement (.statement (car guards)))
                          (aggregated-guard (make <guard>
                                              #:expression expression
                                              #:statement statement)))
                     (cons aggregated-guard (loop remainder)))))))))
     ((and (? (is? <component>) (= .behaviour behaviour)))
      (clone o #:behaviour (aggregate-guard-s behaviour)))
     ((and (? (is? <interface>) (= .behaviour behaviour)))
      (clone o #:behaviour (aggregate-guard-s behaviour)))
     ((? (is? <component-model>)) o)
     ((? om:imperative?) o)
     (($ <functions> (functions ...)) o)
     (($ <skip>) o)
     ((? (is? <ast>)) (om:map aggregate-guard-s o))
     (_ o)))

(define (norm:guard-same-statement? model lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
       (om:equal? (.statement lhs) (.statement rhs))))

(define (combine-ons o)
  (match o
    (($ <on>) ((passdown-on- o) (.statement o)))
    (($ <skip>) o)
    (($ <functions> (functions ...)) o)
    ((and (? (is? <component>) (= .behaviour behaviour)))
     (clone o #:behaviour (combine-ons behaviour)))
    ((and (? (is? <interface>) (= .behaviour behaviour)))
     (clone o #:behaviour (combine-ons behaviour)))
    ((? (is? <component-model>)) o)
    ((? (is? <ast>)) (om:map combine-ons o))
    (_ o)))

(define ((passdown-on- on) o)
  (match o
    ((and ($ <compound> (s ...)) (? om:declarative?))
     (clone o #:elements (map (passdown-on- on) s)))
    (_
     (clone on #:statement o))))

(define (passdown-guard o)
  (match o
    ((and ($ <compound> (s ...)) (? om:imperative?)) o)
    (($ <guard>) ((passdown-guard- o) (.statement o)))
    (($ <skip>) o)
    ((and (? (is? <component>) (= .behaviour behaviour)))
     (clone o #:behaviour (passdown-guard behaviour)))
    ((and (? (is? <interface>) (= .behaviour behaviour)))
     (clone o #:behaviour (passdown-guard behaviour)))
    ((? (is? <component-model>)) o)
    (($ <functions> (functions ...)) o)
    ((? (is? <ast>)) (om:map passdown-guard o))
    (_ o)))

(define* ((passdown-guard- guard #:optional (seen-on? #f)) o)
  (define (make-guard o)
    (clone guard #:statement o))
  (match o
    (($ <on>)
     (clone o
       #:statement ((passdown-guard- guard #t) (.statement o))))
    (($ <compound> (($ <guard>) ..1)) (=> failure)
     (if seen-on?
         (make-guard o)
         (failure)))
    ((and ($ <compound> (s ...)) (? om:declarative?))
     (clone o #:elements (map (passdown-guard- guard seen-on?) s)))
    (($ <compound> (s ...))
     (make-guard o))
    (($ <guard> e s)
     (let ((oo  ((passdown-guard- o seen-on?) s)))
       (match oo
         (($ <on> t s)
          (clone oo #:statement (make-guard s)))
         ((and ($ <compound> (t ...)) (? om:declarative?))
          (clone oo #:elements (map (passdown-guard- guard seen-on?) t)))
         (_
          (make-guard oo)))))
    (_
     (make-guard o))))

(define (ast-> ast)
  ((compose-root
    om->list
    ;;((@ (gaiag dzn) ast->dzn))
    code-norm-event
    ast:resolve
    ast->om
    ) ast))

(define (pair-eq? p) (eq? (car p) (cdr p)))

(define-method (ast:direction (o <trigger>))
  (.direction (.event o)))

(define-method (ast:provided-in-triggers (o <component-model>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                     (filter om:in? (om:events port))))
              (filter om:provides? (om:ports o))))

(define-method (ast:required-out-triggers (o <component-model>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                     (filter om:out? (om:events port))))
              (filter om:requires? (om:ports o) )))

(define-method (ast:in-triggers (o <component-model>))
  (append (ast:provided-in-triggers o) (ast:required-out-triggers o)))

(define-method (ast:provided-out-triggers (o <component-model>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                     (filter om:out? (om:events port))))
              (filter om:provides? (om:ports o))))

(define-method (ast:required-in-triggers (o <component-model>))
  (append-map (lambda (port)
                (map (lambda (event) (make <trigger> #:port (.name port) #:event event #:formals ((compose .formals .signature) event)))
                     (filter om:in? (om:events port))))
              (filter om:requires? (om:ports o) )))

(define-method (ast:out-triggers (o <component-model>))
  (append (ast:provided-out-triggers o) (ast:required-in-triggers o)))

(define-method (trigger->illegal (o <trigger>))
  (make <on>
    #:triggers (make <triggers> #:elements (list o))
    #:statement (make <illegal>)))

(define* ((add-illegals-auwe-meuk #:optional model) o)
  (match o
    ((and ($ <component>) (= .behaviour behaviour))
     (clone o #:behaviour ((add-illegals-auwe-meuk o) behaviour)))

    ((and ($ <behaviour>) (= .statement statement))
     (let* ((triggers (ast:in-triggers model))
            (ons (.elements statement))
            (on-triggers (append-map (compose .elements .triggers) ons))
            (triggers (filter
                       (lambda (trigger)
                         (not (find (lambda (on-trigger)
                                      (and (eq? (.port.name trigger) (.port.name on-trigger))
                                           (eq? (.event.name trigger) (.event.name on-trigger))))
                                    on-triggers)))
                       triggers))
            (ons (append ons (map trigger->illegal triggers))))
       (if (null? ons) o
           (clone o #:statement (clone statement #:elements ons)))))
    (($ <interface>) o)
    (($ <system>) o)
    ((? (is? <ast>)) (om:map (add-illegals-auwe-meuk model) o))
    (_ o)))

(define* (add-reply-port o #:optional (port #f) (block? #f)) ;; requires (= 1 (length (.triggers on)))
  ;(stderr "add-reply-report o = ~a; port = ~a: model = ~a\n" o port model)
  (match o
    (($ <reply>) (let ((port? (.port o))) (if (and port? (not (symbol? port?))) o (clone o #:port port))))
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
    ((and ($ <behaviour>) (= .statement statement)) (clone o #:statement (add-reply-port statement port block?)))
    ((and ($ <component>) (= .behaviour behaviour)) (clone o #:behaviour (ast:set-model-scope o (add-reply-port behaviour (if (= 1 (length (filter om:provides? (om:ports o)))) (om:port o) #f) block?))))
    (($ <system>) o)
    (($ <interface>) o)
    ((? (is? <ast>)) (om:map (cut add-reply-port <> port block?) o))
    (_ o)))

(define* ((add-illegals #:optional model) o)
  (match o
    ((and ($ <component>) (= .behaviour behaviour))
     (clone o #:behaviour ((add-illegals o) behaviour)))

    ((and ($ <behaviour>) (= .statement statement))
     (let* ((triggers (ast:in-triggers model))
            (ons (.elements statement))
            (on-triggers (append-map (compose .elements .triggers) ons))
            (triggers (filter
                       (lambda (trigger)
                         (not (find (lambda (on-trigger)
                                      (and (eq? (.port.name trigger) (.port.name on-trigger))
                                           (eq? (.event.name trigger) (.event.name on-trigger))))
                                    on-triggers)))
                       triggers))
            (ons (append (map (add-illegals model) ons) (map trigger->illegal triggers))))
       (if (null? ons) o
           (clone o #:statement (clone statement #:elements ons)))))
    ((and ($ <compound>) (? om:declarative?)) (=> failure)
     (if (and (pair? (.elements o)) (is-a? (car (.elements o)) <guard>) (null? (filter (is? <otherwise>) (.elements o))))
         (clone o #:elements (append (.elements o) (list (make <guard> #:expression (make <otherwise>) #:statement (make <illegal>)))))
         (failure)))
    (($ <interface>) o)
    (($ <system>) o)
    ((? (is? <ast>)) (om:map (add-illegals model) o))
    (_ o)))

(define* ((rewrite-formals #:optional model (locals '())) o)

  (define (member? identifier) (om:variable model identifier))
  (define (local? identifier) (assoc-ref locals identifier))
  (define (var? identifier) (or (member? identifier) (local? identifier)))
  (define (extern? identifier) (and=> (var? identifier) (cut om:extern model <>)))
  (define (extern-type? type) (om:extern model type))

  (define (assoc-xref alist value)
    (define (cdr-equal? x) (equal? (cdr x) value))
    (and=> (find cdr-equal? alist) car))

  (define ((rename mapping) o)
    ;;(stderr "rename o=~a\n" o)
    (match o
      (($ <trigger> port event ($ <formals> ())) o)
      (($ <trigger> port event ($ <formals> (on-formal* ...)))
       (clone o #:formals (make <formals> #:elements (map (rename mapping) on-formal*))))
      ;; (($ <expression> ($ <var> name))
      ;;  (clone o #:value (make <var> #:name ((rename mapping) name))))
      ;; (($ <expression> ('<- ($ <var> name) global))
      ;;  (clone o #:value `(<- ,(make <var> #:name ((rename mapping) name)) ,global)))
      ((? symbol?) (or (assoc-ref mapping o) o))
      ((? (is? <ast>)) (om:map (rename mapping) o))
      (_ o)))

  (define (name->on-formal name)
    (make <formal> #:name name))

  ;;(stderr "rewrite o=~a\n" o)
  (match o
    (($ <on> ($ <triggers> ((and ($ <trigger>) (= .formals ($ <formals> ())) (get! trigger)))) statement)
     (let* ((trigger (trigger))
            (formals (map .name ((compose .elements .formals .signature) (.event trigger))))
            (on-formals (map name->on-formal formals)))
       (if (null? formals) o
           (clone o
                  #:triggers (make <triggers> #:elements (list (clone trigger #:formals (make <formals> #:elements on-formals))))))))
    (($ <on> ($ <triggers> ((and ($ <trigger>) (= .formals ($ <formals> (on-formal* ...))) (get! trigger)))) statement)
     (let* ((trigger (trigger))
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
            (mapping (filter (negate pair-eq?) (map cons (map .name on-formal*) fresh-formals)))

            (occupied (append (map cdr mapping) members))

            (mapping (append (map cons locals (list-head (refresh occupied locals) (length locals))) mapping)))

       (if (null? mapping) o
           (clone o
                  #:triggers (make <triggers> #:elements (list ((rename mapping) trigger)))
                  #:statement ((rename mapping) statement)))))

    ((and ($ <component>) (= .behaviour behaviour))
     (clone o #:behaviour ((rewrite-formals o) behaviour)))

    ((and ($ <behaviour>) (= .statement statement))
     (clone o #:statement ((rewrite-formals model '()) statement)))

    (($ <interface>) o)
    (($ <system>) o)
    ((? (is? <ast>)) (om:map (rewrite-formals model locals) o))
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
    ((and ($ <on>) (= .triggers triggers) (= .statement statement))
     (let* ((trigger (car (.elements triggers)))
            (on-formals (.elements (.formals trigger)))
            (formal-bindings (filter (is? <formal-binding>) on-formals))
            (formal-bindings (and (pair? formal-bindings) (make <out-bindings> #:elements formal-bindings #:port (.port trigger))))
            (on-formals (map formal-binding->formal on-formals)))
       (if (not formal-bindings) o
        (clone o
               #:triggers (clone triggers
                                 #:elements (list (clone trigger #:formals (make <formals> #:elements on-formals))))
               #:statement ((passdown-formal-bindings formal-bindings) statement)))))

    ((and ($ <component>) (= .behaviour behaviour))
     (clone o #:behaviour (ast:set-model-scope o ((binding-into-blocking) behaviour))))

    ((and ($ <behaviour>) (= .statement statement))
     (clone o #:statement ((binding-into-blocking '()) statement)))

    (($ <interface>) o)
    (($ <system>) o)
    ((? (is? <ast>)) (om:map (binding-into-blocking locals) o))
    (_ o)))


(define (on-compound o)
  (match o
    ((and ($ <on>) (= .statement ($ <compound>))) o)
    (($ <on>)
     (clone o #:statement (make <compound> #:elements (list (.statement o)))))

    ((and ($ <component>) (= .behaviour behaviour))
     (clone o #:behaviour (on-compound behaviour)))

    ((and ($ <behaviour>) (= .statement statement))
     (clone o #:statement (on-compound statement)))

    (($ <interface>) o)
    ((? (is? <component-model>)) o)
    (($ <functions> (functions ...)) o)
    ((? (is? <ast>)) (om:map on-compound o))
    (_ o)))

;; (define ast (read-ast '../../test/all/normalize_alias_local/normalize_alias_local.dzn))
;; (define om (ast->om ast))
;; (define root (ast:resolve om))
;; (define model (find (is? <component>) root))
;; (define statement (.statement (.behaviour model)))
