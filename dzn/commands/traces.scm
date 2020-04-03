;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2017, 2018, 2021 Rutger van Beusekom <rutger@dezyne.org>
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
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) 'goops:<port> x)))

  #:use-module (dzn misc)
  #:use-module (dzn config)
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn commands parse)
  #:use-module (dzn command-line)
  #:use-module (dzn lts)
  #:use-module (dzn code makreel)
  #:use-module (dzn normalize)
  #:use-module (dzn parse)
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
            (lts (single-char #\l))
            (traces (single-char #\t))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (queue-size (single-char #\q) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (when (or help? usage?)
      (let ((port (if usage? (current-error-port) (current-output-port))))
        (format port "\
Usage: dzn traces [OPTION]... DZN-FILE
Generate exhaustive set of traces for Dezyne model

  -f, --flush                 include <flush> events in trace
  -h, --help                  display this help and exit
  -i, --illegal               include traces that lead to an illegal
  -I, --import=DIR+           add DIR to import path
  -l, --lts                   also generate LTS
  -m, --model=MODEL           generate traces for model MODEL
  -o, --output=DIR            write lts,traces in directory DIR
  -t, --traces                also generate traces (default)
  -q, --queue-size=SIZE       use queue size=SIZE for generation
")
        (exit (or (and usage? EXIT_OTHER_FAILURE) EXIT_SUCCESS))))
    options))

(define (mark-async text async-ports)
  (let loop ((text text) (async-ports async-ports))
    (if (null? async-ports) text
        (loop (regexp-substitute/global #f (string-append "\"" (makreel:.name  (car async-ports)) ".inevitable\"") text 'pre "\"<ack>\"" 'post)
              (cdr async-ports)))))

(define (remove-mark-async text)
  (regexp-substitute/global #f "\"<ack>\"" text 'pre "\"tau\"" 'post))

(define (lts-hide-internal-labels text)
  (let* ((text (regexp-substitute/global #f "\"<declarative-illegal>\"" text 'pre "\"<illegal>\"" 'post))
         (text (regexp-substitute/global #f "\"[^\"]*<blocking>\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"[^\"]*\\.qout\\.[^\"]*\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"(optional|inevitable)\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"[^\"]*\\.(optional|inevitable)\"" text 'pre "\"tau\"" 'post))
         (text (regexp-substitute/global #f "\"tag[()].[^\"]*\"" text 'pre "\"tau\"" 'post)))
    text))

(define (model->lts root model file-name)
  (let* ((lts (verify-pipeline "aut-weak-trace" root model))
         (lts (if (is-a? model <interface>) lts (mark-async lts (ast:async-port* model))))
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
            (cute display (remove-mark-async lts)))
          (display lts)))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (ast (parse options file-name))
         (model-name (option-ref options 'model #f)))
    (define (named? o)
      (equal? (makreel:unticked-dotted-name o) model-name))
    (parameterize ((%no-unreachable? #t))
      (let* ((root (makreel:om ast))
             (models (ast:model* root))
             (components-interfaces
              (append
               (filter (conjoin (is? <component>) .behavior) models)
               (filter (is? <interface>) models)))
             (model (or (and model-name (find named? models))
                        (and (pair? components-interfaces)
                             (car components-interfaces)))))
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
