;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:use-module (gaiag annotate)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)

  #:use-module (gaiag location)

  #:export (
           om:behaviour-ports
           om:bind
           om:bind-other-port
           om:binding
           om:bindings
           om:binding-other
           om:binding-other-port
           om:blocking?
           om:blocking-compound?
           om:instance-name
           om:collect
           om:declarative?
           om:enums
           om:event
           om:events
           om:filter:p
           om:find-triggers
           om:functions
           om:globals
           om:imperative?
           om:imported?
           om:in?
           om:instances
           om:instance-name
           om:instance-binding?
           om:interface-enums
           om:interface-types
           om:interfaces
           om:name
           om:named
           om:operator?
           om:out-formals
           om:out-or-inout?
           om:out?
           om:port
           om:port-event
           om:ports
           om:port-bind
           om:port-bind?
           om:port-binding?
           om:public-types
           om:provided
           om:reply-enums
           om:reply-types
           om:required
           om:scope
           om:scope+name
           om:scope-join ;; JUNKME
           om:scope-name
           om:type
           om:typed?
           om:type-name
           om:types
           om:variables
           om:void?
           ))

(define (deprecated . where)
  (stderr "DEPRECATED:~a\n" where))

(define* (om:events- o #:optional (predicate? identity))
  (filter predicate?
          (match o
            (($ <interface>) ((compose .elements .events) o))
            (($ <port>) ((compose om:events .type) o)))))

(define om:events (pure-funcq om:events-))

(define (om:bindings o)
  (match o
    (($ <system>) ((compose .elements .bindings) o))))

(define (om:functions model)
  ((compose .elements .functions .behaviour) model))

(define (om:instances o)
  (match o
    (($ <interface>) '())
    (($ <foreign>) o)
    (($ <component>) o)
    ((? (is? <system>)) ((compose .elements .instances) o))))

(define (om:ports- o)
  (match o
    (($ <interface>) '())
    ((? (is? <component-model>)) (ast:port* o))
    (($ <behaviour>) ((compose .elements .ports) o))))

(define om:ports (pure-funcq om:ports-))

(define (om:types o)
  (match o
    (($ <root>) (filter (is? <type>) (ast:global* o)))
    (($ <behaviour>) (ast:type* o))
    (($ <interface>)
     (append ((compose .elements .types .behaviour) o)
             ((compose .elements .types) o)))
    ((and ($ <component>) (not (= .behaviour #f)))
     (append ((compose .elements .types .behaviour) o) (om:interface-types o)))
    ((? (is? <component-model>)) (om:interface-types o))
    (($ <import>) '())
    (#f '())
    ((? unspecified?) '())))

(define (om:globals o)
  (filter (is? <type>) (.elements (parent <root> o))))

(define-method (om:variables (o <model>))
  (match o
    (($ <system>) '())
    (($ <foreign>) '())
    ((= .behaviour #f) '())
    (_ ((compose .elements .variables .behaviour) o))))


(define (om:enums o)
  (filter (is? <enum>) (om:types o)))


(define (om:provided o)
  (filter ast:provides? (om:ports o)))

(define (om:required o)
  (filter ast:requires? (om:ports o)))


(define (om:interface-enums o)
  (match o
    (($ <interface>) (om:filter (is? <enum>) (.types o)))
    (($ <port>) (om:enums o))
    ((? (is? <component-model>))
     (append-map om:interface-enums (ast:port* o)))))


;;; SINGLE-LOOKUP

(define (om:port-bind? bind)
  (and (om:port-binding? bind)
       bind))

(define (om:port-binding? bind)
  (or (and (not (.instance (.left bind)))
           (.left bind))
      (and (not (.instance (.right bind)))
           (.right bind))))

(define (om:instance-binding? bind)
  (or (and (not (.instance (.left bind)))
           (.right bind))
      (and (not (.instance (.right bind)))
           (.left bind))))


(define (om:port-bind system port)
  (find (lambda (bind) (and=> (om:port-bind? bind)
                              (lambda (b)
				(om:equal? (.port (om:port-binding? b)) port))))
        ((compose .elements .bindings) system)))

(define (om:bind system o)
  (let* ((binds ((compose .elements .bindings) system)))
    (match o
      ((? symbol?) ;; FIXME: port need not be unique
       (deprecated (current-source-location))
       (find (lambda (bind) (or (om:equal? (.port.name (.left bind)) o)
                                (om:equal? (.port.name (.right bind)) o)))
           binds))
      ((and ($ <binding>) (= .instance instance) (= .port port-name))
       (find (lambda (bind)
               (or (and (eq? (.instance (.left bind)) instance)
                                     (eq? (.port.name (.left bind)) port-name))
                                (and (eq? (.instance (.right bind)) instance)
                                     (eq? (.port.name (.right bind)) port-name))))
             binds)))))

(define (om:bind-other-port bind port-name) ;; FIXME: port need not be unique
  (deprecated (current-source-location))
  (if (eq? (.port.name (.left bind)) port-name) (.right bind) (.left bind)))

(define (om:binding system o)
  (match o
    ((? symbol?)
     (deprecated (current-source-location))
     (let ((bind (om:bind system o)))
       (if (eq? (.port.name (.left bind)) o) (.left bind) (.right bind))))
    ((and ($ <binding>) (= .instance instance) (= .port port-name))
     (let ((bind (om:bind system o)))
       (and bind
            (if (and (eq? (.instance (.left bind)) instance)
                     (eq? (.port.name (.left bind)) port-name)) (.left bind)
                     (.right bind)))))))

(define (om:binding-other-port system port) ;; FIXME: port need not be unique
  (deprecated (current-source-location))
  (let* ((bind (om:bind system port)))
    (om:bind-other-port bind port)))

(define (om:binding-other system binding)
  (let ((bind (om:bind system binding)))
    (if (and (eq? (.instance (.left bind)) (.instance binding))
             (eq? (.port.name (.left bind)) (.port.name binding)))
        (.right bind)
        (.left bind))))

(define (om:instance-name bind)
  (or (.instance (.left bind)) (.instance (.right bind))))

(define-method (om:behaviour-ports (o <component-model>))
  (if (and (is-a? o <component>) (.behaviour o))
      ((compose .elements .ports .behaviour) o)
      '()))

(define* (om:port model #:optional (o #f))
  (match o
    (($ <binding>)
     (let* ((port (.port o)))
       (or
        (and-let* ((name (.name (.instance o)))
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

(define (om:type-name o)
  (match o
    (($ <enum>) 'enum)
    (($ <extern>) ((->symbol-join '_) (om:scope+name o))) ;; FIXME: -> 'data
    (($ <int>) 'int)
    (($ <bool>) 'bool)
    (($ <void>) 'void)))

(define ((om:type model) o)             ; deprecated
  (or (as o <type>)
      (.type o)))


;;; NAME/NAMESPACE/SCOPE

(define ((om:named name) o)
  (om:equal? (.name o) name))

(define-method (om:scope+name o)
  (match o
    (($ <bool>) '(bool))
    (($ <void>) '(void))
    (($ <event>) ((compose om:scope+name .signature) o))
    (($ <formal>) ((compose om:scope+name .type) o))
    (($ <instance>) (om:scope+name (.type.name o)))
    (($ <enum-literal>) (append (om:scope+name (.type o)) (list (.field o))))
    (($ <port>) (om:scope+name (.type.name o)))
    (($ <scope.name>) (append (.scope o) (list (.name o))))
    (($ <signature>) ((compose om:scope+name .type) o))
    (($ <trigger>) ((compose om:scope+name .event) o))
    ((? (is? <scoped>)) ((compose om:scope+name .name) o))
    ((? (is? <model>)) ((compose om:scope+name .name) o)) ;; FIXME
    ))

(define* ((om:scope-name #:optional (infix '_)) o)
  (let ((infix (if (symbol? infix) infix
                   (string->symbol infix))))
    ((->symbol-join infix) (om:scope+name o))))

(define* ((om:scope-join #:optional (model #f) (infix '_)) o)
  (define (global-scope?)
    (and model (>1 (length o))
         (not (eq? ((compose car om:scope+name) model) (car o)))))
  (let* ((infix (if (symbol? infix) infix
		    (string->symbol infix)))
         (scope (if (not model) o
                    (if (global-scope?) (cons null-symbol o)
                        (drop-prefix (om:scope+name model) o)))))
    ((->symbol-join infix) scope)))

(define (om:name o)
  ((compose last om:scope+name) o))

(define (om:scope o)
  (drop-right (om:scope+name o) 1))

;;; UTILITIES

(define (om:blocking? o)
  (match o
    (($ <component>)
     (and-let* ((behaviour (.behaviour o))
                (blocking ((om:collect <blocking>) behaviour)))
       (pair? blocking)))
    (_ #f)))

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

(define* (om:find-triggers ast #:optional (found '()))
  (match ast
    ((or ($ <interface>) ($ <component>))
     (or (and=> (.behaviour ast) om:find-triggers) '()))
    (($ <behaviour>) (or (and=> (.statement ast) om:find-triggers) '()))
    (($ <compound>)
     (delete-duplicates (sort (append (apply append (map om:find-triggers (ast:statement* ast)))) om:<)))
    (($ <blocking>) (om:find-triggers (.statement ast) found))
    (($ <on>) (om:find-triggers (.triggers ast)))
    (($ <triggers>) (ast:trigger* ast))
    (($ <guard>) (om:find-triggers (.statement ast) found))
    (($ <system>) (append-map om:find-triggers (map (lambda (i) (resolve:component ast i)) (om:instances ast))))
    (_ '())))

(define (om:interface-types o)
  ;;(stderr "om:interface-types o=~a\n" o)
  (match o
    (($ <interface>) (om:public-types o))
    (($ <port>) ((compose om:public-types .type) o))
    ((? (is? <model>)) (append-map om:interface-types (om:ports o)))))

(define (om:public-types o)
  ;;(stderr "PUBLIC[~a]: ~a\n" (.name o) ((compose .elements .types) o))
  (match o
    ((? (is? <interface>)) ((compose .elements .types) o))
    (_ '())))

(define* (om:typed? o #:optional (trigger #f))
  (if trigger (om:typed? (.event trigger))
      (match o
        (($ <event>)
         (let ((type ((compose .type .signature) o)))
           (not (is-a? type <void>))))
        ((? (is? <modeling-event>)) #f)
        ((? boolean?) #f))))

(define (om:reply-enums o)
  (om:reply-types o #:pred (is? <enum>)))

(define* (om:reply-types o #:key (pred om:typed?))
  (match o
    (($ <interface>)
     (let* ((events (filter pred (om:events o)))
            (types (delete-duplicates (map (compose .type .signature) events))))
       (filter-map (om:type o) types)))
    ((or ($ <component>) ($ <foreign>))
     (delete-duplicates (append-map (compose (cut om:reply-types <> #:pred pred) .type) (ast:port* o))))
    (_ '())))

(define (om:out-formals o)
  (match o
    (($ <interface>)
     (filter om:out-or-inout? (append-map (compose .elements .formals .signature) (om:events o))))
    (_ '())))

(define (om:declarative? o)
  (or (is-a? o <declarative>)
      (and (is-a? o <compound>)
                    (>0 (length (.elements o)))
                    (om:declarative? (car (.elements o))))
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
    (and-let* ((model-file (source-file o))
               (model-file (if (string? model-file) (string->symbol model-file) model-file)))
              (eq? (basename- file) (basename- model-file)))))

(define-method (om:imported? o)
  (if (assoc 'imported? (source-properties o))
      (source-property o 'imported?)
      (let ((files (command-line:get '() '(#f))))
        (and (pair? files)
             (let ((file (car files)))
               (cond
                ((string= file "-") #f)
                ((string= file "/dev/stdin") #f)
                ((string-suffix? ".scm" file) #f)
                (else (not (in-file? o file)))))))))

(define-method (om:imported? (o <model>)) ;; FIXME
  (om:imported? (.node o)))
