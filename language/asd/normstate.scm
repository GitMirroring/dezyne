;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(read-set! keywords 'prefix)

(define-module (language asd normstate)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (ice-9 match)
  :use-module (ice-9 curried-definitions)

  :use-module (srfi srfi-1)

  :use-module (language asd ast:)
  :use-module (language asd misc)
  :use-module (language asd pretty)
  :use-module (language asd reader)
  :use-module (language asd scheme)

  :export (ast-> normstate))

(define (normstate ast)
  (aggregate-on-stats (flatten-compound (combine-guards (passdown-on ((remove-otherwise '()) (add-skip (expand-on ast))))))))
(define ast-> normstate)


(define (expand-on ast)
  (match ast
    (('compound s ...) (ast:make 'compound (apply append (map expand-on-stat (cdr ast)))))
    ((h ...) (map expand-on ast))
    (_ ast)))

(define (expand-on-stat ast)
  (match ast
    (('on triggers statement) (map (lambda (trigger) (ast:make 'on (list trigger) statement)) triggers))
    (_ (list (expand-on ast)))))

(define (add-skip ast)
  (match ast 
    (('compound) (list 'skip))
    ((h ...) (map add-skip ast))
    (_ ast)))

(define (wrap-compound-as-needed x)
  (if (or (null? x) (>1 (length x)))
      (ast:make 'compound x)
      (car x)))

(define (aggregate-on-stats ast)
; vind alle ons met matching guards
; duw alle ons binnen de eerste guard en discard de rest
  (match ast
    (('compound ('on events stat) ...) ast)
    (('compound guards ...)
     (ast:make 'compound
               (reverse
                (let loop ((guards guards))
                  (if ( null? guards)
                      '()
                      (receive (shared-guards remainder)
                          (partition (lambda (x) (ast:guard-equals? (car guards) x)) guards)
                        (let* ((expression (ast:expression (car shared-guards)))
                               (aggregated-guard (ast:make 'guard expression
                                                           (wrap-compound-as-needed (map ast:statement shared-guards)))))
                          (cons aggregated-guard (loop remainder)))))))))
    (('functions f ...) ast)
    ((h ...) (map aggregate-on-stats ast))
    (_ ast)))

(define (flatten-compound ast)
  (match ast
    (('compound s ...) (ast:make 'compound (apply append (map flatten-compound-stat (cdr ast)))))
    (('on t s) ast)
    ((h ...) (map flatten-compound ast))
    (_ ast)))

(define (flatten-compound-stat stat)
   (let ((res (flatten-compound stat)))
     (match res
       (('compound s ...) (cdr res))
       (_ (list res)))))

(define (guards-not-or statements)
  (let ((guards (map cadr (cdr statements))))
    (list '! (reduce (lambda (g0 g1) (list 'or g0 g1)) '() (delete 'otherwise guards)))))

(define ((remove-otherwise statements) ast)
  (match ast
    (('guard 'otherwise s) (ast:make 'guard (guards-not-or statements) ((remove-otherwise '()) s)))
    (('compound s ...) (ast:make 'compound (map (remove-otherwise ast) (cdr ast))))
    ((h ...) (map (remove-otherwise statements) ast))
    (_ ast)))

 (define (combine-guards ast)
  (match ast
    (('guard guard statement) ((passdown-guard guard) statement))
    ((h ...) (map combine-guards ast))
    (_ ast)))

(define ((passdown-guard guard) statement)
  (match statement
    (('compound s ...) (ast:make 'compound (map (passdown-guard guard) (cdr statement))))
    (('guard g s) ((passdown-guard (list 'and guard g)) s))
    (_ (ast:make 'guard guard statement))))

(define (passdown-on ast)
  (match ast
    (('on triggers statement) ((passdown-triggers triggers) statement)) ; match on
    ((h ...) (map passdown-on ast))                                     ; match any list
    (_, ast)))                                                          ; match anything

(define ((passdown-triggers triggers) statement)
  (match statement
    (('compound ('guard g s) ...) (ast:make 'compound (map (passdown-triggers triggers) (cdr statement))))
    (('guard g s) (ast:make 'guard g ((passdown-triggers triggers) s)))
    (_ (ast:make 'on triggers statement))))
