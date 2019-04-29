;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag deprecated om)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag compare)
  #:use-module (gaiag util)

  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)

  #:export (
           om:behaviour-ports
           om:bind
           om:blocking-compound?
           om:instance-name
           om:collect
           om:declarative?
           om:events
           om:filter:p
           om:functions
           om:imperative?
           om:in?
           om:instances
           om:instance-name
           ;; om:interface-types
           om:name
           om:named
           om:out-or-inout?
           om:out?
           om:port
           om:ports
           om:port-bind
           om:port-bind?
           ;; om:port-binding?
           ;; om:public-types
           om:provided
           om:required
           om:scope
           om:scope+name
           om:scope-name
           om:type
           om:variables
           om:void?
           ))

(define (deprecated . where)
  (stderr "DEPRECATED:~a\n" where))

(define* (om:events- o #:optional (predicate? identity))
  (filter predicate?
          (match o
            (($ <interface>) (ast:event* o))
            (($ <port>) ((compose om:events .type) o)))))

(define om:events (pure-funcq om:events-))

(define (om:functions model)
  ((compose ast:function* .behaviour) model))

(define (om:instances o)
  (match o
    (($ <interface>) '())
    (($ <foreign>) o)
    (($ <component>) o)
    ((? (is? <system>)) (ast:instance* o))))

(define (om:ports- o)
  (match o
    (($ <interface>) '())
    ((? (is? <component-model>)) (ast:port* o))
    (($ <behaviour>) (ast:port* o))))

(define om:ports (pure-funcq om:ports-))

(define-method (om:variables (o <model>))
  (match o
    (($ <system>) '())
    (($ <foreign>) '())
    ((= .behaviour #f) '())
    (_ ((compose ast:variable* .behaviour) o))))



(define (om:provided o)
  (filter ast:provides? (om:ports o)))

(define (om:required o)
  (filter ast:requires? (om:ports o)))

;;; SINGLE-LOOKUP

(define (om:port-bind? bind)
  (and (om:port-binding? bind)
       bind))

(define (om:port-binding? bind)
  (or (and (not (.instance.name (.left bind)))
           (.left bind))
      (and (not (.instance.name (.right bind)))
           (.right bind))))

(define (om:port-bind system port)
  (find (lambda (bind) (and=> (om:port-bind? bind)
                              (lambda (b)
				(ast:equal? (.port (om:port-binding? b)) port))))
        (ast:binding* system)))

(define (om:bind system o)
  (let* ((binds (ast:binding* system)))
    (match o
      ((? symbol?) ;; FIXME: port need not be unique
       (deprecated (current-source-location))
       (find (lambda (bind) (or (ast:equal? (.port.name (.left bind)) o)
                                (ast:equal? (.port.name (.right bind)) o)))
           binds))
      ((and ($ <end-point>) (= .instance.name instance-name) (= .port.name port-name))
       (find (lambda (bind)
               (or (and (eq? (.instance.name (.left bind)) instance-name)
                                     (eq? (.port.name (.left bind)) port-name))
                                (and (eq? (.instance.name (.right bind)) instance-name)
                                     (eq? (.port.name (.right bind)) port-name))))
             binds)))))

(define (om:instance-name bind)
  (or (.instance.name (.left bind)) (.instance.name (.right bind))))

(define-method (om:behaviour-ports (o <component-model>))
  (if (and (is-a? o <component>) (.behaviour o))
      ((compose ast:port* .behaviour) o)
      '()))

(define* (om:port model #:optional (o #f))
  (match o
    (($ <end-point>)
     (let* ((port (.port o)))
       (or
        (and-let* ((name (.instance.name o))
                   (instance (resolve:instance model name))
                   (type (and=> instance .type))
                   (component type))
          (om:port component port))
        (om:port model port))))
    ('* (make <port> #:name '* #:direction 'requires))
    (_ (find (if o (om:named o)
                 (lambda (x) (eq? (.direction x) 'provides)))
             (append (ast:port* model)
                     (om:behaviour-ports model))))))

(define (unspecified? x) (eq? x *unspecified*))

;;; TYPES

(define ((om:type model) o)             ; deprecated
  (or (as o <type>)
      (.type o)))


;;; NAME/NAMESPACE/SCOPE

(define ((om:named name) o)
  (ast:equal? (.name o) name))

(define-method (om:scope+name o)
  (match o
    (($ <bool>) '(bool))
    (($ <void>) '(void))
    (($ <event>) ((compose om:scope+name .signature) o))
    (($ <formal>) ((compose om:scope+name .type.name) o))
    (($ <instance>) (om:scope+name (.type.name o)))
    (($ <enum-literal>) (append (om:scope+name (.type o)) (list (.field o))))
    (($ <port>) (om:scope+name (.type.name o)))
    (($ <scope.name>) (append (.scope o) (list (.name o))))
    (($ <signature>) ((compose om:scope+name .type.name) o))
    (($ <trigger>) ((compose om:scope+name .event) o))
    ((? (is? <named>)) ((compose om:scope+name .name) o))
    ))

(define* ((om:scope-name #:optional (infix '_)) o)
  (let ((infix (if (symbol? infix) infix
                   (string->symbol infix))))
    ((->symbol-join infix) (om:scope+name o))))

(define (om:name o)
  ((compose last om:scope+name) o))

(define (om:scope o)
  (drop-right (om:scope+name o) 1))

;;; UTILITIES

(define (om:blocking-compound? o)
  (match o
    (($ <component>)
     (and-let* ((behaviour (.behaviour o))
                (blocking ((om:collect <blocking-compound>) behaviour)))
       (pair? blocking)))
    (_ #f)))

(define ((collect predicate) o)
  (match o
    ((? (compose null-is-#f predicate)) (list o))
    (($ <compound>)
     (filter identity (apply append (map (collect predicate) (ast:statement* o)))))
    (($ <declarative-compound>)
     (filter identity (apply append (map (collect predicate) (ast:statement* o)))))
    (($ <functions>)
     (filter identity (apply append (map (collect predicate) (ast:function* o)))))
    (($ <variables>)
     (filter identity (apply append (map (collect predicate) (ast:variable* o)))))
    (($ <function>) (filter identity ((collect predicate) (.statement o))))
    (($ <assign>) (filter identity ((collect predicate) (.expression o))))
    (($ <variable>) (filter identity ((collect predicate) (.expression o))))
    (($ <blocking>) (filter identity ((collect predicate) (.statement o))))
    (($ <guard>) (filter identity ((collect predicate) (.statement o))))
    (($ <on>) (filter identity ((collect predicate) (.statement o))))
    (($ <if>) (append (filter identity ((collect predicate) (.then o)))
                      (filter identity ((collect predicate) (.else o)))))
    ;; FIXME: recurse through whole AST
    (($ <interface>) (filter identity ((collect predicate) (.behaviour o))))
    (($ <component>) (filter identity ((collect predicate) (.behaviour o))))
    (($ <behaviour>) (append
                      (filter identity ((collect predicate) (.statement o)))
                      (filter identity ((collect predicate) (.functions o)))))
    ((h t ...)
     (filter identity (apply append (map (collect predicate) o))))
    (_ '())))

(define ((om:collect x) o)
  (match x
    ((? procedure?) ((collect x) o))
    (_ ((collect (is? x)) o))))

(define ((om:filter:p x) o)
  (let ((filter (if (is-a? o <ast>) om:filter filter)))
    (match x
      (symbol? (filter (is? x) o))
      (procedure? (filter x o)))))

(define (om:interface-types o)
  ;;(stderr "om:interface-types o=~a\n" o)
  (match o
    (($ <interface>) (om:public-types o))
    (($ <port>) ((compose om:public-types .type) o))
    ((? (is? <model>)) (append-map om:interface-types (om:ports o)))))

(define (om:public-types o)
  (match o
    ((? (is? <interface>)) (ast:type* o))
    (_ '())))

(define (om:declarative? o)
  (or (is-a? o <declarative>)
      (and (is-a? o <compound>)
                    (>0 (length (ast:statement* o)))
                    (om:declarative? (car (ast:statement* o))))
      (and (pair? o)
           (om:declarative? (car o)))))

(define (om:imperative? o)
  (and (is-a? o <statement>)
       (not (om:declarative? o))))

(define (om:in? o)
  (match o
    ((? (is? <event>)) (eq? (.direction o) 'in))
    ((? (is? <modeling-event>)) #t)
    (($ <formal>) (or (eq? (.direction o) 'in) (not (.direction o))))
    (($ <trigger>) #t)))

(define (om:out? o)
  (match o
    (($ <event>) (eq? (.direction o) 'out))
    ((? (is? <modeling-event>)) #f)
    (($ <formal>) (eq? (.direction o) 'out))
    (($ <trigger>) #f)))

(define (om:out-or-inout? o)
  (match o
    (? (is? <formal>)
     (or (eq? (.direction o) 'out)
         (eq? (.direction o) 'inout)))))

;;;; OM handling

(define (basename- o)
  (string->symbol (basename (symbol->string o))))

(define (in-file? o file)
  (let ((file (if (string? file) (string->symbol file) file)))
    (and-let* ((model-file (ast:source-file o))
               (model-file (if (string? model-file) (string->symbol model-file) model-file)))
              (eq? (basename- file) (basename- model-file)))))
