;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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
  :use-module (ice-9 and-let-star)
  :use-module (gaiag list match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (gaiag misc)
  :use-module (gaiag om)

  :export (animate
           animate-file
           animate-string
           animate-input
           populate-module
           snippet
           gulp-template
           prefix-dir
           template?
           template-file
           template-dir
           templates))

(define (prefix-dir)
  (let* ((canary "gaiag/gaiag")
         (canary.go (string-append canary ".go"))
         (canary.scm (string-append canary ".scm")))
    (append
     ((compose file-name->components dirname dirname dirname dirname)
      (or (search-path %load-compiled-path canary.go)
          (%search-load-path canary.scm)
          (let ((message
                 (string-join
                  (list "gaiag: Installation error: templates not found"
                        (format #f "gaiag: No such file or directory: ~a [~a]" canary.go %load-compiled-path)
                        (format #f "gaiag: No such file or directory: ~a [~a]" canary.scm %load-path)) "\n")))
            (stderr message)
            (throw 'installation-error message))))
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
    (with-input-from-file file-name (lambda () (animate-input (get-module o p))))))

(define* (get-module o :optional (p #f))
  (match o
    ((? module?) o)
    ((? list?) (populate-module (current-module) o p))
    (_ (current-module))))

(define (animate-input module)
  (let* ((start '(0))
         (start-hash-read-string (lambda (chr port)
                                   (set! start
                                         (cons (1+ (ftell (current-input-port))) start))
                                   (hash-read-string chr port))))
    (read-hash-extend #\{ start-hash-read-string)
    (while (and-let* ((s (*eof*-is-#f (read-delimited (make-string 1 escape)))))
                     (display s))
      (let ((c (read-char)))
        (cond
         ((eq? c escape) (display c))
         ((eq? *eof* c) #f)
         (else (unread-char c)
               (let* ((xstart (ftell (current-input-port)))
                      (expr (read (current-input-port)))
                      (end (ftell (current-input-port))))
                 (catch 'boo ;;(if (batch-mode?) #t 'no-funky-exceptions)
                   (lambda ()
                     (let ((result (eval expr module)))
                       (display (->string result))
                       (eat-one-space)))
                   (lambda (key . args)
                     (let* ((tell (cons
                                   (ftell (current-input-port))
                                   (f-is-null (assoc-ref (car args) 'tell))))
                            (line (or (assoc-ref (car args) 'line)
                                      (read-delimited "\n")))
                            (size (cons (port-size (current-input-port))
                                        (f-is-null (assoc-ref (car args) 'size))))
                            (start (let loop ((start start))
                                     (if (null? start)
                                         0
                                         (if (or (=1 (length size))
                                                 (< (+ (car start) (cadr size)) (car tell)))
                                             (car start)
                                             (loop (cdr start))))))
                            (start (cons start
                                         (f-is-null (assoc-ref (car args) 'start))))
                            (args (car (or (assoc-ref (car args) 'args)
                                       (list args)))))
                       (throw 'parse-error (append `((tell . ,tell) (start . ,start) (size . ,size) (line . ,line) (args ,args))))))))))))))

(define escape #\#)

(define (port-size port)
  (seek port 0 SEEK_END)
  (ftell port))
