;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019, 202, 2020 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2014, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2014, 2018, 2020, 2021 Rutger van Beusekom <rutger@dezyne.org>
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

  #:use-module (dzn ast display)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast parse)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn parse peg)
  #:use-module (dzn ast wfc)

  #:export (file->ast
            file->stream
            file+import-content-alist
            call-with-handle-exceptions
            peg:handle-syntax-error
            string->ast
            string->parse-tree
            string->fall-back-parse-tree
            format-display-syntax-error))

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

(define (peg:imported-from->message content-alist file-name)
  (let* ((imported-from (imported-from content-alist))
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

(define (format-capture-syntax-error error-collector)
  "Return a procedure that generates a human-readable message and passes
it to the ERROR-COLLECTOR procedure."
  (lambda (str line-number col-number error-type error)
    (let ((message (peg:syntax-error->message (cadar error) str (caar error))))
      (error-collector error-type message line-number col-number))))

(define (format-display-syntax-error file-name)
  "Return a procedure that to format GNU style error message for
FILE-NAME."
  (lambda (str line-number col-number error-type error)
    (let ((message (peg:syntax-error->message (cadar error) str (caar error))))
      (format (current-error-port) "~a:~a:~a: ~a\n"
              file-name line-number col-number message))))

(define* (string->parse-tree string #:key (file-name "-") (content-alist '()))
  (let ((fall-back? (%peg:fall-back?)))
    (define (parse)
      (let* ((parse-tree (peg:parse string))
             (parse-tree (match parse-tree
                           (('root tree ...)
                            `(root
                                 ,@(if (not file-name) '()
                                       `((file-name ,file-name (location 0 0))))
                               ,@tree))))
             (parse-tree (if (%peg:fall-back?) (peg:flatten-tree parse-tree)
                             parse-tree)))
        (when (> (dzn:debugity) 2)
          (format (current-error-port) "parse-tree: ~a\n" file-name)
          (pretty-print parse-tree (current-error-port)))
        parse-tree))
    (parameterize ((%peg:fall-back? #f)
                   (%peg:locations? #t)
                   (%peg:skip? peg:skip-parse)
                   (%peg:debug? (> (dzn:debugity) 3)))
      ;; In case of fall-back, try a regular parse first
      (catch 'syntax-error
        (lambda () (values (parse) #f))
        (lambda (key . args)
          (if fall-back? (parameterize ((%peg:fall-back? #t))
                           (values (parse) #t))
              (apply (peg:handle-syntax-error file-name string
                                              #:content-alist content-alist)
                     key args)))))))

(define (string->fall-back-parse-tree text content-alist
                                      file-name error-collector)
  "Wrapper for running string->parse-tree in fall-back mode only."
  (parameterize ((%peg:fall-back? #t)
                 (%peg:error (format-capture-syntax-error error-collector)))
    (string->parse-tree text
                        #:content-alist content-alist
                        #:file-name file-name)))

(define (parse-file+import-content-alist alist)
  "From ALIST of form

   '((FILE-NAME . CONTENT)
     (IMPORTED-FILE-NAME . IMPORTED-CONTENT) ...)

parse CONTENT and return multiple values

'((FILE-NAME . PARSE-TREE)
  (IMPORTED-FILE-NAME . IMPORTED-PARSE-TREE) ...)

+

  #true if parsing of any CONTENT failed."

  (let* ((parse-failed? #f)
         (alist (map
                 (match-lambda
                   ((file-name . content)
                    (let ((tree failed?
                                (string->parse-tree content
                                                    #:file-name file-name
                                                    #:content-alist alist)))
                      (when failed?
                        (set! parse-failed? #t))
                      (cons file-name tree))))
                 alist)))
    (values alist parse-failed?)))

(define* (parse-tree-alist->ast alist #:key (content-alist '())
                                (working-directory (getcwd)))
  "Return an AST by merging ALIST of form

   '((FILE-NAME . PARSE-TREE)
     (IMPORTED-FILE-NAME . IMPORTED-PARSE-TREE) ...)

using CONTENT-ALIST to transform locations."
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

  (let* ((ast-alist
          (map (match-lambda
                 ((file-name . parse-tree)
                  (let ((content (assoc-ref content-alist file-name)))
                    (cons file-name
                          (parse-tree->ast parse-tree
                                           #:string content
                                           #:file-name file-name
                                           #:working-directory working-directory)))))
               alist))
         (ast (expand-imports ast-alist)))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print ast (current-error-port)))
    ast))

(define* (file->ast file-name #:key debug? (imports '()) parse-tree? skip-wfc?
                    (transform '()))
  "Parse FILE-NAME and return an ast.  When PARSE-TREE?, return the
parse trees.  When SKIP-WFC?, skip the well-formedness checks.  Unless
@var{debug?}, handle exceptions."
  (define (helper)
    (if (equal? file-name "-") (string->ast (read-string)
                                            #:parse-tree? parse-tree?
                                            #:skip-wfc? skip-wfc?
                                            #:transform transform)
        (let* ((content-alist
                dir
                (file+import-content-alist file-name #:imports imports))
               (parse-tree-alist
                parse-failed?
                (parse-file+import-content-alist content-alist))
               (skip-ast? (or parse-tree? (null? parse-tree-alist))))
          (if skip-ast? (values parse-tree-alist parse-failed?)
              (let* ((ast (parse-tree-alist->ast parse-tree-alist
                                                 #:content-alist content-alist
                                                 #:working-directory dir))
                     (ast (if skip-wfc? ast
                              (ast:wfc ast)))
                     (transform (map string->transformation transform)))
                (values ((apply compose identity (reverse transform)) ast)
                        parse-failed?))))))

  (catch (if debug? 'none #t)
    helper
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (values #f #t))))

(define (parse:handle-exceptions file-name)
  (lambda (key . args)
    (case key
      ((syntax-error)
       #t)
      ((import-error)
       (match args
         ((file imports content-alist)
          (cond ((string=? file-name (car args))
                 (format (current-error-port) "No such file: ~a\n" file-name))
                (else
                 (let* ((imported-from (imported-from content-alist))
                        (from (assoc-ref imported-from (basename file))))
                   (format (current-error-port)
                           "No such file: ~a found in: ~a;\n"
                           file (string-join imports ", "))
                   (let loop ((from from))
                     (when from
                       (format (current-error-port) "imported from ~a\n" from)
                       (loop (assoc-ref imported-from (basename from)))))))))))
      ((error)
       (apply format (current-error-port) "~a:error:~a\n" file-name args))
      ((well-formedness-error)
       (for-each wfc:report-message args))
      ((system-error)
       (let ((errno (system-error-errno (cons key args))))
         (format (current-error-port) "~a: ~a\n"
                 (strerror errno) file-name)))
      (else
       (format (current-error-port) "internal error: ~a: ~a: ~s\n"
               file-name key args)))))

(define* (call-with-handle-exceptions thunk #:key backtrace? (file-name "-"))
  (catch (if backtrace? 'none #t)
    thunk
    (lambda (key . args)
      (apply (parse:handle-exceptions file-name) key args)
      (exit EXIT_FAILURE))))

(define* (string->ast string #:key parse-tree? skip-wfc? (transform '()))
  "Parse STRING and return an ast.  When PARSE-TREE?, return the parse
trees.  When SKIP-WFC? skip the well-formedness checks."
  (let* ((content-alist dir (string->file+import-content-alist string))
         (parse-tree-alist parse-failed? (parse-file+import-content-alist
                                          content-alist))
         (skip-ast? (or parse-tree? (null? parse-tree-alist))))
    (if skip-ast? (values parse-tree-alist parse-failed?)
        (let* ((ast (parse-tree-alist->ast parse-tree-alist
                                           #:content-alist content-alist
                                           #:working-directory dir))
               (ast (if skip-wfc? ast
                        (ast:wfc ast)))
               (transform (map string->transformation transform)))
          (values ((apply compose identity (reverse transform)) ast)
                  parse-failed?)))))

(define (string->file+import-content-alist string)
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

(define* (file->stream file-name #:key (imports '()))
  "Read @var{file-name}, using @var{imports} to resolve @code{import}
statements and return the expanded dezyne text, similar to @command{gcc
-E}."

  (let* ((content-alist
          dir
          (if (equal? file-name "-") (string->file+import-content-alist (read-string))
              (file+import-content-alist file-name #:imports imports)))
         (file (car content-alist))
         (imports (cdr content-alist)))
    (string-join
     (append
      (match file
        ((file-name . content)
         (if (string-prefix? "#dir " content) (list content)
             (list (format #f "#dir ~s" dir)
                   (format #f "#file ~s" file-name)
                   content))))
      (append-map (match-lambda ((file-name . content)
                                 (list (format #f "#imported ~s" file-name)
                                       content)))
                  imports))
     "\n")))

(define* (file+import-content-alist file-name #:key (imports '()) (content-alist '()))
  "Recursively resolve imports starting with FILE-NAME and return two
values, an alist:

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
    (let ((content (with-input-from-file file-name read-string)))
      (cons file-name content)))

  (define (resolve from imports imported content-alist)
    (map (lambda (import)
           (let* ((paths (cons (dirname from) imports))
                  (file-name (search-path paths import)))
             (unless file-name
               (throw 'import-error import paths content-alist))
             file-name))
         imported))

  (let ((content (with-input-from-file file-name read-string)))
    (if (string-prefix? "#dir \"" content) (string->file+import-content-alist content)
        (let*
            ((content-alist (acons file-name content content-alist))
             (file-names (resolve file-name imports
                                  (imported-file-names content)
                                  content-alist))
             (alist
              (let loop ((file-names file-names) (content-alist content-alist))
                (if (null? file-names) (reverse content-alist)
                    (let* ((canonical-string=?
                            (lambda (a b)
                              (string=? (canonicalize-path-memoized a)
                                        (canonicalize-path-memoized b))))
                           (file-names (delete-duplicates file-names
                                                          canonical-string=?))
                           (file-names (lset-difference canonical-string=?
                                                        file-names
                                                        (map car
                                                             content-alist)))
                           (alist (reverse (map read-file file-names)))
                           (content-alist (append alist content-alist))
                           (file-names
                            (append-map
                             (match-lambda
                               ((file-name . content)
                                (resolve file-name imports
                                         (imported-file-names content)
                                         content-alist)))
                             alist)))
                      (loop file-names content-alist))))))
          (values alist (getcwd))))))

(define (imported-file-names content)
  "Return the list of file names used in import statements in content."
  (let ((tree (parameterize ((%peg:locations? #f)
                             (%peg:skip? peg:import-skip-parse)
                             (%peg:debug? (> (dzn:debugity) 3)))
                (peg:imports content))))
    (match tree
      (('import file-name) (list file-name))
      ((('import file-name) ...) file-name))))

(define (imported-from alist)
  "Return an alist of imported file names"
  (define parse
    (match-lambda ((file-name . content)
                   (map (cute cons <> file-name)
                        (imported-file-names content)))))
  (append-map parse alist))

(define (string->transformation str)
  (let* ((transform (resolve-interface `(dzn transform)))
         (input (open-input-string str))
         (name (false-if-exception (read input)))
         (transformation (false-if-exception
                          (module-ref transform name)))
         (parameters (false-if-exception (read input)))
         (parameters (if (pair? parameters) parameters '()))
         (parameters? (and (pair? parameters)
                           (match (warn "arity" (procedure-minimum-arity transformation))
                             ((1 0 optional) #f)
                             (_ #t)))))
    (unless transformation
      (throw 'error (format #f "no such transformation: ~a" str)))
    (if parameters? (cute transformation <> parameters)
        transformation)))
