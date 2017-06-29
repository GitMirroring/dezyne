;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gash glob)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  :use-module (ice-9 ftw)
  #:use-module (ice-9 regex)

  #:use-module (gash util)

  #:export (glob))

(define (glob pattern) ;; pattern -> list of path

  (define (glob? pattern)
    (string-match "\\?|\\*" pattern))

  (define (glob2regex pattern)
    (let* ((pattern (regexp-substitute/global #f "\\." pattern 'pre "\\." 'post))
           (pattern (regexp-substitute/global #f "\\?" pattern 'pre "." 'post))
           (pattern (regexp-substitute/global #f "\\*" pattern 'pre ".*" 'post)))
      (make-regexp (string-append "^" pattern "$"))))

  (define (glob-match regex path) ;; pattern path -> bool
    (regexp-match? (regexp-exec regex path)))

  (define (glob- pattern paths)
    (map (lambda (path)
           (if (string-prefix? "./" path) (string-drop path 2) path))
         (append-map (lambda (path)
                       (map (cute string-append (if (string=? "/" path) "" path) "/" <>)
                            (filter (conjoin (negate (cut string-prefix? "." <>))
                                             (cute glob-match (glob2regex pattern) <>))
                                    (or (scandir path) '()))))
                     paths)))
  (if (glob? pattern)
      (let ((absolute? (string-prefix? "/" pattern)))
        (let loop ((patterns (filter (negate string-null?) (string-split pattern #\/)))
                   (paths (if absolute? '("/") '("."))))
          (if (null? patterns)
              paths
              (loop (cdr patterns) (glob- (car patterns) paths)))))
      (list pattern)))
