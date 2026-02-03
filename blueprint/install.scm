;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2026 Janneke Nieuwenhuizen <janneke@gnu.org>
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

(define-module (blueprint install)
  #:use-module (blue build)
  #:use-module (blue states)
  #:use-module (blue types blueprint)
  #:use-module (blue types command)
  #:export (install-command))

(define-command (install-command _)
  ((invoke "install")
   (category 'install)
   (synopsis "Install the project")
   (help "
Install all buildables."))
  (install! (blueprint-buildables (current-blueprint)))
  (install!
   ;; (string-append #%?srcdir "/share/bash-completion/completions/blue")
   ;; (string-append #%?prefix "/share/bash-completion/completions")
   ))
