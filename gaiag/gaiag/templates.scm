;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag templates)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 peg)
  #:use-module (ice-9 peg codegen)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)

  #:export (define-templates-base
             define-templates-macro
             display-primitive))

(eval-when (compile load expand)
  (define (template->tree file-name)
    (define-peg-string-patterns
      "script       <-- pegtext*
       pegtext      <-  (!pegprocedure (escape '#' / .))* pegprocedure?
       pegsep       <   [ ]?
       escape       <   '#'
       pegprocedure <-- '#' [-!$%&'*+,./0-9:<=>?A-Z^_a-z{|}~]([-!#$%&'*+,./0-9:<=>?A-Z^_a-z{|}~])* pegsep")
    (let* ( ;;(debug-level (length (gdzn:debugity)))
           (result (match-pattern script (with-input-from-file file-name read-string)))
           (end (peg:end result)))
      (peg:tree result)))

  (define (display-primitive o)
    (cond (((disjoin char? number? string?) o) (display o) "")
          ((symbol? o) (display (symbol->string o)) "")
          (else o)))

  (define (tree->body t . id)
    (let ((id (if (or #t (null? id)) '() ;;DEBUG MEUK HERE
                  (list (list 'display-primitive (car id))))))
      (append id
              (match t
                (('script t ...) (tree->body t))
                (('pegprocedure s) (list (list 'display-primitive (list (string->symbol (string-drop s 1)) 'o))))
                ((? string?) (list (list 'display t)))
                ((t ...) (append-map tree->body t))
                ('script '())))))

  (define* (display-join proc name dir o #:optional (grammar-alist '((#f . ("")))))
    "Like STRING-JOIN, allowing \"PRE\" 'pre and \"POST\" 'post in GRAMMAR"
    (define (bla o)
      (when (and #f (is-a? o <ast>) (gdzn:command-line:get 'debug)) ;;FIX FOR verify -d etc.
        (display "/*\ngaiag/")
        (display dir)
        (display name)
        (display "@")
        (display (string-trim-both (symbol->string (class-name (class-of o))) (lambda (c)
                                                                                (or (eqv? c #\<)
										    (eqv? c #\>)))))
        (display ":0: */\n"))
      (cond (((disjoin char? number? string? symbol?) o) (display o))
            ((null? o))
            (else (proc o))))
    (let* ((grammar (or (and (pair? o)
                             (assoc-ref grammar-alist ((compose ast-name car) o)))
                        (assoc-ref grammar-alist #f)))
           (grammar? (> (length grammar) 1))
           (g-alist (if (not grammar?) (car grammar)
                        (reduce-sexp grammar)))
           (infix (if (not grammar?) ""
                      (or (and=> (xassoc '(infix) g-alist)
                                 car) "")))
           (suffix (if (not grammar?) ""
                       (or (and=> (xassoc '(suffix) g-alist)
                                  car) "")))
           (prefix (if (not grammar?) ""
                       (or (and=> (xassoc '(prefix) g-alist)
                                  car) "")))
           (pre (if (not grammar?) ""
                    (or (and=> (xassoc '(pre) g-alist)
                               car) "")))
           (post (if (not grammar?) ""
                     (or (and=> (xassoc '(post) g-alist)
                                car) ""))))
      (unless (null? o) (display pre))
      (if (pair? o)
          (let loop ((lst o))
            (when (pair? lst)
              (let ((o (car lst)))
                (unless (and (string? o) (string-null? o)) (display prefix))
                (bla o)
                (unless (and (string? o) (string-null? o)) (display suffix)))
              (when (pair? (cdr lst)) (display infix))
              (loop (cdr lst))))
          (bla o))
      (unless (null? o) (display post))))

  (define (reduce-sexp l)
    (unfold null? (compose (cut apply list <>) (cut list-head <> 2)) cddr l))

  (define (xassoc key alist) (find (compose (cut equal? key <>) cdr) alist))

  (define (isdir? path)
    (and (access? path F_OK) (eq? 'directory (stat:type (stat path)))))

  (define (ls dir)
    (map (lambda (path)
           (if (isdir? (string-append dir path))
               (string-append path "/")
               path))
         (sort (filter (negate (cut string-every #\. <>))
                       (scandir (if (string-null? dir) (getcwd) dir))) string<?))))

(define (drop-<> o)
  (string->symbol (string-drop (string-drop-right (symbol->string o) 1) 1)))

(define-syntax compile-template
  (lambda (x)

    (syntax-case x ()
      ((_ name class language)
       (let* ((tname (datum->syntax x (symbol-append 't: (syntax->datum #'name))))
              (class-name (drop-<> (syntax->datum #'class)))
              (template (symbol->string (symbol-append 'templates/ (syntax->datum #'language) '/ (syntax->datum #'name) '@ class-name)))
              (tree (template->tree (syntax->datum template)))
              (body (datum->syntax x (tree->body tree (syntax->datum template))))
              (o (datum->syntax x 'o)))
         #`(define-method (#,tname (#,o class)) #,@body))))))

(define-syntax define-templates-base
  (lambda (x)
    (define (body language name xname tname func sep)
      (let ((dir (string-append "templates/" (symbol->string (syntax->datum language)) "/")))
        (define (read-sep file-name)
          (with-input-from-file (string-append dir file-name) read))
        (let* ((o (datum->syntax x 'o))
               (name@ (string-append (symbol->string (syntax->datum name)) "@"))
               (files (ls dir))
               (types (map (compose string->symbol (cut string-append "<" <> ">") (cute string-drop <> (string-length name@))) (filter (cute string-prefix? name@ <>) files)))
               (grammars (or (and (syntax->datum sep)
                                  (let ((sep-files (filter (cute string-prefix? (string-append ((compose symbol->string syntax->datum) sep) ;;"@"
                                                                                               ) <>) files)))
                                    (map (lambda (sep)
                                           (let* ((aapje (string-index sep #\@))
                                                  (type (and aapje ((compose string->symbol (cut string-drop <> (1+ aapje))) sep))))
                                             (cons type (read-sep sep)))) sep-files)))
                             '()))
               (grammars (append grammars '((#f . ("")))))
               (grammars (datum->syntax x grammars)))
          #`(begin
              #,@(map (lambda (t) #`(compile-template #,name #,(datum->syntax x t) #,language)) (syntax->datum types))
              (if (and #,(null? (syntax->datum types)) (not (defined? '#,tname)))
                  (define-method (#,tname (o <top>)) (throw 'missing-template-overload: (string-append "template: " (symbol->string '#,name) " for type: " (symbol->string (class-name (class-of o)))))))
              (define (#,xname #,o)
                (let ((f (#,func #,o)))
		  (when (and #f (gdzn:command-line:get 'debug)) ;;FIX FOR verify -d etc.
		    (display "// ") (display '#,func) (newline))
                  (display-join #,tname '#,name #,dir f '#,grammars)))))))

    (syntax-case x ()
      ((_  language name xname tname)
       (body #'language #'name #'xname #'tname #'identity #f))
      ((_  language name xname tname func)
       (body #'language #'name #'xname #'tname #'func #f))
      ((_  language name xname tname func sep)
       (body #'language #'name #'xname #'tname #'func #'sep)))))

(define-syntax define-templates-macro
  (lambda (x)
    (syntax-case x ()
      ((_ name language)
       #'(define-syntax name
           (lambda (x)
             (syntax-case x ()
               ((_ name)
                (with-syntax ((tname (datum->syntax x (symbol-append 't: (syntax->datum #'name))))
                              (xname (datum->syntax x (symbol-append 'x: (syntax->datum #'name)))))
                  #`(define-templates-base language name xname tname identity #f)))
               ((_ name func)
                (with-syntax ((tname (datum->syntax x (symbol-append 't: (syntax->datum #'name))))
                              (xname (datum->syntax x (symbol-append 'x: (syntax->datum #'name)))))
                  #`(define-templates-base language name xname tname func #f)))
               ((_ name func sep)
                (with-syntax ((tname (datum->syntax x (symbol-append 't: (syntax->datum #'name))))
                              (xname (datum->syntax x (symbol-append 'x: (syntax->datum #'name)))))
                  #`(define-templates-base language name xname tname func sep))))))))))
