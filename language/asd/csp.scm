;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014  Rutger van Beusekom
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (language asd csp)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (srfi srfi-1)

  :use-module (language asd animate)
  :use-module (language asd ast)
  :use-module (language asd c++)
  :use-module (language asd misc)
  :use-module (language asd format-keys)
  :use-module (language asd snippets)
  :export (asd->))

(define *ast* '())

(define (asd-> ast)
  (set! *ast* ast)
  (module-define! (resolve-module '(language asd csp)) 'ast ast)  ;; FIXME
  (module-define! (resolve-module '(language asd c++)) 'ast ast)  ;; FIXME
  (and-let* ((comp (component ast))
             (name (component-name comp)))
            (animate-file 'templates/component.csp.scm (list name '.csp) (csp-module ast)))
  "")

(define (csp-module ast)
  (let ((module (make-module 31 (list 
                                 (resolve-module '(ice-9 match))
                                 (resolve-module '(language asd ast))
                                 (resolve-module '(language asd c++))
                                 (resolve-module '(language asd csp))))))
    (module-define! module 'ast ast)
    (and-let* ((comp (component ast)))
              (module-define! module '.component (component-name comp))
	      (module-define! module '.interface (interface-name (interface ast)))
	      (module-define! module '.behaviour (behaviour-name (component-behaviour comp)))
              (module-define! module '.interface-behaviour (behaviour-name (interface-behaviour (interface ast))))
	      (module-define! module '.port (port-name (component-provides comp))))
    module))

(define (map-guards string guards)
  (map (lambda (guard)
         (let ((module (csp-module *ast*)))
           (module-define! module 'guard guard)
           (module-define! module '*guard-def* guard)

           ;;; FIXME
           (module-define! (resolve-module '(language asd csp)) '*guard* (lambda () (guard-name guard)))
           (module-define! (resolve-module '(language asd csp)) '*guard-def* guard)
           (animate-string string module))) guards))


(define (symbol< a b) (string< (symbol->string a) (symbol->string b)))
(define-public (flatten x)
  "Unnest list."
  (let loop ((x x) (tail '()))
    (cond ((list? x) (fold-right loop tail x))
          ((not (pair? x)) (cons x tail))
          (else (loop (car x) (loop (cdr x) tail))))))

(define-public (unique lst)
  "Uniq @var{lst}, assuming that it is sorted.  Uses @code{equal?}
for comparisons."

  (reverse!
   (fold (lambda (x acc)
           (if (null? acc)
               (list x)
               (if (equal? x (car acc))
                   acc
                   (cons x acc))))
         '() lst) '()))

(define (->join lst infix) (string-join (map ->string lst) infix))
(define (pipe-join lst) (->join lst " | "))

(define (event-names ports)
  (let loop ((ports ports) (events '()))
    (if (null? ports)
        events
        (loop (cdr ports) (append events (map port-name (port-events (car ports))))))))
