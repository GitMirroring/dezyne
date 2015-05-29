;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (gaiag goops csp)
  :use-module (ice-9 optargs)
  :use-module (gaiag goops om)
  :export (
           <context>
;;           <context-vector>
           <csp-assign>           
           <csp-call>
           <csp-variable>
           <skip>
           <csp-if>
           <csp-on>
           <csp-reply>
           <csp-return>
           <semi>
           <voidreply>
           <the-end>           

           .members
           .locals
           .context
           .continuation
           .expressions
           ))

(define-class <context> (<ast>)
  (members :accessor .members :init-form (list) :init-keyword :members)
  (locals :accessor .locals :init-form (list) :init-keyword :locals))

;;(define-class <context-vector> (<ast-list>))

(define-class <contexted> (<ast>)
  (context :accessor .context :init-value #f :init-keyword :context))

(define-class <csp-call> (<call> <contexted>))

(define-class <csp-variable> (<variable> <contexted>)
  (continuation :accessor .continuation :init-value #f :init-keyword :continuation))

(define-class <csp-assign> (<assign> <contexted>)
  (expressions :accessor .expressions :init-value #f :init-keyword :expressions))

(define-class <skip> (<ast>))

(define-class <csp-if> (<if> <contexted>))

(define-class <csp-on> (<on> <contexted>))

(define-class <csp-reply> (<reply> <contexted>))

(define-class <csp-return> (<return> <contexted>))

(define-class <semi> (<ast>)
  (statement :accessor .statement :init-value #f :init-keyword :statement)
  (continuation :accessor .continuation :init-value #f :init-keyword :continuation))

(define-class <the-end> ())

(define-class <voidreply> (<ast>))
