;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019, 202, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2014, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
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
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 pretty-print)

  #:use-module (dzn ast)
  #:use-module (dzn ast display)
  #:use-module (dzn ast ast)
  #:use-module (dzn ast parse)
  #:use-module (dzn ast recursive)
  #:use-module (dzn ast wfc)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn parse peg)
  #:use-module (dzn peg util)
  #:use-module (dzn parse tree)

  #:declarative? #f

  #:export (parse:call-with-handle-exceptions
            parse:file->ast
            parse:file->content-alist
            parse:file->stream
            parse:file->tree
            parse:file->tree-alist
            parse:string->ast
            parse:string->fall-back-tree
            parse:string->tree
            parse:string->tree*))

;;;
;;; Utilities.
;;;
(define* (parse:file->string #:optional (file-name "-"))
  (if (equal? file-name "-") (read-string)
      (with-input-from-file file-name read-string)))

(define (parse:handle-exceptions file-name)
  (lambda (key . args)
    (case key
      ((syntax-error)
       ;; Syntax errors should have been handled in the ->tree stage.
       #t)
      ((import-error)
       (match args
         ((file imports content-alist)
          (cond ((string=? file-name (car args))
                 (format (current-error-port) "No such file: ~a\n" file-name))
                (else
                 (let* ((imported-from (peg:imported-from content-alist))
                        (from (assoc-ref imported-from (basename file))))
                   (format (current-error-port)
                           "No such file: ~a found in: ~a;\n"
                           file (string-join imports ", "))
                   (let loop ((from from))
                     (when from
                       (format (current-error-port) "imported from ~a\n" from)
                       (loop (assoc-ref imported-from (basename from)))))))))))
      ((error)
       (apply format (current-error-port) "~a:~a:~a\n" file-name key args))
      ((well-formedness-error)
       (for-each wfc:report-message args))
      ((system-error)
       (let ((errno (system-error-errno (cons key args))))
         (format (current-error-port) "~a: ~a\n"
                 (strerror errno) file-name)))
      ((quit)
       (apply exit args))
      (else
       (apply format (current-error-port) "internal error: ~a: ~a: ~s\n"
              file-name key args)))))

(define* (parse:call-with-handle-exceptions thunk #:key backtrace? (exit? #t)
                                            (file-name "-"))
  (catch (if backtrace? 'none #t)
    thunk
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (and exit?
           (exit EXIT_FAILURE)))))


;;;
;;; Content-aist.
;;;
(define (parse:string->content-alist string)
  (if (parse:preprocessed? string) (parse:stream->content-alist string)
      `(("-" . ,string))))

(define* (parse:file->content-alist file-name #:key (imports '())
                                    (content-alist '()))
  "Recursively resolve imports starting with FILE-NAME and return an alist
of form:

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)

An import file name is resolved by searching for it in its parent
directory and up the ancestral tree and then along the directories
specified in IMPORTS."
  (define (canonicalize-path-memoized path)
    ((pure-funcq
      (lambda (path-symbol)
        (canonicalize-path (symbol->string path-symbol))))
     (string->symbol path)))

  (define (read-file file-name)
    (let ((content (parse:file->string file-name)))
      (cons file-name content)))

  (define (resolve from imports imported content-alist)
    (map (lambda (import)
           (let* ((paths (cons (dirname from) imports))
                  (file-name (search-path paths import)))
             (unless file-name
               (throw 'import-error import paths content-alist))
             file-name))
         imported))

  (define (canonical-file-name=? a b)
    (string=? (canonicalize-path-memoized a)
              (canonicalize-path-memoized b)))

  (let ((content (parse:file->string file-name)))
    (if (parse:preprocessed? content) (parse:stream->content-alist content)
        (let* ((content-alist (acons file-name content content-alist))
               (file-names (resolve file-name imports
                                    (peg:imported-file-names content)
                                    content-alist)))
          (let loop ((file-names file-names)
                     (content-alist content-alist))
            (if (null? file-names) (reverse content-alist)
                (let* ((file-names (delete-duplicates
                                    file-names
                                    canonical-file-name=?))
                       (file-names (lset-difference
                                    canonical-file-name=?
                                    file-names
                                    (map car content-alist)))
                       (alist (reverse (map read-file file-names)))
                       (content-alist (append alist content-alist))
                       (file-names
                        (append-map
                         (match-lambda
                           ((file-name . content)
                            (resolve file-name imports
                                     (peg:imported-file-names content)
                                     content-alist)))
                         alist)))
                  (loop file-names content-alist))))))))


;;;
;;; Parse tree, tree-alist.
;;;
(define* (parse:string->tree string #:key (content-alist '()) (file-name "-")
                             (locations? (not (eq? (%peg:locations?) 'none))))
  "Parse @var{string} and return a parse tree, printing any syntax errors."
  (parameterize ((%peg:locations? locations?)
                 (%peg:skip? peg:skip-parse)
                 (%peg:debug? (> (dzn:debugity) 3)))
    (catch 'syntax-error
      (lambda _
        (let* ((tree (peg:parse string))
               (tree (match tree
                       (('root tree ...)
                        `(root
                             ,@(if (not file-name) '()
                                   `((file-name ,file-name (location 0 0))))
                           ,@tree))))
               (tree (if (%peg:fall-back?) (peg:flatten-tree tree)
                         tree))
               (tree (tree:normalize tree)))
          (when (> (dzn:debugity) 2)
            (debug "tree: ~a" file-name)
            (pretty-print tree (current-error-port)))
          tree))
      (lambda (key . args)
        (apply (peg:handle-syntax-error
                file-name string #:content-alist content-alist)
               key args)))))

(define* (parse:string->tree* string #:key (content-alist '()) (file-name "-"))
  "Parse @var{string} and return a parse tree, trying a regular parse
first and upon failure return a fall-back tree.  Note that the
fall-back tree may differ from the non-fall-back tree (even) if there
are no errors."
  ;; Attempt a regular parse first
  (parameterize ((%peg:fall-back? #f)
                 (%peg:locations? #t)
                 (%peg:skip? peg:skip-parse)
                 (%peg:debug? (> (dzn:debugity) 3)))
    (catch 'syntax-error
      (lambda _
        (parse:string->tree string
                            #:content-alist content-alist
                            #:file-name file-name))
      (lambda (key . args)
        (parameterize ((%peg:fall-back? #t))
          (parse:string->tree string
                              #:content-alist content-alist
                              #:file-name file-name))))))

(define (parse:file->tree file-name)
  "Parse @var{file-name} using @var{content-alist} to resolve import
files."
  (let ((string (parse:file->string file-name)))
    (parse:string->tree string #:file-name file-name)))

(define* (parse:content-alist->tree-alist content-alist)
  "From CONTENT-ALIST of form

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)

parse CONTENT and return a TREE-ALIST of form

'((FILE-NAME . TREE)
  (IMPORTED-FILE-NAME . IMPORTED-TREE) ...)"

  (define file+content->file+tree
    (match-lambda
      ((file-name . content)
       (let ((tree (parse:string->tree content
                                       #:file-name file-name
                                       #:content-alist content-alist)))
         (cons file-name tree)))))
  (map file+content->file+tree content-alist))

(define* (parse:file->tree-alist+content-alist file-name #:key (imports '()))
  "Parse @var{file-name} using @var{imports} to resolve import files,
and return two values, the @var{tree-alist}, and the
@var{content-alist}."
  (let* ((content-alist (parse:file->content-alist file-name #:imports imports))
         (tree-alist (parse:content-alist->tree-alist content-alist)))
    (values tree-alist content-alist)))

(define* (parse:file->tree-alist file-name #:key (imports '()))
  "Parse @var{file-name} using @var{imports} to resolve import files,
and the @var{tree-alist}."
  (let ((content-alist (parse:file->content-alist file-name #:imports imports)))
    (parse:content-alist->tree-alist content-alist)))


;;;
;;; Ast.
;;;
(define* (parse:annotate-ast ast)
  (let ()
    (when (> (dzn:debugity) 1)
      (debug "ast:")
      (ast:pretty-print ast (current-error-port)))
    ast))

(define* (parse:tree-alist->ast tree-alist #:key (content-alist '()))
  "Return an AST by merging TREE-ALIST of form

   '((FILE-NAME . TREE)
     (IMPORTED-FILE-NAME . IMPORTED-TREE) ...)

optionally using CONTENT-ALIST of form

    `((FILE-NAME . CONTENT) ...)
"
  (define (expand-imports ast-alist)
    (let ((file (car ast-alist))
          (imports (cdr ast-alist)))
      (match file
        ((file-name . root)
         (let* ((imports (append-map (match-lambda
                                       ((file-name . root) (.elements root)))
                                     imports))
                (elements (append imports (.elements root))))
           (clone root #:elements elements))))))

  (define file+tree->ast
    (match-lambda
      ((file-name . tree)
       (let ((content (assoc-ref content-alist file-name)))
         (cons file-name
               (parse:tree->ast tree
                                #:string content
                                #:file-name file-name))))))

  (let* ((ast-alist (map file+tree->ast tree-alist))
         (ast (expand-imports ast-alist)))
    ast))

(define* (parse:file->ast file-name #:key (imports '()))
  "Parse FILE-NAME and return an ast."
  (let* ((tree-alist content-alist (parse:file->tree-alist+content-alist
                                    file-name #:imports imports))
         (ast (parse:tree-alist->ast tree-alist #:content-alist content-alist)))
    (parse:annotate-ast ast)))

(define (parse:string->ast string)
  "Parse STRING and return an ast."
  (let* ((content-alist (parse:string->content-alist string))
         (tree-alist (parse:content-alist->tree-alist content-alist)))
    (and (pair? tree-alist)
         (let ((ast (parse:tree-alist->ast
                     tree-alist #:content-alist content-alist)))
           (parse:annotate-ast ast)))))


;;;
;;; Stream / preprocess.
;;;
(define (parse:file-match stream)
  "Return preprocessor file match for STREAM."
  (let ((file-regexp "#(file|imported) \"([^\"]*)\"\n"))
    (string-match file-regexp stream)))

(define (parse:preprocessed? stream)
  (and=> (parse:file-match stream)
         (compose (cute equal? <> "file")
                  (cute match:substring <> 1))))

(define* (parse:file->stream file-name #:key (imports '()))
  "Read @var{file-name}, using @var{imports} to resolve @code{import}
statements and return the expanded dezyne text, similar to @command{gcc
-E}."

  (define import+content->stream-lines
    (match-lambda
      ((file-name . content)
       (list (format #f "#imported ~s" file-name)
             content))))

  (let ((content-alist (parse:file->content-alist file-name #:imports imports)))

    (define file+content->stream-lines
      (match-lambda
        ((file-name . content)
         (if (parse:preprocessed? content) (list content)
             (list (format #f "#file ~s" file-name)
                   content)))))

    (let* ((file+content (car content-alist))
           (imports (cdr content-alist))
           (file-lines (file+content->stream-lines file+content))
           (import-lines (append-map import+content->stream-lines imports))
           (lines (append file-lines import-lines)))
      (string-join lines "\n"))))

(define (parse:stream->content-alist stream)
  "Split pre-processed string STREAM at preprocessing markers

   #file \"file-name\"
   <content>
   #imported \"imported-file-name\"
   <imported-content>
   ...

and return an alist of form

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...) "

  (define (stream->file-name+stream stream)
    (let* ((m (parse:file-match stream))
           (file-name (match:substring m 2))
           (stream (substring stream (match:end m))))
      (values file-name stream)))

  (define (stream->content+stream stream)
    (let* ((m (parse:file-match stream))
           (content (if (not m) stream
                        (substring stream 0 (1- (match:start m)))))
           (stream (if (not m) ""
                       (substring stream (match:start m)))))
      (values content stream)))

  (unless (parse:preprocessed? stream)
    (throw 'invalid-input "pre-processor stream expected, got" stream))
  (let loop ((stream stream))
    (if (string-null? stream) '()
        (let* ((file-name stream (stream->file-name+stream stream))
               (content stream (stream->content+stream stream)))
          (cons `(,file-name . ,content)
                (loop stream))))))
