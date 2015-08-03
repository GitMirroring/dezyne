;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014, 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag c++)
  :use-module (ice-9 curried-definitions)
  :use-module (gaiag list match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 pretty-print)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag c)
  :use-module (gaiag code)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
;;  :use-module (gaiag wfc)

  :use-module (gaiag ast)

  :export (ast->
           gen1-interfaces))

(define (ast-> ast)
  (let ((om ((om:register code:om #t) ast)))
    (map dump (filter (negate om:imported?) ((om:filter <model>) om))))
  "")

(define* ((c++:scope-join :optional (model #f) (infix (string->symbol "::"))) o)
  ((om:scope-join model infix) o))

(define* ((c++:scope-name :optional (infix (string->symbol "::"))) o)
  ((om:scope-name infix) o))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    (($ <component>) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  ((@@ (gaiag c) dump-interface) o))

(define (dump-component o)
  ((@@ (gaiag c) dump-component) o)
  (let ((name ((om:scope-name) o)))
    (if (and (not (.behaviour o))
             (map-file o))
        (dump-indented (symbol-append 'glue- name '.cc)
                       (lambda ()
                         (c++-file 'glue-bottom-component.cc.scm (code:module o)))))))

(define (dump-system o)
  ((@@ (gaiag c) dump-system) o)
  (let ((name ((om:scope-name) o)))
    (if (map-file o)
        (dump-indented (symbol-append name 'Interface.h)
                       (lambda ()
                         (c++-file 'glue-top-system-interface.hh.scm (code:module (om:interface (om:port o)))))))
    ;;(stderr "MAP: ~a [~a] ==> ~a\n" (.name o) (om:port o) (map-file o))
    (when (map-file o)
      (dump-indented (symbol-append name 'Component.h)
                    (lambda ()
                      (c++-file 'glue-top-system.hh.scm (code:module o))))
      (dump-indented (symbol-append name 'Component.cpp)
                     (lambda ()
                       (c++-file 'glue-top-system.cc.scm (code:module o)))))))

(define (c++-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
    (animate-file file-name module)))

(define (event2->interface1-event1-alist port)
  (and-let* ((string (gulp-file (find-file (map-file-name port) '(.map))))
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (map string->symbol (string-tokenize o char-set:graphic))) lst))
             (lst (filter pair? lst)))
            (fold (lambda (e r) (acons (third e) (take e 2) r)) '() lst)))

(define (assoc-xref alist value)
  (define (cdr-equal? x) (equal? (cdr x) value))
  (and=> (find cdr-equal? alist) car))

(define ((gen1-interfaces dir?) model)
  (let* ((provided
          (filter dir? ((compose .elements .events) model)))
         (alist (event2->interface1-event1-alist (.name model)))
         (gen1-provided (filter identity (map (lambda (x) (assoc (.name x) alist)) provided))))
    (if (pair? gen1-provided) (list gen1-provided) '())))

(define (map-file o)
  (and (om:port o)
       (try-find-file (map-file-name o) '(.map))))

(define (map-file-name o)
  (match o
    ((or ($ <component>) ($ <system>)) (map-file-name (om:port o)))
    (_ (om:name o)) ;; dzn::IConsole ==> IConsole.map
    (_ ((om:scope-name) o)))) ;; dzn::IConsole ==> dzn_IConsole.map
