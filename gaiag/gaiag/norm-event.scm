;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2016 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
           code-norm-event
           norm-event
           table-norm-event
           ))

(define (norm-event o)
  ((compose
    remove-skip
    aggregate-guard-s
    (group-ons)
    (aggregate-on norm:on-statement-equal?)
    (expand-on norm:on-equal?)
    aggregate-guard-s
    flatten-compound
    combine-ons
    passdown-guard
    (passdown-blocking)
    (remove-otherwise)
    add-skip
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

(define (code-norm-event o)
  ((compose
    remove-skip
    flatten-compound
    combine-guards
    (aggregate-on norm:triggers-equal?)
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
    add-skip
    )
   o))

(define* ((group-ons #:optional (group? norm:triggers-equal?)) o)
  "stable place ons with same group? next to eachother"
  (match o
    (($ <compound> (($ <on>) ..1))
     (if (=1 (length (.elements o)))
         o
         (make <compound>
           #:elements
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
     (make <compound>
       #:elements
       (let loop ((guards (.elements o)))
         (if (null? guards)
             '()
             (receive (shared-guards remainder)
                 (partition (lambda (x) (norm:guard-same-statement? #f (car guards) x)) guards)
               (if (=1 (length shared-guards))
                   (cons (car shared-guards) (loop remainder))
                   (let* ((expression
                           (reduce (lambda (x y)
                                     (list 'or x y))
                                   '()
                                   (delete-duplicates (map (compose .value .expression) shared-guards) om:equal?)))
                          (statement (.statement (car guards)))
                          (aggregated-guard (make <guard>
                                              #:expression (make <expression>
                                                            #:value expression)
                                              #:statement statement)))
                     (cons aggregated-guard (loop remainder)))))))))
     (($ <functions> (functions ...)) o)
     (($ <skip>) o)
     ((? (is? <ast>)) (om:map aggregate-guard-s o))
     (_ o)))

(define (norm:guard-same-statement? model lhs rhs)
  (and (is-a? lhs <guard>) (is-a? rhs <guard>)
       (equal? (om->list (.statement lhs)) (om->list (.statement rhs)))))

(define (combine-ons o)
  (match o
    (($ <on>) ((passdown-triggers (.triggers o)) (.statement o)))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map combine-ons o))
    (_ o)))

(define ((passdown-triggers triggers) o)
  (match o
    (($ <on>)
     ((passdown-triggers
       (retain-source-properties
        (.triggers o)
        (make <triggers> #:elements (append (.elements triggers) (.elements (.triggers o))))))
      (.statement o)))
    ((and ($ <compound> (s ...)) (? om:declarative?))
     (retain-source-properties
      o
      (make <compound> #:elements (map (passdown-triggers triggers) s))))
    (($ <compound> (statements ...))
     (make <on> #:triggers triggers #:statement o))
    (_
     (retain-source-properties
      triggers
      (make <on> #:triggers triggers #:statement o)))))

(define (passdown-guard o)
  (match o
    ((and ($ <compound> (s ...)) (? om:imperative?)) o)
    (($ <guard>) ((passdown-expression (retain-source-properties o (.expression o))) (.statement o)))
    (($ <skip>) o)
    ((? (is? <ast>)) (om:map passdown-guard o))
    (_ o)))

(define* ((passdown-expression expression #:optional (seen-on? #f)) o)
  (match o
    (($ <on>)
     (make <on>
       #:triggers (.triggers o)
       #:statement
       (retain-source-properties
        expression
        ((passdown-expression expression #t) (.statement o)))))
    (($ <compound> (($ <guard>) ..1)) (=> failure)
     (if seen-on?
         (retain-source-properties
          expression
          (make <guard> #:expression expression #:statement o))
         (failure)))
    ((and ($ <compound> (s ...)) (? om:declarative?))
     (retain-source-properties
      o
      (make <compound> #:elements (map (passdown-expression expression seen-on?) s))))
    (($ <compound> (s ...))
     (retain-source-properties
      expression
      (make <guard> #:expression expression #:statement o)))
    (($ <guard> e s)
     (let ((o ((passdown-expression e seen-on?) s)))
       (match o
         (($ <on> t s)
          (make <on>
            #:triggers t
            #:statement
            (retain-source-properties
             expression
             (make <guard> #:expression expression #:statement s))))
         ((and ($ <compound> (t ...)) (? om:declarative?))
          (retain-source-properties
           o
           (make <compound>
             #:elements (map (passdown-expression expression seen-on?) t))))
         (_
          (retain-source-properties
           expression
           (make <guard> #:expression expression #:statement o))))))
    (_
     (retain-source-properties
        expression
        (make <guard> #:expression expression #:statement o)))))

(define (ast-> ast)
  ((compose
    om->list
    ((@ (gaiag dzn) ast->dzn))
    code-norm-event
    ast:resolve
    ast->om
    ) ast))

(define (pair-eq? p) (eq? (car p) (cdr p)))

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
    (match o
      (($ <trigger> port event ($ <arguments> ())) o)
      (($ <trigger> port event ($ <arguments> (argument* ...)))
       (make <trigger> #:port port #:event event
             #:arguments (make <arguments> #:elements (map (rename mapping) argument*))))
      (($ <expression> ($ <var> name))
       (make <expression> #:value (make <var> #:name ((rename mapping) name))))
      (($ <expression> ('<- ($ <var> name) global))
       (clone o #:value `(<- ,(make <var> #:name ((rename mapping) name)) ,global)))
      ((? symbol?) (or (assoc-ref mapping o) o))
      ((? (is? <ast>)) (om:map (rename mapping) o))
      (_ o)))

  (define (name->argument name)
    (make <expression> #:value (make <var> #:name name)))

  (match o
    (($ <on> ($ <triggers> ((and ($ <trigger> port event ($ <arguments> ())) (get! trigger)))) statement)
     (let* ((trigger (trigger))
            (formals (map .name ((compose .elements .formals .signature) (om:event model trigger))))
            (arguments (map name->argument formals)))
       (if (null? formals) o
           (rsp o (make <on>
                    #:triggers (make <triggers> #:elements (list (make <trigger> #:port port #:event event #:arguments (make <arguments> #:elements arguments))))
                    #:statement statement)))))
    (($ <on> ($ <triggers> ((and ($ <trigger> port event ($ <arguments> (argument* ...))) (get! trigger)))) statement)
     (let* ((trigger (trigger))
            (members (map .name (om:variables model)))
            (formals (map .name ((compose .elements .formals .signature) (om:event model trigger))))
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
            (mapping (filter (negate pair-eq?) (map cons (map (compose .name .value) argument*) fresh-formals)))

            (occupied (append (map cdr mapping) members))

            (mapping (append (map cons locals (list-head (refresh occupied locals) (length locals))) mapping)))

       (if (null? mapping) o
           (rsp o (make <on>
                    #:triggers (make <triggers> #:elements (list ((rename mapping) trigger)))
                    #:statement ((rename mapping) statement))))))

    ;; TOP
    (($ <enum>) o)
    (($ <extern>) o)
    (($ <int>) o)
    (($ <interface>) o)
    (($ <system>) o)
    (($ <component> name ports behaviour)
     (rsp o (make <component>
              #:name name
              #:ports ports
              #:behaviour ((rewrite-formals o) behaviour))))

    (($ <behaviour> name types ports variables functions statement)
     (make <behaviour>
       #:name name
       #:types types
       #:ports ports
       #:variables variables
       #:functions functions
       #:statement ((rewrite-formals model '()) statement)))

    ((? (is? <ast>)) (om:map (rewrite-formals model locals) o))
    (_ o)))

;; (define ast (read-ast '../../test/all/normalize_alias_local/normalize_alias_local.dzn))
;; (define om (ast->om ast))
;; (define root (ast:resolve om))
;; (define model (find (is? <component>) root))
;; (define statement (.statement (.behaviour model)))
