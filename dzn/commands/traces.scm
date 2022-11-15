;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2017, 2018, 2021, 2022, 2023 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
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

(define-module (dzn commands traces)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 regex)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code)
  #:use-module (dzn code language makreel)
  #:use-module (dzn command-line)
  #:use-module (dzn commands parse)
  #:use-module (dzn config)
  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:use-module (dzn verify pipeline)

  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((flush (single-char #\f))
            (dzn (single-char #\G))
            (help (single-char #\h))
            (illegal (single-char #\i))
            (import (single-char #\I) (value #t))
            (jitty (single-char #\j))
            (lts (single-char #\l))
            (traces (single-char #\t))
            (model (single-char #\m) (value #t))
            (no-constraint (single-char #\C))
            (no-non-compliance (single-char #\D))
            (output (single-char #\o) (value #t))
            (queue-size (single-char #\q) (value #t))
            (queue-size-defer (value #t))
            (queue-size-external (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn traces [OPTION]... DZN-FILE
Generate exhaustive set of traces for Dezyne model

  -C, --no-constraint         do not use a constraining process
  -D, --no-non-compliance     report deadlock upon non-compliance
  -f, --flush                 include <flush> events in trace
  -h, --help                  display this help and exit
  -i, --illegal               include traces that lead to an illegal
  -j, --jitty                 pass to lps2lts, for LARGE models
  -I, --import=DIR+           add DIR to import path
  -l, --lts                   also generate LTS
  -m, --model=MODEL           generate traces for model MODEL
  -o, --output=DIR            write lts,traces in directory DIR
  -t, --traces                also generate traces (default)
  -q, --queue-size=SIZE       use queue size=SIZE for generation [~a]
      --queue-size-defer=SIZE
                              use defer queue size=SIZE for verification [~a]
      --queue-size-external=SIZE
                              use external queue size=SIZE for verification [~a]
" (%queue-size) (%queue-size-defer) (%queue-size-external))
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (lts-hide-internal-labels text)
  (let* ((text (regexp-substitute/global #f "\"<declarative-illegal>\"" text 'pre "\"<illegal>\"" 'post))
         (text (regexp-substitute/global #f "\"[^\"]*<blocking>\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"[^\"]*\\.qout\\.[^\"]*\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"(optional|inevitable)\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"[^\"]*\\.(optional|inevitable)\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"tag[()].[^\"]*\"" text 'pre "\"tau\"" 'post)))
    text))

(define (model->lts root model file-name)
  (let* ((jitty? (command-line:get 'jitty))
         (lts (verify-pipeline (if jitty? "aut-weak-trace-jitty"
                                   "aut-weak-trace")
                               root model))
         (lts (lts-hide-internal-labels lts)))
    (when (string-null? (string-trim-right lts))
      (throw 'error "failed to create LTS"))
    lts))

(define (model->traces options root model file-name)
  (let* ((verbose? (dzn:command-line:get 'verbose))
         (lts (model->lts root model file-name))
         (provides-ports (if (is-a? model <interface>) '()
                             (ast:provides-port* model)))
         (provides-in (if (is-a? model <component>)
                          (map (lambda (t) (string-append (string-drop-right (.port.name t) 1) "." (.event.name t)))
                               (ast:provides-in-triggers model))
                          (map .name (filter ast:in? (ast:event* model)))))
         (provides (map .name provides-ports))
         (model-name (makreel:unticked-dotted-name model))
         (bin ((compose dirname car) (command-line)))
         (flush-opt (option-ref options 'flush #f))
         (illegal-opt (option-ref options 'illegal #f))
         (lts? (option-ref options 'lts #f))
         (traces? (option-ref options 'traces #f))
         (output (option-ref options 'output #f)))
    (when (and output (not (equal? output "-")))
      (mkdir-p output))
    (when (or (not lts?) traces?)
      (let* ((text (string-trim-right lts))
             (lines (string-split text #\newline)))
        (lts->traces lines
                     illegal-opt
                     flush-opt
                     (is-a? model <interface>)
                     (or output ".")
                     model-name
                     provides
                     provides-in
                     #:verbose? verbose?)))
    (when lts?
      (if (and output (not (equal? output "-")))
          (with-output-to-file (string-append output "/" model-name ".aut")
            (cute display lts))
          (display lts)))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (ast (parse options file-name))
         (model-name (option-ref options 'model #f))
         (queue-size (option-ref options 'queue-size (%queue-size)))
         (queue-size-defer (option-ref options 'queue-size-defer
                                       (%queue-size-defer)))
         (queue-size-external (option-ref options 'queue-size-external
                                          (%queue-size-external))))
    (define (named? o)
      (equal? (makreel:unticked-dotted-name o) model-name))
    (parameterize ((%no-unreachable? #t)
                   (%queue-size queue-size)
                   (%queue-size-defer queue-size-defer)
                   (%queue-size-external queue-size-external))
      (let* ((root (makreel:om ast))
             (models (ast:model* root))
             (components-interfaces
              (append
               (filter (conjoin (is? <component>) .behavior) models)
               (filter (is? <interface>) models)))
             (model (or (and model-name (find named? models))
                        (and (pair? components-interfaces)
                             (car components-interfaces)))))
        (when (and=> model ast:imported?)
          (let ((name (ast:dotted-name model)))
            (format (current-error-port)
                    "~a:error: cannot generate traces for imported model: ~a\n"
                    (ast:source-file root)
                    name)
            (format (current-error-port)
                    "~a:info: ~a imported from here\n"
                    (ast:source-file model)
                    name))
          (exit EXIT_OTHER_FAILURE))
        (cond ((and model-name (not model))
               (error "no such model:" model-name))
              ((is-a? model <system>) ;; silently no traces
               #t)
              ((and model-name
                    (or (is-a? model <foreign>)
                        (not (.behavior model))))
               (error "no model with behavior:" model-name))
              (model
               (model->traces options root model file-name)))))))
