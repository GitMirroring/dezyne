;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag lexicals)
  #:use-module (system syntax)
  :export (local-lexicals lexicals))

(eval-when (expand load eval)
  (define (local-lexicals id)
    (filter (lambda (x)
              (eq? (syntax-local-binding x) 'lexical))
            (syntax-locally-bound-identifiers id)))

  (define-syntax lexicals
    (lambda (x)
      (syntax-case x ()
        ((lexicals) #'(lexicals lexicals))
        ((lexicals scope)
         (with-syntax (((id ...) (local-lexicals #'scope)))
           #'(list (cons 'id id) ...)))))))
