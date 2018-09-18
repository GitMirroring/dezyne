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

  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 receive)

  #:use-module (peg)
  #:use-module (peg cache)
  #:use-module (peg codegen)
  #:use-module (peg string-peg)

  #:use-module (gaiag command-line)

  #:export (peg:parse))

(define %peg-locations? #f)

(define (wrap-parser-for-users for-syntax parser accumsym s-syn)
  #`(lambda (str strlen pos)
      (when (or #f (gdzn:command-line:get 'debug))
        (format (current-error-port) "~a ~a : ~s\n"
                (make-string (- pos (or (string-rindex str #\newline 0 pos) 0)) #\space)
                '#,s-syn
                (substring str pos (min (+ pos 40) strlen))))

      (let* ((res (#,parser str strlen pos)))
        (and #f res (format (current-error-port) "~a: ~s\n"
                         '#,s-syn
                         (substring str pos (min (+ pos 40) strlen))))
        ;; Try to match the nonterminal.
        (if res
            ;; If we matched, do some post-processing to figure out
            ;; what data to propagate upward.
            (let ((at (car res))
                  (body (cadr res)))
              #,(cond
                 ((eq? accumsym 'name)
                  #`(list at '#,s-syn))
                 ((eq? accumsym 'all)
                  #`(list (car res)
                          (cond
                           ((not (list? body))
                            (list '#,s-syn body))
                           ((null? body) '#,s-syn)
                           ((symbol? (car body))
                            (if %peg-locations? (list '#,s-syn body (list 'location pos at)) (list '#,s-syn body)))
                           (else (if %peg-locations? (cons '#,s-syn (append body (list (list 'location pos at)))) (cons '#,s-syn body))))))
                 ((eq? accumsym 'none) #`(list (car res) '()))
                 (else #`(begin res))))
            ;; If we didn't match, just return false.
            #f))))

(define (cg-expect-int clauses accum str strlen at)
  (syntax-case clauses ()
    ((pat)
     #`(or (#,(compile-peg-pattern #'pat accum) #,str #,strlen #,at)
           (throw 'parse-error (list #,at (syntax->datum #'pat)))))))

(define (cg-expect clauses accum)
  #`(lambda (str len pos)
      #,(cg-expect-int clauses ((@@ (ice-9 peg codegen) baf) accum) #'str #'len #'pos)))

(add-peg-compiler! 'expect cg-expect)

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

(define (peg:parse input)

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
  (define-peg-pattern event-name body -event-name-)

  (define (-is-event- str len pos)
    (let ((res (identifier str len pos)))
      (and res (member (substring str pos (car res)) interface-events) res)))
  (define-peg-pattern is-event body -is-event-)

  (define-peg-string-patterns
    "root <-- (w elements)* w eof#

eof < !.

elements <- import / namespace / type / extern / interface / component / data

import <-- IMPORT w (!SEMICOLON .)* SEMICOLON#

namespace <-- NAMESPACE w compound-name# w BRACE-OPEN#(w elements)* w BRACE-CLOSE#

type <- enum / int

enum <-- ENUM w compound-name# w BRACE-OPEN# w fields# w BRACE-CLOSE# w SEMICOLON#

fields <-- name (w COMMA w name)*

int <-- SUBINT w compound-name# w BRACE-OPEN# w range# BRACE-CLOSE# w SEMICOLON#

range <-- integer w '..'# w integer# w

extern <-- EXTERN w compound-name# w data# w SEMICOLON#

interface <-- INTERFACE reset-event-names w compound-name# w BRACE-OPEN# types-and-events (w behaviour)? w BRACE-CLOSE#

types-and-events <-- (w type / w extern / w event)*

event <-- direction w type-name# w event-name# w
   PAREN-OPEN#(w formal-parameter (w COMMA w formal-parameter)*)? w PAREN-CLOSE# w SEMICOLON#

component <-- COMPONENT reset-event-names w compound-name# w BRACE-OPEN# ports (w behaviour / w system-declaration)? w BRACE-CLOSE#

ports <-- (w port)*

port <-- port-direction w compound-name# w name# w SEMICOLON#

port-direction <-- PROVIDES (w EXTERNAL)? / REQUIRES ( w INJECTED / w EXTERNAL)?

behaviour <-- BEHAVIOUR (w name)? w BRACE-OPEN#
  (w (function-declaration / variable-declaration / declarative-statement / type))*
  w BRACE-CLOSE#

behaviour-statement <- declarative-statement / imperative-statement

declarative-statement <- on / blocking-statement / guarded-statement / compound

imperative-statement <- (reply / action-or-call / interface-action-or-call) w SEMICOLON /
                        assign / if-statement / illegal-statement / compound /
                        return-statement / variable-declaration / skip

compound <-- BRACE-OPEN (w behaviour-statement)* w BRACE-CLOSE#

on <-- ON w triggers# w COLON# w behaviour-statement#

interface-action-or-call <- (interface-action / interface-call)

argument-list <- w PAREN-OPEN (w argument (w COMMA w argument)*)? w PAREN-CLOSE#

interface-action <-- is-event / name DOT name

action-or-call <- (action / call)

action <-- (is-event / name DOT name) argument-list

interface-call <-- !is-event name

call <-- !is-event name argument-list


guarded-statement <-- BRACKET-OPEN w guard# w BRACKET-CLOSE# w behaviour-statement#

guard <-- OTHERWISE / expression

skip <-- skip-haakjes

skip-haakjes < w SEMICOLON

triggers <-- trigger (w COMMA w trigger)*

trigger <-- (is-event / OPTIONAL / INEVITABLE / name DOT name) argument-list?


argument <-- !PAREN-CLOSE expression

blocking-statement <-- BLOCKING w behaviour-statement

illegal-statement <-- ILLEGAL w SEMICOLON#

assign <-- var w EQUAL w expression w SEMICOLON#

if-statement <-- IF w PAREN-OPEN# w expression w PAREN-CLOSE# w imperative-statement (w ELSE w imperative-statement)?

reply <-- (name DOT)? REPLY w PAREN-OPEN# (w expression)? w PAREN-CLOSE#

return-statement <-- RETURN w expression? w SEMICOLON#




integer <-- (UNARY-MINUS w)? unsigned

unsigned <- [0-9]+


identifier <- !KEYWORD ([a-zA-Z_] [a-zA-Z_0-9]*)

line-comment <-- COMMENT (!end-of-line .)* end-of-line

block-comment <-- COMMENT-OPEN (block-comment / !COMMENT-OPEN !COMMENT-CLOSE .)* COMMENT-CLOSE#


dollar-string <- (!DOLLAR .)*

data <-- DOLLAR dollar-string DOLLAR

compound-name <-- DOT? name (DOT name)*

name <-- identifier

var <-- identifier

direction <-- IN / OUT

type-name <-- compound-name / BOOL

formal-parameter <-- ((INOUT / IN / OUT) w)? type-name w name

function-declaration <-- type-name w name w
    PAREN-OPEN (w formal-parameter (w COMMA w formal-parameter)*)? w PAREN-CLOSE# w
    BRACE-OPEN# (w imperative-statement)* w BRACE-CLOSE#

variable-declaration <-- type-name w name (w EQUAL w expression#)? w SEMICOLON#

expression <-- or-expression (w LEFT-ARROW w or-expression#)?
or-expression <-- and-expression (w OR w or-expression#)?
and-expression <-- compare-expression (w AND w and-expression#)?
compare-expression <-- plus-min-expression (w compare-operator w plus-min-expression#)?
compare-operator <-- IS-EQUAL / IS-NOT-EQUAL / IS-LESS-EQUAL / IS-LESS / IS-GREATER-EQUAL / IS-GREATER
plus-min-expression <-- not-expression (w (PLUS / MINUS) w not-expression#)*
not-expression <-- NOT w not-expression# / base-expression

base-expression <-- named-expression / int-constant-expression /
                    bool-constant-expression / paren-expression / dollar-expression

named-expression <-- action-or-call / literal / var

literal <-- name (DOT name)+

int-constant-expression <-- integer

bool-constant-expression <-- FALSE / TRUE

paren-expression <-- PAREN-OPEN w expression w PAREN-CLOSE#

dollar-expression <-- data

system-declaration <-- SYSTEM w BRACE-OPEN# (w instantiation-statement / w binding-statement)* w BRACE-CLOSE#

instantiation-statement <-- compound-name w name w SEMICOLON#

binding-statement <-- name-with-wildcard w BIND w name-with-wildcard w SEMICOLON#

name-with-wildcard <-- compound-name (DOT STAR)? / STAR



white-space <- white-space-char / line-comment / block-comment

white-space-char < [ \t] / end-of-line

end-of-line < [\f\n\r]

w <- (white-space)*


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
EQUAL               <  '='
STAR                <  '*'
LEFT-ARROW          <  '<-'
OR                  <  '||'
AND                 <  '&&'
IS-EQUAL            <  '=='
IS-NOT-EQUAL        <  '!='
IS-LESS             <  '<'
IS-LESS-EQUAL       <  '<='
IS-GREATER          <  '>'
IS-GREATER-EQUAL    <  '>='
PLUS                <  '+'
MINUS               <  '-'
NOT                 <  '!'


BEHAVIOUR           <  'behaviour' ![a-zA-Z_0-9]
BLOCKING            <- 'blocking' ![a-zA-Z_0-9]
BOOL                <- 'bool' ![a-zA-Z_0-9]
COMPONENT           <  'component' ![a-zA-Z_0-9]
ELSE                <  'else' ![a-zA-Z_0-9]
ENUM                <  'enum' ![a-zA-Z_0-9]
EXTERN              <  'extern' ![a-zA-Z_0-9]
EXTERNAL            <- 'external' ![a-zA-Z_0-9]
FALSE               <  'false' ![a-zA-Z_0-9]
IF                  <  'if' ![a-zA-Z_0-9]
ILLEGAL             <- 'illegal' ![a-zA-Z_0-9]
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

  (set! %peg-locations? #t)
  (catch 'parse-error (lambda ()
                        (let* ((result (match-pattern root input))
                               (end (peg:end result))
                               (tree (peg:tree result)))
                          (set! %peg-locations? #f)
                          (display "tree:\n")
                          (pretty-print tree)
                          (newline)
                          tree))
    (lambda (key . args)
      (receive (ln col line) (line-column input (caar args))
        (let ((indent (make-string col #\space)))
          (format #t ":~a:~a\n~a\n~a^\n~aexpected ~a\n"
                  ln col line
                  indent
                  indent
                  (cadar args))
          (exit 1))))))

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
