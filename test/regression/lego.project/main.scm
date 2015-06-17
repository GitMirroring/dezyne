;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define (drop-prefix string prefix)
  (if (string-prefix? prefix string)
      (substring string (string-length prefix))
      string))

(define (consume_synchronous_out_events event-alist)
  (read-line)
  (let loop ((line (read-line)))
    (and-let* ((line line) 
               ((not (eof-object? line)))
               (event (assoc-ref event-alist (string->symbol line))))
              (event)
              (loop (read-line)))
    line))

(define (log-in prefix event event-alist)
  (stderr "~a~a\n" prefix event)
  (consume_synchronous_out_events event-alist)
  (stderr "~a~a\n" prefix 'return)
  #f)

(define (log-out prefix event event-alist)
  (stderr "~a~a\n" prefix event)
  #f)

(define (log-valued prefix event event-alist string->value value->symbol)
  (stderr "~a~a\n" prefix event)
  (let* ((s (consume_synchronous_out_events event-alist))
         (r (string->value s)))
    (if r
        (and (stderr "~a~a\n" prefix (value->symbol r))
             r)
        #f)))

(define (fill-event-alist o)
  (let ((e `(
             (port.create . ,(.create (.in (.port o))))
             (port.cancel . ,(.cancel (.in (.port o)))))))
          (set! (.timeout (.out (.port o)))
       (lambda (. args)
      (log-out "port." 'timeout e)))
      e))


(define (log-in prefix event event-alist)
  (stderr "~ain.~a\n" prefix event)
  #f)

(define (log-out prefix event event-alist)
  (stderr "~aout.~a\n" prefix event)
  #f)

(define (log-valued prefix event event-alist string->value value->symbol)
  (stderr "~ain.~a\n" prefix event)
  (stderr "~a~a\n" prefix (value->symbol 0))
  0)

(define (main . args)
  (let* ((print-illegal (lambda () (stderr "illegal\n") (exit 0)))
         (locator (make <locator>))
         (runtime (make <runtime> :illegal print-illegal))
         (sut (make <timer> :locator (set locator runtime) :name 'sut))
         (event-alist (fill-event-alist sut)))
    (while (and-let*
            ((line (read-line))
             ((not (eof-object? line))))
            (or (and-let* ((event (assoc-ref event-alist (string->symbol line))))
                          (event))
                #t)))))
