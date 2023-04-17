;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Timothy Sample <samplet@ngyro.com>
;;; Copyright © 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (test dzn dzn)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)

  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn pipe)
  #:use-module (dzn shell-util)
  #:use-module (dzn trace)
  #:export (%default-stages
            run-baseline
            run-test))

(define %default-stages
  '("verify" "traces" "simulate" "lts" "code"))


;;;
;;; Invocation helpers
;;;

(define %interpreter-alist
  `(("javascript" . ,(list (or (getenv "NODE") "node")))
    ("scheme" . ,(list (or (getenv "GUILE") "guile") "--no-auto-compile"))))

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

(define (ltscompare-status? status stdout)
  (let* ((lines (and stdout (string-split stdout #\newline)))
         (stdout-status (and lines (filter (cute string-prefix? "result: " <>) lines)))
         (stdout-status (and (pair? stdout-status) (car stdout-status))))
    (if (and (zero? status)
             stdout-status
             (string=? stdout-status "result: true"))
        EXIT_SUCCESS EXIT_FAILURE)))


;;;
;;; META
;;;
(define (get-meta file-name)
  (let ((META (string-append file-name "/META")))
    (and (file-exists? META)
         (with-input-from-file META read))))

(define (skip? file-name . stages)
  (let ((alist (get-meta file-name)))
    (and alist
         (or-map (lambda (stage)
                   (let ((stages (and=> (assq-ref alist 'skip)
                                        car)))
                     (and=> stages (cute member stage <>))))
                 stages)
         (format #t "skip\n"))))

(define (get-meta-flag file-name flag)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq-ref alist flag)
                (cute equal? <> '(#t))))))

(define (fall-back? file-name)
  (get-meta-flag file-name 'fall-back))

(define (flush? file-name)
  (get-meta-flag file-name 'flush))

(define (queue-size file-name)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq-ref alist 'queue-size) car))))

(define (queue-size-defer file-name)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq-ref alist 'queue-size-defer) car))))

(define (queue-size-external file-name)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq-ref alist 'queue-size-external) car))))

(define (thread-pool? file-name)
  (get-meta-flag file-name 'thead-pool))

(define (thread-safe-shell? file-name)
  (get-meta-flag file-name 'tss))

(define (code-options file-name)
  (let ((alist (get-meta file-name)))
    (or (and alist
             (and=> (assq-ref alist 'code-options) car))
        '())))

(define (model? file-name)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq-ref alist 'model) car))))

(define (model-unset? file-name)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq 'model alist)
                (cute equal? <> '(model #f))))))

(define (trace-format file-name)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq-ref alist 'trace-format) car))))

(define (non-strict? file-name)
  (let ((alist (get-meta file-name)))
    (and alist
         (and=> (assq-ref alist 'non-strict?) car))))

(define (simulate-flags file-name)
  (let ((alist (get-meta file-name)))
    (or (and alist
             (and=> (assq-ref alist 'simulate-flags) car))
        '())))


;;;
;;; Utility.
;;;
(define (error-model? file-name)
  (or (file-exists? (string-append file-name "/baseline/verify.out"))
      (file-exists? (string-append file-name "/baseline/verify.err"))
      ;; no verify baseline for system error models
      (file-exists? (string-append file-name "/baseline/simulate.out"))
      (file-exists? (string-append file-name "/baseline/simulate.err"))))

(define (features file-name)
  (define (feature? feature)
    (and (string-contains file-name feature) feature))
  (filter identity
          (list
           (feature? "block")
           (and (or (feature? "_race") ;: XXX rename tests => collateral?
                    (feature? "collateral"))
                "collateral")
           (feature? "calling_context")
           (feature? "defer")
           (and (or (feature? "multiple_out")
                    (feature? "double_inevitable")
                    (feature? "flush"))
                "flush")
           (feature? "inject")
           (feature? "space"))))

(define (features-missing file-name language)
  (fold (lambda (feature missing)
          (if (member language (assoc-ref %feature-alist feature)) missing
              (cons feature missing)))
        '()
        (features file-name)))

(define (feature-skip? file-name language)
  (let ((missing (features-missing file-name language)))
    (if (null? missing) #f
        (format #t "~a: skip, no support for ~a.\n"
                language
                (string-join missing ", " 'infix)))))

(define (filter-<flush> string)
  (let* ((lines (string-split string #\newline))
         (events (filter (negate (cute string-contains <> "<flush>")) lines)))
    (string-join events "\n")))

(define (filter-<defer> string)
  (let* ((lines (string-split string #\newline))
         (events (filter (negate (cute string-contains <> "<defer>")) lines)))
    (string-join events "\n")))

(define (filter-state string)
  (let* ((lines (string-split string #\newline))
         (events (filter (negate (cute string-prefix? "(state " <>)) lines)))
    (string-join events "\n")))


;;;
;;; Stage runners.
;;;
(define (run-verify file-name)
  (format #t "** stage: verify\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cute string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cute list "-I" <>) includes))
         (fall-back? (fall-back? file-name))
         (model (or (model? file-name) base-name))
         (queue-size (queue-size file-name))
         (queue-size-defer (queue-size-defer file-name))
         (queue-size-external (queue-size-external file-name))
         (command
          (if fall-back?
              `("dzn" "--verbose" "parse" "--fall-back"
                ,@includes
                ,dzn-name)
              `("dzn" "--verbose" "verify"
                ,@includes
                "--all"
                ,@(if (not queue-size) '()
                      `("-q" ,(number->string queue-size)))
                ,@(if (not queue-size-defer) '()
                      `("--queue-size-defer" ,(number->string queue-size-defer)))
                ,@(if (not queue-size-external) '()
                      `("--queue-size-external"
                        ,(number->string queue-size-external)))
                ,@(if (model-unset? file-name) '() `("-m" ,model))
                ,dzn-name))))
    (or (skip? file-name "verify")
        (run-baseline file-name command
                      #:language "verify"))))

(define (run-code file-name language)
  (format #t "** stage: code: ~a\n" language)
  (and (let* ((base-name (basename file-name))
              (dzn-name (string-append file-name "/" base-name ".dzn"))
              (input "")
              (in-lang (string-append file-name "/" language))
              (includes (cons in-lang
                              (or (and=> (getenv "DZN_INCLUDE_PATH")
                                         (cute string-split <> #\:))
                                  '())))
              (includes (filter directory-exists? includes))
              (includes (append-map (cute list "-I" <>) includes))
              (out (string-append file-name "/out"))
              (out-lang (string-append out "/" language))
              (model (or (model? file-name) base-name))
              ;; FIXME: METAs `model' is used for component/system tricksery
              (model base-name))
         (or (error-model? file-name)
             (skip? file-name "code" language (string-append language ":code"))
             (feature-skip? file-name language)
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
              (let* ((dzn-files (append (list-files file-name ".+\\.*dzn*$")
                                        (if (not (directory-exists? in-lang)) '()
                                            (list-files in-lang ".+\\.*dzn*$"))))
                     (extra-dzn-files (filter
                                       (negate (cute equal? <> dzn-name))
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
         (and-map (cute run-execute file-name language <>) traces))))

(define (run-traces file-name)
  (format #t "** stage: traces\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cute string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cute list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (queue-size (queue-size file-name))
         (queue-size-defer (queue-size-defer file-name))
         (queue-size-external (queue-size-external file-name))
         (language "traces")
         (out (string-append file-name "/out"))
         (out-lang (string-append out "/" language))
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
               ,@(if (not queue-size) '()
                     `("-q" ,(number->string queue-size)))
               ,@(if (not queue-size-defer) '()
                     `("--queue-size-defer" ,(number->string queue-size-defer)))
               ,@(if (not queue-size-external) '()
                     `("--queue-size-external" ,(number->string
                                                 queue-size-external)))
               "--lts"
               ,dzn-name)
             input)
          (zero? status)))))

(define (run-constrained-component file-name)
  "Assert that the constrained component and the unconstrained component
are weak-bisim equivalent"
  (format #t "** stage: constrained-component\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cute string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cute list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (queue-size (queue-size file-name))
         (language "constrained-component")
         (out (string-append file-name "/out"))
         (out-lang (string-append out "/" language))
         (constrained (string-append out-lang "/constrained.aut"))
         (unconstrained (string-append out-lang "/unconstrained.aut"))
         (input ""))
    (define (component?)
      (let ((stdout
             status
             (pipeline->string
              `(("dzn" "parse"
                 ,@includes
                 "-m" ,model
                 "--list-models"
                 ,dzn-name)))))
        (and (zero? status)
             (string-contains stdout (string-append model " component")))))
    (mkdir-p out-lang)
    (or (and (error-model? file-name))
        (skip? file-name "constrained-component")
        (not (component?))
        (let ((status-constrained
               stdout-constrained
               stderr-constrained
               (observe
                `("dzn" "traces"
                  "--lts"
                  ,@includes
                  "-m" ,model
                  ,@(if queue-size `("-q" ,(number->string queue-size)) '())
                  ,dzn-name)
                input))
              (status-unconstrained
               stdout-unconstrained
               stderr-unconstrained
               (observe
                `("dzn" "traces"
                  "--lts"
                  "-C"
                  ,@includes
                  "-m" ,model
                  ,@(if queue-size `("-q" ,(number->string queue-size)) '())
                  ,dzn-name)
                input)))
          (with-output-to-file constrained (cute display stdout-constrained))
          (with-output-to-file unconstrained (cute display stdout-unconstrained))
          (and (zero? status-constrained)
               (zero? status-unconstrained)
               (let ((status
                      stdout
                      stderr
                      (observe
                       `("ltscompare" "--structured-output" "-eweak-bisim" "--tau=constrained_legal"
                         ,constrained
                         ,unconstrained)
                       input)))
                 (zero? (ltscompare-status? status stdout))))))))

(define (run-constrained-no-compliance file-name)
  "Assert that the constrained component and the no-compliance component
are weak-bisim equivalent"
  (format #t "** stage: constrained-no-compliance\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cute string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cute list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (queue-size (queue-size file-name))
         (language "constrained-no-compliance")
         (out (string-append file-name "/out"))
         (out-lang (string-append out "/" language))
         (constrained (string-append out-lang "/constrained.aut"))
         (no-compliance (string-append out-lang "/no-compliance.aut"))
         (input ""))
    (define (component?)
      (let ((stdout
             status
             (pipeline->string
              `(("dzn" "parse"
                 ,@includes
                 "-m" ,model
                 "--list-models"
                 ,dzn-name)))))
        (and (zero? status)
             (string-contains stdout (string-append model " component")))))
    (mkdir-p out-lang)
    (or (and (error-model? file-name))
        (skip? file-name "constrained-component")
        (not (component?))
        (let ((status-constrained
               stdout-constrained
               stderr-constrained
               (observe
                `("dzn" "traces"
                  "--lts"
                  ,@includes
                  "-m" ,model
                  ,@(if queue-size `("-q" ,(number->string queue-size)) '())
                  ,dzn-name)
                input))
              (status-no-compliance
               stdout-no-compliance
               stderr-no-compliance
               (observe
                `("dzn" "traces"
                  "--lts"
                  "-D"
                  ,@includes
                  "-m" ,model
                  ,@(if queue-size `("-q" ,(number->string queue-size)) '())
                  ,dzn-name)
                input)))
          (with-output-to-file constrained (cute display stdout-constrained))
          (with-output-to-file no-compliance (cute display stdout-no-compliance))
          (and (zero? status-constrained)
               (zero? status-no-compliance)
               (let ((status
                      stdout
                      stderr
                      (observe
                       `("ltscompare" "--structured-output" "-eweak-bisim" "--tau=constrained_legal"
                         ,constrained
                         ,no-compliance)
                       input)))
                 (zero? (ltscompare-status? status stdout))))))))

(define (run-build file-name language)
  (format #t "** stage: build: ~a\n" language)
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (out (string-append file-name "/out"))
         (out-lang (string-append out "/" language))
         (thread-pool? (thread-pool? file-name))
         (command `("make"
                    "-f" ,(string-append "test/lib/build." language ".make")
                    ,(string-append "LANGUAGE=" language)
                    ,(string-append "IN=" file-name)
                    ,(string-append "OUT=" out-lang)
                    ,@(if thread-pool? '("THREAD_POOL_O=thread_pool.o") '()))))
    (or (error-model? file-name)
        (feature-skip? file-name language)
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
         (out-lang (string-append out "/" language))
         (test (string-append out-lang "/test"))
         (interpreter (or (assoc-ref %interpreter-alist language) '())))
    (or (error-model? file-name)
        (feature-skip? file-name language)
        (skip? file-name
               language
               "code" (string-append language ":code")
               "build" (string-append language ":build")
               "execute" (string-append language ":execute"))
        (receive (status stdout stderr)
            (observe `(,@interpreter
                       ,test ,@(if (flush? file-name) '("--flush") '())) input)
          (and (zero? status)
               (let ((net (trace:format-trace stderr #:format "event")))
                 (receive (status stdout stderr)
                     (let* ((input (filter-state input))
                            (input (filter-<flush> input))
                            (input (filter-<defer> input)))
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
                                    (cute string-split <> #\:))
                             '())))
         (includes (filter directory-exists? includes))
         (includes (append-map (cute list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (language "simulate")
         (out (string-append file-name "/out"))
         (out-lang (string-append out "/" language))
         (input (filter-<flush> input))
         (model (or (model? file-name) base-name))
         (queue-size (queue-size file-name))
         (queue-size-defer (queue-size-defer file-name))
         (queue-size-external (queue-size-external file-name))
         ;; FIXME: METAs `model' is used for component/system tricksery
         (model base-name)
         (baseline? (file-exists? (string-append baseline ".out")))
         (trace-format (cond ((trace-format file-name))
                             (baseline? "trace")
                             (else "event"))))
    (receive (status stdout stderr)
        (observe `("dzn" "simulate"
                   ,@includes
                   ,@(if (not queue-size) '()
                         `("-q" ,(number->string queue-size)))
                   ,@(if (not queue-size-defer) '()
                         `("--queue-size-defer"
                           ,(number->string queue-size-defer)))
                   ,@(if (not queue-size-external) '()
                         `("--queue-size-external"
                           ,(number->string queue-size-external)))
                   "--format" ,trace-format
                   ,@(if (non-strict? file-name) '() '("--strict"))
                   ,@(simulate-flags file-name)
                   "-m" ,model
                   ,dzn-name)
                 input)

      (cond ((and (zero? status) (not baseline?))
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
                    (format (current-error-port) "ERROR: ~a\n" stderr)))))
            (else
             (let ((out-file (string-append out-lang "/out"))
                   (err-file (string-append out-lang "/err")))
               (mkdir-p out-lang)
               (with-output-to-file out-file
                 (cute display stdout))
               (with-output-to-file err-file
                 (cute display stderr))
               (let ((baseline-out (string-append baseline ".out"))
                     (baseline-err (string-append baseline ".err")))
                 (and (zero? (system* "diff" "-ywB" baseline-out out-file))
                      (or (and (string-null? stderr)
                               (not (file-exists? baseline-err)))
                          (zero? (system* "diff" "-ywB"
                                          baseline-err err-file)))))))))))

(define (run-simulate file-name)
  (format #t "** stage: simulate\n")
  (or (skip? file-name
             "simulate")
      (let ((traces (find-files file-name ".*trace.*$")))
        (and-map (cute run-simulate-trace file-name <>) traces))))

(define (run-lts file-name)
  (format #t "** stage: lts\n")
  (let* ((base-name (basename file-name))
         (dzn-name (string-append file-name "/" base-name ".dzn"))
         (input "")
         (includes (cons (string-append file-name "/dzn")
                         (or (and=> (getenv "DZN_INCLUDE_PATH")
                                    (cute string-split <> #\:))
                             '())))
         (includes (append-map (cute list "-I" <>) includes))
         (model (or (model? file-name) base-name))
         (queue-size (queue-size file-name))
         (queue-size-defer (queue-size-defer file-name))
         (queue-size-external (queue-size-external file-name))
         (language "lts")
         (out (string-append file-name "/out"))
         (out-lang (string-append out "/" language))
         (handwritten-traces (list-files file-name ".*trace.*$")))
    (or (and (error-model? file-name)
             (null? handwritten-traces))
        (skip? file-name
               "traces"
               "lts")
        (receive (status stdout stderr)
            (observe
             `("dzn" "graph" "--backend=lts"
               ,@includes
               ,@(if (not queue-size) '()
                     `("-q" ,(number->string queue-size)))
               ,@(if (not queue-size-defer) '()
                     `("--queue-size-defer" ,(number->string queue-size-defer)))
               ,@(if (not queue-size-external) '()
                     `("--queue-size-external"
                       ,(number->string queue-size-external)))
               "-m" ,model
               ,dzn-name)
             input)
          (and (zero? status)
               (let* ((makreel-lts-file (string-append out "/traces/" base-name ".aut"))
                      (lts-file (string-append out-lang "/" base-name ".aut"))
                      (taus '("<deadlock>" "<livelock>" "<state>"))
                      (modeling (list-matches
                                 "\"([^\"]*[.](inevitable|optional))\""
                                 stdout))
                      (modeling (map (cute match:substring <> 1) modeling))
                      (modeling (delete-duplicates modeling))
                      (taus+modeling (append taus modeling)))
                 (mkdir-p out-lang)
                 (with-output-to-file lts-file (cute display stdout))
                 (or (and (not (file-exists? makreel-lts-file))
                          ;; XXX skip: "probably a system"
                          (format (current-error-port) "skip compare: ~s\n" makreel-lts-file))
                     (let* ((makreel-lts (with-input-from-file makreel-lts-file read-string))
                            (flushes (list-matches "\"([^\"]*<flush>)\"" makreel-lts))
                            (flushes (map (cute match:substring <> 1) flushes))
                            (flushes (delete-duplicates flushes))
                            (blocking (list-matches "\"([^\"]*<blocking>)\"" makreel-lts))
                            (blocking (map (cute match:substring <> 1) blocking))
                            (blocking (delete-duplicates blocking))
                            (modeling (append modeling '("inevitable" "optional")))
                            (taus (append taus flushes blocking))
                            (taus+modeling (append taus modeling)))
                       (with-output-to-file makreel-lts-file
                         (cute display makreel-lts))
                       ;; FIXME: --structured-output with -eweak-trace still writes to disk
                       (with-directory-excursion out-lang
                         (receive (status stdout stderr)
                             (observe
                              `("ltscompare" "--counter-example" "--structured-output"
                                "-eweak-trace"
                                ,(string-append "--tau=" (string-join taus+modeling ","))
                                ,(string-append "../traces/" base-name ".aut")
                                ,(string-append base-name ".aut"))
                              "")
                           (display stdout)
                           (zero? (ltscompare-status? status stdout))))))))))))


;;;
;;; Entry points.
;;;
(define* (run-baseline file-name command #:key
                       (baseline (string-append file-name "/baseline"))
                       (input "")
                       (language "parse")
                       (stdout-filter identity))
  (let* ((base-out (string-append baseline "/" language))
         (baseline-out (string-append base-out ".out"))
         (baseline-err (string-append base-out ".err")))
    (receive (status stdout stderr)
        (observe command input)
      (or (and (zero? status)
               (not (file-exists? baseline-out))
               (not (file-exists? baseline-err)))
          (let* ((out (string-append file-name "/out"))
                 (out-lang (string-append out "/" language))
                 (out-file (string-append out-lang "/out"))
                 (err-file (string-append out-lang "/err")))
            (mkdir-p out-lang)
            (with-output-to-file out-file
              (cute display (stdout-filter stdout)))
            (with-output-to-file err-file
              (cute display stderr))
            (and (or (and (string-null? stdout)
                          (not (file-exists? baseline-out)))
                     (zero? (system* "diff" "-uwB" baseline-out out-file)))
                 (or (and (string-null? stderr)
                          (not (file-exists? baseline-err)))
                     (zero? (system* "diff" "-uwB"
                                     baseline-err err-file)))))))))

(define* (run-test file-name languages #:key (stages %default-stages))
  (define (skip? stage)
    (not (member stage stages)))
  (setvbuf (current-output-port) 'line)
  (format #t "* run: ~a ~a\n" file-name languages)
  (let ((result
         (and
          (or (skip? "verify") (run-verify file-name))
          (or (skip? "traces") (run-traces file-name))
          (or (skip? "simulate") (run-simulate file-name))
          (or (skip? "lts") (run-lts file-name))
          (or (skip? "code") (and-map (cute run-code file-name <>) languages))
          (or (skip? "constrained-component") (run-constrained-component file-name))
          (or (skip? "constrained-no-compliance") (run-constrained-no-compliance file-name)))))
    (format #t "# Local Variables:
# mode: org
# End:
")
    result))

;;; Local Variables:
;;; mode: scheme
;;; End:
