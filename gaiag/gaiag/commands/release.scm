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

  #:use-module (gnu services)
  #:use-module (guix base32)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)

  #:use-module (dezyne system service)
  #:use-module (dezyne system os)

  #:use-module (dezyne extra)
  #:use-module (dezyne pack)
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

(define configurations
  '("development"))

(define (branch config)
  (let* ((version (string-split config #\.))
         (version (if (= 3 (length version)) (drop-right version 1) version)))
    (string-join version ".")))

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
(define (git-clean? b)
  (with-output-to-file "/dev/null"
    (lambda _
      (and (zero? (system* "git" "diff" "--exit-code" b))
           (zero? (system* "git" "diff" "--cached" "--exit-code" b))))))
(define (git-message b)
  (let ((msg (gulp-pipe* "git" "show" "--no-patch" "--format=%s" b)))
    (and (string? msg)
         (car (string-split msg #\newline)))))
(define (git-message->spec b)
  (let ((msg (git-message b)))
    (and msg
         (let ((lst (string-split msg #\space)))
           (and (= (length lst) 3)
                (string=? (car lst) "release:")
                (= (string-length (caddr lst)) 52)
                (cdr lst))))))
(define (git-commit-describe b)
  (and (git-clean? b)
       (and=> (git-message->spec b) car)))
(define (git-commit-hash b)
  (and (git-clean? b)
       (and=> (git-message->spec b) cadr)))
(define (git-describe b)
  (or (git-commit-describe b)
      (gulp-pipe* "git" "describe" b)))
(define (git-branch)
  (string-split (gulp-pipe* "git"  "branch" "--format=%(refname:short)") #\newline))

(define (guix-hash b)
  (or (git-commit-hash b)
      (begin
        (with-output-to-file "/dev/null"
          (lambda _
            (system* "git" "worktree" "remove" "--force" %hash-dir)
            (system* "git" "worktree" "add" "--detach" %hash-dir b)))
        (with-directory-excursion %hash-dir
                                  (gulp-pipe* "guix" "hash" "-rx" ".")))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (branches (map branch configurations))
         (missing-branches (filter (lambda (b) (not (member b (git-branch)))) branches))
         (branches (filter (lambda (b) (member b (git-branch))) branches))
         (branch-commit-alist (map (lambda (b) (cons b (git-describe b))) branches))
         (foo (when (> (gdzn:debugity) 1) (stderr "branch-commit-alist: ~s\n" branch-commit-alist)))
         (branch-hash-alist (map (lambda (b) (cons b (guix-hash b))) branches))
         (foo (when (> (gdzn:debugity) 1) (stderr "branch-hash-alist: ~s\n" branch-hash-alist)))
         (branch-origin-spec (map (lambda (c)
                                    (let ((b (branch c)))
                                      (cons c (cons (assoc-ref branch-commit-alist b)
                                                    (assoc-ref branch-hash-alist b)))))
                                  configurations))
         (pack-alist (map (lambda (p) (cons (package-version p) p))
                          %dezyne-os-packages))

         (services (filter (compose (cut symbol-prefix? 'dezyne <>) service-type-name service-kind) %dezyne-os-services))
         (foo (when (> (gdzn:debugity) 1) (stderr "services: ~s\n" services)))
         (packs (map (compose dezyne-configuration-dezyne-pack service-value) services))

         (pack-alist (map (lambda (p) (cons (package-version p) p)) packs))
         (foo (when (> (gdzn:debugity) 1) (stderr "pack-alist: ~s\n" pack-alist)))
         (services-packages
          (map cadr (filter (compose (cut string-prefix? "dezyne-services" <>) car)
                            (append-map package-direct-inputs (map cdr pack-alist)))))
         (foo (when (> (gdzn:debugity) 1) (stderr "services-packages: ~s\n" services-packages)))
         (services-origins (map package-source services-packages))
         (verbose? (gdzn:command-line:get 'verbose)))
    (define (check-origin spec)
      (let* ((config (car spec))
             (foo (when (gdzn:debugity) (stderr "config: ~s\n" config)))
             (describe (cadr spec))
             (commit (git-describe->commit describe))
             (hash (cddr spec))
             (version config)
             (name (if (equal? version "2.8") "dezyne-services-2.8.2"
                       "dezyne-services"))
             (package (find (conjoin (compose (cut equal? name <>) package-name)
                                     (compose (cut equal? version <>) package-version)) services-packages))
             (origin (and package (package-source package)))
             (location (and package (package-location package)))
             (package-commit (and origin (git-reference-commit (origin-uri origin))))
             (package-hash (and origin (bytevector->nix-base32-string (origin-sha256 origin))))
             (happy? (and (equal? commit package-commit)
                          (equal? hash package-hash)))
             (dezyne-pack (assoc-ref pack-alist version))
             (pack-location (and dezyne-pack (package-location dezyne-pack))))
        (when (and happy? verbose?)
          (format (current-output-port) "~a:~a:info:~a: up to date: ~s ~s\n"
                  (and location (location-file location))
                  (and location (location-line location))
                  config
                  describe
                  hash))
        (when (not happy?)
          (cond (package
                 (format (current-error-port) "~a:~a:error:package not up to date, expected:~a:~s ~s\n"
                         (and location (location-file location))
                         (and location (location-line location))
                         config
                         describe
                         hash))
                (else (format (current-error-port) "~a:~a:error:no such package:~a:update pack\n"
                              (and pack-location (location-file pack-location))
                              (and pack-location (location-line pack-location))
                              config))))
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
      (let ((message (format #f "release: ~a ~a\n\nguix version:~a\n"
                             (assoc-ref branch-commit-alist (car branches))
                             (assoc-ref branch-hash-alist (car branches))
                             (@ (guix config) %guix-version))))
        (if (and (not (git-clean? (car configurations)))
                 (not (zero? (system* "git" "commit" "-m" message)))) (exit 1)
            (format (current-error-port) "Now do something like:
git push blessed ~a
cd ../release
./configure
make
./pre-inst-env deploy-test1
" (car configurations)))))))
