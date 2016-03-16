;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

;; guix.scm for Dezyne
;;
;; To setup the guix-0.9.0 package manager on Ubuntu, run
;;
;;   wget http://192.168.32.138/guix_0.9.0-2_amd64.deb
;;   wget http://192.168.32.138/guile-json_0.5.0-1_all.deb
;;   sudo dpkg -i guix_0.9.0-2_amd64.deb guile-json_0.5.0-1_all.deb
;;   sudo guix archive --authorize < /usr/share/guix/hydra.gnu.org.pub
;;
;; To build and install, run
;;
;;   guix package -f guix.scm
;;
;; To setup a Dezyne build environment, run
;;
;;   guix environment -f guix.scm --ad-hoc ccache git
;;
;; To build and run a vm with multiple services, run
;;
;;   make guix-vm
;;   make run-guix-vm

(set! %load-path (cons "release" %load-path))
(use-modules (dezyne))
dezyne-server
