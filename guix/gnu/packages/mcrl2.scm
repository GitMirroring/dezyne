;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019,2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gnu packages mcrl2)
  #:use-module (gnu packages)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages maths)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public mcrl2-pipeline
  (let ((commit "863ff222638f1bc9a716c8ee1c0a9621fa47a16b")
        (version "201908.0")
        (revision "1"))
  (package
    (inherit mcrl2)
    (version (git-version version revision commit))
    (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/mCRL2org/mCRL2")
                      (commit commit)))
                (sha256
                 (base32
                  "0glrz197xx8mlaw2hj6c87bkpl6fqs3zfcciik3ar0wphcjlblwx"))))
    (name "mcrl2-pipeline"))))

(define-public mcrl2-pipeline-minimal
  (package
    (inherit mcrl2-minimal)
    (name "mcrl2-pipeline-minimal")
    (version (package-version mcrl2-pipeline))
    (source (package-source mcrl2-pipeline))))
