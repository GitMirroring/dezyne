;;; Dezyne --- Dezyne command line tools
;;;
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

(read-set! keywords 'prefix)

(define-module (gaiag list simulate)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)  
  :use-module (gaiag list om)
  :export (
           <info>
           make-<info>

           .trail
           ;;.ast
           .state
           .reply
           .return
           .state-alist
           .trace
           ))

(define simulate-classes
  '(
    info
    ))

(let ((module (current-module)))
  (for-each (lambda (x) (module-define! module (symbol->class x) x))
            (append simulate-classes)))

(define (make-<info> . args)
  (let-keywords
   args #f
   ((trail '())
    (ast '())
    (state '())
    (reply 'return)
    (return #f)
    (state-alist '())
    (trace '()))
   (cons <info> (list trail ast state reply return state-alist trace))))


(define (.trail o)
  (match o
    (('info trail ast state reply return state-alist trace) trail)))

(define (.ast o)
  (match o
    (('error ast message) ast)
    (('info trail ast state reply return state-alist trace) ast)))

(define (.state o)
  (match o
    (('info trail ast state reply return state-alist trace) state)))

(define (.reply o)
  (match o
    (('info trail ast state reply return state-alist trace) reply)))

(define (.return o)
  (match o
    (('info trail ast state reply return state-alist trace) return)))

(define (.state-alist o)
  (match o
    (('info trail ast state reply return state-alist trace) state-alist)))

(define (.trace o)
  (match o
    (('info trail ast state reply return state-alist trace) trace)))
