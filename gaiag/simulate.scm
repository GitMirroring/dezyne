;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag simulate)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)

  #:use-module (gaiag ast)
  #:use-module (gaiag command-line)
  #:use-module (gaiag display)
  #:use-module (gaiag misc)
  #:use-module (gaiag parse)
  #:use-module (gaiag shell-util)
  #:use-module (gaiag vm ast)
  #:use-module (gaiag vm evaluate)
  #:use-module (gaiag vm goops)
  #:use-module (gaiag vm normalize)
  #:use-module (gaiag vm runtime)
  #:use-module (gaiag vm report)
  #:use-module (gaiag vm run)
  #:use-module (gaiag vm step)
  #:use-module (gaiag vm util)
  #:export (repl
            simulate))

;;; Commentary:
;;;
;;; ’simulate’ implements a system simulator using the Dezyne vm.
;;;
;;; Code:

(define (check-provides-compliance pc event trace)
  (let* ((component ((compose .type .ast) (%sut)))
         (trigger (clone (string->trigger event) #:parent component))
         (port-name (cond ((provides-trigger? event) (.port.name trigger))
                          (((compose ast:provides-port .type .ast %sut)) => .name)))
         (port-instance (runtime:port-name->instance port-name))
         (provides-trigger? (provides-trigger? event))
         (port-event (and provides-trigger? (.event.name trigger))))

    (define (port-event? e)
      (and (string? e)
           (match (string-split e #\.)
             (('state state) #f)
             ((port event) (and (equal? port port-name) event))
             (_ #f))))

    (%debug "check-provides-compliance... ~s: ~a\n" port-name event)

    (cond
     ((and (null? trace) (not provides-trigger?))
      '())
     (else
      (let* ((interface ((compose .type .ast) port-instance))

             ;; modeling trace
             (modeling-names (modeling-names interface))
             (ipc (clone pc #:trail '() #:status #f))
             (traces (list (list ipc)))
             (silent-traces (run-silent pc port-instance))
             (traces (append silent-traces traces))
             (modeling-traces (parameterize ((%sut port-instance)
                                             (%strict? #f))
                                (append-map (lambda (trace)
                                              (append-map
                                               (cute run-to-completion trace <>)
                                               modeling-names))
                                            traces)))
             ;; provides trace
             (traces (append traces modeling-traces))
             (port-traces (if (not port-event) '()
                              (parameterize ((%sut port-instance)
                                             (%strict? #f))
                                (append-map (cut run-to-completion <> port-event)
                                            traces))))
             (port-traces (append port-traces
                                  modeling-traces)))

        (when (> (dzn:debugity) 0)
          (%debug "port-traces[~s]:\n" (length port-traces))
          (parameterize ((%sut port-instance))
            (display-trails port-traces)))

        (let* ((port-prefix (format #f "~a." port-name))
               (sut-trail (trace->trail trace))
               (sut-trail (filter (compose (disjoin (cut equal? <> "illegal")
                                                    (cut string-prefix? port-prefix <>))
                                           cdr)
                                  sut-trail)))

          (define (port-trail trace)
            (parameterize ((%sut port-instance)) (trace->trail trace)))

          (define (first-non-match port-trace)
            (define (non-matching-pair? a b)
              (and (not (equal? (cdr a) ((compose last (cut string-split <> #\.) cdr) b))) (cons a b)))

            (let* ((port-trail (port-trail port-trace))
                   (foo (%debug "     port trail : ~s\n" port-trail))
                   (foo (%debug "     port trail : ~s\n" (map cdr port-trail)))
                   (port-name ((compose .name .ast) port-instance))
                   (foo (%debug "      sut trail : ~s\n" (map cdr sut-trail)))
                   (events (map (compose last (cut string-split <> #\.) cdr) sut-trail))
                   (foo (%debug "      sut trail : ~s\n" events)))
              (or (any non-matching-pair? port-trail sut-trail)
                  (let ((port-length (length port-trail))
                        (sut-length (length sut-trail)))
                    (cond ((< port-length sut-length) (cons '(#f) (list-ref sut-trail port-length)))
                          ((> port-length sut-length) (list (list-ref port-trail sut-length) #f))
                          (else #f))))))

          (define (port-acceptance-equal? a b)
            (and (equal? (and=> (caar a) trigger->string)
                         (and=> (caar b) trigger->string))
                 (equal? (cadr a) (cadr b))))

          (let ((port-traces non-compliances
                             (partition (negate first-non-match) port-traces)))
            (cond ((pair? port-traces)
                   (let ((port-pcs (map (compose (cut clone pc #:state <>) .state car) port-traces)))
                     (map (lambda (port-pc)
                            (cons (set-state (car trace) (get-state port-pc port-instance))
                                  (cdr trace)))
                          port-pcs)))
                  ((null? non-compliances)
                   (if (null? trace) '()
                       (list trace)))
                  ((and port-event
                        (not (caar (first-non-match (car non-compliances)))))
                   (list trace))
                  ((and (not port-event)
                        (null? sut-trail))
                   (list trace))
                  (else
                   (let* ((port-acceptances (map first-non-match non-compliances))
                          (port-acceptances (delete-duplicates port-acceptances port-acceptance-equal?))
                          (component-acceptance (or (cadar port-acceptances)
                                                    (and=> (.status pc) .ast)
                                                    (trigger->component-trigger trigger)))
                          (port-acceptances (make <acceptances> #:elements (map caar port-acceptances)))
                          (pc (clone pc
                                     #:previous #f
                                     #:status (make <compliance-error>
                                                #:message "compliance"
                                                #:component-acceptance component-acceptance
                                                #:port port-instance
                                                #:port-acceptance port-acceptances)))
                          (tail (if (null? trace) '() (cdr trace))))
                     (list (cons pc tail))))))))))))

(define-method (check-provides-compliance* (pc <program-counter>) event traces)
  (cond
   ((find (compose (conjoin
                    .status
                    (negate (is-status? <match-error>)))
                   car)
          traces)
    traces)
   ((find (compose pair? .blocked car) traces)
    traces)
   ((null? traces)
    (check-provides-compliance pc event '()))
   (else
    (append-map (cute check-provides-compliance pc event <>) traces))))

(define-method (event-traces-alist (pc <program-counter>))
  (define (event->label-traces pc event)
    (let* ((pc (clone pc #:trail '()))
           (traces (parameterize ((%exploring? #t)
                                  (%strict? #f))
                     (run-to-completion* pc event))))
      (cons event traces)))
  (map (cute event->label-traces pc <>) (labels)))

(define-method (is-not-deadlock? (pc <program-counter>))
  (conjoin (negate .status)
           (lambda (new)
             (or (null? (.blocked pc))
                 (and (pair? (.blocked pc))
                      (or (.released new)
                          (null? (.blocked new))))))))

(define-method (eligible-labels (pc <program-counter>) event-traces-alist)
  (let ((eligible-traces
         (filter (match-lambda
                   ((event)
                    #f)
                   ((event (pcs tails ...) ...)
                    (find (is-not-deadlock? pc) pcs)))
                 event-traces-alist)))
    (map car eligible-traces)))

(define-method (check-deadlock (pc <program-counter>) event-traces-alist event)
  (define (mark-deadlock pc)
    (let* ((error (.status pc))
           (ast (or (and error (.ast error))
                    (let ((model (.type (.ast (%sut)))))
                      (.behaviour model)))))
      (if (and error (not (is-a? error <implicit-illegal-error>))) pc
          (clone pc #:status (make <deadlock-error> #:ast ast #:message "deadlock")))))
  (cond
   ((and (is-a? (%sut) <runtime:port>)
         (let ((interface (.type (.ast (%sut)))))
           (and (null? (ast:in-event* interface))
                (list (list (mark-deadlock pc)))))))
   (else
    (and
     (pair? event-traces-alist)
     (let* ((pcs-alist (map
                        (match-lambda
                          ((event traces ...)
                         (cons event (map car traces))))
                      event-traces-alist))
          (valid-pcs-alist (map
                            (match-lambda
                              ((event pcs ...)
                               (cons event (filter (is-not-deadlock? pc) pcs))))
                            pcs-alist))
          (valid-pcs (append-map cdr valid-pcs-alist)))
     (and (null? valid-pcs)
          (let* ((traces (assoc-ref event-traces-alist event))
                 (traces (if (pair? traces) traces (list (list pc)))))
            (map (cute rewrite-trace-head mark-deadlock <>) traces))))))))

(define-method (run-state (pc <program-counter>) (state <list>))
  (let ((pc (set-state pc state)))
    (serialize (.state pc) (current-output-port))
    (newline)
    (list (list pc))))

(define-method (run-component (pc <program-counter>) event)
  (let ((traces (run-to-completion* pc event)))
    (check-provides-compliance* pc event traces)))

(define (run-sut pc)
  (let* ((event pc ((%next-input) pc))
         (pc (clone pc #:instance #f)))
    (%debug "run-sut pc: ~s\n" pc)
    (%debug "     event: ~s\n" event)
    (match event
      (('state state ...)
       (run-state pc state))
      ((? string?)
       (if (is-a? (%sut) <runtime:port>) (run-to-completion* pc event)
           (run-component pc event)))
      (else
       '()))))

(define* (run-trail trail #:key deadlock-check? locations? trace verbose?)
  "Run TRAIL on (%SUT) and produce a trace on STDOUT."
  (define (trail-input pc)
    (let ((trail (.trail pc)))
      (if (null? trail) (values #f pc)
          (let* ((event (car trail))
                 (trail (cdr trail)))
            (%debug "  pop trail ~s ~s\n" event trail)
            (values event (clone pc #:trail trail))))))
  (define (deadlock-report pc traces)
    (let ((event pc ((%next-input) pc)))
      (let* ((event-traces-alist (event-traces-alist pc))
             (eligible (eligible-labels pc event-traces-alist))
             (traces (or (check-deadlock pc event-traces-alist event)
                         traces)))
        (report traces
                #:eligible eligible
                #:locations? locations?
                #:trace trace
                #:verbose? verbose?))))
  (let ((pc (make-pc #:trail trail)))
    (when (equal? trace "trace")
      (serialize-header (.state pc) (current-output-port))
      (newline))
    (report (list (list pc)) #:trace trace #:header #t)
    (parameterize ((%next-input (if (pair? trail) trail-input read-input)))
      (let loop ((pcs (list pc)))
        (let* ((traces (map run-sut pcs))
               (all-traces (apply append traces))
               (valid-traces (filter (compose (negate .status) car) all-traces)))
          (cond
           ((null? valid-traces)
            (cond
             ((and deadlock-check? (null? all-traces))
              (for-each (cute deadlock-report <> '()) pcs))
             (deadlock-check?
              (for-each deadlock-report pcs traces))
             (else
              (report all-traces
                      #:eligible #t
                      #:locations? locations?
                      #:trace trace
                      #:verbose? verbose?))))
           (else
            (report valid-traces
                    #:locations? locations?
                    #:trace trace
                    #:verbose? verbose?)
            (let ((pcs (map car valid-traces)))
              (loop pcs)))))))))


;;;
;;; Repl helpers
;;;

(define %pc (make-parameter #f))
(define %traces (make-parameter (list)))

(define-method (next-step (pc <program-counter>) event)
  (list (begin-step pc event)))

(define-method (next-step (trace <list>) event)
  (let* ((pc (car trace))
         (pc (begin-step pc event)))
    (list pc)))

(define-method (next-step (pc <program-counter>))
  (step pc (.statement pc)))

(define-method (next-step (trace <list>))
  (let* ((pc (car trace))
         (pcs (step pc (.statement pc))))
    (map (cut cons <> trace) pcs)))

(define-method (next event)
  (%traces (append-map (cut next-step <> event) (%traces)))
  (%pc (map car (%traces)))
  (%pc))

(define-method (next)
  (next (%traces)))

(define-method (next (traces <list>))
  (%traces (append-map (cut next-step <>) (%traces)))
  (%pc (map car (%traces)))
  (%pc))

(define (n . rest)
  (if (and (null? rest)
           (or (not (%pc))
               (every rtc? (%pc)))) (format (current-error-port) "labels: ~a\n" (labels))
               (let ((pcs (apply next rest)))
                 (when (pair? pcs)
                   (let ((trail (trace->trail (car pcs))))
                     (when (pair? trail)
                       (format #t "~a\n" (cdr trail)))))
                 pcs)))


;;;
;;; Entry points
;;;

(define* (repl file-name #:optional model-name)
  "Entry point REPL, try: C-c C-a (repl \"system_hello.dzn\") RET (n \"h.hello\") RET."
  #!
  ;; Start Emacs inside [Guix] environment or set it after
  ;; echo $GUIX_ENVIRONMENT  => <profile>
  M-x guix-set-emacs-environment <profile> RET
  ;; POSSIBLY (See https://lists.gnu.org/archive/html/guix-patches/2020-09/msg00203.html)
  ;; set exec path:
  (setq exec-path (getenv "PATH"))
  (setq geiser-guile-binary "<profile>/bin/guile")

  ;; then
  C-c C-a
  (repl "system_hello.dzn")
  (n "h.hello")
  (n)
  !#
  (let* ((%test-dir (string-append (dirname (getcwd)) "/test"))
         (file-name (search-path
                     (cons "." (find-files (string-append %test-dir "/all") #:directories? #t))
                     file-name))
         (root (file->ast file-name))
         (root (vm:normalize root)))
    (%sut (runtime:get-sut root (ast:get-model root model-name)))
    (%instances (runtime:system* (%sut)))
    (%pc (list (make-pc)))
    (%traces (list (%pc)))
    (%next-input read-input)
    (%pc)))

(define* (simulate* root trail #:key deadlock-check? model-name queue-size
                    strict? trace locations? verbose?)
  "Entry point for simulate library: start simulate session for MODEL,
following TRAIL.  When STRICT?, the trail must include all observable
events.  When deadlock-check?, run check-deadlock at the end."
  (let ((root (vm:normalize root)))
    (when (> (dzn:debugity) 0)
      (set! %debug? #t))
    (when (> (dzn:debugity) 1)
      (ast:pretty-print root (current-error-port)))
    (parameterize ((%strict? strict?)
                   (%sut (runtime:get-sut root (ast:get-model root model-name))))
      (parameterize ((%instances (runtime:system* (%sut))))
        (run-trail trail
                   #:deadlock-check? deadlock-check?
                   #:locations? locations?
                   #:trace trace
                   #:verbose? verbose?)))))

(define* (simulate root #:key deadlock-check? model-name queue-size strict?
                   trace trail locations? verbose?)
  "Entry-point for the command module: dzn simulate: start simulate
session for MODEL, following TRAIL.  When STRICT?, the trail must
include all observable events.  When deadlock-check?, run check-deadlock
at the end."
  (let ((trail (and=> (or trail
                          (and (not (isatty? (current-input-port)))
                               (input-port? (current-input-port))
                               (read-string (current-input-port)))
                          "")
                      string->trail)))
    (simulate* root trail
               #:deadlock-check? deadlock-check?
               #:model-name model-name
               #:queue-size queue-size
               #:strict? strict?
               #:trace trace
               #:locations? locations?
               #:verbose? verbose?)))
