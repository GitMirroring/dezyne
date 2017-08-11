;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag deprecated c++)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)
  #:use-module (srfi srfi-1)

  #:use-module (gaiag animate)
  #:use-module (gaiag c)
  #:use-module (gaiag animate-code)
  #:use-module (gaiag code)
  #:use-module (gaiag command-line)
  #:use-module (gaiag indent)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast2om)
  #:use-module (gaiag om)

  #:use-module (language dezyne location)

  #:export (c++-file
            dump-system-glue
            asd-interfaces))

(define (dump-system-glue o)
  (let ((name (om:name o)))
    (dump-indented (symbol-append name 'Component.h)
                   (lambda ()
                     (c++-file 'glue-top-system.hh.scm (code:module o))))
    (dump-indented (symbol-append name 'Component.cpp)
                   (lambda ()
                     (c++-file 'glue-top-system.cc.scm (code:module o))))))

(define (dzn-async? o)
  (or (gaiag-dzn-async? o)
      (generator-dzn-async? o)))

(define (gaiag-dzn-async? o)
  (equal? ((compose .scope .name) o) '(dzn async)))

(define (generator-dzn-async? o)
  (let* ((name (.name o))
         (scope (.scope name)))
    (and (pair? scope)
         (eq? (car scope) 'dzn)
         (symbol-prefix? 'async (.name name)))))

(define* ((c++:scope-join #:optional (model #f) (infix (string->symbol "::"))) o)
  ((om:scope-join model infix) o))

(define* ((c++:scope-name #:optional (infix (string->symbol "::"))) o)
  ((om:scope-name infix) o))

(define (c++:init-brace-open) "{")
(define (c++:init-brace-close) "}")

(define (c++:skel-file model)
  ((->symbol-join '_) (append (drop-right (om:scope+name model) 1) '(skel) (take-right (om:scope+name model) 1))))

(define (dump o)
  (match o
    (($ <interface>) (dump-interface o))
    ((or ($ <component>) ($ <foreign>)) (dump-component o))
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
      (let ((name ((om:scope-name) o))
            (skel-name (if (is-a? o <foreign>) (c++:skel-file o) ((om:scope-name) o)))
            (interfaces (map .type ((compose .elements .ports) o))))
        ((@@ (gaiag c) dump-main) o)
        (dump-indented (symbol-append skel-name (code:extension (make <interface>)))
                       (cute c++-file (if (is-a? o <foreign>) 'foreign.hh.scm 'component.hh.scm) (code:module o)))
        (dump-indented (symbol-append skel-name (code:extension o))
                       (cute c++-file (if (is-a? o <foreign>) 'foreign.cc.scm 'component.cc.scm) (code:module o)))
        ;; TODO: rename dzn glue templates
        (when (and (is-a? o <foreign>) (map-file o))
            (dump-indented (symbol-append name '.hh)
                           (lambda ()
                             (c++-file 'glue-bottom-component.hh.scm (code:module o))))
            (dump-indented (symbol-append name '.cc)
                           (lambda ()
                             (c++-file 'glue-bottom-component.cc.scm (code:module o))))))))

(define (c++-file file-name module)
  (parameterize ((template-dir (append (prefix-dir) `(templates ,(language)))))
    (code:animate-file file-name module)))

(define (event2->interface1-event1-alist- string)
  (and-let* ((string string)
             (lst (string-split string #\newline))
             (lst (filter (lambda (x) (not (string-prefix? "//" x))) lst))
             (lst (map (lambda (o) (map string->symbol (string-tokenize o char-set:graphic))) lst))
             (lst (filter pair? lst)))
            (fold (lambda (e r) (acons (third e) (take e 2) r)) '() lst)))

(define (event2->interface1-event1-alist port)
  (event2->interface1-event1-alist-
   ((compose gulp-file map-file) port)))

(define (assoc-xref alist value)
  (define (cdr-equal? x) (equal? (cdr x) value))
  (and=> (find cdr-equal? alist) car))

(define ((asd-interfaces dir?) model)
  (let* ((provided
          (filter dir? ((compose .elements .events) model)))
         (alist (event2->interface1-event1-alist (.name model)))
         (asd-provided (filter identity (map (lambda (x) (assoc (.name x) alist)) provided))))
    (if (pair? asd-provided) asd-provided '())))

(define (map-file o)
  (let* ((files (command-line:get '() '()))
         (map-files (filter (cut string-suffix? ".map" <>) files))
         (map-file-name (string-append (symbol->string (map-file-name o)) ".map"))
         (map-files (if (pair? map-files) map-files (list map-file-name))))
    (and=> (find (lambda (f) (equal? (basename f) map-file-name)) map-files)
           try-find-file)))

(define (map-file-name o)
  (match o
    ((or ($ <foreign>) ($ <component>) ($ <system>)) (map-file-name (om:port o)))
    (_ (om:name o)) ;; dzn::IConsole ==> IConsole.map
    (_ ((om:scope-name) o)))) ;; dzn::IConsole ==> dzn_IConsole.map

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
