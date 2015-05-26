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

(read-set! keywords 'prefix)

(define-module (gaiag list csp)
  :use-module (ice-9 match)
  :use-module (ice-9 optargs)  
  :use-module (gaiag list om)
  :export (
           <context>
           <context-vector>
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

           make-<context>
           make-<context-vector>
           make-<csp-call>
           make-<csp-variable>
           make-<csp-assign>
           make-<skip>
           make-<csp-if>
           make-<csp-on>
           make-<csp-reply>
           make-<csp-return>
           make-<semi>
           make-<the-end>           
           make-<voidreply>
           ))

(define (.members o)
  (match o
    (('context members locals) members)))

(define (.locals o)
  (match o
    (('context members locals) locals)))

(define .context cadr)

(define .continuation #f)
(define .expressions #f)

(define csp-classes
  '(
    context
    context-vector
    csp-assign           
    csp-call
    csp-variable
    skip
    csp-if
    csp-on
    csp-reply
    csp-return
    semi
    the-end           
    voidreply
 ))

(let ((module (current-module)))
  (for-each (lambda (x) (module-define! module (symbol->class x) x))
            (append csp-classes)))

(define (make-<context> . args)
  (let-keywords
   args #f
   ((members '())
    (locals '()))
   (cons <context> (list members locals))))

(define (make-<context-vector> . args)
  (apply make-<list> (append (list :type 'context-vector ) args)))

(define (make-<csp-call> . args)
  (let-keywords
   args #f
   ((context #f)
    (identifier #f)
    (arguments (make <arguments>)))
   (cons <csp-call> (list context identifier arguments))))

(define (make-<csp-variable> . args)
  (let-keywords
   args #f
   ((context #f)
    (name #f)
    (type #f)
    (expression (make <expression>))
    (continuation #f))
   (cons <csp-variable> (list context name expression continuation))))

(define (make-<csp-assign> . args)
  (let-keywords
   args #f
   ((context #f)
    (identifier #f)
    (expression (make <expression>)))
   (cons <assign> (list context identifier expression))))

(define (make-<skip> . args)
  '(skip))

(define (make-<csp-if> . args)
  (let-keywords
   args #f
   ((context #f)
    (expression (make <expression>))
    (then #f)
    (else #f))
   (cons <csp-if> (list context expression then else))))

(define (make-<csp-on> . args)
    (let-keywords
   args #f
   ((context #f)
    (triggers (make <triggers>))
    (statement #f))
   (cons <csp-on> (list context triggers statement))))

(define (make-<csp-reply> . args)
  (let-keywords
   args #f
   ((context #f)
    (expression #f))
   (cons <return> (list context expression))))

(define (make-<csp-return> . args)
  (let-keywords
   args #f
   ((context #f)
    (expression #f))
   (cons <return> (list context expression))))

(define (make-<semi> . args)
  (let-keywords
   args #t
   ((continuation #f)
    (statement #f))
   (cons <semi> (list statement continuation))))

(define (make-<the-end> . args)
  (let-keywords
   args #f
   ((context #f))
   (cons <the-end> (list context))))

(define (make-<voidreply> . args)
  '(voidreply))
