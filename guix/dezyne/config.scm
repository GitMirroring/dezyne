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

(define-module (dezyne config))

#!

Build from local git

mkdir -p $HOME/git-daemon/buildmaster
ln -s $HOME/src/development $HOME/git-daemon/buildmaster/development.git
git daemon --base-path=$HOME/git-daemon --export-all &
git_oban=git://localhost GUIX_PACKAGE_PATH=guix guix build dezyne-services

!#

(define-public git.oban (or (getenv "git_oban") "http://git.oban.verum.com"))
(define-public git.oban/blessed (string-append (string-append git.oban "/buildmaster")))

(define-public git.oban/git git.oban/blessed)

(define-public git.oban/blessed/http (string-append (string-append git.oban "/~buildmaster")))
(define-public git.oban/http git.oban/blessed/http)
