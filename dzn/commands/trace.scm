;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2020 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn commands trace)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-9 gnu)

  #:use-module (dzn config)
  #:use-module (dzn misc)
  #:use-module (dzn command-line)

  #:use-module (dzn peg)
  #:use-module (dzn parse)

  #:use-module (json)

  #:export (format-trace
            json-string->alist-scm
            parse-opts
            step:format-trace
            seqdiag:get-model
            seqdiag:format-sexp
            seqdiag:format-trace
            seqdiag:sexp->steps
            seqdiag:sequence->trail
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (locations (single-char #\L))
            (trail (single-char #\t) (value #t))))
	 (options (getopt-long args option-spec))
	 (help? (option-ref options 'help #f)))
    (when help?
      (format #t "\
Usage: dzn trace [OPTION]... FILE
Pseudo-filter to translate between different trace formats

  -f, --format=FORMAT    display trace in format FORMAT [code] {code,event,sexp}
  -h, --help             display this help and exit
  -L, --locations        prepend locations to output trail
  -t, --trail=TRAIL      use trail=TRAIL [read from stdin]
")
      (exit EXIT_SUCCESS))
    options))

(define (trace-parse ascii)
  (define (-sexp- str len pos)
    (and (< pos len) (eq? #\( (string-ref str pos))
     (catch #t
       (lambda ()
         (with-input-from-string (substring str pos len)
           (lambda () (let* ((sexp (read))
                             (end (+ pos (ftell (current-input-port)))))
                        (list end (substring str pos end))))))
       (lambda (key . args)
         (warn 'sexp-parse-failed: key args)
         #f))))
  (define-peg-pattern sexp all -sexp-)

  (define-peg-string-patterns
    "trace <- line*
line             <-  sexp ws* eol# / location? ws* (communication ws* eol# / message ws* eol#)
communication    <-- content ws* arrow ws* content# ws* state-vector?
content          <-- instance-event
state-vector     <   '[' (!']' .)+ ']'
scopename        <-  name (DOT name)*
instance-event   <-  dotted-event / instance event
dotted-event     <-- '...'
instance         <-- (name DOT)*
event            <-- name / number
message          <-- (!(eol / arrow / ws) .)+
location         <-- (!COLON .)+ COLON location-number COLON location-number COLON
COLON            <-  ':'
DOT              <   '.'
arrow            <-  in / out
in               <-- '->'
out              <-- '<-'
name             <-- [a-zA-Z_][a-zA-Z_0-9]* / '<external>' / '<q>'
number           <-- '-'? [0-9]+
location-number  <-  [0-9]+
eol              <   [\n]
ws               <   [ \t]
")
  (peg:tree (match-pattern trace ascii)))

(define* (trace->steps trace #:key (file-name "<stdin>"))
  ;;(stderr "trace:") (pretty-print trace (current-error-port))
  (catch 'syntax-error
    (lambda _
      (let ((result (trace-parse trace)))
        (match result
          (('communication communication ...) (list result))
          (_ result))))
    (peg:handle-syntax-error file-name trace)))

(define-immutable-record-type <communication>
  (make-communication line location left right event direction arrow)
  communication?
  (line communication-line)
  (location communication-location)
  (left communication-left)
  (right communication-right)
  (event communication-event)
  (direction communication-direction)
  (arrow communication-arrow))

(define (record->alist o)
  (let ((type (record-type-descriptor o)))
    (cons (record-type-name type)
          (map (lambda (f) (cons f ((record-accessor type f) o))) (record-type-fields type)))))

(define-immutable-record-type message ;; fubar me javascript <message>
  (make-message line location message)
  message?
  (line message-line)
  (location message-location)
  (message message-message))

(define-immutable-record-type state ;; fubar me javascript <state>
  (make-state sexp)
  state?
  (sexp state-sexp))

(define (step->communication o)
  (match o
    (('sexp sexp)
     (make-state sexp))

    ((('location location) ('message message))
     (make-message o location message))

    ((('location location) communication)
     (let ((communication (step->communication communication)))
       (and communication
            (set-field communication (communication-location) location))))

    (('communication left (direction (and arrow (or "<-" "->"))) right)
     (let ((left (step->communication left))
           (right (step->communication right)))
       (cond ((and left right)
              (make-communication o #f (car left) (car right) (or (cdr left) (cdr right)) direction arrow))
             (left
              (make-communication o #f (car left) #f (cdr left) direction arrow))
             (right
              (make-communication o #f #f (car right) (cdr right) direction arrow))
             (else (throw 'incommunicado o)))))

    (((and communication ('communication t ...)))
     (step->communication communication))

    (('content ('instance ('name instance) ...) ('event ('name "<q>")))
     `((,@instance "<q>") . #f))

    (('content ('instance ('name instance) ...) ('event (or ('name event) ('number event))))
     (cons instance event))

    (('content ('dotted-event dots))
     #f)

    ((content ('instance ('event (or ('name event) ('number event)))))
     `(("sut") . ,event))

     (_ #f)))

(define (code-pijltjes? steps)
  (and (pair? steps)
       (let ((c (car steps)))
         (and
          (communication? c)
          (communication-left c)
          (communication-right c)))))

(define (merge-communications steps)
  (if (code-pijltjes? steps) steps
      (let loop ((steps steps))
        (if (null? steps) '()
            (let ((step (car steps)))
              (if (or (not (communication? step))
                      (and (communication-left step)
                           (communication-right step))) (cons step (loop (cdr steps)))
                           (if (null? (cdr steps)) (list step)
                               (let ((step2 (cadr steps)))
                                 (if (not (communication? step2)) (loop (cons step (cddr steps)))
                                     (let* ((event (or (communication-event step)
                                                       (communication-event step2)))
                                            (communication (if (communication-left step)
                                                               (set-field step (communication-right) (communication-right step2))
                                                               (set-field step (communication-left) (communication-left step2))))
                                            (communication (if (communication-event communication) communication
                                                               (set-field communication (communication-event) event))))
                                       (cons communication (loop (cddr steps)))))))))))))

(define (communication->string o)
  (let* ((event (communication-event o))
         (locations? (command-line:get 'locations))
         (location (or (and locations? (communication-location o)) "")))
    (if (or (not (string? event))
            (not (list? (communication-left o)))
            (not (list? (communication-right o)))
            (not (string? (communication-arrow o))))
        (begin
          (stderr "URG: ~s\n" o)
         "<boe>")
        (string-append
         location
         (apply string-join `(,(communication-left o) ".")) "." event
         " " (communication-arrow o) " "
         (apply string-join `(,(communication-right o) ".")) "." event))))

(define (communication->code o)
  (let* ((event (communication-event o))
         (locations? (command-line:get 'locations))
         (location (or (and locations? (communication-location o)) "")))
    (if (and #f
             (or (not (string? event))
             (not (list? (communication-left o)))
             (not (list? (communication-right o)))
             (not (string? (communication-arrow o)))))
        (begin
          (stderr "URG: ~s\n" o)
         "<boe>")
        (string-append
         location
         (cond ((not (communication-left o)) "")
               ((q-instance? (communication-left o))
                (string-append
                 (apply string-join `(,(communication-left o) "."))
                 " "))
               (else
                (string-append
                 (apply string-join `(,(communication-left o) ".")) "." event
                 " ")))
         (communication-arrow o)
         (if (not (communication-right o)) ""
             (string-append
              " "
              (apply string-join `(,(communication-right o) ".")) "." event))))))

(define (message->string o)
  (let* ((locations? (command-line:get 'locations))
         (location (or (and locations? (message-location o)) "")))
    (string-append
     location
     (message-message o))))

(define (state->string o)
  (with-output-to-string (cut display (state-sexp o))))

(define (step->code o)
  (cond ((communication? o) (communication->code o))
        ((state? o) (state->string o))
        ((message? o) (message->string o))))

(define (communication-port o)
  (and=> o last))

(define (external-instance? o)
  (equal? (car o) "<external>"))

(define (q-instance? o)
  (equal? (last o) "<q>"))

(define (external? o)
  (and (communication? o)
       (or (and=> (communication-left o) external-instance?)
           (and=> (communication-right o) external-instance?))))

(define (q-out? o)
  (and (communication? o)
       (communication-right o)
       (q-instance? (communication-right o))))

(define (step->event o)
  (let ((instance (cond ((and=> (communication-left o) external-instance?) (communication-left o))
                        ((and=> (communication-right o) external-instance?) (communication-right o))
                        ((and=> (communication-left o) q-instance?) (communication-right o))
                        (else (if (communication-left o) (communication-left o)
                                  (communication-right o))))))
    (string-join
     (append
      (cdr instance)
      (list (communication-event o)))
     ".")))

(define (trace:step->trace:code pijltjes)
  (let* ((steps (trace->steps pijltjes #:file-name "foobar"))
         (debug? #f)
         (foo (when debug? (stderr "steps:") (pretty-print steps (current-error-port))))
         (steps (map (lambda (s) (or (step->communication s) s)) steps))
         (merged (merge-communications steps))
         (communications (filter (disjoin state? (conjoin (negate q-out?) communication?)) merged)))
    (string-join (map step->code communications) "\n" 'suffix)))

(define (serialize o)
  (let ((x (record->alist o)))

    (match x
      (('<communication> ('line line ...) rest ...) `((communication ,@rest)))
      (('state ('sexp . sexp)) (stderr "X: ~s\n" sexp) (warn 'Y: (list (with-input-from-string sexp read)))
       )
      (_ (list x)))))


(define (seqdiag:get-model sexp)
  (let* ((inits (filter (compose (cut equal? <> "Initialize") (cut assoc-ref <> "kind"))
                        sexp))
         (model-inits (if (= (length inits) 1) inits
                         (filter (compose (cut equal? <> "component") (cut assoc-ref <> "role"))
                                 inits))))
    (assoc-ref (car model-inits) "instance")))

(define (seqdiag:sequence->trail sequence model)
  (let* ((steps (filter
                 (conjoin (compose (cut equal? <> model) (cut assoc-ref <> "instance"))
                          (disjoin (cut assoc-ref <> "synchronization")
                                   (conjoin (compose (cut equal? <> "Error")
                                                     (cut assoc-ref <> "kind"))
                                            (compose (cut equal? <> "illegal")
                                                     (cut assoc-ref <> "message")))))
                        sequence)))
    (map (disjoin (cut assoc-ref <> "synchronization")
                  (cut assoc-ref <> "message"))
         steps)))

(define-immutable-record-type <seqdiag:step>
  (make-seqdiag-step location instance event message)
  seqdiag:step?
  (location seqdiag:step-location)
  (instance seqdiag:step-instance)
  (event seqdiag:step-event)
  (message seqdiag:step-message))

(define (seqdiag:step->string step)
  (string-join `(,(or (seqdiag:step-location step) "?")
                 ": "
                 ,@(let ((instance (seqdiag:step-instance step)))
                     (if instance (list instance ".")
                         '()))
                 ,(or (seqdiag:step-event step)
                      (seqdiag:step-message step)
                      "?"))
               ""))

(define (json-vector->list o)
  ;; guile-json-3 translates arrays to vectors
  (if (vector? o) (vector->list o) o))

(define (seqdiag:sexp->location sexp)
  (let ((selection (assoc-ref sexp "selection")))
    (and selection
         (let* ((locations (json-vector->list selection))
                (location (car locations))
                (file (assoc-ref location "file")))
           (and file
                (format #f "~a:~a:~a:~a" file
                        (assoc-ref location "line")
                        (assoc-ref location "column")
                        (if (equal? (assoc-ref sexp "kind") "Error") "error" "info")))))))

(define (seqdiag:sequence->steps sequence model)
  (define (seqdiag:state->string state)
    (define (alist->string x)
      (format #f "~a=~a" (assoc-ref x "variable") (assoc-ref x "value")))
    (string-join (map alist->string (json-vector->list state))))
  (define (seqdiag:sexp->step sexp)
    (make-seqdiag-step (seqdiag:sexp->location sexp)
                       (assoc-ref sexp "instance")
                       (or (assoc-ref sexp "event")
                           (and (assoc-ref sexp "return") "return")
                           (and (equal? (assoc-ref sexp "kind") "ReplyStatement") "reply")
                           (and=> (assoc-ref sexp "state") seqdiag:state->string))
                       (assoc-ref sexp "message")))
  (let* ((sequen (filter (negate (compose (cut member <> '("Error" "Initialize" "OnEventStatement" "ThreedEnter" "ThreadExit" "TraceType"))
                                          (cut assoc-ref <> "kind")))
                         sequence))
         (steps (map seqdiag:sexp->step sequen))
         (final (last sequence))
         (error (and (equal? (assoc-ref final "kind") "Error") final))
         (error-instance (and error (or (assoc-ref error "instance") model)))
         (error-location (and error (find (compose (cut equal? <> error-instance)
                                                   (cut assoc-ref <> "instance"))
                                          (reverse sequen))))
         (error-location (and error-location (assoc-ref error-location "selection")))
         (error (and error (seqdiag:sexp->step (acons "selection" error-location error))))
         (steps (if error (cons error steps) steps)))
    steps))

(define (json->alist-scm src)
  (match src
    ((? hash-table?) (json->alist-scm (hash-table->alist src)))
    ((h ...) (map json->alist-scm src))
    ((h . t) (cons (json->alist-scm h) (json->alist-scm t)))
    (_ src)))

(define (json-string->alist-scm src)
  (json->alist-scm (json-string->scm src)))

(define* (seqdiag:sexp->steps sexp #:key (file-name "<stdin>"))
  (let* ((sequence (json-vector->list sexp))
         (model (seqdiag:get-model sequence))
         (steps (seqdiag:sequence->steps sequence model)))
    steps))

(define (seqdiag:trace? string)
  (string-prefix? "[{" string))

(define (seqdiag:format-sexp sexp)
  (let ((steps (seqdiag:sexp->steps sexp)))
    (string-join (map seqdiag:step->string steps) "\n" 'suffix)))

(define (seqdiag:format-trace trace)
  (seqdiag:format-sexp (json-string->alist-scm trace)))

(define* (step:format-trace trace #:key file-name format debug?)
  (let* ((steps (trace->steps trace #:file-name file-name))
         (foo (when debug? (stderr "steps:") (pretty-print steps (current-error-port))))
         (structured (map (lambda (s) (or (step->communication s) s)) steps))
         (merged (merge-communications structured)))
    (cond ((equal? format "sexp") (if (dzn:command-line:get 'json) (scm->json-string (map serialize structured))
                                      (map serialize structured)))
          ((equal? format "event")
           (let ((communications (filter (conjoin (negate q-out?) external?) merged)))
             (string-join (map step->event communications) "\n" 'suffix)))
          (else
           (let ((communications (filter (disjoin state? (conjoin (negate q-out?) communication?)) merged)))
             (string-join (map step->code communications) "\n" 'suffix))))))

(define* (format-trace trace #:key file-name format debug?)
  (if (seqdiag:trace? trace) (seqdiag:format-trace trace)
      (step:format-trace trace #:file-name file-name #:format format #:debug? debug?)))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (if (pair? files) (car files) "-"))
         (trail (command-line:get 'trail))
         (trace (or trail
                    (if (equal? file-name "-") (read-string)
                        (with-input-from-file (car files) read-string))))
         (format (option-ref options 'format "code"))
         (debug? (dzn:command-line:get 'debug)))
    (display (format-trace trace #:file-name file-name #:format format #:debug? debug?))
    ""))
