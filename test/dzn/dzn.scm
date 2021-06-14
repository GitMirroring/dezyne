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

(define-module (test dzn dzn)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)
  #:use-module (json)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:use-module (dzn commands trace)
  #:export (observe
            run-baseline
            run-build
            run-code
            run-execute
            run-test
            run-traces
            run-verify))


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

(define (get-meta file-name)
  (let ((META (string-append file-name "/META")))
    (and (file-exists? META)
         (let ((text (with-input-from-file META read-string)))
           (json-string->alist-scm text)))))

(define (skip? file-name . stages)
  (let ((json (get-meta file-name)))
    (and json
         (or-map (lambda (stage)
                   (or (and=> (assoc-ref json "skip")
                              (cut member stage <>))
                       (and=> (assoc-ref json "known")
                              (cut member stage <>))))
                 stages)
         (format #t "skip\n"))))

(define (get-meta-flag file-name flag)
  (let ((json (get-meta file-name)))
    (and json
         (and=> (assoc-ref json flag)
                (cut equal? <> #t)))))

(define (flush? file-name)
  (get-meta-flag file-name "flush"))

(define (thread-pool? file-name)
  (get-meta-flag file-name "thead-pool"))

(define (thread-safe-shell? file-name)
  (get-meta-flag file-name "tss"))

(define (code-options file-name)
  (let ((json (get-meta file-name)))
    (or (and json
             (and=> (assoc-ref json "code_options")
                    list))
        '())))

(define (model? file-name)
  (let ((json (get-meta file-name)))
    (and json
         (assoc-ref json "model"))))

(define (model-unset? file-name)
  (let ((json (get-meta file-name)))
    (and json
         (and=> (assoc "model" json)
                (cut equal? <> '("model" . #f))))))

(define (trace-format file-name)
  (let ((json (get-meta file-name)))
    (and json
         (assoc-ref json "trace-format"))))

(define (non-strict? file-name)
  (let ((json (get-meta file-name)))
    (and json
         (assoc-ref json "non-strict?"))))

(define (error-model? file-name)
  (or (directory-exists? (string-append file-name "/baseline/verify"))
      ;; no verify baseline for system error models
      (directory-exists? (string-append file-name "/baseline/simulate"))))

(define (filter-<flush> string)
  (let* ((lines (string-split string #\newline))
         (events (filter (negate (cut string-contains <> "<flush>")) lines)))
    (string-join events "\n")))

(define (filter-state string)
  (let* ((lines (string-split string #\newline))
         (events (filter (negate (cut string-prefix? "(state " <>)) lines)))
    (string-join events "\n")))

(define* (run-baseline file-name command #:key
                       (baseline (string-append file-name "/baseline"))
                       (input "")
                       (stdout-filter identity))
  (receive (status stdout stderr)
      (observe command input)
    (or (and (zero? status)
             (not (directory-exists? baseline)))
        (let ((out-file (string-append file-name ".out"))
              (err-file (string-append file-name ".err")))
          (with-output-to-file out-file
            (cut display (stdout-filter stdout)))
          (with-output-to-file err-file
            (cut display stderr))
          (let* ((base-name (basename file-name))
                 (baseline-out (string-append baseline "/" base-name))
                 (baseline-err (string-append baseline-out ".stderr")))
            (and (or (and (string-null? stdout)
                          (not (file-exists? baseline-out)))
                     (zero? (system* "diff" "-uwB" baseline-out out-file)))
                 (or (and (string-null? stderr)
                          (not (file-exists? baseline-err)))
                     (zero? (system* "diff" "-uwB"
                                     baseline-err err-file)))))))))

(define (run-verify file-name)
  (format #t "** stage: verify\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (baseline (string-append file-name "/baseline/verify"))
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cut string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cut list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (command `("dzn" "--verbose" "verify"
                    ,@includes
                    "--all"
                    ,@(if (model-unset? file-name) '() `("-m" ,model))
                    ,dzn-name)))
    (or (skip? file-name "verify")
        (run-baseline file-name command
                      #:baseline baseline))))

(define (run-code file-name language)
  (format #t "** stage: code: ~a\n" language)
  (and (let* ((base-name (basename file-name))
              (dzn-name (string-append file-name "/" base-name ".dzn"))
              (input "")
              (in-lang (string-append file-name "/" language))
              (includes (cons in-lang
                              (or (and=> (getenv "DZN_INCLUDE_PATH")
                                         (cut string-split <> #\:))
                                  '())))
              (includes (filter directory-exists? includes))
              (includes (append-map (cut list "-I" <>) includes))
              (out (string-append file-name "/out"))
              (out-lang (string-append file-name "/out/" language))
              (model (or (model? file-name) base-name))
              ;; FIXME: METAs `model' is used for component/system tricksery
              (model base-name))
         (or (error-model? file-name)
             (skip? file-name "code" language (string-append language ":code"))
             (and
              (receive (status stdout stderr)
                  (observe
                   `("dzn" "code"
                     ,@includes
                     "-l" ,language
                     "-o" ,out-lang
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
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cut string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cut list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (out (string-append file-name "/out"))
         (out-lang (string-append file-name "/out/traces"))
         (handwritten-traces (list-files file-name ".*trace.*$")))
    (or (and (error-model? file-name)
             (null? handwritten-traces))
        (skip? file-name "traces")
        (receive (status stdout stderr)
            (observe
             `("dzn" "traces"
               ,@includes
               "-m" ,model
               "-o" ,out-lang
               ,@(if (null? handwritten-traces) '("--traces") '())
               ,@(if (flush? file-name) '("--flush") '())
               "--lts"
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
         (thread-pool? (thread-pool? file-name))
         (command `("make"
                    "-f" ,(string-append "test/lib/build." language ".make")
                    ,(string-append "LANGUAGE=" language)
                    ,(string-append "IN=" file-name)
                    ,(string-append "OUT=" out-lang)
                    ,@(if thread-pool? '("THREAD_POOL_O=thread_pool.o") '()))))
    (or (error-model? file-name)
        (skip? file-name
               language
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
    (or (error-model? file-name)
        (skip? file-name
               language
               "code" (string-append language ":code")
               "build" (string-append language ":build")
               "execute" (string-append language ":execute"))
        (receive (status stdout stderr)
            (observe `(,test ,@(if (flush? file-name) '("--flush") '())) input)
          (and (zero? status)
               (let ((net (trace:format-trace stderr #:format "event")))
                 (receive (status stdout stderr)
                     (let* ((input (filter-state input))
                            (input (filter-<flush> input)))
                       (observe `("bash" "-c"
                                  ,(string-append "diff -ywB"
                                                  ;; ignore foreign/system communications
                                                  " --ignore-matching-lines='[.][^. ]\\+[.][^. ]\\+[.]'"
                                                  " <(echo -e '" input "')"
                                                  " <(echo -e '" net "')" ))
                                #f))
                   (zero? status))))))))

(define (run-simulate-trace file-name trace)
  (format #t "** stage: simulate-trace ~a\n" trace)
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (baseline (string-append file-name "/baseline/simulate"))
         (input (with-input-from-file trace read-string))
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cut string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cut list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (out (string-append file-name "/out"))
         (language "simulate")
         (out-lang (string-append file-name "/out/" language))
         (input (filter-<flush> input))
         (model (or (model? file-name) base-name))
         ;; FIXME: METAs `model' is used for component/system tricksery
         (model base-name)
         (trace-format (or (trace-format file-name) "event")))
    (receive (status stdout stderr)
        (observe `("dzn" "simulate"
                   ,@includes
                   "--format" ,trace-format
                   ,@(if (non-strict? file-name) '() '("--strict"))
                   "-m" ,model
                   ,dzn-name)
                 input)

      (cond ((and (zero? status) (not (file-exists? baseline)))

             (let* ((input (filter-state input))
                    (trail (filter-state stdout)))
               (and
                (receive (status stdout stderr)
                    (observe `("bash" "-c"
                               ,(string-append
                                 "diff -ywB"
                                 " <(echo -e '" input "')"
                                 " <(echo -e '" trail "')" ))
                             #f)
                  (zero? status))
                (or (string-null? stderr)
                    (and (format (current-error-port) "ERROR: ~a\n" stderr)
                         #f)))))
            (else
             (let ((out-file (string-append out-lang "/out"))
                   (err-file (string-append out-lang "/err"))
                   (trail (filter-state stdout)))
               (mkdir-p out-lang)
               (with-output-to-file out-file
                 (cut display trail))
               (with-output-to-file err-file
                 (cut display stderr))
               (let ((baseline-out (string-append baseline "/" base-name))
                     (baseline-err (string-append baseline "/" base-name ".stderr")))
                 (and (zero? (system* "diff" "-ywB" baseline-out out-file))
                      (or (and (string-null? stderr)
                               (not (file-exists? baseline-err)))
                          (zero? (system* "diff" "-ywB" baseline-err err-file)))))))))))

(define (run-simulate file-name)
  (format #t "** stage: simulate\n")
  (or (skip? file-name
             "simulate")
      (let ((traces (find-files file-name ".*trace.*$")))
        (and-map (cut run-simulate-trace file-name <>) traces))))

(define (run-lts file-name)
  (format #t "** stage: lts\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cut string-split <> #\:))
                             '())))
         (includes (append-map (cut list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (out (string-append file-name "/out"))
         (language "lts")
         (out-lang (string-append file-name "/out/" language))
         (handwritten-traces (list-files file-name ".*trace.*$")))
    (or (and (error-model? file-name)
             (null? handwritten-traces))
        (skip? file-name
               "traces"
               "lts")
        (receive (status stdout stderr)
            (observe
             `("dzn" "explore" "--lts"
               ,@includes
               "-m" ,model
               ,dzn-name)
             input)
          (and (zero? status)
               (let ((makreel-lts-file (string-append out "/traces/" base-name ".aut")))
                 (or (and (not (file-exists? makreel-lts-file))
                          ;; XXX skip: "probably a system"
                          (format (current-error-port) "skip compare: ~s\n" makreel-lts-file))
                     (let* ((makreel-lts (with-input-from-file makreel-lts-file read-string))
                            (flushes (list-matches "\"([^\"]*<flush>)\"" makreel-lts))
                            (flushes (map (cute match:substring <> 1) flushes))
                            (flushes (delete-duplicates flushes))
                            (taus (append '("<deadlock>" "<livelock>" "optional" "inevitable") flushes)))
                       (with-output-to-file makreel-lts-file
                         (cute display makreel-lts))
                       (mkdir-p out-lang)
                       (with-output-to-file (string-append out-lang "/" base-name ".aut")
                         (cute display stdout))
                       ;; FIXME: --structured-output with -eweak-trace still writes to disk
                       (with-directory-excursion out-lang
                         (receive (status stdout stderr)
                             (observe
                              `("ltscompare" "--counter-example" "--structured-output"
                                "-eweak-trace"
                                ,(string-append "--tau=" (string-join taus ","))
                                ,(string-append "../traces/" base-name ".aut")
                                ,(string-append base-name ".aut"))
                              "")
                           (display stdout)
                           (let* ((lines (and stdout (string-split stdout #\newline)))
                                  (stdout-status (and lines (filter (cut string-prefix? "result: " <>) lines)))
                                  (stdout-status (and (pair? stdout-status) (car stdout-status)))
                                  (status (if (and (zero? status)
                                                   stdout-status
                                                   (string=? stdout-status "result: true"))
                                              EXIT_SUCCESS EXIT_FAILURE)))
                             (zero? status))))))))))))

(define (run-test file-name languages)
  (setvbuf (current-output-port) 'line)
  (format #t "* run: ~a ~a\n" file-name languages)
  (let ((result (and (run-verify file-name)
                     (run-traces file-name)
                     (run-lts file-name)
                     (run-simulate file-name)
                     (and-map (cut run-code file-name <>) languages))))
    (format #t "# Local Variables:
# mode: org
# End:
")
    result))

;;; Local Variables:
;;; mode: scheme
;;; End:
