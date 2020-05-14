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
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public mcrl2-pipeline
  (package
    (inherit mcrl2)
    (version "201908.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://www.mcrl2.org/download/release/mcrl2-"
                    version ".tar.gz"))
              (patches (search-patches "mcrl2-lps2lts-stdout.patch"
                                       "mcrl2-ltscompare-multiple-lts.patch"
                                       "mcrl2-ltscompare-structured-output.patch"))
              (sha256
               (base32
                "1i4xgl2d5fgiz1mwi50cyfkrrcpm8nxfayfjgmhq7chs58wlhfsz"))))
    (name "mcrl2-pipeline")))

(define-public mcrl2-minimal
  (package
    (inherit mcrl2)
    (name "mcrl2-minimal")
    (inputs
     `(("boost" ,boost)))
    (arguments
     '(#:configure-flags '("-DMCRL2_ENABLE_GUI_TOOLS=OFF")))))

(define-public mcrl2-pipeline-minimal
  (package
    (inherit mcrl2-minimal)
    (name "mcrl2-pipeline-minimal")
    (version (package-version mcrl2-pipeline))
    (source (package-source mcrl2-pipeline))))
