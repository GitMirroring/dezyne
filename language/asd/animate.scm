;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(read-set! keywords 'prefix)

(define-module (language asd animate)
  :use-module (ice-9 match)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 rdelim)
  :use-module (srfi srfi-1)

  :use-module (language asd misc)
  :export (animate-file
           animate-string
           animate-template
           file-line-column-location
           gulp-template
           template?
           template->string
           template-dir
           templates))

(define template-dir (make-parameter '(templates)))
(define (template-file name) (string-join (map symbol->string (append (template-dir) (list name))) "/"))
(define (gulp-template name) (gulp-text-file (template-file name)))

(define templates (make-parameter
                  `((test . ((foo . ,identity)
                             (bar . (lambda (x) "boo"))
                             (baz . "blaat"))))))

(define (template? x)
  (and (list? x) (pair? (assoc (car x) (templates)))))

(define (template->string name . key-func-pairs)
  (let ((template (assoc-ref (templates) name)))
    (animate-template name (map (lambda (x)
                               (let* ((pair (car x))
                                      (key (car pair))
                                      (func (cdr pair))
                                      (data (cadr x))
                                      (value (func data)))
                                 (cons key value)))
                             (zip template key-func-pairs)))))

(define (animate-template name key-value-pairs)
  (let ((module (current-module)))
    (let loop ((pairs key-value-pairs))
      (when (pair? pairs)
        (module-define! module (caar pairs) (cdar pairs))
        (loop (cdr pairs))))
    (with-output-to-string
      (lambda () (animate-string (gulp-template name) module)))))

(define (file-line-column-location file-name tell)
  (let* ((port (open-file (->string file-name) "r")))
    (let loop ((line 1))
      (let ((string (read-delimited "\n" port)))
        (if (eq? string *eof*)
            (list 0 0 "")
            (if (>= (ftell port) tell)
              (list line (- tell (- (ftell port) (string-length string) 1)) string)
              (loop (1+ line))))))))

(define (animate-file file-name out-name module)
  (catch 'parse-error
        (lambda ()
          (dump-file (->string out-name)
                     (with-output-to-string
                       (lambda ()
                         (animate-string (gulp-text-file file-name) module)))))
        (lambda (key . args)
          (let* ((tell (assoc-ref (car args) 'ftell))
                 (line-column (if (pair?  tell)
                                  (file-line-column-location file-name (car tell))
                                  (list 0 0 "")))
                 (line (car line-column))
                 (column (cadr line-column))
                 (file-string (caddr line-column))
                 (string (car (assoc-ref (car args) 'line)))
                 (args (car (or (assoc-ref (car args) 'args)
                                (list args))))
                 (message 
                  (if (string? string)
                      (if (string-contains file-string string)
                          (format #f "~a:~a:~a: parse error:\n~a\n~a~a...\n~a\n" file-name line column (string-take file-string column) (make-string column #\space) string args)
                          (format #f "~a:~a: parse error: just before: ~a\n~a\n" file-name line string args))
                      (format #f "~a:~a: parse error: *eof*\n~a\n" file-name line args))))
            (stderr "~a" message)
            (throw 'parse-error message)))))

(define (animate-string string module)
  (with-input-from-string string
    (lambda () (animate-input module))))

(define (eat-one-space)
  (let ((c (read-char)))
    (cond
     ((eq? c #\space) #t)
     ((eq? *eof* c) #f)
     (else (unread-char c)))))

(define (eat-one-space-or-newline)
  (let ((c (read-char)))
    (cond
     ((eq? c #\space) #t)
     ((eq? c #\newline) #t)
     ((eq? *eof* c) #f)
     (else (unread-char c)))))

(define (animate-hash-read-string chr port)
  (eat-one-space-or-newline)
  (with-output-to-string
    (lambda ()
      (let ((depth 1))
        (while (and-let* (((>0 depth))
                          (s (*eof*-is-#f (read-delimited "#" port))))
                         (display s))
          (let ((c (peek-char port)))
            (cond
             ((eq? c #\{) (set! depth (1+ depth)) (display "#"))
             ((eq? c #\}) (set! depth (1- depth)) (if (=0 depth)
                                                      (read-char port)
                                                      (display "#")))
             ((eq? *eof* c) (set! depth 0) #f)
             (else (display "#")))))))))

(define escape #\#)

(define (animate-input module)
  (read-hash-extend #\{ animate-hash-read-string)
  (while (and-let* ((s (*eof*-is-#f (read-delimited (make-string 1 escape)))))
                   (display s))
    (let ((c (read-char)))
      (cond
       ((eq? c escape) (display c))
       ((eq? *eof* c) #f)
       (else (unread-char c)
             (catch #t (lambda ()
                         (let* ((expr (read (current-input-port)))
                                (result (eval expr module)))
                         (display (->string result))
                         (eat-one-space)))
               (lambda (key . args)
                 (let* ((tell (car (or (assoc-ref (car args) 'xftell)
                                       (list (ftell (current-input-port))))))
                        (line (car (or (assoc-ref (car args) 'line)
                                       (list (read-delimited "\n")))))
                        (args (car (or (assoc-ref (car args) 'args)
                                       (list args)))))
                   (throw 'parse-error (append `((ftell ,tell) (line ,line) (args ,args))))))))))));,(apply format #f (cadr args) (caddr args))))))))))))))
