#! /run/current-system/profile/bin/guile \
-e main -s
!#
;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

;;; Commentary:

;;; This script means to maintain the history of the rewrite while
;;; being minimally disruptive to the Dezyne repository.

;;; Code:

(use-modules (srfi srfi-1)
             (srfi srfi-26)
             (ice-9 curried-definitions)
             (ice-9 popen)
             (ice-9 match)
             (ice-9 regex)
             (ice-9 rdelim)
             (guix build utils))

(define %ide? (file-exists? "bin/ide.in"))

(define (pke . stuff)
  "Like peek (pk), writing to (CURRENT-ERROR-PORT)."
  (newline (current-error-port))
  (display ";;; " (current-error-port))
  (write stuff (current-error-port))
  (newline (current-error-port))
  (car (last-pair stuff)))

(define (gulp-pipe command)
  (let* ((port (open-pipe command OPEN_READ))
         (output (read-string port))
         (status (close-pipe port)))
    (if (zero? status) (string-trim-right output #\newline)
        (error (format #f "pipe failed: ~s" command)))))

(define (symbolic-link? file)
  (eq? (stat:type (lstat file)) 'symlink))

(define dezyne-header "Dezyne --- Dezyne command line tools
Copyright © ~a ~a

This file is part of Dezyne.

Dezyne is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Dezyne is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
")

(define dezyne-runtime-header "dzn-runtime -- Dezyne runtime library
Copyright © ~a ~a

This file is part of dzn-runtime.

dzn-runtime is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

dzn-runtime is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
")

(define dezyne-examples-header "dzn-examples -- Dezyne examples
Copyright © ~a ~a

This file is part of dzn-examples.

dzn-examples is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

dzn-examples is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with dzn-examples.  If not, see <http://www.gnu.org/licenses/>.
")

(define ide-header "Dezyne-IDE --- An IDE for Dezyne
Copyright © ~a ~a

This file is part of Dezyne-IDE.

All rights reserved.
")

(define (delete-trailing-whitespace s)
  (regexp-substitute/global #f " \n" s 'pre "\n" 'post))

(define (comment line-comment header)
  (delete-trailing-whitespace
   (string-append
    line-comment
    " "
    (string-join
     (string-split header #\newline)
     (string-append "\n" line-comment " "))
    "\n")))

(define (scm-file? o)
  (let ((m (string-match "(\\.el$|\\.scm$|config\\.scm\\.in|dzn\\.in|ide\\.in|simulate\\.in)" o)))
    (and=> m match:string)))

(define (script-file? o)
  (let ((m (string-match "(configure.ac|pre-inst-env.in|test/bin/rename|\\.mk|\\.make|Makefile.*|\\.sh$)$" o)))
    (and=> m match:string)))

(define (code-file? o)
  (let ((m (string-match "\\.(cc|cs|dzn|js)(|.in)$" o)))
    (and=> m match:string)))

(define (author-unique author)
  (cond
   ((string-prefix? "Henk Katerberg" author)
    "Henk Katerberg <henk.katerberg@yahoo.com>")
   ((string-prefix? "Jan Nieuwenhuizen" author)
    "Jan (janneke) Nieuwenhuizen <janneke@gnu.org>")
   ((string-prefix? "Johri van Eerd" author)
    "Johri van Eerd <vaneerd.johri@gmail.com>")
   ((string-prefix? "Rob Wieringa" author)
    "Rob Wieringa <rma.wieringa@gmail.com>")
   (else
    author)))

(define (author-copyright-line file-name author)
  (let* ((m (string-match "(.*) <(.*)>" author))
         (name (and=> m (cute match:substring <> 1)))
         (email (and=> m (cute match:substring <> 2)))
         (years (gulp-pipe
                 ;; Get all commit years, filter-out copyright updates
                 (format #f
                         "git log -i --author='~a' --author='~a' --line-prefix=+ '~a' \\
| sed '-e s,^\\+commit ,\\nCommit: ,' \\
  -e 's,^+Author,Author,' \\
  -e 's,^+\\(Date:.*\\),\\1\\nMessage:,' \\
| recsel -i -e '! (Message ~~ \"copyright\")' \\
| grep ^Date: \\
| sed -r 's,.*(20[0-9][0-9]).*,\\1,'"
                         name email file-name)))
         (years (string-split years #\newline))
         (years (filter (negate string-null?) years))
         (copyright-line (gulp-pipe (format #f "grep -Ei '(~a|~a)' ~a || echo" name email file-name)))
         (original-years (string-match "© ([0-9, ]*[0-9]) +" copyright-line))
         (original-years (and=> original-years (cute match:substring <> 1)))
         (original-years (and=> original-years (cute string-split <> #\,)))
         (original-years (or (and original-years (map string-trim original-years)) '()))
         (years (append years original-years))
         (years (sort years string<))
         (years (delete-duplicates years))
         (years (string-join years ", ")))
    (format #f "Copyright © ~a ~a" years author)))

(define (filter-author line)
  (let ((m (string-match "© ([0-9, ]*[0-9]) +(.*>)" line)))
    (and m (match:substring m 2))))

(define (copyright-lines file-name)
  (let* ((original-authors (gulp-pipe
                            (format #f
                                    "grep -E 'Copyright © ([0-9, ]*[0-9]) ' ~a || echo"
                                    file-name)))
         (original-authors (string-split original-authors #\newline))
         (original-authors (filter-map filter-author original-authors))
         (authors (gulp-pipe (format #f "git log --line-prefix=+ '~a' \\
| sed '-e s,^\\+commit ,\\nCommit: ,' \\
  -e 's,^+Author,Author,' \\
  -e 's,^+\\(Date:.*\\),\\1\\nMessage:,' \\
| recsel -i -e '! (Message ~~ \"copyright\")' \\
| grep ^Author: \\
| sed 's/^Author: *//'"
                                     file-name)))
         (authors (string-split authors #\newline))
         (authors (append original-authors authors))
         (authors (map author-unique authors))
         (authors (delete-duplicates authors)))
    (map (cute author-copyright-line file-name <>) authors)))

(define (fix-header file-name)
  (format (current-error-port) "~a..." file-name)
  (let* ((header (cond (%ide?
                        ide-header)
                       ((string-suffix? "local.mk" file-name)
                        dezyne-header)
                       ((string-prefix? "runtime/examples" file-name)
                        dezyne-examples-header)
                       ((string-prefix? "runtime" file-name)
                        dezyne-runtime-header)
                       (else
                        dezyne-header)))
         (type (cond ((scm-file? file-name) ";;;")
                     ((script-file? file-name) "#")
                     ((code-file? file-name) "//")))
         (content (with-input-from-file file-name read-string))
         (header-end (and=> (string-contains content "If not, see <http://www.gnu.org/licenses/>.")
                            (cut + <> 1 (string-length "If not, see <http://www.gnu.org/licenses/>."))))
         (header-end (or (and=> (string-contains content "All rights reserved.")
                                (cut + <> 1 (string-length "All rights reserved.")))
                         header-end)))
    (let* ((header-start (and=> (string-contains content "\n!#") (cut + <> 4)))
           (header-start (and header-start (< header-start 300) header-start))
           (header-start (or header-start (and (string-prefix? "#!" content)
                                               (and=> (string-contains content "\n")
                                                      (cut + <> 1)))))
           (body (substring content (or header-end header-start 0)))
           (body-space? (or (string-prefix? type body)
                            (string-prefix? "\n" body)))
           (header (if body-space? (string-trim-right header) header))
           (header (comment type header))
           (header (delete-trailing-whitespace header))
           (pre-header (if (not header-start) ""
                           (substring content 0 header-start)))
           (header-lines (string-split header #\newline))
           (header-identify (car header-lines))
           (header-identify (string-append header-identify "\n"))
           (header-rest (cdr header-lines))
           (header-rest (filter (negate (cute string-contains <> "Copyright")) header-rest))
           (header-rest (string-join header-rest "\n"))
           (copyright-lines (copyright-lines file-name))
           (copyright (string-join copyright-lines "\n"))
           (copyright (comment type copyright)))
      (with-output-to-file file-name
        (lambda _
          (display pre-header)
          (display header-identify)
          (display (comment type ""))
          (display copyright)
          (display header-rest)
          (display body)))
      (newline (current-error-port)))))

(define (skip? file-name)
  (or (symbolic-link? file-name)
      (member file-name '(".gitignore"
                          "ide/json.scm"
                          "build-aux/copyright-header.scm"
                          "build-aux/ltmain.sh"))
      (string-prefix? "doc/" file-name)
      (string-prefix? "dzn/peg" file-name)
      (string-prefix? "emacs/" file-name)
      (string-prefix? "test/language" file-name)
      ;; ide
      (string-prefix? "dzn/js/p5/" file-name)
      (string-prefix? "examples/" file-name)
      (and %ide? (string-prefix? "test/" file-name))
      (not (or (scm-file? file-name)
               (code-file? file-name)
               (script-file? file-name)))))

(define (main args)
  (setenv "GIT_COMMIT" "HEAD")
  (match (command-line)
      ((copyright-header)
       (let* ((files (string-split (gulp-pipe "git ls-tree -r --name-only $GIT_COMMIT") #\newline))
              (files (filter (negate skip?) files)))
         (for-each fix-header files)))
      ((copyright-header files ...)
       (for-each fix-header files))))
