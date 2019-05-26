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

(define-module (gnu packages lts)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-mingw))

(define git.oban
  (or (getenv "git_oban") "http://git.oban.verum.com/buildmaster"))
(define git.oban/http
  (or (getenv "git_oban_http") "http://git.oban.verum.com/~buildmaster"))

(define-public lts
  (let* ((commit "8a6bab5c729d0173105e900e239aed4aedd7f82e")
         (src-url (string-append git.oban "/lts.git"))
         (src-hash "1qjnhv7yf2x6slzy49pizpcbrqcrxlfbqzqfr4yssy3iv4j48lpr")
         (revision "0"))
    (package
      (name "lts")
      (version (string-append "0.3-" revision "." (string-take commit 7)))
      (source (origin
                (method git-fetch)
                (uri (git-reference (url src-url) (commit commit)))
                (sha256 (base32 src-hash))))
      (inputs `(("guile" ,guile-2.2)))
      (build-system gnu-build-system)
      (synopsis "Navigate and query lts in Aldebaran (aut) format")
      (description "Navigate and query lts in Aldebaran (aut) format")
      (home-page "http://www.verum.com")
      (license ((@@ (guix licenses) license)
                "proprietary"
                "http://verum.com"
                "internal")))))

(define-public lts-mingw
  (package
    (inherit lts)
    (name "lts-mingw")
    (inputs `(("guile" ,guile-mingw)))
    (native-inputs `(("guile-for-build" ,guile-2.2)))))
