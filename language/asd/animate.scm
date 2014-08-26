;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (language asd animate)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (language asd misc)
  :export (animate-file
           animate-input
           animate-module-populate
           animate-string
           animate-template
           file-line-column-location
           line-column-location
           gulp-template
           template?
           template->string
           template-dir
           templates))

(define template-dir (make-parameter '(templates)))
(define (template-file name) (string-join (map symbol->string (append (template-dir) (list name))) "/"))
(define (gulp-template name) (gulp-file (template-file name)))

(define templates (make-parameter
                  `((test . ((foo . ,identity)
                             (bar . (lambda (x) "boo"))
                             (baz . "blaat"))))))

(define (template? x)
  (and (list? x) (pair? (assoc (car x) (templates)))))

(define (animate-module-populate module parameter key-procedure-pairs)
  (let loop ((pairs key-procedure-pairs))
    (if (null? pairs)
        module
        (let* ((pair (car pairs))
               (key (car pair))
               (procedure-or-data (cdr pair))
               (value (if (procedure? procedure-or-data)
                          (procedure-or-data parameter)
                          procedure-or-data)))
          (module-define! module key value)
          (loop (cdr pairs))))))

(define (template->string name . key-procedure-pairs)
  (let ((template (assoc-ref (templates) name)))
    (animate-template name (map (lambda (x)
                               (let* ((pair (car x))
                                      (key (car pair))
                                      (procedure (cdr pair))
                                      (data (cadr x))
                                      (value (procedure data)))
                                 (cons key value)))
                             (zip template key-procedure-pairs)))))

(define (animate-template name key-value-pairs)
  (let ((module (current-module)))
    (let loop ((pairs key-value-pairs))
      (when (pair? pairs)
        (module-define! module (caar pairs) (cdar pairs))
        (loop (cdr pairs))))
    (with-output-to-string
      (lambda () (animate-file (template-file name) module)))))

(define* (line-column-location tell :optional (port (current-input-port)))
  (seek port 0 SEEK_SET)
  (let loop ((line 1))
    (let ((string (read-delimited "\n" port)))
      (if (eq? string *eof*)
          (list 0 0 "")
          (if (>= (ftell port) tell)
              (list line (- tell (- (ftell port) (string-length string) 1)) string)
              (loop (1+ line)))))))

(define (port-size port)
  (seek port 0 SEEK_END)
  (ftell port))

(define (file-line-column-location file-name tell)
  (with-input-from-file file-name (lambda () (line-column-location tell))))

(define (animate-file file-name module)
  (with-input-from-file (->string file-name) (lambda () (animate-input module file-name))))

(define* (animate-input module :optional (file-name "<input>"))
  (catch 'parse-error
    (lambda ()
      (animate-input- module))
    (lambda (key . args)
      (let* ((tell (assoc-ref (car args) 'tell))
             (size (assoc-ref (car args) 'size))
             (start (assoc-ref (car args) 'start))
             (scm (assoc-ref (car args) 'scm))
             (pos (let loop ((tell (if (>1 (length tell)) (cdr tell) tell)) (start start))
                    (if (null? tell)
                        0
                        (+ (car tell) (car start)
                           (loop (cdr tell) (cdr start))))))
             (line-column (if pos
                              (line-column-location pos)
                              (list 0 0 "")))
             (line (car line-column))
             (column (cadr line-column))
             (file-string (caddr line-column))
             (string (assoc-ref (car args) 'line))
             (args (car (or (assoc-ref (car args) 'args)
                            (list args))))
             (error-message (or (car args) (cadr args)))
             (error-args (if (car args) '() (caddr args)))
             (error-string (apply format (append (list #f error-message) error-args)))
             (message
              (if (string? string)
                  (if (string-contains file-string string)
                      (format #f "~a:~a:~a: parse error: ~a\n~a\n~a~a...\n" file-name line column error-string (string-take file-string column) (make-string column #\space)
                              (string-drop file-string column))
                      (format #f "~a:~a: parse error: ~a\n    just before: ~a\n" file-name line error-string string))
                  (format #f "~a:~a: parse error: *eof*: ~a\n" file-name line error-string))))
        (stderr "~a" message)
        (throw 'parse-error message)))))

(define* (animate-string string :optional (module (current-module)))
  (with-input-from-string string
    (lambda () (animate-input- module))))

(define escape #\#)

(define (animate-input- module)
  (let* ((start '(0))
         (start-hash-read-string (lambda (chr port)
                                   (set! start
                                         (cons (1+ (ftell (current-input-port))) start)
                                         ;;(1+ (ftell (current-input-port)))
                                         )
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
