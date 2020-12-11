;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2019, 2020 Rob Wieringa <Rob.Wieringa@verum.com>
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

(define-module (dzn parse peg)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)

  #:use-module (dzn peg)
  #:use-module (dzn parse ast)

  #:re-export (%peg:locations?
               %peg:skip?
               %peg:fall-back?
               %peg:debug?
               %peg:error)

  #:export (peg:imports
            peg:parse
            peg:skip-parse
            peg:import-skip-parse))

(define-skip-parser peg-eof none (not-followed-by peg-any))
(define-skip-parser peg-eol none (or "\f" "\n" "\r" "\v"))
(define-skip-parser peg-ws none (or " " "\t"))
(define-skip-parser peg-line all (and "//" (* (and (not-followed-by peg-eol) peg-any))))
(define-skip-parser peg-block-strict all (and "/*" (* (or peg-block (and (not-followed-by "*/") peg-any))) (expect "*/")))
(define-skip-parser peg-skip all (* (or peg-ws peg-eol peg-line peg-block-strict)))

(define-skip-parser peg-block all (and "/*" (* (or peg-block (and (not-followed-by "*/") peg-any))) (or "*/" peg-eof)))
(define-skip-parser peg-import-skip all (* (or peg-ws peg-eol peg-line peg-block)))

(define (peg:imports string)
  (define-peg-string-patterns
    "root <- (import / SKIP+)*
import <-- IMPORT file-name SEMICOLON
IMPORT < 'import' ![a-zA-Z_0-9]
file-name <- (!SEMICOLON .)+
SEMICOLON < ';'
SKIP < !IMPORT . 'import'*")
  (peg:tree (match-pattern root string)))

(define peg:skip-parse peg-skip)
(define peg:import-skip-parse peg-import-skip)

(define* (peg:parse string)
  (define interface-events '())

  (define (-reset-event-names- str len pos)
    (set! interface-events '())
    (list pos '()))
  (define-peg-pattern reset-event-names none -reset-event-names-)

  (define (-event-name- str len pos)
    (let ((res (name str len pos)))
      (when res
        (set! interface-events (cons (substring str pos (car res)) interface-events)))
      res))
  (define-peg-pattern event-name all -event-name-)

  (define (-is-event- str len pos)
    (let ((res (name str len pos)))
      (and res (member (substring str pos (car res)) interface-events) res)))
  (define-peg-pattern is-event body -is-event-)

  (define port-names '())

  (define (-reset-port-names- str len pos)
    (set! port-names '())
    (list pos '()))
  (define-peg-pattern reset-port-names none -reset-port-names-)

  (define (-port-name- str len pos)
    (let ((res (name str len pos)))
      (when res
        (set! port-names (cons (substring str pos (car res)) port-names)))
      res))
  (define-peg-pattern port-name body -port-name-)

  (define (-is-port- str len pos)
    (let ((res (name str len pos)))
      (and res (member (substring str pos (car res)) port-names) res)))
  (define-peg-pattern is-port body -is-port-)


  (define variable-stack '(()))

  (define (-enter-frame- str len pos)
    (set! variable-stack (cons (car variable-stack) variable-stack))
    (list pos '()))
  (define-peg-pattern enter-frame none -enter-frame-)

  (define (-exit-frame- str len pos)
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
  (define-peg-pattern add-var body -add-var-)

  (define (-var- str len pos)
    (let* ((res (name str len pos))
           (top (car variable-stack))
           (var-name (and res (substring str pos (car res)))))
      (and var-name
           (find (cut equal? var-name <>) top)
           res)))
  (define-peg-pattern var all -var-)

  (define (dollars-no-skip str len pos)
    (parameterize ((%peg:skip? (lambda (str strlen at) `(,at ()))))
      (dollars- str len pos)))

  ;; TODO: come up with lexical scope construct (see spirit), i.e. disable skip parser locally
  (define-peg-pattern dollars all dollars-no-skip)

  (define-peg-string-patterns
    "root <-- (import / dollars / type / namespace / interface / component / EOF)#*

dollars- <- DOLLAR (!DOLLAR !NEWLINE .)* DOLLAR#

import <-- IMPORT file-name SEMICOLON#
  file-name <- (!SEMICOLON .)+

type <- enum / int / extern
  enum <-- ENUM compound-name# BRACE-OPEN# fields# BRACE-CLOSE# SEMICOLON#
    fields <-- (name (&BRACE-CLOSE / COMMA#))+

  int <-- SUBINT compound-name# BRACE-OPEN# range# BRACE-CLOSE# SEMICOLON#
    range <-- from DOTDOT# to
    from <-- NUMBER#
    to <-- NUMBER#

  extern <-- EXTERN compound-name# dollars# SEMICOLON#

namespace <-- NAMESPACE compound-name# BRACE-OPEN# namespace-root BRACE-CLOSE#
  namespace-root <-- (type / namespace / interface / component / &BRACE-CLOSE)#*

interface <-- INTERFACE reset-event-names reset-port-names compound-name# BRACE-OPEN# types-and-events# behaviour# BRACE-CLOSE#

  types-and-events <-- (type / event / &behaviour)#+
    event <-- direction type-name# event-name# formals# SEMICOLON#
      direction <-- IN / OUT

component <-- COMPONENT reset-port-names reset-event-names compound-name# BRACE-OPEN# ports# body# BRACE-CLOSE#
  body <- behaviour / system / &BRACE-CLOSE
    system <-- SYSTEM BRACE-OPEN# instances-and-bindings BRACE-CLOSE#
      instances-and-bindings <-- (instance / binding)*
        instance <-- compound-name name SEMICOLON#
        binding <-- end-point BIND end-point SEMICOLON#
          end-point <-- compound-name (DOT ASTERISK)? / ASTERISK

  ports <-- (port / &BEHAVIOUR / &SYSTEM / &BRACE-CLOSE)#*
    port <-- port-direction port-qualifiers? compound-name# formals? port-name# SEMICOLON#
      port-direction <- provides / requires
      port-qualifiers <-- (external / injected / &compound-name)*
      formals <-- PAREN-OPEN (formal (&PAREN-CLOSE / COMMA#))* PAREN-CLOSE#
        formal <-- (INOUT / IN / OUT)? type-name add-var

type-name <-- compound-name / BOOL / VOID

behaviour <-- BEHAVIOUR (name)? behaviour-compound
  behaviour-compound <-- BRACE-OPEN# enter-frame behaviour-statements BRACE-CLOSE# exit-frame
    behaviour-statements <- (port / function / variable / declarative-statement / type / &BRACE-CLOSE)#*
      function <-- type-name name &(formals BRACE-OPEN) enter-frame formals BRACE-OPEN# (imperative-statement  / !unknown-identifier)#* BRACE-CLOSE# exit-frame

declarative-statement <- on / blocking / guard / compound
  on <-- ON (illegal-triggers COLON# illegal /
             enter-frame triggers# COLON# (statement / !unknown-identifier)# exit-frame)

    illegal-triggers <-- (illegal-trigger (&COLON / COMMA)#)+
      illegal-trigger <-- is-port DOT# name# trigger-formals? / is-event

    triggers <-- ((trigger / !unknown-identifier) (&COLON / COMMA)#)#+
      trigger <-- is-port DOT# name# trigger-formals# / OPTIONAL / INEVITABLE / is-event
        trigger-formals <-- PAREN-OPEN (trigger-formal (&PAREN-CLOSE / COMMA#))* PAREN-CLOSE#
          trigger-formal <-- add-var (LEFT-ARROW var)?

  guard <-- BRACKET-OPEN (otherwise / expression)# BRACKET-CLOSE# statement#

compound <-- BRACE-OPEN enter-frame (statement / !unknown-identifier)#* BRACE-CLOSE# exit-frame
  statement <- (declarative-statement / imperative-statement / !unknown-identifier)#

imperative-statement <- variable / assign / if-statement / illegal /
                        return / skip-statement / compound /
                        reply / action-or-call / interface-action SEMICOLON#

  interface-action <-- is-event

  action-or-call <- (action / call) SEMICOLON#
    action <-- is-port DOT# name# arguments#
    call <-- name arguments
      arguments <-- PAREN-OPEN (argument (&PAREN-CLOSE / COMMA#))* PAREN-CLOSE#
        argument <-- expression

  skip-statement <-- SEMICOLON

  blocking <-- BLOCKING statement

  illegal <-- ILLEGAL SEMICOLON# / BRACE-OPEN ILLEGAL SEMICOLON# BRACE-CLOSE#

  assign <-- var ASSIGN expression# SEMICOLON#

  if-statement <-- IF PAREN-OPEN# expression# PAREN-CLOSE# imperative-statement# (ELSE imperative-statement#)?

  reply <-- (name DOT)? REPLY PAREN-OPEN# expression? PAREN-CLOSE# SEMICOLON#

  return <-- RETURN expression? SEMICOLON#

  variable <-- type-name add-var (ASSIGN expression#)? SEMICOLON#

expression <-- or-expression
or-expression <- and-expression OR or-expression# / and-expression
and-expression <- compare-expression AND and-expression# / compare-expression
compare-expression <- plus-min-expression !LEFT-ARROW COMPARE plus-min-expression# / plus-min-expression
plus-min-expression <- not-expression (PLUS / MINUS) not-expression# / not-expression
not-expression <- not / group / dollars / (!var !is-port enum-literal / field-test / literal / var !DOT / action / call / interface-action)
not <-- NOT not-expression#
enum-literal <-- scope name
field-test <-- !is-port var DOT name
literal <-- NUMBER / FALSE / TRUE
group <-- PAREN-OPEN expression PAREN-CLOSE#

name <-- identifier

compound-name <-- scope? name

scope <-- global? (name DOT &name)+ / global &name
  global <-- DOT

identifier <- !KEYWORD [a-zA-Z_] [a-zA-Z_0-9]*

unknown-identifier <- identifier

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
NEWLINE             <- '\n'

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
