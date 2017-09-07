;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; This file is part of Gaiag, Guile in Asd In Asd in Guile.

(define-module (gaiag systems)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 getopt-long)

  #:use-module (ice-9 match)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag ast2om)
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)
  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)
  #:use-module (gaiag reader)
  #:use-module (gaiag resolve))

(define (om->systems om)
  (let* ((name (and (and=> (command-line:get 'model #f) string->symbol))))
    (let* ((systems (om:filter (is? <system>) om))
           (systems (if name (filter (om:named name) systems) systems)))
      (when (pair? systems)
        (stdout "~a\n" ((->join "\n") (map om:name systems))))
      (exit (or (not name) (pair? systems))))))

(define (ast-> ast)
  (let ((om ((compose ast:resolve ast->om) ast)))
    (om->systems om))
  "")
