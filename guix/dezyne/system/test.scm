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

(define-module (dezyne system test)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 rdelim)

  #:use-module (srfi srfi-26)

  #:use-module (guix gexp)
  #:use-module (guix monads)
  #:use-module (guix packages)
  #:use-module (guix store)

  #:use-module (gnu tests)
  #:use-module (gnu system)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system shadow)
  #:use-module (gnu system vm)

  #:use-module (gnu packages bash)
  #:use-module (gnu packages wget)

  #:use-module (gnu services herd)
  #:use-module (gnu services networking)
  #:use-module (gnu services ssh)

  #:use-module (dezyne extra)
  #:use-module (dezyne system service)
  #:use-module (dezyne system os)

  #:use-module (dezyne pack)
  #:use-module (guix config)

  #:export (%test-dezyne))

(define %test-os
  (operating-system
   (inherit %dezyne-os)
   (host-name "test.verum.com")
   (hosts-file
    (plain-file "hosts"
                (string-append (local-host-aliases host-name)
                               "
127.0.0.1	database
")))))

(define* (run-dezyne-test #:key (http-port 3000) check?)
  "Run tests in %TEST-OS, which has dezyne running and listening on
HTTP-PORT."
  (let* ((test-content dezyne-test-content)
         (version (package-version dezyne-services))
         (dezyne-test-packages (map cadr (package-direct-inputs dezyne-regression-test)))
         (node-packages (map cadr (filter (lambda (p) (string-prefix? "node-" (car p))) (package-direct-inputs dezyne-server)))))

    (mlet* %store-monad ((os ->   (marionette-operating-system
                                   %test-os
                                   #:imported-modules '((gnu services herd)
                                                        (guix combinators))))
                         (command (apply system-qemu-image/shared-store-script
                                         (list os #:graphic? #f #:memory-size 4096))))

      (define test
        (with-imported-modules '((guix build utils)
                                 (gnu build marionette))
          #~(begin
              (use-modules (srfi srfi-1) (srfi srfi-11) (srfi srfi-26) (srfi srfi-64)
                           (ice-9 curried-definitions)
                           (ice-9 popen)
                           (ice-9 regex)
                           (ice-9 rdelim)
                           (guix build utils)
                           (gnu build marionette)
                           (web uri)
                           (web client)
                           (web response))

              (define out (string-append #$output "/regression/" #$version))

              (define marionette
                ;; Forward the guest's HTTP-PORT, where dezyne is listening, to
                ;; port 3001 in the homest.
                (make-marionette (list #$command "-net"
                                       (string-append
                                        "user,hostfwd=tcp::3001-:"
                                        #$(number->string http-port)))))

              (define ((bin/test dir) version test-content)
                (let* ((dzn-version (if (equal? version "development") ""
                                        (string-append "DZN_VERSION=" version)))
                       (cmd (format #f "set -o pipefail;~a ~a/test/bin/test ~a/test/~a |& tee hello.log" dzn-version test-content test-content dir))
                       (dir (string-append "../" version)))
                  (mkdir-p dir)
                  (chdir dir)
                  (zero? (system cmd))))

              (define services-alist
                `(;;("development" . ,#$dezyne-test-content)

                  ("2.9.1" . ,#$dezyne-test-content)

                  ))

              (define query-output
                (string-append
                               (string-join (filter (negate (cut equal? <> "development"))
                                                    (map car (reverse services-alist)))
                                            "\n  " 'prefix)
                               ;;"\n* development\n"
                               "\n* 2.9\n"
                               ))

              (mkdir-p out)
              (chdir out)

              (setenv "HOME" out)       ; make ticket part of report

              (define npm-prefix "/tmp/.npm")
              (define node-modules-dir (string-append npm-prefix "/lib/node_modules"))

              (define dzn (string-append #$output "/bin/dzn"))
              (mkdir-p (dirname dzn))
              ;; create dzn wrapper to select --version
              (with-output-to-file dzn
                (lambda _
                  (display (string-append "#! " #$bash "/bin/bash\n"
                                          #$node6 "/bin/node" " " npm-prefix "/bin/dzn"
                                          " \"$@\" ${DZN_VERSION+--version=$DZN_VERSION}"
                                          "\n"))))
              (chmod dzn #o755)
              (setenv "DZN" dzn)        ; tell aspects.js to use this wrapper

              ;; create npm wrapper no set --prefix --cache --user=guix --no-registry
              (define npm (string-append #$output "/bin/npm"))
              (with-output-to-file npm
                (lambda _
                  (display (string-append "#! " #$bash "/bin/bash\n"
                                          "set -x\n"
                                          "command=$1\n"
                                          "shift\n"
                                          #$node6 "/bin/node" " " npm-prefix "/bin/npm"
                                          " --verbose $command "
                                          " --prefix=" npm-prefix
                                          " --cache=" npm-prefix
                                          " --user=guix --no-registry"
                                          " \"$@\" "
                                          "\n"
                                          ;;"cp -a --no-preserve=mode " #$node-snapshot " " npm-prefix "\n"
                                          "\n"))))
              (chmod npm #o755)

              (set-path-environment-variable "PATH" '("bin" "sbin")
                                             (cons* #$output
                                                    #$wget
                                                    (append '#$dezyne-test-packages
                                                            '#$%base-packages)))

              (set-path-environment-variable "CPLUS_INCLUDE_PATH" '("include")
                                             '#$dezyne-test-packages)

              (set-path-environment-variable "LIBRARY_PATH" '("lib")
                                             '#$dezyne-test-packages)

              (set-path-environment-variable "NODE_PATH" '("lib/node_modules")
                                             '#$node-packages)

              (test-begin "dezyne")

              (marionette-eval '(mkdir-p "/var/log/dezyne") marionette)

              ;; Wait for postgres to be up and running.
              (test-eq "postgres running"
                'running!
                (marionette-eval
                 '(begin
                    (use-modules (guix build utils)
                                 (gnu services herd))
                    (start-service 'postgres)
                    'running!)
                 marionette))

              (test-assert "setup"
                (marionette-eval
                 '(begin
                    (system* "createuser" "--superuser" "root" "-U" "postgres")
                    (system (string-append #$dezyne-server "/database/db-setup.sh")))
                 marionette))

              ;; Wait for dezyne to be up and running.
              (test-eq "service running"
                'running!
                (marionette-eval
                 '(begin
                    (use-modules (guix build utils)
                                 (gnu services herd))
                    (start-service 'dezyne)
                    'running!)
                 marionette))

              ;; There should be a parent log file in here.
              (test-assert "parent log file"
                (marionette-eval
                 '(file-exists? "/var/log/dezyne.parent.log")
                 marionette))

              (test-assert "display parent log"
                (marionette-eval
                 '(begin
                    (use-modules (ice-9 rdelim))
                    (display
                     (with-input-from-file "/var/log/dezyne.parent.log" read-string)
                     (current-error-port)))
                 marionette))

              (test-assert "child log file"
                (marionette-eval
                 '(file-exists? "/var/log/dezyne/child.log")
                 marionette))

              (test-assert "display child log"
                (marionette-eval
                 '(begin
                    (use-modules (ice-9 rdelim))
                    (display
                     (with-input-from-file "/var/log/dezyne/child.log" read-string)
                     (current-error-port)))
                 marionette))

              ;; wait for server to get up
              (test-assert "express"
                (zero? (system* "wget" "http://localhost:3001")))

              (test-assert "wget dzn dev"
                (zero? (system* "wget" (string-append "http://localhost:3001"
                                                      "/download/npm/dzn-development.tar.gz"))))

              ;; (test-assert "wget dzn 2.9.1"
              ;;   (zero? (system* "wget" (string-append "http://localhost:3001"
              ;;                                         "/download/npm/dzn-2.9.1.tar.gz"))))

              (test-assert "install dzn"
                (let ((cmd (string-append "set -x; " npm " install --global"
                                          " http://localhost:3001"
                                          "/download/npm/dzn-development.tar.gz")))
                  ;; create writable cache for npm from snapshot
                  (system* "cp" "-a" "--no-preserve=mode" #$node-snapshot npm-prefix)
                  (zero? (system cmd))))

              (test-assert "hello authenticate"
                (let ((cmd (format #f "set -x; echo root | ~a --debug -u root -s http://localhost:3001 -p hello" dzn)))
                  (zero? (system cmd))))

              (test-equal "hello"
                "hello\n"
                (let* ((cmd (format #f "set -x; ~a hello" dzn))
                       (p (open-input-pipe cmd))
                       (output (read-string p))
                       (close-pipe p))
                  output))

              (test-equal "query"
                query-output
                (let* ((cmd (format #f "set -x; ~a query" dzn))
                       (p (open-input-pipe cmd))
                       (output (read-string p))
                       (close-pipe p))
                  output))

              (test-assert "install traces.js"
                (copy-file (string-append #$test-content "/dzn/commands/traces.js")
                           (string-append node-modules-dir "/dzn/commands/traces.js")))

              (test-assert "test all/helloworld"
                (begin
                  (every identity (map (bin/test "all/helloworld")
                                       (map car services-alist)
                                       (map cdr services-alist)))))

              (test-assert "test check"
                (if #$check? (every identity (map (bin/test "check")
                                                 (map car services-alist)
                                                 (map cdr services-alist)))))

              (test-end)

              (chdir out)

              (let ((regression (string-append #$output "/root/regression")))
                (mkdir-p regression)
                (for-each
                 (lambda (v)
                   (format (current-error-port) "rename : ~s -> ~s"
                           (string-append (dirname out) "/" v "/out")
                           (string-append regression "/" v))
                   (rename-file (string-append (dirname out) "/" v "/out")
                                (string-append regression "/" v)))
                 (map car services-alist)))

              (exit (= (test-runner-fail-count (test-runner-current)) 0)))))

      (gexp->derivation (string-append "dezyne-test-results" "-" version) test))))

(define %test-dezyne
  (system-test
   (name "dezyne")
   (description "Create dezyne vm, run [part of] test framework.")
   (value (run-dezyne-test #:check? #f)))) ; do not run full test/check/ yet
