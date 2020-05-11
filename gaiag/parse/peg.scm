;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2019, 2020 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

(define-module (gaiag parse peg)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)

  #:use-module (gaiag peg)
  #:use-module (gaiag parse ast)

  #:re-export (%peg:locations?
               %peg:skip?
               %peg:fall-back?
               %peg:debug?
               %peg:error)

  #:export (peg:parse
            peg:skip-parse))

(define-skip-parser peg-eol none (or "\f" "\n" "\r" "\v"))
(define-skip-parser peg-ws none (or " " "\t"))
(define-skip-parser peg-line all (and "//" (* (and (not-followed-by peg-eol) peg-any))))
(define-skip-parser peg-block all (and "/*" (* (or peg-block (and (not-followed-by "*/") peg-any))) (expect "*/")))
(define-skip-parser peg-skip all (* (or peg-ws peg-eol peg-line peg-block)))

(define peg:skip-parse peg-skip)

(define* (peg:parse string file-name #:key (imports '()))

  (define imported-files '())

  (define* (peg:parse-recursive string file-name #:key (imports '()))

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
      (unless (%peg:fall-back?)
        (set! variable-stack (cons (car variable-stack) variable-stack)))
      (list pos '()))
    (define-peg-pattern enter-frame none -enter-frame-)

    (define (-exit-frame- str len pos)
      (unless (%peg:fall-back?)
        (set! variable-stack (cdr variable-stack)))
      (list pos '()))
    (define-peg-pattern exit-frame none -exit-frame-)

    (define (-add-var- str len pos)
      (let ((res (identifier str len pos))
            (top (or (%peg:fall-back?) (car variable-stack)))
            (bottom (or (%peg:fall-back?) (cdr variable-stack))))
        (when res
          (or (%peg:fall-back?)
              (set! variable-stack (cons (cons (substring str pos (car res)) top) bottom))))
        res))
    (define-peg-pattern add-var all -add-var-)

    (define (-var- str len pos)
      (let* ((res (identifier str len pos))
             (top (or (%peg:fall-back?) (car variable-stack)))
             (var-name (and res (substring str pos (car res)))))
        (and var-name
             (or (%peg:fall-back?)
                 (find (cut equal? var-name <>) top))
             res)))
    (define-peg-pattern var all -var-)

    (define (-do-import- str len pos)
      (let ((res (import str len pos)))
        (and res
             (let* ((import-file-name (string-trim-both (apply string-append (cdadr res))))
                    (import-file-name (or (search-path imports import-file-name)
                                          (let ((pos (car res))
                                                (message (format #f "No such file: `~a' in [~a]\n" import-file-name (string-join imports))))
                                            ((@@ (gaiag parse) peg:error) file-name str pos message))))
                    (import-file-name (canonicalize-path import-file-name))
                    (root (if (member import-file-name imported-files) #f
                              (let* ((foo (set! imported-files (cons import-file-name imported-files)))
                                     (string (with-input-from-file import-file-name read-string))
                                     (imports (cons (dirname import-file-name) imports))
                                     (parse-tree (catch 'syntax-error
                                                   (lambda ()
                                                     (peg:parse-recursive string import-file-name #:imports imports))
                                                   ((@@ (gaiag parse) peg:handle-syntax-error) import-file-name string))))
                                (parse-tree->ast parse-tree #:string string #:file-name import-file-name)))))
               (list (car res) (list 'import import-file-name root))))))
    (define-peg-pattern do-import body -do-import-)

    (define (-do-file-command- str len pos)
      (let ((res (file-command str len pos)))
        (when res
          (let* ((body (cadr res))
                 (text (drop-right (drop body 1) 1))
                 (file-file-name (string-trim-both (apply string-append text))))
            (set! file-name file-file-name)))
        res))
    (define-peg-pattern do-file-command body -do-file-command-)

    (define-peg-string-patterns
      "root <-- top* EOF#

top <- do-import / stream-command / namespace / type / interface / component / data

import <- IMPORT (!SEMICOLON .)+ SEMICOLON#

stream-command <- do-file-command / imported-command
file-command <-- FILE dq-string#
imported-command <-- IMPORTED dq-string#
FILE < '#file'
IMPORTED < '#imported'
dq-string <- double-quote unq-string double-quote
double-quote < '\"'
unq-string <- ('\\\"' / !'\"' .)*

namespace <-- NAMESPACE compound-name# BRACE-OPEN# top* BRACE-CLOSE#

type <- enum / int / extern

enum <-- ENUM compound-name# BRACE-OPEN# fields# BRACE-CLOSE# SEMICOLON#
fields <-- (name (&BRACE-CLOSE / COMMA#))+

int <-- SUBINT compound-name# BRACE-OPEN# range# BRACE-CLOSE# SEMICOLON#

range <-- from# DOTDOT# to#
from <-- NUMBER
to <-- NUMBER

extern <-- EXTERN compound-name# data# SEMICOLON#

interface <-- INTERFACE reset-event-names compound-name# BRACE-OPEN# types-and-events# behaviour# BRACE-CLOSE#

types-and-events <-- (type / event)+

event <-- direction type-name# event-name# formals# SEMICOLON#

component <-- COMPONENT reset-event-names compound-name# BRACE-OPEN# ports# body# BRACE-CLOSE#

body <- behaviour / system / &BRACE-CLOSE

ports <-- (port / &BEHAVIOUR / &SYSTEM / &BRACE-CLOSE)#*

port <-- port-direction compound-name# formals? name# SEMICOLON#

port-direction <- provides external? / requires (injected / external)?

behaviour <-- BEHAVIOUR (name)? behaviour-compound

behaviour-compound <-- BRACE-OPEN# enter-frame behaviour-statement* BRACE-CLOSE# exit-frame

behaviour-statement <- port / function / variable / declarative-statement / type

statement <- declarative-statement / imperative-statement

declarative-statement <- on / blocking / guard / compound

imperative-statement <- variable / assign / if-statement / illegal /
                        return / skip-statement / compound /
                        (reply / action-or-call / interface-action-or-call) SEMICOLON#

compound <-- BRACE-OPEN enter-frame statement* BRACE-CLOSE# exit-frame

on <-- ON (illegal-triggers COLON illegal / enter-frame triggers# COLON# statement# exit-frame)

interface-action-or-call <- (interface-action / interface-call)

arguments <-- PAREN-OPEN (argument (&PAREN-CLOSE / COMMA#))* PAREN-CLOSE#
argument <-- expression

interface-action <-- is-event

action-or-call <- (action / call)

action <-- name DOT name arguments

interface-call <-- !is-event name

call <-- !is-event name arguments


guard <-- BRACKET-OPEN (otherwise / expression)# BRACKET-CLOSE# statement#

skip-statement <-- SEMICOLON

triggers <-- (trigger (&COLON / COMMA)#)+
trigger <-- is-event / OPTIONAL / INEVITABLE / name DOT# name# trigger-formals#

formals <-- PAREN-OPEN (formal (&PAREN-CLOSE / COMMA#))* PAREN-CLOSE#
formal <-- (INOUT / IN / OUT)? type-name add-var

trigger-formals <-- PAREN-OPEN (trigger-formal (&PAREN-CLOSE / COMMA#))* PAREN-CLOSE#
trigger-formal <-- add-var (LEFT-ARROW var)?

illegal-triggers <-- (illegal-trigger (&COLON / COMMA)#)+
illegal-trigger <-- is-event / name DOT# name# trigger-formals?

blocking <-- BLOCKING statement

illegal <-- ILLEGAL SEMICOLON# / BRACE-OPEN ILLEGAL SEMICOLON BRACE-CLOSE#

assign <-- name ASSIGN expression SEMICOLON#

if-statement <-- IF PAREN-OPEN# expression PAREN-CLOSE# imperative-statement# (ELSE imperative-statement#)?

reply <-- (name DOT)? REPLY PAREN-OPEN# expression? PAREN-CLOSE#

return <-- RETURN expression? SEMICOLON#

identifier <- !KEYWORD [a-zA-Z_] [a-zA-Z_0-9]*

data <-- DOLLAR (!DOLLAR .)* DOLLAR#

compound-name <-- scope? name
scope <-- global? (name DOT &name)+
global <-- DOT

name <-- identifier

direction <-- IN / OUT

type-name <-- compound-name / BOOL / VOID

function <-- type-name name &(formals BRACE-OPEN) enter-frame formals BRACE-OPEN# imperative-statement* BRACE-CLOSE# exit-frame

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
group <-- PAREN-OPEN expression PAREN-CLOSE#

system <-- SYSTEM BRACE-OPEN# instances-and-bindings BRACE-CLOSE#

instances-and-bindings <-- (instance / binding)*
instance <-- compound-name name SEMICOLON#
binding <-- end-point BIND end-point SEMICOLON#
end-point <-- compound-name (DOT ASTERISK)? / ASTERISK

otherwise <-- OTHERWISE
provides <-- PROVIDES
requires <-- REQUIRES
external <-- EXTERNAL
injected <-- INJECTED

NUMBER              <-  MINUS? [0-9]+
ASTERISK            <-  '*'
DOLLAR              <   '$'
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
VOID                <- 'void' ![a-zA-Z_0-9]

KEYWORD <
    'behaviour' ![a-zA-Z_0-9]
  / 'blocking' ![a-zA-Z_0-9]
  / 'component' ![a-zA-Z_0-9]
  / 'else' ![a-zA-Z_0-9]
  / 'enum' ![a-zA-Z_0-9]
  / 'extern' ![a-zA-Z_0-9]
  / 'external' ![a-zA-Z_0-9]
  / 'false' ![a-zA-Z_0-9]
  / 'if' ![a-zA-Z_0-9]
  / 'illegal' ![a-zA-Z_0-9]
  / 'import' ![a-zA-Z_0-9]
  / 'in' ![a-zA-Z_0-9]
  / 'inevitable' ![a-zA-Z_0-9]
  / 'injected' ![a-zA-Z_0-9]
  / 'inout' ![a-zA-Z_0-9]
  / 'interface' ![a-zA-Z_0-9]
  / 'namespace' ![a-zA-Z_0-9]
  / 'on' ![a-zA-Z_0-9]
  / 'optional' ![a-zA-Z_0-9]
  / 'otherwise' ![a-zA-Z_0-9]
  / 'out' ![a-zA-Z_0-9]
  / 'provides' ![a-zA-Z_0-9]
  / 'reply' ![a-zA-Z_0-9]
  / 'requires' ![a-zA-Z_0-9]
  / 'return' ![a-zA-Z_0-9]
  / 'subint' ![a-zA-Z_0-9]
  / 'system' ![a-zA-Z_0-9]
  / 'true' ![a-zA-Z_0-9]")

    (peg:tree (match-pattern root string)))

  (peg:parse-recursive string file-name #:imports imports))
