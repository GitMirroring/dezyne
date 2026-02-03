;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; Copyright (c) 2025 Sergio Pastor Pérez <sergio.pastorperez@gmail.com>

(define-module (bluebox build-system blue)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix monads)
  #:use-module (guix store)
  #:use-module (guix packages)
  #:use-module (guix search-paths)
  #:use-module (guix build-system)
  #:use-module (guix build-system gnu)
  #:use-module (guix build gnu-build-system)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:export (%blue-build-system-modules
            blue-build
            blue-build-system))

(define %blue-build-system-modules
  ;; Build-side modules imported by default.
  `((bluebox build blue-build-system)
    (guix build gnu-build-system)
    (guix build utils)
    (guix build gremlin)
    (guix elf)))

(define (default-blue)
  "Return the default blue package."
  ;; Lazily resolve the binding to avoid a circular dependency.
  (let ((module (resolve-interface '(bluebox packages blue))))
    (module-ref module 'blue)))

(define* (lower name
                #:key source inputs native-inputs outputs target
                (blue (default-blue))
                (implicit-inputs? #t) (implicit-cross-inputs? #t)
                (strip-binaries? #t) system
                #:allow-other-keys
                #:rest arguments)
  "Return a bag for NAME from the given arguments."
  (define private-keywords
    `(#:inputs #:native-inputs #:outputs
      #:implicit-inputs? #:implicit-cross-inputs?
      ,@(if target '() '(#:target))))

  (bag
    (name name)
    (system system) (target target)
    (build-inputs `(,@(if source
                          `(("source" ,source))
                          '())
                    ,@native-inputs
                    ,@(if (package? blue)
                          `(("blue" ,blue))
                          '())
                    ;; When not cross-compiling, ensure implicit inputs come
                    ;; last.  That way, libc headers come last, which allows
                    ;; #include_next to work correctly; see
                    ;; <https://bugs.gnu.org/30756>.
                    ,@(if target '() inputs)
                    ,@(if (and target implicit-cross-inputs?)
                          (standard-cross-packages target 'host)
                          '())
                    ,@(if implicit-inputs?
                          (standard-packages system)
                          '())))
    (host-inputs (if target inputs '()))

    ;; The cross-libc is really a target package, but for bootstrapping
    ;; reasons, we can't put it in 'host-inputs'.  Namely, 'cross-gcc' is a
    ;; native package, so it would end up using a "native" variant of
    ;; 'cross-libc' (built with 'gnu-build'), whereas all the other packages
    ;; would use a target variant (built with 'gnu-cross-build'.)
    (target-inputs (if (and target implicit-cross-inputs?)
                       (standard-cross-packages target 'target)
                       '()))
    (outputs (if strip-binaries?
                 outputs
                 (delete "debug" outputs)))
    (build (if target blue-cross-build blue-build))
    (arguments (strip-keyword-arguments private-keywords arguments))))

(define (maybe-add-sub-phases orig-phases after command flags)
  (if (list? command)
      ;; List is doubly quoted. And we drop the first since it's already a
      ;; phase.
      (let ((sub-commands (cdadr command)))
        (if sub-commands
            (let* ((nums (iota (length sub-commands) 1))
                   (phase-names
                    (map (lambda (num)
                           (string->symbol
                            (string-append (symbol->string after)
                                           "-"
                                           (number->string num))))
                         nums))
                   (phase-names/command (zip phase-names sub-commands))
                   (phases (map (lambda (name/command)
                                  (match-let (((name command) name/command))
                                    (let ((command* (string-split command #\space))
                                          (flags* (cadr flags))) ; List is doubly quoted.
                                      `(add-after ',after ',name
                                         (lambda _
                                           (apply invoke
                                                  "blue"
                                                  '(,@flags* ,@command*)))))))
                                ;; Reverse the list since add-after always adds
                                ;; the phase as the next one from the original.
                                (reverse phase-names/command))))
              (values
               `(modify-phases ,orig-phases ,@phases)
               phase-names))
            (values orig-phases '())))
      (values orig-phases '())))

(define (chain-blue-commands blue-flags phases name+command)
  (fold
   (lambda (name+command phases+names)
     (call-with-values
         (lambda ()
           (maybe-add-sub-phases (car phases+names) (car name+command) (cdr name+command) blue-flags))
       (lambda (phases names)
         (cons phases (append names (cdr phases+names))))))
   (cons phases '())
   name+command))

(define* (blue-build name inputs
                     #:key
                     blue guile source
                     (outputs '("out"))
                     (search-paths '())

                     (blue-flags ''())
                     (configure-flags ''())
                     (build-command "build")
                     (out-of-source? #f)
                     (tests? #t)
                     (test-command "check")
                     (parallel-build? #t)
                     (parallel-tests? #t)
                     (install-command "install")
                     (patch-shebangs? #t)
                     (strip-binaries? #t)
                     (strip-flags %strip-flags)
                     (strip-directories %strip-directories)
                     (validate-runpath? #t)
                     (make-dynamic-linker-cache? #t)
                     (license-file-regexp %license-file-regexp)
                     (phases '%standard-phases)
                     (locale "C.UTF-8")
                     (separate-from-pid1? #t)
                     (system (%current-system))
                     (build (nix-system->gnu-triplet system))
                     (imported-modules %blue-build-system-modules)
                     (modules '((bluebox build blue-build-system)
                                (guix build utils)))
                     (substitutable? #t)
                     allowed-references
                     disallowed-references)
  "Return a derivation called NAME that builds from tarball SOURCE, with
input derivation INPUTS, using the usual procedure of the GNU Build
System.  The builder is run with GUILE, or with the distro's final Guile
package if GUILE is #f or omitted.

The builder is run in a context where MODULES are used; IMPORTED-MODULES
specifies modules not provided by Guile itself that must be imported in
the builder's environment, from the host.  Note that we distinguish
between both, because for Guile's own modules like (ice-9 foo), we want
to use GUILE's own version of it, rather than import the user's one,
which could lead to gratuitous input divergence.

SUBSTITUTABLE? determines whether users may be able to use substitutes of the
returned derivations, or whether they should always build it locally.

ALLOWED-REFERENCES can be either #f, or a list of packages that the outputs
are allowed to refer to."
  (define builder
    (with-imported-modules imported-modules
      #~(begin
          (use-modules #$@(sexp->gexp modules))

          #$(let ((phases (if (pair? phases)
                              (sexp->gexp phases)
                              phases)))
              (define phases+names
                (chain-blue-commands blue-flags phases
                                     `((build . ,build-command)
                                       (check . ,test-command)
                                       (install . ,install-command))))
              `(begin
                 (define augmented-phases
                   ,(car phases+names))
                 (define subphase-names
                   '(,@(cdr phases+names)))))

          #$(with-build-variables inputs outputs
              #~(blue-build #:source #+source
                            #:system #$system
                            #:build #$build
                            #:outputs %outputs
                            #:inputs %build-inputs
                            #:search-paths '#$(sexp->gexp
                                               (map search-path-specification->sexp
                                                    search-paths))
                            #:phases augmented-phases
                            #:subphase-names subphase-names
                            #:locale #$locale
                            #:separate-from-pid1? #$separate-from-pid1?
                            #:blue #$blue
                            #:blue-flags #$(if (pair? blue-flags)
                                               (sexp->gexp blue-flags)
                                               blue-flags)
                            #:configure-flags #$(if (pair? configure-flags)
                                                    (sexp->gexp configure-flags)
                                                    configure-flags)
                            #:build-command #$build-command
                            #:out-of-source? #$out-of-source?
                            #:tests? #$tests?
                            #:test-command #$test-command
                            #:parallel-build? #$parallel-build?
                            #:parallel-tests? #$parallel-tests?
                            #:install-command #$install-command
                            #:patch-shebangs? #$patch-shebangs?
                            #:license-file-regexp #$license-file-regexp
                            #:strip-binaries? #$strip-binaries?
                            #:validate-runpath? #$validate-runpath?
                            #:make-dynamic-linker-cache? #$make-dynamic-linker-cache?
                            #:license-file-regexp #$license-file-regexp
                            #:strip-flags #$strip-flags
                            #:strip-directories #$strip-directories)))))

  (mlet %store-monad ((guile (package->derivation (or guile (default-guile))
                                                  system #:graft? #f)))
    ;; Note: Always pass #:graft? #f.  Without it, ALLOWED-REFERENCES &
    ;; co. would be interpreted as referring to grafted packages.
    (gexp->derivation name builder
                      #:system system
                      #:target #f
                      #:graft? #f
                      #:substitutable? substitutable?
                      #:allowed-references allowed-references
                      #:disallowed-references disallowed-references
                      #:guile-for-build guile)))


;;;
;;; Cross-compilation.
;;;

(define* (blue-cross-build name
                           #:key
                           target
                           build-inputs target-inputs host-inputs
                           blue guile source
                           (outputs '("out"))
                           (search-paths '())
                           (native-search-paths '())

                           (blue-flags ''())
                           (configure-flags ''())
                           (build-command "build")
                           (out-of-source? #f)
                           (tests? #f)             ; nothing can be done
                           (test-command "check")
                           (parallel-build? #t)
                           (parallel-tests? #t)
                           (install-command "install")
                           (patch-shebangs? #t)
                           (strip-binaries? #t)
                           (strip-flags %strip-flags)
                           (strip-directories %strip-directories)
                           (validate-runpath? #t)

                           ;; We run 'ldconfig' to generate ld.so.cache and it
                           ;; generally can't do that for cross-built binaries
                           ;; ("ldconfig: foo.so is for unknown machine 40.").
                           (make-dynamic-linker-cache? #f)

                           (license-file-regexp %license-file-regexp)
                           (phases '%standard-phases)
                           (locale "C.UTF-8")
                           (separate-from-pid1? #t)
                           (system (%current-system))
                           (build (nix-system->gnu-triplet system))
                           (imported-modules %blue-build-system-modules)
                           (modules '((bluebox build blue-build-system)
                                      (guix build utils)))
                           (substitutable? #t)
                           allowed-references
                           disallowed-references)
  "Cross-build NAME for TARGET, where TARGET is a GNU triplet.  INPUTS are
cross-built inputs, and NATIVE-INPUTS are inputs that run on the build
platform."
  (define builder
    #~(begin
        (use-modules #$@(sexp->gexp modules))

        #$(let ((phases (if (pair? phases)
                            (sexp->gexp phases)
                            phases)))
            (define phases+names
              (chain-blue-commands blue-flags phases
                                   `((build . ,build-command)
                                     (check . ,test-command)
                                     (install . ,install-command))))
            `(begin
               (define augmented-phases
                 ,(car phases+names))
               (define subphase-names
                 '(,@(cdr phases+names)))))

        (define %build-host-inputs
          #+(input-tuples->gexp build-inputs))

        (define %build-command-inputs
          (append #$(input-tuples->gexp host-inputs)
                  #+(input-tuples->gexp target-inputs)))

        (define %build-inputs
          (append %build-host-inputs %build-command-inputs))

        (define %outputs
          #$(outputs->gexp outputs))

        (blue-build #:source #+source
                    #:system #$system
                    #:build #$build
                    #:target #$target
                    #:outputs %outputs
                    #:inputs %build-command-inputs
                    #:native-inputs %build-host-inputs
                    #:search-paths '#$(sexp->gexp
                                       (map search-path-specification->sexp
                                            search-paths))
                    #:native-search-paths '#$(sexp->gexp
                                              (map
                                               search-path-specification->sexp
                                               native-search-paths))
                    #:phases augmented-phases
                    #:subphase-names subphase-names
                    #:locale #$locale
                    #:separate-from-pid1? #$separate-from-pid1?
                    #:blue #$blue
                    #:blue-flags #$blue-flags
                    #:configure-flags #$configure-flags
                    #:build-command #$build-command
                    #:out-of-source? #$out-of-source?
                    #:tests? #$tests?
                    #:test-command #$test-command
                    #:parallel-build? #$parallel-build?
                    #:parallel-tests? #$parallel-tests?
                    #:install-command #$install-command
                    #:patch-shebangs? #$patch-shebangs?
                    #:license-file-regexp #$license-file-regexp
                    #:strip-binaries? #$strip-binaries?
                    #:validate-runpath? #$validate-runpath?
                    #:make-dynamic-linker-cache? #$make-dynamic-linker-cache?
                    #:license-file-regexp #$license-file-regexp
                    #:strip-flags #$strip-flags
                    #:strip-directories #$strip-directories)))

  (mlet %store-monad ((guile (package->derivation (or guile (default-guile))
                                                  system #:graft? #f)))
    (gexp->derivation name builder
                      #:system system
                      #:target target
                      #:graft? #f
                      #:modules imported-modules
                      #:substitutable? substitutable?
                      #:allowed-references allowed-references
                      #:disallowed-references disallowed-references
                      #:guile-for-build guile)))

(define blue-build-system
  (build-system
    (name 'blue)
    (description
     "The BLUE Build System—i.e., 'blue configure' && 'blue build' &&
'blue install'")
    (lower lower)))
