;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2025 Rutger van Beusekom <rutger@dezyne.org>
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
;;; License along with Dezyne.  If not, see <http:;;;www.gnu.org/licenses/>.
;;;
;;; Commentary:
;;;
;;; Usage: dzn parse -E foo/bar.dzn | guile build-aux/postprocess.scm
;;; writes the combined file content to `bar.dzn'.
;;;
;;; Code:

(use-modules (srfi srfi-26)
             (srfi srfi-71)
             (ice-9 rdelim)
             (ice-9 regex))

(define hash-re "(#file|#imported)[ \t]+\"([^\"]+)\"")

(define (read-content port)
  (let loop ((content "") (directive #f))
    (let* ((file-content (read-delimited "#" port 'peek))
           (line (read-line port)))
      (if (or (eof-object? line) (string-match hash-re line))
          (values line (string-append content file-content))
          (loop (string-append content file-content line)  directive)))))

(let ((port (current-input-port)))
  (let loop ((line (read-line port)))
    (when (and (not (eof-object? line))
               (string-prefix? "#" line))
      (let ((m (string-match hash-re line)))
        (when m
          (let ((file-name (match:substring m 2))
                (line file-content (read-content port)))
            (when (or (equal? (dirname file-name) ".")
                      (equal? (dirname (canonicalize-path file-name))
                              (canonicalize-path (getcwd))))
              (format (current-error-port)
                      "error: cowardly refusing to clobber: ~a\n" file-name)
              (exit 2))
            (let ((file-name (basename file-name)))
              (format #t "writing: ~a\n" file-name)
              (with-output-to-file file-name
                (cute display file-content)))
            (loop line)))))))
