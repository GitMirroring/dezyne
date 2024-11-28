;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn commands hash)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (rnrs bytevectors)
  #:use-module (dzn command-line)
  #:use-module (dzn hash)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn shell-util)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
            (import (single-char #\I) (value #t))))
         (options (getopt-long args option-spec))
         (help? (option-ref options 'help #f))
         (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn hash [OPTION]... DZN-FILE...
  -h, --help             display this help and exit
  -I, --import=DIR+      add DIR to import path
")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define* (file-name->hash file-name #:key debug? (imports '()) verbose?)
  (parse:call-with-handle-exceptions
   (lambda _
     (let* ((hash (dzn-hash file-name #:imports imports))
            (bytes (bytevector->u8-list hash))
            (hex (map (cute number->string <> 16) bytes))
            (hex (map (cute format #f "~2,'0x" <>) bytes))
            (hex-string (apply string-append hex)))
       (if (not verbose?) (format #t "~a\n" hex-string)
           (format #t "~a  ~a\n" hex-string file-name))))
   #:backtrace? debug?
   #:file-name file-name))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (dir? (file-is-directory? (car files)))
         (files (append-map file-name->dzn-files files))
         (imports (command-line:get 'import))
         (debug? (dzn:command-line:get 'debug))
         (verbose? (dzn:command-line:get 'verbose))
         (verbose? (or verbose?
                       dir?
                       (> (length files) 1))))
    (for-each
     (cut file-name->hash <> #:imports imports
          #:debug? debug? #:verbose? verbose?)
     files)))
