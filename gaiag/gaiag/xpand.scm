;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag xpand)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 peg)
  #:use-module (ice-9 peg codegen)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:export (define-template
             gulp-template
             prefix-dir
             template?
             template-dir
             template-file
             x:pand))

(define (prefix-dir) ;; FIXME
  (let* ((canary "language/dezyne/spec")
         (canary.go (string-append canary ".go"))
         (canary.scm (string-append canary ".scm"))
	 (prefix (or (and=> (search-path %load-compiled-path canary.go) (cut string-drop-right <> (string-length canary.go)))
                     (and=> (%search-load-path canary.scm) (cut string-drop-right <> (string-length canary.scm)))
                     (let ((message
                            (string-join
                             (list "gaiag: Installation error: templates not found"
                                   (format #f "gaiag: No such file or directory: ~a [~a]" canary.go %load-compiled-path)
                                   (format #f "gaiag: No such file or directory: ~a [~a]" canary.scm %load-path)) "\n")))
                       (stderr message)
                       (throw 'installation-error message)))))
    (append
     ((compose file-name->components dirname) prefix)
     '(gaiag))))

(define template-dir (make-parameter (append (prefix-dir) '(templates))))
(define (template-file name) (append (template-dir) (if (pair? name) name (list name))))
(define (gulp-template name) (gulp-file (template-file name)))

(define* (x:pand filename o #:optional (module (current-module)))
  (define (tree->string t)
    (match t
      (('script t ...) (tree->string t))
      (('pegprocedure s) (display (->string (eval (list (string->symbol (string-drop s 1)) o) module))))
      ((? string?) (display t))
      ((t ...) (map tree->string t))
      (_ #f)))
  (define-peg-string-patterns
    "script       <-- pegtext*
     pegtext      <-  (!pegprocedure (escape '#' / .))* pegprocedure?
     pegsep       <   [ ]?
     escape       <   '#'
     pegprocedure <-- '#' ('='/'.'/':'/'-'/'+'/[a-zA-Z0-9_])+ pegsep")
  ;; (stderr "X:PAND: ~a\n" o)
  (let* ((debug? (command-line:get 'debug #f))
         (result (match-pattern script (gulp-template filename)))
         (end (peg:end result))
         (tree (peg:tree result)))
    (if debug?
        (format #t "/*\ntemplates/~a/~a:0:expand */\n" (language) filename))
    ;; (stderr "tree: ~s\n" tree)
    ;; (stderr "   => ~a\n" filename)
    (tree->string tree)))

(define (reduce-sexp l)
  (unfold null? (compose (cut apply list <>) (cut list-head <> 2)) cddr l))

(define (xassoc key alist) (find (compose (cut equal? key <>) cdr) alist))

(define* (string-join+ lst #:optional (grammar '("")))
  "Like STRING-JOIN, allowing \"PRE\" 'pre and \"POST\" 'post in GRAMMAR"
  ;; (stderr "string-join+ lst=~s\n" lst)
  ;; (stderr "            grammar=~s\n" grammar)
  (let* ((grammar? (> (length grammar) 1))
         (g-alist (if (not grammar?) (car grammar)
                       (reduce-sexp grammar)))
         (delimiter (if (not grammar?) grammar
                        (or (xassoc '(infix) g-alist)
                            (xassoc '(suffix) g-alist)
                            (xassoc '(prefix) g-alist)
                            '(""))))
         (pre (if (not grammar?) ""
                  (or (and=> (xassoc '(pre) g-alist)
                             car) "")))
         (post (if (not grammar?) ""
                   (or (and=> (xassoc '(post) g-alist)
                              car) ""))))
    ;;(stderr "            delim=~s\n" delimiter)
    (string-append pre (apply string-join (cons lst delimiter)) post)))

(define (type->template module file-name type sep o)
  (let ((debug? (command-line:get 'debug #f)))
    (if (and debug?
             (not (pair? o))
             (not (is-a? o <ast>)))
        (format #t "/*\ntemplates/~a/~a:0:expand */\n" (language) file-name)))
  (cond ((char? o) (display o))
        ((number? o) (display o))
        ((symbol? o) (display o))
        ((string? o) (display o))
        ((pair? o)
         ;;(stderr "PAIR [~a,t=~a,f=~a] ~a\n" (class-name (class-of o)) (and type (class-name type)) file-name (class-name (class-of (car o))))
         (let* ((sexp (if (not sep) '("")
                          (with-input-from-string (gulp-template sep) read)))
                (join (lambda (o) (apply string-join+ (cons o (list sexp))))))
           (display (join (map (lambda (ast)
                                 (with-output-to-string
                                   (lambda () (if (or (char? ast)
                                                      (string? ast)
                                                      (symbol? ast)) (display ast)
                                                      (let* ((name (symbol->string (ast-name (if (is-a? ast type) type (class-of ast)))))
                                                             (file-name (string-append file-name "@" name)))
                                                        (if (not (eq? o (car (ast:scope))))
                                                            (ast:extend-scope ast (x:pand file-name ast))
                                                            (x:pand file-name ast))))))) o)))))
        ((null? o) #f)
        ((is-a? o <ast>)
         ;;(stderr "ATOM [~a,t=~a,f=~a] ~a\n" (class-name (class-of ast)) (and type (class-name type)) file-name (class-name (class-of o)))
         (let* ((name (symbol->string (ast-name (if (is-a? o type) type (class-of o)))))
                (file-name (string-append file-name "@" name)))
	   (if (not (eq? o (car (ast:scope))))
	       (ast:extend-scope o (x:pand file-name o))
	       (x:pand file-name o))))
        (#t (x:pand file-name o))))

(define-syntax define-template
  (syntax-rules ()
    ((_ name f sep type)
     (define-public (name ast)
       (let* ((module (current-module))
              (file-name (string-drop (symbol->string 'name) 2)))
         (type->template module file-name type sep (f ast)))
       ""))
    ((_ name f sep)
     (define-template name f sep #f))
    ((_ name f)
     (define-template name f #f))))
