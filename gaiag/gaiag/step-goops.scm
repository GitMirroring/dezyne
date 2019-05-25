;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag step-goops)
  #:use-module (oop goops)
  #:use-module (gaiag goops)
  #:export (<node>
            <state>
            <step>

            .deferred
            .handling?
            .q
            .reply
            .return
            .stack
            .state-alist
            .status
            .steps
            .trail
            .vars
            )
  #:re-export (clone))

(define-class <step> ())
(define-method (clone (o <step>) . setters)
  (apply clone-base (cons o setters)))

(define-class <state> (<step>)
  (deferred #:getter .deferred #:init-form #f #:init-keyword #:deferred)
  (handling? #:getter .handling? #:init-form #f #:init-keyword #:handling?)
  (reply #:getter .reply #:init-form #f #:init-keyword #:reply)
  (return #:getter .return #:init-form #f #:init-keyword #:return)
  (q #:getter .q #:init-form (list) #:init-keyword #:q)
  (vars #:getter .vars #:init-form (list) #:init-keyword #:vars)) ; alist of scoped var name and value

(define-class <node> (<step>)
  (stack #:getter .stack #:init-form (list) #:init-keyword #:stack) ; <frame>
  (state-alist #:getter .state-alist #:init-form (list) #:init-keyword #:state-alist) ; '((sut b) . <state>) (sut c) . <state>))
  (steps #:getter .steps #:init-form (list) #:init-keyword #:steps)
  (trail #:getter .trail #:init-form (list) #:init-keyword #:trail)
  (status #:getter .status #:init-value #f #:init-keyword #:status))
