;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2018 Henk Katerberg <henk.katerberg@verum.com>
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
  #:use-module (gash pipe)

  #:export (main
            rename-lts-actions
            cleanup-lts
            mcrl2-trace-file->dzn-trace))

(define (find-aliases mcrl2file)
  (let* ((mcrl2-text (call-with-input-file "verify.mcrl2" read-string))
	 (aliases (map
		   (lambda (m) (match:substring m 1))
		   (list-matches "\\b([a-zA-Z0-9_']*)\\s*=\\s*struct\\b" mcrl2-text))))
    aliases))

(define trace "console'in(IConsole'action(IConsole'in'arm))
sensor'in(ISensor'action(ISensor'in'enable))
sensor'reply(ISensor'Void(void))
tau
console'reply(IConsole'Void(void))
tau
tau
tau
sensor'out(ISensor'action(ISensor'out'triggered))
console'out(IConsole'action(IConsole'out'detected))
siren'in(ISiren'action(ISiren'in'turnon))
siren'reply(ISiren'Void(void))
tau
tau
console'in(IConsole'action(IConsole'in'disarm))
sensor'in(ISensor'action(ISensor'in'disable))
sensor'reply(ISensor'Void(void))
tau
console'reply(IConsole'Void(void))
tau
tau
tau
sensor'out(ISensor'action(ISensor'out'disabled))
console'out(IConsole'action(IConsole'out'deactivated))
tau
tau
console'in(IConsole'action(IConsole'in'arm))
sensor'in(ISensor'action(ISensor'in'enable))
sensor'reply(ISensor'Void(void))
tau
console'reply(IConsole'Void(void))
tau
tau
tau
sensor'out(ISensor'action(ISensor'out'triggered))
console'out(IConsole'action(IConsole'out'detected))
siren'in(ISiren'action(ISiren'in'turnon))
illegal")

(define (parse input)
  (define-peg-string-patterns
    "trace              <-- ((event / modeling / reply / queue / tau-literal / illegal / error / end / flush / parse-error) newline?)*
     parse-error        <-- [a-zA-Z_0-9'()]*
     event              <-- port-name tick direction lpar scope* action-literal lpar scope* direction tick event-name rpar rpar
     modeling           <-- port-name tick internal-literal lpar scope* ('inevitable' / 'optional') rpar
     queue              <-- port-name tick queue-direction lpar scope* action-literal lpar scope* direction tick event-name rpar rpar
     end                <   scope* 'end'
     flush              <-- identifier tick 'flush'
     reply              <-- port-name tick reply-literal lpar scope* reply-value rpar
     scope              <   identifier tick
     interface-name     <   scope* identifier
     port-name          <-  identifier
     event-name         <-  identifier
     reply-value        <-  bool-literal lpar bool rpar / lpar enum-literal rpar / int-literal lpar int rpar / void-literal lpar void rpar
     bool-literal       <   'Bool'
     bool               <-- ('true' / 'false' )
     int-literal        <   'Int'
     int                <-- '-'?[0-9]+
     void-literal       <   'Void'
     void               <-- 'void'
     enum-name          <   identifier
     enum-literal       <-- (enum tick)* enum-field
     enum               <-  identifier
     enum-field         <-  identifier
     direction          <   'qin' / 'in' / 'out'
     queue-direction    <-- 'qout'
     action-literal     <   'action'
     internal-literal   <   'internal'
     reply-literal      <   'reply'
     tau-literal        <   'tau'
     illegal            <   'illegal' / 'declarative_illegal' / 'dillegal'
     error              <-- incomplete / queue-full / range-error / reply-error / missing-reply / second-reply
     queue-full         <-  'queue_full' / port-name tick 'queue_full'
     range-error        <-  'range_error'
     incomplete         <-  'incomplete'
     reply-error        <-  'double_reply_error' / 'no_reply_error'
     missing-reply      <-  'missing_reply'
     second-reply       <-  'second_reply'
     newline            <   '\n'
     tick               <   [']
     lpar               <   [(]
     rpar               <   [)]
     identifier         <-- &(direction [a-zA-Z0-9_]+) [a-zA-Z0-9_]+ / !direction [a-zA-Z_][a-zA-Z0-9_]*")
  (let* ((match (match-pattern trace input))
         (end (peg:end match))
         (tree (peg:tree match)))
    (if (eq? (string-length input) end)
        (if (symbol? tree) '()
            (cdr tree))
        (if match
            (begin
              (format (current-error-port) "input: ~a\nparse error: at offset: ~a\n~s\n" input end tree)
              #f)
            (begin
              (format (current-error-port) "parse error: no match\n")
              #f)))))

(define* (parse-tree2text tree #:key internal?)
  (match tree
    (('parse-error parse-error) (stderr "parse error:~s\n" tree) parse-error)
    (('error error) error)
    (('flush ('identifier port) "flush") (string-append port ".<flush>"))
    (('error ('identifier port) error) error)
    (('event ('identifier port) ('identifier event)) (string-append port "." event))
    (('modeling ('identifier port) event) (and internal? (string-append port "." event)))
    (('queue ('identifier port) ('queue-direction direction) ('identifier event)) (and internal? (string-append port "." direction "." event)))
    (('reply ('identifier port) ('void "void")) (string-append port ".return"))
    (('reply ('identifier port) ('bool value)) (string-append port "." value))
    (('reply ('identifier port) ('int value)) (string-append port "." value))
    (('reply ('identifier port) ('enum-literal scope ... ('identifier name) ('identifier field))) (string-append port "." name "_" field))
    (('reply ('identifier port) ('enum-literal (scope ... ('identifier name)) ('identifier field))) (string-append port "." name "_" field))))

;;(format #t "~a" (string-join (map parse-tree2text (parse trace)) "\n"))

(define (mcrl2-trace-file->dzn-trace mcrl2-trace-file)
  (cleanup-lts (pipeline->string `("tracepp" ,mcrl2-trace-file))))

(define (rename-lts-actions trace)
  (string-join (filter-map parse-tree2text (parse trace)) "\n"))

(define (cleanup-text text)
  (define (cleanup-line line)
    (let ((fris (parse line)))
      (and (pair? fris)
           (parse-tree2text (car fris)))))
  (string-join
   (filter-map cleanup-line (string-split text #\newline))
   "\n" 'suffix))

(define* (cleanup-lts text #:key internal?)
  (define (cleanup-node-label node)
    (or (and (= (length node) 3)
             (let* ((label ((compose (cut string-drop <> 1) (cut string-drop-right <> 1) cadr) node)))
               (or (and (not (string-null? label))
                        (let ((fris (parse label)))
                          (or (and (pair? fris)
                                   (let ((label (parse-tree2text (car fris) #:internal? internal?)))
                                     (and label
                                          (list (car node)
                                                (format #f "~s" label)
                                                (caddr node)))))
                              (if internal? node
                                  (list (car node)
                                        (format #f "~s" "tau")
                                        (caddr node)))))))))
        node))
  (let* ((lines (string-split text #\newline))
         (nodes (list-tail lines 1))
         (nodes (map (cut string-split <> #\,) nodes))
         (nodes (map cleanup-node-label nodes))
         (fris (map (cut string-join <> ",") nodes)))
    (string-join (cons (car lines) fris) "\n" 'suffix)))

(define (main arguments)
  (let* ((files (cdr arguments))
         (file (if (or (null? files)
                       (equal? (car files) "-")) "/dev/stdin"
                       (car files)))
         (text (string-trim-right (with-input-from-file file read-string)))
         (lts? (string-prefix? "des " text)))
    (if lts? (display (cleanup-lts text #:internal? #t))
        (display (cleanup-text text)))))
