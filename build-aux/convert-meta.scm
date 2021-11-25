#! /run/current-system/profile/bin/guile \
-e main -s
!#
;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

;;; Commentary:

;;; This script means to maintain the history of the rewrite while
;;; being minimally disruptive to the Dezyne repository.

;;; Code:

(use-modules (srfi srfi-1)
             (srfi srfi-26)
             (ice-9 match)
             (ice-9 popen)
             (ice-9 pretty-print)
             (ice-9 rdelim)
             (dzn misc))

(define (gulp-pipe command)
  (let* ((port (open-pipe command OPEN_READ))
         (output (read-string port))
         (status (close-pipe port)))
    (if (zero? status) (string-trim-right output #\newline)
        (error (format #f "pipe failed: ~s" command)))))

(define (merge-known-and-skip alist)
  (let* ((known (or (assoc-ref alist "known") '()))
         (skip (or (assoc-ref alist "skip") '()))
         (skip (append known skip))
         (skip (filter (negate (cute member <> '("run" "step"))) skip))
         (skip (if (null? skip) '()
                   `(("skip" ,@skip))))
         (alist (filter (compose not (cute member <> '("known" "skip")) car)
                        alist)))
    `(,@skip
      ,@alist)))

(define (json->scm file-name)
  (let* ((text (with-input-from-file file-name read-string))
         (alist (json-string->alist-scm text))
         (alist (merge-known-and-skip alist))
         (alist (map (match-lambda
                       (("code_options" . value)
                        (list 'code-options (list value)))
                       (("comment" alist ...)
                        (list 'comment
                              (map (match-lambda
                                     (("true" . comment)
                                      (list #t comment))
                                     ((key . value)
                                      (list key value)))
                                   alist)))
                       ((key . value)
                        (list (string->symbol key) value)))
                     alist)))
    (with-output-to-file file-name
      (lambda _
        (write-line ";;; -*- scheme -*-")
        (pretty-print alist)))))

(define (main args)
  (match (command-line)
      ((convert-meta)
       (let ((files (string-split (gulp-pipe "git ls-files '*META*'") #\newline)))
         (for-each json->scm files)))
      ((convert-meta files ...)
       (for-each json->scm files))))
