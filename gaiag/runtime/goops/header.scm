;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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


(define (main . args)
  ((@@ (dezyne) main) (command-line)))

(read-set! keywords 'prefix)

(define-module (dezyne)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (ice-9 rdelim)
  :use-module (oop goops))

(define (stderr . args)
  (apply format (cons* (current-error-port) args)))

(define-class <model> ())

(define-class <interface> (<model>)
  (in :accessor .in :init-value #f :init-keyword :in)
  (out :accessor .out :init-value #f :init-keyword :out))

(define-class <component> (<interface>))
(define-class <system> (<model>))

(define-method (connect-ports (provided <interface>) (required <interface>))
  (set! (.out provided) (.out required))
  (set! (.in required) (.in provided)))

(define (illegal) (throw 'assert 'illegal))

(define-method (action (o <component>) (port <accessor>) (dir <accessor>) (event <accessor>))
  (((compose event dir port) o)))

(define (flush o) #f)
(define (defer i o f)
  (f))

(define-method (call-in (o <component>) f m)
  (apply trace-in m)
  (let ((handle (.handling o)))
    (set! (.handling o) #t)
    (let ((r (f)))
      (if handle (throw 'defer "a valued event cannot be deferred"))
      (set! (.handling o) #f)
      (flush o)
      (trace-out (car m) (if (eq? r (if #f #f)) 'return 'TODO))
      r)))

(define-method (call-out (o <component>) f m)
  (apply trace-out m)
  (defer (.self (.in m)) o f))

(define (trace-in i e)
  (stderr "~a.~a\n" i e))

(define (trace-out i e)
  (stderr "~a.~a\n" i e))
