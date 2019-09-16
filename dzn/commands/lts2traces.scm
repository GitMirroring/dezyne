;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn commands lts2traces)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 rdelim)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn lts2traces)
  #:export (main))

(define (parse-opts args)
  (let* ((option-spec
          '((debug (single-char #\d))
            (flush)
            (illegal)
            (interface)
            (lts)
            (model (single-char #\m) (value #t))
            (out (value #t))
            (provided (value #t))
            (provides-in (value #t))
            (help (single-char #\h))
	    (version (single-char #\V))))
	 (options (getopt-long args option-spec
                               #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (not (= (length files) 1)))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn lts2traces [OPTION]... LTS-FILE
      --flush                 include <flush> event in trace
      --illegal               include traces that lead to an illegal
      --lts                   generate lts
  -m, --model=MODEL           generate main for MODEL
  -o, --out=DIR               write output to DIR (use - for stdout)
      --provided=PORT         add PORT to list of provide ports
      --provides-in=EVENT     add EVENT to list of provide-in events
  -h, --help                  display this help and exit
  -V, --version               display version and exit
")
          (exit (or (and usage? 2) 0)))
     options)))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (text (if (equal? file-name "-") (read-string)
                   (with-input-from-file file-name read-string)))
         (text (string-trim-right text))
         (lines (string-split text #\newline))
         (provided (multi-opt options 'provided))
         (provided (if (pair? provided) provided '("")))
         (provides-in (multi-opt options 'provides-in)))
    (lts->traces lines
                 (option-ref options 'illegal #f)
                 (option-ref options 'flush #f)
                 (option-ref options 'interface #f)
                 (option-ref options 'out #f)
                 (option-ref options 'lts #f)
                 (option-ref options 'model #f)
                 provided
                 (multi-opt options 'provides-in))))

;; if __name__ == "__main__":
;;     main()
