;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2019 Timothy Sample <samplet@ngyro.com>
;;; Copyright © 2019, 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (test gaiag dzn)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (json)
  #:use-module (gaiag shell-util)
  #:use-module (gaiag commands trace)
  #:export (observe
            run-build
            run-code
            run-execute
            run-test
            run-traces
            run-verify
            verification-reorder))


;;; Shell-util

(define (list-files dir pred)
  (filter
   (negate (compose (cut string-index <> #\/)
                    (cut string-drop <> (1+ (string-length dir)))))
   (find-files dir pred)))

;;; Invocation helpers

;; XXX: This is probably the slowest way possible to do this.  I hope
;; it is correct, at least.
(define (get-strings-all . ports)
  (define accs (make-hash-table (length ports)))

  (define (accs-cons! x port)
    (hashq-set! accs port (cons x (hashq-ref accs port '()))))

  (let loop ((ps ports))
    (match ps
      (() (map (lambda (port)
                 (reverse-list->string (hashq-ref accs port '())))
               ports))
      (_ (match (select ps '() '())
           (((ready-port . _) _ _)
            (match (read-char ready-port)
              ((? eof-object?)
               (loop (filter (lambda (port)
                               (not (eq? port ready-port)))
                             ps)))
              (chr (accs-cons! chr ready-port)
                   (loop ps)))))))))

(define (observe command input)
  "Run COMMAND with INPUT, returning the exit status, standard
output, and standard error as three values."
  (define (cleanup)
    (when (directory-exists? "@abs_top_srcdir@/tests/data/tmp")
      (delete-file-recursively "@abs_top_srcdir@/tests/data/tmp")))
  (match-let (((stdin-input . stdin-output) (pipe))
              ((stdout-input . stdout-output) (pipe))
              ((stderr-input . stderr-output) (pipe))
              ((ex-input . ex-output) (pipe)))
    (format #t "~a\n" (string-join
                       (map (lambda (s)
                              (if (or (string-index s #\space)
                                      (string-index s #\newline))
                                  (format #f "~s" s)
                                  s))
                            command)))
    (match (primitive-fork)
      (0 (catch #t
           (lambda ()
             (close-port stdin-output)
             (close-port stdout-input)
             (close-port stderr-input)
             (close-port ex-input)
             (dup stdin-input 0)
             (dup stdout-output 1)
             (dup stderr-output 2)
             ;; (chdir "@abs_top_srcdir@/tests/data")
             (setenv "TEST_TMP" (getcwd))
             (and=> (getenv "srcdir") chdir)
             (apply execlp (car command) command))
           (lambda args
             (write args ex-output)
             (force-output ex-output)
             (primitive-_exit EXIT_FAILURE))))
      (pid (close-port stdin-input)
           (close-port stdout-output)
           (close-port stderr-output)
           (close-port ex-output)
           (display input stdin-output)
           (close stdin-output)
           (match (get-strings-all stdout-input stderr-input ex-input)
             ((stdout stderr "")
              (match-let (((pid . status) (waitpid pid)))
                (cleanup)
                (let ((status (or (status:exit-val status) 1)))
                  (unless (zero? status)
                    (format #t "status: ~a\n" status))
                  (unless (string-null? stdout)
                    (format #t "stdout:\n~a\n" stdout))
                  (unless (string-null? stderr)
                    (format #t "stderr:\n~a\n" stderr))
                  (values (or status 1) stdout stderr))))
             ((_ _ ex)
              (cleanup)
              (apply throw (call-with-input-string ex read))))))))

(define (verification-reorder string)
  (define (verification-less? a b)
    (let ((a-split (string-split a #\:))
          (b-split (string-split b #\:)))
      (let ((model-a (cadr a-split))
            (model-b (cadr b-split)))
        (if (string=? model-a model-b)
            (let ((check-a (string-trim-both (cadddr a-split)))
                  (check-b (string-trim-both (cadddr b-split)))
                  (check-order '("deterministic"
                                 "completeness"
                                 "illegal"
                                 "deadlock"
                                 "compliance"
                                 "livelock")))
              (< (list-index (cut string=? <> check-a) check-order)
                 (list-index (cut string=? <> check-b) check-order)))
            (string<? model-a model-b)))))
  (let* ((lines (string-split string #\newline))
         (chunks (let loop ((line "") (lines lines))
                   (if (null? lines) '()
                       (if (and (pair? (cdr lines))
                                (not (string-prefix? "verify:" (cadr lines))))
                           (loop (string-append
                                  line (string-append (car lines) "\n"))
                                 (cdr lines))
                           (cons (string-trim-right
                                  (string-append line (car lines)))
                                 (loop "" (cdr lines))))))))
    (string-join (sort chunks verification-less?) "\n" 'suffix)))

(define (skip? file-name . stages)
  (let ((META (string-append file-name "/META")))
    (and (file-exists? META)
         (let ((json (json->scm (open-input-file META))))
           (or-map (lambda (stage)
                     (or (and=> (hash-ref json "skip")
                                (cut member stage <>))
                         (and=> (hash-ref json "known")
                                (cut member stage <>))))
                   stages))
         (format #t "skip\n"))))

(define (flush? file-name)
  (let ((META (string-append file-name "/META")))
    (and (file-exists? META)
         (let ((json (json->scm (open-input-file META))))
           (and=> (hash-ref json "flush")
                  (cut equal? <> "true"))))))

(define (thread-safe-shell? file-name)
  (let ((META (string-append file-name "/META")))
    (and (file-exists? META)
         (let ((json (json->scm (open-input-file META))))
           (and=> (hash-ref json "tss")
                  (cut equal? <> "true"))))))

(define (code-options file-name)
  (let ((META (string-append file-name "/META")))
    (or (and (file-exists? META)
             (let ((json (json->scm (open-input-file META))))
               (and=> (hash-ref json "code_options")
                      list)))
        '())))

(define (model? file-name)
  (let ((META (string-append file-name "/META")))
    (and (file-exists? META)
         (let ((json (json->scm (open-input-file META))))
           (hash-ref json "model")))))

(define (model-unset? file-name)
  (let ((META (string-append file-name "/META")))
    (and (file-exists? META)
         (let ((json (json->scm (open-input-file META))))
           (and=> (hash-get-handle json "model")
                  (cut equal? <> '("model" . #f)))))))

(define (verify-only? file-name)
  (directory-exists? (string-append file-name "/baseline/verify")))

(define (run-verify file-name)
  (format #t "** stage: verify\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (baseline (string-append file-name "/baseline/verify"))
         (input "")
         (includes (append-map (cut list "-I" <>)
                               (cons (string-append file-name "/dzn")
                                     (or (and=> (getenv "DZN_INCLUDE_PATH")
                                                (cut string-split <> #\:))
                                         '()))))
         (model (or (model? file-name) base-name)))
    (or (skip? file-name "verify")
        (receive (status stdout stderr)
            (observe
             `("dzn" "--verbose" "verify" ,@includes "--all"
               ,@(if (model-unset? file-name) '() `("-m" ,model))
               ,dzn-name) input)
          (or (and (zero? status)
                   (not (directory-exists? baseline)))
              (let ((out-file (string-append file-name ".out"))
                    (err-file (string-append file-name ".err")))
                (with-output-to-file out-file
                  (cut display (verification-reorder stdout)))
                (with-output-to-file err-file
                  (cut display stderr))
                (let ((baseline-out (string-append baseline "/" base-name)))
                  (and (zero? (system* "diff" "-uwB" baseline-out out-file))
                       (zero? (system* "diff" "-uwB"
                                       (string-append baseline-out ".stderr") err-file))))))))))

(define (run-code file-name language)
  (format #t "** stage: code: ~a\n" language)
  (and (let* ((base-name (basename file-name))
              (dzn-name (string-append file-name "/" base-name ".dzn"))
              (input "")
              (includes (append-map (cut list "-I" <>)
                                    (cons (string-append file-name "/" language)
                                          (or (and=> (getenv "DZN_INCLUDE_PATH")
                                                     (cut string-split <> #\:))
                                              '()))))
              (out (string-append file-name "/out"))
              (out-lang (string-append file-name "/out/" language))
              (model (or (model? file-name) base-name))
              ;; FIXME: METAs `model' is used for component/system tricksery
              (model base-name))
         (or (verify-only? file-name)
             (skip? file-name "code" (string-append language ":code"))
             (and
              (receive (status stdout stderr)
                  (observe
                   `("dzn" "code" ,@includes "-l" ,language "-o" ,out-lang
                     "-m" ,model
                     ,@(if (thread-safe-shell? file-name) `("-s" ,base-name) '())
                     ,@(code-options file-name)
                     ,dzn-name) input)
                (zero? status))
              (let* ((dzn-files (list-files file-name ".+\\.*dzn*$"))
                     (extra-dzn-files (filter
                                       (negate (cut equal? <> dzn-name))
                                       dzn-files)))
                (and-map
                 (lambda (dzn-file)
                   (receive (status stdout stderr)
                       (observe
                        `("dzn" "code" ,@includes "-l" ,language "-o" ,out-lang
                          ,@(code-options file-name)
                          ,dzn-file) input)
                     (zero? status)))
                 extra-dzn-files)))))
       (run-build file-name language)
       (let ((traces (find-files file-name ".*trace.*$")))
         (and-map (cut run-execute file-name language <>) traces))))

(define (run-traces file-name)
  (format #t "** stage: traces\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (includes (append-map (cut list "-I" <>)
                               (cons (string-append file-name "/dzn")
                                     (or (and=> (getenv "DZN_INCLUDE_PATH")
                                                (cut string-split <> #\:))
                                         '()))))
         (model (or (model? file-name) base-name))
         (out (string-append file-name "/out"))
         (out-lang (string-append file-name "/out/traces"))
         (handwritten-traces (list-files file-name ".*trace.*$")))
    (or (verify-only? file-name)
        (pair? handwritten-traces)
        (skip? file-name "traces")
        (receive (status stdout stderr)
            (observe
             `("dzn" "traces"
               ,@includes
               "-m" ,model
               "-o" ,out-lang
               ,@(if (flush? file-name) '("--flush") '())
               ,dzn-name)
             input)
          (zero? status)))))

(define (run-build file-name language)
  (format #t "** stage: build: ~a\n" language)
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (out (string-append file-name "/out"))
         (out-lang (string-append file-name "/out/" language))
         (command `("make"
                    "-f" ,(string-append "test/lib/build." language ".make")
                    ,(string-append "LANGUAGE=" language)
                    ,(string-append "IN=" file-name)
                    ,(string-append "OUT=" out-lang))))
    (or (verify-only? file-name)
        (skip? file-name
               "code" (string-append language ":code")
               "build" (string-append language ":build"))
        (receive (status stdout stderr)
            (observe command input)
          (zero? status)))))

(define (run-execute file-name language trace)
  (format #t "** stage: execute: ~a ~a\n" language trace)
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input (with-input-from-file trace read-string))
         (out (string-append file-name "/out"))
         (out-lang (string-append file-name "/out/" language))
         (test (string-append out-lang "/test")))
    (or (verify-only? file-name)
        (skip? file-name
               "code" (string-append language ":code")
               "build" (string-append language ":build")
               "execute" (string-append language ":execute"))
        (receive (status stdout stderr)
            (observe `(,test ,@(if (flush? file-name) '("--flush") '())) input)
          (and (zero? status)
               (let (;; FIXME: async_order and other async_* tests
                     ;; use an ugly " " hack that dzn trace chokes on.
                     ;; TODO: fix async_* (or dzn trace??) and drop
                     ;; code2fdr.
                     ;; (net (format-trace stderr #:format "event"))
                     (net (receive (status stdout stderr)
                                  (observe '("code2fdr") stderr)
                                stdout)))
                 (receive (status stdout stderr)
                     (observe `("bash" "-c"
                                ,(string-append "diff -ywB"
                                                " --ignore-matching-lines='<flush>$'"
                                                ;; ignore foreign/system communications
                                                " --ignore-matching-lines='[.][^. ]\\+[.][^. ]\\+[.]'"
                                                " <(echo -e '" input "')"
                                                " <(echo -e '" net "')" ))
                              #f)
                   (zero? status))))))))

(define (run-test file-name languages)
  (setvbuf (current-output-port) 'line)
  (format #t "* run: ~a ~a\n" file-name languages)
  (let ((result (and (run-verify file-name)
                     (run-traces file-name)
                     (and-map (cut run-code file-name <>) languages))))
    (format #t "# Local Variables:
# mode: org
# End:
")
    result))

;;; Local Variables:
;;; mode: scheme
;;; End:
