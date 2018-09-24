;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017 Rob Wieringa <Rob.Wieringa@verum.com>
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

  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

  #:use-module (peg)
  #:use-module (peg cache)
  #:use-module (peg codegen)
  #:use-module (peg string-peg)

  #:use-module (gaiag command-line)

  #:use-module (system base compile)

  #:export (peg:parse))

(define-syntax my-define-sexp-parser
  (lambda (x)
    (syntax-case x ()
      ((_ sym accum pat)
       (let* ((matchf (compile-peg-pattern #'pat (syntax->datum #'accum))))
         #`(define sym #,matchf))))))

(my-define-sexp-parser eol none (or "\f" "\n" "\r"))
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
      (when (gdzn:command-line:get 'debug)
        (format (current-error-port) "~a ~a : ~s\n"
                (make-string (- pos (or (string-rindex str #\newline 0 pos) 0)) #\space)
                '#,s-syn
                (substring str pos (min (+ pos 40) strlen))))

      (let* ((comment-res (comment str strlen pos))
             (pos (or (and comment-res (car comment-res)) pos))
             (res (#,parser str strlen pos)))
        ;; Try to match the nonterminal.
        (if res
            ;; If we matched, do some post-processing to figure out
            ;; what data to propagate upward.
            (let* ((at (car res))
                   (body (cadr res))
                   (loc `(location ,pos ,at))
                   (annotate (if (null? (cadr comment-res)) `(,loc)
                                 `((comment ,(cadr comment-res)) ,loc))))
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

(define (line-column input pos)
    (let* ((length (string-length input))
           (pos (let loop ((pos pos))
                  (if (and (< pos length) (char-whitespace? (string-ref input pos))) (loop (1+ pos)) pos))))
      (let loop ((lines (string-split input #\newline)) (ln 1) (p 0))
      (if (null? lines) (values #f #f input)
          (let* ((line (car lines))
                 (length (string-length line))
                 (end (+ p length 1)))
            (if (<= pos end) (values ln (- pos p) line)
                (loop (cdr lines) (1+ ln) end)))))))

(define (peg:parse string)

  (define interface-events '())

  (define-peg-pattern always none (followed-by peg-any))

  (define (-reset-event-names- str len pos)
    (set! interface-events '())
    (always str len pos))
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

  (define-peg-string-patterns
    "root <-- top* eof#

eof < !.

top <- import / namespace / type / extern / interface / component / data

import <-- IMPORT (!SEMICOLON .)* SEMICOLON#

namespace <-- NAMESPACE compound-name# BRACE-OPEN# top* BRACE-CLOSE#

type <- enum / int

enum <-- ENUM compound-name# BRACE-OPEN# fields# BRACE-CLOSE# SEMICOLON#

fields <-- name# (COMMA name#)*

int <-- SUBINT compound-name# BRACE-OPEN# range# BRACE-CLOSE# SEMICOLON#

range <-- integer# '..'# integer#

extern <-- EXTERN compound-name# data# SEMICOLON#

interface <-- INTERFACE reset-event-names compound-name# BRACE-OPEN# types-or-events# behaviour# BRACE-CLOSE#

types-or-events <-- (type / extern / event)+


formal-parameter <-- (INOUT / IN / OUT)? type-name name

formal-list <-- PAREN-OPEN (formal-parameter (COMMA formal-parameter#)*)? PAREN-CLOSE#

event <-- direction type-name# event-name# formal-list SEMICOLON#

component <-- COMPONENT reset-event-names compound-name# BRACE-OPEN# ports (behaviour / system)? BRACE-CLOSE#

ports <-- port*

port <-- port-direction compound-name# formal-list? name# SEMICOLON#

port-direction <-- PROVIDES (EXTERNAL)? / REQUIRES (INJECTED / EXTERNAL)?

behaviour <-- BEHAVIOUR (name)? behaviour-compound

behaviour-compound <-- BRACE-OPEN# behaviour-statement* BRACE-CLOSE#

behaviour-statement <- port / function-declaration / variable / declarative-statement / type

statement <- declarative-statement / imperative-statement

declarative-statement <- on / blocking-statement / guard / compound

imperative-statement <- (reply / action-or-call / interface-action-or-call) SEMICOLON /
                        assign / if-statement / illegal / compound /
                        return-statement / variable / skip-statement

compound <-- BRACE-OPEN statement* BRACE-CLOSE#

on <-- ON triggers# COLON# statement#

interface-action-or-call <- (interface-action / interface-call)

argument-list <- PAREN-OPEN (argument (COMMA argument)*)? PAREN-CLOSE#

interface-action <-- is-event / name DOT name

action-or-call <- (action / call)

action <-- (is-event / name DOT name) argument-list

interface-call <-- !is-event name

call <-- !is-event name argument-list


guard <-- BRACKET-OPEN (OTHERWISE / expression)# BRACKET-CLOSE# statement#

skip-statement <-- SEMICOLON

triggers <-- trigger (COMMA trigger)*

trigger <-- (is-event / compound-name) argument-list? / OPTIONAL / INEVITABLE


argument <-- !PAREN-CLOSE expression

blocking-statement <-- BLOCKING statement

illegal <- ILLEGAL SEMICOLON#

assign <-- var ASSIGN expression SEMICOLON#

if-statement <-- IF PAREN-OPEN# expression PAREN-CLOSE# imperative-statement (ELSE imperative-statement)?

reply <-- (name DOT)? REPLY PAREN-OPEN# (expression)? PAREN-CLOSE#

return-statement <-- RETURN expression? SEMICOLON#




integer <- UNARY-MINUS? unsigned

unsigned <- [0-9]+


identifier <- !KEYWORD ([a-zA-Z_] [a-zA-Z_0-9]*)

dollar-string <- (!DOLLAR .)*

data <-- DOLLAR dollar-string DOLLAR

compound-name <-- DOT? name (DOT name)*

name <-- identifier

var <-- identifier

direction <-- IN / OUT

type-name <-- compound-name / BOOL

function-declaration <-- type-name name formal-list
    BRACE-OPEN# (imperative-statement)* BRACE-CLOSE#

variable <-- type-name name (ASSIGN expression#)? SEMICOLON#

expression <- or-expression
or-expression <- and-expression OR or-expression# / and-expression
and-expression <- compare-expression AND and-expression# / compare-expression
compare-expression <- plus-min-expression COMPARE plus-min-expression# / plus-min-expression
plus-min-expression <- not-expression (PLUS / MINUS) not-expression# / not-expression
not-expression <- NOT not-expression# / base-expression

base-expression <- paren-expression / dollar-expression / named-expression

named-expression <- action-or-call / enum-literal / literal / blocking-binding / var

enum-literal <-- DOT? name (DOT name)+

literal <-- integer / FALSE / TRUE

blocking-binding <-- var LEFT-ARROW var

paren-expression <-- PAREN-OPEN expression PAREN-CLOSE#

dollar-expression <-- data

system <-- SYSTEM BRACE-OPEN# instances bindings BRACE-CLOSE#

instances <-- (instance)*

instance <-- compound-name name SEMICOLON#

bindings <-- (binding)*

binding <-- name-with-wildcard BIND name-with-wildcard SEMICOLON#

name-with-wildcard <-- compound-name (DOT STAR)? / STAR

UNARY-MINUS         <- '-'

DOLLAR              <  '$'
COMMENT-OPEN        <  '/*'
COMMENT-CLOSE       <  '*/'
COMMENT             <  '//'
BRACE-OPEN          <  '{'
BRACE-CLOSE         <  '}'
BRACKET-OPEN        <  '['
BRACKET-CLOSE       <  ']'
PAREN-OPEN          <  '('
PAREN-CLOSE         <  ')'
SEMICOLON           <  ';'
COLON               <  ':'
DOT                 <  '.'
COMMA               <  ','
BIND                <  '<=>'
ASSIGN              <  '='
STAR                <  '*'
LEFT-ARROW          <  '<-'
OR                  <- '||'
AND                 <- '&&'
EQUAL               <- '=='
NOT-EQUAL           <- '!='
LESS                <- '<'
LESS-EQUAL          <- '<='
GREATER             <- '>'
GREATER-EQUAL       <- '>='
PLUS                <- '+'
MINUS               <- '-'
NOT                 <- '!'

COMPARE             <- EQUAL / NOT-EQUAL / LESS-EQUAL / LESS / GREATER-EQUAL / GREATER


BEHAVIOUR           <  'behaviour' ![a-zA-Z_0-9]
BLOCKING            <- 'blocking' ![a-zA-Z_0-9]
BOOL                <- 'bool' ![a-zA-Z_0-9]
COMPONENT           <  'component' ![a-zA-Z_0-9]
ELSE                <  'else' ![a-zA-Z_0-9]
ENUM                <  'enum' ![a-zA-Z_0-9]
EXTERN              <  'extern' ![a-zA-Z_0-9]
EXTERNAL            <- 'external' ![a-zA-Z_0-9]
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
OTHERWISE           <- 'otherwise' ![a-zA-Z_0-9]
OUT                 <- 'out' ![a-zA-Z_0-9]
PROVIDES            <- 'provides' ![a-zA-Z_0-9]
REPLY               <  'reply' ![a-zA-Z_0-9]
REQUIRES            <- 'requires' ![a-zA-Z_0-9]
RETURN              <  'return' ![a-zA-Z_0-9]
SUBINT              <  'subint' ![a-zA-Z_0-9]
SYSTEM              <  'system' ![a-zA-Z_0-9]
TRUE                <- 'true' ![a-zA-Z_0-9]

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
  / 'true' ) ![a-zA-Z_0-9]

")

  (let* ((result (match-pattern root string))
         (tree (peg:tree result)))
    tree))
