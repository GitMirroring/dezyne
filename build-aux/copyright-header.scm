#! /run/current-system/profile/bin/guile \
-e main -s
!#
;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2021, 2022, 2023 Janneke Nieuwenhuizen <janneke@gnu.org>
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
             (srfi srfi-71)
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

(define ide-header "Verum-Dezyne --- An IDE for Dezyne
Copyright © ~a ~a

This file is part of Verum-Dezyne.

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
  (let ((m (string-match "(.gitignore|configure.ac|pre-inst-env.in|test/bin/rename|\\.mk|\\.make|Makefile.*|\\.sh|/run)$" o)))
    (and=> m match:string)))

(define (code-file? o)
  (let ((m (string-match "\\.(cc|cs|dzn|h|hh|js)(|.in)$" o)))
    (and=> m match:string)))

(define (canonicalize-author author)
  (cond
   ((string-prefix? "Henk Katerberg" author)
    "Henk Katerberg <hank@mudball.nl>")
   ((or (string-prefix? "Janneke Nieuwenhuizen" author)
        (string-prefix? "Jan Nieuwenhuizen" author)
        (string-prefix? "Jan (janneke) Nieuwenhuizen" author)
        (string-prefix? "Jan Nieuwenhuien" author)
        (string-prefix? "Jan (janneke) Nieuwenhuien" author))
    "Janneke Nieuwenhuizen <janneke@gnu.org>")
   ((string-prefix? "Johri van Eerd" author)
    "Johri van Eerd <vaneerd.johri@gmail.com>")
   ((string-prefix? "Paul Hoogendijk" author)
    "Paul Hoogendijk <paul@dezyne.org>")
   ((string-prefix? "Rob Wieringa" author)
    "Rob Wieringa <rma.wieringa@gmail.com>")
   ((or (string-prefix? "Rutger van Beusekom" author)
        (string-prefix? "Rutger (regtur) van Beusekom" author))
    "Rutger (regtur) van Beusekom <rutger@dezyne.org>")
   (else
    author)))

(define (author-equal? a b)
  (equal? (canonicalize-author a) (canonicalize-author b)))

(define (author->name+email author)
  (let* ((m (string-match "(.*) <(.*)>" author))
         (name (and=> m (cute match:substring <> 1)))
         (email (and=> m (cute match:substring <> 2))))
    (values name email)))

(define (file-authors file-name)
  (let ((text (gulp-pipe
               (format #f
                       "\
grep -E 'Copyright © ([0-9, ]*[0-9]) ' ~a || echo"
                       file-name))))
    (string-split text #\newline)))

(define (file-author-copyright-line file-name author)
  (let ((name email (author->name+email author)))
    (gulp-pipe (format #f "grep -Ei '(~a|~a)' ~a || echo" name email
                       file-name))))

(define (file-author-copyright-years file-name author)
  (let* ((text (file-author-copyright-line file-name author))
         (years (string-match "© ([0-9, ]*[0-9]) +" text))
         (years (and=> years (cute match:substring <> 1)))
         (years (and=> years (cute string-split <> #\,)))
         (years (or (and years (map string-trim years)) '()))
         (years (delete-duplicates years)))
    (filter (negate string-null?) years)))

(define (git:author-copyright-years file-name author)
  (let* ((name email (author->name+email author))
         (text (gulp-pipe
                ;; Get all commit years, filter-out copyright updates
                (format #f
                        "\
git log --regexp-ignore-case --author='~a' --author='~a'    \\
  --pretty=format:'Commit:  %H%nAuthor:  %aN <%aE>%nDate:    %ad%nMessage: %s%n' '~a' \\
| recsel -i -e '!(Message ~~ \"copyright\")
             && !(Message ~~ \"indent.scm\")
             && !(Message ~~ \"dezyne.org\")
             && !(Message ~~ \"Verum-Dezyne\")
             && !(Message ~~ \"email\")' \\
| grep ^Date: \\
| sed -r 's,.*(20[0-9][0-9]).*,\\1,'"
                        name email file-name)))
         (lines (string-split text #\newline))
         (lines (sort lines string<))
         (years (delete-duplicates lines)))
    (filter (negate string-null?) years)))

(define (git:file-authors file-name)
  (let ((text (gulp-pipe
               ;; Get all commit years, filter-out copyright updates
               (format #f
                       "\
git log --regexp-ignore-case \\
  --pretty=format:'Commit:  %H%nAuthor:  %aN <%aE>%nDate:    %ad%nMessage: %s%n' '~a' \\
| recsel -i -e '!(Message ~~ \"copyright\") && !(Message ~~ \"dezyne.org\") && !(Message ~~ \"email\")' \\
| grep ^Author: \\
| sed 's/^Author: *//'"
                       file-name))))
    (string-split text #\newline)))

(define (git:commit-authors commit)
  (let ((text (gulp-pipe
               (format #f
                       "\
git show --pretty=format:'Author:  %aN <%aE>%n' --no-patch ~a \\
| grep -iE '^(Author|Co-authored-by):' \\
| sed -re 's,^(Author|Co-authored-by): *,,i'"
                       commit))))
    (string-split text #\newline)))

(define (git:files-in-commit commit)
  (let ((files (string-split
                (gulp-pipe (format #f "git ls-tree -r --name-only ~a" commit))
                #\newline)))
    (filter (negate skip?) files)))

(define* (author-copyright-line file-name author #:key update?)
  (let* ((git-years (if (not update?) '()
                        (git:author-copyright-years file-name author)))
         (file-years (file-author-copyright-years file-name author))
         (years (append git-years file-years))
         (years (sort years string<))
         (years (delete-duplicates years))
         (years (string-join years ", "))
         (author (if (not update?) author
                     (canonicalize-author author))))
    (format #f "Copyright © ~a ~a" years author)))

(define (filter-author line)
  (let ((m (string-match "© ([0-9, ]*[0-9]) +(.*>)" line)))
    (and m (match:substring m 2))))

(define* (copyright-lines file-name #:key commit hysterical?)
  (let* ((file-authors (file-authors file-name))
         (file-authors (filter-map filter-author file-authors))
         (git-authors (if hysterical? (git:file-authors file-name)
                          (git:commit-authors commit)))
         (authors (append file-authors git-authors))
         (authors (delete-duplicates authors author-equal?))
         (update? (if hysterical? authors
                      (map (cute member <> git-authors author-equal?) authors))))
    (append (map (cute author-copyright-line file-name <> #:update? <>)
                 authors
                 update?))))

(define* (fix-header file-name #:key commit dry-run? hysterical?)
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
           (copyright-lines (copyright-lines file-name #:commit commit
                                             #:hysterical? hysterical?))
           (copyright (string-join copyright-lines "\n"))
           (copyright (comment type copyright)))
      (newline (current-error-port))
      (if dry-run? (display copyright)
          (with-output-to-file file-name
            (lambda _
              (display pre-header)
              (display header-identify)
              (display (comment type ""))
              (display copyright)
              (display header-rest)
              (display body)))))))

(define (skip? file-name)
  (or (symbolic-link? file-name)
      (member file-name '("ide/json.scm"
                          "build-aux/copyright-header.scm"
                          "build-aux/ltmain.sh"))
      (string-prefix? "doc/" file-name)
      (string-prefix? "dzn/peg" file-name)
      (string-prefix? "test/language" file-name)
      ;; ide
      (string-prefix? "dzn/js/p5/" file-name)
      (string-prefix? "examples/" file-name)
      (and %ide? (string-prefix? "test/" file-name))
      (not (or (scm-file? file-name)
               (code-file? file-name)
               (script-file? file-name)))))

(define (main args)
  (let ((commit "HEAD"))
    (setenv "GIT_COMMIT" "HEAD")
    (match (command-line)
      ((copyright-header)
       (let ((files (filter (negate skip?) files)))
         (for-each fix-header files)))
      ((copyright-header files ...)
       (let* ((dry-run? (member "--dry-run" files))
              (hysterical? (member "--hysterical" files))
              (files (filter (negate (cute string-prefix? "--" <>)) files))
              (files (if (pair? files) files
                         (git:files-in-commit commit)))
              (files (filter (negate skip?) files)))
         (for-each (cute fix-header <>
                         #:commit commit
                         #:dry-run? dry-run?
                         #:hysterical? hysterical?)
                   files))))))
