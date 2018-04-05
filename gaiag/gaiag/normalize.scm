;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag normalize)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag util)
  #:use-module (gaiag misc)

  #:use-module (gaiag ast)
  #:use-module (gaiag om)
  #:use-module (gaiag resolve)
  #:use-module (gaiag dzn)

  #:export (root->
            triples:state-traversal
            triples:->compound-guard-on
            triples:->triples
            triples:add-illegals
            triples:add-voidreply
            triples:compound->triples
            triples:fix-empty-interface
            triples:on-compound
            triples:split-multiple-on
            ))

(define om:imperative? (@ (gaiag deprecated om) om:imperative?)) ;; REMOVEME

(define (combine guards)
  (make <guard> #:expression (fold (cut make <and> #:left <> #:right <>)
                                   (make <literal> #:value 'true)
                                   (map .expression guards))))

(define (combine-not guards)
  (make <guard> #:expression (fold (lambda (elem prev) (make <and> #:left (make <not> #:expression elem) #:right prev))
                                   (make <literal> #:value 'true)
                                   (map .expression guards))))

(define (t-triple on guard blocking statement) (list on guard blocking statement))
(define (t-on triple) (first triple))
(define (t-guard triple) (second triple))
(define (t-blocking triple) (third triple))
(define (t-statement triple) (fourth triple))

(define (triples:->compound-guard-on triples)
  (let* ((st (map (lambda (t)
                    (let* ((on (t-on t))
                           (guard (t-guard t))
                           (statement (t-statement t))
                           (blocking (t-blocking t))
                           (statement (if blocking (clone blocking #:statement statement)
                                          statement)))
                      (clone guard #:statement (clone on #:statement statement))))
                  triples)))
    (make <declarative-compound> #:elements st)))

(define ((triples:component-prepend-illegal-guard model) triples)
  (define (declarative-illegal? o)
    (match o
      (($ <illegal>) o)
      ((and ($ <compound>) (= .elements (? null?))) #f)
      (($ <compound>) (declarative-illegal? ((compose car .elements) o)))
      (_ #f)))
  (define (prepend t)
    (if (not (declarative-illegal? (t-statement t))) t
        (let* ((guard (t-guard t))
               (ill (make <literal> #:value 'illegal_guard))
               (guard (clone guard #:expression (make <and> #:left ill #:right (.expression guard)))))
          (t-triple (t-on t) guard (t-blocking t) (t-statement t)))))
  (if (is-a? model <interface>) triples (map prepend triples)))

(define ((triples:fix-empty-interface model) triples)
  (if (and (is-a? model <interface>) (null? triples))
      (let* ((on (make <on> #:triggers (make <triggers> #:elements (list (make <trigger> #:event.name 'inevitable)))))
             (guard (make <guard> #:expression (make <literal> #:value 'false)))
             (statement (make <compound> #:elements (list (make <illegal>)))))
        (list (t-triple on guard #f statement)))
      triples))

(define ((triples:add-illegals model) triples)
  (define (add-illegals- triples trigger)
    (define (trigger-eq? t)
      (and (eq? (.port.name t) (.port.name trigger)) (eq? (.event.name t) (.event.name trigger))))
    (let* ((triples (filter (lambda (t) (trigger-eq? ((compose car ast:trigger* t-on) t))) triples))
           (on (make <on> #:triggers (make <triggers> #:elements (list trigger))))
           (guard (combine-not (map t-guard triples)))
           (statement (make <illegal> #:incomplete #t)))
      (append triples (list (t-triple on guard #f statement)))))
  (append (append-map (cut add-illegals- triples <>) (ast:in-triggers model))
          (filter (compose ast:modeling? car ast:trigger* t-on) triples)))

(define (triples:add-voidreply triples)
  (define (voidreply-triple t)
    (let* ((on (t-on t))
           (valued-triggers? (ast:typed? ((compose car ast:trigger*) on)))
           (modeling? (is-a? ((compose .event car ast:trigger*) on) <modeling-event>))
           (port ((compose .port car ast:trigger*) on))
           (requires? (and port (ast:requires? port))))
      (if (or modeling? requires? valued-triggers?) t
          (let* ((statement (t-statement t))
                 (voidreply (make <voidreply>))
                 (elements (if (is-a? statement <compound>)
                               (append (.elements statement) (list voidreply))
                               (list statement voidreply)))
                 (statement (make <compound> #:elements elements)))
            (t-triple on (t-guard t) (t-blocking t) statement)))))
  (map voidreply-triple triples))

(define (triples:split-multiple-on triples)
  (define (split-on t)
    (let* ((on (t-on t))
           (triggers (ast:trigger* on))
           (ons (if (= (length triggers) 1) (list on)
                    (map (lambda (t) (clone on #:triggers (make <triggers> #:elements (list t)))) triggers))))
      (map (lambda (on) (t-triple on (t-guard t) (t-blocking t) (t-statement t))) ons)))
  (append-map split-on triples))

(define (triples:->triples o)
  (define (triple o)
    (let ((path (ast:path o (lambda (p) (is-a? (.parent p) <behaviour>)))))
      (t-triple (find (is? <on>) path)
                (combine (filter (is? <guard>) path))
                (find (is? <blocking>) path)
                o)))
  ;;(filter t-on (map triple (tree-collect-shallow om:imperative? o)))
  (if (and (is-a? o <compound>) (null? (.elements o))) '()
      (map triple (tree-collect-shallow om:imperative? o))))

(define (triples:on-compound triples)
  (define (foo t)
    (let* ((statement (t-statement t))
           (statement (if (is-a? statement <compound>) statement
                          (make <compound> #:elements (list statement)))))
      (t-triple (t-on t) (t-guard t) (t-blocking t) statement)))
  (map foo triples))

(define (triples:state-traversal o)
  (match o
    (($ <behaviour>) (clone o #:statement
                            ((compose
                              triples:->compound-guard-on
                              (triples:fix-empty-interface (parent o <model>))
                              (triples:component-prepend-illegal-guard (parent o <model>))
                              (triples:add-illegals (parent o <model>))
                              triples:add-voidreply
                              triples:split-multiple-on
                              triples:->triples
                              .statement
                              ) o)))
    ((? (is? <ast>)) (tree-map triples:state-traversal o))
    (_ o)))

(define-method (root-> (o <root>))
  ((compose
    (lambda (o) (display (ast->dzn o) (current-error-port)) o)
    triples:state-traversal
    ast:resolve
    ) o))

(define (ast-> ast)
  ((compose
    (cut display ast->dzn <>)
    root->
    parse->om)
   ast))
