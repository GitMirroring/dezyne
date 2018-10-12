;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag grammar)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

  #:use-module (peg)
  #:use-module (peg cache)
  #:use-module (peg codegen)
  #:use-module (peg string-peg)

  #:use-module (gaiag command-line)
  #:use-module (gaiag misc)

  #:use-module (system base compile)

  #:export (peg:parse %peg-locations? %skip-parser?))

(define %peg-locations? #f)
(define %skip-parser? #f)

(define-syntax my-define-sexp-parser
  (lambda (x)
    (syntax-case x ()
      ((_ sym accum pat)
       (let* ((matchf (compile-peg-pattern #'pat (syntax->datum #'accum))))
         #`(define sym #,matchf))))))

(my-define-sexp-parser eol none (or "\f" "\n" "\r" "\v"))
(add-peg-compiler! 'eol eol)

(my-define-sexp-parser ws none (or " " "\t"))
(add-peg-compiler! 'ws ws)

(my-define-sexp-parser line all (and "//" (* (and (not-followed-by eol) peg-any))))
(add-peg-compiler! 'line line)

(my-define-sexp-parser block all (and "/*" (* (or block (and (not-followed-by "*/") peg-any))) (expect "*/")))

(my-define-sexp-parser comment all (* (or ws eol line block)))
(add-peg-compiler! 'comment comment)


(define (wrap-parser-for-users for-syntax parser accumsym s-syn)
  #`(lambda (str strlen pos)
      (when (and #t (gdzn:debugity) (> (length (gdzn:debugity)) 1)) ;; PEG debug only with -d -d
        (format (current-error-port) "~a ~a : ~s\n"
                (make-string (- pos (or (string-rindex str #\newline 0 pos) 0)) #\space)
                '#,s-syn
                (substring str pos (min (+ pos 40) strlen))))

      (let* ((comment-res (if (not %skip-parser?) (list pos '())
                              (comment str strlen pos)))
             (pos (or (and comment-res (car comment-res)) pos))
             (res (#,parser str strlen pos)))
        ;; Try to match the nonterminal.
        (if res
            ;; If we matched, do some post-processing to figure out
            ;; what data to propagate upward.
            (let* ((at (car res))
                   (body (cadr res))
                   (loc `(location ,pos ,at))
                   (annotate (if (not %peg-locations?) '()
                                 (if (null? (cadr comment-res)) `(,loc)
                                     `((comment ,(cadr comment-res)) ,loc)))))
              #,(cond
                 ((eq? accumsym 'name)
                  #``(,at ,'#,s-syn ,@annotate))
                 ((eq? accumsym 'all)
                  #`(list at
                          (cond
                           ((not (list? body))
                            `(,'#,s-syn ,body ,@annotate))
                           ((null? body) `(,'#,s-syn ,@annotate))
                           ((symbol? (car body))
                            `(,'#,s-syn ,body ,@annotate))
                           (else (cons '#,s-syn (append body annotate))))))
                 ((eq? accumsym 'none) #``(,at () ,@annotate))
                 (else #``(,at ,body ,@annotate))))
            ;; If we didn't match, just return false.
            #f))))

(module-define! (resolve-module '(peg codegen)) 'wrap-parser-for-users wrap-parser-for-users)

(define (peg:parse string file-name)

  (define interface-events '())

  (define (-reset-event-names- str len pos)
    (set! interface-events '())
    (list pos '()))
  (define-peg-pattern reset-event-names none -reset-event-names-)

  (define (-event-name- str len pos)
    (let ((res (identifier str len pos)))
      (when res
        (set! interface-events (cons (substring str pos (car res)) interface-events)))
      res))
  (define-peg-pattern event-name all -event-name-)

  (define (-is-event- str len pos)
    (let ((res (identifier str len pos)))
      (and res (member (substring str pos (car res)) interface-events) res)))
  (define-peg-pattern is-event body -is-event-)




  (define variable-stack '(()))

  (define (-enter-frame- str len pos)
    ;;(warn 'enter-frame: variable-stack)
    (set! variable-stack (cons (car variable-stack) variable-stack))
    (list pos '()))
  (define-peg-pattern enter-frame none -enter-frame-)

  (define (-exit-frame- str len pos)
    ;;(warn 'exit-frame: variable-stack)
    (set! variable-stack (cdr variable-stack))
    (list pos '()))
  (define-peg-pattern exit-frame none -exit-frame-)

  (define (-add-var- str len pos)
    (let ((res (name str len pos))
          (top (car variable-stack))
          (bottom (cdr variable-stack)))
      (when res
        (set! variable-stack (cons (cons (substring str pos (car res)) top) bottom)))
      res))
  (define-peg-pattern add-var all -add-var-)

  (define (-var- str len pos)
    (let* ((top (car variable-stack))
           (res (identifier str len pos))
           (var-name (and res (substring str pos (car res)))))
      (and var-name
           (find (cut equal? var-name <>) top)
           res)))
  (define-peg-pattern var all -var-)

  (define (-do-import- str len pos)
    (let* ((res (import str len pos))
           (input-file-name file-name)
           (file-name (and res (string-trim-both (apply string-append (cdadr res)))))
           (root (and res ((@@ (gaiag parse) peg:parse-file) (string-append (dirname input-file-name) "/" file-name)))))
      (and res (list (car res) (list 'import file-name root)))))
  (define-peg-pattern do-import body -do-import-)

  (define-peg-string-patterns
    "root <-- top* EOF#

top <- do-import / namespace / type / interface / component / data

import <- IMPORT (!SEMICOLON .)+ SEMICOLON#

namespace <-- NAMESPACE compound-name# BRACE-OPEN# top* BRACE-CLOSE#

type <- enum / int / extern

enum <-- ENUM compound-name# BRACE-OPEN# fields# BRACE-CLOSE# SEMICOLON#
fields <-- (name (!BRACE-CLOSE COMMA# / !COMMA &BRACE-CLOSE))+

int <-- SUBINT compound-name# BRACE-OPEN# range# BRACE-CLOSE# SEMICOLON#

range <-- from# DOTDOT# to#
from <-- NUMBER
to <-- NUMBER

extern <-- EXTERN compound-name# data# SEMICOLON#

interface <-- INTERFACE reset-event-names compound-name# BRACE-OPEN# types-or-events# behaviour# BRACE-CLOSE#

types-or-events <-- (type / event)+

formals <-- PAREN-OPEN (formal (!PAREN-CLOSE COMMA# / !COMMA &PAREN-CLOSE))* PAREN-CLOSE#
formal <-- (INOUT / IN / OUT)? type-name add-var

trigger-formals <-- PAREN-OPEN (trigger-formal (!PAREN-CLOSE COMMA# / !COMMA &PAREN-CLOSE))* PAREN-CLOSE#
trigger-formal <-- out-formal / add-var

event <-- direction type-name# event-name# formals SEMICOLON#

component <-- COMPONENT reset-event-names compound-name# BRACE-OPEN# ports (behaviour / system)? BRACE-CLOSE#

ports <-- port*

port <-- port-direction compound-name# formals? name# SEMICOLON#

port-direction <- provides external? / requires (injected / external)?

behaviour <-- BEHAVIOUR (name)? behaviour-compound

behaviour-compound <-- BRACE-OPEN# enter-frame behaviour-statement* BRACE-CLOSE# exit-frame

behaviour-statement <- port / function / variable / declarative-statement / type

statement <- declarative-statement / imperative-statement

declarative-statement <- on / blocking / guard / compound

imperative-statement <- variable / assign / if / illegal /
                        return / skip-statement / compound /
                        (reply / action-or-call / interface-action-or-call) SEMICOLON#

compound <-- BRACE-OPEN enter-frame statement* BRACE-CLOSE# exit-frame

on <-- ON enter-frame triggers# COLON# statement# exit-frame

interface-action-or-call <- (interface-action / interface-call)

arguments <-- PAREN-OPEN (argument (!PAREN-CLOSE COMMA# / &PAREN-CLOSE))* PAREN-CLOSE#
argument <-- expression

interface-action <-- is-event

action-or-call <- (action / call)

action <-- name DOT name arguments

interface-call <-- !is-event name

call <-- !is-event name arguments


guard <-- BRACKET-OPEN (otherwise / expression)# BRACKET-CLOSE# statement#

skip-statement <-- SEMICOLON

triggers <-- (trigger (!COLON COMMA# / &COLON))*

trigger <-- is-event / OPTIONAL / INEVITABLE / name DOT name trigger-formals

blocking <-- BLOCKING statement

illegal <-- ILLEGAL SEMICOLON#

assign <-- name ASSIGN expression SEMICOLON#

if <-- IF PAREN-OPEN# expression PAREN-CLOSE# imperative-statement# (ELSE imperative-statement#)?

reply <-- (name DOT)? REPLY PAREN-OPEN# expression? PAREN-CLOSE#

return <-- RETURN expression? SEMICOLON#

identifier <- !KEYWORD [a-zA-Z_] [a-zA-Z_0-9]*

data <-- DOLLAR (!DOLLAR .)* DOLLAR

compound-name <-- scope? name
scope <-- global? (name DOT &name)+
global <-- DOT

name <-- identifier

direction <-- IN / OUT

type-name <-- compound-name / BOOL / VOID

function <-- type-name name &(formals BRACE-OPEN) enter-frame formals BRACE-OPEN# (imperative-statement)* BRACE-CLOSE# exit-frame

variable <-- type-name add-var (ASSIGN expression#)? SEMICOLON#

expression <-- or-expression
or-expression <- and-expression OR or-expression# / and-expression
and-expression <- compare-expression AND and-expression# / compare-expression
compare-expression <- plus-min-expression COMPARE plus-min-expression# / plus-min-expression
plus-min-expression <- not-expression (PLUS / MINUS) not-expression# / not-expression
not-expression <- not / group / data / named-expression
not <-- NOT not-expression#

named-expression <- action-or-call / field-test / enum-literal / literal / var

enum-literal <-- scope name
field-test <-- var DOT name

literal <-- NUMBER / FALSE / TRUE

out-formal <-- &(var LEFT-ARROW) add-var LEFT-ARROW var

group <-- PAREN-OPEN expression PAREN-CLOSE#

system <-- SYSTEM BRACE-OPEN# instances bindings BRACE-CLOSE#

instances <-- instance*
instance <-- compound-name name SEMICOLON#

bindings <-- bind*
bind <-- binding BIND binding SEMICOLON#
binding <-- compound-name (DOT ASTERISK)? / ASTERISK

otherwise <-- OTHERWISE
provides <-- PROVIDES
requires <-- REQUIRES
external <-- EXTERNAL
injected <-- INJECTED


NUMBER              <-  MINUS? [0-9]+
DOLLAR              <   '$'
COMMENT-OPEN        <   '/*'
COMMENT-CLOSE       <   '*/'
COMMENT             <   '//'
BRACE-OPEN          <   '{'
BRACE-CLOSE         <   '}'
BRACKET-OPEN        <   '['
BRACKET-CLOSE       <   ']'
PAREN-OPEN          <   '('
PAREN-CLOSE         <   ')'
SEMICOLON           <   ';'
COLON               <   ':'
DOT                 <   '.'
DOTDOT              <   '..'
COMMA               <   ','
BIND                <   '<=>'
ASSIGN              <   '='
ASTERISK            <   '*'
LEFT-ARROW          <   '<-'
OR                  <-  '||'
AND                 <-  '&&'
EQUAL               <-  '=='
NOT-EQUAL           <-  '!='
LESS                <-  '<'
LESS-EQUAL          <-  '<='
GREATER             <-  '>'
GREATER-EQUAL       <-  '>='
PLUS                <-  '+'
MINUS               <-  '-'
NOT                 <   '!'
EOF                 <   !.
COMPARE             <-  EQUAL / NOT-EQUAL / LESS-EQUAL / LESS / GREATER-EQUAL / GREATER


BEHAVIOUR           <  'behaviour' ![a-zA-Z_0-9]
BLOCKING            <  'blocking' ![a-zA-Z_0-9]
BOOL                <- 'bool' ![a-zA-Z_0-9]
COMPONENT           <  'component' ![a-zA-Z_0-9]
ELSE                <  'else' ![a-zA-Z_0-9]
ENUM                <  'enum' ![a-zA-Z_0-9]
EXTERN              <  'extern' ![a-zA-Z_0-9]
EXTERNAL            <  'external' ![a-zA-Z_0-9]
FALSE               <- 'false' ![a-zA-Z_0-9]
IF                  <  'if' ![a-zA-Z_0-9]
ILLEGAL             <  'illegal' ![a-zA-Z_0-9]
IMPORT              <  'import' ![a-zA-Z_0-9]
IN                  <- 'in' ![a-zA-Z_0-9]
INEVITABLE          <- 'inevitable' ![a-zA-Z_0-9]
INJECTED            <  'injected' ![a-zA-Z_0-9]
INOUT               <- 'inout' ![a-zA-Z_0-9]
INTERFACE           <  'interface' ![a-zA-Z_0-9]
NAMESPACE           <  'namespace' ![a-zA-Z_0-9]
ON                  <  'on' ![a-zA-Z_0-9]
OPTIONAL            <- 'optional' ![a-zA-Z_0-9]
OTHERWISE           <  'otherwise' ![a-zA-Z_0-9]
OUT                 <- 'out' ![a-zA-Z_0-9]
PROVIDES            <  'provides' ![a-zA-Z_0-9]
REPLY               <- 'reply' ![a-zA-Z_0-9]
REQUIRES            <  'requires' ![a-zA-Z_0-9]
RETURN              <  'return' ![a-zA-Z_0-9]
SUBINT              <  'subint' ![a-zA-Z_0-9]
SYSTEM              <  'system' ![a-zA-Z_0-9]
TRUE                <- 'true' ![a-zA-Z_0-9]
VOID                <- 'void'

KEYWORD <
  ( 'behaviour'
  / 'blocking'
  / 'bool'
  / 'component'
  / 'else'
  / 'enum'
  / 'extern'
  / 'external'
  / 'false'
  / 'if'
  / 'illegal'
  / 'import'
  / 'in'
  / 'inevitable'
  / 'injected'
  / 'inout'
  / 'interface'
  / 'namespace'
  / 'on'
  / 'optional'
  / 'otherwise'
  / 'out'
  / 'provides'
  / 'reply'
  / 'requires'
  / 'return'
  / 'subint'
  / 'system'
  / 'true'
  / 'void') ![a-zA-Z_0-9]

")

  (set! %peg-locations? #t)
  (set! %skip-parser? #t)
  (let* ((result (match-pattern root string))
         (tree (peg:tree result)))
    ;;(set! %peg-locations? #f)
    ;;(set! %skip-parser? #f)
    tree))
