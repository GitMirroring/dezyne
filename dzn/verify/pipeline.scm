;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018, 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
;;;
;;; Commentary:
;;;
;;; Code:

(define-module (dzn verify pipeline)

  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn commands verify)
  #:use-module (dzn config)
  #:use-module (dzn goops)
  #:use-module (dzn makreel)
  #:use-module (dzn misc)
  #:use-module (dzn shell-util)
  #:use-module (dzn verify traces)
  #:use-module (gash job)
  #:use-module (gash pipe)
  #:use-module (json)

  #:export (mcrl2:verify
            verify:file-name
            x:interface-init
            x:component-init))

(define %dzn (if (mingw?) "dzn.cmd" %dzn))

(define* ((om:scope-name #:optional (infix "_")) o)
  (let ((infix (if (symbol? infix) (symbol->string infix)
                   infix)))
    ((->string-join infix) (ast:full-name o))))

(define (x:interface-init o) (format #f "init ~ainterface;" (apply string-append (ast:full-name o))))
(define (x:provides-init o) "init provides;\n")
(define (x:component-init o) "init component;\n")

(define (verify:file-name o)
  (string-append (verify:scope-name o) ".makreel"))

(define (interface-taus model)
  (define (compose-taus names)
    (string-join (append-map (lambda (o) (map (cut string-append o <>) '("silent" "silent_end" "internal" "end"))) names) ","))
  (compose-taus (list (apply string-append (ast:full-name model)))))

(define (component-taus model)
  (define (compose-taus names)
    (string-join (append-map (lambda (o) (map (cut string-append o <>) '("in" "qin" "qout" "reply"))) names) ","))
  (compose-taus (map .name (ast:required+async model))))

(define (compliance-taus model)
  (define (compose-taus names)
    (string-join (append-map (lambda (o) (map (cut string-append o <>) '("in" "internal" "silent" "qin" "qout" "reply" "flush"))) names) ","))
  (compose-taus (map .name (ast:required+async model))))

(define (deterministic-labels component)
  (define (compose-triggers channel dir triggers)
    (map (lambda (t) (string-append (.port.name t) channel "(" ((compose (om:scope-name (string->symbol "")) .type .port) t) "action" "("
                                    ((compose (om:scope-name (string->symbol "")) .type .port) t) dir (.event.name t) ")" ")")) triggers))
  (string-join (append (compose-triggers "in" "in'" (ast:provided-in-triggers component))
                       (compose-triggers "qout" "out'" (append (ast:async-out-triggers component) (ast:required-out-triggers component)))) ","))

;;(define cppflag "-rjittyc")
(define cppflag "")

(define execute
  (let ((job-count 0))
    (lambda (procs)
      "Wrap pipeline->string, inserting a @command{tee} commands when
@var{gdzn:debugity} is non-zero."
      (let* ((debug? (> (gdzn:debugity) 0))
             (job-id (number->string job-count))
             (procs (if (not debug?) procs
                        (fold-right (lambda (proc id lst)
                                      (let ((file (string-append job-id "." id)))
                                        (cons* proc `("tee" ,file) lst)))
                                    '() procs (map number->string (iota (length procs))))))
             (foo (when debug? (with-output-to-file job-id (cut format #t "COMMANDS: ~s\n" procs)))))
        (set! job-count (1+ job-count))
        (pipeline->string procs)))))

(define (reduce-or all? l)
  (if all? (fold (cut or <> <>) #f (map (cut <>) l))
      (fold (lambda (e res) (or res (e))) #f l)))

(define (mcrl2:verify-component model-name ast)
  (let* ((component (find (lambda (x) (equal? (verify:scope-name x) model-name)) (filter (is? <component>) (ast:model* ast))))
         (interfaces (delete-duplicates (map .type (ast:port* component)) ast:eq?))
         (verify-models (append (map (lambda (i) (cut mcrl2:verify-interface i ast)) interfaces)
                                (list (cut mcrl2:verify-component-asserts component ast)))))
    (reduce-or (command-line:get 'all) verify-models)))

(define* (display-binary string #:optional (port (current-output-port)))
  (set-port-encoding! port "ISO-8859-1")
  (display string port))

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
         (trace (and trace (rename-lts-actions trace))))
    trace))

(define (get-info assert result)
  (string-split (caddr (get-line assert result)) #\,))

(define (mcrl2:verify-interface model ast)
  (let* ((model-name ((compose ->string verify:scope-name) model))
         (taus (interface-taus model))
         (file-name (verify:file-name model))
         (intf (with-output-to-string (cut model->mcrl2 ast model)))
         (commands `(,(cut format #t "~a\n~a\n" intf (x:interface-init model))
                     ("m4-cw")
                     ("mcrl22lps" "--quiet" "-b")
                     ("lpsconstelm" "-st")
                     ("lpsparelm")
                     ("lps2lts" "--cached" "--out=aut" "--save-at-end" "-" "-")
                     ("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut")
                     (,%dzn "lts" "--single-line" "--deadlock" "--tau" ,taus "--livelock" "-")))
         (result (execute commands))
         (result (result-split result))
         (info (get-info 'deadlock result)))
    (reduce-or (command-line:get 'all)
               (list (cut report 'deadlock #f (get-trace 'deadlock result) #f info 'interface model-name)
                     (cut report 'livelock #f (get-trace 'livelock result) #f info 'interface model-name)))))

(define (do-refinement lts model-name makreel model)
  (let* ((taus (compliance-taus model))
         (taus (if (string-null? taus) '()
                   (list (string-append "--tau=" taus))))
         (commands `(,(cut format #t "~a\n~a\n" makreel (x:provides-init model))
                     ("m4-cw")
                     ("mcrl22lps" "--quiet" "-b")
                     ("lpsconstelm" "--quiet" "-st")
                     ("lpsparelm")
                     ("lps2lts" "--cached" "--out=aut" "--save-at-end" "-" "-")
                     ("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut")
                     (,%dzn "lts" "--failures" "-")))
         (interface (execute commands))
         (commands `(,(cut format #t "~a\n\x04\n~a" lts interface)
                     ("ltscompare" "--quiet" "--counter-example" "--structured-output" "-pweak-failures" ,@taus "--in1=aut" "--in2=aut" "-" "-"))))
    (receive (output status)
        (execute commands)
      (let* ((lines (and output (string-split output #\newline)))
             (stdout-status (and lines (filter (cut string-prefix? "result: " <>) lines)))
             (stdout-status (and (pair? stdout-status) (car stdout-status)))
             (status (if (and (zero? status)
                              stdout-status
                              (string=? stdout-status "result: true"))
                         0 1))
             (trace (and lines (find (cut string-prefix? "counter_example_weak_failures_refinement: " <>) lines)))
             (trace (and trace (substring trace (1+ (string-index trace #\:)))))
             (trace (and trace (string-trim-both trace)))
             (trace (and trace (rename-lts-actions trace)))
             (trace (and trace (if (string-null? trace) trace (string-append trace "\n"))))
             (component-accepts (and lines (find (cut string-prefix? "left-acceptance: " <>) lines)))
             (component-accepts (and component-accepts (substring component-accepts (+ 2 (string-contains component-accepts ": ")))))
             (component-accepts (and component-accepts (rename-lts-actions component-accepts)))
             (component-accepts (and component-accepts (string-split component-accepts #\newline)))
             (component-accepts (and component-accepts (sort component-accepts string<?)))
             (interface-accepts (and lines (filter (cut string-prefix? "right-acceptance: " <>) lines)))
             (interface-accepts (and (pair? interface-accepts) (car interface-accepts)))
             (interface-accepts (and interface-accepts (substring interface-accepts (+ 2 (string-contains interface-accepts ": ")))))
             (interface-accepts (and interface-accepts (rename-lts-actions interface-accepts)))
             (interface-accepts (and interface-accepts (string-split interface-accepts #\newline)))
             (interface-accepts (and interface-accepts (sort interface-accepts string<?))))
        (when (and (not (zero? status))
                   (not trace))
          ;; XXX Avoid "no verification errors found"
          (throw 'programming-error (format #f "status: ~s, trace: ~s\n" status trace)))
        (values trace interface-accepts component-accepts)))))

(define (extend-trace trace accepts)
  (if accepts (string-append trace (car accepts) "\n")
              trace))

(define (mcrl2:verify-component-asserts model ast)
  (let* ((model-name ((compose ->string verify:scope-name) model))
         (taus (component-taus model))
         (taus (if (string-null? taus) '()
                   `(,(string-append "--tau=" taus))))
         (deterministic (deterministic-labels model))
         (makreel (with-output-to-string (cut model->mcrl2 ast model)))
         (commands `(,(cut format #t "~a\n~a\n" makreel (x:component-init model))
                     ("m4-cw")
                     ("mcrl22lps" "--quiet" "-b")
                     ("lpsconstelm" "-st")
                     ("lpsparelm")
                     ("lps2lts" "--cached" "--out=aut" "--save-at-end" "-" "-")
                     ("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut")
                     (,%dzn "lts" "--single-line"  "--nondet" ,deterministic "--illegal" "illegal" "--deadlock" ,@taus "--livelock" "--failures" "-")))
         (result (execute commands))
         (result (result-split result))
         (lts (get-lts result))
         (info (get-info 'deterministic result)))
    (receive (refinement-trace interface-accepts component-accepts)
        (do-refinement lts model-name makreel model)
      (define (report-assert assert)
        (report assert #f (get-trace assert result) #f info 'component model-name))
      (reduce-or (command-line:get 'all)
        (list (cut report-assert 'deterministic)
              (cut report-assert 'illegal)
              (cut report-assert 'deadlock)
              (cut report-assert 'livelock)
              (cut report 'compliance
                         (or (get-trace 'illegal result) (get-trace 'deadlock result))
                         (extend-trace refinement-trace component-accepts)
                         (extend-trace refinement-trace interface-accepts)
                         info 'component model-name))))))

(define (mcrl2:verify model-name ast)
  (let ((model (find (lambda (x) (equal? (verify:scope-name x) model-name)) (filter (is? <model>) (ast:model* ast)))))
    (cond ((is-a? model <interface>) (mcrl2:verify-interface model ast))
          ((is-a? model <component>) (mcrl2:verify-component model-name ast))
          (else #f))))

(define (report-ok model-type model-name assert info)
  (let* ((verbose? (gdzn:command-line:get 'verbose))
         (states (car info))
         (transitions (car (cdr info))))
    (if (not (gdzn:command-line:get 'json))
      (when verbose?
        (stdout "verify: ~a: check: ~a: ok\n" model-name assert))
      (format #t "~a\n"
         (scm->json-string `((model . ,model-name)
                             (type . ,model-type)
                             (assert . ,assert)
                             (status . done)
                             (result . ok)
                             (states . ,states)
                             (transitions . ,transitions)))))
  #f))

(define (remove-flushes trace)
  (and trace (string-join (filter (negate (cut string-contains <> "<flush>"))
                                  (string-split trace #\newline))
                          "\n")))

(define (report-fail model-type model-name assert info trace interface-trace)
  (let* ((states (car info))
         (transitions (car (cdr info)))
         (trace-list (filter (negate string-null?) (string-split trace #\newline)))
         (last-el (and (pair? trace-list) (last trace-list)))
         (second-last (and (pair? trace-list)
                           (pair? (drop-right trace-list 1))
                           (last (drop-right trace-list 1))))
         (last (and last-el (string->symbol last-el)))
         (error (case assert
                   ((deadlock) (cond
                                 ((member last (list 'range_error 'type_error 'missing_reply 'second_reply 'incomplete)) last)
                                 ((find (cut equal? "queue_full" <>) trace-list) 'queue_full)
                                 (else assert)))
                   (else assert)))
         (message (case error
                   ((illegal) (format #f "illegal action performed in model ~a" model-name))
                   ((deterministic) (format #f "component ~a is non-deterministic due to overlapping guards" model-name))
                   ((compliance) (format #f "component ~a is non-compliant with interface(s) of provides port(s)" model-name))
                   ((range_error) (format #f "integer range error in model ~a" model-name))
                   ((type_error) (format #f "type error in model ~a" model-name))
                   ((missing_reply) (format #f "reply missing from model ~a" model-name))
                   ((second_reply) (format #f "double reply in model ~a" model-name))
                   ((incomplete) (format #f "model ~a is incomplete: event '~a' not handled" model-name second-last))
                   (else (format #f "~a in model ~a" error model-name))))
         (trace (if (equal? last error)
                    (string-join (drop-right trace-list (if (equal? last 'incomplete) 2 1)) "\n")
                    (string-join (take-while (negate (cut equal? "queue_full" <>)) trace-list) "\n")))

         ;; XXX TODO current simulator does not expect flushes; remove
         ;; when new simulator is in place
         (trace (remove-flushes trace))
         (interface-trace (remove-flushes interface-trace)))
    (if (gdzn:command-line:get 'json)
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
          (when (gdzn:command-line:get 'verbose)
            (stdout "verify: ~a: check: ~a: fail\n" model-name assert trace))
          (stderr "error: ~a\n" message)
          (unless (string-null? trace)
            (stdout "~a\n" trace))))
    #t))

(define (report-skip model-type model-name assert)
  (if (not (gdzn:command-line:get 'json))
    (when (gdzn:command-line:get 'verbose)
      (stdout "verify: ~a: check: ~a: skip\n" model-name assert))
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
