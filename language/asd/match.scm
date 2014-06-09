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

(use-modules (ice-9 match))
(use-modules (ice-9 and-let-star))
(use-modules (srfi srfi-1))
(use-modules (language asd misc))
(use-modules (ice-9 pretty-print))  

(define (->string src) 
  (match src
    ((? char?) (make-string 1 src))
    ((? string?) src)
    ((? symbol?) (symbol->string src))
    ((h ... t) (apply string-append (map ->string src)))
    (_ "")))


(define (equalizer x) 
  ;;(stderr "creating equalizer: comparing with == ~a\n" x)
  (lambda (y) 
    (if (eq? x y)     (stderr "    equalizer: ~a == ~a\n" x y))
    (eq? x y)))

(define ast (read (open-input-file "examples/Alarm.scm")))

(define q1 'foobar)
(define (get-statements src state port event)
  (if (equal? src ast)
      (stderr "\nstate ~a ~a ~a\n" state port event)
      ;;(stderr "MATCHING: ~a\n" src)
      )
  (match src
    ((path *** ('guard ('field 'state (? (equalizer state))) statements))
     (get-statements statements state port event))
    (('statements t ...)
     (get-statements t state port event))
    ((('on clause statements) t ...)
     (or (get-statements (append (list clause) (list statements)) state port event)
         (get-statements t state port event)))
    (((('field (? (equalizer port)) (? (equalizer event))) t ...) statements)
     statements)
    (((('field a b) t ...) statements)
     (get-statements (cons t (list statements)) state port event))
    ((h ... t) #f)
    (_ (begin (stderr "NO pMATCH\n") #f))))

(define (print x)
  (pretty-print x)
  (stdout "\n\n"))

(print (get-statements ast 'Disarmed 'console 'arm))
(print (get-statements ast 'Disarmed 'console 'disarm))
(print (get-statements ast 'Disarmed 'sensor 'triggered))
(print (get-statements ast 'Disarmed 'sensor 'disabled))

(print (get-statements ast 'Armed 'console 'arm))
(print (get-statements ast 'Armed 'console 'disarm))
(print (get-statements ast 'Armed 'sensor 'triggered))
(print (get-statements ast 'Armed 'sensor 'disabled))

(print (get-statements ast 'Disarming 'console 'arm))
(print (get-statements ast 'Disarming 'console 'disarm))
(print (get-statements ast 'Disarming 'sensor 'triggered))
(print (get-statements ast 'Disarming 'sensor 'disabled))

(print (get-statements ast 'Triggered 'console 'arm))
(print (get-statements ast 'Triggered 'console 'disarm))
(print (get-statements ast 'Triggered 'sensor 'triggered))
(print (get-statements ast 'Triggered 'sensor 'disabled))
