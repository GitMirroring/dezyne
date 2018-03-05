;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (gaiag m))

(define-syntax my-define
  (lambda (x)
    (syntax-case x ()
      ((_ name)
       #`(define (name)
           (display 'name)
           (newline))))))


(define-syntax my-define2
  (lambda (x)
    (syntax-case x ()
      ((_ name name2)
       (let ((bar #'name2))
         #`(define (name)
             (display 'name)
             (display " ")
             (display '#,bar)
             (newline)))))))

(define-syntax my-define3
  (lambda (x)
    (syntax-case x ()
      ((_ name name2)
       (let ((bar #'name2))
         #`(define (#,bar)
             (display 'name)
             (display " ")
             (display '#,bar)
             (newline)))))))

(define-syntax my-define4
  (lambda (x)
    (syntax-case x ()
      ((_ name name2)
       (let ((bar (datum->syntax x (symbol-append (syntax->datum #'name) ': (syntax->datum #'name2)))))
         #`(define (#,bar)
             (display 'name)
             (display " ")
             (display '#,bar)
             (newline)))))))

(define-syntax my-define5
  (lambda (x)
    (syntax-case x ()
      ((_ name name2)
       (with-syntax ((bar (datum->syntax x (symbol-append (syntax->datum #'name) ': (syntax->datum #'name2)))))
         #`(define (bar)
             (display 'name)
             (display " ")
             (display 'bar)
             (newline)))))))

(define-syntax my-define6
  (lambda (x)
    (syntax-case x ()
      ((_ name name2)
       (with-syntax ((bar0 (syntax->datum #'name))
                     (bar1 (syntax->datum #'name2)))
         (with-syntax ((bar2 (datum->syntax x (symbol-append #'bar0 ': #'bar1))))
          #`(define (bar2)
              (display 'name)
              (display " ")
              (display 'bar2)
              (newline))))))))

(define-syntax my-define7
  (lambda (x)
    (syntax-case x ()
      ((_ name name2)
       (let* ((bar0 (syntax->datum #'name))
              (bar1 (syntax->datum #'name2))
              (bar2 (symbol-append bar0 ': bar1)))
         (with-syntax ((bar3 (datum->syntax x bar2)))
           #`(define (bar3)
               (display 'name)
               (display " ")
               (display 'bar3)
               (newline))))))))

;;(my-define7 test bla)

(define-syntax my-define8
  (lambda (x)
    (syntax-case x ()
      ((_ name)
       (with-syntax ((name (datum->syntax x (symbol-append 'test: (syntax->datum #'name)))))
        #`(my-define name))))))


;;(my-define7 foo0 baz)
;; (module-map (lambda (. rest) (map display rest) (newline)) (current-module))
;; (foo0:baz)
;; (my-define8 foo)
;; (module-map (lambda (. rest) (map display rest) (newline)) (current-module))
;; (test:foo)



(define-syntax my-define9
  (lambda (x)
    (syntax-case x ()
      ((_ name)
       #'(my-define name)))))

(define-syntax my-define10
  (lambda (x)
    (syntax-case x ()
      ((_ name)
       #`(begin #,@(map (lambda (y) #`(my-define #,(datum->syntax x y))) '(a b)))))))

(my-define9 foo)
(my-define10 bar)
;;(module-map (lambda (. rest) (map display rest) (newline)) (current-module))
