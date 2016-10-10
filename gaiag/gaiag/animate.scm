;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; This file is part of Gaiag.
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

;; this file is part of gaiag, guile in asd in asd in guile.
;;
;; copyright (c) 2014  jan nieuwenhuizen <janneke@gnu.org>
;;
;; gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the gnu affero general public license as
;; published by the free software foundation, either version 3 of the
;; license, or (at your option) any later version.
;;
;; gaiag is distributed in the hope that it will be useful,
;; but without any warranty; without even the implied warranty of
;; merchantability or fitness for a particular purpose.  see the
;; gnu affero general public license for more details.
;;
;; you should have received a copy of the gnu affero general public license
;; along with gaiag.  if not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define-module (gaiag animate)
  :use-module (gaiag list match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)
  :use-module (srfi srfi-26)

  :use-module (gaiag misc)
  :use-module (gaiag om)

  :export (animate
           animate-file
           animate-string
           animate-input
           any->string
           populate-module
           snippet
           gulp-template
           prefix-dir
           template?
           template-file
           template-dir
           templates))

(define (prefix-dir)
  (let* ((canary "language/dezyne/spec")
         (canary.go (string-append canary ".go"))
         (canary.scm (string-append canary ".scm"))
	 (file (or (and=> (search-path %load-compiled-path canary.go) dirname)
		   (%search-load-path canary.scm)
		   (let ((message
			  (string-join
			   (list "gaiag: Installation error: templates not found"
				 (format #f "gaiag: No such file or directory: ~a [~a]" canary.go %load-compiled-path)
				 (format #f "gaiag: No such file or directory: ~a [~a]" canary.scm %load-path)) "\n")))
		     (stderr message)
		     (throw 'installation-error message)))))
    (append
     ((compose file-name->components dirname dirname dirname dirname) file)
     '(gaiag))))

(define template-dir (make-parameter (append (prefix-dir) '(templates))))
(define (template-file name) (append (template-dir) (if (pair? name) name (list name))))
(define (gulp-template name) (gulp-file (template-file name)))

(define templates (make-parameter
                  `((test . ((foo . ,identity)
                             (bar . (lambda (x) "boo"))
                             (baz . "blaat"))))))

(define (template? x)
  (or (and (is-a? x <ast>)
           (pair? (assoc (ast-name x) (templates))))
      (and (list? x) (pair? (assoc (car x) (templates))))))

(define* (populate-module module key-value-pairs :optional (o #f))
  (let loop ((pairs key-value-pairs))
    (if (null? pairs)
        module
        (let* ((pair (car pairs))
               (key (car pair))
               (procedure-or-data (cadr pair))
               (value (if (procedure? procedure-or-data) (procedure-or-data o)
                          procedure-or-data)))
          (module-define! module key value)
          (loop (cdr pairs))))))

(define* (animate string :optional (o #f) (p #f))
  (with-output-to-string (lambda () (animate-string string o p))))

(define* (snippet file-name :optional (o #f) (p #f))
  ;;(stderr "SNIPPET: ~a\n" file-name)
  (parameterize ((template-dir (append (template-dir) '(snippets))))
    (with-output-to-string (lambda () (animate-file file-name o p)))))

(define* (animate-string string :optional (o #f) (p #f))
  (with-input-from-string string (lambda () (animate-input (get-module o p)))))

(define* (animate-file file-name :optional (o #f) (p #f))
  (let ((file-name (components->file-name (template-file file-name))))
    (with-input-from-file file-name (lambda () (animate-input (get-module o p) file-name)))))

(define* (get-module o :optional (p #f))
  (match o
    ((? module?) o)
    ((? list?) (populate-module (current-module) o p))
    (_ (current-module))))

(define* (line-column-location tell :optional (port (current-input-port)))
  (seek port 0 SEEK_SET)
  (let loop ((line 1))
    (let ((string (read-delimited "\n" port)))
      (if (eq? string *eof*)
          (list 0 0 "")
          (if (>= (ftell port) tell)
              (list line (- tell (- (ftell port) (string-length string) 1)) string)
              (loop (1+ line)))))))

(define (file-line-column-location file-name tell)
  (with-input-from-file file-name (lambda () (line-column-location tell))))

(define (relative-file-name file-name)
  (if (not (string-prefix? (getcwd) file-name)) file-name
      (string-drop file-name (1+ (string-length (getcwd))))))

(define* (animate-input module #:optional (file-name "<stdin>"))
  (catch #t
    (lambda ()
      (animate-input- module))
    (lambda (key . args)
      (let* ((options (car args))
             (tell (or (and=> (assoc-ref options 'tell) car)
                       (ftell (current-input-port))))
             (exception (or (assoc-ref options 'exception)
                            (and (or (not (car args))
                                     (string? (car args)))
                                 (pair? (cdr args))
                                 args)
                            (and (stderr "args2 ~a" args)
                                 '("function" "" '() #f))))
             (format-string (cadr exception))
             (format-args (caddr exception))
             (start (or (assoc-ref options 'eval)
                        (assoc-ref options 'start)))
             (loc (line-column-location start))
             (file-name (relative-file-name file-name))
             (line (car loc))
             (column (cadr loc))
             (string (caddr loc))
             (error (apply format (cons* #f format-string format-args)))
             (safe-column (min column (string-length string)))
             (before-error (string-take string safe-column))
             (before-error-white (make-string column #\space))
             (after-error (string-drop string safe-column))
             (message 
              (format #f "~a:~a:~a: ~a: ~a\n~a\n~a~a\n" file-name line column key error before-error before-error-white after-error)))
        (stderr "~a" message)
        (apply throw (cons key args))))))

(define %start '(0))
(define (start-hash-read-string chr port)
  (set! %start
        (cons (1+ (ftell (current-input-port))) %start))
  (hash-read-string chr port))

(define any->string (make-parameter ->string))

(define (animate-input- module)
  (read-hash-extend #\{ start-hash-read-string)
  (while (and=> (*eof*-is-#f (read-delimited (make-string 1 #\#)))
                display)
    (let ((c (read-char)))
      (cond
       ((eq? c #\#) (display c))
       ((eq? *eof* c) #f)
       (else
        (unread-char c)
        (catch #t
          (lambda ()
            (let* ((start (ftell (current-input-port)))
                   (expr (read (current-input-port))))
              (catch #t
                (lambda ()
                  (let ((o (eval expr module)))
                    (display
                     (match o
                       ((? number?) o)
                       ((? string?) o)
                       ((? symbol?) (symbol->string o))
                       (_ ((any->string) o)))))
                  (eat-one-space))
                (lambda (key . args)
                  (let* ((options (car args))
                         (exception (or (assoc-ref options 'exception)
                                        (and (or (not (car args))
                                                 (string? (car args)))
                                             (pair? (cdr args))
                                             args)
                                        (and (stderr "args0 ~a" args)
                                             '("function" "" '() #f))))
                         (eval (and (not (assoc-ref options 'eval)) start))
                         (start (assoc-ref options 'start))
                         (tell (cons
                                (ftell (current-input-port))
                                (f-is-null (assoc-ref options 'tell))))
                         (tell '()))
                    (throw key `((eval . ,eval)
                                 (tell . ,tell)
                                 (start . ,start)
                                 (exception . ,exception))))))))
          (lambda (key . args)
            (let* ((options (car args))
                   (exception (or (assoc-ref options 'exception)
                                  (and (or (not (car args))
                                           (string? (car args)))
                                       (pair? (cdr args))
                                       args)
                                  (and  (stderr "args1 ~a" args)
                                        '("function" "" '() #f))))
                   (tell (cons (ftell (current-input-port))
                               (f-is-null (assoc-ref options 'tell))))
                   (eval (assoc-ref options 'eval))
                   (start (assoc-ref options 'start))
                   (tell (if eval '(0 0) tell))
                   (start (cond (eval (+ eval (car %start)))
                                (start start)
                                ((= (length tell) 1) (car tell))
                                (else (reduce + 0 (append (cdr tell) %start))))))
              (throw key `((eval . ,eval)
                           (tell . ,tell)
                           (start . ,start)
                           (exception . ,exception)))))))))))
