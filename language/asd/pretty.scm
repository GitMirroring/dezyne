;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

  :use-module (language asd animate)
;;  :use-module (language asd ast:)
  :use-module (language asd misc)
;;  :use-module (language asd reader)

  :export (ast-> ast->asd ast->pretty ast->string))

(define (ast->string ast) 
  (apply string-append (map ->string ast)))

(define ast-> ast->string)
(define ast->asd ast->string)
(define ast->pretty ast->string)

(define (->string src) 
  (match src
    (#f "false")
    (#t "true")
    (('behaviour) "")
    (('compound s ...) (string-join (append '("{ ") (map ->string (cdr src)) '("}\n") ) ""))
    (('if expr statement else) (->string (cons 'if-then-else (cdr src))))
    (('if expr statement) (->string (cons 'if-then (cdr src))))
    ((? asd-template?) (apply asd-template->string src))
    ((? join?) (apply join-all (cdr src)))
    ((? symbol?) (symbol->string src))
    ((! expression) (string-append "!(" (->string expression) ")"))
    (_ (format #f "\n~aNO MATCH:~a\n" (current-source-location) src))))

(define (asd-template? x) (parameterize ((templates asd-templates)) (template? x)))

(define (asd-template->string . x)
  (parameterize ((template-dir asd-template-dir) (templates asd-templates))
    (apply template->string x)))

(define (comma-space-join lst) (string-join (map ->string lst) ", "))

(define asd-template-dir '(templates asd))
(define asd-templates
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
                  ;; TOP level compound does *not* have braces
                  (compound . ,(lambda (x) (apply string-append (map ->string (cdr x)))))))
    (enum . ((name . ,identity)
             (elements . ,comma-space-join)))
    (declare . ((type . ,identity)
                (var . ,identity)
                (value . ,->string)))
    (field . ((struct . ,identity)
            (field . ,identity)))
    (on . ((trigger . ,comma-space-join)
           (statement . ,->string)))
    (guard . ((expression . ,->string)
              (statement . ,->string)))
    (assign . ((identifier . ,identity)
               (expression . ,->string)))
    (action . ((expression . ,->string)))
    (if-then . ((expression . ,->string)
                (statement . ,->string)))
    (if-then-else . ((expression . ,->string)
                     (statement . ,->string)
                     (else . ,->string)))
    (or . ((left . ,->string)
           (right . ,->string)))
    (and . ((left . ,->string)
           (right . ,->string)))
    (in . ((type . ,->string)
           (identifier . ,->string)))
    (out . ((type . ,->string)
            (identifier . ,->string)))
    (import . ((file . ,->string)))))

(define (join-all . rest) (string-join (map ->string rest) ""))
(define join '(events imports ports types variables))
(define (join? x) (and (list? x) (member (car x) join)))
