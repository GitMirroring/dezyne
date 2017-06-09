;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

(use-modules (srfi srfi-1))

(define (readlink-f path)
  (define (try-readlink path)
    (catch #t
      (lambda () (readlink path))
      (lambda (key . parameters) path)))
  (reduce (lambda (next previous)
            (try-readlink (string-append previous "/" next)))
          path
          (string-split path #\/)))

(let* ((path (car (command-line)))
       (path (readlink-f path))
       (prefix (dirname (dirname path)))
       (prefix (if (string=? (basename prefix) "gaiag")
                   prefix
                   (string-append prefix "/gaiag"))))
  (if (not (getenv "DEZYNE_PREFIX"))
      (setenv "DEZYNE_PREFIX" (string-append prefix "/..")))
  (setenv "PATH" (string-append (string-append prefix "/../bin:") (getenv "PATH")))
  (set! %load-path (append (list prefix ".") %load-path))
  (set! %load-compiled-path (append (list prefix ".") %load-compiled-path)))
