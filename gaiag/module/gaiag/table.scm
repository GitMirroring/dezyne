;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag table)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (oop goops)

  :use-module (gaiag gaiag)
  :use-module (gaiag json-table)
  :use-module (gaiag misc)
  :use-module (gaiag normstate)
  :use-module (gaiag pretty)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)

  :use-module (gaiag gom)

  :export (ast-> state-table))

(define-method (state-table (o <list>))
  (filter identity (map state-table o)))

(define-method (state-table (o <root>))
  ;; FIXME: c&p csp.scm
  (let ((name
         (and (and=> (option-ref (parse-opts (command-line)) 'model #f)
                     string->symbol))))
    (or (and-let* ((models (null-is-#f (gom:models-with-behaviour o)))
                   (models (if name (list (find (gom:named name) models)) models))
                   (models (null-is-#f (filter has-enum? models))))
                  (map state-table models))
        (let* ((models ((gom:filter <model>) o))
               (models (comma-join (map .name models)))
               (message (if name
                            "gaiag: no model [name=~a] with behaviour: ~a\n"
                            "gaiag: no model with behaviour: ~a\n"))
               (message (format #f message name models)))
          (stderr message)
          (throw 'state message)))))

(define (has-enum? o)
  (null-is-#f (gom:enums (.behaviour o))))

(define-method (state-table (o <model>))
  (let ((statement (state-table o ((compose .statement .behaviour) o))))
    (make (class-of o)
      :name (.name o)
      :behaviour
      (make <behaviour>
        :name ((compose .name .behaviour) o)
        :statement statement))))

(define-method (state-table (o <imports>))
  #f)

(define-method (state-table (model <model>) (o <boolean>)) #f)

(define-method (state-table (model <model>) (o <compound>))
  (or (and-let* ((types ((compose .elements .types .behaviour) model))
                 (enum (find (is? <enum>) types))
                 (fields ((compose .elements .fields) enum))
                 (states (map (lambda (field)
                                (make <literal>
                                  :type (.name enum)
                                  :field field)) fields))
                 (guards (filter identity
                                 (map (lambda (state)
                                        (state-table model state o))
                                      states))))
                (make <compound> :elements guards))
      o))

(define-method (state-table (model <model>) (state <literal>) (o <compound>))
  (and-let* ((statement (flatten-compound (evaluate model state o))))
            (make <guard>
              :expression (make <expression> :value (field model state))
              :statement statement)))

(define-method (field (model <model>) (state <literal>))
  (define (type? v) (eq? ((compose .name .type) v)) (.type state))
  (let ((var (find type? (gom:variables model))))
    (make <field> :identifier (.name var) :field (.field state))))

(define-method (evaluate (model <model>) (state <literal>) o)
  (match o
    (($ <compound> statements)
     (let* ((statements
             (let loop ((statements (.elements o)))
               (if (null? statements)
                   '()
                   (let* ((statement (annotate-otherwise o (car statements)))
                          (statement (evaluate model state statement)))
                     (if statement
                         (cons statement (loop (cdr statements)))
                         (loop (cdr statements))))))))

       (cond
        ((null? statements) #f)
        ((=1 (length statements)) (car statements))
        (else (make <compound> :elements statements)))))

    (($ <guard> expression ($ <on> triggers statement))
     (and-let*
      ((guard (make <guard> :expression expression :statement statement))
       (guard (evaluate model state guard)))
      (make <on> :triggers triggers :statement guard)))

    (($ <guard> expression statement)
     (and-let* ((value (eval-expression model state expression))
                (expression (if (is-a? value <otherwise>)
                                value
                                (make <expression> :value value)))
                (statement (evaluate model state statement)))
               (match value
                 (#t statement)
                 (($ <literal>) (and (equal? value state) statement))
                 (_ (make <guard> :expression expression :statement statement)))))

    (($ <on> triggers ($ <guard> expression statement))
     (and-let* ((guard (.statement o))
                (statement (evaluate model state guard)))
               (make <on> :triggers triggers :statement statement)))

    (($ <on> triggers statement)
     (and-let* ((statement (evaluate model state statement)))
               (make <on> :triggers triggers :statement statement)))

    (_ (stderr "ignoring:") (pretty-print (gom->list o) (current-error-port))
     o)))

(define-method (annotate-otherwise (o <compound>) (guard <guard>))
  (and-let* ((guards ((gom:filter <guard>) (.elements o)))
             (expression (.expression guard))
             ((is-a? expression <otherwise>))
             (value (.value (guards-not-or guards))))
            (set! (.value (.expression guard)) value))
  guard)

(define-method (annotate-otherwise (o <compound>) (statement <statement>))
  statement)

(define-method (eval-expression (model <model>) (state <literal>) o)

  (define (type? identifier) (and-let* ((var (gom:variable model identifier)))
                                       (eq? ((compose .name .type) var)
                                            (.type state))))

  (match o

    (($ <expression> expression) (eval-expression model state expression))

    (($ <otherwise> expression)
     (let ((value (eval-expression model state expression)))
       (match value
         (#t #t)
         (#f #f)
         (_ o))))

    (($ <literal>) o)

    (($ <field> (? type?) field)
     (eq? field (.field state)))

    (($ <field>) o)

    (('== lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (or (equal? lhs rhs)
           (if (and (is-a? lhs <literal>) (is-a? rhs <literal>))
               #f
               (list '== lhs rhs)))))

    (('!= lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (or (not (equal? lhs rhs))
           (list '!= lhs rhs))))

    (('and lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (and lhs rhs (cond
                     ((and (eq? lhs #t) (eq? rhs #t)) #t)
                     ((eq? lhs #t) rhs)
                     ((eq? rhs #t) lhs)
                     (else (list 'and lhs rhs))))))

    (('or lhs rhs)
     (let ((lhs (eval-expression model state lhs))
           (rhs (eval-expression model state rhs)))
       (and (or lhs rhs) (cond
                          ((or (eq? lhs #t) (eq? rhs #t)) #t)
                          ((equal? (list '! lhs) rhs) #t)
                          ((equal? (list '! rhs) lhs) #t)
                          ((eq? lhs #f) rhs)
                          ((eq? rhs #f) lhs)
                          (else (list 'or lhs rhs))))))

    (('! expression)
     (let ((expression (eval-expression model state expression)))
       (cond
        ((eq? expression #t) #f)
        ((eq? expression #f) #t)
        (else (list '! expression)))))

    (('group expression)
     (let ((expression (eval-expression model state expression)))
       (cond
        ((eq? expression #t) #t)
        ((eq? expression #f) #f)
        (else (list 'group expression)))))

    (($ <var> (? type?)) state)

    (($ <var>) o)

    ('false #f)
    ('true #t)

    (_ (stderr "eval-expression: TODO: ~a\n" o) o)))

(define-method (equal? (lhs <literal>) (rhs <literal>))
  (and (eq? (.scope lhs) (.scope rhs))
       (eq? (.type lhs) (.type rhs))
       (eq? (.field lhs) (.field rhs))))

(define-method (equal? (lhs <field>) (rhs <field>))
  (and (eq? (.identifier lhs) (.identifier rhs))
       (eq? (.field lhs) (.field rhs))))

(define-method (equal? (lhs <var>) (rhs <var>))
  (eq? (.name lhs) (.name rhs)))

(define-method (mangle-table (o <list>))
  (map mangle-table o))

(define-method (mangle-table (o <model>))
  (let ((json? (option-ref (parse-opts (command-line)) 'json #f))
        (statement ((compose .statement .behaviour) o)))
    (if json?
        (alist->hash-table
         (append
          (json-init o)
          (json-table statement)))
        (demo-table statement))))

(define-method (demo-table (o <compound>))
  (gom:map demo-table o))

(define-method (demo-table (o <list>))
  (map demo-table o))

(define-method (demo-table (o <guard>))
  o)

(define-method (demo-table (o <on>))
  o)

(define-method (pretty (o <ast>)) (ast->asd o))
(define-method (pretty (o <list>))
  (match o
    (((? (is? <ast>)) ...) (string-join (map ast->asd o)))
    (_ o)))
(define-method (pretty o) o)

(define (ast-> ast)
  ((compose
    pretty
    mangle-table
    state-table ast:resolve) ast))
