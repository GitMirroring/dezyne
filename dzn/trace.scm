;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018, 2020, 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn trace)
  #:use-module (ice-9 match)
  #:use-module (ice-9 pretty-print)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)

  #:use-module (dzn peg)
  #:use-module (dzn parse)
  #:use-module (dzn parse util)
  #:use-module (dzn misc)

  #:use-module (json)

  #:export (trace:format-trace))

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
line             <-  garbage eol# / sexp ws* eol# / location? ws* (communication ws* eol# / message ws* eol#)
garbage          <   SEMICOLON (!eol .)+
communication    <-- content ws* arrow ws* content# ws* state-vector?
content          <-- instance-event
state-vector     <   '[' (!']' .)+ ']'
scopename        <-  name (DOT name)*
instance-event   <-  dotted-event / instance event
dotted-event     <-- '...'
instance         <-- (name DOT)*
event            <-- enum / name / number
message          <-- (!(eol / arrow) .)+
location         <-- (!(SEMICOLON / eol / COLON location-number COLON location-number COLON) .)+ COLON location-number COLON location-number COLON
COLON            <-  ':'
SEMICOLON        <-  ';'
DOT              <   '.'
arrow            <-  in / out
in               <-- '->'
out              <-- '<-'
name             <-- [a-zA-Z_][a-zA-Z_0-9]* / '<external>' / '<q>'
number           <-- '-'? [0-9]+
enum             <-- [a-zA-Z_][a-zA-Z_0-9]* ':' [a-zA-Z_][a-zA-Z_0-9]*
location-number  <-  [0-9]+
eol              <   [\n]
space            <   ' '
ws               <   [ \t]
")
  (peg:tree (match-pattern trace ascii)))

(define* (trace:trace->steps trace #:key (file-name "<stdin>") debug?)
  (when debug?
    (format (current-error-port) "trace:")
    (pretty-print trace (current-error-port)))
  (catch 'syntax-error
    (lambda _
      (let ((result (trace-parse trace)))
        (match result
          (('communication communication ...) (list result))
          (_ result))))
    (peg:handle-syntax-error file-name trace)))

(define-immutable-record-type <communication>
  (make-communication line left-location left right-location right event direction arrow)
  communication?
  (line communication-line)
  (left-location communication-left-location)
  (location communication-location)
  (left communication-left)
  (right-location communication-right-location)
  (right communication-right)
  (event communication-event)
  (direction communication-direction)
  (arrow communication-arrow))

(define (communication-complete? o)
  (and (string? (communication-event o))
       (list? (communication-left o))
       (list? (communication-right o))
       (string? (communication-arrow o))))

(define (communication-location o)
  (if (eq? (communication-direction o) 'in)
      (or (communication-left-location o)
          (communication-right-location o))
      (or (communication-right-location o)
          (communication-left-location o))))

(define (communication-instance->model-path lst)
  (let ((path (map string->symbol lst)))
    (match path
      (('sut port) '(sut))
      (('sut path ... port) (cons 'sut path))
      (('<external> path ...) path)
      (_ path))))

(define (record->alist o)
  (let ((type (record-type-descriptor o)))
    (cons (record-type-name type)
          (map (lambda (f) (cons f ((record-accessor type f) o))) (record-type-fields type)))))

(define-immutable-record-type <message>
  (make-message line location message)
  message?
  (line message-line)
  (location message-location)
  (message message-message))

(define (message-text-equal? a b)
  (equal? (message-message a) (message-message b)))

(define-immutable-record-type <eligible>
  (make-eligible sexp)
  eligible?
  (sexp eligible-sexp))

(define-immutable-record-type <header>
  (make-header sexp)
  header?
  (sexp header-sexp))

(define-immutable-record-type <labels>
  (make-labels sexp)
  labels?
  (sexp labels-sexp))

(define-immutable-record-type <state>
  (make-state sexp)
  state?
  (sexp state-sexp))

(define-immutable-record-type <trail>
  (make-trail sexp)
  trail?
  (sexp trail-sexp))

(define (step->communication o)
  (match o
    (('sexp string)
     (let ((sexp (with-input-from-string string read)))
       (match sexp
         (('eligible eligible ...)
          (make-eligible eligible))
         (('header header ...)
          (make-header header))
         (('labels labels ...)
          (make-labels labels))
         (('state state ...)
          (make-state state))
         (('trail trail ...)
          (make-trail trail)))))

    ((('location location) ('message message))
     (make-message o location message))

    ((('location location) communication)
     (let ((communication (step->communication communication)))
       (and communication
            (if (not (communication-right communication))
                (set-field communication (communication-left-location) location)
                (set-field communication (communication-right-location) location)))))

    (('communication left (direction (and arrow (or "<-" "->"))) right)
     (let ((left (step->communication left))
           (right (step->communication right)))
       (cond ((and left right)
              (make-communication o #f (car left) #f (car right) (or (cdr left) (cdr right)) direction arrow))
             (left
              (make-communication o #f (car left) #f #f (cdr left) direction arrow))
             (right
              (make-communication o #f #f #f (car right) (cdr right) direction arrow))
             (else (throw 'incommunicado o)))))

    (((and communication ('communication t ...)))
     (step->communication communication))

    (('content ('instance ('name instance) ...) ('event ('name "<q>")))
     `((,@instance "<q>") . #f))

    (('content ('instance ('name instance) ...) ('event (or ('name event) ('number event) ('enum event))))
     (cons instance event))

    (('content ('dotted-event dots))
     #f)

    ((content ('instance ('event (or ('name event) ('number event) ('enum event)))))
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
  (define (merge-able? step step2)
    (or (and (eq? (communication-direction step) 'in)
             (communication-left step)
             (not (communication-right step))
             (eq? (communication-direction step2) 'in)
             (not (communication-left step2))
             (communication-right step2))
        (and (eq? (communication-direction step) 'out)
             (not (communication-left step))
             (communication-right step)
             (eq? (communication-direction step2) 'out)
             (communication-left step2)
             (not (communication-right step2)))))
  (define (first-half? step)
    (or (and (eq? (communication-direction step) 'in)
             (communication-left step)
             (not (communication-right step)))
        (and (eq? (communication-direction step) 'out)
             (not (communication-left step)))))
  (define (merge step step2)
    (let* ((event (communication-event step))
           (event (or (and (not (member event '("inevitable" "optional")))
                           event)
                      (communication-event step2)))
           (communication (cond
                           ((communication-left step)
                            (set-fields step
                                        ((communication-event) event)
                                        ((communication-right-location) (communication-right-location step2))
                                        ((communication-right) (communication-right step2))))
                           (else
                            (set-fields step
                                        ((communication-event) event)
                                        ((communication-left-location) (communication-left-location step2))
                                        ((communication-left) (communication-left step2))))))
           (communication (cond
                           ((communication-event communication)
                            communication)
                           (else
                            (set-field communication (communication-event) event)))))
      communication))
  (if (code-pijltjes? steps) steps
      (let loop ((steps steps))
        (if (null? steps) '()
            (let ((step (car steps)))
              (if (or (not (communication? step))
                      (and (communication-left step)
                           (communication-right step))) (cons step (loop (cdr steps)))
                           (cond
                            ((and (null? (cdr steps))
                                  (first-half? step))
                             (let ((step2 (if (communication-left step)
                                              (make-communication (communication-line step)
                                                                  #f
                                                                  #f
                                                                  (communication-left-location step)
                                                                  (communication-left step)
                                                                  (communication-event step)
                                                                  (communication-direction step)
                                                                  (communication-arrow step))
                                              (make-communication (communication-line step)
                                                                  (communication-right-location step)
                                                                  (communication-right step)
                                                                  #f
                                                                  #f
                                                                  (communication-event step)
                                                                  (communication-direction step)
                                                                  (communication-arrow step)))))
                               (list (merge step step2))))
                            ((null? (cdr steps))
                             (let ((message "error: split-arrows missing complement arrow")
                                   (arrow (string-append "error: arrow: "
                                                         (communication->string step)))
                                   (location (communication-location step)))
                               (list (make-message
                                      (string-append (or location "") message)
                                      location message)
                                     (make-message
                                      (string-append (or location "") arrow)
                                      location arrow))))
                            (else
                             (let ((step2 (cadr steps)))
                               (cond
                                ((not (communication? step2))
                                 (cons step2 (loop (cons step (cddr steps)))))
                                ((merge-able? step step2)
                                 (cons (merge step step2) (loop (cddr steps))))
                                (else
                                 (let ((message "error: split-arrows cannot be merged")
                                       (arrow1 (string-append "error: arrow1: "
                                                              (communication->string step)))
                                       (arrow2 (string-append "error: arrow2: "
                                                              (communication->string step2)))
                                       (location (communication-location step))
                                       (location2 (communication-location step2)))
                                   (list (make-message
                                          (string-append (or location "") message)
                                          location message)
                                         (make-message
                                          (string-append (or location "") arrow1)
                                          location arrow1)
                                         (make-message
                                          (string-append (or location2 "") arrow2)
                                          location2 arrow2))))))))))))))

(define* (communication->string o #:key locations?)
  (let* ((event (communication-event o))
         (location (or (and locations? (communication-location o)) "")))
    (cond
     ((communication-complete? o)
      (string-append
       location
       (string-join `(,@(communication-left o) ,event) ".")
       " " (communication-arrow o) " "
       (string-join `(,@(communication-right o) ,event) ".")))
     ((and (string? event)
           (list? (communication-left o)))
      (string-append
       location
       (string-join `(,@(communication-left o) ,event) ".")
       " " (communication-arrow o) " "
       "..."))
     ((and (string? event)
           (list? (communication-right o)))
      (string-append
       location
       "..."
       " " (communication-arrow o) " "
       (string-join `(,@(communication-right o) ,event) ".")))
     (else
      (format #f "~s" o)))))

(define* (communication->code o #:key locations?)
  (let* ((event (communication-event o))
         (location (or (and locations? (communication-location o)) "")))
    (cond
     ((communication-complete? o)
      (string-append
       location
       (cond
        ((not (communication-left o)) "")
        ((q-instance? (communication-left o))
         (string-append
          (string-join `(,@(communication-left o) ,event) ".")
          " "))
        (else
         (string-append
          (string-join `(,@(communication-left o) ,event) ".")
          " ")))
       (communication-arrow o)
       (if (not (communication-right o)) ""
           (string-append
            " "
            (string-join `(,@(communication-right o) ,event) ".")))))
     (else
      (format #f "~s" o)))))

(define (message->string o)
  (let ((location (or (message-location o) "")))
    (string-append
     location
     (message-message o))))

(define (eligible->string o)
  (with-output-to-string (cut display (cons 'eligible (eligible-sexp o)))))

(define (header->string o)
  (with-output-to-string (cut display (cons 'header (header-sexp o)))))

(define (labels->string o)
  (with-output-to-string (cut display (cons 'labels (labels-sexp o)))))

(define (trail->string o)
  (with-output-to-string (cut display (cons 'trail (trail-sexp o)))))

(define (state->string o)
  (with-output-to-string (cut display (cons 'state (state-sexp o)))))

(define (trail->string o)
  (with-output-to-string (cut display (cons 'trail (trail-sexp o)))))

(define* (step->code o #:key locations?)
  (cond ((communication? o) (communication->code o #:locations? locations?))
        ((eligible? o) (eligible->string o))
        ((header? o) (header->string o))
        ((labels? o) (labels->string o))
        ((message? o) (message->string o))
        ((state? o) (state->string o))
        ((trail? o) (trail->string o))))

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

(define (q-in? o)
  (and (communication? o)
       (communication-left o)
       (q-instance? (communication-left o))))

(define (step->event o)
  (cond ((communication? o)
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
        ((message? o)
         (message->string o))))

(define (serialize o)
  (let ((x (record->alist o)))
    (match x
      (('<communication> ('line line ...) rest ...) `((communication ,@rest)))
      (('state ('sexp . sexp)) (format (current-error-port) "X: ~s\n" sexp) (warn 'Y: (list (with-input-from-string sexp read))))
      (_ (list x)))))

(define* (trace:trace->structured trace #:key file-name debug?)
  (let* ((steps (trace:trace->steps trace #:file-name file-name #:debug? debug?))
         (foo (when debug? (format (current-error-port) "steps:") (pretty-print steps (current-error-port))))
         (structured (map (lambda (s) (or (step->communication s) s)) steps)))
    structured))


;;;
;;; Diagram
;;;
(define (instance->string instance)
  (match instance
    ((? string?) instance)
    ((? symbol?) (symbol->string instance))
    ((? pair?) (string-join (map symbol->string instance) "."))))

(define (center reference string)
  (let* ((reference (instance->string reference))
         (string (instance->string string))
         (width (string-length reference))
         (len (string-length string))
         (left-margin (max 0 (quotient (- width len) 2)))
         (pad-left (make-string left-margin #\space))
         (right-margin (max 0 (- width len left-margin)))
         (pad-right (make-string right-margin #\space)))
    (string-append pad-left string pad-right)))

(define (location-length o)
  (cond ((communication? o)
         (max (location-length (communication-left-location o))
              (location-length (communication-right-location o))))
        ((message? o)
         (location-length (message-location o)))
        ((string? o)
         (string-length o))
        (else
         0)))

(define* (step:steps->diagram header steps #:key internal? locations?)
  (let* ((header (header-sexp header))
         (spacing 30)
         (spacer (make-string spacing #\space))
         (sut (find (compose (cut equal? <> '(sut)) car) header))
         (sut-name (and sut (cadr sut)))
         (location-width (and locations? (apply max (map location-length steps)))))
    (define (instance->head instance)
      (match instance
        ((('sut) type kind)
         (center spacer type))
        (('sut)
         (center spacer sut-name))
        ((('sut path ...) type kind)
         (center spacer (cons sut-name path)))
        ((name type 'provides)
         (center name name))
        ((name type 'requires)
         (center name name))
        ((name type 'component)
         (center name name))
        ((name type 'system)
         (center name name))
        ((name)
         (center name name))
        (_
         (center spacer (format #f "~a" instance)))))
    (define (port-instance->name o)
      (match o
        (('sut)
         (symbol->string sut-name))
        (('sut path ...)
         (let* ((instance (find (compose (cut equal? o <>) car) header))
                (kind (match instance ((name type kind) kind))))
           (if (or internal? (memq kind '(foreign provides requires))) (string-join (map symbol->string (cons sut-name path)) ".")
               (symbol->string sut-name))))
        ((port)
         (symbol->string port))
        ((path ... port) ;; FIXME: bug in trace
         (symbol->string port))
        (()
         "client")))
    (define (instance->life instance)
      (match instance
        ((name type 'provides)
         ".")
        ((name type 'requires)
         ".")
        ((name type 'component)
         ":")
        (_
         ":")))

    (let* ((header-instances (filter (match-lambda ((path name type) (not (eq? type 'system)))) header))
           (header-instances (if internal? header-instances
                                 (delete-duplicates
                                  (map (lambda (h)
                                         (match h
                                           ((('sut path ...) type 'component)
                                            sut)
                                           ((('sut path ...) type 'foreign)
                                            sut)
                                           (_ h)))
                                       header-instances))))
           (header-names (map instance->head header-instances))
           (header-line (string-trim-right (string-join header-names))))

      (let* ((life-line (let loop ((instances header-instances) (pos 0))
                          (if (null? instances) '()
                              (let* ((instance (car instances))
                                     (rest (cdr instances))
                                     (name (string-trim-both (instance->head instance)))
                                     (header-name (string-append
                                                   (if (zero? pos) "" " ")
                                                   name
                                                   (if (null? rest) "" " ")))
                                     (index (+ (string-contains header-line header-name)
                                               (if (zero? pos) 0 1)
                                               (modulo (string-length name) 2)
                                               (quotient (string-length name) 2)))
                                     (segment (string-append (make-string (- index pos 1) #\space)
                                                             (instance->life instance))))
                                (cons segment (loop (cdr instances) index))))))
             (life-line (string-join life-line ""))
             (width (1- (string-length header-line))))

        (define* (location-prefix step #:key from?)
          (let* ((location (cond ((and (communication? step)
                                       (or (and from?
                                                (eq? (communication-direction step) 'in))
                                           (and (not from?)
                                                (eq? (communication-direction step) 'out))))
                                  (communication-left-location step))
                                 ((communication? step)
                                  (communication-right-location step))
                                 ((message? step)
                                  (message-location step))
                                 (else ""))))
            (if (not locations?) ""
                (let* ((padding (- location-width (or (and location (string-length location)) 0)))
                       (padding (if (string-prefix? "  " life-line) padding (+ padding 2)))
                       (padding (make-string padding #\space)))
                  (string-append location padding)))))

        (define (communication->life communication)
          (let* ((event (communication-event communication)))
            (if (or (not (string? event))
                    (not (list? (communication-left communication)))
                    (not (list? (communication-right communication)))
                    (not (string? (communication-arrow communication))))
                (begin
                  (format (current-error-port) "communication-error: ~s\n" communication)
                  '())
                (let* ((left (communication-left communication))
                       (left (communication-instance->model-path left))
                       (left (string-trim-both (port-instance->name left)))
                       (left-margin (cond
                                     ((string-prefix? (string-append left " ") header-line)
                                      (quotient (1- (string-length left)) 2))
                                     ((string-suffix? (string-append " " left) header-line)
                                      (- width (quotient (string-length left) 2)))
                                     (else (+ (or (string-contains header-line (string-append " " left " ")) 0)
                                              (modulo (string-length left) 2)
                                              (quotient (string-length left) 2)))))
                       (right (communication-right communication))
                       (right (communication-instance->model-path right))
                       (right (string-trim-both (port-instance->name right)))
                       (right-margin (cond
                                      ((string-prefix? (string-append right " ") header-line)
                                       (quotient (string-length right) 2))
                                      ((string-suffix? (string-append " " right) header-line)
                                       (- width (quotient (string-length right) 2)))
                                      (else (+ (or (string-contains header-line (string-append " " right " ")) 0)
                                               (modulo (string-length right) 2)
                                               (quotient (string-length right) 2)))))
                       (swap left-margin)
                       (swap? (<  right-margin left-margin))
                       (left-margin (if swap? right-margin left-margin))
                       (right-margin (if swap? swap right-margin))
                       (arrow (communication-arrow communication))
                       (arrow (if swap? (assoc-ref `(("<-" . "->") ("->" . "<-")) arrow)
                                  arrow)))
                  (cond
                   ((equal? arrow "->")
                    (catch #t
                      (lambda _
                        (let* ((line (string-append
                                      (substring life-line 0 (1+ left-margin))
                                      event))
                               (len (string-length line))
                               (arrow (string-append (make-string (- right-margin left-margin 2) #\-) ">"))
                               (arrow-line (string-append
                                            (substring life-line 0 (1+ left-margin))
                                            arrow))
                               (arrow-len (string-length arrow-line)))
                          (list (string-append (location-prefix "") life-line)
                                (string-append
                                 (location-prefix communication #:from? #t)
                                 line
                                 (substring life-line len))
                                (string-append
                                 (location-prefix communication #:from? #f)
                                 arrow-line
                                 (substring life-line arrow-len)))))
                      (lambda (key . args)
                        (format (current-error-port) "<- ~a ~s\n" key args)
                        (list ">>>>>" life-line))))
                   ((equal? arrow "<-")
                    (catch #t
                      (lambda _
                        (let ((arrow (string-append "<" (make-string (- right-margin left-margin 2) #\-))))
                          (list (string-append (location-prefix "") life-line)
                                (string-append
                                 (location-prefix communication #:from? #t)
                                 (substring life-line 0 (- right-margin (string-length event) 0))
                                 event
                                 (substring life-line right-margin))
                                (string-append
                                 (location-prefix communication #:from? #f)
                                 (substring life-line 0 (- right-margin (string-length arrow) 0))
                                 arrow
                                 (substring life-line right-margin)))))
                      (lambda (key . args)
                        (format (current-error-port) "<- ~a ~s\n" key args)
                        (list "<<<<<" life-line)))))))))

        (define (message->life step)
          (list (string-append (location-prefix step) life-line " " (message-message step))))

        (cons* (string-append (location-prefix "") header-line)
               (string-append (location-prefix "") life-line)
               (let loop ((steps steps))
                 (if (null? steps) '()
                     (let* ((step (car steps))
                            (tail (cdr steps))
                            (next (and (pair? tail) (car tail)))
                            (communicating? (communication? next))
                            (lines (cond ((communication? step)
                                          (communication->life step))
                                         ((message? step)
                                          (message->life step))
                                         ((eligible? step)
                                          (if communicating? '()
                                              (list (eligible->string step))))
                                         ((state? step)
                                          (if communicating? '()
                                              (list (state->string step))))
                                         ((labels? step)
                                          (list (labels->string step)))
                                         ((trail? step)
                                          (if communicating? '()
                                              (list (trail->string step)))))))
                       (append lines (loop tail))))))))))


;;;
;;; JSON
;;;
(define-immutable-record-type <lifeline-header>
  (make-lifeline-header text role)
  lifeline-header?
  (text lifeline-header-text)
  (role lifeline-header-role))

(define (lifeline-header->scm o)
  `((instance . ,(lifeline-header-text o))
    (role     . ,(lifeline-header-role o))))

(define-immutable-record-type <lifeline-activity>
  (make-lifeline-activity key time location)
  lifeline-activity?
  (key lifeline-activity-key)
  (time lifeline-activity-time)
  (location lifeline-activity-location))

(define (location-string->scm-location string)
  (let ((loc (string->location string)))
    (if (not loc) '()
        `((location . ((file-name . ,(location-file loc))
                       (line      . ,(location-line loc))
                       (column    . ,(location-column loc))))))))

(define (lifeline-activity->scm o)
  `((key      . ,(lifeline-activity-key o))
    (time     . ,(lifeline-activity-time o))
    ,@(let ((location (lifeline-activity-location o)))
        (if location (location-string->scm-location location) '()))))

(define-immutable-record-type <lifeline-label>
  (make-lifeline-label text role illegal?)
  lifeline-label?
  (text lifeline-label-text)
  (role lifeline-label-role)
  (illegal? lifeline-label-illegal?))

(define (lifeline-label->scm o)
  `((text . ,(lifeline-label-text o))
    (role . ,(lifeline-label-role o))
    ,@(if (lifeline-label-illegal? o) `((illegal . #t)) '())))

(define-immutable-record-type <lifeline-event>
  (make-lifeline-event text from to type messages)
  lifeline-event?
  (text lifeline-event-text)
  (from lifeline-event-from)
  (to lifeline-event-to)
  (type lifeline-event-type)
  (messages lifeline-event-messages))

(define (lifeline-event->scm o)
  (define (message->scm message)
    `((text      . ,(message-message message))
      ,@(let ((location (message-location message)))
          (if location (location-string->scm-location location) '()))))
  `((text     . ,(lifeline-event-text o))
    (from     . ,(lifeline-event-from o))
    (to       . ,(lifeline-event-to o))
    (type     . ,(lifeline-event-type o))
    ,@(let ((messages (lifeline-event-messages o)))
        (if (null? messages) '()
            `((messages . ,(list->vector (map message->scm messages))))))))

(define (instance-state->json-scm sut-name o)
  (define state->json-scm
    (match-lambda
      ((name . value)
       `(("name" . ,(symbol->string name))
         ("value" . ,(format #f "~a" value))))))
  (match o
    ((instance state ...)
     (let ((name (if (equal? instance '(sut)) sut-name (instance->string instance))))
       `(("instance" . ,name)
         ("state"    . ,(list->vector (map state->json-scm state))))))))

(define (lifeline-state->json-scm sut-name o)
  (list->vector (map (cute instance-state->json-scm sut-name <>) (state-sexp o))))

(define-immutable-record-type <lifeline>
  (make-lifeline header activities labels)
  lifeline?
  (header lifeline-header)
  (activities lifeline-activities)
  (labels lifeline-labels))

(define (lifeline->scm o)
  `((header     . ,(lifeline-header->scm (lifeline-header o)))
    (activities . ,(list->vector (map lifeline-activity->scm (lifeline-activities o))))
    (labels     . ,(list->vector (map lifeline-label->scm (lifeline-labels o))))))

(define (communication-instance->path instance)
  (match instance
    (("sut") '(sut))
    (("<external>") '(client))
    (("<external>" path ...) (map string->symbol path))
    (("sut" path ... port) (map string->symbol (cons "sut" path)))))

(define (header-instance->name instance)
  (match instance
    ((('sut) type kind)
     (symbol->string type))
    ((path type kind)
     (string-join (map symbol->string path) "."))))

(define (trace:steps->json steps)
  "Produce P5 JSON output from STEPS."

  (define* (instance->lifeline instance activities labels eligible)
    (define (lifeline-label label kind)
      (make-lifeline-label label kind (and (not (equal? label "<back>"))
                                           (not (member label eligible)))))
    (match instance
      ((path type kind)
       (let* ((name       (header-instance->name instance))
              (header     (make-lifeline-header name kind))
              (prefix     (string-append name "."))
              (labels     (cond ((or (member kind '(component interface)))
                                 '("<back>"))
                                ((and (eq? kind 'provides)
                                      (pair? labels)
                                      (not (string-index (car labels) #\.)))
                                 labels)
                                (else
                                 (filter (cute string-prefix? prefix <>) labels))))
              (labels     (map (cute lifeline-label <> kind) labels))
              (activities (assoc-ref activities path)))
         (make-lifeline header activities labels)))))

  (let* ((header (find header? steps))
         (r-steps (reverse steps))
         (eligible (find eligible? r-steps))
         (eligible (and eligible (eligible-sexp eligible)))
         (labels (find labels? r-steps))
         (labels (if labels (labels-sexp labels) '()))
         (header (header-sexp header))
         (instances (filter (match-lambda ((path name type) (not (eq? type 'system)))) header))
         (sut-name (match (assoc-ref instances '(sut)) ((name kind) (symbol->string name)) (_ #f)))
         (activities-alist (map (compose list car) instances))
         (communications (filter communication? steps))
         (states (filter state? steps))
         (messages (delete-duplicates (filter message? steps) message-text-equal?))
         (error? (find (compose (cute string-prefix? "error:" <>) message-message) messages))
         (messages (if error? messages '())))

    ;; loop: cdr through communications, building up activities and events from each communication
    (let loop ((communications communications) (messages messages) (activities activities-alist) (events '()))
      (cond
       ;; FIXME: Systhesize event for adding messages to.
       ;; TODO: Add toplevel messages.
       ((and (null? communications)
             (pair? messages))
        (let* ((from           '(sut))
               (to             '(sut))
               (time           (length events))
               (key-from       (1+ (* 2 time)))
               (key-to         (1+ key-from))
               (location       (message-location (car messages)))
               (activity-from  (make-lifeline-activity key-from time location))
               (activity-to    (make-lifeline-activity key-to time location))
               (label          "")
               (type           "error")
               (event          (make-lifeline-event label key-from key-to type messages))
               (activities     (acons from
                                      (append (or (assoc-ref activities from) '())
                                              (list activity-from))
                                      activities))
               (activities     (acons to
                                      (append (or (assoc-ref activities to) '())
                                              (list activity-to))
                                      activities)))
          (loop '()
                '()
                activities
                (append events (list event)))))
       ((null? communications)
        (let ((lifelines (map (cute instance->lifeline <> activities labels eligible) instances)))
          (scm->json-string
           `((working-directory . ,(getcwd))
             (lifelines . ,(list->vector (map lifeline->scm lifelines)))
             (events    . ,(list->vector (map lifeline-event->scm events)))
             (states    . ,(list->vector (map (cute lifeline-state->json-scm sut-name <>) states)))))))
       (else
        (let* ((communication  (car communications))
               (direction      (communication-direction communication))
               (left           (communication-left communication))
               (right          (communication-right communication))
               (from           (if (eq? direction 'in) left right))
               (to             (if (eq? direction 'in) right left))
               (from           (and from (communication-instance->path from)))
               (to             (and to (communication-instance->path to)))
               (label          (communication-event communication))
               (time           (length events))
               (key-from       (1+ (* 2 time)))
               (location-left  (communication-left-location communication))
               (location-right (communication-right-location communication))
               (location-from  (if (eq? direction 'in) location-left location-right))
               (location-to    (if (eq? direction 'in) location-right location-left))
               (activity-from  (make-lifeline-activity key-from time location-from))
               (key-to         (1+ key-from))
               (activity-to    (make-lifeline-activity key-to time location-to))
               (type           (if (or (member label '("true" "false" "return"))
                                       (string->number label)
                                       (string-index label #\:))
                                   "return"
                                   direction))
               (event          (make-lifeline-event label key-from key-to type '()))
               (activities     (acons from
                                      (append (or (assoc-ref activities from) '())
                                              (list activity-from))
                                      activities))
               (activities     (acons to
                                      (append (or (assoc-ref activities to) '())
                                              (list activity-to))
                                      activities)))
          (loop (cdr communications)
                messages
                activities
                (append events (list event)))))))))

(define* (trace:format-trace trace #:key debug? file-name format internal? locations?)
  (let* ((structured (trace:trace->structured trace #:file-name file-name #:debug? debug?))
         (merged (merge-communications structured)))
    (cond
     ((equal? format "sexp")
      (map serialize structured))
     ((equal? format "event")
      (let* ((communications (filter (conjoin (negate q-out?) external?) merged))
             (communications (map step->event communications)))
        (string-join communications "\n" 'suffix)))
     ((equal? format "diagram")
      (let* ((communications (filter (disjoin (conjoin (negate q-out?)
                                                       (if internal? communication? external?))
                                              eligible? labels? message? state? trail?)
                                     merged))
             (header (find header? structured))
             (communications (step:steps->diagram header communications
                                                  #:internal? internal?
                                                  #:locations? locations?)))
        (string-join communications "\n" 'suffix)))
     ((equal? format "json")
      (trace:steps->json merged))
     (else
      (let* ((communications (filter (disjoin (conjoin (negate q-out?) communication?)
                                              message? state?)
                                     merged))
             (communications (map
                              (cut step->code <> #:locations? locations?)
                              communications)))
        (string-join communications "\n" 'suffix))))))
