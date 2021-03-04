;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
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

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn config)
  #:use-module (dzn parse)
  #:use-module (dzn code makreel)
  #:use-module (dzn commands parse)
  #:use-module (dzn commands code)
  #:use-module (dzn verify pipeline)
  #:use-module (dzn command-line)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((all (single-char #\a))
            (debug (single-char #\d))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (queue-size (single-char #\q) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
         (out (option-ref options 'out #f))
	 (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn verify [OPTION]... DZN-FILE
Check DZN-FILE for verification errors in Dezyne models

  -a, --all                   keep going after first error
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           restrict verification to model MODEL
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
         (model-name (option-ref options 'model #f))
         (ast (parse options file-name))
         (model (and model-name (call-with-handle-exceptions
                                 (lambda _ (ast:get-model ast model-name))
                                 #:backtrace? debug?
                                 #:file-name file-name)))
         (root (makreel:om ast)))
    (exit (verification:verify options root #:all? all? #:model-name model-name))))
