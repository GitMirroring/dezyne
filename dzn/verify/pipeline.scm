;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2018, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2018, 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
;;; Copyright © 2017, 2018 Johri van Eerd <vaneerd.johri@gmail.com>
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

(define-module (dzn verify pipeline)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 poe)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn config)
  #:use-module (dzn goops)
  #:use-module (dzn code makreel)
  #:use-module (dzn lts)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:use-module (dzn pipe)

  #:export (verification:formats
            verification:partial
            verification:verify
            verify-pipeline))

;;; Commentary:
;;;
;;; '(dzn verify pipeline)' implements a mCRL2-base pipeline for
;;; verification of Dezyne models.  Entry point: dzn verify.
;;;
;;; Starting point is from dzn code -l makreel, (dzn code makreel),
;;; the verification pipeline consists of mCRL2 commands and dzn lts.
;;; The result is reported in plain text.

;;; Code:

;;;
;;; Taus.
;;;

(define (interface-taus model)
  (let ((alphabet '("inevitable" "optional")))
    (string-join alphabet ",")))

(define (component-taus model)
  (let ((ports (ast:requires+async-port* model)))
    (string-join (map makreel:.name ports) ",")))

(define (component-exclude-taus model)
  (let ((ports (ast:requires-port* model)))
    (define (port-exclude-taus port)
      (let* ((interface (.type port))
             (port-name (makreel:.name port)))
        (list (string-append port-name ".optional") (string-append port-name ".inevitable"))))
    (string-join (append-map port-exclude-taus ports) ",")))

(define (event-alphabet event)
  "Return the labels that may be used in an LTS for EVENT."
  (define (event-returns event)
    "Return the labels that may be used in an LTS for at the return of
EVENT."
    (define (enum-literal->event o)
      (string-append (makreel:name (.type o)) ":" (.field o)))
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
         (if (ast:out? event) '()
             '("return"))))))
  (let ((event-name (.name event)))
    `("<flush>"
      ,event-name
      ,@(event-returns event)
      ,@(if (ast:in? event) '()
            `(,(string-append "qout." event-name))))))

(define (compliance-taus model)
  "Return the list of events to hide, i.e. map to tau, for the provides
compliance check of MODEL: the requires-out triggers and requires-in
actions."
  (define (events-trigger/action o)
    (map (cute string-append (makreel:.name (.port o)) "." <>)
         (event-alphabet (.event o))))
  (let* ((behavior (.behavior model))
         (compound (.statement behavior))
         (trigger-lists (tree-collect-filter
                         (disjoin (is? <declarative>)
                                  (is? <triggers>))
                         (is? <triggers>)
                         compound))
         (out-triggers (filter ast:out?
                               (append-map ast:trigger* trigger-lists)))
         (in-actions (filter ast:in?
                             (tree-collect-filter
                              (negate (is? <location>)) (is? <action>)
                              behavior)))
         (taus (delete-duplicates
                (append-map events-trigger/action
                            (append out-triggers in-actions))))
         (taus (cons "<defer>" taus)))
    (string-join taus ",")))

(define (deterministic-labels component)
  (define (trigger->event trigger)
    (let ((port (.port trigger)))
      (string-append (makreel:.name (.port trigger))
                     (if (or (ast:async? trigger) (ast:out? trigger)) ".qout."
                         ".")
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
                    (not (string-contains event ".<blocking>"))
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
    (lambda _
      (display makreel)
      (newline)
      (display (makreel:init-process (options-init options))))))

(define (in-out:dzn->aut+provides-aut options)
  (let* ((model (options-model options))
         (root (options-root options))
         (provides-init (get-init model #:provides? #t)))
    (cute display
          (string-append
           ;; The first LTS can be produced by running the
           ;; "aut-failures" pipeline.  Running the already memoized
           ;; "verify-component" gives us the same result, and has
           ;; already been memoized.
           (get-lts (result-split (verify-pipeline "verify-component" root model)))
           "\n\x04\n"
           (verify-pipeline "aut-failures" root model #:init provides-init)))))

(define (in-out:dzn->aut-dpweak-bisim-cached options)
  (let* ((model (options-model options))
         (root (options-root options)))
    (cute display (verify-pipeline "aut-dpweak-bisim" root model))))

(define (in-out:mcrl2->lps options)
  (let ((debug? (dzn:command-line:get 'debug)))
    `("mcrl22lps" ,@(if debug? '() '("--quiet")) "--binary")))

(define in-out:lps->lpsconstelm
  '("lpsconstelm" "--quiet" "--remove-singleton-sorts" "--remove-trivial-summands"))

(define in-out:lps->lpsparelm
  '("lpsparelm"))

(define in-out:lps->aut
  '("lps2lts" "--quiet" "--cached" "--out=aut""--save-at-end" "-" "-"))

(define (in-out:aut->aut-weak-trace options)
  (let* ((model (options-model options))
         (model-name (makreel:name model))
         (taus (if (is-a? model <interface>)
                   '("--tau=inevitable,optional")
                   '())))
    `("ltsconvert" "-eweak-trace" ,@taus "--in=aut" "--out=aut")))

(define in-out:aut->aut-dpweak-bisim
  '("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut"))

(define (in-out:maut->aut options)
  (let* ((model (options-model options))
         (model-name (makreel:name model))
         (prefix (string-append model-name ".")))
    `(,%dzn "lts" "--cleanup"
            ,@(if (is-a? model <interface>) `("--prefix" ,prefix) '()))))

(define in-out:aut->aut-failures
  `(,%dzn "lts" "--failures" "-"))

(define (model-taus options)
  (let* ((model (options-model options))
         (taus (if (is-a? model <interface>) (interface-taus model)
                   (component-taus model)))
         (exclude-taus (if (is-a? model <interface>) ""
                           (component-exclude-taus model))))
    (append
      (if (string-null? taus) '()
          (list (string-append "--tau=" taus)))
      (if (string-null? exclude-taus) '()
          (list (string-append "--exclude-tau=" exclude-taus))))))

(define (in-out:aut->verify-interface options)
  (let ((taus (model-taus options)))
    `(,%dzn "lts" "--single-line"
            "--deadlock"
            ,@taus
            "--livelock"
            "-")))

(define in-out:aut->verify-interface-nondet
  `(,%dzn "lts" "--single-line"
          "--deterministic-labels=<state>"))

(define (in-out:aut->verify-component options)
  (let* ((taus (model-taus options))
         (model (options-model options))
         (deterministic (deterministic-labels model)))
    `(,%dzn "lts" "--single-line"
            "--deterministic-labels" ,deterministic
            "--illegal"
            "--deadlock"
            ,@taus
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
  `((("dzn"                     "mcrl2")                   . ,in-out:dzn->makreel)
    (("mcrl2"                   "lps")                     . ,in-out:mcrl2->lps)
    (("lps"                     "lpsconstelm")             . ,in-out:lps->lpsconstelm)
    (("lpsconstelm"             "lpsparelm")               . ,in-out:lps->lpsparelm)
    (("lpsparelm"               "maut")                    . ,in-out:lps->aut)
    (("maut"                    "aut")                     . ,in-out:maut->aut)
    (("maut"                    "maut-weak-trace")         . ,in-out:aut->aut-weak-trace)
    (("maut"                    "maut-dpweak-bisim")       . ,in-out:aut->aut-dpweak-bisim)
    (("maut-weak-trace"         "aut-weak-trace")          . ,in-out:maut->aut)
    (("maut-dpweak-bisim"       "aut-dpweak-bisim")        . ,in-out:maut->aut)
    (("aut-dpweak-bisim"        "aut-failures")            . ,in-out:aut->aut-failures)
    (("dzn"                     "aut-dpweak-bisim-cached") . ,in-out:dzn->aut-dpweak-bisim-cached)
    (("aut-dpweak-bisim-cached" "verify-interface")        . ,in-out:aut->verify-interface)
    (("aut-dpweak-bisim-cached" "aut-weak-trace-cached")   . ,in-out:aut->aut-weak-trace)
    (("aut-weak-trace-cached"   "verify-interface-nondet") . ,in-out:aut->verify-interface-nondet)
    (("aut-dpweak-bisim"        "verify-component")        . ,in-out:aut->verify-component)
    (("dzn"                     "aut+provides-aut")        . ,in-out:dzn->aut+provides-aut)
    (("aut+provides-aut"        "verify-compliance")       . ,in-out:aut+provides-aut->verify-compliance)))

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
      (let ((imports (command-line:get 'import)))
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
         (and (not (string-prefix? "verify-interface" out))
              (string-append
               (format #f "~a code --language=makreel --model=~a~a --init=~s  ~a"
                       (program->string %dzn) model-name (imports->string)
                       (get-init model)
                       file-name)))))))
  (string-join (filter-map command->string commands) " \\\n  | "))

(define* (unmemoized-verify-pipeline out root model #:key (init (get-init model)) stdout?)
  "Create a verify pipeline to produce OUT from MODEL.  Use standard
init for MODEL unless INIT.  When STDOUT?, write result
to (current-output-port)."
  (define ((prepare options) next result)
    (let ((next (if (procedure? next) (next options) next)))
      (cons next result)))
  (let* ((options (make-options root model init))
         (commands (get-commands in-out.pipeline out))
         (commands (reverse (fold (prepare options) '() commands))))
    (when (dzn:command-line:get 'debug)
      (let ((commands (pretty-verify-pipeline commands out root model)))
       (if (equal? out "aut-dpweak-bisim")
           (format (current-error-port) "~a\\\n  | " commands)
           (format (current-error-port) "~a\n" commands))))
    (let* ((pipeline (if stdout? pipeline->port pipeline->string))
           (result status (pipeline commands)))
      (values result status))))

(define verify-pipeline-wrapper
  (lambda* (out root model #:key init)
    (let* ((out (symbol->string out))
           (init (symbol->string init))
           (result status (unmemoized-verify-pipeline
                           out root model #:init init)))
      (list result status))))

(define memoizing-verify-pipeline
  (pure-funcq verify-pipeline-wrapper))

(define* (verify-pipeline out root model #:key (init (get-init model)))
  "Create a verify pipeline to produce OUT from MODEL.  Use standard
init for MODEL unless INIT."
  (let ((out (string->symbol out))
        (init (string->symbol init))
        (debug? (dzn:command-line:get 'debug)))
    (apply values ((if debug? verify-pipeline-wrapper
                       memoizing-verify-pipeline) out root model #:init init))))


;;;
;;; Report.
;;;

(define (result-split result)
  (define (split-colon string)
    (let ((index (string-index string #\:)))
      (if (not index) (list string)
          (list (substring string 0 index)
                (substring string (1+ index))))))
  (define (split-fail line)
    (match line
      ((assert (and (? (cute string-prefix? "fail:" <>)) fail))
       (cons assert (split-colon fail)))
      (_ line)))
  (let ((result (map split-colon (string-split result #\newline))))
    (map split-fail result)))

(define (semi->newline string)
  (string-append (string-map (lambda (c) (if (eq? c #\;) #\newline c)) string) "\n"))

(define (get-line key result)
  (let ((key (symbol->string key)))
    (or (find (compose (cute equal? key <>) car) result)
        (throw 'programming-error (format #f "no such assert: ~s, result: ~s\n" key result)))))

(define (get-lts result)
  (let ((line (get-line 'failures result)))
   (match line
     (("failures" lts)
      (semi->newline lts))
     (_
      (throw 'programming-error (format #f "no failures lts: ~s, line: ~s\n" line result))))))

(define (get-trace key result)
  (let ((assert (get-line key result)))
    (match assert
      ((assert "ok")
       #f)
      ((assert "fail" trace)
       (let ((trace (semi->newline trace)))
         (hide-internal-labels trace)))
      (_
       (throw 'programming-error (format #f "ill-formed assert: ~s, result: ~s\n" assert result))))))

(define (report-ok model assert)
  (let ((verbose? (dzn:command-line:get 'verbose))
        (model-name (makreel:unticked-dotted-name model)))
    (when (dzn:command-line:get 'verbose)
      (format (current-error-port)
              "verify: ~a: check: ~a: ok\n" model-name assert))
    #f))

(define (report-fail model assert trace)
  (define (remove-flushes trace)
    (filter (negate (cut string-contains <> "<flush>")) trace))
  (define (drop-queue-full-tail trace)
    (append (take-while (negate (cut equal? "<queue-full>" <>)) trace) (list "<queue-full>")))
  (let* ((model-name (makreel:unticked-dotted-name model))
         (trace (filter (negate string-null?) (string-split trace #\newline)))
         (last-el (and (pair? trace) (last trace)))
         (second-last (and (pair? trace)
                           (pair? (drop-right trace 1))
                           (last (drop-right trace 1))))
         (last (and last-el (string->symbol last-el)))
         (error (case assert
                  ((deadlock) (cond
                               ((member last '(<range-error> <type-error> <missing-reply> <second-reply>)) last)
                               ((find (cut equal? "<queue-full>" <>) trace) '<queue-full>)
                               (else assert)))
                  ((compliance) 'non-compliance)
                  ((deterministic) 'non-deterministic)
                  (else assert)))
         (message (case error
                    ((illegal) (format #f "illegal action performed in model ~a" model-name))
                    ((non-deterministic)
                     (cond
                      ((is-a? model <interface>)
                       (format #f "interface ~a is unobservably non-deterministic" model-name))
                      ((is-a? model <component>)
                       (format #f "component ~a is non-deterministic due to overlapping guards" model-name))))
                    ((non-compliance) (format #f "component ~a is non-compliant with interface(s) of provides port(s)" model-name))
                    ((<range-error>) (format #f "integer range error in model ~a" model-name))
                    ((<type-error>) (format #f "type error in model ~a" model-name))
                    ((<missing-reply>) (format #f "reply missing from model ~a" model-name))
                    ((<second-reply>) (format #f "double reply in model ~a" model-name))
                    ((<queue-full>) (format #f "queue full in model ~a" model-name))
                    (else (format #f "~a in model ~a" error model-name))))
         (trace (remove-flushes trace))
         (trace (if (member error '(non-compliance deadlock non-deterministic illegal livelock))
                    (append trace (list (cleanup-error (symbol->string error))))
                    trace))
         (trace (if (eq? error '<queue-full>) (drop-queue-full-tail trace) trace))
         (trace (string-join trace "\n")))
    (when (dzn:command-line:get 'verbose)
      (format (current-error-port) "verify: ~a: check: ~a: fail\n" model-name assert))
    (format (current-error-port) "error: ~a\n" message)
    (unless (string-null? trace)
      (format #t "model: ~a\n" model-name)
      (format #t "~a\n" trace))
    #t))

(define (report-skip model assert)
  (let ((verbose? (dzn:command-line:get 'verbose))
        (model-name (makreel:unticked-dotted-name model)))
    (when verbose?
      (format (current-error-port)
              "verify: ~a: check: ~a: skip\n"
              model-name assert))
    #f))

(define (report assert skip trace model)
  (cond (skip  (report-skip model assert))
        (trace (report-fail model assert trace))
        (else  (report-ok   model assert))))


;;;
;;; Verify model.
;;;

(define (reduce-or all? l)
  (if all? (fold (cut or <> <>) #f (map (cut <>) l))
      (fold (lambda (e res) (or res (e))) #f l)))

(define (mcrl2:verify-interface-asserts model root)
  (let* ((model-name (makreel:unticked-dotted-name model))
         (result (string-append
                  (verify-pipeline "verify-interface" root model)
                  (verify-pipeline "verify-interface-nondet" root model)))
         (result (result-split result)))
    (define (report-assert assert)
      (report assert #f (get-trace assert result) model))
    (reduce-or (command-line:get 'all)
               (list (cute report-assert 'deadlock)
                     (cute report-assert 'livelock)
                     (cute report-assert 'deterministic)))))

(define (mcrl2:verify-compliance root model)
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
         (refinement-trace interface-accepts component-accepts
                           (mcrl2:verify-compliance root model)))
    (define (report-assert assert)
      (report assert #f (get-trace assert result) model))
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
                          refinement-trace
                          model)))))

(define (mcrl2:verify-interface root model)
  (mcrl2:verify-interface-asserts model root))

(define (mcrl2:verify-component root model)
  (let* ((component model)
         (interfaces (delete-duplicates (map .type (ast:port* component)) ast:eq?))
         (verify-models (append (map (lambda (i) (cut mcrl2:verify-interface-asserts i root)) interfaces)
                                (list (cut mcrl2:verify-component-asserts component root)))))
    (reduce-or (command-line:get 'all) verify-models)))

(define (mcrl2:verify root model-name)
  (let ((model (makreel:get-model root model-name)))
    (cond ((is-a? model <interface>) (mcrl2:verify-interface root model))
          ((is-a? model <component>) (mcrl2:verify-component root model))
          (else #f))))


;;;
;;; Entry points.
;;;

(define* (verification:partial root model-name #:key out)
  (let ((model (makreel:get-model root model-name)))
    (unmemoized-verify-pipeline out root model #:stdout? #t)))

(define* (verification:verify options root #:key all? model-name)
  (define (model-names-for-verification root)
    (let* ((models (ast:model* root))
           (components (filter (conjoin (is? <component>) (negate ast:imported?) .behavior) models))
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
