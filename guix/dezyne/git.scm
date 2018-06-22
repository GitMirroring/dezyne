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

(define-module (dezyne git)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 popen)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)

  #:use-module (guix gexp)              ; local-file

  #:use-module (guix build utils)
  #:use-module (guix git-download)
  #:use-module (guix packages)

  #:use-module (dezyne extra)
  #:use-module (dezyne services)
  #:use-module (dezyne pack))

#!

  ./pre-inst-env guix build -f guix.scm

  ./pre-inst-env guix build \
    --with-input=dezyne-services=dezyne-services@git \
    --with-input=dezyne-test-content=dezyne-test-content@git\
    dezyne-regression-test

!#

(define-public %source-dir (getcwd))

(define-public git-file?
  (let* ((pipe (with-directory-excursion %source-dir
                 (open-pipe* OPEN_READ "git" "ls-files")))
         (files (let loop ((lines '()))
                  (match (read-line pipe)
                    ((? eof-object?)
                     (reverse lines))
                    (line
                     (loop (cons line lines))))))
         (status (close-pipe pipe)))
    (lambda (file stat)
      (match (stat:type stat)
        ('directory #t)
        ((or 'regular 'symlink)
         (any (cut string-suffix? <> file) files))
        (_ #f)))))

(define dezyne-source.git
  (local-file %source-dir #:recursive? #t #:select? git-file?))

(define-public dezyne-services.git
  (let ((version "git")
        (commit (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ))))
    (package
     (inherit dezyne-services)
     (version (string-append version "." (string-take commit 7)))
     (source dezyne-source.git))))

(define-public dezyne-test-content.git
  (let ((version "git")
        (commit (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ))))
    (package
     (inherit dezyne-test-content)
     (version (string-append version "." (string-take commit 7)))
     (source dezyne-source.git))))

(define-public dezyne-regression-test.git
  (let ((version "git")
        (commit (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ))))
    (package
     (inherit dezyne-regression-test)
     (version (string-append version "." (string-take commit 7)))
     (native-inputs
      `(("dezyne-services" ,dezyne-services.git)
        ("dezyne-test-content" ,dezyne-test-content.git)
        ,@(filter
           (negate (car-member '("dezyne-services" "dezyne-test-content")))
           (package-native-inputs dezyne-regression-test)))))))
