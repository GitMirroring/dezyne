;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(read-set! keywords 'prefix)

(define-module (gaiag systems)
  :use-module (ice-9 and-let-star)
  :use-module (ice-9 getopt-long)

  :use-module (gaiag list match)

  :use-module (gaiag om)
  :use-module (gaiag gaiag)
  :use-module (gaiag misc)
  :use-module (gaiag reader)
  :use-module (gaiag resolve))

(define (om->systems om)
  (let* ((name (and=> (option-ref (parse-opts (command-line)) 'model #f)
                      string->symbol)))
    (let* ((systems (filter (is? <system>) om))
           (systems (if name (filter (om:named name) systems) systems)))
      (when (pair? systems)
        (stdout "~a\n" ((->join "\n") (map om:name systems))))
      (exit (or (not name) (pair? systems))))))

(define (ast-> ast)
  (let ((om ((om:register ast->om #t) ast)))
    (om->systems om))
  "")
