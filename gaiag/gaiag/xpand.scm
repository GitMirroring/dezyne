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

(define-module (gaiag xpand)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 peg)
  #:use-module (ice-9 peg codegen)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)

  #:use-module (gaiag animate) ; gulp-template
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag om)

  #:export (define-template
             x:pand))

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
  (let* ((result (match-pattern script (gulp-template filename)))
         (end (peg:end result))
         (tree (peg:tree result))
         (debug? (command-line:get 'debug #f)))
    (if debug?
        (format #t "/* ~a */\n" filename))
    ;; (stderr "tree: ~s\n" tree)
    ;; (stderr "   => ~a\n" filename)
    (tree->string tree)))

(define-syntax define-template
  (syntax-rules ()
    ((_ name f sep type)
     (define-public (name ast)
       (let* ((module (current-module))
              (filename (string-drop (symbol->string 'name) 2))
              (o (f ast)))
         (cond ((char? o) (display o))
               ((number? o) (display o))
               ((symbol? o) (display o))
               ((string? o) (display o))
               ((pair? o)
                ;;(stderr "PAIR [~a,t=~a,f=~a] ~a\n" (class-name (class-of ast)) (and type (class-name type)) filename (class-name (class-of (car o))))
                (let* ((sexp (if (not sep) '("")
                                 (with-input-from-string (gulp-template sep) read)))
                       (join (lambda (o) (apply string-join (cons o sexp)))))
                  (display (join (map (lambda (ast)
                                        (with-output-to-string
                                          (lambda () (if (or (char? ast)
                                                             (string? ast)
                                                             (symbol? ast)) (display ast)
                                                             (let* ((ast-name (symbol->string (ast-name (if (is-a? ast type) type (class-of ast)))))
                                                                    (filename (if (equal? filename ast-name) filename
                                                                                  (string-append filename "-" ast-name))))
                                                               (if (is-a? ast <model>)
                                                                   (ast:set-model-scope ast (x:pand filename ast))
                                                                   (x:pand filename ast))))))) o)))))
               ((null? o) #f)
               ((is-a? o <ast>)
                ;;(stderr "ATOM [~a,t=~a,f=~a] ~a\n" (class-name (class-of ast)) (and type (class-name type)) filename (class-name (class-of o)))
                (let* ((ast-name (symbol->string (ast-name (if (is-a? o type) type (class-of o)))))
                       (filename (if (equal? filename ast-name) filename
                                     (string-append filename "-" ast-name))))
                  (x:pand filename o)))
               (#t (x:pand filename o))))
       ""))
    ((_ name f sep)
     (define-template name f sep #f))
    ((_ name f)
     (define-template name f #f))))
