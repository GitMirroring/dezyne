;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (dezyne extra)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)

  #:use-module ((guix licenses) #:prefix license:)

  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages mono)
  #:use-module (gnu packages node)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)

  ;; for asd-converter
  #:use-module (gnu packages bison)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages xml)

  #:use-module (gnu packages)

  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)

  #:use-module (guix utils)

  #:use-module (dezyne config))

;; hack for guix 0.13 support
(when (not (defined? 'guile-readline))
  (let ((guile-readline
         (package
           (inherit hello)
           (name "guile-readline"))))
    (module-define! (current-module) 'guile-readline guile-readline)
    (export guile-readline)))

(define-public ((car-member lst) o)
  (member (car o) lst))

(define-public fakechroot
  (package
    (name "fakechroot")
    (version "2.18")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://ftp.debian.org/debian/pool/main/f/" name "/"
                    name "_" version ".orig.tar.gz"))
              (sha256
               (base32
                "13j1sis2lrl8sk4wm5lcfw54a3krp6rkkjp0aj2dybqsgp7id0vj"))))
    (propagated-inputs
     `(("util-linux" ,util-linux)))
    (build-system gnu-build-system)
    (arguments
     '(#:parallel-tests? #f
       #:tests? #f ;; 28 of 35 test fail
       #:phases (modify-phases %standard-phases
                  (add-after
                      'configure 'patch-tests
                    (lambda _
                      (substitute* (find-files "test")
                        ((" /bin/cat") (string-append " " (which "cat")))
                        ((" /bin/echo") (string-append " " (which "echo")))
                        (("-/bin/echo") (string-append "-" (which "echo")))
                        ((" /bin/pwd") (string-append " " (which "pwd")))
                        ((" /bin/sh") (string-append " " (which "sh")))
                        ((" /usr/bin/test") (string-append " " (which "test")))
                        ((" /bin/touch") (string-append " " (which "touch")))))))))
    (home-page "https://github.com/dex4er/fakechroot/wiki")
    (synopsis "provide a fake chroot environment")
    (description "Fakechroot runs a command in an environment were is
additional possibility to use chroot(8) command without root privileges.  This
is useful for allowing users to create own chrooted environment with
possibility to install another packages without need for root privileges.")
    (license license:lgpl2.1+)))

(define-public gojs
  (package
    (name "gojs")
    (version "1.6.15.73fc41e1b41c289246994a7e5a6a32b7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append git.oban/http "/" name "/" name "-" version ".tar.gz"))
       (sha256
        (base32 "07h6m4wvrxzlvgr5k1q2nnwgkbcfdsrwbzfsbjxxsd555v7j4lis"))))
    (native-inputs `(("bash" ,bash)
                     ("gzip" ,gzip)
                     ("tar" ,tar)))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let* ((out (assoc-ref %outputs "out"))
                (source (assoc-ref %build-inputs "source"))
                (bash (assoc-ref %build-inputs "bash"))
                (gzip (assoc-ref %build-inputs "gzip"))
                (tar (assoc-ref %build-inputs "tar"))
                (dir (string-append out "/share/gojs")))
           (setenv "PATH" (string-append bash "/bin:"
                                         gzip "/bin:"
                                         tar "/bin"))
           (mkdir-p dir)
           (system* "tar" "-C" dir "--strip-components=1" "-xf" source)))))
    (synopsis "gojs")
    (description "gojs")
    (home-page "https://gojs.com")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://gojs.com"
              "internal"))))

(define-public m4-changeword
  (package
    (inherit m4)
    (name "m4-changeword")
    (arguments
     (substitute-keyword-arguments `(#:configure-flags '("--enable-changeword" "--program-suffix=-cw")
                                     ,@(package-arguments m4))))))

(define-public mcrl2
  (package
    (name "mcrl2")
    (version "201707.1.e8b5e54f45")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.mcrl2.org/download/devel/mcrl2-"
                                  version
                                  ".tar.gz"))
              (sha256
               (base32
                "11cz9cln0dvxric8gjxl23fagpcjm0ryy524ihxbsv7vc52b6s8f"))))
    (native-inputs
     `(("git" ,git)
       ("python" ,python-2)))
    (inputs
     `(("boost" ,boost)
       ("glu" ,glu)
       ("mesa" ,mesa)
       ("qt" ,qt)))
    (build-system cmake-build-system)
    (synopsis "toolset for the mCRL2 formal specification language")
    (description
     "mCRL2 (micro Common Representation Language 2) is a formal specification
language for describing concurrent discrete event systems.  Its toolset
supports analysing and automatic verification, linearisation, simulation,
state-space exploration and generation and tools to optimise and analyse
specifications.  Also, state spaces can be manipulated, visualised and
analysed.")
    (home-page "http://www.mcrl2.org")
    (license license:boost1.0)))

(define-public mono-4.2
  (package
    (inherit mono)
    (name "mono")
    (version "4.2.1.102")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://download.mono-project.com/sources/mono/"
                    name "-" version
                    ".tar.bz2"))
              (sha256
               (base32
                "14np3sjqgl7pc1j165ryzlww8cyby73ahsqni0fn4prp0kz63d5p"))))
    (arguments
     `(#:tests? #f ; 4.2.1.102: many tests fail, hang-- disable all
       ,@(package-arguments mono)))))

(define-public node7
  (package
    (name "node7")
    (version "7.8.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://nodejs.org/dist/v" version
                                  "/node-v" version ".tar.gz"))
              (sha256
               (base32
                "1nkngdjbsm81nn3v0w0c2aqx9nb7mwy3z49ynq4wwcrzfr9ap8ka"))
              ;; https://github.com/nodejs/node/pull/9077
              (patches (search-patches "node-9077.patch"))))
    (build-system gnu-build-system)
    (arguments
     ;; TODO: Package http_parser and add --shared-http-parser.
     '(#:configure-flags '("--shared-openssl"
                           "--shared-zlib"
                           "--shared-libuv"
                           "--without-snapshot")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-files
           (lambda* (#:key inputs #:allow-other-keys)
             ;; Fix hardcoded /bin/sh references.
             (substitute* '("lib/child_process.js"
                            "lib/internal/v8_prof_polyfill.js"
                            "test/parallel/test-child-process-spawnsync-shell.js"
                            "test/parallel/test-stdio-closed.js")
               (("'/bin/sh'")
                (string-append "'" (which "sh") "'")))

             ;; Fix hardcoded /usr/bin/env references.
             (substitute* '("test/parallel/test-child-process-default-options.js"
                            "test/parallel/test-child-process-env.js"
                            "test/parallel/test-child-process-exec-env.js")
               (("'/usr/bin/env'")
                (string-append "'" (which "env") "'")))

             ;; Having the build fail because of linter errors is insane!
             (substitute* '("Makefile")
               (("	\\$\\(MAKE\\) jslint") "")
               (("	\\$\\(MAKE\\) cpplint\n") ""))

             ;; FIXME: These tests fail in the build container, but they don't
             ;; seem to be indicative of real problems in practice.
             (for-each delete-file
                       '("test/parallel/test-dgram-membership.js"
                         "test/parallel/test-cluster-master-error.js"
                         "test/parallel/test-cluster-master-kill.js"
                         "test/parallel/test-npm-install.js"
                         "test/sequential/test-child-process-emfile.js"))
             #t))
         (replace 'configure
           ;; Node's configure script is actually a python script, so we can't
           ;; run it with bash.
           (lambda* (#:key outputs (configure-flags '()) inputs
                     #:allow-other-keys)
             (let* ((prefix (assoc-ref outputs "out"))
                    (flags (cons (string-append "--prefix=" prefix)
                                 configure-flags)))
               (format #t "build directory: ~s~%" (getcwd))
               (format #t "configure flags: ~s~%" flags)
               ;; Node's configure script expects the CC environment variable to
               ;; be set.
               (setenv "CC" (string-append (assoc-ref inputs "gcc") "/bin/gcc"))
               (zero? (apply system*
                             (string-append (assoc-ref inputs "python")
                                            "/bin/python")
                             "configure" flags)))))
         (add-after 'patch-shebangs 'patch-npm-shebang
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((bindir (string-append (assoc-ref outputs "out")
                                           "/bin"))
                    (npm    (string-append bindir "/npm"))
                    (target (readlink npm)))
               (with-directory-excursion bindir
                 (patch-shebang target (list bindir))
                 #t)))))))
    (native-inputs
     `(("python" ,python-2)
       ("perl" ,perl)
       ("procps" ,procps)
       ("util-linux" ,util-linux)
       ("which" ,which)))
    (inputs
     `(("libuv" ,libuv)
       ("openssl" ,openssl)
       ("zlib" ,zlib)))
    (synopsis "Evented I/O for V8 JavaScript")
    (description "Node.js is a platform built on Chrome's JavaScript runtime
for easily building fast, scalable network applications.  Node.js uses an
event-driven, non-blocking I/O model that makes it lightweight and efficient,
perfect for data-intensive real-time applications that run across distributed
devices.")
    (home-page "http://nodejs.org/")
    (license license:expat)
    (properties '((timeout . 3600)))))

(define-public node6
  (package
    (inherit node7)
    (name "node6")
    (version "6.8.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://nodejs.org/dist/v" version
                                  "/node-v" version ".tar.gz"))
              (sha256
               (base32
                "0lj3250hglz4w5ic4svd7wlg2r3qc49hnasvbva1v69l8yvx98m8"))
              (patches (search-patches "node-9077.patch"))))
    (native-search-paths
     (list (search-path-specification
            (variable "NODE_PATH")
            (files '("lib/node_modules")))))))

(define-public node-snapshot
  (package
    (name "node-snapshot")
    (version "10")
    (source
     (origin
       (method url-fetch)
       (uri (string-append git.oban/http "/" name "/" name "-" version ".tar.gz"))
       (sha256
        (base32 "1csnlx86x6vnz2k00b35hibd8papgl0a023s5j4qbzfkxil9xbpm"))))
    (propagated-inputs `(("bash" ,bash) ; patch-shebangs
                         ("gcc-lib" ,gcc "lib")
                         ("libc" ,glibc)
                         ("node" ,node6))) ; patch-shebangs
    (native-inputs `(("gzip" ,gzip)
                     ("patchelf" ,patchelf)
                     ("tar" ,tar)))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils)
                  (srfi srfi-1)
                  (srfi srfi-26)
                  (ice-9 receive))
       #:builder
       (begin
         (use-modules (guix build utils)
                      (srfi srfi-1)
                      (srfi srfi-26)
                      (ice-9 receive))
         (let* ((out (assoc-ref %outputs "out"))
                (source (assoc-ref %build-inputs "source"))
                (bash (assoc-ref %build-inputs "bash"))
                (gzip (assoc-ref %build-inputs "gzip"))
                (node (assoc-ref %build-inputs "node"))
                (patchelf (assoc-ref %build-inputs "patchelf"))
                (tar (assoc-ref %build-inputs "tar"))

                (libc (assoc-ref %build-inputs "libc"))
                (ld.so (string-append libc ,(glibc-dynamic-linker)))
                (libc-rpath (dirname ld.so))
                (gcc-lib (assoc-ref %build-inputs "gcc-lib"))
                (libstdc++-rpath (string-append gcc-lib "/lib")))
           (setenv "PATH" (string-append bash "/bin:"
                                         gzip "/bin:"
                                         node "/bin:"
                                         patchelf "/bin:"
                                         tar "/bin"))
           (mkdir-p out)
           (system* "tar" "-C" out "-xf" source)
           (for-each patch-shebang
                     (find-files out
                                 (lambda (file stat)
                                   ;; Filter out symlinks.
                                   (eq? 'regular (stat:type stat)))
                                 #:stat lstat))
           (receive (linux-x64 other)
               (partition (cut string-contains <> "linux")
                          (find-files (string-append out "/lib/node_modules/uws") ".*.node"))
             (for-each delete-file other)
             (for-each (cut system* "patchelf" "--set-rpath" libc-rpath <>)
                       linux-x64))
           (receive (linux-x64 other)
               (partition (cut string-contains <> "linux-x64")
                          (find-files (string-append out "/lib/node_modules/fibers/bin") "fibers.node"))
             (for-each delete-file other)
             (for-each (cut system* "patchelf" "--set-rpath" libstdc++-rpath <>)
                       linux-x64))))))
    (synopsis "internet snapshot of installed node npm packages as binary blob")
    (description "internet snapshot of installed node npm packages as binary blob")
    (home-page "https://hosting.verum.com/download/npm")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))

(define %default-postgres-hba
  (plain-file "pg_hba.conf"
              "
local   all             postgres                                peer
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             10.0.77.64/28           trust
host    all             all             192.168.32.0/24         trust
host    all             all             ::1/128                 trust "))

(define %default-postgres-ident
  (plain-file "pg_ident.conf"
              "# MAPNAME       SYSTEM-USERNAME         PG-USERNAME"))

(define %default-postgres-config
  (mixed-text-file "postgresql.conf"
                   "log_destination = 'syslog'\n"
                   "hba_file = '" %default-postgres-hba "'\n"
                   "ident_file = '" %default-postgres-ident "'\n"
                   "listen_addresses = '*'\n"
                   "port = 5432\n"
                   "max_connections = 100\n"
                   "#unix_socket_directories = '/var/run/postgresql'\n"
                   "tcp_keepalives_idle = 60\n"
                   "tcp_keepalives_interval = 60\n"
                   "tcp_keepalives_count = 1\n"
                   "shared_buffers = 128MB\n"
                   "log_line_prefix = '%t '\n"
                   "log_timezone = 'Europe/Amsterdam'\n"
                   "datestyle = 'iso, dmy'\n"
                   "timezone = 'Europe/Amsterdam'\n"
                   "lc_messages = 'nl_NL.UTF-8'\n"
                   "lc_monetary = 'nl_NL.UTF-8'\n"
                   "lc_numeric = 'nl_NL.UTF-8'\n"
                   "lc_time = 'nl_NL.UTF-8'\n"
                   "default_text_search_config = 'pg_catalog.english'\n"
                   ))

(define-public postgres-config
  (package
    (version "9")
    (name "postgres-config")
    (source #f)
    (native-inputs
     `(("postgresql.conf" ,%default-postgres-config)
       ("pg_hba.conf" ,%default-postgres-hba)
       ("pg_ident.conf" ,%default-postgres-ident)))
    (propagated-inputs
     `(("glibc-locales" ,glibc-locales)))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils)
                  (guix monads))
       #:builder (begin (use-modules (guix build utils)
                                     (guix monads))
                        (mkdir-p (string-append (assoc-ref %outputs "out") "/etc"))
                        (copy-file (assoc-ref %build-inputs "postgresql.conf")
                                   (string-append (assoc-ref %outputs "out") "/etc/postgresql.conf"))
                        (copy-file (assoc-ref %build-inputs "pg_hba.conf")
                                   (string-append (assoc-ref %outputs "out") "/etc/pg_hba.conf"))
                        (copy-file (assoc-ref %build-inputs "pg_ident.conf")
                                   (string-append (assoc-ref %outputs "out") "/etc/pg_ident.conf")))))
    (synopsis "package for postgres service config")
    (description "package for postgres service config")
    (home-page "http://verum.com")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))

(define-public asd-converter-0.1.6
  (package
    (name "asd-converter")
    (version "0.1.6")
    (source (origin
              (method git-fetch)
              (uri (git-reference (url (string-append git.oban/git "/gen1gen2.git"))
                                  (commit "f0767fdb3e7c12a65dcc0e6c52b9b76088979608")))
              (sha256 (base32 "0vac7svmsm3lxw4l5d2vhlmfg6crzlinr67bf8xm326q8gg8ymdf"))))
    (inputs `(("boost" ,boost)
              ("expat" ,expat)))
    (native-inputs `(("bison" ,bison)
                     ("flex" ,flex)
                     ("gcc" ,gcc)
                     ("gcc-lib" ,gcc "lib")
                     ("tcl" ,tcl)
                     ("tcllib" ,tcllib)
                     ("tclxml" ,tclxml)))
    (build-system gnu-build-system)
    (arguments
     `(#:parallel-tests? #f
       #:parallel-build? #f
       #:tests? #f
       #:make-flags '("-C" "product/code")
       #:modules ((srfi srfi-1)
                  ,@%gnu-build-system-modules)
       #:phases (modify-phases %standard-phases
                  (delete 'configure)
                  (replace 'install
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let* ((out (assoc-ref outputs "out"))
                             (version (last (string-split out #\-)))
                             (bin (string-append out "/bin"))
                             (asd (string-append "asd" "-" version)))
                        (mkdir-p (string-append out "/bin"))
                        (copy-file "product/code/build/linux64/asd"
                                   (string-append bin "/" asd))
                        (symlink (string-append asd) (string-append bin "/asd"))))))))
    (synopsis "package for asd->dzn converter")
    (description "package for asd->dzn converter")
    (home-page "http://verum.com")
    (license ((@@ (guix licenses) license)
              "proprietary"
              "http://verum.com"
              "internal"))))
