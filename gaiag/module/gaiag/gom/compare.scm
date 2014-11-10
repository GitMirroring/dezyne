;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(read-set! keywords 'prefix)

(define-module (gaiag gom compare)
  :use-module (oop goops)

  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag gom ast)
  :use-module (gaiag gom gom)
  :use-module (gaiag gom display)

  :re-export (<))

(define-method (< (lhs <on>) (rhs <on>))
  (< (.triggers lhs) (.triggers rhs)))

(define-method (< (lhs <triggers>) (rhs <triggers>))
  (< (stable-sort (.elements lhs) <)
     (stable-sort (.elements rhs) <)))

(define-method (< (lhs <trigger>) (rhs <trigger>))
  (if (and (not (< (.port lhs) (.port rhs)))
           (not (< (.port rhs) (.port lhs))))
      (symbol< (.event lhs) (.event rhs))
      (cond
       ((not (.port lhs)) #t)
       ((not (.port rhs)) #f)
       (else
        (symbol< (.port lhs) (.port rhs))))))

(define-method (< (lhs <list>) (rhs <list>))
  (let loop ((lhs lhs) (rhs rhs))
    (if (or (null? lhs) (null? rhs))
        (< (length lhs) (length rhs))
        (if (and (not (< (car lhs) (car rhs)))
                 (not (< (car rhs) (car lhs))))
            (loop (cdr lhs) (cdr rhs))
            (< (car lhs) (car rhs))))))

(define-method (< (lhs <symbol>) (rhs <symbol>))
  (symbol< lhs rhs))

(define-method (< (lhs <boolean>) (rhs <symbol>))
  #t)

(define-method (< (lhs <boolean>) (rhs <boolean>))
  #f)

(define-method (< (lhs <symbol>) (rhs <boolean>))
  #f)
