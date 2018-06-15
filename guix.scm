;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
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

;;; guix.scm -- Guix package definition

;;; Borrowing code from:
;;; guile-sdl2 --- FFI bindings for SDL2
;;; Copyright © 2015 David Thompson <davet@gnu.org>

;;; Commentary:
;;
;; GNU Guix development package.  To build and install, run:
;;
;;   guix package -f guix.scm
;;
;; To build it, but not install it, run:
;;
;;   guix build -f guix.scm
;;
;; To use as the basis for a development environment, run:
;;
;;   guix environment -l guix.scm
;;
;;; Code:

(use-modules (srfi srfi-1)
             (srfi srfi-26)
             (ice-9 match)
             (ice-9 popen)
             (ice-9 rdelim)
             (gnu packages)
             (gnu packages base)
             (gnu packages ccache)
             (gnu packages commencement)
             (gnu packages dezyne)
             (gnu packages databases)
             (gnu packages gcc)
             (gnu packages guile)
             (gnu packages package-management)
             (gnu packages version-control)
             ((guix build utils) #:select (with-directory-excursion))
             (guix build-system gnu)
             (guix build-system trivial)
             (guix gexp)
             (guix git-download)
             ((guix licenses) #:prefix license:)
             (guix packages))

(define %source-dir (dirname (current-filename)))

(define git-file?
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

(define-public dezyne-services.git
  (let ((version "development")
        (revision "0")
        (commit (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ))))
    (package
      (inherit dezyne-services)
      (version (string-append version "-" revision "." (string-take commit 7)))
      (source (local-file %source-dir #:recursive? #t #:select? git-file?))
      (native-inputs `(("dezyne-services" ,dezyne-services)
                       ("ccache" ,ccache)
                       ("git" ,git)
                       ("mcrl2" ,mcrl2-svn)
                       ("postgresql" ,postgresql)
                       ,@(package-native-inputs dezyne-services))))))

;; Return it here so `guix build/environment/package' can consume it directly.
dezyne-services.git
