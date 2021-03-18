;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018, 2019, 2020, 2021 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018, 2021 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018, 2020 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

(define-module (scmcrl2 verification)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (gaiag ast)
  #:use-module (gaiag command-line)
  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag code makreel)
  #:use-module (gaiag lts)
  #:use-module (gaiag misc)
  #:use-module (gaiag shell-util)
  #:use-module (gash pipe)
  #:use-module (json)

  #:export (verification:formats
            verification:partial
            verification:verify
            verify-pipeline))

;;; Commentary:
;;;
;;; '(scmrl2 verification)' implements a mCRL2-base pipeline for
;;; verification of Dezyne models.  Entry point: dzn verify.
;;;
;;; Starting point is from dzn code -l makreel, (gaiag code makreel),
;;; the verification pipeline consists of mCRL2 commands and dzn lts.
;;; The result is reported in plain text or JSON.
;;;
;;; TODO:
;;;   * Do not drop failure event "illegal", keep it as <illegal>,
;;;     together with something like <compliance>, <deadlock>,
;;;     <missing-reply>, <range-error>, <queue-full>, <second-reply>.
;;;   * Cleanup reporting.
;;;
;;; Code:

;;;
;;; Taus.
;;;

(define (interface-taus model)
  (let ((alphabet '("inevitable" "optional")))
    (string-join alphabet ",")))

(define (enum-literal->event o)
  (string-append (makreel:name (.type o)) "_" (.field o)))

(define (event-returns event)
  (let ((type (ast:type event)))
    (match type
      (($ <bool>)
       '("false" "true"))
      (($ <enum>)
       (map enum-literal->event (makreel:enum-fields type)))
      (($ <int>)
       (let* ((range (.range type))
              (from (.from range)))
         (map number->string (iota (1+ (- (.to range) from)) from))))
      (($  <void>)
       '("return")))))

(define (event-alpabet event)
  (cons* (.name event)
         (string-append "qout." (.name event))
         (event-returns event)))

(define (component-taus model)
  (let ((ports (ast:required+async model)))
    (define (port-taus port)
      (let* ((interface (.type port))
             (port-name (makreel:.name port))
             (alphabet (append-map event-alpabet (ast:event* interface))))
        (map (cute string-append port-name "." <>) alphabet)))
    (string-join (append-map port-taus ports) ",")))

(define (compliance-taus model)
  (define (provides-taus port)
    (let ((port-name (makreel:.name port)))
      (map (cute string-append port-name "." <>) '("inevitable" "optional"))))
  (define (requires-taus port)
    (let* ((interface (.type port))
           (port-name (makreel:.name port))
           (alphabet (append-map event-alpabet (ast:event* interface)))
           (alphabet (cons* "<flush>"  "inevitable" "optional" "qout.ack" alphabet)))
      (map (cute string-append port-name "." <>) alphabet)))
  (let* ((provides-ports (ast:provides-port* model))
         (requires-ports (ast:required+async model))
         (taus (append (append-map provides-taus provides-ports)
                       (append-map requires-taus requires-ports))))
    (string-join taus ",")))

(define (deterministic-labels component)
  (define (trigger->event trigger)
    (let ((port (.port trigger)))
      (string-append (makreel:.name (.port trigger))
                     (if (ast:async? trigger) ".qout." ".")
                     (.event.name trigger))))
  (let* ((triggers (ast:in-triggers component))
         (alphabet (map trigger->event triggers)))
    (string-join alphabet ",")))

(define (hide-internal-labels trace)
  (let ((trace (string-map (lambda (c) (if (eq? c #\newline) #\; c)) trace)))
    (string-join
     (filter (lambda (event)
               (and (not (member event '("inevitable" "optional" "tau" ;;"<illegal>" "<declarative-illegal>"
                                         )))
                    (not (string-contains event ".qout."))
                    (not (find (cute string-suffix? <> event) '(".optional" ".inevitable")))))
             (string-split trace #\;))
     "\n")))

(define (hide-illegal-labels trace)
  (let ((trace (string-map (lambda (c) (if (eq? c #\newline) #\; c)) trace)))
    (string-join
     (filter (lambda (event)
               (not (member event '("<illegal>" "<declarative-illegal>"))))
             (string-split trace #\;))
     "\n")))


;;;
;;; Verify pipeline.
;;;

(define-immutable-record-type <options>
  (make-options root model init)
  options?
  (root options-root)
  (model options-model)
  (init options-init))

(define (get-commands in-out.pipeline format) ;target-format -> commands
  (define (get-input in-out.pipeline format) ;target-format -> input
    (any
     (match-lambda (((from to) . command)
                    (and (equal? to format) from)))
     in-out.pipeline))
  (define (get-command in-out.pipeline format) ;target-format -> command
    (any
     (match-lambda (((from to) . command)
                    (and (equal? to format) command)))
     in-out.pipeline))
  (reverse
   (let loop ((format format))
     (let ((command (get-command in-out.pipeline format)))
       (if (not command) '()
           (cons command
                 (loop (get-input in-out.pipeline format))))))))

(define root+model->makreel
  (pure-funcq
   (lambda (root model)
     (with-output-to-string (cute makreel:model->makreel root model)))))

(define (in-out:dzn->makreel options)
  (let* ((root (options-root options))
         (model (options-model options))
         (makreel (root+model->makreel root model)))
    (cute display makreel)))

(define (in-out:dzn->aut+provides-aut options)
  (let* ((model (options-model options))
         (root (options-root options))
         (provides-init (get-init model #:provides? #t)))
    (cute display
          (string-append
           (verify-pipeline "aut-failures" root model)
           "\n\x04\n"
           (verify-pipeline "aut-failures" root model #:init provides-init)))))

(define (in-out:makreel->mcrl2 options)
  `("m4-cw" ,(string-append "--define=init_process=" (options-init options))))

(define in-out:mcrl2->lps
  '("mcrl22lps" "--quiet" "--binary"))

(define in-out:lps->lpsconstelm
  '("lpsconstelm" "--quiet" "--remove-singleton-sorts" "--remove-trivial-summands"))

(define in-out:lpsconstelm->lpsparelm
  '("lpsparelm"))

(define in-out:lpsparelm->aut
  '("lps2lts" "--quiet" "--cached" "--out=aut""--save-at-end" "-" "-"))

(define in-out:aut->aut-weak-trace
  '("ltsconvert" "-eweak-trace" "--in=aut" "--out=aut"))

(define in-out:aut->aut-dpweak-bisim
  '("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut"))

(define (in-out:aut-makreel->aut options)
  (let* ((model (options-model options))
         (model-name (makreel:name model))
         (prefix (string-append model-name ".")))
    `(,%dzn "lts" "--cleanup"
            ,@(if (is-a? model <interface>) `("--prefix" ,prefix) '()))))

(define in-out:aut-dpweak-bisim->aut-failures
  `(,%dzn "lts" "--failures" "-"))

(define (model-taus options)
  (let* ((model (options-model options))
         (taus (if (is-a? model <interface>) (interface-taus model)
                   (component-taus model))))
    (if (string-null? taus) '()
        (list (string-append "--tau=" taus)))))

(define (in-out:aut-dpweak-bisim->verify-interface options)
  (let ((taus (model-taus options)))
    `(,%dzn "lts" "--single-line" "--deadlock" ,@taus "--livelock" "-")))

(define (in-out:aut-dpweak-bisim->verify-component options)
  (let* ((taus (model-taus options))
         (model (options-model options))
         (deterministic (deterministic-labels model)))
    `(,%dzn "lts" "--single-line"
            "--nondet" ,deterministic ;; XXX Rename --determinism
            "--illegal" "<illegal>"
            "--deadlock" ,@taus
            "--livelock"
            "--failures"
            "-")))

(define (in-out:aut+provides-aut->verify-compliance options)
  (let* ((model (options-model options))
         (taus (compliance-taus model))
         (taus (if (string-null? taus) '()
                   (list (string-append "--tau=" taus)))))
    `("ltscompare" "--quiet" "--counter-example" "--structured-output" "-pweak-failures"
      ,@taus
      "--in1=aut" "--in2=aut" "-" "-")))

(define in-out.pipeline
  `((("dzn"               "makreel")           . ,in-out:dzn->makreel)
    (("makreel"           "mcrl2")             . ,in-out:makreel->mcrl2)
    (("mcrl2"             "lps")               . ,in-out:mcrl2->lps)
    (("lps"               "lpsconstelm")       . ,in-out:lps->lpsconstelm)
    (("lpsconstelm"       "lpsparelm")         . ,in-out:lpsconstelm->lpsparelm)
    (("lpsparelm"         "aut-makreel")       . ,in-out:lpsparelm->aut)
    (("aut-makreel"       "aut")               . ,in-out:aut-makreel->aut)
    (("aut"               "aut-weak-trace")    . ,in-out:aut->aut-weak-trace)
    (("aut"               "aut-dpweak-bisim")  . ,in-out:aut->aut-dpweak-bisim)
    (("aut-dpweak-bisim"  "aut-failures")      . ,in-out:aut-dpweak-bisim->aut-failures)
    (("aut-dpweak-bisim"  "verify-interface")  . ,in-out:aut-dpweak-bisim->verify-interface)
    (("aut-dpweak-bisim"  "verify-component")  . ,in-out:aut-dpweak-bisim->verify-component)
    (("dzn"               "aut+provides-aut")  . ,in-out:dzn->aut+provides-aut)
    (("aut+provides-aut"  "verify-compliance") . ,in-out:aut+provides-aut->verify-compliance)))

(define (verification:formats)
  (map (match-lambda (((from to) . command) to)) in-out.pipeline))

(define* (get-init model #:key provides?)
  (cond ((is-a? model <interface>)
         (let ((name (string-join (ast:full-name model) "")))
           (format #f "~ainterface" name)))
        (provides?
         "provides")
        (else
         "component")))

(define (pretty-verify-pipeline commands out root model)
  "Return a pretty printable string for COMMANDS.  Synthesize dzn code
for MODEL, using ROOT."
  (define (command->string command)
    (define (program->string program)
      (if (and (equal? (basename program) "dzn")
               (getenv "DZN_UNINSTALLED"))
          "./pre-inst-env dzn"
          program))
    (define (arg->string arg)
      (if (string-any (string->char-set "<>;'") arg) (format #f "~s" arg)
          (format #f "~a" arg)))
    (define (imports->string)
      (let* ((options ((@@ (gaiag commands verify) parse-opts)
                       (command:command-line)))
             (imports (multi-opt options 'import)))
        (if (null? imports) ""
            (string-join imports " -I " 'prefix))))
    (let ((file-name (ast:source-file root))
          (model-name (makreel:unticked-dotted-name model)))
      (match command
        (((and (? string?) program) args ...)
         (let ((program (program->string program)))
           (format #f "~a ~a" program (string-join (map arg->string args)))))
        ((? (const (equal? out "verify-compliance")))
         (format #f "~a verify --model=~a --out=aut+provides-aut~a ~a"
                 (program->string %dzn) model-name (imports->string) file-name))
        (_
         (format #f "~a code --language=makreel --model=~a~a ~a"
                 (program->string %dzn) model-name (imports->string)
                 file-name)))))
   (string-join (map command->string commands) " \\\n  | "))

(define* (verify-pipeline out root model #:key (init (get-init model)))
  "Create a verify pipeline to produce OUT from MODEL.  Use standard
init for MODEL unless INIT."
  (define ((prepare options) next result)
    (let ((next (if (procedure? next) (next options) next)))
      (cons next result)))
  (let* ((options (make-options root model init))
         (commands (get-commands in-out.pipeline out))
         (commands (reverse (fold (prepare options) '() commands))))
    (when (dzn:command-line:get 'debug)
      (format (current-error-port) "~a\n"
              (pretty-verify-pipeline commands out root model)))
    (pipeline->string commands)))


;;;
;;; Report.
;;;

(define (result-split result)
  (map (cut string-split <> #\:) (string-split result #\newline)))

(define (get-line key result)
  (let ((key (symbol->string key)))
    (car (filter (lambda (line) (equal? key (car line))) result))))

(define (get-lts result)
  (let* ((line (get-line 'failures result)))
    (string-join (string-split (cadr line) #\;) "\n")))

(define (get-trace assert result)
  (let* ((line (get-line assert result))
         (trace (and (equal? (cadr line) "fail") (string-join (string-split (cadddr line) #\;) "\n")))
         (trace (and trace (hide-internal-labels trace))))
    trace))

(define (get-info assert result)
  (string-split (caddr (get-line assert result)) #\,))

(define (report-ok model-type model-name assert info)
  (let* ((verbose? (dzn:command-line:get 'verbose))
         (states (car info))
         (transitions (car (cdr info))))
    (if (not (dzn:command-line:get 'json))
      (when verbose?
        (format #t "verify: ~a: check: ~a: ok\n" model-name assert))
      (format #t "~a\n"
         (scm->json-string `((model . ,model-name)
                             (type . ,model-type)
                             (assert . ,assert)
                             (status . done)
                             (result . ok)
                             (states . ,states)
                             (transitions . ,transitions)))))
  #f))

(define (report-fail model-type model-name assert info trace interface-trace)
  (define (remove-flushes trace)
    (filter (negate (cut string-contains <> "<flush>")) trace))
  (define (drop-queue-full-tail trace)
    (append (take-while (negate (cut equal? "<queue-full>" <>)) trace) (list "<queue-full>")))
  (let* ((states (car info))
         (transitions (car (cdr info)))
         (trace (filter (negate string-null?) (string-split trace #\newline)))
         (last-el (and (pair? trace) (last trace)))
         (second-last (and (pair? trace)
                           (pair? (drop-right trace 1))
                           (last (drop-right trace 1))))
         (last (and last-el (string->symbol last-el)))
         (error (case assert
                   ((deadlock) (cond
                                 ((member last '(<range-error> <type-error> <missing-reply> <second-reply> <incomplete>)) last)
                                 ((find (cut equal? "<queue-full>" <>) trace) '<queue-full>)
                                 (else assert)))
                   (else assert)))
         (message (case error
                   ((illegal) (format #f "illegal action performed in model ~a" model-name))
                   ((deterministic) (format #f "component ~a is non-deterministic due to overlapping guards" model-name))
                   ((compliance) (format #f "component ~a is non-compliant with interface(s) of provides port(s)" model-name))
                   ((<range-error>) (format #f "integer range error in model ~a" model-name))
                   ((<type-error>) (format #f "type error in model ~a" model-name))
                   ((<missing-reply>) (format #f "reply missing from model ~a" model-name))
                   ((<second-reply>) (format #f "double reply in model ~a" model-name))
                   ((<incomplete>) (format #f "model ~a is incomplete: event '~a' not handled" model-name second-last))
                   ((<queue-full>) (format #f "queue full in model ~a" model-name))
                   (else (format #f "~a in model ~a" error model-name))))
         (trace (remove-flushes trace))
         (trace (if (member error '(compliance deadlock deterministic illegal livelock))
                    (append trace (list (cleanup-error (symbol->string error))))
                    trace))
         (trace (if (eq? error '<queue-full>) (drop-queue-full-tail trace) trace))
         (trace (string-join trace "\n"))
         (interface-trace (and interface-trace
                               (string-join (remove-flushes (string-split interface-trace #\n)) "\n"))))
    (if (dzn:command-line:get 'json)
        (format #t "~a\n"
                (scm->json-string (append
                                    `((model . ,model-name)
                                     (type . ,model-type)
                                     (assert . ,assert)
                                     (status . done)
                                     (result . fail)
                                     (error . ,error)
                                     (message . ,message)
                                     (states . ,states)
                                     (transitions . ,transitions)
                                     (trace . ,trace))
                                     (if interface-trace `((interface-trace . ,interface-trace)) `()))))
        (begin
          (when (dzn:command-line:get 'verbose)
            (format #t "verify: ~a: check: ~a: fail\n" model-name assert))
          (format (current-error-port) "error: ~a\n" message)
          (unless (string-null? trace)
            (format #t "~a\n" trace))))
    #t))

(define (report-skip model-type model-name assert)
  (if (not (dzn:command-line:get 'json))
    (when (dzn:command-line:get 'verbose)
      (format #t "verify: ~a: check: ~a: skip\n" model-name assert))
    (format #t "~a\n"
       (scm->json-string `((model . ,model-name)
                           (type . ,model-type)
                           (assert . ,assert)
                           (status . done)
                           (result . skip)))))
  #f)

(define (report assert skip trace interface-trace info model-type model-name)
  (cond (skip  (report-skip model-type model-name assert))
        (trace (report-fail model-type model-name assert info trace interface-trace ))
        (else  (report-ok   model-type model-name assert info))))


;;;
;;; Verify model.
;;;

(define (reduce-or all? l)
  (if all? (fold (cut or <> <>) #f (map (cut <>) l))
      (fold (lambda (e res) (or res (e))) #f l)))

(define (mcrl2:verify-interface-asserts model root)
  (let* ((model-name (makreel:unticked-dotted-name model))
         (result (verify-pipeline "verify-interface" root model))
         (result (result-split result))
         (info (get-info 'deadlock result)))
    (reduce-or (command-line:get 'all)
               (list (cut report 'deadlock #f (get-trace 'deadlock result) #f info 'interface model-name)
                     (cut report 'livelock #f (get-trace 'livelock result) #f info 'interface model-name)))))

(define (mcrl2:verify-compliance root aut model)
  (let* ((output status (verify-pipeline "verify-compliance" root model))
         (lines (and output (string-split output #\newline)))
         (stdout-status (and lines (filter (cut string-prefix? "result: " <>) lines)))
         (stdout-status (and (pair? stdout-status) (car stdout-status)))
         (status (if (and (zero? status)
                          stdout-status
                          (string=? stdout-status "result: true"))
                     0 1))
         (trace (and lines (find (cut string-prefix? "counter_example_weak_failures_refinement: " <>) lines)))
         (trace (and trace (substring trace (1+ (string-index trace #\:)))))
         (trace (and trace (string-trim-both trace)))

         (trace (and trace (hide-internal-labels trace)))
         (trace (and trace (hide-illegal-labels trace)))

         (trace (and trace (if (string-null? trace) trace (string-append trace "\n"))))
         (component-accepts (and lines (find (cut string-prefix? "left-acceptance: " <>) lines)))
         (component-accepts (and component-accepts (substring component-accepts (+ 2 (string-contains component-accepts ": ")))))

         (component-accepts (and component-accepts (hide-internal-labels component-accepts)))
         (component-accepts (and component-accepts (hide-illegal-labels component-accepts)))

         (component-accepts (and component-accepts (string-split component-accepts #\newline)))
         (component-accepts (and component-accepts (sort component-accepts string<?)))
         (interface-accepts (and lines (filter (cut string-prefix? "right-acceptance: " <>) lines)))
         (interface-accepts (and (pair? interface-accepts) (car interface-accepts)))
         (interface-accepts (and interface-accepts (substring interface-accepts (+ 2 (string-contains interface-accepts ": ")))))

         (interface-accepts (and interface-accepts (hide-internal-labels interface-accepts)))
         (interface-accepts (and interface-accepts (hide-illegal-labels interface-accepts)))

         (interface-accepts (and interface-accepts (string-split interface-accepts #\newline)))
         (interface-accepts (and interface-accepts (sort interface-accepts string<?))))
    (when (and (not (zero? status))
               (not trace))
      ;; XXX Avoid "no verification errors found"
      (throw 'programming-error (format #f "status: ~s, trace: ~s\n" status trace)))
    (values trace interface-accepts component-accepts)))

(define (mcrl2:verify-component-asserts model root)
  (let* ((model-name (makreel:unticked-dotted-name model))
         (result status (verify-pipeline "verify-component" root model))
         (result (result-split result))
         (lts (get-lts result))
         (info (get-info 'deterministic result))
         (refinement-trace interface-accepts component-accepts
                           (mcrl2:verify-compliance root lts model)))
    (define (report-assert assert)
      (report assert #f (get-trace assert result) #f info 'component model-name))
    (define (extend-trace trace accepts)
      (if accepts (string-append trace (car accepts) "\n")
          trace))
    (reduce-or (command-line:get 'all)
               (list (cut report-assert 'deterministic)
                     (cut report-assert 'illegal)
                     (cut report-assert 'deadlock)
                     (cut report-assert 'livelock)
                     (cut report 'compliance
                          (or (get-trace 'illegal result) (get-trace 'deadlock result))
                          (extend-trace refinement-trace component-accepts)
                          (extend-trace refinement-trace interface-accepts)
                          info 'component model-name)))))

(define (mcrl2:verify-interface root model-name)
  (let ((model (makreel:get-model root model-name)))
    (mcrl2:verify-interface-asserts model root)))

(define (mcrl2:verify-component root model-name)
  (let* ((component (makreel:get-model root model-name))
         (interfaces (delete-duplicates (map .type (ast:port* component)) ast:eq?))
         (verify-models (append (map (lambda (i) (cut mcrl2:verify-interface-asserts i root)) interfaces)
                                (list (cut mcrl2:verify-component-asserts component root)))))
    (reduce-or (command-line:get 'all) verify-models)))

(define (mcrl2:verify root model-name)
  (let ((model (makreel:get-model root model-name)))
    (cond ((is-a? model <interface>) (mcrl2:verify-interface root model-name))
          ((is-a? model <component>) (mcrl2:verify-component root model-name))
          (else #f))))


;;;
;;; Entry points.
;;;

(define* (verification:partial root model-name #:key out)
  (let ((model (makreel:get-model root model-name)))
    (display (verify-pipeline out root model))))

(define* (verification:verify options root #:key all? model-name)
  (define (model-names-for-verification root)
    (let* ((models (ast:model* root))
           (components (filter (conjoin (is? <component>) (negate ast:imported?) .behaviour) models))
           (component-names (map makreel:unticked-dotted-name components))
           (interfaces (filter (conjoin (is? <interface>) (negate ast:dzn-scope?)) models))
           (interface-names (map makreel:unticked-dotted-name interfaces))
           (interface-names (let loop ((components components) (interface-names interface-names))
                              (if (null? components) interface-names
                                  (let ((component-interfaces (map (compose makreel:unticked-dotted-name .type) (ast:port* (car components)))))
                                    (loop (cdr components)
                                          (filter (negate (cut member <> component-interfaces)) interface-names)))))))
      (append interface-names component-names)))
  (let ((model-names (if model-name (list model-name)
                         (model-names-for-verification root))))
    (let loop ((model-names model-names) (error? #f))
      (if (or (and (not all?) error?) (null? model-names)) (if error? 1 0)
          (let* ((model-name (car model-names))
                 (this-error? (mcrl2:verify root model-name))
                 (error? (or error? this-error?)))
            (loop (cdr model-names) error?))))))
