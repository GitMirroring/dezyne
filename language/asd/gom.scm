;; This file is part of Gaiag, Guile in Asd In Asd in Guile.
;;
;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;
;; Gaiag is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; Gaiag is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(read-set! keywords 'prefix)

(define (std-renamer lst)
  (lambda (x) (case x ((<parameter>) '<std:parameter>) ((<port>) '<std:port>) (else x))))

(define-module (language asd gom)
  :use-module (ice-9 pretty-print)

  :use-module (language asd misc)
  :use-module (language asd resolve)

  :use-module (oop goops)
;;  :use-module ((oop goops) :renamer (std-renamer '(port parameter)))
  :use-module (oop goops describe)

  :use-module (language asd gom ast)
  :use-module (language asd gom gom)
  :use-module (language asd gom display)
  :use-module (language asd gom util)

  :export (ast->))

(re-export-modules
 (language asd gom ast)
 (language asd gom gom)
 (language asd gom display)
 (language asd gom util))

(define (ast-> ast)
  (pretty-print (with-input-from-string
                    (with-output-to-string (lambda () (write (ast->gom (ast:resolve ast)))))
                  read)) "")
