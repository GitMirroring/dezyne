;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
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
;;; Aid for sending sensitive bug reports, do something like:
;;;
;;;    dzn parse -E foo.dzn | dzn anonymize - > anon.dzn
;;;
;;; Code:

(define-module (dzn commands anonymize)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 regex)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))))
         (options (getopt-long args option-spec))
         (help? (option-ref options 'help #f))
         (files (option-ref options '() '()))
         (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn anonymize [OPTION]... DZN-FILE
Write anonymized DZN-FILE to standard output.

  -h, --help             display this help and exit
")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define %dezyne-keywords
  '("behavior"
    "behaviour"
    "blocking"
    "bool"
    "component"
    "defer"
    "else"
    "enum"
    "extern"
    "external"
    "false"
    "if"
    "illegal"
    "import"
    "in"
    "inevitable"
    "injected"
    "inout"
    "interface"
    "invariant"
    "namespace"
    "on"
    "optional"
    "otherwise"
    "out"
    "provides"
    "reply"
    "requires"
    "return"
    "subint"
    "system"
    "true"
    "void"))

(define %keep-words
  '("Commentary"
    "Code"

    "file"
    "imported"

    "dzn"
    "verify"
    "trace"
    "simulate"

    "m"
    "q"
    "t"
    "v"

    "model"
    "queue"
    "size"
    "trail"))

(define %word-re (make-regexp "([_A-Za-z][_A-Za-z0-9]*)"))

(define (keep-word? s)
  (or (find (cute string=? s <>) %dezyne-keywords)
      (find (cute string=? s <>) %keep-words)))

(define* (anonimize text)
  (let ((anon-table (make-hash-table)))
    (define new
      (let ((count 0))
        (lambda _
          (let ((word (format #f "_~a" count)))
            (set! count (1+ count))
            word))))
    (define (next word)
      (let ((word' (new word)))
        (hash-set! anon-table word word')
        word'))
    (let loop ((text text))
      (unless (string-null? text)
        (let ((m (regexp-exec %word-re text)))
          (if (not m) (display text)
              (let* ((prefix (substring text 0 (match:start m 1)))
                     (word (match:substring m 1))
                     (text (substring text (match:end m 1)))
                     (word' (or (keep-word? word)
                                (hash-ref anon-table word)
                                (next word))))
                (display prefix)
                (display word')
                (loop text))))))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file (car files))
         (text (parse:file->string file)))
    (anonimize text)))
