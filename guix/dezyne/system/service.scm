;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Henk Katerberg <henk.katerberg@verum.com>
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
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)

  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages guile)

  #:use-module (gnu services shepherd)
  #:use-module (gnu services)

  #:use-module (gnu system shadow)

  #:use-module (guix build union)
  #:use-module (guix build utils)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix records)

  #:use-module (dezyne pack)
  #:use-module (dezyne extra)

  #:export (dezyne-service
            dezyne-configuration?
            dezyne-configuration-dezyne-server
            dezyne-configuration-dezyne-pack))

;;; Commentary:
;;;
;;; Dezyne service.
;;;
;;; Code:

(define-record-type* <dezyne-configuration>
  dezyne-configuration make-dezyne-configuration
  dezyne-configuration?
  (dezyne-server dezyne-configuration-dezyne-server)   ;<package>
  (dezyne-pack dezyne-configuration-dezyne-pack)       ;<package>
  (profile-inputs dezyne-configuration-profile-inputs) ;(<package>)
  (binary dezyne-configuration-binary)                 ;string
  (log-directory dezyne-configuration-log-directory)   ;string
  (run-directory dezyne-configuration-run-directory)   ;string
  (port dezyne-configuration-port)                     ;number
  (database dezyne-configuration-database)             ;string
  (debug? dezyne-configuration-debug?))                ;boolean

(define %user "dezyne")
(define %group "dezyne")

(define %dezyne-accounts
  (list (user-group (name %user) (system? #t))
        (user-account
         (name %user)
         (group %group)
         (system? #t)
         (comment "dezyne server user")
         (home-directory "/var/empty")
         (shell #~(string-append #$shadow "/sbin/nologin")))))

(define dezyne-activation
  (match-lambda
    (($ <dezyne-configuration> dezyne-server dezyne-pack profile-inputs log-directory run-directory port database debug?)
     #~(begin
         (use-modules (guix build utils))
         (let ((user (passwd:uid (getpwnam #$%user)))
               (group (group:gid (getgrnam #$%group))))
           (format #t "creating dezyne log directory '~a'~%" #$log-directory)
           (mkdir-p #$log-directory)
           (chown #$log-directory user group)
           (format #t "creating dezyne run directory '~a'~%" #$run-directory)
           (mkdir-p #$run-directory)
           (chown #$run-directory user group))))))

(define (build-dezyne-prefix name packages)
  "Return the union unix root for @var{packages}."
  (define build
    (with-imported-modules '((guix build union)
                             (guix build utils))
      #~(begin
          (use-modules (ice-9 match)
                       (guix build union)
                       (guix build utils))

          (match '#$packages
            (((names . directories) ...)
             (union-build #$output (apply append directories)))
            (((directories) ...)
             (union-build #$output (apply append directories)))
            ((directories ...)
             (union-build #$output directories))))))

  (computed-file name build))

(define (dezyne-shepherd-service)
  (match-lambda
    (($ <dezyne-configuration> dezyne-server dezyne-pack profile-inputs binary log-directory run-directory port database debug?)
     (let* ((dezyne-binary #~(string-append #$dezyne-server "/" #$binary))
            (options '())
            (options (if port (cons (string-append "--port=" (number->string port)) options)
                         options))
            (options (cons "--database=database" options))
            (options (if debug? (cons "--debug" options)
                         options))
            (dependencies (package-direct-inputs dezyne-server))
            (node-modules (map cadr (filter (lambda (p) (string-prefix? "node-" (car p))) dependencies)))
            (log-file (string-append log-directory "/dezyne.log"))
            (version (package-version dezyne-server))
            (union-content (append (map cadr dependencies) profile-inputs))
            (prefix (build-dezyne-prefix (string-append "dezyne-" version) union-content)))

       (list (shepherd-service
              (provision (list (string->symbol (string-append "dezyne-" version))))
              (documentation "Run the dezyne server.")
              (requirement '(user-processes loopback networking postgres))
              (modules '((srfi srfi-1)))
              (start #~(make-forkexec-constructor
                        (cons #$dezyne-binary '#$options)
                        #:environment-variables
                        (list
                         (string-append "PATH=" #$prefix "/bin"
                                        ":/run/current-system/profile/bin")
                         (string-append "GUILE_LOAD_PATH="
                                        (string-join
                                         (map (lambda (dir)
                                                (string-append dir "/share/guile/site/2.2"))
                                              (list '#$guile-2.2 '#$guile-json))
                                         ":"))
                         (string-append "GUILE_LOAD_COMPILED_PATH="
                                        (string-join
                                         (append-map
                                          (lambda (dir)
                                            (list (string-append dir "/share/guile/site/2.2")
                                                  (string-append dir "/lib/guile/2.2/site-ccache")))
                                          '("share/guile/site/2.2"
                                            "lib/guile/2.2/site-ccache"))
                                         ":"))
                         (string-append "NODE_PATH="
                                        (string-join
                                         (map (lambda (dir)
                                                (string-append dir "/lib/node_modules"))
                                              '#$node-modules)
                                         ":"))
                         (string-append "DEZYNE_PREFIX=" #$prefix)
                         "HTTP_ROOT=/run/current-system/profile/root")
                        #:user #$%user
                        #:group #$%group
                        #:log-file (string-append #$log-file)))
              (stop #~(make-kill-destructor))))))))

(define (dezyne-service-type dezyne-server)
  (service-type (name (string->symbol (string-append (package-name dezyne-server) "-" (package-version dezyne-server))))
                (extensions
                 (list (service-extension shepherd-root-service-type
                                          (dezyne-shepherd-service))
                       (service-extension activation-service-type
                                          dezyne-activation)
                       (service-extension account-service-type
                                          (const %dezyne-accounts))))))

(define* (dezyne-service #:key dezyne-server
                         dezyne-pack
                         (profile-inputs '())
                         (binary "bin/dzn-server")
                         (log-directory "/var/log/dezyne")
                         (run-directory "/var/run/dezyne")
                         port
                         database
                         debug?)
  "Return a service that runs DEZYNE, the dezyne server.

The dezyne server BINARY runs in RUN-DIRECTORY, writes logs to
LOG-DIRECTORY, listens to PORT and connects to DATABASE."
  (service (dezyne-service-type dezyne-server)
           (dezyne-configuration
            (dezyne-server dezyne-server)
            (dezyne-pack dezyne-pack)
            (profile-inputs profile-inputs)
            (binary binary)
            (log-directory log-directory)
            (run-directory run-directory)
            (port port)
            (database database)
            (debug? debug?))))
