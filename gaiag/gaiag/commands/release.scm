;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag commands release)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 getopt-long)

  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag config)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gash job)
  #:use-module (gash pipe)

  #:export (parse-opts
            main))

(define (run-pipeline . commands)
  (receive (job ports)
      (apply pipeline+ #f commands)
    (let ((output (read-string (car ports)))
          (error (read-string (cadr ports))))
      (handle-error job error)
      output)))

(define (parse-opts args)
  (let* ((option-spec
          '((help (single-char #\h))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: gdzn release [OPTION]... FILE
  -h, --help             display this help and exit
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
    options))

(define branches
  '(("master" . "b20d0604709a743a771ccf682bbb8efb43e576f1")
    ("2.8.0" . "3f9fac542492d9fb038bd5aec77c3e0559568ee7")))

(define-immutable-record-type <work-tree>
  (make-work-tree dir hash branch)
  work-tree?
  (dir work-tree-dir)
  (hash work-tree-hash)
  (branch work-tree-branch))

(define (string->work-tree s)
  (let ((split (filter (negate string-null?) (string-split s #\space))))
   (receive (dir hash branch)
       (apply values split)
     (make-work-tree dir hash branch))))

(define (git-work-trees)
  (let ((lines (string-split (string-trim-right (run-pipeline '("git" "worktree" "list"))) #\newline)))
    (map string->work-tree lines)))

(define (release-tree? o)
  (let ((release-dir (canonicalize-path (string-append (getcwd) "/../release/"))))
    (string-prefix? release-dir (work-tree-dir o))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (work-trees (git-work-trees))
         (release-trees (filter release-tree? work-trees)))
    ;;(system* "git" "worktree" "list")
    (stderr "work-trees:\n")
    (for-each (lambda (o) (stderr "~a\n" o)) release-trees)
    (stderr "releasing: ~a\n" (string-join (map car branches) ", "))))
