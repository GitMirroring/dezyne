;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2020, 2021 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code makreel)
  #:use-module (dzn command-line)
  #:use-module (dzn commands code)
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
            (model (single-char #\m) (value #t))
            (no-unreachable (single-char #\U))
            (out (value #t))
            (queue-size (single-char #\q) (value #t))))
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

  -a, --all                   keep going after first error
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           restrict verification to model MODEL
      --out=FORMAT            produce output FORMAT (use \"help\" for a list)
  -U, --no-unreachable        skip the unreachable code check
  -q, --queue-size=SIZE       use queue size=SIZE for verification [3]
")
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
         (no-unreachable? (command-line:get 'no-unreachable)))
    (parameterize ((%no-unreachable? no-unreachable?))
      (let ((root (makreel:om ast)))
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
