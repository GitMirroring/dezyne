;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017, 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
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

(define-module (gaiag commands verify)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag om)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag util)
  #:use-module (gaiag config)
  #:use-module (gaiag json2scm)
  #:use-module (gaiag misc)
  #:use-module (gaiag mcrl2)
  #:use-module (gaiag commands parse)
  #:use-module (gaiag resolve)
  #:use-module (gaiag commands code)
  #:use-module (scmcrl2 verification)
  #:use-module (gaiag command-line)
  #:use-module (gaiag resolve)
  #:use-module (gaiag csp)
  #:use-module (gaiag shell-util)
  #:use-module (gash job)
  #:use-module (gash pipe)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((all (single-char #\a))
            (csp)
            (debug (single-char #\d))
            (gaiag (single-char #\G))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (output (single-char #\o) (value #t))
            (queue_size (single-char #\q) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn verify [OPTION]... DZN-FILE [MAP-FILE]...
  -a, --all                   run all checks
      --csp                   use CSP for verification
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           generate main for MODEL
  -o, --output=DIR            write output to DIR (use - for stdout)
  -q, --queue_size=SIZE       use queue size=SIZE for verification [3]
FIXME:  -V, --version=VERSION       use service version=VERSION
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define ((result->string file-name) result)
  (let* ((check (assoc-ref result 'assert))
         (model (assoc-ref result 'model))
         (trace (assoc-ref result 'trace))
         (trace (map symbol->string trace))
         (micro-trace (assoc-ref result 'sequence))
         (trace (apply string-join `(,trace "\n" prefix))))
    (if (pair? micro-trace)
        (let* ((micro-trace (reverse micro-trace))
               (error (car micro-trace))
               (message (assoc-ref error 'message))
               (message (symbol->string message))
               (location (find (lambda (e) (and=> (assoc-ref e 'selection)
                                                  (compose (cut assoc-ref <> 'file) car)))
                               (map cdr micro-trace)))
               (location (and=> (assoc-ref location 'selection) car))
               (file (assoc-ref location 'file))
               (line (assoc-ref location 'line))
               (column (assoc-ref location 'column))
               (index (assoc-ref location 'index)))
          (format (current-error-port) "~a:~a:~a:i~a: ~a\n" file-name line column index message)
          (format #t "xxxverify: ~a: check: ~a: ~a~a\n" model check "fail" trace))
        (let ((gdzn-verbose? (gdzn:command-line:get 'verbose)))
          (if gdzn-verbose?
              (begin (format #t "xxxverify: ~a: check: ~a: ~a~a\n" model check "ok" trace))
              "")))))

(define (models-for-verification root)
  (let* ((models (ast:model* root))
         (components (filter (conjoin (is? <component>) .behaviour) models))
         (component-names (map (compose symbol->string verify:scope-name) components))
         (interfaces (filter (is? <interface>) models))
         (interface-names (map (compose symbol->string verify:scope-name) interfaces))
         (interface-names (let loop ((components components) (interface-names interface-names))
                            (if (null? components) interface-names
                                (let ((component-interfaces (map (compose symbol->string verify:scope-name .type) (ast:port* (car components)))))
                                  (loop (cdr components)
                                        (filter (negate (cut member <> component-interfaces)) interface-names)))))))
    (append interface-names component-names)))

(define (verify-model-csp options dir file-name root model-name)
  (let* ((all? (option-ref options 'all #f))
         (gdzn-debug? (gdzn:command-line:get 'debug))
         ;; FIXME: see traces.scm: modeel->traces
         (csp (with-output-to-string (lambda () (om->csp root #:file-name "-" #:separate-asserts? #f))))
         (tmp ".")
         (models (filter (is? <model>) (.elements root)))
         (model (if model-name (find (csp:mangle-named (string->symbol model-name)) models)
                    (find .behaviour (append (om:filter (is? <component>) root)
                                             (om:filter (is? <interface>) root)))))
         (tmp.csp (string-append tmp "/" model-name ".csp"))
         (fdr2.stderr (string-append tmp "/fdr2.stderr"))
         (modelchecker.stderr (string-append tmp "/modelchecker.stderr"))

         (foo (with-output-to-file tmp.csp (lambda () (display csp))))
         (fdr2-command (list "bash" "-c" (string-append "fdr2 batch -depth 2 -refusals -report auto " tmp.csp " 2>" fdr2.stderr ";exit 0")))
         (all? (command-line:get 'all))
         (gdzn-verbose? (gdzn:command-line:get 'verbose))
         (commands (list fdr2-command
                         (list "bash" "-c" (string-append %service-dir "/scripts/modelchecker 2>" modelchecker.stderr)))))
    (if gdzn-debug? (stderr "commands:~s\n" commands))
    (receive (job port)
        (apply pipeline #f commands)

      (let* ((trails (let loop ()
                       (let ((line (read-line port)))
                         (if (eof-object? line) '()
                             (receive (model assert ok/fail trail)
                                 (apply values (string-split line #\:))
                               (let ((fail? (equal? ok/fail "fail")))
                                 (when (or gdzn-verbose? fail?)
                                   (stdout line)
                                   (newline))
                                 (if (or all? (not fail?)) (cons line (loop))
                                     (list line))))))))
             (status (wait job))
             (status (or (status:term-sig status) (status:exit-val status))))
        (if (not (zero? status))
            (begin
              (stderr "gdzn verify failed:")
              (display (gulp-file (if (access? modelchecker.stderr R_OK) modelchecker.stderr fdr2.stderr)))
              '(error))
            trails)))))

(define error? 0)
(define (verify-csp options dir file-name ast)
  (let* ((root (csp:parse->om ast))
         (model (option-ref options 'model #f))
         (models (if model (list model) (models-for-verification root)))
         (all? (option-ref options 'all #f)))
    (if (not (zero? (system "fdr2 batch >&/dev/null")))
        (begin
          (set! error? 1)
          (stderr "verification is offline while fdr2 is being replaced by mcrl2"))
        (let loop ((models models) (traces '()))
          (if (and (or (null? models) (not all?)) (pair? traces)) (set! error? 1))
          (if (pair? models)
              (loop (cdr models) (append traces (verify-model-csp options dir file-name root (car models)))))))))

(define (verify-mcrl2 options dir file-name ast)
  (let* ((model (option-ref options 'model #f))
         (root ((compose ast:resolve tick-names parse->om) ast))
         (models (if model (list model) (models-for-verification root)))
         (all? (option-ref options 'all #f))
         (module (resolve-module `(gaiag mcrl2)))
         (root-> (module-ref module 'root->))
         (gdzn-verbose? (gdzn:command-line:get 'verbose)))
    (let loop ((models models) (errors #f))
      (if (and (or (null? models) (not all?)) errors) (set! error? 1)
          (if (pair? models)
              (let* ((model (find (lambda (o) (equal? ((compose symbol->string verify:scope-name) o) (car models))) (ast:model* root)))
                     (component? (is-a? model <component>))
                     (elements (append (match model
                                         (($ <system>) '())
                                         (_  (list model)))
                                       (filter (negate (is? <model>)) (ast:global* root))
                                       (if component?
                                           (filter (is? <interface>) (ast:model* root))
                                           '()))))
                (if (pair? elements)
                    (let* ((ast-model (make <root> #:elements elements))
                           (root (mcrl2:om ast-model)))
                      (parameterize ((language 'mcrl2))
                        (with-output-to-file "verify.mcrl2" (cut root-> root)))
                      (loop (cdr models) (or (mcrl2:verify dir file-name (car models) root gdzn-verbose? all?))))
                    (loop (cdr models) errors))))))
    ""))

(use-modules (ice-9 pretty-print))
(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (dump? (equal? file-name "-"))
	 (csp? (option-ref options 'csp #f))
         (json? (gdzn:command-line:get 'json))
         (gdzn-debug? (gdzn:command-line:get 'debug))
         (tmp (string-append (tmpnam) "-verify"))
         (cwd (getcwd))
         (dir (if dump? tmp cwd)))
    (setvbuf (current-output-port) 'line)
    (mkdir-p tmp)
    (when dump? (chdir tmp))
    (receive (files importeds)
        (if dump? (dump-model-stream)
            (values files '()))
      (let* ((file-name (car files))
             ;; parse on `original' (when not dump?) file-name, to preserve path in parse errors
             (ast (assert-parse options file-name #:mangle? csp? #:csp? csp?)))
        ;; canonicalize-path so that seqdiag can find original file after chdir'ing
        (when (not dump?) (chdir tmp))
        (if csp?
            (verify-csp options dir file-name ast)
            (verify-mcrl2 options dir file-name ast))))
    (chdir cwd)
    ;;(if (not gdzn-debug?) (delete-file-recursively tmp))
    (exit error?)))
