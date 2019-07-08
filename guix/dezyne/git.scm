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

(define-module (dezyne git)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)

  #:use-module (guix gexp)              ; local-file

  #:use-module (guix build utils)
  #:use-module (guix git-download)
  #:use-module (guix packages)

  #:use-module (dezyne extra)
  #:use-module (dezyne services)
  #:use-module (dezyne server)
  #:use-module (dezyne pack))

(define (current-filename)
  (search-path %load-path (module-filename (current-module))))

(define %source-dir (dirname (dirname (dirname (current-filename)))))

(format (current-error-port) "source-dir:~s\n" %source-dir)

(define (git-commit)
  (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ)))

(define dezyne-source.git
  (local-file %source-dir
              #:recursive? #t
              #:select? (git-predicate %source-dir)))

(define-public dezyne-services.git
  (package
   (inherit dezyne-services)
   (version (string-append "git." (string-take (git-commit) 7)))
   (source dezyne-source.git)))

(define-public dezyne-server.git
  (package
   (inherit dezyne-server)
   (version (string-append "git." (string-take (git-commit) 7)))
   (source dezyne-source.git)
   (native-inputs
    `(("dezyne-services" ,dezyne-services.git)
      ,@(filter
         (negate (car-member '("dezyne-services")))
         (package-native-inputs dezyne-server))))))

(define-public dezyne-test-content.git
  (package
   (inherit dezyne-test-content)
   (version (string-append "git." (string-take (git-commit) 7)))
   (source dezyne-source.git)))

(define-public dezyne-regression-test.git
  (package
   (inherit dezyne-regression-test)
   (version (string-append "git." (string-take (git-commit) 7)))
   (native-inputs
    `(("dezyne-services" ,dezyne-services.git)
      ("dezyne-test-content" ,dezyne-test-content.git)
      ,@(filter
         (negate (car-member '("dezyne-services" "dezyne-test-content")))
         (package-native-inputs dezyne-regression-test))))))

(define-public dezyne-pack.git
  (package
   (inherit dezyne-pack)
   (version (string-append "git." (string-take (git-commit) 7)))
   (propagated-inputs
    `(("dezyne-server" ,dezyne-server.git)
      ("dezyne-services" ,dezyne-services.git)
      ("dezyne-regression-test" ,dezyne-regression-test.git)
      ;;("dezyne-test-content" ,dezyne-test-content.git)
      ;;("dzn-client-tarball" ,dzn-client-tarball.git)
      ,@(filter
         (negate (car-member '("dezyne-regression-test"
                               "dezyne-server"
                               "dezyne-services"
                               "dezyne-test-content"
                               "dzn-client-tarball")))
         (package-propagated-inputs dezyne-pack))))))
