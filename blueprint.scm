;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2026 Janneke Nieuwenhuizen <janneke@gnu.org>
;;;;Copyright © 2026 Olivier Dion <olivier.dion@polymtl.ca>
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

;;; TODO
;;; * Add dependency on template build of dzn/config.scm, try:
;;;     rm -f dzn/config.scm && blue build
;;;   gives
;;; 	GUILD	/home/janneke/src/verum/dzn/wip-blue/dzn/peg/util.go
;;;     misc-error: no code for module (dzn config)
;;;      ...
;;;	TPL	/home/janneke/src/verum/dzn/wip-blue/dzn/config.scm
;;; * configure.ac (flags)
;;; ** --enable-languages=LANG,... [c++]
;;; ** --disable-c++-thread-pool
;;; ** --with-boost/without-boost
;;; ** json detection/error if not found
;;; ** recent scmackerel detection/error if not found
;;; ** libpth detection
;;; * grep ^FAIL: test-suite.log | sort -u > fail ... make check TESTS="$(cut -d: -f2 fail)"
;;; * make check-hello / check-smoke?
;;; * manuals (help2man)
;;; * no-install-scm-files
;;; * no-build-scm-files
;;; * no-install-no-build-scm-files
;;; * make [sign-]dist
;;; ** [reproducible!] source tarball
;;; * reproducible doc/version.texi
;;; * generate .texi snippets (make update-doc)
;;; * install
;;; ** how to install template-file (config.scm, config.hh)?
;;;  goops-error: No applicable method for #<<generic> install! (6)> in call (install! #{<template-file>dzn/config.scm: blueprint.scm:357:6} "roet/share/guile/site/3.0/dzn" 292)
;;; ** how to NOT install template-file (pre-inst-env, test/bin/run, etc)?

;;; * build runtime/c++/lib* , runtime/c/lib*, when language enabled
;;; * command-line override arguments for script->log; make check TESTS=... RUN_FLAGS=--stage=verify
;;; * optionally skip spawn of test/bin/run[.in], directly invoke `run-test'
;;; * rewrite test suite's test/dzn/dzn.scm's => test/lib/*.make to also use blue

;;; DONE
;;; * Fix miscompilation of dzn/peg/cache.go; workaround:
;;     (./autogen.sh; ./configure; make)
;;;    rm -f dzn/peg/cache.go && make dzn/peg/cache.go
;;; => Use -O2 instead of -O3 (branch hack-use-optimization-level-2)
;;; * After succesful: blue build, a second blue build gives:
;;;     In blue/stencils/c.scm:
;;;       349:29  1 (_ #<input: /home/janneke/src/verum/dzn/wip-blue/runtim…>)
;;;   (seems to be some bug in the check-dependencies procedure)
;;; => BLUE bug (branch fix-check-dependencies)
;;; * command-line override: TESTS, XFAIL_TESTS
;;; => TESTS=test/all/hello blue check
;;; * command-line override: RUN_FLAGS='--timeout=600 --stage=verify --language=c'
;;; => RUN_FLAGS=--stage=verify TESTS=test/all/hello blue check
;;; * command-line override XFAIL_*: make check XFAIL_TESTS=... / XFAIL_VERIFY=...
;;; => XFAIL_TESTS= blue check
;;; ** how does runtime/c++/dzn/config.hh.in template work, i.e., the typical
;;;    autoconf stanza:
;;       #ifndef HAVE_BOOST_COROUTINE
;;;      /* Define if you have the boost coroutine library. */
;;;       #undef HAVE_BOOST_COROUTINE
;;;       #endif
;;;  => either unchanged, or => #define HAVE_BOOST_COROUTINE 1
;;; ** --with-courage (for c, javascript, scheme)
;;;
;;; Code:

(use-modules (srfi srfi-1)
	     (srfi srfi-26)
	     ;; (srfi srfi-71) ;import breaks blue?

	     (ice-9 exceptions)
	     (ice-9 match)
	     (ice-9 regex)

	     (oop goops)

	     (blue build)
	     (blue configuration find)
	     (blue configuration states)
	     (blue configuration toolchain c)
	     (blue dependency c)
	     (blue oop)
	     (blue states)
	     (blue stencils c)
	     (blue stencils c configuration)
	     (blue stencils guile)
	     (blue stencils template-file)
	     (blue subprocess)
	     (blue types blueprint)
	     (blue types buildable)
	     (blue types cli-option)
	     (blue types command)
	     (blue types configuration)
	     (blue types testable)
	     (blue types variable)
	     (blue utils environ)
	     (blue utils hash)
	     (blue utils host)

	     (blueprint install)
	     (blueprint sources)
	     (blueprint tests)

	     (dzn misc))

(define dezyne-options
  (list
   (cli-option
    (labels '("enable-languages"))
    (argument '(required "LANG[,LANG]..."))
    (process (lambda# (value #:key modify-variable #:allow-other-keys #:rest states)
               (let* ((languages (string-split value #\,))
		      (languages (map string-trim-both languages))
		      (languages-string (string-join languages " ")))
                 (modify-variable "languages-list" languages states)
                 ;; FIXME: remove duplication
		 (modify-variable "languages" languages-string states))))
    (doc "specify languages to build for")
    ;;(autocomplete '("c" "c++" "cs" "scheme" "javascript")) ;FIXME?
    )

   (cli-option
    (labels '("disable-c++-thread-pool"))
    (argument '(switch #f))
    (process (lambda# (value #:key modify-variable #:allow-other-keys #:rest states)
               (modify-variable "with-c++-thread-pool?" value states)))
    (doc "apply courage"))

   (cli-option
    (labels '("with-courage"))
    ;; FIXME: "bad VALUE"
    ;; (argument #f)
    ;; (argument 'none)
    ;; (argument 'switch)
    (argument '(switch #t))	 ;seems to work..but now it's MANDATORY?
    (process (lambda# (value #:key modify-variable #:allow-other-keys #:rest states)
               (modify-variable "with-courage?" value states)))
    (doc "apply courage"))))

(define dezyne-variables
  (append
   (make-package-variables
    #:name "Dezyne"
    #:version "2.20.0"
    #:bug-report "bug-dezyne@nongnu.org"
    #:url "https://dezyne.org")
   (list
    (variable
     (name "PATH")
     (value #%~(string-append
		#%?builddir "/bin"
		":" #%?srcdir "/test/bin"
                ":" #%?builddir "/test/bin"
		":" (getenv "PATH"))))
    (variable
     (name "VERSION_MAJOR")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
	(match (string-split (variable-ref "PACKAGE_VERSION") #\.)
	  ((major minor patch . rest) major)))))
    (variable
     (name "VERSION_MINOR")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
	(match (string-split (variable-ref "PACKAGE_VERSION") #\.)
	  ((major minor patch . rest) minor)))))
    (variable
     (name "VERSION_PATCH")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
	(match (string-split (variable-ref "PACKAGE_VERSION") #\.)
	  ((major minor patch . rest) patch)))))
    (variable
     (name "abs_top_srcdir")
     (value (const #%~#%?srcdir)))
    (variable
     (name "abs_top_builddir")
     (value (const #%~#%?builddir)))
    (variable
     (name "guilemoduledir")
     (value (const #%~#%?guile-module-dir)))
    (variable
     (name "guileobjectdir")
     (value (const #%~#%?guile-object-dir)))
    (variable
     (name "GUILE_TOOLS")
     (value (delay# (find-executable "guild"))))
    (variable
     (name "HELP2MAN")
     (value (delay# (find-executable "help2man"))))
    (variable
     (name "SHELL")
     (value (delay# (or (find-executable "bash")
			(find-executable "sh")))))
    (variable
     (name "have-libpth?")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (let ((includes '())
              (fmt "%s")
              (expression "\"hallo, hallo\""))
          (false-if-exception      ;FIXME: exception when linking fails?
           (zero? (c-toolchain-try-statement
                   (variable-ref "CC")
                   "pth_init ();"
                   #:lang "c"
                   #:includes '("<pth.h>")
                   #:ldflags '("-l" "pth"))))))))
    ;; FIXME: TODO: warn/error if not available
    ;; TODO: check for recent enough scmackerel
    (variable
     (name "SCMACKEREL_SOURCE_DIRECTORY")
     (value (delay#
             (and=> (find-guile-module "scmackerel/processes.scm" #:required? #t) dirname))))
    (variable
     (name "SCMACKEREL_OBJECT_DIRECTORY")
     (value (delay#
             (and=> (find-guile-module-object "scmackerel/processes.go" #:required? #t) dirname))))

    ;; FIXME: TODO: warn/error if not available
    (variable
     (name "JSON_SOURCE_DIRECTORY")
     (value (delay#
             (and=> (find-guile-module "json.scm" #:required? #t) dirname))))
    (variable
     (name "JSON_OBJECT_DIRECTORY")
     (value (delay#
             (and=> (find-guile-module-object "json.go" #:required? #t) dirname))))
    (variable
     (name "MONO")
     (value (delay# (find-executable "mcs"))))
    (variable
     (name "NODE")
     (value (delay# (find-executable "node"))))
    (variable
     (name "with-courage?")
     (value #f))
    (variable
     (name "with-c++-thread-pool?")
     (value #t))
    (variable
     (name "with-dzn-version-assert?")
     (value #t))
    (variable
     (name "have-c++-mutex?")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (false-if-exception    ;FIXME: exception when compilation fails?
         (zero? (c-toolchain-try-statement
                 (variable-ref "CXX")
                 "std::mutex m;"
                 #:lang "c++"
                 #:includes '("<mutex>")))))))
    (variable
     (name "have-boost-coroutine?")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (false-if-exception        ;FIXME: exception when linking fails?
         (zero? (c-toolchain-try-statement
                 (variable-ref "CXX")
                 "boost::coroutines::stack_traits::default_size ();"
                 #:lang "c++"
                 #:includes '("<boost/coroutine/all.hpp>")
                 #:ldflags '("-l" "boost_coroutine")))))))
    (variable
     (name "languages-list")            ;FIXME: remove duplication
     (value (lambda# (#:key variable-ref #:allow-other-keys)
	      (let ((courage? (false-if-exception ;FIXME: this can't be right?
			       ;; with-courage? No variable with that name???
			       ;; THIS ONLY WORKS when using: blue configure --with-courage ...hmm?
			       (variable-ref "with-courage?"))))
		(append
		 (or (and (variable-ref "CXX") '("c++")) '())
		 (or (and (variable-ref "MONO") '("cs")) '())
		 (or (and courage? '("scheme")) '())
		 (or (and courage? (variable-ref "CC") '("c")) '())
		 (or (and courage? (variable-ref "NODE") '("javascript")) '()))))))
    (variable
     (name "languages")
     (value (lambda# (#:key variable-ref #:allow-other-keys)
              (string-join (variable-ref "languages-list") " "))))

    ;; ldflags
    (variable
     (name "LIBPTH")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (if (variable-ref "have-libpth?") '("-l" "pth") '()))))

    (variable
     (name "LIBBOOST_COROUTINE")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (if (variable-ref "have-boost-coroutine?") '("-l" "boost_coroutine")
            '()))))

    ;; config.h[h] substitutions
    (variable
     (name "DZN_VERSION_ASSERT")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (if (variable-ref "with-dzn-version-assert?") "#define DZN_VERSION_ASSERT 1"
            "#undef DZN_VERSION_ASSERT"))))
    (variable
     (name "HAVE_LIBPTH")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (if (variable-ref "have-libpth?") "#define HAVE_LIBPATH 1"
            "#undef HAVE_LIBPATH"))))
    (variable
     (name "HAVE_BOOST_COROUTINE")
     (value
      (lambda# (#:key variable-ref #:allow-other-keys)
        (if (variable-ref "have-boost-coroutine?") "#define HAVE_BOOST_COROUTINE 1"
            "#undef HAVE_BOOST_COROUTINE")))))))

(define dezyne-dependencies
  (list
   ;; FIXME: how does this work: No package 'guile' found, what's a "package"?
   ;; (c-dependency
   ;;  (name "guile")
   ;;  (required? #t)
   ;;  (minimum-version "2.0"))

   (c-dependency ;FIXME: copied from the Shepherd...
    (name "guile-3.0")
    (required? #t)
    (minimum-version "3.0"))))

(define dezyne-configuration
  (configuration
   (dependencies dezyne-dependencies)
   (variables dezyne-variables)
   (options dezyne-options)))

(define @variable@-template-regexp
  (make-regexp "@([a-zA-Z_-][a-zA-Z0-9_-]*)@"))

(define undef-template-regexp
  (make-regexp "#undef ([a-zA-Z-][a-zA-Z0-9_-]*)"))

(define (dezyne-go-location source)
  #%~(string-append #%?guile-object-dir "/" #%,(dirname source)))

(define (dezyne-source-location source)
  #%~(string-append #%?guile-module-dir "/" #%,(dirname source)))

(define +template-files+
  (list
   (template-file
    (inputs (list "build-aux/pre-inst-env.in"))
    (outputs "pre-inst-env")
    (install-location #%~#%?bindir) ;FIXME
    (mode #o755)
    (regexp @variable@-template-regexp))

   (template-file
    (inputs (list "bin/dzn.in"))
    (outputs "bin/dzn")
    (install-location #%~#%?bindir)
    (mode #o755)
    (regexp @variable@-template-regexp))
   (template-file
    (inputs (list "test/bin/run.in"))
    (outputs "test/bin/run")
    (install-location #%~#%?bindir) ;FIXME
    (mode #o755)
    (regexp @variable@-template-regexp))

   (template-file
    (inputs (list "test/bin/run-baseline.in"))
    (outputs "test/bin/run-baseline")
    (install-location #%~#%?bindir) ;FIXME
    (mode #o755)
    (regexp @variable@-template-regexp))

   (template-file
    (inputs (list "test/bin/run-build.in"))
    (outputs "test/bin/run-build")
    (install-location #%~#%?bindir) ;FIXME
    (mode #o755)
    (regexp @variable@-template-regexp))

   (template-file
    (inputs (list "test/bin/run-execute.in"))
    (outputs "test/bin/run-execute")
    (install-location #%~#%?bindir) ;FIXME
    (mode #o755)
    (regexp @variable@-template-regexp))

   (guile-module	     ;FIXME: all .go's must depend on config.scm
    (inputs
     (list
      (template-file
       (inputs (list "dzn/config.scm.in"))
       (regexp @variable@-template-regexp)
       (outputs "dzn/config.scm"))))
    (outputs "dzn/config.go")
    (install-location
     (dezyne-go-location "dzn/config.scm"))
    (install-source-location
     (dezyne-source-location "dzn/config.scm")))

   (template-file
    (inputs (list "runtime/c++/dzn/config.hh.in"))
    (outputs "runtime/c++/dzn/config.hh")
    (install-location #%~#%?%includedir) ;FIXME
    (regexp undef-template-regexp))

   (template-file
    (inputs (list "runtime/c++/dzn/meta.hh.in"))
    (outputs "runtime/c++/dzn/meta.hh")
    (install-location #%~#%?%includedir) ;FIXME
    (regexp @variable@-template-regexp))

   (template-file
    (inputs (list "runtime/c/dzn/config.h.in"))
    (outputs "runtime/c/dzn/config.h")
    (install-location #%~#%?%includedir)
    (regexp undef-template-regexp)))) ;FIXME

(define +sources+ scm-files)

(define build-environment
  #%~(list
      "LC_ALL=C"
      "LC_MESSAGES=C"
      (string-append "DZN_PREFIX=" #%?builddir)
      "DZN_UNINSTALLED=1"
      (string-append "PATH="
                     (in-vicinity #%?builddir "/bin")
                     ":" (in-vicinity #%?srcdir "/test/bin")
                     ":" (in-vicinity #%?builddir "/test/bin")
                     ":" (getenv "PATH"))
      (string-append "GUILE_LOAD_PATH="
		     (string-join
		      (cons* #%?srcdir #%?builddir %load-path)
		      ":"))
      (string-append "GUILE_LOAD_COMPILED_PATH="
		     (string-join
		      (cons* #%?srcdir #%?builddir %load-compiled-path)
		      ":"))
      (format #f "GUILE=~a" #%?GUILE)))

(define* (scm->go source #:key (enabled? #t))
  (guile-module
   (inputs (list source))
   (outputs (->.go source))
   (enabled? enabled?)
   (load-path #%~(list #%?srcdir #%?builddir))
   (install-location (dezyne-go-location source))
   (install-source-location (dezyne-source-location source))
   (environment build-environment)))

(define with-language-c++?        #%~(member "c++"        #%?languages-list))
(define with-language-c?          #%~(member "c"          #%?languages-list))
(define with-language-cs?         #%~(member "cs"         #%?languages-list))
(define with-language-javascript? #%~(member "javascript" #%?languages-list))
(define with-language-scheme?     #%~(member "scheme"     #%?languages-list))

(define +modules+
  (append
   (map scm->go +sources+)
   ;;(map (cute scm->go <> #:enabled? #f) no-install-scm-files)
   (map (cute scm->go <> #:enabled? #t) no-install-scm-files) ;FIXME: must compile, not install
   (map (cute scm->go <> #:enabled? with-language-c++?) c++-scm-files)
   (map (cute scm->go <> #:enabled? with-language-c?) c-scm-files)
   (map (cute scm->go <> #:enabled? with-language-cs?) cs-scm-files)
   (map (cute scm->go <> #:enabled? with-language-javascript?) javascript-scm-files)
   (map (cute scm->go <> #:enabled? with-language-scheme?) scheme-scm-files)))

;; FIXME: TODO:
;;  * split test/bin/run.in into module, invoke `main' with argumens? OR
;;  * split stages/languages logic, use to invoke run-test languages #:stages?
(define-blue-class <script-test-suite> (<testable>))

;; FIXME: TODO: Add to BLUE interface.
(define test-result
  (let ((total 0)
	(pass  0)
	(fail  0)
	(skip  0)
	(xfail 0)
	(xpass 0))
    (lambda (type)
      (case type
	((total) total)
	((result) (format #f "
============================================================================
Testsuite summary for Dezyne 2.19.3.114-7ca0c2
============================================================================
# PASS:  ~a
# FAIL:  ~a
# SKIP:  ~a
# XFAIL: ~a
# XPASS: ~a
# TOTAL: ~a
============================================================================
"
			  pass fail skip xfail xpass total))
	((pass)  (set! pass  (1+ pass))  (set! total (1+ total)) "PASS")
	((fail)  (set! fail  (1+ fail))  (set! total (1+ total)) "FAIL")
	((skip)  (set! skip  (1+ skip))  (set! total (1+ total)) "SKIP")
	((xfail) (set! xfail (1+ xfail)) (set! total (1+ total)) "XFAIL")
	((xpass) (set! xpass (1+ xpass)) (set! total (1+ total)) "XPASS")))))

(define %test-suite.log "test-suite.log") ;FIXME
(define-method (ask-build-manifest (this <script-test-suite>)
                                   (input <string>)
                                   (output <string>))
  (let* ((cwd (getcwd))
	 (relative (if (not (string-prefix? cwd input)) input
		       (string-drop input (1+ (string-length cwd)))))
	 (input relative))
    (make-build-manifest
     (format #f "TEST ~a" input)
     (lambda _
       (with-output-to-file output
	 (lambda _
	   (let* ((script (string-append #%?builddir "/test/bin/run")) ;FIXME: make configure'able
		  (arguments (or (and=> (getenv "RUN_FLAGS") ;FIXME: make configure'able
					(cute string-split <> #\space))
				 '()))
		  (status (popen script `(,@arguments ,input)))
		  (status (/ status 256))
		  (expect-fail? (member input xfail-tests))
		  (skip? (eq? status 77))
		  (success? (zero? status))
		  (first? (zero? (test-result 'total))) ;FIXME: totals hack
		  ;; FIXME: TODO: How to TOTALs?
		  (result (cond (skip?                             (test-result 'skip))
				((and expect-fail? success?)       (test-result 'xpass))
				((and expect-fail? (not success?)) (test-result 'xfail))
				(success?                          (test-result 'pass))
				(else                              (test-result 'fail))))
		  (message (format #f "~a: ~a" result input))
		  (log (open-file %test-suite.log "a"))
		  (last? (equal? (test-result 'total) (length +script-tests+)))) ;FIXME: totals hack
	     (when first?
	       (truncate-file log))
	     (display message (current-error-port))
	     (with-output-to-port log
	       (cute format #t "~a\n" message))
	     (when last?		;FIXME: totals hack
	       (let ((message (test-result 'result)))
		 (display message (current-error-port))
		 (with-output-to-port log
		   (cute display message))))
	     (force-output log))))))))

(define (script->log test-name)
  (script-test-suite
   (inputs test-name)
   (outputs (string-append test-name ".log"))
   (environment build-environment)))

(define (scm->log scm-name)
  (let ((test-options
	 #%~(let ((path (list
			 #%?srcdir
			 #%?builddir)))
	      (list
	       #:load-path path
	       #:load-compiled-path path
	       #:enable-coverage? #f))))
    (guile-test-suite
     (inputs scm-name)
     (environment build-environment)
     (options test-options))))

(define +script-tests+ full-tests)
(define +unit-tests+ unit-tests)

(define one-test-only? #f) ;FIXME: use #t to only smoke-test the test suite

(when one-test-only?
  (set! +script-tests+ '("test/all/hello"))
  (set! +unit-tests+   '("test/dzn/ast.scm")))

(define +tests+
  (append
   (map script->log +script-tests+)
   (map scm->log +unit-tests+)))


;;;
;;; Runtime
;;;
(define libdzn-c++
  (c-binary
   (inputs runtime-cc-files)
   (outputs "runtime/c++/.libs/libdzn-c++.so")
   (cppflags (list (string-append "-I" #%?srcdir "/runtime/c++")))
   (library? #t)
   (shared? #t)
   (enabled? with-language-c++?)))

(define libdzn-c
  (c-binary
   (inputs runtime-c-files)
   (outputs "runtime/c/.libs/libdzn-c.so")
   (cppflags (list (string-append "-I" #%?srcdir "/runtime/c")))
   (library? #t)
   (shared? #t)
   (enabled? with-language-c?)))

(define +libraries+
  (append
   (list libdzn-c++)
   (list libdzn-c)))

(blueprint
 (configuration
  (merge-configuration
   dezyne-configuration
   (merge-configuration
    %c-configuration
    %cxx-configuration
    'first)
   'first))
 (buildables
  (append +template-files+
	  +modules+
	  +libraries+))
 (testables
  +tests+)
 (commands
  (list
   install-command)))

;;; Local Variables:
;;; mode: scheme
;;; coding: utf-8
;;; indent-tabs-mode: nil
;;; eval: (modify-syntax-entry ?% "'")
;;; eval: (put (intern "lambda#") 'scheme-indent-function 1)
;;; End:
