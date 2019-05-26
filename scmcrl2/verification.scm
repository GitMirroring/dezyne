;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
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

  #:use-module (gaiag ast)
  #:use-module (gaiag command-line)
  #:use-module (gaiag commands verify)
  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag makreel)
  #:use-module (gaiag misc)
  #:use-module (scmcrl2 traces)
  #:use-module (gash job)
  #:use-module (gash pipe)
  #:use-module (json)

  #:export (mcrl2:verify
            verify:file-name
            x:interface-init
            x:component-init))

(define* ((om:scope-name #:optional (infix '_)) o)
  (let ((infix (if (symbol? infix) infix
                   (string->symbol infix))))
    ((->symbol-join infix) (ast:full-name o))))

(define (x:interface-init o) (format #f "init ~ainterface;" (apply string-append (map symbol->string (ast:full-name o)))))
(define (x:provides-init o) "init provides;\n")
(define (x:component-init o) "init component;\n")

(define (verify:file-name o)
  (string-append (symbol->string (verify:scope-name o)) ".makreel"))

(define (interface-taus model)
  (define (compose-taus names)
    (string-join (append-map (lambda (o) (map (cut string-append o <>) '("silent" "silent_end" "internal" "end"))) names) ","))
  (compose-taus (list (apply string-append (map symbol->string (ast:full-name model))))))

(define (component-taus model)
  (define (compose-taus names)
    (string-join (append-map (lambda (o) (map (cut string-append o <>) '("in" "qin" "qout" "reply"))) names) ","))
  (compose-taus (map (compose symbol->string .name) (ast:required+async model))))

(define (compliance-taus model)
  (define (compose-taus names)
    (string-join (append-map (lambda (o) (map (cut string-append o <>) '("in" "internal" "silent" "qin" "qout" "reply" "flush"))) names) ","))
  (compose-taus (map (compose symbol->string .name) (ast:required+async model))))

(define (deterministic-labels component)
  (define (compose-triggers channel dir triggers)
    (map (lambda (t) (string-append (symbol->string (.port.name t)) channel "(" (symbol->string ((compose (om:scope-name (string->symbol "")) .type .port) t)) "action" "("
                                    (symbol->string ((compose (om:scope-name (string->symbol "")) .type .port) t)) dir (symbol->string (.event.name t)) ")" ")")) triggers))
  (string-join (append (compose-triggers "in" "in'" (ast:provided-in-triggers component))
                       (compose-triggers "qout" "out'" (append (ast:async-out-triggers component) (ast:required-out-triggers component)))) ","))

;;(define cppflag "-rjittyc")
(define cppflag "")

(define (mcrl2:verify-interface dir dzn-file-name interface ast verbose? all?)
  (let* ((asserts (list (mcrl2:verify-interface-deadlock-livelock interface))))
    (let loop ((asserts asserts))
      (if (null? asserts) #f
          (let* ((assert (car asserts))
                 (fail? (apply assert (list dir dzn-file-name ast verbose? all?))))
            (if (or (not fail?) all?) (or (loop (cdr asserts)) fail?)
                fail?))))))

(define (mcrl2:verify-component dir dzn-file-name model-name ast verbose? all?)
  (let* ((component (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <component>) (ast:model* ast))))
         (interfaces (delete-duplicates (map .type (ast:port* component)) ast:eq?))
         (asserts (append
                   (append-map
                    (lambda (i) (list
                                 (mcrl2:verify-interface-deadlock-livelock i)))
                    interfaces)
                   (list
                    (mcrl2:verify-component-deterministic-illegal-deadlock-livelock-refinement component)))))
    (let loop ((asserts asserts))
      (if (null? asserts) #f
          (let* ((assert (car asserts))
                 (fail? (apply assert (list dir dzn-file-name ast verbose? all?))))
            (if (or (not fail?) all?) (or (loop (cdr asserts)) fail?)
                fail?))))))

(define* (display-binary string #:optional (port (current-output-port)))
  (set-port-encoding! port "ISO-8859-1")
  (display string port))

(define (reduce-or all? l)
  (if all? (fold (cut or <> <>) #f (map (cut <>) l))
      (fold (lambda (e res) (or res (e))) #f l)))

(define (result-split result)
  (map (cut string-split <> #\:) (string-split result #\newline)))

(define (get-line key result)
  (car (filter (lambda (line) (equal? key (car line))) result)))

(define (get-lts result)
  (let* ((line (get-line "failures" result)))
    (string-join (string-split (cadr line) #\;) "\n")))

(define (get-trace check result)
  (let* ((line (get-line check result))
         (trace (and (equal? (cadr line) "fail") (string-join (string-split (cadddr line) #\;) "\n")))
         (trace (and trace (rename-lts-actions trace))))
    trace))

(define (get-info check result)
  (string-split (caddr (get-line check result)) #\,))

(define ((mcrl2:verify-interface-deadlock-livelock model) dir dzn-file-name ast verbose? all?)
  (let* ((model-name ((compose ->string verify:scope-name) model))
         (foo (assert-start 'interface model-name 'deadlock verbose?))
         (foo (assert-start 'interface model-name 'livelock verbose?))
         (foo (assert-start 'interface model-name 'deadlock verbose?))
         (taus (interface-taus model))
         (file-name (verify:file-name model))
         (intf (with-output-to-string (cut model->mcrl2 ast model)))
         (foo (with-output-to-file (verify:file-name model) (cut display intf)))
         (commands `(,(cut display intf)
                     ("bash" "-c" ,(format #f "cat - ; echo \"~a\"" (x:interface-init model)))
                     ("m4-cw")
                     ("mcrl22lps" "-b")
                     ("lpsconstelm" "-st")
                     ("lpsparelm")
                     ("bash" "-c" "set -e; lps2lts --cached --out=aut /dev/stdin lts.aut; cat lts.aut")
                     ("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut")
                     ("sed" "-e" "s,\"declarative_illegal\",\"dillegal\",g")
                     (,%lts "--single-line" "--deadlock" "--tau" ,taus "--livelock" "/dev/stdin")
                     ))
         (result (receive (job ports)
                    (apply pipeline+ #f commands)
                  (set-port-encoding! (car ports) "ISO-8859-1")
                   (let ((result (read-string (car ports)))
                         (error (read-string (cadr ports))))
                     (handle-error job error)
                     result)))
         (result (result-split result))
         (info (get-info "deadlock" result)))
    (reduce-or all?
               (list (cut check-deadlock (get-trace "deadlock" result) info dir dzn-file-name 'interface model-name verbose?)
                     (cut check-livelock (get-trace "livelock" result) info dir dzn-file-name 'interface model-name verbose?)))))

(define ((mcrl2:verify-component-deterministic-illegal-deadlock-livelock-refinement model) dir dzn-file-name ast verbose? all?)
  (define (verify-component-refinement lts info model-name ast)
    (let* ((foo (assert-start 'component model-name 'compliance verbose?))
           (taus (compliance-taus model))
           (taus (if (string-null? taus) '()
                     `(,(string-append "--tau=" taus))))
           (commands `(,(cut display lts)
                       ("bash" "-c" "cat > component")))
           (error (receive (job ports)
                      (apply pipeline+ #f commands)
                    (set-port-encoding! (car ports) "ISO-8859-1")
                    (let ((error (read-string (cadr ports))))
                      (handle-error job error)
                      error)))
           (file-name (verify:file-name model))
           (commands `(("bash" "-c" ,(format #f "cat ~a; echo \"~a\"" file-name (x:provides-init model)))
                       ("m4-cw")
                       ("mcrl22lps" "-b")
                       ("lpsconstelm" "-st")
                       ("lpsparelm")
                       ("bash" "-c" "set -e; lps2lts --cached --out=aut /dev/stdin lts.aut; cat lts.aut")
                       ("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut")
                       ("sed" "-e" "s,\"declarative_illegal\",\"dillegal\",g")
                       (,%lts "--failures" "/dev/stdin")
                       ("ltscompare" "--verbose" "--counter-example" "-pweak-failures" ,@taus "--in1=aut" "--in2=aut" "component" "/dev/stdin")))
           (error (receive (job ports)
                      (apply pipeline+ #f commands)
                    (set-port-encoding! (car ports) "ISO-8859-1")
                    (let ((error (read-string (cadr ports))))
                      (handle-error job error)
                      error)))
           (trace (and (string-contains error "is not included in the LTS")
                       (read-string (open-input-file "counter_example_weak_failures_refinement.trc" #:binary #t))))
           (trace (and trace (pipeline->string (cut display-binary trace) '("tracepp"))))
           (trace (and trace (rename-lts-actions trace))))
      (check-compliance error trace info dir dzn-file-name 'component model-name verbose?)))
  (let* ((model-name ((compose ->string verify:scope-name) model))
         (foo (assert-start 'component model-name 'deterministic verbose?))
         (foo (assert-start 'component model-name 'illegal verbose?))
         (foo (assert-start 'component model-name 'deadlock verbose?))
         (foo (assert-start 'component model-name 'livelock verbose?))
         (foo (assert-start 'component model-name 'deterministic verbose?))
         (taus (component-taus model))
         (taus (if (string-null? taus) '()
                   `(,(string-append "--tau=" taus))))
         (deterministic (deterministic-labels model))
         (file-name (verify:file-name model))
         (commands `(,(cut model->mcrl2 ast model)
                     ("tee" ,file-name)
                     ("bash" "-c" ,(format #f "cat - ; echo \"~a\"" (x:component-init model)))
                     ("m4-cw")
                     ("mcrl22lps" "-b")
                     ("lpsconstelm" "-st")
                     ("lpsparelm")
                     ("bash" "-c" "set -e; lps2lts --cached --out=aut /dev/stdin lts.aut; cat lts.aut")
                     ("ltsconvert" "-edpweak-bisim" "--in=aut" "--out=aut")
                     ("sed" "-e" "s,\"declarative_illegal\",\"dillegal\",g")
                     (,%lts "--single-line"  "--nondet" ,deterministic "--illegal" "illegal" "--deadlock" ,@taus "--livelock" "--failures" "/dev/stdin")))
         (result (receive (job ports)
                    (apply pipeline+ #f commands)
                   (set-port-encoding! (car ports) "ISO-8859-1")
                   (let ((result (read-string (car ports)))
                         (error (read-string (cadr ports))))
                     (handle-error job error)
                     result)))
         (result (result-split result))
         (lts (get-lts result))
         (info (get-info "deterministic" result)))
    (reduce-or all?
               (list (cut check-deterministic (get-trace "deterministic" result) info dir dzn-file-name 'component model-name verbose?)
                     (cut check-illegal       (get-trace "illegal"       result) info dir dzn-file-name 'component model-name verbose?)
                     (cut check-deadlock      (get-trace "deadlock"      result) info dir dzn-file-name 'component model-name verbose?)
                     (cut check-livelock      (get-trace "livelock"      result) info dir dzn-file-name 'component model-name verbose?)
                     (cut verify-component-refinement lts info model-name ast)))))

(define (mcrl2:verify dir dzn-file-name model-name ast verbose? all?)
  (let ((model (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model-name)) (filter (is? <model>) (ast:model* ast)))))
    (cond ((is-a? model <interface>) (mcrl2:verify-interface dir dzn-file-name model ast verbose? all?))
          ((is-a? model <component>) (mcrl2:verify-component dir dzn-file-name model-name ast verbose? all?))
          (else #f))))

(define (assert-start model-type model-name assert verbose?)
  (when verbose?
    (if (gdzn:command-line:get 'json)
        (format #t "~a\n"
                (scm->json-string `(((model . ,model-name)
                                     (type . ,model-type)
                                     (assert . ,assert)
                                     (first . "true")
                                     (status . "assert")))))))
  #f)

(define (assert-ok model-type model-name assert info verbose?)
  (let* ((states (car info))
         (transitions (cdr info)))
    (when verbose?
      (if (not (gdzn:command-line:get 'json))
          (stdout "verify: ~a: check: ~a: ok\n" model-name assert)
          (format #t "~a\n"
           (scm->json-string `(((model . ,model-name)
                                (type . ,model-type)
                                (assert . ,assert)
                                (total_states . ,states)
                                (total_transitions . ,transitions)
                                (result . ok)
                                (trace . ,`())
                                (status . "done")))))))
    #f))

(define (assert-fail dir dzn-file-name model-type model-name assert info trace message interface-trace)
  (when interface-trace (with-output-to-file "interface-trace.txt"
                          (cut display (string-join (filter (negate (cut string-contains <> "<flush>")) (string-split interface-trace #\newline)) "\n"))))
  (let* ((interface-trace-file (and interface-trace (canonicalize-path "interface-trace.txt")))
         (verbose? (gdzn:command-line:get 'verbose))
         (message (or message (format #f "~a in model ~a" assert model-name)))
         (trace-list (filter (negate string-null?) (string-split trace #\newline)))
         (last-el (and (pair? trace-list) (last trace-list)))
         (second-last (and (pair? trace-list)
                           (pair? (drop-right trace-list 1))
                           (last (drop-right trace-list 1))))
         (last last-el)
         (message (cond
                   ((equal? last "range_error") (format #f "integer range error in model ~a" model-name))
                   ((equal? last "type_error") (format #f "type error in model ~a" model-name))
                   ((equal? last "missing_reply") (format #f "error reply missing from model ~a" model-name))
                   ((equal? last "second_reply") (format #f "error double reply in model ~a" model-name))
                   ((equal? last "incomplete") (format #f "model ~a is incomplete: event '~a' not handled" model-name second-last))
                   ((find (cut equal? "queue_full" <>) trace-list) "queue full")
                   (else message)))
         (trace-list (filter (negate (cut string-contains <> "<flush>")) trace-list))
         (trace (if (member last '("range_error" "type_error" "missing_reply" "second_reply" "incomplete"))
                    (string-join (drop-right trace-list (if (member last '("incomplete")) 2 1)) "\n")
                    (string-join (take-while (negate (cut equal? "queue_full" <>)) trace-list) "\n"))))
    (stdout "verify: ~a: check: ~a: fail\n" model-name assert trace)
    (unless (string-null? trace)
      (stdout "~a\n" trace))
    #t))

(define (check-deterministic trace info dir dzn-file-name model-type model-name verbose?)
  (let ((assert 'deterministic))
    (if (not trace) (assert-ok model-type model-name assert info verbose?)
        (let ((message (format #f "Component ~a is non-deterministic due to overlapping guards" model-name)))
          (assert-fail dir dzn-file-name model-type model-name assert info trace message #f)))))

(define (check-illegal trace info dir dzn-file-name model-type model-name verbose?)
  (let ((assert 'illegal))
    (if (not trace) (assert-ok model-type model-name assert info verbose?)
        (let ((message "illegal"))
          (assert-fail dir dzn-file-name model-type model-name assert info trace message #f)))))

(define (check-deadlock trace info dir dzn-file-name model-type model-name verbose?)
  (let ((assert 'deadlock))
    (if (not trace) (assert-ok model-type model-name assert info verbose?)
        (let ((message #f))
          (assert-fail dir dzn-file-name model-type model-name assert info trace message #f)))))

(define (check-livelock trace info dir dzn-file-name model-type model-name verbose?)
  (let ((assert 'livelock))
    (if (not trace) (assert-ok model-type model-name assert info verbose?)
        (let ((message #f))
          (assert-fail dir dzn-file-name model-type model-name assert info trace message #f)))))

(define (check-compliance error trace info dir dzn-file-name model-type model-name verbose?)
  (let ((assert 'compliance))
    (if (not trace) (assert-ok model-type model-name assert info verbose?)
        (let* ((trace (string-trim-right trace))
               (trace (if (string-null? trace) trace (string-append trace "\n")))
               (component-accepts (cond ((string-match "The acceptance of the left process is empty." error) #f)
                                        ((string-match "A stable acceptance set of the left process is:\n([^\n]*)\n" error) => (cut match:substring <> 1))
                                        ((string-match "is not included in the LTS in" error) "")
                                        (else (stderr "other string:~s\n" error))))
               (component-accepts (and component-accepts (rename-lts-actions component-accepts)))
               (component-trace (if component-accepts (string-append trace component-accepts "\n")
                                    trace))
               (component-trace-file "component-trace.txt")
               (interface-accepts (cond ((string-match "The process at the right has no acceptance sets" error) #f)
                                        ((string-match "An acceptance set of the right process is:\n([^\n]*)\n" error) =>  (cut match:substring <> 1))
                                        ((string-match "is not included in the LTS in" error) "")
                                        (else (stderr "other string:~s\n" error))))
               (interface-accepts (and interface-accepts (rename-lts-actions interface-accepts)))
               (interface-trace (if interface-accepts (string-append trace interface-accepts "\n")
                                    trace))
               (interface-trace-file "interface-trace.txt")
               (message (format #f "Component ~a is non-compliant with interface of provided port" model-name)))
          (assert-fail dir dzn-file-name model-type model-name assert info component-trace message interface-trace)))))
