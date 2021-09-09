;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
;;; Stress test Dezyne Language completion.
;;;
;;; Code:

(define-module (dzn parse stress)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (dzn misc)
  #:use-module (dzn parse)
  #:use-module (dzn parse complete)
  #:use-module (dzn parse peg)
  #:use-module (dzn parse tree)
  #:export (stress))

(define keywords
  '("behaviour"
    "blocking"
    "component"
    "else"
    "enum"
    "extern"
    "external"
    "if"
    "import"
    "in"
    "inevitable"
    "injected"
    "inout"
    "interface"
    "namespace"
    "on"
    "optional"
    "otherwise"
    "out"
    "provides"
    "reply"
    "requires"
    "return"
    "system"))

(define separators
  '("\\{" "\\}"
    "\\(" "\\)"
    "\\[" "\\]"
    ":" ";"
    ","
    ;; operators?
    ))

(define identifiers
  '("blocking"
    "else"
    "external"
    "import"
    "in"
    "injected"
    "inout"
    "on"
    "out"
    "provides"
    "requires"
    "return"))

(define (select-completions str predicate)
  "SELECT-COMPLETIONS produces an ALIST of an OFFSET to a STRING. An
OFFSET is an index in STR. The STRING is a substring of STR from the
OFFSET up to the next word boundary. PREDICATE determines each OFFSET in
STR. The weakest post-condition of PREDICATE is that it identifies
left-handed word boundaries."
  (predicate str))

(define* (completion-heuristics str #:optional (offset 0))
  (let* ((keywords-regex (make-regexp (string-join (map (cute string-append "\\<" <> "\\>") keywords) "|")))
         (identifier-regex (make-regexp (string-append "\\<[a-zA-Z_.][0-9a-zA-Z_.]*|"
                                                       (string-join separators "|")
                                                       "\\>")))
         (identifiers-regex (make-regexp
                             (string-append
                              (string-join (map (cute string-append "\\<" <> "\\>") identifiers) "|" 'suffix)
                              (string-join separators "|")))))
    (append
     (map
      (lambda (m)
        (cons
         (match:start m)
         (match:substring m)))
      (list-matches keywords-regex str))
     (filter-map
      (lambda (m)
        (let* ((end (match:end m))
               (m (regexp-exec identifier-regex str end)))
          (and m
               (not (find (cute string-contains <> (match:substring m)) separators ))
               (cons
                (match:start m)
                (match:substring m)))))
      (list-matches identifiers-regex str)))))

(define (test:complete str offset)
  "COMPLETE produces the completion list for OFFSET in STR"
  ((pure-funcq
    (lambda (str offset)
      (let* ((context (complete:context
                       (parameterize
                           ((%peg:locations? #t)
                            (%peg:skip? peg:skip-parse)
                            (%peg:fall-back? #t)
                            (%peg:error (const #f)))
                         (string->parse-tree str))
                       offset)))
        (complete (.tree context) context (1+ offset)))))
   str offset))

(define* (assert-completions str predicate #:key debug? file-name)
  "Call complete for every relevant OFFSET in STR according to PREDICATE"

  (define (assert-completion offset-expect str)
    (match offset-expect
      ((offset . expect)
       (let ((completions (test:complete str offset))
             (snippet-name (format #f "~a-~a.dzn" file-name (1+ offset))))

         (when debug?
           (with-output-to-file snippet-name
             (cute display str)))

         (cond ((find (cute string-contains <> expect) completions)
                #f)
               (else
                (with-output-to-file snippet-name
                  (cute display str))
                (list (1+ offset) expect completions)))))))

  (define* ((make-hole str) offset-expect)
    "Return STR with a whitepace hole inserted at OFFSET-EXPECT."
    (match offset-expect
      ((offset . expect)
       (let* ((len (string-length expect))
              (start offset)
              (len (cond
                    ((and (equal? expect "reply")
                          (string-match "^( *\\([^()]*\\))" (substring str (+ offset len))))
                     =>
                     (lambda (m)
                       (+ len (string-length (match:substring m 1)))))
                    (else
                     len)))
              (end (+ start len)))
         (string-replace str (make-string len #\space) start end)))))

  (let* ((offset-expects (select-completions str predicate))
         (strings (map (make-hole str) offset-expects)))
    ;;(pretty-print offset-completion)
    (filter-map assert-completion offset-expects strings)))

(define (tipex-comments str)
  (let ((comment-regexp (make-regexp "//[^\n]*")))
    (let loop ((str str) (matches (list-matches comment-regexp str)))
      (if (null? matches) str
          (let* ((m (car matches))
                 (start (match:start m))
                 (end (match:end m)))
            (loop (string-replace str (make-string (- end start) #\space) start end) (cdr matches)))))))


;;;
;;; Entry points.
;;;

(define* (stress file-name #:key debug?)
  (let* ((str (tipex-comments (with-input-from-file file-name read-string))))
    (pretty-print (assert-completions
                   str
                   completion-heuristics
                   #:debug? debug?
                   #:file-name (basename file-name ".dzn")))))

(when (equal? (command-line) '("dzn/parse/stress.scm"))
  (stress "test/all/helloworld/helloworld.dzn"))
