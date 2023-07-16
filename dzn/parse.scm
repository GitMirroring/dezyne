;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019, 202, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2014, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2014, 2018, 2020, 2021, 2024 Rutger (regtur) van Beusekom <rutger@dezyne.org>
;;; Copyright © 2023 Karol Kobiela <karol.kobiela@verum.com>
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
  #:use-module (dzn ast goops)
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
            parse:string->tree))

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
      (else
       (apply format (current-error-port) "internal error: ~a: ~a: ~s\n"
              file-name key args)))))

(define* (parse:call-with-handle-exceptions thunk #:key backtrace? (exit? #t)
                                            (file-name "-"))
  (catch (if backtrace? 'none #t)
    thunk
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (when exit?
        (exit EXIT_FAILURE))
      (values #f #t))))


;;;
;;; Content-aist.
;;;
(define (parse:string->content-alist string)
  "Split possibly pre-processed STRING at preprocessing markers

   #dir \"working directory\"
   #file \"file-name\"
   <content>
   #imported \"imported-file-name\"
   <imported-content>
   ...

and return two values, an alist:

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)

and the working directory.
"
  (let ((imported-regexp "\n#imported \"([^\"]*)\"\n")
        (file-match (string-match (string-append "^#dir \"([^\"]*)\"\n"
                                                 "#file \"([^\"]*)\"\n")
                                  string)))
    (if (not file-match) (values `(("-" . ,string)) (getcwd))
        (let* ((dir (match:substring file-match 1))
               (file-name (match:substring file-match 2))
               (string (substring string (match:end file-match)))
               (alist (let loop ((file-name file-name)
                                 (string string)
                                 (imported-match (string-match imported-regexp string)))
                        (if (not imported-match) `((,file-name . ,string))
                            (cons `(,file-name . ,(substring string 0 (match:start imported-match)))
                                  (let ((string (substring string (match:end imported-match))))
                                    (loop (match:substring imported-match 1)
                                          string
                                          (string-match imported-regexp string))))))))
          (values alist dir)))))

(define* (parse:file->content-alist file-name #:key (imports '())
                                    (content-alist '()))
  "Recursively resolve imports starting with FILE-NAME and return two values,
an alist of form:

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)

and the working directory.

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

  (let* ((content (parse:file->string file-name))
         (string? (or (equal? file-name "-")
                      (string-prefix? "#dir \"" content))))
    (if string? (parse:string->content-alist content)
        (let* ((content-alist (acons file-name content content-alist))
               (file-names (resolve file-name imports
                                    (peg:imported-file-names content)
                                    content-alist))
               (content-alist
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
                        (loop file-names content-alist))))))
          (values content-alist (getcwd))))))


;;;
;;; Parse tree, tree-alist.
;;;
(define* (parse:string->tree string #:key (content-alist '())
                             (fall-back? (%peg:fall-back?))
                             (file-name "-"))
  "Parse @var{string} and return multiple values, a parse tree and #true if parse failed.
  When @var{fall-back?}, try a regular parse first and upon failure
return a fall-back tree."
  (define (parse)
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
        (format (current-error-port) "tree: ~a\n" file-name)
        (pretty-print tree (current-error-port)))
      tree))
  ;; In case of fall-back, try a regular parse first
  (parameterize ((%peg:fall-back? #f)
                 (%peg:locations? #t)
                 (%peg:skip? peg:skip-parse)
                 (%peg:debug? (> (dzn:debugity) 3)))
    (catch 'syntax-error
      (lambda _ (values (parse) #f))
      (lambda (key . args)
        (if fall-back? (parameterize ((%peg:fall-back? #t))
                         (values (parse) #t))
            (apply (peg:handle-syntax-error
                    file-name string #:content-alist content-alist)
                   key args))))))

(define* (parse:file->tree file-name #:key debug?)
  "Parse @var{file-name} using @var{content-alist} to resolve import files,
and return multiple values, the @val{ast} and @code{#true} if parsing
failed.  Unless @var{debug?}, handle exceptions."
  (catch (if debug? 'none #t)
    (lambda _
      (let ((string (parse:file->string file-name)))
        (parse:string->tree string #:file-name file-name)))
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (values #f #t))))

(define* (parse:string->fall-back-tree string #:key (file-name "-")
                                       (error-collector (const '())))
  ;; XXX FIXME, THIS IS A LIE, we always try regular parse first
  "Wrapper for running parse:string->tree in fall-back mode only."
  (parameterize ((%peg:fall-back? #t)
                 (%peg:error (peg:format-capture-syntax-error error-collector)))
    (parse:string->tree string #:file-name file-name)))

(define* (parse:string->tree-alist+content-alist string #:key (file-name "-"))
  (let* ((content-alist dir (parse:string->content-alist string))
         (tree-alist
          parse-failed?
          (parse:content-alist->tree-alist content-alist)))
    (values tree-alist content-alist dir parse-failed?)))

(define* (parse:content-alist->tree-alist content-alist #:key debug?)
  "From CONTENT-ALIST of form

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)

parse CONTENT and return multiple values

'((FILE-NAME . TREE)
  (IMPORTED-FILE-NAME . IMPORTED-TREE) ...)

+

  #true if parsing of any CONTENT failed."

  (let ((parse-failed? #f))
    (define file+content->file+tree
      (match-lambda
        ((file-name . content)
         (let ((tree failed?
                     (parse:string->tree content
                                         #:file-name file-name
                                         #:content-alist content-alist)))
           (when failed?
             (set! parse-failed? #t))
           (cons file-name tree)))))
    (let ((tree-alist (map file+content->file+tree content-alist)))
      (values tree-alist parse-failed?))))

(define* (parse:file->tree-alist+content-alist file-name #:key debug?
                                               (imports '()))
  "Parse @var{file-name} using @var{imports} to resolve import files,
and return four values, the @var{tree-alist}, the @var{content-alist},
the @var{working-directory}, and @code{#true} if parsing failed.  Unless
@var{debug?}, handle exceptions."
  (catch (if debug? 'none #t)
    (lambda _
      (if (equal? file-name "-") (parse:string->tree-alist+content-alist
                                  (parse:file->string file-name))
          (let* ((content-alist
                  dir
                  (parse:file->content-alist file-name #:imports imports))
                 (tree-alist
                  parse-failed?
                  (parse:content-alist->tree-alist content-alist
                                                   #:debug? debug?)))
            (values tree-alist content-alist dir parse-failed?))))
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (values #f #f #f #t))))

(define* (parse:file->tree-alist file-name #:key debug? (imports '()))
  "Parse @var{file-name} using @var{imports} to resolve import files,
and return two values, the @var{tree-alist}, and @code{#true} if parsing
failed.  Unless @var{debug?}, handle exceptions."
  (catch (if debug? 'none #t)
    (lambda _
      (if (equal? file-name "-") (parse:string->tree-alist+content-alist
                                  (parse:file->string file-name))
          (let* ((content-alist
                  dir
                  (parse:file->content-alist file-name #:imports imports))
                 (tree-alist
                  parse-failed?
                  (parse:content-alist->tree-alist content-alist
                                                   #:debug? debug?)))
            (values tree-alist parse-failed?))))
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (values #f #t))))


;;;
;;; Ast.
;;;
(define* (parse:annotate-ast ast)
  (let ()
    (when (> (dzn:debugity) 1)
      (ast:pretty-print ast (current-error-port)))
    ast))

(define* (parse:tree-alist->ast tree-alist #:key (content-alist '())
                                (working-directory (getcwd)))
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
                                #:file-name file-name
                                #:working-directory working-directory))))))

  (let* ((ast-alist (map file+tree->ast tree-alist))
         (ast (expand-imports ast-alist)))
    ast))

(define* (parse:file->ast file-name #:key debug? (imports '()))
  "Parse FILE-NAME and return an ast.  Unless @var{debug?}, handle
exceptions."
  (catch (if debug? 'none #t)
    (lambda _
      (let ((tree-alist
             content-alist
             dir
             parse-failed? (parse:file->tree-alist+content-alist
                            file-name
                            #:debug? #t
                            #:imports imports)))
        ;; (pke "parse:file->ast" file-name)
        ;; (pke "  content-alist" content-alist)
        ;; (pke "  " file-name)
        ;; (pke "parse:file->ast" file-name)
        (if parse-failed? (values #f #t)
            (let* ((ast (parse:tree-alist->ast tree-alist
                                               #:content-alist content-alist
                                               #:working-directory dir))
                   (ast (parse:annotate-ast ast)))
              (values ast parse-failed?)))))
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (values #f #t))))

(define (parse:string->ast string)
  "Parse STRING and return an ast."
  (let* ((content-alist dir (parse:string->content-alist string))
         (tree-alist parse-failed? (parse:content-alist->tree-alist
                                    content-alist))
         (skip-ast? (or parse-failed? (null? tree-alist))))
    (if skip-ast? (values tree-alist parse-failed?)
        (let* ((ast (parse:tree-alist->ast tree-alist
                                           #:content-alist content-alist
                                           #:working-directory dir))
               (ast (parse:annotate-ast ast)))
          (values ast parse-failed?)))))


;;;
;;; Stream / preprocess.
;;;
(define* (parse:file->stream file-name #:key (imports '()))
  "Read @var{file-name}, using @var{imports} to resolve @code{import}
statements and return the expanded dezyne text, similar to @command{gcc
-E}."

  (define import+content->stream-lines
    (match-lambda
      ((file-name . content)
       (list (format #f "#imported ~s" file-name)
             content))))

  (let ((content-alist
         dir
         (parse:file->content-alist file-name #:imports imports)))

    (define file+content->stream-lines
      (match-lambda
        ((file-name . content)
         (if (string-prefix? "#dir " content) (list content)
             (list (format #f "#dir ~s" dir)
                   (format #f "#file ~s" file-name)
                   content)))))

    (let* ((file+content (car content-alist))
           (imports (cdr content-alist))
           (file-lines (file+content->stream-lines file+content))
           (import-lines (append-map import+content->stream-lines imports))
           (lines (append file-lines import-lines)))
      (string-join lines "\n"))))
