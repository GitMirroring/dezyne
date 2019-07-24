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

(define-module (dezyne config))

#!

Build from public git

    git_oban=http://git.oban.verum.com/jannieuwenhuizen GUIX_PACKAGE_PATH=guix guix build dezyne-services

Build from local git

    mkdir -p $HOME/git-daemon
    ln -s $HOME/src/development $HOME/git-daemon/development.git
    git daemon --base-path=$HOME/git-daemon --export-all &
    git_oban=git://localhost GUIX_PACKAGE_PATH=guix guix build dezyne-services

!#

(define-public git.oban (or (getenv "git_oban") "http://git.oban.verum.com/buildmaster"))
(define-public git.oban/http (or (getenv "git_oban_http") "http://git.oban.verum.com/~buildmaster"))
