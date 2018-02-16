;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
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

(define-module (scmcrl2 verification)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (gaiag command-line)
  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag util)
  #:use-module (gaiag mcrl2)
  #:use-module (gaiag misc)
  #:use-module (gaiag resolve)
  #:use-module (gaiag xpand)
  #:use-module (scmcrl2 traces)
  #:use-module (gash pipe)
  #:use-module (json)

  #:export (mcrl2:verify
            verify:scope-name
            component-lts))

(define (verify:scope-name o)
  ((om:scope-name '.) o))

(define (compliance-hidden-actions)
  (list "return" "optional" "inevitable" "event" "flush"))

(define (livelock-hidden-actions)
  (list "return" "event" "flush"))

(define (find-taus component model-name hidden-actions)
  (let ((req-ports (if component (map (lambda (r) (.name r)) (om:required component))
                       '())))
    (string-join (append-map (lambda (p)
			       (let ((portname (symbol->string p)))
				 (map (lambda (h)
					(string-append portname "'" h) )
				      hidden-actions)))
			     req-ports)
		 "," 'infix)))

(define-method (mcrl2:init ast template)
  (let ((module (make-module 31 `(,(resolve-module '(gaiag deprecated code))
                                  ,(resolve-module '(gaiag mcrl2))))))
    (module-define! module 'ast ast)
    (parameterize ((template-dir (string-append %template-dir "/mcrl2")))
      (with-output-to-string (lambda () (x:pand template ast module))))))

(define (assert-system command)
  (let ((status (system (string-append "set -o pipefail; " command))))
    (or (zero? status)
        (begin
          (stderr "verify failed: ~a\n" command)
          (exit 1)))))

(define (create-lps mcrl2 lpstype ast)
  (let ((lps (string-append (basename mcrl2 ".mcrl2") "_" (->string lpstype) ".lps")))
    (match lpstype
      ('deterministic (assert-system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'determinism-init@ast) " | mcrl22lps -b  2> mcrl22lps-deterministic.stderr > " lps)))
      ('deadlock (assert-system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'component-deadlock-init@ast) " | mcrl22lps -b 2> mcrl22lps-component-deadlock.stderr > " lps)))
      ('component (assert-system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'component-init@ast) " | mcrl22lps -b 2> mcrl22lps-component.stderr > " lps)))
      ('interface (assert-system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'interface-init@ast) " | mcrl22lps -b 2> mcrl22lps-interface.stderr > " lps)))
      ('interface-lts (assert-system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'interface-lts-init@ast) " | mcrl22lps -b 2> mcrl22lps-interface.stderr > " lps)))
     ('provided (assert-system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'compliance-init@ast) " | mcrl22lps -b 2> mcrl22lps-provided.stderr > " lps))))
    (reduce-lps lps)))

(define (create-if-lps mcrl2 lpstype ast)
  (let ((lps (string-append (basename mcrl2 ".mcrl2") "_" ((compose ->string verify:scope-name) ast) ".lps")))
    (assert-system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'interface-init@ast) " | mcrl22lps -b > " lps))
    (reduce-lps lps)))

(define (reduce-lps lps)
  (assert-system (string-append "lpsconstelm -st " lps " " lps))
  (assert-system (string-append "lpsparelm " lps " " lps))
  lps)

(define* (reduce-lts lts #:optional trace)
  (if trace
      (begin
        (assert-system (string-append "ltsconvert -eweak-trace " lts " " lts))
        lts)
      (begin
        (assert-system (string-append "ltsconvert -edpbranching-bisim " lts " " lts))
        lts)
      ))

(define (component-lts model-name ast)
  (let* ((component (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <component>) (.elements ast))))
         (interface (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <interface>) (.elements ast))))
         (lps (create-lps "verify.mcrl2" (if component 'component 'interface-lts) (if component ast interface)))
         (lts (create-lts lps))
         (lts (reduce-lts lts #t)))
    lts))

;;(define cppflag "-rjittyc")
(define cppflag "")

(define (create-lts lps)
  (system (string-append "lps2lts -v " cppflag " --cached " lps " " (basename lps ".lps") ".aut 2>&1"))
  (string-append (basename lps ".lps") ".aut"))

(define (verifydeterministic lps)
  (let* ((ltsname (string-append (basename lps ".lps") ".aut"))
         (lps2lts (list "lps2lts" "--nondeterminism" cppflag "--cached" "--trace" lps ltsname))
         (commands (list "bash" "-c" (string-append (string-join lps2lts " ") " 2>&1"))))
    (pipeline->string commands)))

(define (verifydeadlock lps)
  (let* ((lps2lts (list "lps2lts"
                        "--deadlock" "-t1" cppflag "--cached" "-v" lps (string-append (basename lps ".lps") ".aut")))
         (commands (list "bash" "-c" (string-append (string-join lps2lts " ") " 2>&1"))))
    (pipeline->string commands)))

(define (verifyillegal lps)
  (let* ((lps2lts (list "lps2lts"
                        "-aillegal" "-t1" "-v" cppflag "--cached" lps (string-append (basename lps ".lps") ".aut")))
         (commands (list "bash" "-c" (string-append (string-join lps2lts " ") " 2>&1"))))
    (pipeline->string commands)))

(define (verifylivelock lps taus)
  (let* ((lps2lts (list "lps2lts"
                        "--divergence" "-t1" "-v" cppflag "--cached" (string-append "--tau=\"" taus "\"") lps (string-append (basename lps ".lps") ".aut")))
         (commands (list "bash" "-c" (string-append (string-join lps2lts " ") " 2>&1"))))
    (pipeline->string commands)))

  ;; (blockingcall (string-append "lps2lts --divergence -t1 -v "  "--tau=\"" taus "\" " lps " " (basename lps ".lps") ".aut 2>&1")))

(define (verifyrefinement complps provlps taus)
  (let* ((provlts (string-append (basename provlps ".lps") ".aut"))
	 (complts (string-append (basename complps ".lps") ".aut")))
    (assert-system (string-append "lps2lts " cppflag " --cached " provlps " " provlts))
    (assert-system (string-append "sed -i -e 's/\"illegal\"/\"dillegal\"/g' " provlts))
    (assert-system (string-append "lps2lts " cppflag " --cached " complps " " complts))
    (reduce-lts provlts)
    (reduce-lts complts)
    (let* ((ltscompare (list "ltscompare" "-v" "-c" "-pweak-failures"
                             (string-append "--tau=\"" taus "\"")
                             complts
                             provlts))
           (commands (list "bash" "-c" (string-append (string-join ltscompare " ") " 2>&1"))))
      (pipeline->string commands))))

(define (verifyall lps taus)
  (blockingcall (string-append "lps2lts -aillegal --deadlock --divergence -t1 -v " cppflag " --cached --tau=\"" taus "\" " lps " " (basename lps ".lps") ".aut 2>&1")))

(define (blockingcall command)
  (stderr "blockingcall: check exit status, use pipeline ~a\n" command)
  (throw 'blockingcall)
  (let* ((port (open-input-pipe command))
	 (str (read-string port)))
    (close-pipe port)
    str))

(define (mcrl2:verify-interface file-name interface verbose?)
  (let* ((iflps (create-if-lps "verify.mcrl2" 'interface interface))
         (output (verifydeadlock iflps))
         (output (string-append output (verifylivelock iflps ""))))
    (interpret-if-results output file-name ((compose ->string verify:scope-name) interface) verbose?)))

(define (mcrl2:verify-component file-name model-name ast verbose? all?)
  (let* ((component (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <component>) (.elements ast))))
         (interfaces (delete-duplicates (map .type (om:ports component))))
         (livelock-taus (find-taus component model-name (livelock-hidden-actions)))
         (compliance-taus (find-taus component model-name (compliance-hidden-actions)))
         (deterministic-lps (create-lps "verify.mcrl2" 'deterministic ast))
         (provided-lps (create-lps "verify.mcrl2" 'provided ast))
         (deadlock-lps (create-lps "verify.mcrl2" 'deadlock ast))
         (lpsfile (create-lps "verify.mcrl2" 'component ast))
         (output (verifydeterministic deterministic-lps))
	 (output (string-append output (verifyillegal lpsfile)))
         (output (string-append output (verifydeadlock deadlock-lps)))
         (output (string-append output (verifylivelock lpsfile livelock-taus)))
         (output (string-append output (verifyrefinement lpsfile provided-lps compliance-taus))))
    (if all?
        (pair? (filter identity (append (map (cut mcrl2:verify-interface file-name <> verbose?) interfaces)
                                        (list (interpret-results output file-name model-name verbose?)))))
        (or (pair? (filter identity (map (cut mcrl2:verify-interface file-name <> verbose?) interfaces)))
            (interpret-results output file-name model-name verbose?)))))

(define (mcrl2:verify-component file-name model-name ast verbose? all?)
  (let* ((component (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <component>) (.elements ast))))
         (interfaces (delete-duplicates (map .type (om:ports component))))
         (asserts (append
                   (append-map
                    (lambda (i) (list
                                 (mcrl2:verify-interface-deadlock i)
                                 (mcrl2:verify-interface-livelock i)))
                    interfaces)
                   (list
                    (mcrl2:verify-component-deterministic component)
                    (mcrl2:verify-component-illegal component)
                    (mcrl2:verify-component-deadlock component)
                    (mcrl2:verify-component-livelock component)
                    (mcrl2:verify-component-refinement component)))))
    (let loop ((asserts asserts))
      (if (null? asserts) #f
          (let* ((assert (car asserts))
                 (fail? (apply assert (list file-name ast verbose? all?))))
            (if (or (not fail?) all?) (or (loop (cdr asserts)) fail?)
                fail?))))))

(define ((mcrl2:verify-interface-deadlock model) file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
 	 (foo (assert-start 'interface model-name 'deadlock verbose?))
         (lpsfile (create-if-lps "verify.mcrl2" 'interface model))
         (result (verifydeadlock lpsfile)))
    (if (number? result) (exit result)
        (check-deadlock result file-name model-name verbose?))))

(define ((mcrl2:verify-interface-livelock model) file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
 	 (foo (assert-start 'interface model-name 'livelock verbose?))
         (livelock-taus "")
         (lpsfile (create-if-lps "verify.mcrl2" 'interface model))
         (result (verifylivelock lpsfile livelock-taus)))
    (if (number? result) (exit result)
        (check-livelock result file-name model-name verbose?))))

(define ((mcrl2:verify-component-deterministic model) file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
 	 (foo (assert-start 'component model-name 'determinisic verbose?))
         (deterministic-lps (create-lps "verify.mcrl2" 'deterministic ast))
         (result (verifydeterministic deterministic-lps)))
    (if (number? result) (exit result)
        (check-deterministic result file-name model-name verbose?))))

(define ((mcrl2:verify-component-illegal model) file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
 	 (foo (assert-start 'component model-name 'illegal verbose?))
         (lpsfile (create-lps "verify.mcrl2" 'component ast))
         (result (verifyillegal lpsfile)))
    (if (number? result) (exit result)
        (check-illegal result file-name model-name verbose?))))

(define ((mcrl2:verify-component-deadlock model) file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
 	 (foo (assert-start 'component model-name 'deadlock verbose?))
         (lpsfile (create-lps "verify.mcrl2" 'deadlock ast))
         (result (verifydeadlock lpsfile)))
    (if (number? result) (exit result)
        (check-deadlock result file-name model-name verbose?))))

(define ((mcrl2:verify-component-livelock model) file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
 	 (foo (assert-start 'component model-name 'livelock verbose?))
         (livelock-taus (find-taus model model-name (livelock-hidden-actions)))
         (lpsfile (create-lps "verify.mcrl2" 'component ast))
         (result (verifylivelock lpsfile livelock-taus)))
    (if (number? result) (exit result)
        (check-livelock result file-name model-name verbose?))))

(define ((mcrl2:verify-component-refinement model) file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
 	 (foo (assert-start 'component model-name 'compliance verbose?))
         (compliance-taus (find-taus model model-name (compliance-hidden-actions)))
         (provided-lps (create-lps "verify.mcrl2" 'provided ast))
         (lpsfile (create-lps "verify.mcrl2" 'component ast))
         (result (verifyrefinement lpsfile provided-lps compliance-taus)))
    (if (number? result) (exit result)
        (check-compliance result file-name model-name verbose?))))

(define (mcrl2:verify file-name model-name ast verbose? all?)
  (if model-name
      (let ((model (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <model>) (.elements ast)))))
        (if (is-a? model <component>)
            (mcrl2:verify-component file-name model-name ast verbose? all?)
            (mcrl2:verify-interface file-name model verbose?)))
      (let ((components (filter (is? <component>) (.elements ast))))
        (pair? (filter identity (map (lambda (c) (mcrl2:verify-component file-name (->string (verify:scope-name c)) ast verbose? all?)) components))))
      ))

(define (interpret-if-results output file-name model-name verbose?)
  (let ((deadlock (check-deadlock output file-name model-name verbose?))
        (livelock (check-livelock output file-name model-name verbose?)))
    (or deadlock livelock)))

(define (interpret-results output file-name model-name verbose?)
  (let ((compliance (check-compliance output file-name model-name verbose?))
        (illegal (check-illegal output file-name model-name verbose?))
        (deadlock (check-deadlock output file-name model-name verbose?))
        (livelock (check-livelock output file-name model-name verbose?))
        (deterministic (check-deterministic output file-name model-name verbose?)))
    (or compliance illegal deadlock livelock deterministic)))

(define (assert-start model-type model-name assert verbose?)
  (when verbose?
    (if (gdzn:command-line:get 'json)
        (format #t "~a###"
                (scm->json-string `(((model . ,model-name)
                                     (type . ,model-type)
                                     (assert . ,assert)
                                     (status . "assert")))))))
  #f)

(define (assert-ok model-type model-name assert verbose?)
  (when verbose?
    (if (not (gdzn:command-line:get 'json))
        (stdout "verify: ~a: check: ~a: ok\n" model-name assert)
        (format #t "~a###"
                (scm->json-string `(((model . ,model-name)
                                     (type . ,model-type)
                                     (assert . ,assert)
                                     (result . ok)
                                     (status . "done")))))))
  #f)

(define (assert-fail file-name model-type model-name assert trace verbose?)
  (if (not (gdzn:command-line:get 'json))
      (stdout "verify: ~a: check: ~a: fail\n~a" model-name assert trace)
      (let* ((cwd (getcwd))
             (foo (chdir (dirname file-name)))
             (commands (list
                        ;;(display trace) ;; FIXME
                        (list "echo" trace)
                        (list "seqdiag" "-m" model-name file-name))))
        (receive (job port)
            (apply pipeline #f commands)
          (let ((json (read-string port)))
            (chdir cwd)
            (format #t "~a###"
                    (scm->json-string `(((model . ,model-name)
                                         (type . ,model-type)
                                         (assert . ,assert)
                                         (sequence . ,(json-string->scm json))
                                         (trace . ,(string-split trace #\newline))
                                         (result . fail)
                                         (status . "done")
                                         (first . true)))))))))
  #t)

(define (assert-fail-compliance file-name model-type model-name assert spec-trace-file impl-trace-file impl-trace verbose?)
  (if (not (gdzn:command-line:get 'json))
      (stdout "verify: ~a: check: ~a: fail\n~a" model-name assert impl-trace)
      (let* ((cwd (getcwd))
             (foo (chdir (dirname file-name)))
             (commands (list
                        ;;(display trace) ;; FIXME
                        ;;(list "echo" trace)
                        (list "seqdiag" "-m" model-name "-s" spec-trace-file "-t" impl-trace-file (basename file-name)))))
        (receive (job port)
            (apply pipeline #f commands)
          (let ((json (read-string port)))
            (chdir cwd)
            (format #t "~a###"
                    (scm->json-string `(((model . ,model-name)
                                         (type . ,model-type)
                                         (assert . ,assert)
                                         (sequence . ,(json-string->scm json))
                                         (trace . ,(string-split impl-trace #\newline))
                                         (result . fail)))))))))
  #t)

(define (check-deterministic string file-name model-name verbose?)
  (let ((match? (regexp-exec (make-regexp "Nondeterministic state found and saved to '([^'\n]*)'.*") string))
        (assert 'deterministic)
        (model-type 'component))
    (if match? (let ((trace (make-trace-file (match:substring match? 1) assert file-name model-name)))
                 (assert-fail file-name model-type model-name assert trace verbose?))
        (assert-ok model-type model-name assert verbose?))))

(define (check-illegal string file-name model-name verbose?)
  (let ((match? (regexp-exec (make-regexp "Detected action 'illegal' .* and saved to '([^'\n]*)'") string))
        (assert 'illegal)
        (model-type 'component))
    (if match? (let ((trace (make-trace-file (match:substring match? 1) assert file-name model-name)))
                 (assert-fail file-name model-type model-name assert trace verbose?))
        (assert-ok model-type model-name assert verbose?))))

(define (check-deadlock string file-name model-name verbose?)
  (let ((match? (regexp-exec (make-regexp "deadlock-detect: deadlock found and saved to '([^'\n]*)'") string))
        (assert 'deadlock)
        (model-type 'component))
    (if match? (let ((trace (make-trace-file (match:substring match? 1) assert file-name model-name)))
                 (assert-fail file-name model-type model-name assert trace verbose?))
        (assert-ok model-type model-name assert verbose?))))

(define (check-livelock string file-name model-name verbose?)
  (let ((match? (regexp-exec (make-regexp "Trace to the divergencing state is saved to '([^'\n]*)") string))
        (assert 'livelock)
        (model-type 'component))
    (if match? (let ((trace (make-trace-file (match:substring match? 1) assert file-name model-name)))
                 (assert-fail file-name model-type model-name assert trace verbose?))
        (assert-ok model-type model-name assert verbose?))))

(define (check-compliance string file-name model-name verbose?)
  (let ((match? (regexp-exec (make-regexp "Saved trace to file (.*)\nThe LTS in (.*) is not included in the LTS .*") string))
        (assert 'compliance)
        (model-type 'component))
    (if match? (let* ((trace (make-trace-file (match:substring match? 1) assert file-name model-name))
                      (impl-accepts (if (string-match "The acceptance of the left process is empty." string) #f
                                        (match:substring
                                         (string-match "A stable acceptance set of the left process is:\n([^\n]*)\n" (pke string))
                                         1)))
                      (impl-accepts (and impl-accepts (rename-lts-actions impl-accepts)))
                      (impl-trace (if impl-accepts (string-append trace impl-accepts "\n")
                                      trace))
                      (impl-trace-file "impl_trace.txt")
                      (spec-accepts (if (string-match "The process at the right has no acceptance sets" string) #f
                                        (match:substring
                                         (string-match "An acceptance set of the right process is:\n([^\n]*)\n" string)
                                         1)))
                      (spec-accepts (and spec-accepts (rename-lts-actions spec-accepts)))
                      (spec-trace (if spec-accepts (string-append trace spec-accepts "\n")
                                      trace))
                      (spec-trace-file "spec_trace.txt"))
                 (with-output-to-file spec-trace-file (cut display spec-trace))
                 (with-output-to-file impl-trace-file (cut display impl-trace))
                 (assert-fail-compliance file-name model-type model-name assert spec-trace-file impl-trace-file impl-trace verbose?))
        (assert-ok model-type model-name assert verbose?))))
