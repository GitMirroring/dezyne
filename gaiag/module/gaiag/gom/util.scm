;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag gom util)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (system foreign)
  :use-module (srfi srfi-1)

  :use-module (gaiag ast:)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (gaiag gom ast)
  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)

  :export (
           is?
           gom->list
           gom:booleans
           gom:bottom?
           gom:component
           gom:components
           gom:declarative?
           gom:dir-matches?
           gom:enums
           gom:event
           gom:events
           gom:filter
           gom:find-events
           gom:function
           gom:functions
           gom:import
           gom:instance
           gom:in?
           gom:integers
           gom:interface
           gom:interfaces
           gom:member-names
           gom:member-values
           gom:name ;; REMOVEME
           gom:out?
           gom:parent
           gom:parse-asd
           gom:port
           gom:provides?
           gom:requires?
           gom:register
           gom:statement
           gom:statements-of-type
           gom:system
           gom:typed?
           gom:variable
           gom:variables
           ))

(define ((is? class) o)
  (if (is-a? o class) o #f))

(define (gom->list gom)
  (with-input-from-string
      (with-output-to-string (lambda () (write gom)))
    read))

(define-method (gom:filter (predicate <top>) (o <ast-list>))
  (filter predicate (.elements o)))

(define-method (gom:filter (predicate <top>) (o <list>))
  (filter predicate o))

(define-method (gom:filter (predicate <procedure>))
  (lambda (o) (gom:filter predicate o)))

(define-method (gom:filter (predicate <top>))
  (lambda (o) (gom:filter predicate o)))

(define-method (gom:filter (class <class>))
  (lambda (o) (gom:filter (is? class) o)))

(define-method (gom:trigger< (lhs <trigger>) (rhs <trigger>))
  (if (and (not (.port lhs)) (not (.port rhs)))
      (symbol< (.event lhs) (.event rhs))
      (if
       (and (symbol? (.port lhs)) (symbol? (.port rhs))
            (list< (list (.port lhs) (.event lhs))
                   (list (.port rhs) (.event rhs))))
       (not (symbol? (.port lhs))))))

(define* (gom:find-events ast :optional (found '()))
  "Search for optional and inevitable."
  (match ast
    ((or ($ <interface>) ($ <component>))
     (delete-duplicates (sort (gom:find-events (gom:statement (.behaviour ast))) gom:trigger<)))
    (($ <compound>) (append (apply append (map gom:find-events (.elements ast))) found))
    (($ <on>) (gom:find-events (.triggers ast)))
;;    (($ <trigger>) (list ast))
    (($ <triggers>) (.elements ast))
    (($ <guard>) (gom:find-events (.statement ast) found))
    (('inevitable) ast)
    (('optional) ast)
    (('action x) '())
    (('illegal) '())
    (_ (throw 'match-error  (format #f "~a:gom:find-events: no match: ~a\n" (current-source-location) ast)))))

(define* (gom:variable ast identifier)   ;; use SYMBOL TABLE
  (match ast
    (($ <component>) (gom:variable (apply append (map gom:variables (cons ast ((compose .elements .ports) ast)))) identifier))
    (($ <interface>) (gom:variable (gom:variables ast) identifier))
    (($ <variable>) (if (eq? (.name ast) identifier) ast #f))
    ((h ...) (and=> (null-is-#f (filter identity (map (lambda (x) (gom:variable x identifier)) ast))) car))
    (_ #f)
    (_ (throw 'match-error  (format #f "~a:gom:variable: no match: ~a\n" (current-source-location) ast)))))

(define (gom:functions ast)  ;; REMOVEME
  (match ast
    (($ <behaviour>) (.elements (.functions ast)))
    (($ <interface>) (append
                      (.elements (.functions ast))
                      (gom:functions (.behaviour ast))))
    (($ <component>) (.functions (.behaviour ast)))
    (($ <port>) (stderr "port: ~a\n" (.type ast))
     (gom:functions (gom:import (.type ast) ast->gom)))
    (_ (throw 'match-error  (format #f "~a:gom:functions: no match: ~a\n" (current-source-location) ast)))))

(define (gom:function ast identifier)  ;; use SYMBOL TABLE
  (find (lambda (f) (eq? (.name f) identifier))
        (match ast
          (($ <functions>) (.elements ast))
          (($ <component>) (.elements (.functions (.behaviour ast))))
          (($ <interface>) (.elements (.functions (.behaviour ast))))
          (_ (throw 'match-error  (format #f "~a:gom:function: no match: ~a\n" (current-source-location) ast))))))

(define (gom:variables ast)  ;; REMOVEME
  (match ast
    (($ <behaviour>) (.elements (or (.variables ast) (make <variables>))))
    (($ <interface>) (gom:variables (.behaviour ast)))
    (($ <component>) (gom:variables (.behaviour ast)))
    (($ <port>) (gom:variables (gom:import (.type ast) ast->gom)))
    (_ (throw 'match-error  (format #f "~a:gom:variables: no match: ~a\n" (current-source-location) ast)))))

(define (gom:member-names model)  ;; SYMBOL TABLE
  (map .name (gom:variables (.behaviour model))))

(define (gom:member-values model)  ;; SYMBOL TABLE
  (map (lambda (x) (.value (.expression x))) (gom:variables (.behaviour model))))

(define (statement? ast)  ;; REMOVEME
  (member (ast-name ast) '(action assign bind call compound guard if instance on reply variable return)))

(define (gom:statement ast) ;; REMOVEME
  (match ast
    ((? ast:system?) (or (find (lambda (x) (is-a? x <compound>)) (ast:body ast))))
    (($ <model>) (gom:statement (.behaviour ast)))
    (($ <behaviour>) (or (.statement ast) (make <compound>)))
    (($ <function>) (.statement ast))
    (_ (throw 'match-error  (format #f "~a:gom:statement: no match: ~a\n" (current-source-location) ast)))))

(define ((gom:statement-of-type type) statement)
  (eq? (ast-name statement) type))

(define ((gom:statements-of-type type) statement)
  (match statement
    ((? (gom:statement-of-type type)) (list statement))
    (($ <compound>) (filter identity (apply append (map (gom:statements-of-type type) (.elements statement)))))
    ((? (is? <statement>)) '())
    (_ (throw 'match-error  (format #f "~a:gom:statements-of-type, type: ~a: no match: ~a\n" (current-source-location) type statement)))))

(define (gom:typed? ast)
  (match ast
    (($ <event>) (not (equal? (.type (.type ast)) '(type void))))
    (($ <port>) (null-is-#f (filter (lambda (x) (gom:typed? x)) (gom:events ast))))
    (_ (throw 'match-error  (format #f "~a:gom:typed?: no match: ~a\n" (current-source-location) ast)))))

(define-method (gom:dir-matches? (p <port>) (e <event>))
  (or (and (eq? (.direction p) 'provides)
           (eq? (.direction e) 'in))
      (and (eq? (.direction p) 'requires)
           (eq? (.direction e) 'out))))

(define-method (gom:dir-matches? (o <port>))
  (lambda (event) (gom:dir-matches? o event)))

(define-method (gom:event (o <interface>) name)
  (find (lambda (x) (eq? (.name x) name)) (.elements (.events o))))

(define-method (gom:component (o <top>)) #f)
(define-method (gom:component (o <component>)) o)
(define-method (gom:component (o <list>)) (find (is? <component>) o))
(define-method (gom:component (o <ast-list>))
  (find (is? <component>) (.elements o)))

(define-method (gom:interface (o <top>)) #f)
(define-method (gom:interface (o <interface>)) o)
(define-method (gom:interface (o <list>)) (find (is? <interface>) o))
(define-method (gom:interface (o <ast-list>))
  (find (is? <interface>) (.elements o)))

(define-method (gom:system (o <top>)) #f)
(define-method (gom:system (o <system>)) o)
(define-method (gom:system (o <list>)) (find (is? <system>) o))
(define-method (gom:system (o <ast-list>))
  (find (is? <system>) (.elements o)))

(define-method (gom:port (o <component>))
  (car ((gom:filter gom:provides?) (.ports o))))

(define-method (gom:port (o <component>) (name <symbol>))
  (find (lambda (p) (eq? (.name p) name)) (.elements (.ports o))))

(define-method (gom:port (o <system>))
  (car (filter gom:provides? (.elements (.ports o)))))

(define-method (gom:port (o <system>) (name <symbol>))
  (or (find (lambda (p) (eq? (.name p) name)) (.elements (.ports o)))))

(define-method (gom:port (o <system>) (bind <binding>))
  (or (gom:port o (.port bind))
      (let ((instance (gom:instance o (.instance bind))))
        (if (eq? (.instance bind) (.port bind))
            (make <port> :name (.port bind))
            (gom:port (gom:import (.type instance)) (.port bind))))))

(define-method (gom:instance (o <system>) (name <boolean>))
  (make <instance> :name name :type 'Foobar))

(define-method (gom:instance (o <system>) (name <symbol>))
  (or (find (lambda (i) (eq? (.name i) name)) ((compose .elements .instances) o))
      (make <instance> :name name :type 'Foobar)))

(define-method (gom:instance (o <system>) (bind <binding>))
  (gom:instance o (.instance bind)))

(define-method (gom:in? (o <event>))
  (eq? (.direction o) 'in))

(define-method (gom:out? (o <event>))
  (eq? (.direction o) 'out))

(define-method (gom:provides? (o <port>))
  (eq? (.direction o) 'provides))

(define-method (gom:requires? (o <port>))
  (eq? (.direction o) 'requires))

(define (gom:booleans o)
  '())

(define (gom:enums o)
  (filter (is? <enum>) (.elements (.types o))))

(define (gom:integers ast)
  (filter (is? <int>) (.elements (.types ast))))

(define (gom:enums o)
  ((gom:filter <enum>) (.types o)))

(define-method (gom:model (o <component>)) o)
(define-method (gom:model (o <interface>)) o)
(define (gom:models o) ((gom:filter <model>) o))
(define (gom:components o) ((gom:filter <component>) o))
(define (gom:interfaces o) ((gom:filter <interface>) o))

(define* (gom:events ast)
  (match ast
    (($ <interface>) (.elements (.events ast)))
    (($ <port>) (gom:events (ast->gom (gom:import (.type ast)))))
    (_ (throw 'match-error  (format #f "~a:events: no match: ~a\n" (current-source-location) ast)))))

(define-method (gom:bottom? (o <component>))
  (and-let* ((ports ((compose .elements .ports) o))
             ((=1 (length ports))))
            (gom:provides? (car ports))))

(define-method (gom:bottom? (o <interface>)) #f)

(define-method (gom:bottom? (o <system>)) #t)

;;;; reading/caching
(define *ast-alist* '())

(define (cached-model name)
  (assoc-ref *ast-alist* name))

(define-method (cache-model name (o <model>))
  (set! *ast-alist* (assoc-set! *ast-alist* name o))
  o)

(define-method (register-model (o <model>))
   (if (not (cached-model (.name o)))
      (cache-model (.name o) o))
  o)

(define* ((gom:register transform) ast :optional (clear? #f))
  (if clear?
    (set! *ast-alist* '()))
  (let ((gom (transform ast)))
    (for-each register-model (gom:models gom))
    gom))

(define* (read-ast name #:optional (transform (compose ast->gom ast:resolve)))
  (and-let* ((ast (null-is-#f (read-asd (list name '.asd) (gom:register transform))))
             (models (null-is-#f (gom:models ast))))
            (find (lambda (model) (eq? (.name model) name)) models)))

(define* (gom:import name #:optional (transform (compose ast->gom ast:resolve)))
  (or (cached-model name)
      (and-let* ((ast (read-ast name transform)))
                (cache-model name ast))))

(define* (gom:parse-asd string :optional (register (gom:register (compose ast->gom ast:resolve))))
  (parse-asd string register))

(define-method (gom:declarative? (o <statement>)) #f)
(define-method (gom:declarative? (o <on>)) #t)
(define-method (gom:declarative? (o <guard>)) #t)

(define-method (gom:id (o <top>)) ((compose pointer-address scm->pointer) o))

(define-method (gom:parent (o <top>) (t <top>)) #f)

(define-method (gom:parent (o <ast>) (t <ast>)) #f)

(define-method (gom:parent (o <ast-list>) (t <ast>))
  (if (member (gom:id t) (map gom:id (.elements o)))
      o
      (let loop ((elements (.elements o)))
        (if (null? elements)
            #f
            (let ((parent (gom:parent (car elements) t)))
              (if parent parent
                  (loop (cdr elements))))))))

(define-method (gom:parent (o <model>) (t <ast>))
  (gom:parent ((compose .statement .behaviour) o) t))

(define-method (gom:parent (o <guard>) (t <ast>))
  (or (and (eq? (.expression o) t) o)
      (and (eq? (gom:id (.expression o)) (gom:id t)) o)
      (gom:parent (.statement o) t)))

(define-method (gom:parent (o <on>) (t <ast>))
  (gom:parent (.statement o) t))

(define (gom:name type) (cadr type)) ;; REMOVEME
