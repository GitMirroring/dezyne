;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014, 2015, 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
  :use-module (srfi srfi-26)
  :use-module (ice-9 curried-definitions)
  :use-module (gaiag list match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 getopt-long)
  :use-module (ice-9 pretty-print)
  :use-module (ice-9 receive)
  :use-module (srfi srfi-1)

  :use-module (gaiag animate)
  :use-module (gaiag c)
  :use-module (gaiag code)
  :use-module (gaiag gaiag)
  :use-module (gaiag indent)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve)
;;  :use-module (gaiag wfc)

  :use-module (gaiag om)

  :export (ast->
           asd-interfaces))

(define (ast-> ast)
  (let ((om ((om:register code:om #t) ast)))
    (map dump (filter (negate om:imported?) ((om:filter <model>) om))))
  "")

(define* ((c++:scope-join :optional (model #f) (infix (string->symbol "::"))) o)
  ((om:scope-join model infix) o))

(define* ((c++:scope-name :optional (infix (string->symbol "::"))) o)
  ((om:scope-name infix) o))

(define (c++:init-brace-open) "{")
(define (c++:init-brace-close) "}")

(define (c++:skel-file model)
  ((->symbol-join '_) (append (drop-right (om:scope+name model) 1) '(skel) (take-right (om:scope+name model) 1))))

(define (glue)
  (and=> (option-ref (parse-opts (command-line)) 'glue #f) string->symbol))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    (($ <component>) (dump-component o))
    (($ <system>) (dump-system o))))

(define (dump-interface o)
  ((@@ (gaiag c) dump-interface) o))

(define (dump-component o)
  (if (and (glue)
           (eq? (glue) 'asd)
           (map-file o))
      ;; TODO: asd glue templates
      (let ((name ((om:scope-name) o)))
        (dump-indented (symbol-append name '.hh)
                       (lambda ()
                         (c++-file 'asd.hh.scm (code:module o))))
        (dump-indented (symbol-append name '.cc)
                       (lambda ()
                         (c++-file 'asd.cc.scm (code:module o))))
        ((@@ (gaiag c) dump-main) o)
        (for-each (lambda (port)
                    (let* ((module (code:module o))
                           (interface (symbol-drop (last (.type port)) 1))
                           (INTERFACE (symbol-upcase interface)))
                      (module-define! module '.interface interface)
                      (module-define! module '.INTERFACE INTERFACE)
                      (dump-indented (symbol-append interface 'Component.h)
                                     (cute c++-file 'asdcomponent.h.scm module))))
                  (filter om:requires? (om:ports o))))
      (let ((name (if (.behaviour o) ((om:scope-name) o) (c++:skel-file o)))
            (interfaces (map code:import (map .type ((compose .elements .ports) o)))))
        ((@@ (gaiag c) dump-main) o)
        (dump-indented (symbol-append name (code:extension (make <interface>)))
                       (cute c++-file (if (.behaviour o) 'component.hh.scm 'foreign.hh.scm) (code:module o)))
        (dump-indented (symbol-append name (code:extension o))
                       (cute c++-file (if (.behaviour o) 'component.cc.scm 'foreign.cc.scm) (code:module o)))
        ;; TODO: rename dzn glue templates
        (if (and (not (.behaviour o))
                 (map-file o))
            (dump-indented (symbol-append 'glue- name '.cc)
                           (lambda ()
                             (c++-file 'glue-bottom-component.cc.scm (code:module o))))))))

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

(define (event2->interface1-event1-alist- string)
  (and-let* ((string string)
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (map string->symbol (string-tokenize o char-set:graphic))) lst))
             (lst (filter pair? lst)))
            (fold (lambda (e r) (acons (third e) (take e 2) r)) '() lst)))

(define (event2->interface1-event1-alist port)
  (event2->interface1-event1-alist-
   (gulp-file (find-file (map-file-name port) '(.map)))))

(define (assoc-xref alist value)
  (define (cdr-equal? x) (equal? (cdr x) value))
  (and=> (find cdr-equal? alist) car))

(define ((asd-interfaces dir?) model)
  (let* ((provided
          (filter dir? ((compose .elements .events) model)))
         (alist (event2->interface1-event1-alist (.name model)))
         (asd-provided (filter identity (map (lambda (x) (assoc (.name x) alist)) provided))))
    (if (pair? asd-provided) (list asd-provided) '())))

(define (map-file o)
  (and (om:port o)
       (try-find-file (map-file-name o) '(.map))))

(define (map-file-name o)
  (match o
    ((or ($ <component>) ($ <system>)) (map-file-name (om:port o)))
    (_ (om:name o)) ;; dzn::IConsole ==> IConsole.map
    (_ ((om:scope-name) o)))) ;; dzn::IConsole ==> dzn_IConsole.map

;;(define mapping->asd-interface second)
(define (string->mapping string)
  (and-let* ((string string)
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (map string->symbol (string-tokenize o char-set:graphic))) lst))
             (lst (filter pair? lst)))
            lst ;;            (fold (lambda (e r) (acons (third e) (take e 2) r)) '() lst)
            ))

(define (mapping->channel mapping)
  (let loop ((lst mapping))
    (if (null? lst) '()
        (let ((channel (caar lst)))
          (receive (same rest)
              (partition (lambda (m) (eq? (car m) channel)) lst)
            (append (list (cons (caar same) (map cdr same))) (loop rest)))))))

(define* ((stderr-identity :optional (identifier "#")) o) (stderr "~a:~a\n" identifier o) o)
(define (port->mapping-list port)
  ((compose
    mapping->channel
    string->mapping
    gulp-file
    (cut find-file <> '(.map)))
   (map-file-name port)))

(define ((event->formals interface) event)
   ((compose .formals .signature) (om:event interface event)))

(define ((event->formals-code interface) event)
   (code:->code interface ((event->formals interface) event)))

(define ((event->asd-formals-code interface) event)
   ((->join ", ") (map (lambda (f) (->string (list  (if (om:in? f) "const " "") "asd::value<" (code:->code interface (.type f)) ">::type&" (code:->code interface (.name f))))) (.elements ((event->formals interface) event)))))

(define ((event->arguments-code interface) event)
   ((->join ", ") (map .name (.elements ((event->formals interface) event)))))

(define (c++:out-var-decls model formal-objects)
  (map (lambda (f i)
         (if (member (.direction f) '(inout out))
             (list (->code model (.type f)) " _" i "; ")))
       formal-objects (iota (length formal-objects))))

(define (c++:out-param-list model formal-objects)
  ((->join ",")
   (map (lambda (f i)
          (if (member (.direction f) '(inout out))
              (list "_" i)
              (list (->code model (.type f)) "()")))
        formal-objects (iota (length formal-objects)))))
