;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2020, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017 Henk Katerberg <hank@mudball.nl>
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

(define-module (dzn commands verify)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 getopt-long)

  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code language makreel)
  #:use-module (dzn command-line)
  #:use-module (dzn commands parse)
  #:use-module (dzn config)
  #:use-module (dzn parse)
  #:use-module (dzn verify pipeline)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((all (single-char #\a))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (jitty (single-char #\j))
            (model (single-char #\m) (value #t))
            (no-constraint (single-char #\C))
            (no-interfaces)
            (no-non-compliance (single-char #\D))
            (no-unreachable (single-char #\U))
            (out (value #t))
            (queue-size (single-char #\q) (value #t))
            (queue-size-defer (value #t))
            (queue-size-external (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (out (option-ref options 'out #f))
	 (usage? (and (not help?) (null? files))))
    (when (equal? out "help")
      (format #t "formats:~a\n" (string-join (verification:formats) "\n  " 'prefix))
      (exit EXIT_SUCCESS))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn verify [OPTION]... DZN-FILE
Check DZN-FILE for verification errors in Dezyne models

  -a, --all                keep going after first error
  -C, --no-constraint      do not use a constraining process
  -D, --no-non-compliance  report deadlock upon non-compliance
  -h, --help               display this help and exit
  -I, --import=DIR+        add DIR to import path
  -j, --jitty              run lps2lts with --rewriter=jittyc
  -m, --model=MODEL        restrict verification to model MODEL
      --no-interfaces      skip interface verification
      --out=FORMAT         produce output FORMAT (use \"help\" for a list)
  -U, --no-unreachable     skip the unreachable code check
  -q, --queue-size=SIZE    use queue size=SIZE for verification [~a]
      --queue-size-defer=SIZE
                           use defer queue size=SIZE for verification [~a]
      --queue-size-external=SIZE
                           use external queue size=SIZE for verification [~a]
" (%queue-size) (%queue-size-defer) (%queue-size-external))
	(exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (main args)
  (setvbuf (current-output-port) 'line)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (all? (option-ref options 'all #f))
         (debug? (dzn:command-line:get 'debug #f))
         (out (option-ref options 'out #f))
         (model-name (option-ref options 'model #f))
         (ast (parse options file-name))
         (model (and model-name (call-with-handle-exceptions
                                 (lambda _ (ast:get-model ast model-name))
                                 #:backtrace? debug?
                                 #:file-name file-name)))
         (no-unreachable? (command-line:get 'no-unreachable))
         (queue-size (option-ref options 'queue-size (%queue-size)))
         (queue-size-defer (option-ref options 'queue-size-defer
                                       (%queue-size-defer)))
         (queue-size-external (option-ref options 'queue-size-external
                                          (%queue-size-external))))
    (parameterize ((%no-unreachable? no-unreachable?)
                   (%queue-size queue-size)
                   (%queue-size-defer queue-size-defer)
                   (%queue-size-external queue-size-external))
      (let ((root (makreel:om ast)))
        (when (and=> model ast:imported?)
          (let ((name (ast:dotted-name model)))
            (format (current-error-port)
                    "~a:error: cannot verify imported model: ~a\n"
                    (ast:source-file root)
                    name)
            (format (current-error-port)
                    "~a:info: ~a imported from here\n"
                    (ast:source-file model)
                    name))
          (exit EXIT_OTHER_FAILURE))
        (cond
         (out
          (let ((formats (verification:formats)))
            (unless (member out formats)
              (format #t "formats:~a\n" (string-join (verification:formats)
                                                     "\n  " 'prefix))
              (exit EXIT_OTHER_FAILURE))
            (let* ((model (call-with-handle-exceptions
                           (lambda _ (ast:get-model ast model-name))
                           #:backtrace? debug?
                           #:file-name file-name))
                   (model-name (ast:dotted-name model)))
              (verification:partial root model-name #:out out))))
         (else
          (exit (verification:verify options root #:all? all?
                                     #:model-name model-name))))))))
