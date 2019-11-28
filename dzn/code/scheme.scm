;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (dzn code scheme)
  #:use-module (ice-9 receive)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn command-line)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

  #:use-module (dzn ast)
  #:use-module (dzn code dzn)
  #:use-module (dzn code)
  #:use-module (dzn indent)
  #:use-module (dzn templates))

(define (scheme:namespace-setup o)
  "")

(define-method (scheme:constructor-parameters (o <component>))
  (cons "flushes? " (map .name (ast:port* o))))

(define (string->class-name o)
  (string-append "<" o ">"))

(define (string->accessor o)
  (string-append "." o))

(define-method (scheme:class-name (o <model>))
  (string-join (ast:full-name o) ":"))

(define-method (scheme:class-name (o <ast>))
  (scheme:class-name (parent o <model>)))

;; Work around a bug that base name of a Guile module cannot include
;; dots.  See http://debbugs.gnu.org/cgi/bugreport.cgi?bug=39162
(define-method (scheme:sanitize-module-name (o <string>))
  (string-map (lambda (c) (if (eq? c #\.) #\- c)) o))

(define-method (scheme:module-name (o <root>))
  (let ((dzn-file (ast:source-file o))
        (namespaces (filter (conjoin (negate ast:imported?)
                                     (negate (compose (cut equal? <> '("dzn")) ast:full-name)))
                            (ast:namespace* o))))
    (scheme:sanitize-module-name
     (if (null? namespaces) (basename dzn-file ".dzn")
         (scheme:module-name (car namespaces))))))

(define-method (scheme:module-name (o <foreign>))
  (scheme:sanitize-module-name
   (string-join (ast:full-name o) " ")))

(define-method (scheme:module-name (o <namespace>))
  (let* ((dzn-file (ast:source-file o))
         (base-name (basename dzn-file ".dzn"))
         (namespace (ast:full-name o)))
    (scheme:sanitize-module-name
     (string-join (append namespace (list base-name)) " "))))

(define-method (scheme:module-name (o <model>))
  (let* ((dzn-file (ast:source-file o))
         (base-name (basename dzn-file ".dzn"))
         (namespace (append-map (cut string-split <> #\.)
                                (drop-right (ast:full-name o) 1))))
    (scheme:sanitize-module-name
     (string-join (append namespace (list base-name)) " "))))

(define-method (scheme:names (o <interface>))
  (let* ((name (scheme:class-name o))
         (classes (map string->class-name
                       (list name
                             (string-append name ".in")
                             (string-append name ".out"))))
         (accessors (map (compose string->accessor .name) (ast:event* o))))
    (append classes accessors)))

(define-method (scheme:names (o <component-model>))
  (let* ((name (scheme:class-name o))
         (classes (list (string->class-name name)))
         (accessors (append (map (compose string->accessor .name)
                                 (ast:port* o))
                            (if (or (is-a? o <foreign>)
                                    (not (.behaviour o))) '()
                                (map (compose string->accessor .name) (ast:variable* o))))))
    (append classes accessors)))

(define-method (scheme:names (o <system>))
  (let* ((name (scheme:class-name o))
         (classes (list (string->class-name name)))
         (accessors (map (compose string->accessor .name)
                         (append (ast:port* o) (ast:instance* o)))))
    (append classes accessors)))

(define-method (scheme:imported-names (o <root>))
  (let ((imported-models (append (filter ast:imported? (ast:model* o))
                                 (code:used-foreigns o))))
    (delete-duplicates (append-map scheme:names imported-models) string=?)))

(define-method (scheme:exported-names (o <root>))
  (let ((models (append (filter (conjoin (negate ast:imported?)
                                         (negate (is? <foreign>)))
                                (ast:model* o))
                        (code:used-foreigns o))))
    (delete-duplicates (append-map scheme:names models) string=?)))

(define-method (scheme:export (o <root>))
  (let ((imports (scheme:imported-names o))
        (exports (scheme:exported-names o)))
    (partition (negate (cut member <> imports)) exports)))

(define-method (scheme:re-export (o <root>))
  (receive (export re-export) (scheme:export o)
    re-export))

(define-method (scheme:statement (o <guard>))
  (if (is-a? (.expression o) <otherwise>) (clone (make <otherwise-guard> #:expression (.expression o) #:statement (.statement o)))
      o))

(define-method (scheme:statement o)
  (dzn:statement o))

(define-method (scheme:expand-on (o <on>))
  (let ((statement (.statement o)))
    (if (and (is-a? statement <compound>) (null? (ast:statement* statement))) (make <skip>)
        statement)))

(define-method (scheme:enum-name (o <enum-literal>))
  (scheme:enum-name (.type o)))

(define-method (scheme:enum-name (o <enum>))
  (append (ast:full-name o) '("alist")))

(define-method (scheme:reply-name (o <enum>))
  (cons "reply" (append (ast:full-name o))))

(define-method (scheme:reply-name (o <int>))
  '("reply-int"))

(define-method (scheme:reply-name (o <bool>))
  '("reply-bool"))

(define-method (scheme:reply-name (o <reply>))
  (scheme:reply-name (ast:type (.expression o))))

(define-method (scheme:let-variable (o <compound>))
  (filter (is? <variable>) (ast:statement* o)))

(define-method (scheme:use-module (o <root>))
  (let* ((models (filter ast:imported? (ast:model* o)))
         (modules (map scheme:module-name models))
         (foreigns (map scheme:module-name (code:used-foreigns o)))
         (components (filter (is? <component>) (ast:model* o)))
         (pump (if (or (pair? (append-map ast:async-port* components))
                       (pair? (append-map (cut tree-collect (disjoin (is? <blocking>) (is? <blocking-compound>)) <>) components))) '("dzn pump") '())))
    (map (cut make <file-name> #:name <>) (delete-duplicates (append pump modules foreigns)))))

(define-method (scheme:use-module (o <model>))
  (scheme:use-module (parent o <root>)))

(define-method (scheme:variable/local (o <formal>))
  (if (ast:in? o) o
      (make <local> #:name (.name o) #:type.name (.type.name o))))

(define-method (scheme:variable/local (o <variable>))
  (if (code:class-member? o) o
      (make <local> #:name (.name o) #:type.name (.type.name o) #:expression (.expression o))))

(define-method (scheme:set! (o <assign>))
  (scheme:variable/local (.variable o)))

(define-method (scheme:async-req (o <port>))
  (let ((event (find (cut ast:name-equal? <> "req") (ast:event* (.type o)))))
    (make <trigger> #:port.name (.name o) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event) (parent o <model>)))))

(define-method (scheme:async-clr (o <port>))
  (let ((event (find (cut ast:name-equal? <> "clr") (ast:event* (.type o)))))
    (make <trigger> #:port.name (.name o) #:event.name (.name event) #:formals (ast:rescope ((compose .formals .signature) event)  (parent o <model>)))))

(define-templates-macro define-templates scheme)
(include-from-path "dzn/templates/dzn.scm")
(include-from-path "dzn/templates/code.scm")
(include-from-path "dzn/templates/scheme.scm")

(define (scheme:root-> root)
  (parameterize ((%language "scheme")
                 (%x:main x:main)
                 (%x:header identity)
                 (%x:source x:source)
                 (%dzn:indenter (cut indent #:open #\( #:close #\) #:no-indent "")))
    (code:root-> root)))

(define (ast-> ast)
  (let ((root (code:om ast)))
    (scheme:root-> root))
  "")
