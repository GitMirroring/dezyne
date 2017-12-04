;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;;
;;; This file is part of Gaiag.
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

(define-module (gaiag json)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)

  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 match)

  #:use-module (gaiag location)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag util)

  #:use-module (gaiag misc)
  #:use-module (gaiag parse)

  #:export (
           json-location
           ))

(define (json-location o)
  (match o
    ((? (is? <ast>))
     (or (and-let* ((loc (source-location o))
                    (properties (source-location->user-source-properties loc)))
           `((file . ,(assoc-ref properties 'filename))
             (line . ,(assoc-ref properties 'line))
             (column . ,(assoc-ref properties 'column))
             (offset . ,(assoc-ref properties 'offset))
             (length . ,(assoc-ref properties 'length))))
         '()))
    (_ '())))
