;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
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

(define-module (scmcrl2 traces)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 peg)
  #:use-module (ice-9 peg codegen)
  #:use-module (ice-9 pretty-print)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)

  #:export (make-trace
            make-trace-file
            rename-lts-actions))

(define (find-aliases mcrl2file)
  (let* ((mcrl2-text (call-with-input-file "verify.mcrl2" read-string))
	 (aliases (map
		   (lambda (m) (match:substring m 1))
		   (list-matches "\\b([a-zA-Z0-9_']*)\\s*=\\s*struct\\b" mcrl2-text))))
    aliases))

;; (define trace "startIF'event(StartControlIF'in'startAll)
;; device1IF'event(Device1IF'in'turnon)
;; device1IF'return(Device1IF'in'turnon, reply_Device1IF'Void(void))
;; tau
;; tau
;; startIF'return(StartControlIF'in'startAll, reply_StartControlIF'Void(void))
;; device1IF'inevitable
;; device1IF'event(Device1IF'out'ok)
;; device1IF'flush
;; tau
;; device2IF'event(Device2IF'in'turnon)
;; device2IF'return(Device2IF'in'turnon, reply_Device2IF'Device2IF'Result(Device2IF'Result'NOK))
;; startIF'event(StartControlIF'out'startFailed)
;; tau
;; tau
;; startIF'flush
;; startIF'event(StartControlIF'in'startAll)
;; device1IF'event(Device1IF'in'turnon)
;; illegal
;; ")

;;(define trace "p'event(ibool'in'hello)")
(define trace "tau")

(define (parse input)
  (define-peg-string-patterns
    "trace          <-- ((tau / illegal / range-error / reply-error / flush / modeling / event / return / error) newline?)*
     newline        <   '\n'
     lpar           <   '('
     rpar           <   ')'
     tick           <   [']
     error          <-- (! newline .)*
     direction      <   'in' / 'out'
     tau            <   'tau'
     illegal        <   'illegal' / 'dillegal'
     range-error    <   'range_error'
     reply-error    <   'double_reply_error' / 'no_reply_error'
     flush          <   (identifier tick)+ 'flush'
     modeling       <   port tick ('inevitable' / 'optional')
     event          <-- port tick (event-literal / direction) lpar mcrl2-event rpar
     return         <-- port tick return-literal lpar arguments rpar
     arguments      <-  mcrl2-event- (comma reply compound-type compound-value)?
     mcrl2-event    <-  model tick direction tick event-name
     mcrl2-event-   <   mcrl2-event
     comma          <   ',' ' '*
     reply          <   'reply_' identifier tick
     compound-type  <   (type tick)* type
     compound-value <-  lpar (scope tick)? (type tick)? (identifier / number) rpar
     scope          <   identifier
     model          <   identifier
     port           <-  identifier
     type           <-  identifier
     event-name     <-  identifier
     identifier     <-- [a-zA-Z_][a-zA-Z0-9_]*
     number         <-- '-'? [0-9]+
     event-literal  <   'event'
     return-literal <   'return' / 'reply_in' / 'reply_out'
")
  (let* ((match (match-pattern trace input))
         (end (peg:end match))
         (tree (peg:tree match)))
    (if (eq? (string-length input) end)
        (if (symbol? tree) '()
            (cdr tree))
        (if match
            (begin
              (format (current-error-port) "parse error: at offset: ~a\n~s\n" end tree)
              #f)
            (begin
              (format (current-error-port) "parse error: no match\n")
              #f)))))

(define (parse-tree2text tree)
  (match tree
         (('event ('identifier port) ('identifier event)) (string-append port "." event))
         (('return ('identifier port) ('identifier "void")) (string-append port ".return"))
         (('return ('identifier port) ('identifier value)) (string-append port "." value))
         (('return ('identifier port) ('number value)) (string-append port "." value))
         (('return ('identifier port) (('identifier type) ('identifier value))) (string-append port "." type "_" value))))

;;(format #t "~a" (string-join (map parse-tree2text (pk "FOO:" (parse trace))) "\n"))

(define (rename-lts-actions trace)
  (string-join (map parse-tree2text (parse trace)) "\n"))


(define (make-json-trace modelname tracefile dir file-name outfile)
  (let* ((cwd (getcwd))
         (outfile (canonicalize-path outfile))
         (command (string-append "seqdiag -m " modelname " -t " tracefile " " file-name " > " outfile)))
    (chdir dir)
    (if (gdzn:command-line:get 'debug) (stderr "seqdiag command: ~s\n" command))
    (system command)
    (chdir cwd))
  (if (gdzn:command-line:get 'json) (display (gulp-file outfile))))

(define (make-trace tracefile option dir file-name modelname)
  (let ((outfile (string-append modelname option ".trc")))
    (system (string-append "tracepp " tracefile " > trace1.txt"))
    (let ((trace (rename-lts-actions "trace1.txt")))
      (with-output-to-file outfile (cut display trace))
      (make-json-trace modelname outfile dir file-name (string-append outfile ".json"))
      (if (gdzn:command-line:get 'json) "" trace))))

(define (make-trace-file tracefile option dir file-name modelname)
  (let ((outfile (format #f "~a~a.trc" modelname option))
        (trace-file "trace1.txt"))
    (system (string-append "tracepp " tracefile " > " trace-file))
    (rename-lts-actions (call-with-input-file trace-file read-string))))
