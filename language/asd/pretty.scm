;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (language asd pretty)
  :use-module (ice-9 rdelim)
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)
  :use-module (system base lalr)
  :use-module (language tree-il)
  :use-module (asd format-keys)
  :export (asd->string))

(define *pretty* (current-module))

(define (gulp-text-file name)
  (let* ((file (open-file name "r"))
	 (text (read-delimited "" file)))
    (close file)
    text))

(define (gulp-snippet name)
  (gulp-text-file (string-join (map symbol->string `(snippets asd ,name)) "/")))

(define (format-snippet name pairs) 
  (format-keys (gulp-snippet name) pairs))

(define (asd->string tree) 
  ;;(format #t "tree:~a\n" tree)
  (apply string-append (map ->string tree)))

(define (->string src) 
;;  (format #t "MATCHING:~a\n" src)
  (match src
    (#f "false")
    (#t "true")
    (('behaviour) "")
    ((? snippet?) (apply handle-snippet src))
    ((? join?) (apply join-all (cdr src)))
    ((? symbol?) (symbol->string src))
    (_ (format #f "\nNO MATCH:~a\n" src))))

(define snippets
  `((component . ((name . ,identity)
                  (ports . ,->string)
                  (behaviour . ,->string)))
    (interface . ((name . ,identity)
                  (types . ,->string)
                  (ports . ,->string)
                  (behaviour . ,->string)))
    (requires . ((type . ,identity)
                 (name . ,identity)))
    (provides . ((type . ,identity)
                 (name . ,identity)))
    (behaviour . ((name . ,(lambda (name) (if name name "")))
                  (types . ,->string)
                  (variables . ,->string)
                  (statements . ,->string)))
    (enum . ((name . ,identity)
             (elements . ,(lambda (elements) 
                            (string-join (map symbol->string elements) ",")))))
    (declare . ((type . ,identity)
                (var . ,identity)
                (value . ,->string)))
    (dot . ((struct . ,identity)
            (field . ,identity)))
    (on . ((trigger . ,->string)
           (statement . ,->string)))
    (guard . ((expression . ,->string)
              (statement . ,->string)))
    (assign . ((identifier . ,identity)
               (expression . ,->string)))
    (action . ((expression . ,->string)))
    (logic-or . ((left . ,->string)
                 (right . ,->string)))
    (in . ((type . ,->string)
           (identifier . ,->string)))
    (out . ((type . ,->string)
            (identifier . ,->string)))
    (import . ((file . ,->string)))))

(define (snippet? x)
  (and (list? x) (pair? (assoc (car x) snippets))))

(define (handle-snippet name . rest)
  (let ((snippet (assoc-ref snippets name)))
    (format-snippet name (map (lambda (x)
                                (let* ((pair (car x))
                                       (key (car pair))
                                       (func (cdr pair))
                                       (data (cadr x))
                                       (value (func data)))
                                  (cons key value)))
                              (zip snippet rest)))))

(define (join-all . rest) (string-join (map ->string rest)))
(define join '(events imports ports statements types variables))
(define (join? x) (and (list? x) (member (car x) join)))
