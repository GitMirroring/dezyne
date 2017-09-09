;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015, 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2014, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag wfc)
  #:use-module (ice-9 and-let-star)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 optargs)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)

  #:use-module (language dezyne location)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag ast)

  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag util)

  #:export (
           ast:wfc
           ))

(define (ast:wfc o)
  (and-let* ((errors (null-is-#f
                      ((om:collect <error>)
                       (append
                        (interface o)
                        (component o)
                        ((second-on) o)
                        (mixing-declarative-imperative o))))))
            (report-errors errors))
  o)

(define (wfc-error o message)
  (make <error> #:ast o #:message (string-append "not well-formed: " message)))

(define (interface o)
  (match o
    (($ <root> (elements ...)) '(()) (append-map interface elements))
    (($ <interface> name ($ <types>) ($ <events>) #f)
     (list (wfc-error o "interface must have a behaviour")))
    (_ '())))

(define (component o)
  (match o
    (($ <root> (elements ...)) '(()) (append-map component elements))
    (($ <component> name ($ <ports> (ports ...)) ($ <behaviour>))
     ((om:filter:p <error>)
      (if (>0 (length (filter om:provides? ports))) '()
          (list (wfc-error o "component with behaviour must have one provides port")))))
    (_ '())))

(define* ((second-on #:optional (count 0)) o)
  (match o
    (($ <root> (elements ...)) (append-map (second-on) elements))
    (($ <system>) '())
    (($ <foreign>) '())
    (($ <interface>) (or (and=> (.behaviour o) (second-on)) '()))
    (($ <component>) (or (and=> (.behaviour o) (second-on)) '()))
    (($ <behaviour>) (or (and=> (.statement o) (second-on)) '()))
    (($ <compound> (statements ...)) (map (second-on count) statements))
    (($ <on> triggers statement)
     (if (>0 count) (wfc-error o "second on")
         ((second-on (1+ count)) statement)))
    (($ <guard> expression statement) ((second-on count) statement))
    (_ '())))

(define (mixing-declarative-imperative o)
  (match o
    (($ <root> (elements ...)) (append-map mixing-declarative-imperative elements))
    (($ <system>) '())
    (($ <foreign>) '())
    (($ <interface>) (or (and=> (.behaviour o) mixing-declarative-imperative) '()))
    (($ <component>) (or (and=> (.behaviour o) mixing-declarative-imperative) '()))
    (($ <behaviour>) (or (and=> (.statement o) mixing-declarative-imperative) '()))
    ((and ($ <compound> (statements ...)) (? om:declarative?))
     (append
      (or (and-let* ((imperative
                      (null-is-#f (filter om:imperative? statements)))
                     (ast (car imperative)))
                    (list (wfc-error ast "mixing imperative")))
          '())
      (append-map mixing-declarative-imperative statements)))
    (($ <compound> (statements ...))
     (append
      (or (and-let* ((declarative
                      (null-is-#f (filter om:declarative? statements)))
                     (ast (car declarative)))
                          (list (wfc-error ast "mixing declarative")))
          '())
      (append-map mixing-declarative-imperative statements)))
    (($ <on> triggers statement) (mixing-declarative-imperative statement))
    (($ <guard> epression statement) (mixing-declarative-imperative statement))
    (($ <if> expression then #f) (mixing-declarative-imperative then))
    (($ <if> expression then else) (append (mixing-declarative-imperative then)
                                           (mixing-declarative-imperative else)))
    (_ '())))

(define (ast-> ast)
  ((compose
    om->list
    ast:wfc
    ast:resolve
    parse->om
    ) ast))
