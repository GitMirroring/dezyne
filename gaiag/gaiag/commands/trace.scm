;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag commands trace)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-9 gnu)

  #:use-module (gaiag config)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)

  #:use-module (peg)
  #:use-module (peg cache)
  #:use-module (peg codegen)
  #:use-module (peg string-peg)

  #:use-module (json)


  #:export (parse-opts
            format-trace
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((format (single-char #\f) (value #t))
            (help (single-char #\h))
            (locations (single-char #\L))
            (trail (single-char #\t) (value #t))
	    (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '())))
    (or
     (and help?
          (stdout "\
Usage: gdzn trace [OPTION]... FILE
  -f, --format=FORMAT    display trace in format FORMAT [code] {code,event,sexp}
  -h, --help             display this help and exit
  -L, --locations        prepend locations to output trail
  -t, --trail=TRAIL      use trail=TRAIL [read from stdin]
  -V, --version=VERSION  use service version=VERSION
")
          (exit 0)))
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
communication    <-- content ws* arrow ws* content#
content          <-- instance-event
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
number           <-- [0-9]+
location-number  <-  [0-9]+
eol              <   [\n]
ws               <   [ \t]
")
  (peg:tree (match-pattern trace ascii)))

(define* (trace->steps trace #:key (file-name "<stdin>"))
  ;;(stderr "trace:") (pretty-print trace (current-error-port))
  (catch 'syntax-error
    (lambda ()
      (trace-parse trace))
    (lambda (key . args)
      (receive (ln col line) ((@@ (gaiag parse) line-column) trace (caar args))
        (let ((indent (make-string col #\space)))
          (format #t "~a:~a:~a: syntax-error\n~a\n~a^\n~aexpected '~a'\n"
                  file-name
                  ln col line
                  indent
                  indent
                  (cadar args))
          (exit 1))))))

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
              (make-communication o #f (car left) (car right) (cdr left) direction arrow))
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
     `((sut) . ,event))

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
         (if (not (communication-left o)) ""
             (string-append
              (apply string-join `(,(communication-left o) ".")) "." event
              " "))
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

(define* (format-trace trace #:key file-name format debug?)
  (let* ((steps (trace->steps trace #:file-name file-name))
         (foo (when debug? (stderr "steps:") (pretty-print steps (current-error-port))))
         (structured (map (lambda (s) (or (step->communication s) s)) steps))
         (merged (merge-communications structured)))
    (cond ((equal? format "sexp") (if (gdzn:command-line:get 'json) (scm->json-string (map serialize structured))
                                      (map serialize structured)))
          ((equal? format "event")
           (let ((communications (filter (conjoin (negate q-out?) external?) merged)))
             (string-join (map step->event communications) "\n" 'suffix)))
          (else
           (let ((communications (filter (disjoin state? (conjoin (negate q-out?) communication?)) merged)))
             (string-join (map step->code communications) "\n" 'suffix))))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (if (pair? files) (car files) "-"))
         (trail (command-line:get 'trail))
         (trace (or trail
                    (if (equal? file-name "-") (read-string)
                        (with-input-from-file (car files) read-string))))
         (format (option-ref options 'format "code"))
         (debug? (gdzn:command-line:get 'debug)))
    (display (format-trace trace #:file-name file-name #:format format #:debug? debug?))
    ""))
