;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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
  #:use-module (gnu services web)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages certs)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages wget)
  #:use-module (guix config)

  #:use-module (dezyne pack)
  #:use-module (dezyne server)
  #:use-module (dezyne services)
  #:use-module (dezyne system service)

  #:export (%dezyne-os
            %dezyne-os-packages
            %dezyne-os-services))

(define %dezyne-os-packages
  (list
   (specification->package "postgresql@9.6")
   dezyne-pack))

(define %dezyne-os-services
  (list
   (postgresql-service #:postgresql postgresql-9.6)
   (dezyne-service #:dezyne-server dezyne-server #:dezyne-pack dezyne-pack #:log-directory "/var/log/dezyne" #:port 3000)

   (service
    nginx-service-type
    (nginx-configuration
     (server-blocks
      (list (nginx-server-configuration
             (server-name '("localhost"))
             (root "/run/current-system/profile/root")
             (ssl-certificate "/run/current-system/profile/server/ssl/5fd35a5805c0ab62.crt")
             (ssl-certificate-key "/run/current-system/profile/server/ssl/privateKey.key")
             (locations
              (list
               (nginx-location-configuration
                (uri "/NEWS")
                (body '("proxy_pass http://development/NEWS;")))
               (nginx-location-configuration
                (uri "/service/development/socket.io")
                (body '("proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection \"upgrade\";
proxy_http_version 1.1;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header Host $host;
proxy_pass http://development/socket.io;")))
               (nginx-location-configuration
                (uri "/service/development")
                (body '("proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection \"upgrade\";
proxy_http_version 1.1;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header Host $host;
proxy_pass http://development;")))
               (nginx-location-configuration
                (uri "/")
                (body '("proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection \"upgrade\";
proxy_http_version 1.1;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header Host $host;
proxy_pass http://development;"))))))))
     (upstream-blocks
      (list (nginx-upstream-configuration
             (name "development")
             (servers (list "localhost:3000")))))))))

(define %dezyne-os
  (operating-system
   (host-name "hosting.verum.com")
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
    (cons* openssh
           wget
           (append %dezyne-os-packages
                   %base-packages)))

   (services
    (cons* (service dhcp-client-service-type)
           (service openssh-service-type
                    (openssh-configuration
                     (port-number 22)
                     (permit-root-login #t)
                     (allow-empty-passwords? #t)
                     (password-authentication? #t)))

           (append %dezyne-os-services
                   %base-services)))))

;; Return it here so 'guix system' can consume it directly.
%dezyne-os
