;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag goops simulate)
  :use-module (ice-9 optargs)
  :use-module (gaiag goops om)
  :export (
           <info>
           .trail
           .q
           .state
           .reply
           .return
           .state-alist
           .trace
           .error
           )
  :re-export (
              .ast
              ))

(define-class <info> (<ast>)
  (trail :accessor .trail :init-form (list) :init-keyword :trail)
  (ast :accessor .ast :init-form (list) :init-keyword :ast)
  (state :accessor .state :init-form (list) :init-keyword :state)
  (q :accessor .q :init-form (list) :init-keyword :q)
  (reply :accessor .reply :init-form 'return :init-keyword :reply)
  (return :accessor .return :init-form #f :init-keyword :return)
  (state-alist :accessor .state-alist :init-form (list) :init-keyword :state-alist)
  (trace :accessor .trace :init-form (list) :init-keyword :trace)
  (error :accessor .error :init-form #f :init-keyword :error))
