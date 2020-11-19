;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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
;;; Dezyne Language completion using parse trees
;;;
;;; Code:

(define-module (dzn parse util)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-9 gnu)
  #:export (<location>
            make-location
            location?
            location-file
            location-line
            location-column
            location->string

            line-column->offset
            offset->line-column
            location->offset
            file-offset->location))

;;; XXX TODO: Use file-parse record: (file-name text tree) to refactor
;;; file+import-content-alist, parse-tree-alist

;;;
;;; A source location.
;;;
(define-immutable-record-type <location>
  (make-location file line column)
  location?
  (file          location-file)         ;file name
  (line          location-line)         ;1-based line
  (column        location-column))      ;0-based column

(define (location->string loc)
  "Return a human-friendly, GNU-standard representation of LOC."
  (match loc
    (#f "<unknown-location>")
    (($ <location> file line column)
     (format #f "~a:~a:~a" file line column))))


;;;
;;; Offset utilities.
;;;

;; offset: 0-based
;; line:   1-based
;; colunm: 0-based

(define (line-column->offset line column text)
  "Return 0-based offset in TEXT for position LINE:COLUMN."
  (let loop ((ln 0) (offset 0))
    (if (= ln (1- line)) (+ offset column)
        (loop (1+ ln) (1+ (or (string-index text #\newline offset) 0))))))

(define (offset->line-column offset text)
  "Return (line . column) for OFFSET in TEXT."
  (let ((offset (min (string-length text) offset)))
    (cons (1+ (string-count text #\newline 0 offset))
          (- offset (or (and=> (string-rindex text #\newline 0 offset) 1+) 0)))))

(define (location->offset loc text)
  "Return 0-based offset in TEXT for LOC."
  (line-column->offset (location-line loc) (location-column loc) text))

(define (file-offset->location file-name offset text)
  (match (offset->line-column offset text)
    ((line . column)
     (make-location file-name line column))))
