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
  ((@ (dezyne) main) (command-line)))

(read-set! keywords 'prefix)

(define-module (dezyne)
  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 optargs)
  :use-module (oop goops)
  :export (main))

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

(define-method (action (o <component>) (port <accessor>) (dir <accessor>) (event <symbol>))
  ((assoc-ref ((compose dir port) o) event)))
