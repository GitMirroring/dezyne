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
  :use-module (ice-9 match)
  :use-module (srfi srfi-1)
  :use-module (language asd misc)
  :use-module (language asd format-keys)
  :use-module (language asd snippets)
  :export (asd-> asd->asd asd->pretty asd->string))

(define (asd->string ast) 
  (apply string-append (map ->string ast)))

(define asd-> asd->string)
(define asd->asd asd->string)
(define asd->pretty asd->string)

(define (->string src) 
;;  (format #t "MATCHING:~a\n" src)
  (match src
    (#f "false")
    (#t "true")
    (('behaviour) "")
    ((? asd-snippet?) (apply asd-snippet->string src))
    ((? join?) (apply join-all (cdr src)))
    ((? symbol?) (symbol->string src))
    (_ (format #f "\nNO MATCH:~a\n" src))))

(define (asd-snippet? x)
  (parameterize ((snippets asd-snippets)) (snippet? x)))

(define (asd-snippet->string . x)
  (parameterize ((snippet-dir asd-snippet-dir) (snippets asd-snippets))
    (apply snippet->string x)))

(define (comma-join lst) (string-join (map symbol->string lst) ", "))

(define asd-snippet-dir '(snippets asd))
(define asd-snippets
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
             (elements . ,comma-join)))
    (declare . ((type . ,identity)
                (var . ,identity)
                (value . ,->string)))
    (field . ((struct . ,identity)
            (field . ,identity)))
    (on . ((trigger . ,comma-join)
           (statement . ,->string)))
    (guard . ((expression . ,->string)
              (statement . ,->string)))
    (assign . ((identifier . ,identity)
               (expression . ,->string)))
    (action . ((expression . ,->string)))
    (or . ((left . ,->string)
           (right . ,->string)))
    (in . ((type . ,->string)
           (identifier . ,->string)))
    (out . ((type . ,->string)
            (identifier . ,->string)))
    (import . ((file . ,->string)))))

(define (join-all . rest) (string-join (map ->string rest) ""))
(define join '(events imports ports statements types variables))
(define (join? x) (and (list? x) (member (car x) join)))
