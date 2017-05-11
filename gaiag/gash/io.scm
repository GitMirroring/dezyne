;;; Gash --- Guile As SHell
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@gmail.com>
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gash.
;;;
;;; Gash is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Gash is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Gash.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gash io)

  :export (stdout stderr))

(define (output port o)
  (map (lambda (o) (display o port)) o)
  (newline port)
  (force-output port))

(define (stdout . o)
  (output (current-output-port) o)
  o)

(define (stderr . o)
  (output (current-error-port) o)
  o)
