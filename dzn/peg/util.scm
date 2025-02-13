;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2019, 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021, 2023 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2019 Johri van Eerd <vaneerd.johri@gmail.com>
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

(define-module (dzn peg util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 regex)

  #:use-module (dzn command-line)
  #:use-module (dzn parse peg)

  #:export (peg:column-number
            peg:error-message
            peg:flatten-tree
            peg:handle-syntax-error
            peg:imported-file-names
            peg:imported-from
            peg:imported-from->message
            peg:line
            peg:line-number
            peg:message
            peg:format-capture-syntax-error
            peg:format-display-syntax-error))

(define (peg:flatten-tree tree)
  "When in fall-back mode, the parse tree may contain non-tree
constructs like ...((action ...)) or ((variable ...) ...).  Remove
such unnamed lists."
  (define (tree? x)
    (match x
      (((? symbol?) slot ...) #t)
      (_ #f)))
  (define (helper tree)
    (match tree
      ((? tree?)
       (map helper tree))
      (((and (? tree?) tree))
       (map helper tree))
      ((and (((? symbol?) rest ...) x ...) tree)
       (cons 'compound (map helper tree)))
      (_
       tree)))
  (map helper tree))

(define (peg:line-number string pos)
  (1+ (string-count string #\newline 0 pos)))

(define (peg:column-number string pos)
  (- pos (or (string-rindex string #\newline 0 pos) -1)))

(define (peg:line string pos)
  (let ((start (1+ (or (string-rindex string #\newline 0 pos) -1)))
        (end (or (string-index string #\newline pos) (string-length string))))
    (substring string start end)))

(define (peg:message file-name string pos error message)
  (let* ((line-number (peg:line-number string pos))
         (column-number (peg:column-number string pos))
         (line (peg:line string pos))
         (indent (make-string (1- column-number) #\space))
         (hanging (string-append indent message)))
    (string-append
     (format #f "~a:~a:~a: ~a\n~a\n~a^\n"
             file-name line-number column-number
             error line indent)
     (if (string-null? hanging) ""
         (string-append hanging "\n")))))

(define (peg:imported-file-names content)
  "Return the list of file names used in import statements in content."
  (let ((tree (parameterize ((%peg:locations? #f)
                             (%peg:skip? peg:import-skip-parse)
                             (%peg:debug? (> (dzn:debugity) 3)))
                (peg:imports content))))
    (match tree
      (('import file-name) (list file-name))
      ((('import file-name rest ...) ...) file-name))))

(define (peg:imported-from alist)
  "Return an alist of imported file names"
  (define parse
    (match-lambda ((file-name . content)
                   (map (cute cons <> file-name)
                        (peg:imported-file-names content)))))
  (append-map parse alist))

(define (peg:imported-from->message content-alist file-name)
  (let* ((imported-from (peg:imported-from content-alist))
         (from (assoc-ref imported-from (basename file-name))))
    (if (not from) ""
        (string-append
         (format #f "In ~a:\n" file-name)
         (let loop ((from from))
           (if from (string-append (format #f "imported from ~a:\n" from)
                                   (loop (assoc-ref imported-from (basename from))))
               "\n"))))))

(define (peg:error-message content-alist file-name string pos message)
  (display (peg:imported-from->message content-alist file-name) (current-error-port))
  (display (peg:message file-name string pos "error" message) (current-error-port)))

(define (peg:syntax-error->message e string pos)
  (define (unknown-identifier? e)
    (match e
      (('not-followed-by 'unknown-identifier) #t)
      ((symbol items ...) (any unknown-identifier? items))
      (_ #f)))

  (define (name string pos)
    (let ((m (string-match "[a-zA-Z_][a-zA-Z_0-9]*" (substring string pos))))
      (or (match:substring m)
          "")))

  (define (error->string e)
    (match e
      ('port-trigger "trigger")
      ('is-event "event")
      ('OPTIONAL "optional")
      ('INEVITABLE "inevitable")
      ('dq-string "double quoted string")
      ('compound-name "name or dotted name")
      ('BRACE-OPEN "{")
      ('BRACE-CLOSE "}")
      ('SEMICOLON ";")
      ('COMMA "comma")
      ('COLON ":")
      ('NUMBER "number")
      ('DOLLAR "$")
      ('DOTDOT "..")
      ('data "dollar expression")
      (('followed-by item) (error->string item))
      (('not-followed-by item) #f)
      (('and items ...) (string-join (filter-map error->string items) " "))
      (('or items ...) (string-join (filter-map error->string items) ", "))
      (('expect item) (error->string item))
      ((? symbol?) (symbol->string e))
      ((? string?) e)))

  (let ((message (error->string e)))
    (if (not (unknown-identifier? e)) (string-append "`" message "' expected")
        (string-append "undefined identifier `" (name string pos) "'"))))

(define* (peg:handle-syntax-error file-name string #:key (content-alist '()))
  (lambda (key . args)
    (unless (or (null? args) (null? (car args)))
      (let* ((pos (caar args))
             (message (peg:syntax-error->message (cadar args) string pos)))
        (peg:error-message content-alist file-name string pos message)))
    (apply throw key args)))

(define (peg:format-capture-syntax-error error-collector)
  "Return a procedure that generates a human-readable message and passes
it to the ERROR-COLLECTOR procedure."
  (lambda (str line-number col-number error-type error)
    (let ((message (peg:syntax-error->message (cadar error) str (caar error))))
      (error-collector error-type message line-number col-number))))

(define (peg:format-display-syntax-error file-name)
  "Return a procedure that to format GNU style error message for
FILE-NAME."
  (lambda (str line-number col-number error-type error)
    (let ((message (peg:syntax-error->message (cadar error) str (caar error))))
      (format (current-error-port) "~a:~a:~a: ~a\n"
              file-name line-number col-number message))))
