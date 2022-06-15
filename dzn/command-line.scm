;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017, 2018 Johri van Eerd <vaneerd.johri@gmail.com>
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

(define-module (dzn command-line)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (dzn config)
  #:use-module (dzn script)
  #:export (command-line:get
            command-line:get-number
            command:command-line
            dzn:command-line:get
            dzn:debugity
            dzn:multi-opt
            dzn:verbosity
            %locations?
            multi-opt
            show-version-and-exit
            EXIT_OTHER_FAILURE))

(define EXIT_OTHER_FAILURE 2)

(define %locations?
  (make-parameter #f))

(define multi-options
  '(import transform))

(define (command)
  (let ((files (option-ref (parse-opts (command-line)) '() '(#f))))
    (match files
      ((command t ...) command)
      (_ "dzn"))))

(define* (command-line:get option #:optional default)
  (and (> (length (command-line)) 1)
       (let* ((files (option-ref (parse-opts (command-line)) '() '(#f)))
              (command (string->symbol (command)))
              (parse-opts (let ((module (resolve-module `(dzn commands ,command))))
                            (module-ref module 'parse-opts)))
              (options (if command (parse-opts files)
                           (parse-opts (command-line)))))
         (if (not (member option multi-options)) (option-ref options option default)
             (multi-opt options option)))))

(define* (command-line:get-number option #:optional (default 0))
  (let* ((value (command-line:get option (number->string default)))
         (number (string->number value)))
    (unless number
      (format (current-error-port)
              "~a: number expected for option --~a, got: `~a'\n"
              (command) option value)
      (exit EXIT_OTHER_FAILURE))
    number))

(define (dzn:options)
  (parse-opts (command-line)))

(define* (dzn:command-line:get option #:optional default)
  (and (> (length (command-line)) 1)
       (let ((options (parse-opts (command-line))))
         (option-ref options option default))))

(define (multi-opt options name)
  (let ((opt? (lambda (o) (and (eq? (car o) name) (cdr o)))))
    (filter-map opt? (reverse options))))

(define (dzn:multi-opt name)
  (and (> (length (command-line)) 1)
       (multi-opt (dzn:options) name)))

(define (dzn:debugity)
  (or (and (pair? (command-line))
           (member ((compose basename car command-line))
                   '("dzn" ".dzn-real"))
           (and=> (dzn:multi-opt 'debug) length))
      0))

(define (dzn:verbosity)
  (dzn:multi-opt 'debug))

(define* (command:command-line #:optional (options (dzn:options)))
  (option-ref options '() '()))

(define* (show-version-and-exit
          #:optional (command (basename (car (command-line)))))
  "Display version information for COMMAND and exit EXIT_SUCCESS."
  (format #t "~a (~a) ~a~%" command %package-name %package-version)
  (display %copyright-info)
  (newline)
  (display %license-info)
  (exit EXIT_SUCCESS))
