;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Henk Katerberg <henk.katerberg@verum.com>
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

(define-module (dezyne system os)
  #:use-module (gnu)
  #:use-module (gnu services base)
  #:use-module (gnu services databases)
  #:use-module (gnu services networking)
  #:use-module (gnu services ssh)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages certs)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages ssh)
  #:use-module (guix config)

  #:use-module (dezyne pack)
  #:use-module (dezyne system service)
  #:use-module (dezyne server)

  #:export (dezyne-os))

(define dezyne-os
  (operating-system
    (host-name "development.verum.com")
    (timezone "Europe/Amsterdam")
    (locale "en_US.UTF-8")

    (bootloader
     (grub-configuration
      (target "/dev/sda")))

    (initrd-modules (append (list "vmw_pvscsi" "shpchp")
                            %base-initrd-modules))
    (file-systems
     (cons* (file-system
              (device (file-system-label "guix"))
              (mount-point "/")
              (type "ext4"))
            %base-file-systems))

    (swap-devices '("/dev/sda2"))

    (groups
     (cons* (user-group (name "guix"))
            %base-groups))

    (users
     (cons* (user-account (name "guix")
                          (group "guix")
                          (password (crypt "" "xx"))
                          (supplementary-groups '("wheel"))
                          (home-directory "/home/guix"))
            %base-user-accounts))

    (packages
     (cons* dezyne-pack
            openssh
            %base-packages))

    (services
     (cons* (service dhcp-client-service-type)
            (service openssh-service-type
                     (openssh-configuration
                      (port-number 22)
                      (permit-root-login #t)
                      (allow-empty-passwords? #t)
                      (password-authentication? #t)))

            (postgresql-service)
            (dezyne-service #:dezyne-server dezyne-server #:config 'localhost)
            %base-services))))


;; Return it here so 'guix system' can consume it directly.
dezyne-os
