;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (language asd gom util)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)

  :use-module (oop goops)
  :use-module (oop goops describe)

  :use-module (language asd gom)
  :use-module (language asd gom ast)

  :export (
           is?
           gom:component
           gom:enums
           gom:events
           gom:find-events
           gom:functions
           gom:in?
           gom:interface
           gom:member-names
           gom:member-values
           gom:out?
           gom:port
           gom:provides?
           gom:requires?
           gom:statement
           gom:statements-of-type
           gom:variable
           gom:variables
           ))

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

(define* (gom:variable ast identifier)
  (match ast
    (($ <component>) (gom:variable (apply append (map gom:variables (cons ast ((compose .elements .ports) ast)))) identifier))
    (($ <interface>) (gom:variable (gom:variables ast) identifier))
    (($ <variable>) (if (eq? (.name ast) identifier) ast #f))
    ((h ...) (and=> (null-is-#f (filter identity (map (lambda (x) (gom:variable x identifier)) ast))) car))
    (_ #f)
    (_ (throw 'match-error  (format #f "~a:gom:variable: no match: ~a\n" (current-source-location) ast)))))

(define (gom:functions ast)
  (match ast
    (($ <behaviour>) (.elements (.functions ast)))
    (($ <interface>) (append
                      (.elements (.functions ast))
                      (gom:functions (.behaviour ast))))
    (($ <component>) (.functions (.behaviour ast)))
    (($ <port>) (stderr "port: ~a\n" (.type ast))
     (gom:functions (ast->gom* (ast:ast (.type ast)))))
    (_ (throw 'match-error  (format #f "~a:gom:functions: no match: ~a\n" (current-source-location) ast)))))

(define (gom:variables ast)  ;; to be removed (.variables o)
  (match ast
    (($ <behaviour>) (.elements (or (.variables ast) (make <variables>))))
    (($ <interface>) (append
                      (.elements (or (.variables (.behaviour ast))
                                     (make <variables>)))
                      (gom:variables (.behaviour ast))))
    (($ <component>) (gom:variables (.behaviour ast)))
    (($ <port>) (gom:variables (ast->gom* (ast:ast (.type ast)))))
    (_ (throw 'match-error  (format #f "~a:gom:variables: no match: ~a\n" (current-source-location) ast)))))

(define (gom:member-names model)
  (map .name (gom:variables (.behaviour model))))

(define ((gom:member-values value) model)
  (map (lambda (x) (.value (.expression x))) (gom:variables (.behaviour model))))

(define (statement? ast)
  (member (ast-name ast) '(action assign bind call compound guard if instance on reply variable return)))

(define (gom:statement ast)
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

(define-method (gom:component (o <top>))
  #f)

(define-method (gom:component (o <list>))
  (find (is? <component>) o))

(define-method (gom:component (o <component>))
  o)

(define-method (gom:interface (o <top>))
  #f)

(define-method (gom:interface (o <list>))
  (find (is? <interface>) o))

(define-method (gom:interface (o <interface>))
  o)

(define-method (gom:port (o <component>))
  (car (filter gom:provides? (.elements (.ports o)))))

(define-method (gom:in? (o <event>))
  (eq? (.direction o) 'in))

(define-method (gom:out? (o <event>))
  (eq? (.direction o) 'out))

(define-method (gom:provides? (o <port>))
  (eq? (.direction o) 'provides))

(define-method (gom:requires? (o <port>))
  (eq? (.direction o) 'requires))

(define (gom:enums ast)
  (filter (is? <enum>) (.elements (.types ast))))

(define (gom:events ast)
  (match ast
    (($ <interface>) (.elements (.events ast)))
;;    (($ <component>) (gom:find-triggers ast))
    (($ <port>) (gom:events (ast->gom* (ast:ast (.type ast)))))
    (_ (throw 'match-error  (format #f "~a:events: no match: ~a\n" (current-source-location) ast)))))

(define ((is? class) o)
  (if (is-a? o class) o #f))

;;;; reading/caching
(define *ast-alist* '())
(define (ast-add name ast)
  (set! *ast-alist* (assoc-set! *ast-alist* name ast))
  ast)

;; procedure: ast:import MODEL-NAME
;;
;; Read and parse the ASD source file for MODEL-NAME, return its AST.
(define (read-ast model-name)
  (and-let* ((ast (null-is-#f (read-asd (->string (list 'examples '/ model-name '.asd)))))
             (models (null-is-#f (models ast))))
            (find (lambda (model) (eq? (name model) model-name)) models)))

(define* (import-ast name #:optional (transform identity))
  "
procedure: ast:import MODEL-NAME

Read and parse the ASD source file for MODEL-NAME, return its AST.

"
  (or (assoc-ref *ast-alist* name)
      (and-let* ((ast (transform (read-ast name))))
                (ast-add name ast))))
