;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; Copyright (c) 2025 Sergio Pastor Pérez <sergio.pastorperez@gmail.com>

(define-module (bluebox packages blue)
  #:use-module (bluebox build-system blue)
  #:use-module (gnu packages code)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages guile)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:))

(define-public blue
  (let ((commit "0d1efbd93410a350af507759473f9a0a9d83343b")
        (revision "20"))
    (package
      (name "blue")
      (version (git-version "0.0.0" revision commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://codeberg.org/janneke/blue")
                      (commit commit)))
                (file-name (git-file-name name version))
                (sha256
                 (base32
                  "0kwc0n1kbajx5b3s98ni7j3cl00hlb6gsdr0g0fliig4vai199a5"))))
      (build-system blue-build-system)
      (arguments
       (list
        #:blue "."
        #:install-command ''("install" "installcheck")
        #:phases
        #~(modify-phases %standard-phases
            (delete 'strip))))
      (inputs (list guile-3.0))
       ;; Extend search path so installing when installing only 'blue + guile'
       ;; libraries' BLUE is able to use those libraries without `guile' being
       ;; in the profile.
      (native-search-paths
       (list (search-path-specification
               (variable "GUILE_LOAD_PATH")
               (files '("share/guile/site/3.0")))
             (search-path-specification
               (variable "GUILE_LOAD_COMPILED_PATH")
               (files '("lib/guile/3.0/site-ccache"
                        "share/guile/site/3.0")))
             (search-path-specification
               (variable "GUILE_EXTENSIONS_PATH")
               (files '("lib/guile/3.0/extensions")))
             (search-path-specification
               (variable "BASH_COMPLETION_USER_DIR")
               (files '("share/bash-completion")))))
      (home-page "https://codeberg.org/lapislazuli/blue")
      (synopsis "User extensible build language")
      (description
       "BLUE is a pure Guile build-system designed to be user extensible.")
      (license license:gpl3))))
