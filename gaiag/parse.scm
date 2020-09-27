;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2017, 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019, 202 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2014, 2018, 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag parse)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 pretty-print)

  #:use-module (gaiag command-line)
  #:use-module (gaiag parse peg)
  #:use-module (gaiag parse ast)
  #:use-module (gaiag parse peg)
  #:use-module (gaiag wfc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)

  #:export (file->ast
            string->ast
            peg:handle-syntax-error
            preprocess))

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

(define* (peg:error-message file-name string pos message)
    (display (peg:message file-name string pos "error" message) (current-error-port)))

(define* (peg:handle-error file-name string pos message #:key (key 'syntax-error))
  (peg:error-message file-name string pos message)
  (throw key '()))

(define (peg:syntax-error-message file-name string args)
  (unless (or (null? args) (null? (car args)))
    (let* ((pos (caar args))
           (message (format #f "`~a' expected" (cadar args))))
      (peg:error-message file-name string pos message))))

(define (peg:handle-syntax-error file-name string)
  (lambda (key . args)
    (if (or (null? args) (null? (car args))) (apply throw key args)
        (begin
          (peg:syntax-error-message file-name string args)
          (apply throw key '())))))

(define (is-a? o symbol)
  (and (pair? o) (eq? symbol (car o))))

(define (is? symbol)
  (lambda (o) (is-a? o symbol)))

(define (expand-imports parse-tree-alist)
  "Turn an alist of file names and parse trees, into a single parse-tree
by replacing import nodes by the actual parse trees."
  (let ((parse-tree (cdr (last parse-tree-alist)))
        (imports (drop-right parse-tree-alist 1)))
    `(root
         ,@(append
            (map (lambda (i)
                   (let ((file-name (car i))
                         (root (filter (negate (is? 'import)) (cdr i))))
                     `(import ,file-name ,root))) imports)
            (filter (negate (is? 'import)) (cdr parse-tree))))))

(define* (parse-string string #:key (file-name "-") (imports '()))
  (let* ((parse-tree-alist (map (lambda (p)
                                  (let ((file-name (car p))
                                        (content (cdr p)))
                                    (catch 'syntax-error
                                      (lambda ()
                                        (parameterize ((%peg:locations? #t)
                                                       (%peg:skip? peg:skip-parse)
                                                       (%peg:debug? (> (gdzn:debugity) 3)))
                                          (cons file-name (peg:parse content))))
                                      (peg:handle-syntax-error file-name content))))
                                (if (string=? "-" file-name) `(,(cons file-name string))
                                    (file+import-content-alist file-name imports))))
         (parse-tree (expand-imports parse-tree-alist))
         (gdzn-debug? (gdzn:command-line:get 'debug)))
    (when (> (gdzn:debugity) 2)
      (pretty-print parse-tree (current-error-port)))
    parse-tree))

(define* (file->ast file-name #:key peg? (imports '()))
  (let* ((string (if (equal? file-name "-") (read-string)
                     (with-input-from-file file-name read-string)))
         (parse-tree (parse-string string #:file-name file-name #:imports imports))
         (ast (parse-tree->ast parse-tree #:string string #:file-name file-name))
         (ast (ast:annotate ast)))
    (when (> (gdzn:debugity) 1)
      (pretty-print ast  (current-error-port)))
    (if peg? ast
        (ast:wfc ast))))

(define* (string->ast string #:key peg?)
  (let* ((parse-tree (parse-string string))
         (ast (parse-tree->ast parse-tree #:string string))
         (ast (ast:annotate ast)))
    (if peg? ast
        (ast:wfc ast))))

(define* (preprocess file-name #:key (imports '()))
  "Read @var{file-name}, using @var{imports} to resolve @code{import}
statements and return the expanded dezyne text, similar to @command{gcc
-E}."
(let* ((content-alist (file+import-content-alist file-name imports))
       (file (last content-alist)))
  (cons* (string-append "#file " (car file))
         (cdr file)
         (append-map
          (lambda (o)
            `(,(string-append "#imported " (car o))
              ,(cdr o)))
          (drop-right content-alist 1)))))

(define* (file+import-content-alist file-name imports)
  "Turn a FILE-NAME into an alist of the file name and the file content
and do the same for its import dependencies given the list of
IMPORTS. An import file-name is resolved by searching for it in its
parent directory and up the ancestral tree and then along the paths
specified in IMPORTS."
  (let loop ((file-names (list (basename file-name)))
             (imports (cons (dirname file-name) imports))
             (content-alist '()))
    (if (null? file-names) content-alist
        (let* ((file-name (or (search-path imports (car file-names))
                              (throw 'import-error (car file-names) (string-join imports))))
               (imports (delete-duplicates (cons (dirname file-name) imports))))
          (if (assoc-ref content-alist file-name) (loop (cdr file-names) imports content-alist)
              (let* ((content-alist (acons file-name
                                           (with-input-from-file file-name read-string)
                                           content-alist)))
                (loop (append (cdr file-names)
                              (let loop ((o (parameterize ((%peg:skip? peg:skip-parse)
                                                           (%peg:debug? (> (gdzn:debugity) 3)))
                                              (peg:imports (assoc-ref content-alist file-name)))))
                                (match o
                                  (('import file-name) `(,file-name))
                                  (_ (append-map loop o)))))
                      imports
                      content-alist)))))))
