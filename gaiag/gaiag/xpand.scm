;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
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
  #:use-module (ice-9 poe)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-19)
  #:use-module (srfi srfi-26)


  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:export (define-template
             gulp-template
             template?
             template-dir
             template-file
             x:pand))

(define template-dir (make-parameter %template-dir))
(define (template-file name) (append (list (template-dir)) (if (pair? name) name (list name))))
(define (gulp-template name) (gulp-file (template-file name)))

(define DEPTH 0)

(define (zero-time)
  (let ((t (current-time time-process)))
    (set-time-second! t 0)
    (set-time-nanosecond! t 0)
    t))

(define T0 (zero-time))

(define (time-decimal t)
  (* 1.0 (+ (time-second t) (/ (time-nanosecond t) 1000000000)))
  )

(define-syntax time
  (syntax-rules ()
    ((_ T S)
     (let* ((foo (set! DEPTH (+ DEPTH 1)))
            (t0 (current-time time-process))
            (s S)
            (t1 (current-time time-process))
            (t (time-difference t1 t0))
            (foo (set! DEPTH (- DEPTH 1))))
       (when (eq? DEPTH 0)
         (set! T (add-duration T t))
         (stderr "--- ~a ~f ~f\n" 'T (time-decimal t) (time-decimal T)))
       s))))


(define (my-eval symbol module o) (->string ((module-ref module symbol) o)))
(define my-eval (pure-funcq my-eval))

(define (funct symbol module o)
  ;(stderr "module: ~a symbol: ~a\n" module symbol)
;  (->string (time T0 (eval (list (string->symbol symbol) o) module)))
;  (time T0 (my-eval (string->symbol symbol) module o))
  (->string (eval (list (string->symbol symbol) o) module)))


(define-peg-string-patterns
    "script       <-- pegtext*
     pegtext      <-  (!pegprocedure (escape '#' / .))* pegprocedure?
     pegsep       <   [ ]?
     escape       <   '#'
     pegprocedure <-- '#' ('='/'.'/':'/'-'/'+'/'?'/[a-zA-Z0-9_])+ pegsep")

(define (x:pand filename o module)
  (define (tree->string t)
    (match t
      (('script t ...) (tree->string t))
      (('pegprocedure s) (display (funct (string-drop s 1) module o)))
      ((? string?) (display t))
      ((t ...) (map tree->string t))
      (_ #f)))

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
                                                      (number? ast)
                                                      (string? ast)
                                                      (symbol? ast)) (display ast)
                                                      (let* ((name (symbol->string (ast-name (if (is-a? ast type) type (class-of ast)))))
                                                             (file-name (string-append file-name "@" name)))
                                                        (x:pand file-name ast (this-module)))))))
                               o)))))
        ((null? o) #f)
        ((is-a? o <ast>)
         ;;(stderr "ATOM [~a,t=~a,f=~a] ~a\n" (class-name (class-of o)) (and type (class-name type)) file-name (class-name (class-of o)))
         (let* ((name (symbol->string (ast-name (if (is-a? o type) type (class-of o)))))
                (file-name (string-append file-name "@" name)))
	   (x:pand file-name o (this-module))))
        (#t (x:pand file-name o (this-module)))))

(define-public this-module (make-parameter #f))

(define-syntax define-template
  (syntax-rules ()
    ((_ name f sep type)
     (define-public (name ast)
       (let* ((module (this-module))
              (file-name (string-drop (symbol->string 'name) 2)))
         (type->template module file-name type sep (f ast)))
       ""))
    ((_ name f sep)
     (define-template name f sep #f))
    ((_ name f)
     (define-template name f #f))))
