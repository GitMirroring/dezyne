;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; Copyright (c) 2025 Sergio Pastor Pérez <sergio.pastorperez@gmail.com>

(define-module (bluebox build blue-build-system)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-19)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-34)
  #:use-module (ice-9 exceptions)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match)
  #:use-module (guix build utils)
  #:use-module ((guix build gnu-build-system) #:prefix gnu:)
  #:export (%standard-phases
            blue-build))

(define* (bootstrap-blue #:key blue inputs #:allow-other-keys)
  "If the package definition specifies a relative path instead of a blue
package, use that path for bootstraping"
  (let ((cache-path (string-append (getcwd) "/../" "cache"))
        (blue-path (false-if-exception (canonicalize-path blue))))
    ;; KLUDGE: Disabling auto-compilation until
    ;; 'https://codeberg.org/lapislazuli/blue/issues/133' is implemented.
    (setenv "GUILE_AUTO_COMPILE" "0")
    (setenv "XDG_CACHE_HOME" cache-path)
    (if (string? blue)
        (cond
         (blue-path
          (substitute* (string-append (or blue-path "") "/blue/blue")
            (("#!.*/bin/sh")
             (string-append "#!" (search-input-file inputs "/bin/guile") " \\
--no-auto-compile -e main -s")))
          (setenv "BLUE_EMBEDDED" blue-path)
          (setenv "PATH" (string-append
                          (string-append blue-path "/blue" ":" (getenv "PATH")))))
         (else
          (raise-exception
           (make-exception
            (make-external-error)
            (make-exception-with-origin (format #f "#:blue ~a" blue))
            (make-exception-with-irritants blue)
            (make-exception-with-message
             "Blue path does not exists or is not a directory")))))
        (format #t "BLUE build system bootstrapping not needed~%"))))

(define* (configure #:key build target native-inputs inputs outputs
                    (blue-flags '()) (configure-flags '()) out-of-source?
                    #:allow-other-keys)
  (define (package-name)
    (let* ((out  (assoc-ref outputs "out"))
           (base (basename out))
           (dash (string-rindex base #\-)))
      ;; XXX: We'd rather use `package-name->name+version' or similar.
      (string-drop (if dash
                       (substring base 0 dash)
                       base)
                   (+ 1 (string-index base #\-)))))

  (let* ((prefix     (assoc-ref outputs "out"))
         (bindir     (assoc-ref outputs "bin"))
         (libdir     (assoc-ref outputs "lib"))
         (includedir (assoc-ref outputs "include"))
         (docdir     (assoc-ref outputs "doc"))
         (bash       (or (and=> (assoc-ref (or native-inputs inputs) "bash")
                                (cut string-append <> "/bin/bash"))
                         "/bin/sh"))
         (flags      `(,@(if target             ; cross building
                             '("CC_FOR_BUILD=gcc")
                             '())
                       ,(string-append "CONFIG_SHELL=" bash)
                       ,(string-append "SHELL=" bash)
                       ,(string-append "--prefix=" prefix)
                       "--enable-fast-install"    ; when using Libtool

                       ;; Produce multiple outputs when specific output names
                       ;; are recognized.
                       ,@(if bindir
                             (list (string-append "--bindir=" bindir "/bin"))
                             '())
                       ,@(if libdir
                             (cons (string-append "--libdir=" libdir "/lib")
                                   (if includedir
                                       '()
                                       (list
                                        (string-append "--includedir="
                                                       libdir "/include"))))
                             '())
                       ,@(if includedir
                             (list (string-append "--includedir="
                                                  includedir "/include"))
                             '())
                       ,@(if docdir
                             (list (string-append "--docdir=" docdir
                                                  "/share/doc/" (package-name)))
                             '())
                       ,@(if build
                             (list (string-append "--build=" build))
                             '())
                       ,@(if target               ; cross building
                             (list (string-append "--host=" target))
                             '())
                       ,@configure-flags))
         (abs-srcdir (getcwd))
         (srcdir     (if out-of-source?
                         (string-append "../" (basename abs-srcdir))
                         ".")))
    (format #t "source directory: ~s (relative from build: ~s)~%"
            abs-srcdir srcdir)
    (if out-of-source?
        (begin
          (mkdir "../build")
          (chdir "../build")
          (setenv "BLUE_BLUEPRINT" (string-append abs-srcdir
                                                  "/blueprint.scm"))))
    (format #t "build directory: ~s~%" (getcwd))
    (format #t "configure flags: ~s~%" flags)

    ;; Use BASH to reduce reliance on /bin/sh since it may not always be
    ;; reliable (see
    ;; <http://thread.gmane.org/gmane.linux.distributions.nixos/9748>
    ;; for a summary of the situation.)
    ;;
    ;; Call `configure' with a relative path.  Otherwise, GCC's build system
    ;; (for instance) records absolute source file names, which typically
    ;; contain the hash part of the `.drv' file, leading to a reference leak.
    (apply invoke "blue" `(,@blue-flags "configure" ,@flags))))

(define* (build #:key (blue-flags '()) (build-command "build")
                (parallel-build? #t)
                #:allow-other-keys)
  (let* ((build-string (if (list? build-command)
                           (car build-command)
                           build-command))
         (build-command* (string-split build-string #\space)))
    (apply invoke
           "blue"
           `(,@(if parallel-build?
                   '()
                   '("--jobs=1"))
             ,@blue-flags
             ,@build-command*))))

(define* (check #:key target (blue-flags '()) (tests? (not target))
                (test-command "check")
                (test-suite-log-regexp (@@ (guix build gnu-build-system)
                                           %test-suite-log-regexp))
                (parallel-tests? #t)
                #:allow-other-keys)
  (if tests?
      (guard (c ((invoke-error? c)
                 ;; Dump the test suite log to facilitate debugging.
                 (display "\nTest suite failed, dumping logs.\n"
                          (current-error-port))
                 (gnu:dump-file-contents "." test-suite-log-regexp)
                 (raise c)))
        (let* ((test-string (if (list? test-command)
                                (car test-command)
                                test-command))
               (test-command* (string-split test-string #\space)))
          (apply invoke
                 "blue"
                 `(,@(if parallel-tests?
                         '()
                         `("--jobs=1"))
                   ,@blue-flags
                   ,@test-command*))))
      (format #t "test suite not run~%")))

(define* (install #:key (blue-flags '()) (install-command "install")
                  #:allow-other-keys)
  (let* ((install-string (if (list? install-command)
                             (car install-command)
                             install-command))
         (install-command* (string-split install-string #\space)))
    (apply invoke "blue" `(,@blue-flags ,@install-command*))))

(define %standard-phases
  (modify-phases gnu:%standard-phases
    (add-after 'patch-source-shebangs 'bootstrap-blue
      bootstrap-blue)
    (replace 'configure configure)
    (replace 'build build)
    (replace 'check check)
    (replace 'install install)))

(define* (blue-build #:key (source #f) (outputs #f) (inputs #f)
                     (build-command "build")
                     (test-command "check")
                     (install-command "install")
                     (phases %standard-phases)
                     (subphase-names '())
                     #:allow-other-keys
                     #:rest args)
  "Build from SOURCE to OUTPUTS, using INPUTS, and by running all of PHASES
in order.  Return #t if all the PHASES succeeded, #f otherwise."
  (define (elapsed-time end start)
    (let ((diff (time-difference end start)))
      (+ (time-second diff)
         (/ (time-nanosecond diff) 1e9))))

  (setvbuf (current-output-port) 'line)
  (setvbuf (current-error-port) 'line)

  ;; Encoding/decoding errors shouldn't be silent.
  (fluid-set! %default-port-conversion-strategy 'error)

  (guard (c ((invoke-error? c)
             (report-invoke-error c)
             (exit 1)))
    ;; The trick is to #:allow-other-keys everywhere, so that each procedure in
    ;; PHASES can pick the keyword arguments it's interested in.
    (for-each (match-lambda
                ((name . proc)
                 (let ((start (current-time time-monotonic))
                       (phase-type (if (member name subphase-names)
                                       "subphase"
                                       "phase")))
                   (define (end-of-phase success?)
                     (let ((end (current-time time-monotonic)))
                       (format #t "~a `~a' ~:[failed~;succeeded~] after ~,1f seconds~%"
                               phase-type name success?
                               (elapsed-time end start))

                       ;; Dump the environment variables as a shell script,
                       ;; for handy debugging.
                       (system "export > $NIX_BUILD_TOP/environment-variables")))

                   (format #t "starting ~a `~a'~%" phase-type name)
                   (with-throw-handler #t
                     (lambda ()
                       (apply proc args)
                       (end-of-phase #t))
                     (lambda args
                       ;; This handler executes before the stack is unwound.
                       ;; The exception is automatically re-thrown from here,
                       ;; and we should get a proper backtrace.
                       (format (current-error-port)
                               "error: in ~a '~a': uncaught exception:
~{~s ~}~%" phase-type name args)
                       (end-of-phase #f))))))
              phases)))
