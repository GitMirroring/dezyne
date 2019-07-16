;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)

  #:use-module (gaiag config)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gaiag shell-util)
  #:use-module (gash job)
  #:use-module (gash pipe)

  #:use-module (guix base32)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)

  #:use-module (dezyne extra)
  #:use-module (dezyne system os)

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
  '("master"))

(define-immutable-record-type <work-tree>
  (make-work-tree dir hash branch)
  work-tree?
  (dir work-tree-dir)
  (hash work-tree-hash)
  (branch work-tree-branch))

(define (string->work-tree s)
  (let ((split (filter (negate string-null?) (string-split s #\space))))
   (receive (dir hash branch)
       (apply values (list-head split 3))
     (make-work-tree dir hash branch))))

(define (git-work-trees)
  (let ((lines (string-split (string-trim-right (run-pipeline '("git" "worktree" "list"))) #\newline)))
    (map string->work-tree lines)))

(define (release-tree? o)
  (let ((release-dir (canonicalize-path (string-append (getcwd) "/../release/"))))
    (string-prefix? release-dir (work-tree-dir o))))

(define %hash-dir "/tmp/gdzn-hash")
(define (git-describe b)
  (gulp-pipe* "git" "describe" b))
(define (git-branch)
  (string-split (gulp-pipe* "git"  "branch" "--format=%(refname:short)") #\newline))

(define (guix-hash b)
  (with-output-to-file "/dev/null"
    (lambda _
      (system* "git" "worktree" "remove" "--force" %hash-dir)
      (system* "git" "worktree" "add" "--detach" %hash-dir b)))
  (with-directory-excursion %hash-dir
    (gulp-pipe* "guix" "hash" "-rx" ".")))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         ;;(work-trees (git-work-trees))
         ;;(release-trees (filter release-tree? work-trees))
         (missing-branches (filter (lambda (b) (not (member b (git-branch)))) branches))
         (branches (filter (lambda (b) (member b (git-branch))) branches))
         (branch-commit-alist (map (lambda (b) (cons b (git-describe b))) branches))
         (branch-hash-alist (map (lambda (b) (cons b (guix-hash b))) branches))
         (branch-origin-spec (map (lambda (b) (cons b (cons (assoc-ref branch-commit-alist b)
                                                            (assoc-ref branch-hash-alist b))))
                                  branches))
         (pack-alist (map (lambda (p) (cons (package-version p) p))
                          %dezyne-os-packages))
         (foo (when (gdzn:debugity) (stderr "pack-alist: ~s\n" pack-alist)))
         (services-packages
          (filter (lambda (e) (string-prefix? "dezyne-services" (car e)))
                  (append-map package-direct-inputs (map cdr pack-alist))))
         (foo (when (gdzn:debugity) (stderr "services-packages: ~s\n" services-packages)))
         (services-origins (map (lambda (p) (cons (car p) (package-source (cadr p)))) services-packages))
         (verbose? (gdzn:command-line:get 'verbose)))
    (define (check-origin spec)
      (let* ((branch (car spec))
             (describe (cadr spec))
             (commit (git-describe->commit describe))
             (hash (cddr spec))
             (key (if (equal? branch "development") "dezyne-services" ; FIXME
                      (string-append "dezyne-services-" branch)))
             (key (string-append "dezyne-services-" branch))
             (key "dezyne-services")
             (foo (when (gdzn:debugity) (stderr "key: ~s\n" key)))
             (origin (assoc-ref services-origins key))
             (package (and=> (assoc-ref services-packages key) car))
             (location (and package (package-location package)))
             (actual-commit (and origin (git-reference-commit (origin-uri origin))))
             (actual-hash (and origin (bytevector->nix-base32-string (origin-sha256 origin))))
             (happy? (and (equal? commit actual-commit)
                          (equal? hash actual-hash)))
             (dezyne-pack (assoc-ref pack-alist key))
             (pack-location (and dezyne-pack (package-location dezyne-pack))))
        (when (and happy? verbose?)
          (format (current-output-port) "~a:~a:info:~a: up to date: ~s ~s\n"
                  (and location (location-file location))
                  (and location (location-line location))
                  branch
                  describe
                  hash))
        (when (not happy?)
          (cond (package
                 (format (current-error-port) "~a:~a:error:package not up to date, expected:~a:~s ~s\n"
                         (and location (location-file location))
                         (and location (location-line location))
                         branch
                         describe
                         hash))
                (else (format (current-error-port) "~a:~a:error:no such package:~a:update pack\n"
                              (and pack-location (location-file pack-location))
                              (and pack-location (location-line pack-location))
                              branch))))
        happy?))
    (when (not (null? missing-branches)) (format (current-error-port) "error: missing branches: ~a\n" missing-branches))
    (when verbose?
      (for-each
       (match-lambda
         ((branch . pack)
          (let ((location (package-location pack)))
            (format (current-error-port) "~a:~a:info:checking pack with branches: ~a\n"
                    (and location (location-file location))
                    (and location (location-line location))
                    branch))))
       pack-alist))
    (stderr "releasing:\n")
    (pretty-print branch-commit-alist)
    (let ((happy? (and-map identity (map check-origin branch-origin-spec))))
      (when (not happy?) (exit 1))
      (let ((message (format #f "release: ~a\n\nguix version:~a\n"
                             (assoc-ref branch-commit-alist (car branches))
                             (@ (guix config) %guix-version))))
        (if (not (zero? (system* "git" "commit" "-m" message))) (exit 1)
            (format (current-error-port) "Now
make check-system
#git push origin release
git push public release
ssh guix@test1.oban
GUIX_PROFILE=$HOME/.config/guix/verum/etc/profile . $HOME/.config/guix/verum/etc/profile
cd src/development
git fetch
#git rebase origin/release
git branch -f development origin/development
./configure
make all-go-guix
#git daemon --base-path=$HOME/git-daemon --export-all &
sudo -E ./pre-inst-env guix system reconfigure guix/dezyne/system/test1.scm
"))))))
