;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018, 2019 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (dzn lts)
  #:use-module (dzn config)
  #:use-module (dzn command-line)
  #:export (main))

(define (parse-opts args)
  (let* ((option-spec '((accepts (single-char #\a))
                        (deadlock (single-char #\d))
                        (deterministic)
                        (events (single-char #\e))
                        (exclude-illegal)
                        (failures (single-char #\f))
                        (help (single-char #\h))
                        (illegal (single-char #\i) (value #t))
                        (livelock (single-char #\l))
                        (metrics (single-char #\m))
                        (nondet (single-char #\n) (value #t))
                        (prefix (single-char #\p) (value #t))
                        (single-line (single-char #\s))
                        (tau (single-char #\t) (value #t))
                        (validate (single-char #\v))))
         (options (getopt-long args option-spec))
         (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (when help?
      (format #t "\
Usage: dzn lts [OPTION]... [FILE]...
Navigate and query an LTS from FILE in Aldebaran (AUT) format.

  -a, --accepts                   list acceptance sets for state reachable by TRACE
  -d, --deadlock                  detect deadlock in LTS (after failures introduction)
      --deterministic             detect non-determinism in LTS with respect to all labels
  -e, --events                    list event alphabet (edge labels) for each FILE.
      --exclude-illegal           remove edges leading to illegal (in combination with
                                    option --failures)
  -f, --failures                  introduce a failure for each 'optional' event
  -h, --help                      display this help and exit
  -i, --illegal=LABEL[,LABEL...]  detect whether LTS contains the labels from LABELs
  -l, --livelock                  detect tau-loops in LTS
  -m, --metrics                   number of states and number of transitions.
  -n, --nondet=LABEL[,LABEL...]   Assert non-determinism by detecting multiple edges
                                    of LABEL from a single state
  -p, --prefix=EVENT[,EVENT...]   find states reachable by EVENTs
                                    [default: empty trace => initial state]
  -t, --tau=EVENT[,EVENT...]      hide all EVENTs
  -s, --single-line               report an error including trace on a single line
  -v, --validate                  validate Aldebran (AUT)-files
")
      (exit EXIT_SUCCESS))
    options))

(define (main args)
  (let* ((sep #\,)
         (output-separator #\;)
         (options (parse-opts args))
         (accepts (option-ref options 'accepts #f))
         (files (option-ref options '() '()))
         (events (option-ref options 'events #f))
         (deadlock (option-ref options 'deadlock #f))
         (deterministic (option-ref options 'deterministic #f))
         (exclude-illegal (option-ref options 'exclude-illegal #f))
         (failures (option-ref options 'failures #f))
         (illegal (option-ref options 'illegal #f))
         (illegal (if illegal (string-split illegal sep) #f))
         (livelock (option-ref options 'livelock #f))
         (metrics (option-ref options 'metrics #f))
         (nondet (option-ref options 'nondet #f))
         (nondet (if nondet (string-split nondet sep) #f))
         (prefix (option-ref options 'prefix #f))
         (prefix (if prefix (string-split prefix sep) '()))
         (single-line (option-ref options 'single-line #f))
         (tau (option-ref options 'tau #f))
         (tau (if tau (string-split tau sep) '()))
         (tau (cons "tau" tau))
         (validate (option-ref options 'validate #f))
         (version? (option-ref options 'version #f))
         (lts- #f)
         (lts-nodes- #f)
         (lts-hide- #f)
         (lts-hide-nodes- #f)
         (lts-failures- #f))

    (define (get-lts)
      (if (not lts-) (set! lts- (aut-file->lts (if (or (null? files) (equal? "-" (car files)))
                                                   (read-string (current-input-port))
                                                   (with-input-from-file (car files) read-string)))))
      lts-)
    (define (get-lts-nodes)
      (if (not lts-nodes-) (set! lts-nodes- (lts->nodes (get-lts))))
      lts-nodes-)
    (define (get-lts-hide)
      (if (not lts-hide-) (set! lts-hide- (lts-hide (get-lts) tau)))
      lts-hide-)
    (define (get-lts-hide-nodes)
      (if (not lts-hide-nodes-) (set! lts-hide-nodes- (lts->nodes (get-lts-hide))))
      lts-hide-nodes-)
    (define (get-lts-failures)
      (if (not lts-failures-) (set! lts-failures- (add-failures (get-lts-hide-nodes))))
      lts-failures-)
    (define (report-result check fail-msg ok-msg trace)
      (let* ((lts (get-lts))
             (states (lts-states lts))
             (transitions (length (lts-edges lts))))
        (if single-line (display (string-append check ":" (if trace "fail" "ok") ":" (number->string states) "," (number->string transitions) ":" (if trace (string-join (map edge-label trace) (make-string 1 output-separator)) "") "\n"))
            (if trace (begin
                        (format (current-error-port) "~a\n" fail-msg)
                        (if (not (null? trace))
                            (format #t "~a\n" (string-join (map edge-label trace) "\n"))))
                (format (current-error-port) "~a\n" ok-msg)))))

    (define (validation-error error)
      (or (not error)
          (begin (format (current-error-port) "Error in aut file: ~a - ~a\n" path error)
                 #f)))

    (when events
      (let ((alphabets (map (compose lts->alphabet (cut lts-hide <> tau) aut-file->lts) files)))
        (map (lambda (f a) (format #t "Events in lts ~a:\n~a\n" f a)) files alphabets)))
    (when accepts
      (let* ((lts (rm-tau-loops (get-lts-hide-nodes)))
             (lts (step-tau lts))
             (lts (run lts prefix))
             (acceptance-sets (lts-stable-accepts lts)))
        (format #t "stable acceptance sets: ~a\n" acceptance-sets)))
    (when deterministic
      (report-result "deterministic" "LTS is non-deterministic" "LTS is deterministic" (assert-deterministic (get-lts-hide))))
    (when illegal
      (report-result "illegal" "LTS contains illegal events" "LTS contains no illegal events" (assert-illegal (get-lts-hide-nodes) illegal)))
    (when metrics
      (map print-metrics files))
    (when livelock
      (report-result "livelock" "tau loop found:" "No tau loop found." (assert-livelock (get-lts-hide-nodes))))
    (when nondet
      (report-result "deterministic" "LTS is non-deterministic" "LTS is deterministic" (assert-partially-deterministic (get-lts-hide) nondet)))
    (when validate
      (if (member #f (map (compose validation-error validate-aut-file) files))
          (begin
            (format (current-error-port) "Invalid aut file(s) found.")
            #f)))
    (when deadlock
      (report-result "deadlock" "deadlock found:" "No deadlock found." (assert-deadlock (get-lts-failures))))
    (when failures
      (write-lts "failures" single-line (car (lts-state (get-lts))) ((if exclude-illegal remove-illegal identity) (get-lts-failures))))))
