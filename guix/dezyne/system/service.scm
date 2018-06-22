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

(define-module (dezyne system service)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (gnu packages admin)
  #:use-module (guix records)
  #:use-module (guix gexp)
  #:use-module (ice-9 match)

  #:use-module (gnu system shadow)
  #:use-module (guix packages)
  #:use-module (gnu packages guile)

  #:use-module (dezyne server)
  #:use-module (dezyne pack)

  #:export (dezyne-service))

;;; Commentary:
;;;
;;; Dezyne service.
;;;
;;; Code:

(define-record-type* <dezyne-configuration>
  dezyne-configuration make-dezyne-configuration
  dezyne-configuration?
  (dezyne-server dezyne-configuration-dezyne-server)  ;<package>
  (log-directory dezyne-configuration-log-directory)  ;string
  (run-directory dezyne-configuration-run-directory)) ;string

(define %dezyne-accounts
  (list (user-group (name "dezyne") (system? #t))
        (user-account
         (name "dezyne")
         (group "dezyne")
         (system? #t)
         (comment "dezyne server user")
         (home-directory "/var/empty")
         (shell #~(string-append #$shadow "/sbin/nologin")))))

(define dezyne-activation
  (match-lambda
    (($ <dezyne-configuration> dezyne-server log-directory run-directory)
     #~(begin
         (use-modules (guix build utils))

         (format #t "creating dezyne log directory '~a'~%" #$log-directory)
         (mkdir-p #$log-directory)
         (format #t "creating dezyne run directory '~a'~%" #$run-directory)
         (mkdir-p #$run-directory)))))

(define dezyne-shepherd-service
  (match-lambda
    (($ <dezyne-configuration> dezyne-server log-directory run-directory)
     (let* ((dezyne-binary #~(string-append #$dezyne-server "/server/main.js"))
            (packages (package-direct-inputs dezyne-server))
            (node-modules (map cadr (filter (lambda (p) (string-prefix? "node-" (car p))) packages)))
            (dezyne-action
             (lambda args
               #~(lambda _
                   (set-path-environment-variable "GUILE_LOAD_PATH" '("share/guile/site/2.2")
                                                  (list '#$guile-2.2 '#$guile-json))
                   (set-path-environment-variable "GUILE_LOAD_COMPILED_PATH"
                                                  '("share/guile/site/2.2"
                                                    "lib/guile/2.2/site-ccache")
                                                  (list '#$guile-2.2 '#$guile-json))
                   (set-path-environment-variable "NODE_PATH"
                                                  '("lib/node_modules")
                                                  '#$node-modules)
                   (setenv "DEZYNE_PREFIX"
                           (if (file-exists? "/run/current-system/profile")
                               "/run/current-system/profile"
                               #$dezyne-server))
                   (zero?
                    (system* #$dezyne-binary "--config=localhost"))))))

       ;; TODO: Add 'reload' action.
       (list (shepherd-service
              (provision '(dezyne))
              (documentation "Run the dezyne daemon.")
              (requirement '(user-processes loopback))
              (start (dezyne-action))
              (stop (dezyne-action "--stop" "stop"))
              (stop (dezyne-action "--reload" "reload"))))))))

(define dezyne-service-type
  (service-type (name 'dezyne)
                (extensions
                 (list (service-extension shepherd-root-service-type
                                          dezyne-shepherd-service)
                       (service-extension activation-service-type
                                          dezyne-activation)
                       (service-extension account-service-type
                                          (const %dezyne-accounts))))))

(define* (dezyne-service #:key (dezyne-server dezyne-server)
                         (log-directory "/var/log/dezyne")
                         (run-directory "/var/run/dezyne")
                         (config 'localhost))
  "Return a service that runs DEZYNE, the dezyne server.

The dezyne daemon loads its runtime configuration from CONFIG-FILE, stores log
files in LOG-DIRECTORY, and stores temporary runtime files in RUN-DIRECTORY."
  (service dezyne-service-type
           (dezyne-configuration
            (dezyne-server dezyne-server)
            (log-directory log-directory)
            (run-directory run-directory))))
