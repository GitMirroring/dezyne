;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
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

(define-module (dzn vm util)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 readline)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 string-fun)
  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (dzn config)
  #:use-module (dzn goops)
  #:use-module (dzn ast)
  #:use-module (dzn command-line)
  #:use-module (dzn misc)
  #:use-module (dzn serialize)
  #:use-module (dzn vm ast)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm evaluate)
  #:use-module (dzn vm runtime)
  #:export (%debug
            %debug?
            %next-input
            %queue-size
            %startup-info
            %strict?

            append-port-trace
            action->trigger
            assign
            async-event?
            block
            blocked-on-action?
            blocked-on-boundary-collateral-release
            blocked-on-boundary-provides?
            blocked-on-boundary-reset
            blocked-on-boundary-switch-context
            blocked-on-boundary?
            blocked-port
            blocked-ports
            collateral-block
            defer-event?
            defer-labels
            dequeue
            dequeue-external
            enqueue
            enqueue-external
            external-trigger?
            external-trigger-in-q?
            flush
            get-handling
            get-reply
            get-state
            get-variables
            graft-locals
            in-event?
            is-status?
            label?
            labels
            make-implicit-illegal
            make-pc
            make-system-state
            modeling-names
            out-event?
            pc->hash
            pc->string
            pc->string-state-diagram
            pop-locals
            port-event?
            provides-trigger?
            prune-defer
            push-local
            pc-equal?
            pc->stack
            pop-deferred
            pop-pc
            push-pc
            q-empty?
            read-input
            requires-trigger?
            reset-handling!
            reset-reply
            reset-replies
            rtc-labels
            return-labels
            return-trigger?
            rewrite-trace-head
            rtc-block-pc
            rtc-block-trigger
            rtc-event?
            rtc-program-counter-equal?
            rtc-port
            rtc-trigger
            serialize
            serialize-header
            set-deferred
            set-handling!
            set-reply
            set-state
            set-variables
            show-eligible
            switch-context
            string->q-trigger
            string->trail
            string->trail+model
            string->trigger
            string->value
            trace-head:eq?
            trigger->component-trigger
            trigger->system-trigger
            trigger->port-trigger
            trigger->string
            update-state)
  #:re-export (eval-expression))

(cond-expand
 (guile-3
  (use-modules (ice-9 copy-tree)))
 (else
  #t))

;;;
;;; Commentary:
;;;
;;; Utility functions for the Dezyne VM.
;;;
;;; Code:

;;; Debug facility
(define %debug? (make-parameter #f))

(define-syntax-rule (%debug fmt arg ...)
  (when (%debug?)
    (format (current-error-port) fmt arg ...)))

;;; The size of the component queues and external queues.
(define %queue-size (make-parameter 3))

;; Is the input trail to be matched exactly?
(define %strict? (make-parameter #f))


;;;
;;; Input, labels
;;;

(define (read-input-file)
  (define (helper x)
    (if (eof-object? x) '()
        (cons x (helper (read)))))
  (helper (read)))

(define (string->trail trail)
  (define (event->string o)
    (match o
      ((h t ...) o)
      (_ (format #f "~a" o))))
  (let* ((trail (string-join (string-split trail #\,) " "))
         (trail (with-input-from-string trail read-input-file))
         (trail (map event->string trail))
         (loop-index (list-index (cute equal? <> "<loop>") trail))
         (trail (filter (negate (conjoin
                                 string?
                                 (conjoin
                                  (cute string-prefix? "<" <>)
                                  (negate
                                   (cute equal? <> "<defer>")))))
                        trail))
         (loop  (and loop-index (call-with-values
                                    (cute split-at trail loop-index)
                                  (lambda (a b) b))))
         (trail (if loop (append trail loop loop)
                    trail)))
    trail))

(define (string->trail+model trail)
  (let* ((model-match (string-match "(^[ \n]*model: ?([^ \n,]+))" trail))
         (trail (if model-match
                    (substring trail (match:end model-match))
                    trail))
         (trail (string->trail trail))
         (model (and model-match (match:substring model-match 2))))
    (values trail model)))

(define %next-input (make-parameter (lambda (pc) (values #f pc))))

(define* (show-eligible eligible #:key traces)

  (define (statement->string o)
    (match o
      (($ <variable>) (statement->string (.expression o)))
      (($ <action>) (format #f "~a.~a" (.port.name o) (.event.name o)))))

  (define action-statement?
    (disjoin (is? <variable>) (is? <action>)))

  (define (statement-equal? . statements)
    (and (pair? statements)
         (not (find (negate (cute ast:eq? (car statements) <>)) statements))))

  (when traces
    (let* ((traces (map reverse traces))
           (statement-traces (map (cute map .statement <>) traces))
           (index-common-prefix (apply list-index (cons (negate statement-equal?) statement-traces)))
           (statement (and index-common-prefix
                           (find action-statement?
                                 (reverse (take (car statement-traces) index-common-prefix))))))
      (when statement
        (format (current-error-port) "action: ~a\n"
                (statement->string statement)))))

  (format (current-error-port) "eligible: ~a\n" (string-join eligible))

  (let* ((commands (map car %commands))
         (complete (append commands eligible)))
    (%next-input (lambda (pc)
                   (with-readline-completion-function
                    (make-completion-function complete)
                    (cute read-input pc))))))

(define %commands `((",help" . ,(lambda _ (display %help-info)))
                    (",quit" . ,(lambda _ (exit EXIT_SUCCESS)))
                    (",state" . ,(lambda (pc command)
                                   (write-line (pc->string pc))))
                    (",show" . ,(lambda (pc command)
                                  (cond
                                   ((string-prefix? command ",show c")
                                    (display %copying-info))
                                   ((string-prefix? command ",show v")
                                    (display %startup-info))
                                   ((string-prefix? command ",show w")
                                    (display %warranty-info)))))))
(define %help-info
"Help Commands:

 ,help                    This help.
 ,quit                    Quit this session
 ,state                   Show current state
 ,show w[arranty]         Show details on the lack of warranty.
 ,show c[opying]          Show license details.
 ,show v[ersion]          Show version information.
")

(define %copying-info
  (format #f "~a is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation; either version 3 of the
License, or (at your option) any later version.

~a is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
License for more details.

You should have received a copy of the GNU Affero General Public License
along with ~a.  If not, see <https://www.gnu.org/licenses/>.
" %package-name %package-name %package-name))

(define %startup-info
  (format #f "dzn simulate (~a) ~a
~a
~a comes with ABSOLUTELY NO WARRANTY; for details type `,show w'.
This program is free software, and you are welcome to redistribute it
under certain conditions; type `,show c' for details.
"
          %package-name
          %package-version
          %copyright-info
          %package-name))

(define %warranty-info
  (format #f  "~a is distributed WITHOUT ANY WARRANTY.  The following sections
from the GNU General Public License, version 3, should make that clear.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

See <https://www.gnu.org/licenses/agpl.html>, for more details.
"
          %package-name))

(define-method (read-input pc)
  (let* ((input (if (isatty? (current-input-port))
                    (readline "> ")
                    (read)))
         (input (cond
                 ((and (string? input)
                       (let ((command (any (conjoin
                                            (cute string-prefix? <> input)
                                            identity)
                                           (map car %commands))))
                         (assoc-ref %commands command)))
                  =>
                  (lambda (command)
                    (command pc input)
                    (read-input pc)))
                 ((string? input)
                  (let* ((input (string-trim-both input))
                         (input (if (string-null? input) (read-input pc)
                                    input)))
                    (add-history input)
                    input))
                 ((symbol? input)
                  (symbol->string input))
                 ((eof-object? input)
                  (exit EXIT_SUCCESS))
                 (else
                  #f))))
    (values input pc)))

(define-method (labels)
  (cond
   ((is-a? (%sut) <runtime:port>)
    (let* ((interface ((compose .type .ast %sut)))
           (modeling-names (modeling-names interface)))
      (append (map .name (ast:in-event* interface))
              modeling-names)))
   (else
    (let ((ports (filter
                  (conjoin runtime:boundary-port?
                           runtime:other-port
                           (negate (compose (is? <runtime:foreign>)
                                            .container
                                            runtime:other-port)))
                  (%instances))))
      (append-map
       (lambda (p)
         (map (compose (cute string-append (runtime:dotted-name p) "." <>)
                       .name)
              (filter (if (ast:provides? (.ast p)) ast:in? ast:out?)
                      (ast:event* (.ast p)))))
       ports)))))

(define-method (labels (pc <program-counter>))
  (append (labels) (rtc-labels pc) (return-labels pc) (defer-labels pc)))

(define-method (label? (o <string>))
  (and (member o (labels)) o))

(define-method (label? (o <boolean>))
  #f)

(define-method (defer-labels (pc <program-counter>))
  (if (null? (.defer pc)) '()
      '("<defer>")))

(define-method (return-labels (o <port>))
  (let* ((port (.name o))
         (values (ast:return-values o)))
    (map (compose (cute format #f "~a.~a" port <>) ->sexp) values)))

(define-method (return-labels (o <runtime:port>))
  (return-labels (.ast o)))

(define-method (rtc-labels (pc <program-counter>))
  (let* ((bob-pc (blocked-on-boundary-switch-context pc))
         (bob-statement (.statement bob-pc))
         (released-pc (blocked-on-boundary-collateral-release pc))
         (switched-pc (switch-context released-pc)))
    (if (or (is-a? bob-statement <trigger-return>) (eq? switched-pc pc)) '()
        (let* ((ports (filter (conjoin runtime:boundary-port? ast:provides?)
                              (%instances)))
               (port-names (map (compose .name .ast) ports)))
          (map (cute format #f "~a.<rtc>" <>) port-names)))))

(define-method (return-labels (pc <program-counter>))
  (let* ((blocked (.blocked pc))
         (released (.released pc))
         (blocked-released (filter (compose (cute memq <> released) car)
                                   blocked))
         (release-pcs (map cdr blocked-released))
         (release-ports (map blocked-port release-pcs))
         (blocked-on-boundary (blocked-on-boundary? pc))
         (release-ports (if (not blocked-on-boundary) release-ports
                            (cons blocked-on-boundary release-ports)))
         (release-ports (map .ast release-ports)))
    (append-map return-labels release-ports)))

(define-method (trigger->string o)
  (let* ((event (.event.name o))
         (event (if (equal? event "void") "return" event)))
    (if (.port.name o) (format #f "~a.~a" (.port.name o) event)
        (format #f "~a" event))))

(define-method (trigger->string (o <q-out>))
  (trigger->string (.trigger o)))

(define-method (trigger->string (o <illegal>))
  "illegal")

(define-method (trigger->string (o <initial-compound>))
  "illegal")

(define-method (string->value (type <bool>) (o <string>))
  (let ((value (string-split o #\.)))
    (match value
      ((path ... "true") (make <literal> #:value "true"))
      ((path ... "false") (make <literal> #:value "false")))))

(define-method (string->value (type <int>) (o <string>))
  (let ((value (string-split o #\.)))
    (match value
      ((path ... number) (make <literal> #:value (string->number number))))))

(define-method (string->value (type <enum>) (o <string>))
  (let* ((value (last (string-split o #\.)))
         (enum (string-split value #\:)))
    (match enum
      ((name field) (or (and (equal? (ast:name type) name)
                             (member field (ast:field* type))
                             (make <enum-literal> #:type.name (.name type) #:field field))
                        (let ((message (format #f "invalid enum value: ~s [~s]\n" o (map (cut string-append (ast:name type) ":" <>) (ast:field* type)))))
                          (display message (current-error-port))
                          (throw 'invalid-input message)))))))

(define (modeling-names-unmemoized o)
  (let ((modeling (tree-collect (conjoin (is? <trigger>) ast:modeling?) o)))
    (delete-duplicates (sort (map .event.name modeling) string=?))))

(define-method (modeling-names (o <interface>))
  ((ast:pure-funcq modeling-names-unmemoized) o))

(define-method (modeling-names (o <runtime:port>))
  (modeling-names ((compose .type .ast) o)))

(define-method (modeling-names)
  (modeling-names (%sut)))



;;;
;;; Trigger conversion
;;;

(define-method (action->trigger (o <runtime:port>) (action <action>))
  (clone (make <trigger>
           #:port.name (and (not (.boundary? o)) (.name (.ast o)))
           #:event.name (.event.name action)
           #:location (.location action))
         #:parent (.type (.ast (if (runtime:boundary-port? o) o
                                   (.container o))))))

(define-method (trigger->component-trigger (o <runtime:port>) trigger)
  (let* ((port (.ast o))
         (trigger (clone trigger #:port.name (.name port))))
    (let* ((instance (or (.container o) (%sut))) ;injected
           (model (.type (.ast instance)))
           (location (ast:location model))
           (trigger (clone trigger #:location location)))
      (clone trigger #:parent model))))

(define-method (trigger->component-trigger trigger)
  (let* ((port-name (.port.name trigger))
         (r:port (and port-name (runtime:port-name->instance port-name)))
         (r:component-port (and r:port (runtime:other-port r:port))))
    (and r:component-port
         (trigger->component-trigger r:component-port trigger))))

(define-method (trigger->system-trigger (o <runtime:port>) trigger)
  (trigger->component-trigger o trigger))

(define-method (trigger->system-trigger (component <runtime:component-model>) trigger)
  (let* ((port-name (.port.name trigger))
         (ports (runtime:runtime-port* component))
         (port (find (compose (cute equal? <> port-name) .name .ast) ports))
         (system-port (runtime:other-port port)))
    (and system-port
         (trigger->system-trigger system-port trigger))))

(define-method (trigger->port-trigger (o <runtime:port>) (trigger <trigger>))
  (let* ((interface ((compose .type .ast) o))
         (location (.location interface))
         (trigger (clone trigger #:port.name #f #:location location)))
    (clone trigger #:parent interface)))

(define-method (string->trigger (class <class>) (o <string>))
  "Return (class [PORT-NAME] EVENT-NAME) from O of form [PORT.]EVENT."
  (let* ((model ((compose .type .ast %sut)))
         (location (ast:location model))
         (trigger (match (string-split o #\.)
                    ((event) (make class #:event.name event))
                    ((port event) (make class #:port.name port #:event.name event))
                    ((path ... port event) (make <trigger>
                                             #:port.name (string-join (append path (list port)) ".")
                                             #:event.name event))))
         (trigger (clone trigger #:location location))
         (trigger (clone trigger #:parent model)))
    trigger))

(define-method (string->trigger (o <string>))
  "Return (trigger [PORT-NAME] EVENT-NAME) from O of form [PORT.]EVENT."
  (string->trigger <trigger> o))

(define-method (string->q-trigger (o <string>))
  "Return (q-trigger [PORT-NAME] EVENT-NAME) from O of form [PORT.]EVENT."
  (string->trigger <q-trigger> o))



;;;
;;; Program counter stack
;;;

(define-method (pop-pc (pc <program-counter>))
  (let ((previous (.previous pc)))
    (clone pc
           #:trigger (.trigger previous)
           #:instance (.instance previous)
           #:previous (.previous previous)
           #:statement (.statement previous))))

(define-method (push-pc (pc <program-counter>))
  (clone pc #:previous pc #:statement #f))

(define-method (push-pc (pc <program-counter>) (trigger <trigger>) (instance <runtime:instance>) (statement <statement>))
  (clone pc #:previous pc #:trigger trigger #:instance instance #:statement statement))

(define-method (push-pc (pc <program-counter>) (statement <statement>))
  (clone pc #:previous pc #:statement statement))

(define-method (push-pc (pc <program-counter>) (trigger <trigger>) (instance <runtime:instance>))
  (push-pc pc trigger instance (ast:statement instance)))

(define-method (push-pc (pc <program-counter>) (instance <runtime:instance>) (statement <statement>))
  (clone pc #:previous pc #:instance instance #:statement statement))

(define-method (pc->stack (pc <program-counter>))
  (unfold (negate .previous) identity .previous pc))

(define (pc->statements pc)
  (map .statement (pc->stack pc)))

(define-method (rtc-pc (pc <program-counter>))
  (last (pc->stack)))

(define-method (rtc-block-pc (pc <program-counter>))
  (let loop ((pc pc))
    (let ((trigger (.trigger pc))
          (previous (.previous pc)))
      (if (or (not previous)
              (not (.trigger previous))
              (is-a? (.trigger previous) <q-trigger>)) pc
              (loop previous)))))

(define-method (rtc-block-trigger (pc <program-counter>))
  (.trigger (rtc-block-pc pc)))

(define-method (rtc-triggers (pc <program-counter>))
  (filter identity (unfold (negate .previous) .trigger .previous pc)))

(define-method (rtc-trigger (pc <program-counter>))
  (let ((triggers (rtc-triggers pc)))
    (and (pair? triggers)
         (last triggers))))

(define-method (rtc-port (pc <program-counter>))
  (and=> (rtc-trigger pc) .port))


;;;
;;; Blocking
;;;

(define-method (block (pc <program-counter>) (port <runtime:port>))
  (let* ((id (.id pc))
         (instance (.instance pc))
         (pc (reset-handling! pc))
         (pc (make <program-counter>
               #:async (.async pc)
               #:id (pc:next-id)
               #:blocked (acons port pc (.blocked pc))
               #:collateral (.collateral pc)
               #:collateral-instance (.collateral-instance pc)
               #:collateral-released (.collateral-released pc)
               #:defer (.defer pc)
               #:external-q (.external-q pc)
               #:released (.released pc)
               #:state (.state pc)
               #:trail (.trail pc))))
    (%debug "  ~s ~s <block> ~a [~a] => [~a]\n"
            (name instance)
            (and=> (.trigger pc) trigger->string)
            (runtime:instance->string port)
            id
            (.id pc))
    pc))

(define (blocked-on-action? pc event)
  (match (blocked-on-boundary-entry? pc event)
    ((port . pc)
     (let ((instance (.instance pc))
           (statement (.statement pc)))
       (and instance
            (is-a? statement <action>)
            (let* ((port (.name (.ast instance)))
                   (action (trigger->string statement))
                   (action (format #f "~a.~a" port action)))
              (equal? action event)))))
    (#f
     #f)))

(define-method (blocked-on-boundary? (pc <program-counter>))
  (and=> (blocked-on-boundary-entry? pc) car))

(define-method (blocked-on-boundary? (pc <program-counter>) event)
  (and=> (blocked-on-boundary-entry? pc event) car))

(define-method (blocked-on-boundary-entries (pc <program-counter>))
  (filter (compose (is? <runtime:port>) .instance cdr)
          (.blocked pc)))

(define-method (blocked-on-boundary-entry? (pc <program-counter>))
  (find (compose (is? <runtime:port>) .instance cdr)
        (.blocked pc)))

(define-method (blocked-on-boundary-entry? (pc <program-counter>) event)
  (let* ((trigger (and=> (as event <string>) string->trigger))
         (port (and=> trigger .port))
         (port (and=> port .name)))
    (find (conjoin (compose (is? <runtime:port>) .instance cdr)
                   (disjoin (const (not event))
                            (compose (cute equal? <> port) .name .ast car)))
          (.blocked pc))))

(define-method (blocked-on-boundary-statements (pc <program-counter>))
  (map (compose .statement cdr)
       (blocked-on-boundary-entries pc)))

(define-method (blocked-on-boundary-collateral-release (pc <program-counter>) event)
  (let ((collateral (.collateral pc))
        (trail (.trail pc))
        (state (.state pc)))
    (match (find
            (compose
             (cute and=> <> (cute blocked-on-boundary? <> event))
             .previous cdr)
            collateral)
      ((port . blocked-pc)
       (or (and (and=> (.previous blocked-pc) blocked-on-boundary?)
                (clone blocked-pc #:state state #:trail trail))
           pc))
      (#f
       pc))))

(define-method (blocked-on-boundary-collateral-release (pc <program-counter>))
  (blocked-on-boundary-collateral-release pc #f))

(define-method (blocked-on-boundary-provides? (pc <program-counter>) event)
  (let ((port (blocked-on-boundary? pc)))
    (and port
         (or (is-a? (%sut) <runtime:component>)
             (let* ((blocked-other-port (runtime:other-port port))
                    (blocked-component (.container blocked-other-port))
                    (trigger (string->trigger event))
                    (port (.port trigger))
                    (r:port (runtime:port (%sut) port))
                    (r:other-port (runtime:other-port r:port))
                    (component (.container r:other-port)))
               (eq? component blocked-component))))))

(define-method (blocked-on-boundary-reset (pc <program-counter>))
  (let* ((blocked (.blocked pc))
         (instance (.instance pc))
         (entry (assq-ref blocked instance)))
    (if (not entry) pc
        (clone pc #:blocked (alist-delete instance blocked)))))

(define-method (blocked-on-boundary-switch-context (pc <program-counter>) event)
  (match (blocked-on-boundary-entry? pc event)
    ((port . blocked-pc)
     (let ((instance (.instance blocked-pc)))
       (if (is-a? instance <runtime:component>) pc
           (begin
             (%debug
              "  ~s ~s <switch-context blocked-on-boundary> ~a [~a] => [~a]\n"
              (name instance)
              (and=> (.trigger blocked-pc) trigger->string)
              (runtime:instance->string port)
              (.id pc)
              (.id blocked-pc))
             (clone pc
                    #:id (.id blocked-pc)
                    #:instance (.instance blocked-pc)
                    #:previous (.previous blocked-pc)
                    #:running-defer? (.running-defer? blocked-pc)
                    #:statement (.statement blocked-pc)
                    #:trigger (.trigger blocked-pc))))))
    (#f
     pc)))

(define-method (blocked-on-boundary-switch-context (pc <program-counter>))
  (blocked-on-boundary-switch-context pc #f))

(define-method (blocked-port (pc <program-counter>))
  (let* ((pc (rtc-block-pc pc))
         (instance (.instance pc))
         (trigger (.trigger pc))
         (r:port (runtime:port instance (.port trigger))))
    (runtime:other-port r:port)))

(define-method (blocked-ports (pc <program-counter>))
  (let ((pcs (map cdr (.blocked pc))))
    (map blocked-port pcs)))

(define-method (blocked-port (pc <program-counter>) (instance <runtime:component>))
  (let ((id (get-handling pc instance)))
    (or (any (match-lambda
               ((port . pc) (and (eq? (.id pc) id) port)))
             (.blocked pc))
        (any (match-lambda
               ((port . pc) (and (eq? (.id pc) id) port)))
             (.collateral pc)))))

(define-method (collateral-block (pc <program-counter>) (instance <runtime:component>))
  (let* ((orig-pc pc)
         (blocked-port (or (blocked-port pc instance)
                           (blocked-on-boundary? (.previous pc))))
         (pc (make <program-counter>
               #:async (.async pc)
               #:id (pc:next-id)
               #:blocked (.blocked pc)
               #:collateral (acons blocked-port pc (.collateral pc))
               #:external-q (.external-q pc)
               #:released (.released pc)
               #:running-defer? (.running-defer? pc)
               #:state (.state pc)
               #:trail (.trail pc))))
    (%debug "  ~s ~s <collateral-block> ~a [~a] => [~a]\n"
            ((compose name .instance) pc)
            (and=> (.trigger pc) trigger->string)
            (runtime:instance->string blocked-port)
            (.id orig-pc)
            (.id pc))
    pc))

(define-method (switch-context (pc <program-counter>))
  (let* ((released (.released pc))
         (r:port (match released ((p t ...) p) (() #f)))
         (blocked (.blocked pc))
         (collateral (.collateral pc))
         (blocked? (assoc-ref blocked r:port))
         (collateral-released (.collateral-released pc))
         (r:port-collateral (match collateral-released ((p t ...) p) (() #f)))
         (released-pc (if blocked? (assoc-ref blocked r:port)
                          (assoc-ref collateral r:port-collateral))))
    (if (or (.status pc) (not released-pc)) pc
        (let* ((collateral (if blocked? collateral
                               (alist-delete r:port-collateral collateral)))
               (instance (.instance released-pc))
               (collateral-instance (if blocked? (.collateral-instance pc)
                                        (.instance released-pc)))
               (collateral-released (if blocked? collateral-released
                                        (delete r:port-collateral collateral-released)))
               (trigger (.trigger released-pc)))
          (%debug "  ~s ~s <switch-context ~a> ~a [~a] => [~a]\n"
                  (name instance)
                  (and=> trigger trigger->string)
                  (if blocked? "block" "collateral")
                  (runtime:instance->string
                   (if blocked? r:port r:port-collateral))
                  (.id pc)
                  (.id released-pc))
          (clone pc
                 #:id (.id released-pc)
                 #:collateral collateral
                 #:collateral-instance collateral-instance
                 #:collateral-released collateral-released
                 #:instance instance
                 #:previous (.previous released-pc)
                 #:statement (.statement released-pc)
                 #:trigger trigger)))))

(define-method (switch-context (trace <list>))
  (let* ((pc (car trace))
         (new-pc (switch-context pc)))
    (if (eq? new-pc pc) trace
        (cons new-pc trace))))


;;;
;;; Q and flush
;;;

(define-method (enqueue (pc <program-counter>)  (ast <ast>) (instance <runtime:component>) (trigger <trigger>))
  (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<enqueue>" (trigger->string trigger))
  (let* ((state (get-state pc instance))
         (q (.q state)))
    (if (= (length q) (%queue-size))
        (let ((error (make <queue-full-error> #:ast ast  #:instance instance
                           #:message "queue-full")))
          (clone pc #:status error))
     (set-deferred (set-state pc (clone state #:q (append q (list trigger)))) instance))))

(define-method (dequeue (pc <program-counter>))
  (let* ((state (get-state pc))
         (q (.q state))
         (pc (set-state pc (clone state #:q (cdr q))))
         (trigger (car q)))
    (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<dequeue>" (trigger->string trigger))
    (values pc trigger)))

(define-method (enqueue-external (pc <program-counter>) (ast <ast>) (trigger <trigger>))
  (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<enqueue-external>" (trigger->string trigger))
  (let* ((external-q (.external-q pc))
         (instance (.instance pc))
         (q (or (assoc-ref external-q instance) '())))
    (if (= (length q) (%queue-size))
        (let ((error (make <queue-full-error> #:ast ast #:instance instance
                           #:message "queue-full")))
          (clone pc #:status error))
        (let* ((external-q (alist-delete instance external-q))
               (external-q (acons instance (append q (list trigger)) external-q))
               (external-q (sort external-q
                                 (match-lambda*
                                   (((port-a q-a ...) (port-b q-b ...))
                                    (string< (name port-a) (name port-b)))))))
          (clone pc #:external-q external-q)))))

(define-method (dequeue-external (pc <program-counter>) (instance <runtime:port>))
  (let* ((external-q (.external-q pc))
         (q (assoc-ref external-q instance)))
    (if (or (not q) (null? q)) (values pc #f)
        (let* ((tail (cdr q))
               (external-q (alist-delete instance external-q))
               (external-q (if (null? tail) external-q
                               (acons instance (cdr q) external-q)))
               (pc (clone pc #:external-q external-q))
               (trigger (car q)))
          (%debug "  ~s ~s ~a => ~s\n" ((compose name .instance) pc) (and=> (.trigger pc) trigger->string) "<dequeue-external>" (trigger->string trigger))
          (values pc trigger)))))

(define-method (get-handling (pc <program-counter>) (instance <runtime:instance>))
  (and=> (get-state pc instance) .handling))

(define-method (set-handling! (pc <program-counter>))
  (set-state pc (clone (get-state pc) #:handling (.id pc))))

(define-method (reset-handling! (pc <program-counter>))
  (set-state pc (clone (get-state pc) #:handling #f)))

(define-method (pop-deferred (pc <program-counter>))
  (let* ((deferred (.deferred (get-state pc)))
         (queue? (not (q-empty? pc deferred)))
         (pc (if queue? pc
                 (set-deferred pc #f))))
    (values deferred pc)))

(define-method (set-deferred (pc <program-counter>) deferred)
  (set-state pc (clone (get-state pc) #:deferred deferred)))

(define-method (prune-defer (pc <program-counter>))
  (define (state-equal? pc defer-pc)
    (define defer-variable-names
      (map .name (ast:defer-variable* (.statement defer-pc))))
    (define defer-variable?
      (match-lambda ((name . expression)
                     (or (null? defer-variable-names)
                         (member name defer-variable-names)))))
    (let* ((instance (.instance defer-pc))
           (defer-members (get-members defer-pc instance))
           (defer-members (filter defer-variable? defer-members))
           (members (get-members pc instance))
           (members (filter defer-variable? members)))
      (or (null? defer-variable-names)
          (ast:equal? members defer-members))))
  (let* ((defer (.defer pc))
         (defer (filter (cute state-equal? pc <>) defer)))
    (clone pc #:defer defer)))

(define-method (flush (pc <program-counter>) instance)
  (%debug "  ~s ~s ~a\n" (name instance) (and=> (.trigger pc) trigger->string) "<flush>")
  (let* ((orig-pc pc)
         (flush-return (make <flush-return>))
         (pc (push-pc pc flush-return))
         (pc (clone pc #:instance instance)))
    (cond
     ((pair? (.q (get-state pc)))
      (let ((pc trigger (dequeue pc)))
        (let* ((q-out (make <q-out> #:trigger trigger))
               (q-out (clone q-out #:location (.location trigger))))
          (push-pc pc trigger instance q-out))))
     (else
      (let ((deferred pc (pop-deferred pc)))
        (cond ((or (not deferred)
                   (get-handling pc deferred))
               orig-pc)
              (else
               (%debug "  flush deferred: ~s\n" deferred)
               (flush pc deferred))))))))

(define-method (flush (pc <program-counter>))
  (flush pc (.instance pc)))


;;;
;;; State / locals / assign
;;;

(define-method (get-state (o <system-state>) (instance <runtime:instance>))
  (find (compose (cute eq? <> instance) .instance) (.state-list o)))

(define-method (get-state (o <program-counter>) (instance <runtime:instance>))
  (get-state (.state o) instance))

(define-method (get-state (o <program-counter>))
  (get-state o (.instance o)))

(define-method (set-state (pc <program-counter>) (o <state>))
  (clone pc #:state (clone (.state pc) #:state-list (map (lambda (x) (if (eq? (.instance o) (.instance x)) o x)) ((compose .state-list .state) pc)))))

(define-method (set-state (pc <program-counter>) (state <list>))
  (fold (cut update-state state <> <>) pc ((compose .state-list .state) pc)))

(define-method (get-reply (pc <program-counter>) (instance <runtime:instance>) (port <string>))
  (assoc-ref (.reply (get-state pc instance)) port))

(define-method (get-reply (pc <program-counter>) (port <string>))
  (get-reply pc (.instance pc) port))

(define-method (reset-reply (pc <program-counter>) (instance <runtime:instance>))
  (set-state pc (clone (get-state pc instance) #:reply '())))

(define-method (reset-reply (pc <program-counter>) (instance <runtime:instance>) (port <string>))
(let ((reply (.reply (get-state pc instance))))
  (set-state pc (clone (get-state pc instance) #:reply (alist-delete port reply)))))

(define-method (reset-reply (pc <program-counter>) (port <string>))
  (reset-reply pc (.instance pc) port))

(define-method (set-reply (pc <program-counter>) (instance <runtime:instance>) (port <string>) value)
  (let ((reply (.reply (get-state pc instance))))
    (set-state pc (clone (get-state pc instance) #:reply (acons port value reply)))))

(define-method (set-reply (pc <program-counter>) (port <string>) value)
  (set-reply pc (.instance pc) port value))

(define-method (reset-replies (pc <program-counter>))
  (if (blocked-on-boundary? pc) pc
      (fold (lambda (instance pc) (reset-reply pc instance))
            pc
            (filter (disjoin (is? <runtime:component>)
                             runtime:boundary-port?)
                    (%instances)))))

(define-method (get-variables (pc <program-counter>))
  ((compose .variables get-state) pc))

(define-method (set-variables (pc <program-counter>) (o <list>))
  (set-state pc (clone (get-state pc) #:variables o)))

(define-method (get-members (pc <program-counter>) instance)
  (let* ((state (get-state pc instance))
         (variables (.variables state))
         (component (runtime:ast-model instance))
         (members (ast:member* component)))
    (take-right variables (length members))))

(define-method (get-locals (pc <program-counter>) instance)
  (let* ((state (get-state pc instance))
         (variables (.variables state))
         (component (runtime:ast-model instance))
         (members (ast:member* component)))
    (drop-right variables (length members))))

(define-method (graft-locals (pc <program-counter>) (from <program-counter>))
  (let* ((instance (.instance from))
         (members (get-members pc instance))
         (locals (get-locals from instance)))
    (set-variables pc (append locals members))))

(define-method (push-local (o <formal>) (e <expression>) (pc <program-counter>))
  (or (and=> (range-error o e) (cut clone pc #:status <>))
      (set-variables pc (acons (.name o) e (get-variables pc)))))

(define-method (push-local (pc <program-counter>) (o <variable>))
  (set-variables pc (acons (.name o) (.expression o) (get-variables pc))))

(define-method (pop-locals (pc <program-counter>) (o <list>))
  (set-variables pc (drop (get-variables pc) (length o))))

(define-method (eval-expression (o <state>) (e <expression>))
  (eval-expression (.variables o) e))

(define-method (eval-expression (pc <program-counter>) (e <expression>))
  (eval-expression (get-state pc) e))

(define-method (range-error o (value <expression>))
  (unless (or (is-a? o <formal>) (is-a? o <variable>))
    (error "range-error" o))
  (let ((type (.type o)))
    (and (is-a? type <int>)
         (let ((range (.range type))
               (value (.value value)))
           (and (or (< value (.from range))
                    (> value (.to range)))
                (let ((parent (.parent (.parent o)))
                      (error (make <range-error>
                               #:ast o #:variable o #:value value
                               #:message "range-error")))
                  (clone error #:parent parent)))))))

(define-method (assign (pc <program-counter>) variable expression)
  (let* ((name (.name variable))
         (state (get-state pc))
         (value (eval-expression state expression))
         (state (clone state #:variables (assoc-set! (copy-tree (.variables state)) name value)))
         (pc (set-state pc state))
         (error (range-error variable value)))
    (if (not error) pc
     (clone pc #:status error))))

(define-method (assign (pc <program-counter>) (variable <variable>) (e <expression>))
  (next-method))

(define-method (assign (pc <program-counter>) (variable <formal>) (e <expression>))
  (next-method))

(define-method (assign (pc <program-counter>) (variable <variable>) (e <action>))
  (let* ((instance (.instance pc))
         (r:port (runtime:port instance (.port e)))
         (other-instance other-port (runtime:other-instance+port instance r:port))
         (port-name (.name (.ast other-port)))
         (reply (get-reply pc other-instance port-name)))
    (assign (reset-reply pc other-instance port-name) variable reply)))

(define-method (assign (pc <program-counter>) (variable <formal>) (e <action>))
  (let* ((instance (.instance pc))
         (r:port (runtime:port instance (.port e)))
         (other-instance other-port (runtime:other-instance+port instance r:port))
         (port-name (.name (.ast other-port)))
         (reply (get-reply pc other-instance port-name)))
    (assign (reset-reply pc other-instance port-name) variable reply)))

(define-method (assign (pc <program-counter>) (variable <variable>) (e <call>))
  (assign pc variable (.return pc)))

(define-method (assign (pc <program-counter>) (variable <formal>) (e <call>))
  (assign pc variable (.return pc)))

(define (rewrite-trace-head rewriter trace)
  (match trace
    ((pc tail ...)
     (cons (rewriter pc) tail))))

(define-method (append-port-trace (pc <program-counter>) trace (port-instance <runtime:port>) port-trace)
  (let* ((ipc (car port-trace))
         (pc (set-state pc (get-state ipc port-instance))))
    (cons pc (cdr trace))))


;;;
;;; Serialise / Deserialise state
;;;

(define-method (serialize (o <system-state>))
  (with-output-to-string
    (lambda _ (cons 'state (serialize o (current-output-port))))))

(define-method (serialize (o <state>))
  (with-output-to-string
    (lambda _
      (serialize o (current-output-port)))))

(define-method (serialize (o <system-state>) port)
  (display "(state " port)
  (for-each (lambda (x) (unless (eq? x ((compose car .state-list) o))
                          (display " " port))
                    (serialize x port))
            (.state-list o))
  (display ")" port))

(define-method (serialize (o <state>) port)
  (let ((path ((compose runtime:instance->path .instance) o)))
    (display "(" port)
    (display path port)
    (unless (equal? path '("client"))
      (for-each (match-lambda ((x . y)
                               (display " " port)
                               (display (cons x (->sexp y)) port)))
                (.variables o)))
    (when (pair? (.q o))
      (display " " port)
      (display `("*q*" . ,(map trigger->string (.q o))) port))
    (display ")" port)))

(define-method (serialize-header (o <system-state>))
  (with-output-to-string
    (lambda _ (cons 'header (serialize-header o (current-output-port))))))

(define-method (serialize-header (o <system-state>) port)
  (display "(header " port)
  (for-each (lambda (x)
              (unless (eq? x ((compose car %instances)))
                (display " " port))
              (serialize-header x port))
            (filter (disjoin (negate (is? <runtime:port>))
                             runtime:boundary-port?)
                    (%instances)))
  (display ")" port))

(define-method (serialize-header (o <runtime:instance>) port)
  (display "(" port)
  (let* ((model (.ast o))
         (name (ast:dotted-name (.type model)))
         (kind (runtime:kind o))
         (path (runtime:instance->path o)))
    (display path port)
    (display " " port)
    (display name port)
    (display " " port)
    (display kind port))
  (display ")" port))

(define (sexp->value v)
  (match v
    ('true (make <literal> #:value "true"))
    ('false (make <literal> #:value "false"))
    ((? number?) (make <literal> #:value v))
    (_ (let ((enum (string-split (symbol->string v) #\:)))
         (match enum
           ((ids ... field)
            (make <enum-literal> #:type.name (make <scope.name> #:ids ids) #:field field))))) ;; FIXME: what about resolving
    ))

(define (update-variable update-list variable pc)
  (let ((name (string->symbol (.name variable))))
    (or (and=> (assoc-ref update-list name)
               (compose (cute assign pc variable <>) sexp->value))
        pc)))

(define (update-state event state pc)
  (let* ((instance (.instance state))
         (path (map string->symbol (runtime:instance->path instance)))
         (update-list (assoc-ref event path))
         (pc (clone pc #:instance instance))
         (variables ((compose ast:variable* .type .ast) instance)))
    (fold (cute update-variable update-list <> <>) pc variables)))


;;;
;;; Hashing state
;;;

(define-method (state->string (o <state>))
  (let* ((instance (.instance o))
         (path (runtime:instance->path instance))
         (path (match path
                 (("sut" path ...) path)
                 (_ path)))
         (variables (map (match-lambda ((x . y)
                                        (format #f "~a=~a" x (->sexp y))))
                         (.variables o)))
         (q (.q o)))
    (and (not (equal? path '("client")))
         (or (pair? variables) (pair? q))
         (string-append
          (string-join path ".")
          (if (pair? path) "=" "")
          "["
          (string-join variables ",\n")
          (if (null? q) ""
              (string-append "q=" (string-join (map trigger->string q) ",")))
          "]"))))

(define-method (state->string (o <system-state>))
  (let* ((state-list (.state-list o))
         (state-list (if (is-a? (%sut) <runtime:port>) state-list
                         (filter (disjoin (compose (is? <runtime:component>) .instance)
                                          (compose ast:requires? .ast .instance))
                                 state-list))))
    (string-join (filter-map state->string state-list) "\n")))

(define-method (async-ports (pc <program-counter>))
  (map (match-lambda ((timeout port . proc)
                      (runtime:dotted-name port)))
       (.async pc)))

(define-method (pc->string (o <program-counter>))
  (match (.status o)
    ((or ($ <illegal-error>) ($ <implicit-illegal-error>))
     "<illegal>")
    (($ <queue-full-error>)
     "<queue-full>")
    ((? identity)
     "<deadlock>")
    (_
     (string-join
      (cons (state->string (.state o))
            (append
             (let* ((instance (.instance o))
                    (statement (.statement o))
                    (defer? (or (as statement <defer>)
                                (as statement <defer-qout>)))
                    (statement (or (as statement <action>)
                                   (as statement <trigger-return>)
                                   defer?)))
               (if (not statement) '()
                   `("instance:" ,(runtime:instance->string instance)
                     ,@(if defer? '()
                           `("statement:" ,(trigger->string statement)))
                     "at:" ,(ast:location->string statement))))
             (let ((triggers (rtc-triggers o)))
               (if (null? triggers) '()
                   `("triggers:" ,@(map trigger->string triggers))))
             (if (null? (.blocked o)) '()
                 '("blocked:"))
             (map (compose runtime:dotted-name car) (.blocked o))
             (let ((blocked (.blocked o)))
               (let* ((pcs (map (compose .previous cdr) blocked))
                      (triggers (filter-map .trigger pcs)))
                 (if (null? triggers) '()
                     (map trigger->string triggers))))
             (if (null? (.collateral o)) '()
                 '("collateral:"))
             (map (compose runtime:dotted-name car) (.collateral o))
             (let ((collateral (.collateral o)))
               (let* ((pcs (map (compose .previous cdr) collateral))
                      (triggers (filter-map .trigger pcs)))
                 (if (null? triggers) '()
                     (map trigger->string triggers))))
             (if (null? (.collateral o)) '()
                 '("blocked-instances:"))
             (map (compose runtime:dotted-name .instance cdr) (.collateral o))
             (let* ((pcs (map cdr (.blocked o)))
                    (statements (append-map pc->statements pcs))
                    (locations (filter-map ast:location->string statements)))
               (map (compose cdr (cute split-after-char-last #\/ <> cons))
                    locations))
             (if (null? (.collateral o)) '()
                 '("collateral-instances:"))
             (map (compose runtime:dotted-name .instance cdr) (.collateral o))
             (let* ((pcs (map cdr (.collateral o)))
                    (statements (append-map pc->statements pcs))
                    (locations (filter-map ast:location->string statements)))
               (map (compose cdr (cute split-after-char-last #\/ <> cons))
                    locations))
             (let ((collateral-instance (.collateral-instance o)))
               (if (not collateral-instance) '()
                   `("collateral-instance:"
                     ,(runtime:instance->string collateral-instance))))
             (if (null? (.released o)) '()
                 '("released:"))
             (map runtime:dotted-name (.released o))
             (if (null? (.collateral-released o)) '()
                 '("collateral-released:"))
             (map runtime:dotted-name (.collateral-released o))
             (if (not (blocked-on-boundary? o)) '()
                 `("blocked-on-boundary:"
                   ,@(map trigger->string (blocked-on-boundary-statements o))))
             (if (null? (.external-q o)) '()
                 (list (external-q->string (.external-q o))))
             (async-ports o)
             (let ((defer (.defer o)))
               (if (null? defer) '()
                   `("defer:"
                     ,@(map (compose pc->string (cute clone <> #:defer '()))
                            defer))))))
      "\n"))))

(define-method (pc->string-state-diagram (o <program-counter>))
  (match (.status o)
    ((or ($ <illegal-error>) ($ <implicit-illegal-error>))
     "<illegal>")
    ((? identity)
     "<deadlock>")
    (_
     (string-join
      (cons (state->string (.state o))
            (append
             (if (null? (.blocked o)) '()
                 `(,(string-append
                     "blocked:"
                     (string-join
                      (map (compose runtime:dotted-name car) (.blocked o))
                      ","))))
             (if (null? (.collateral o)) '()
                 `(,(string-append
                     "collateral:"
                     (string-join
                      (map (compose runtime:dotted-name car) (.collateral o))
                      ","))))
             (map (compose runtime:dotted-name car) (.collateral o))
             (async-ports o)))
      "\n"))))

(define-method (pc->hash (o <program-counter>))
  (string-hash (pc->string o)))


;;;
;;; Predicates
;;;

(define-method (is-status? (type <class>))
  (lambda (pc) (is-a? (.status pc) type)))

(define (provides/requires-trigger? string ast:provides/requires? ast:in/out?)
  (let* ((trigger (string->trigger string))
         (event (.event.name trigger)))
    (if (is-a? <runtime:port> (%sut))
        (member event (map .name (filter ast:in/out? (ast:event* (runtime:%sut-model)))))
        (let* ((port-name (.port.name trigger))
               (ports (filter runtime:boundary-port? (%instances)))
               (ports (filter (compose ast:provides/requires? .ast) ports))
               (port (find (compose (cute equal? <> port-name)
                                    runtime:dotted-name)
                           ports))
               (port (and port (.ast port))))
          (and port
               (ast:dotted-name (.type port))
               (let* ((events (filter ast:in/out? (ast:event* port)))
                      (event-names (map .name events)))
                 (member event event-names)))))))

(define (provides-trigger? string)
  (and (string? string) (provides/requires-trigger? string ast:provides? ast:in?)))

(define (requires-trigger? string)
  (and (string? string) (provides/requires-trigger? string ast:requires? ast:out?)))

(define-method (external-trigger? event)
  (and (requires-trigger? event)
       (let ((port (and=> (string->trigger event) .port)))
         (and port (ast:requires? port) (ast:external? port)))))

(define-method (external-trigger-in-q? (pc <program-counter>) event)
  (and (requires-trigger? event)
       (find (match-lambda
               ((port trigger tail ...)
                (equal? (trigger->string trigger) event)))
             (.external-q pc))))

(define-method (return-trigger? event)
  (and (string? event)
       (let ((event (match (string-split event #\.)
                      ((event) event)
                      ((port event) event)
                      ((path ... port event) event))))
         (or (member event '("return" "false" "true"))
             (string->number event)
             (string-index event #\:)))))

(define-method (rtc-event? event)
  (and (string? event)
       (string-suffix? ".<rtc>" event)))

(define-method (in-event? (o <interface>) (event <string>))
  (let* ((events (ast:in-event* o))
         (event-names (map .name events)))
    (member event event-names)))

(define-method (in-event? (o <runtime:port>) (event <string>))
  (in-event? ((compose .type .ast) o) event))

(define-method (in-event? (event <string>))
  (in-event? (%sut) event))

(define-method (out-event? (o <interface>) (event <string>))
  (let* ((events (ast:out-event* o))
         (event-names (map .name events)))
    (member event event-names)))

(define-method (out-event? (o <runtime:port>) (event <string>))
  (out-event? ((compose .type .ast) o) event))

(define-method (out-event? (event <string>))
  (out-event? (%sut) event))

(define (port-event? port-name e)
  (and (string? e)
       (match (string-split e #\.)
         (('state state) #f)
         ((port event) (and (equal? port port-name) event))
         (_ #f))))

(define-method (q-empty? (pc <program-counter>))
  (or (not (.instance pc))
      (null? (.q (get-state pc)))))

(define-method (q-empty? (pc <program-counter>) instance)
  (or (not instance)
      (null? (.q (get-state pc instance)))))

(define-method (rtc-program-counter-equal? (a <program-counter>) (b <program-counter>))
  (and (ast:equal? (.status a) (.status b))
       (ast:eq? (.statement a) (.statement b))
       (equal? (serialize (.state a)) (serialize (.state b)))
       (equal? (.trail a) (.trail b))
       (equal? (async-ports a) (async-ports b))
       (ast:equal? (.blocked a) (.blocked b))
       (ast:equal? (.collateral a) (.collateral b))
       (equal? (.released a) (.released b))
       (ast:equal? (blocked-on-boundary-statements a)
                   (blocked-on-boundary-statements b))
       (ast:equal? (.external-q a) (.external-q b))))

(define-method (pc:ast:equal? (a <flush-return>) (b <flush-return>))
  #t)

(define-method (pc:ast:equal? (a <trigger-return>) (b <trigger-return>))
  #t)

(define-method (pc:ast:equal? (a <top>) (b <top>))
  (ast:eq? a b))

(define-method (pc-equal? (a <program-counter>) (b <program-counter>))
  (and (eq? (.instance a) (.instance b))
       (ast:equal? (.status a) (.status b))
       (pc:ast:equal? (.statement a) (.statement b))
       (equal? (serialize (.state a)) (serialize (.state b)))
       (equal? (async-ports a) (async-ports b))
       (ast:equal? (.blocked a) (.blocked b))
       (ast:equal? (.collateral a) (.collateral b))
       (equal? (.released a) (.released b))
       (ast:equal? (.external-q a) (.external-q b))
       (ast:equal? (blocked-on-boundary-statements a)
                   (blocked-on-boundary-statements b))
       (pc-equal? (.previous a) (.previous b))))

(define-method (ast:equal? (a <program-counter>) (b <program-counter>))
  (pc-equal? a b))

(define-method (pc-equal? (a <top>) (b <top>))
  (eq? a b))

(define (trace-head:eq? a b)
  (pc-equal? (car a) (car b)))

(define-method (async-event? (pc <program-counter>) event)
  (and (string? event)
       (not (member event (labels)))
       (not (return-trigger? event))
       (pair? (.async pc))))

(define-method (defer-event? (pc <program-counter>) event)
  (and (string? event)
       (not (member event (labels)))
       (not (return-trigger? event))
       (pair? (.defer pc))))


;;;
;;; Initialization
;;;

(define-method (init (o <variable>))
  (let ((value (eval-expression '() (.expression o))))
    (or (range-error o value)
        (cons (.name o) (eval-expression '() (.expression o))))))

(define-method (make-state (o <runtime:instance>))
  (let* ((variables (map init ((compose ast:variable* .type .ast) o)))
         (errors (filter (is? <error>) variables)))
    (if (pair? errors) errors
        (make <state> #:instance o #:variables variables))))

(define-method (make-system-state instances)
  (make <system-state> #:state-list (map make-state (filter (disjoin runtime:boundary-port? (is? <runtime:component>)) instances))))

(define* (make-pc #:key (instances (%instances)) (trail '()))
  (let* ((system-state (make-system-state instances))
         (errors (apply append (filter list? (.state-list system-state))))
         (system-state (if (null? errors) system-state (make-system-state '())))
         (id (pc:next-id))
         (pc (make <program-counter> #:id id #:state system-state #:trail trail))
         (pc (if (null? errors) pc
                 (clone pc #:status (car errors)))))
  pc))

(define-method (make-implicit-illegal (pc <program-counter>) (o <ast>))
  (let ((illegal (make <implicit-illegal-error> #:ast o #:message "illegal")))
    (clone pc #:previous #f #:status illegal)))
