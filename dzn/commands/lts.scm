;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2018, 2019, 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2018 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018, 2019, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

(define-module (dzn commands lts)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)

  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:use-module (dzn command-line)

  #:export (main))

(define (parse-opts args)
  (let* ((option-spec '((cleanup (single-char #\c))
                        (unreachable (value #t))
                        (deadlock (single-char #\d))
                        (exclude-illegal)
                        (exclude-tau (value #t))
                        (failures (single-char #\f))
                        (help (single-char #\h))
                        (illegal (single-char #\i))
                        (livelock (single-char #\l))
                        (deterministic-labels (single-char #\n) (value #t))
                        (prefix (single-char #\p) (value #t))
                        (single-line (single-char #\s))
                        (tau (single-char #\t) (value #t))))
         (options (getopt-long args option-spec))
         (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (when help?
      (format #t "\
Usage: dzn lts [OPTION]... [FILE]...
Navigate and query an LTS from FILE in Aldebaran (AUT) format.

  -c, --cleanup                   rewrite makreel labels to dezyne, optionlly remove PREFIX
      --unreachable TAG[,TAG...]  report tags from TAGS that are not present in the lts
  -d, --deadlock                  detect deadlock in LTS (after failures introduction)
      --exclude-illegal           remove edges leading to illegal (in combination with
                                    option --failures)
  -f, --failures                  introduce a failure for each 'optional' event
  -h, --help                      display this help and exit
  -i, --illegal                   detect whether LTS contains <illegal> labels
  -l, --livelock                  detect tau-loops in LTS
  -n, --deterministic-labels=LABEL[,LABEL...]
                                  assert determinism by detecting multiple edges
                                  of LABEL from a single state
      --prefix PREFIX             optional PREFIX for --cleanup
  -t, --tau=EVENT[,EVENT...]      hide all EVENTs
      --exclude-tau=EVENT[,EVENT...]
                                  exclude given EVENTs from '--tau' list
  -s, --single-line               report an error including trace on a single line
")
      (exit EXIT_SUCCESS))
    options))

(define (main args)
  (let* ((sep #\,)
         (input-separator #\;)
         (output-separator ";")
         (options (parse-opts args))
         (cleanup? (option-ref options 'cleanup #f))
         (exclude-tau (option-ref options 'exclude-tau #f))
         (exclude-tau (if exclude-tau (string-split exclude-tau sep) '()))
         (unreachable (option-ref options 'unreachable #f))
         (unreachable (match unreachable
                        ("" '())
                        ((? string?) (string-split unreachable input-separator))
                        (_ #f)))
         (files (option-ref options '() '()))
         (file-name (and (pair? files) (car files)))
         (deadlock? (option-ref options 'deadlock #f))
         (exclude-illegal? (option-ref options 'exclude-illegal #f))
         (failures? (option-ref options 'failures #f))
         (illegal? (option-ref options 'illegal #f))
         (livelock? (option-ref options 'livelock #f))
         (deterministic-labels (option-ref options 'deterministic-labels #f))
         (deterministic-labels (and deterministic-labels
                                    (string-split deterministic-labels sep)))
         (prefix (option-ref options 'prefix #f))
         (single-line? (option-ref options 'single-line #f))
         (output-separator (if single-line? output-separator "\n"))
         (tau (option-ref options 'tau #f))
         (tau (if tau (string-split tau sep) '()))
         (tau (cons "tau" tau)))

    (define (report-result check failure-message pass-message trace)
      (let* ((fail? trace)
             (trace (map edge-label (or trace '())))
             (trace (string-join trace output-separator)))
        (cond
         (single-line?
          (display
           (string-append check ":"
                          (if fail? "fail" "ok")
                          (if fail? (string-append ":" trace) "") "\n")))
         (fail?
          (format (current-error-port) "~a\n" failure-message)
          (unless (string-null? trace)
            (format #t "~a\n" trace)))
         (else
          (format (current-error-port) "~a\n" pass-message)))))
    (define (report-result-unreachable check fail-msg ok-msg tags)
      (define (tag->line-column tag)
        (let* ((m (string-match "tag\\(([0-9]+), *([0-9]+)\\)" tag))
               (line (match:substring m 1))
               (column  (match:substring m 2)))
          (format #f "~a,~a" line column)))
      (define (tag< a b)
        (define (tag->list tag)
          (map string->number (string-split tag #\,)))
        (match (cons (tag->list a) (tag->list b))
          (((line-a column-a) . (line-b column-b))
           (or (< line-a line-b)
               (and (= line-a line-b) (< column-a column-b))))))
      (let ((tags (and tags (sort (map tag->line-column tags) tag<))))
        (cond ((and single-line? tags)
               (let ((tags (string-join tags output-separator)))
                 (format #t "~a:fail:~a\n" check tags)))
              (tags
               (format (current-error-port) "~a\n" fail-msg)
               (format #t "~a\n" (string-join tags "\n")))
              (single-line?
               (format #t "~a:ok\n" check)))))
    (cond
     (cleanup?
      (cleanup-aut #:file-name file-name #:prefix prefix))
     (else
      (let* ((text (if (or (null? files) (equal? "-" file-name))
                       (with-input-from-port (current-input-port) read-string)
                       (with-input-from-file file-name read-string)))
             (lts (aut-text->lts text))
             (lts-hide (lts-hide lts tau exclude-tau))
             (nodes-hide (lts->nodes lts-hide)))
        (when illegal?
          (report-result "illegal"
                         "LTS contains illegal events"
                         "LTS contains no illegal events"
                         (assert-illegal nodes-hide)))
        (when livelock?
          (report-result "livelock"
                         "tau loop found:"
                         "No tau loop found."
                         (assert-livelock nodes-hide)))
        (when deterministic-labels
          (report-result "deterministic"
                         "LTS is non-deterministic"
                         "LTS is deterministic"
                         (assert-partially-deterministic lts-hide deterministic-labels)))
        (let ((lts-failures (add-failures nodes-hide)))
          (when deadlock?
            (report-result "deadlock"
                           "deadlock found:"
                           "No deadlock found."
                           (assert-deadlock lts-failures)))
          (when unreachable
            (report-result-unreachable "unreachable"
                                       "unreachable code found:"
                                       "No unreachable code found."
                                       (assert-unreachable lts-hide unreachable)))
          (when failures?
            (let ((lts (remove-tag-edges
                        (if exclude-illegal? (remove-illegal lts-failures)
                            lts-failures))))
              (when single-line?
                (format #t "failures:"))
              (display-lts lts #:separator output-separator)))))))))
