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

(define-module (dzn parse)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 pretty-print)

  #:use-module (dzn command-line)
  #:use-module (dzn display)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse ast)
  #:use-module (dzn parse peg)
  #:use-module (dzn wfc)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)

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

(define (peg:imported-from->message imported-from file-name)
  (let ((from (assoc-ref imported-from (basename file-name))))
    (if from (string-append
              (format #f "In ~a:\n" file-name)
              (let loop ((from from))
                (if from (string-append (format #f "imported from ~a:\n" from)
                                        (loop (assoc-ref imported-from (basename from))))
                    "\n")))
        "")))

(define (peg:error-message imported-from file-name string pos message)
  (display (peg:imported-from->message imported-from file-name) (current-error-port))
  (display (peg:message file-name string pos "error" message) (current-error-port)))

(define (peg:syntax-error-message imported-from file-name string args)
  (unless (or (null? args) (null? (car args)))
    (let* ((pos (caar args))
           (message (format #f "`~a' expected" (cadar args))))
      (peg:error-message imported-from file-name string pos message))))

(define* (peg:handle-syntax-error file-name string #:key (imported-from '()))
  (lambda (key . args)
    (if (or (null? args) (null? (car args))) (apply throw key args)
        (begin
          (peg:syntax-error-message imported-from file-name string args)
          (apply throw key '())))))



(define* (file+import-content-alist->ast alist #:key skip-wfc?)
  "From ALIST of form

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT)
      ...)

parse CONTENT and return an ast.  When SKIP-WCF?, skip the
well-formedness checks."

  (define (imported-from alist)
    (define parse
      (match-lambda ((file-name . content)
                     (map (cute cons <> file-name)
                          (imported-file-names content)))))
    (append-map parse alist))

  (define (expand-imports parse-tree-alist)
    (let ((file (car parse-tree-alist))
          (imports (cdr parse-tree-alist)))
      (match file
        ((file-name . root)
         (let* ((imports (append-map (match-lambda
                                       ((file-name . root) (.elements root)))
                                     imports))
                (elements (append imports (.elements root)))
                (elements (filter (negate (is? <import>)) elements)))
           (clone root #:elements elements))))))

  (let* ((parse-tree-alist
          (map (match-lambda
                 ((file-name . content)
                  (catch 'syntax-error
                    (lambda ()
                      (parameterize ((%peg:locations? #t)
                                     (%peg:skip? peg:skip-parse)
                                     (%peg:debug? (> (gdzn:debugity) 3)))
                        (cons file-name (peg:parse content))))
                    (peg:handle-syntax-error file-name content #:imported-from (imported-from alist)))))
               alist))
         (ast-alist (map (match-lambda
                           ((file-name . parse-tree)
                            (let ((content (assoc-ref alist file-name)))
                              (cons file-name
                                    (parse-tree->ast parse-tree #:string content #:file-name file-name)))))
                         parse-tree-alist))
         (ast (expand-imports ast-alist))
         (ast (annotate-ast ast)))
    (when (> (gdzn:debugity) 1)
      (ast:pretty-print ast (current-error-port)))
    (if skip-wfc? ast
        (ast:wfc ast))))

(define* (file->ast file-name #:key skip-wfc? (imports '()))
  "Parse FILE-NAME and return an ast.  When SKIP-WFC?, skip the
well-formedness checks."
  (if (equal? file-name "-") (string->ast (read-string))
      (let ((alist (file+import-content-alist file-name imports)))
        (file+import-content-alist->ast alist #:skip-wfc? skip-wfc?))))

(define* (string->ast string #:key skip-wfc?)
  "Parse STRING and return an ast.  When SKIP-WFC? skip the
well-formedness checks."
  (let ((alist (string->file+import-content-alist string)))
    (file+import-content-alist->ast alist #:skip-wfc? skip-wfc?)))

(define (string->file+import-content-alist string)
  "Split possibly pre-processed STRING at preprocessing markers

   #file \"file-name\"
   <content>
   #imported \"imported-file-name\"
   <imported-content>
   ...

and return an alist:

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)
"
  (let ((file-match (string-match "^#file \"([^\"]*)\"\n" string)))
    (if (not file-match) `(("-" . ,string))
        (let* ((file-name (match:substring file-match 1))
               (string (substring string (match:end file-match))))
          (let loop ((file-name file-name)
                     (string string)
                     (imported-match (string-match "\n#imported \"([^\"]*)\"" string)))
            (if (not imported-match) `((,file-name . ,string))
                (cons `(,file-name . ,(substring string 0 (match:start imported-match)))
                      (let ((string (substring string (match:end imported-match))))
                        (loop (match:substring imported-match 1)
                              string
                              (string-match "\n#imported \"([^\"]*)\"" string))))))))))

(define* (preprocess file-name #:key (imports '()))
  "Read @var{file-name}, using @var{imports} to resolve @code{import}
statements and return the expanded dezyne text, similar to @command{gcc
-E}."
  (let* ((content-alist (if (equal? file-name "-") (string->file+import-content-alist (read-string))
                            (file+import-content-alist file-name imports)))
         (file (car content-alist))
         (imports (cdr content-alist)))
    (string-join
     (append
      (match file
        ((file-name . content)
         (if (string-prefix? "#file " content) (list content)
             (list (format #f "#file ~s" file-name)
                   content))))
      (append-map (match-lambda ((file-name . content)
                                 (list (format #f "#imported ~s" file-name)
                                       content)))
                  imports))
     "\n")))

(define (file+import-content-alist file-name imports)
  "Recursively resolve imports starting with FILE-NAME and return an
alist:

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)

An import file name is resolved by searching for it in its parent
directory and up the ancestral tree and then along the directories
specified in IMPORTS."
  (let loop ((file-names (list (basename file-name)))
             (imports (cons (dirname file-name) imports))
             (content-alist '()))
    (if (null? file-names) (reverse content-alist)
        (let* ((file-name (or (search-path imports (car file-names))
                              (throw 'import-error (car file-names) (string-join imports))))
               (imports (delete-duplicates (cons (dirname file-name) imports))))
          (if (assoc-ref content-alist file-name) (loop (cdr file-names) imports content-alist)
              (let ((content (with-input-from-file file-name read-string)))
                (if (string-prefix? "#file \"" content) (string->file+import-content-alist content)
                    (let ((content-alist (acons file-name content content-alist)))
                      (loop (append (cdr file-names)
                                    (imported-file-names content))
                            imports
                            content-alist)))))))))

(define (imported-file-names content)
  "Return the list of file names used in import statements in content."
  (let loop ((o (parameterize ((%peg:skip? peg:skip-parse)
                               (%peg:debug? (> (gdzn:debugity) 3)))
                  (peg:imports content))))
    (match o
      (('import file-name) `(,file-name))
      (_ (append-map loop o)))))
