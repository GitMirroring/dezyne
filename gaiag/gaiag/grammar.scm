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

  #:use-module (ice-9 receive)
  #:use-module (ice-9 peg)
  #:use-module (ice-9 peg cache)
  #:use-module (ice-9 peg codegen)

  #:use-module (gaiag command-line)

  #:export (peg:parse))

(define %peg-locations? #f)

(define (wrap-parser-for-users for-syntax parser accumsym s-syn)
  #`(lambda (str strlen pos)
      (when (gdzn:command-line:get 'debug)
        (format (current-error-port) "~a ~a : ~s\n"
                (make-string (- pos (or (string-rindex str #\newline 0 pos) 0)) #\space)
                '#,s-syn
                (substring str pos (min (+ pos 40) strlen))))

      (let* ((res (#,parser str strlen pos)))
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

(module-define! (resolve-module '(ice-9 peg codegen)) 'wrap-parser-for-users wrap-parser-for-users)

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
  (define-syntax xNN
    (syntax-rules ()
      ((_ xname name)
       (define-peg-pattern xname none (or name (and (not-followed-by name) error))))))

  (define-peg-pattern COMMENT-OPEN none "/*")
  (define-peg-pattern COMMENT-CLOSE none "*/")
  (define-peg-pattern START-LINE-COMMENT none "//")
  (define-peg-pattern CURLY-BRACKET-OPEN none "{")
  (define-peg-pattern CURLY-BRACKET-CLOSE none "}")
  (define-peg-pattern SQUARE-BRACKET-OPEN none "[")
  (define-peg-pattern SQUARE-BRACKET-CLOSE none "]")
  (define-peg-pattern PARENTHESIS-OPEN none "(")
  (define-peg-pattern PARENTHESIS-CLOSE none ")")
  (define-peg-pattern SEMICOLON none ";")
  (define-peg-pattern COLON none ":")
  (define-peg-pattern DOT-DOT none "..")
  (define-peg-pattern DOT none ".")
  (define-peg-pattern COMMA none ",")
  (define-peg-pattern BIND none "<=>")
  (define-peg-pattern EQUAL none "=")
  (define-peg-pattern STAR none "*")
  (define-peg-pattern LEFT-ARROW none "<-")
  (define-peg-pattern OR none "||")
  (define-peg-pattern AND none "&&")
  (define-peg-pattern IS-EQUAL none "==")
  (define-peg-pattern IS-NOT-EQUAL none "!=")
  (define-peg-pattern IS-LESS none "<")
  (define-peg-pattern IS-LESS-EQUAL none "<=")
  (define-peg-pattern IS-GREATER none ">")
  (define-peg-pattern IS-GREATER-EQUAL none ">=")
  (define-peg-pattern PLUS none "+")
  (define-peg-pattern MINUS none "-")
  (define-peg-pattern UNARY-MINUS body "-")
  (define-peg-pattern NOT none "!")
  (xNN  xCOMMENT-OPEN COMMENT-OPEN)
  (xNN  xCOMMENT-CLOSE COMMENT-CLOSE)
  (xNN  xSTART-LINE-COMMENT START-LINE-COMMENT)
  (xNN  xCURLY-BRACKET-OPEN CURLY-BRACKET-OPEN)
  (xNN  xCURLY-BRACKET-CLOSE CURLY-BRACKET-CLOSE)
  (xNN  xSQUARE-BRACKET-OPEN SQUARE-BRACKET-OPEN)
  (xNN  xSQUARE-BRACKET-CLOSE SQUARE-BRACKET-CLOSE)
  (xNN  xPARENTHESIS-OPEN PARENTHESIS-OPEN)
  (xNN  xPARENTHESIS-CLOSE PARENTHESIS-CLOSE)
  (xNN  xSEMICOLON (expect SEMICOLON))
  (xNN  xCOLON COLON)
  (xNN  xDOT-DOT DOT-DOT)
  (xNN  xDOT DOT)
  (xNN  xCOMMA COMMA)
  (xNN  xBIND BIND)
  (xNN  xEQUAL EQUAL)
  (xNN  xSTAR STAR)
  (xNN  xLEFT-ARROW LEFT-ARROW)
  (xNN  xOR OR)
  (xNN  xAND AND)
  (xNN  xIS-EQUAL IS-EQUAL)
  (xNN  xIS-NOT-EQUAL IS-NOT-EQUAL)
  (xNN  xIS-LESS IS-LESS)
  (xNN  xIS-LESS-EQUAL IS-LESS-EQUAL)
  (xNN  xIS-GREATER IS-GREATER)
  (xNN  xIS-GREATER-EQUAL IS-GREATER-EQUAL)
  (xNN  xPLUS PLUS)
  (xNN  xMINUS MINUS)
  (xNN  xNOT NOT)

  (define-peg-string-patterns
    "xroot <--
    (w top)* w

top <-
    import
  / namespace
  / type
  / extern
  / interface
  / component
  / !.

import <--
    IMPORT w (!SEMICOLON .)* xSEMICOLON

namespace <--
    NAMESPACE w compound-name w
    xCURLY-BRACKET-OPEN
      (w top)* w
    xCURLY-BRACKET-CLOSE

type <-
    enum
  / int

enum <--
    ENUM w compound-name w
    xCURLY-BRACKET-OPEN w
      fields w
    xCURLY-BRACKET-CLOSE w xSEMICOLON

fields <--
    name (w COMMA w name)*

int <--
    SUBINT w compound-name w
    xCURLY-BRACKET-OPEN w
      range
    xCURLY-BRACKET-CLOSE w xSEMICOLON

range <--
    integer w xDOT-DOT w integer w

extern <--
    EXTERN w compound-name w dollar-string w xSEMICOLON

interface <--
    INTERFACE w compound-name w
    xCURLY-BRACKET-OPEN
      types-and-events
      (w behaviour)? w
    xCURLY-BRACKET-CLOSE

types-and-events <--
    (w type / w extern / w event)*

event <--
    direction w type-name w name w
    xPARENTHESIS-OPEN
      (w formal-parameter (w COMMA w formal-parameter)*)? w
    xPARENTHESIS-CLOSE w xSEMICOLON

component <--
   COMPONENT w compound-name w
   xCURLY-BRACKET-OPEN
     ports
     (w behaviour / w system-declaration)? w
   xCURLY-BRACKET-CLOSE

ports <-- (w port)*

port <-- port-direction w compound-name w name w xSEMICOLON

port-direction <--
    PROVIDES (w EXTERNAL)?
  / REQUIRES ( w INJECTED / w EXTERNAL)?

behaviour <--
    BEHAVIOUR (w name)? w
    xCURLY-BRACKET-OPEN (w type)*
      (w function-declaration / w variable-declaration / w behaviour-statement)* w
    xCURLY-BRACKET-CLOSE





behaviour-statement <- declarative-statement / imperative-statement

declarative-statement <-
    blocking-statement
  / compound
  / guarded-statement
  / on

imperative-statement <-
    action-or-call
  / assignment-statement
  / if-statement
  / illegal-statement
  / imperative-compound
  / reply-statement
  / return-statement
  / skip

declarative-compound
  <-- CURLY-BRACKET-OPEN declarative-statement-list xCURLY-BRACKET-CLOSE

compound
  <-- CURLY-BRACKET-OPEN behaviour-statement-list xCURLY-BRACKET-CLOSE

on
  <-- on-literal w triggers w xCOLON w behaviour-statement

imperative-compound
  <-- CURLY-BRACKET-OPEN imperative-statement-list xCURLY-BRACKET-CLOSE

imperative-statement-list
  <-- (variable-declaration w / imperative-statement w)*

action-or-call
  <-- compound-with-arguments w SEMICOLON









guarded-statement <--
    SQUARE-BRACKET-OPEN w guard w xSQUARE-BRACKET-CLOSE w behaviour-statement

guard
  <-- expression
    / OTHERWISE

behaviour-statement-list
  <-- (variable-declaration w / behaviour-statement w)*

declarative-statement-list
  <-- (declarative-statement w)*

skip <-- skip-haakjes

skip-haakjes < w SEMICOLON

on-literal < ON

triggers
  <-- (trigger) (w COMMA w trigger)*
    / OPTIONAL
    / INEVITABLE

trigger
  <-- compound-with-arguments

compound-with-arguments
  <-- compound-name (w PARENTHESIS-OPEN (w argument (w COMMA w argument)*)? w xPARENTHESIS-CLOSE)?

argument
  <-- expression

blocking-statement
  <-- BLOCKING w behaviour-statement

illegal-statement
  <-- ILLEGAL w xSEMICOLON

assignment-statement
  <-- name w EQUAL w expression w xSEMICOLON

if-statement
  <-- IF w xPARENTHESIS-OPEN w expression w xPARENTHESIS-CLOSE w
      behaviour-statement
      (w ELSE w behaviour-statement)?

reply-statement
  <-- (compound-name DOT)? REPLY w
      xPARENTHESIS-OPEN (w expression)? w xPARENTHESIS-CLOSE w xSEMICOLON

return-statement
  <-- RETURN w expression? w xSEMICOLON







integer <-- (UNARY-MINUS w)? unsigned

unsigned <- NUM+


identifier
  <-- !KEYWORD (ALPHA ALPHANUM*)

line-comment
  <-- START-LINE-COMMENT (!end-of-line .)* end-of-line

block-comment
  <-- COMMENT-OPEN (block-comment / !COMMENT-OPEN !COMMENT-CLOSE .)* xCOMMENT-CLOSE


dollar-string <- DOLLAR data DOLLAR

data <-- (!DOLLAR .)*

compound-name
  <-- DOT? name (DOT name)*

name
  <-- identifier

direction <-- IN / OUT

type-name
  <-- compound-name
    / BOOL

formal-parameter
  <-- ((INOUT / IN / OUT) w)? type-name w name

function-declaration
  <-- type-name w name w
      PARENTHESIS-OPEN (w formal-parameter (w COMMA w formal-parameter)*)? w
      xPARENTHESIS-CLOSE w
      xCURLY-BRACKET-OPEN (w variable-declaration / w function-declaration / w behaviour-statement)* w
      xCURLY-BRACKET-CLOSE

variable-declaration
  <-- type-name w name (w EQUAL w expression)? w xSEMICOLON

expression
  <-- or-expression (w LEFT-ARROW w or-expression)?
or-expression
  <-- and-expression (w OR w or-expression)?
and-expression
  <-- compare-expression (w AND w and-expression)?
compare-expression
  <-- plus-min-expression (w compare-operator w plus-min-expression)?
compare-operator
  <-- IS-EQUAL / IS-NOT-EQUAL / IS-LESS-EQUAL / IS-LESS / IS-GREATER-EQUAL / IS-GREATER
plus-min-expression
  <-- not-expression (w (PLUS / MINUS) w not-expression)*
not-expression
  <-- NOT w not-expression
    / base-expression

base-expression
  <-- named-expression
    / int-constant-expression
    / bool-constant-expression
    / paren-expression
    / dollar-expression

named-expression
  <-- compound-with-arguments

int-constant-expression
  <-- integer

bool-constant-expression
  <-- FALSE / TRUE

paren-expression
  <-- PARENTHESIS-OPEN w expression w xPARENTHESIS-CLOSE

dollar-expression
  <-- dollar-string

system-declaration
  <-- SYSTEM w xCURLY-BRACKET-OPEN (w instantiation-statement / w binding-statement)* w
      xCURLY-BRACKET-CLOSE

instantiation-statement
  <-- compound-name w name w xSEMICOLON

binding-statement
  <-- name-with-wildcard w BIND w name-with-wildcard w xSEMICOLON

name-with-wildcard <-- compound-name (DOT STAR)? / STAR



white-space
  <- white-space-char
   / line-comment
   / block-comment

white-space-char
  < [ \f\n\t\r]

end-of-line
  < [\f\n\r]

w <- (white-space)*



DOLLAR < '$'



BEHAVIOUR           <  'behaviour' !ALPHANUM
BLOCKING            <- 'blocking' !ALPHANUM
BOOL                <- 'bool' !ALPHANUM
COMPONENT           <  'component' !ALPHANUM
ELSE                <  'else' !ALPHANUM
ENUM                <  'enum' !ALPHANUM
EXTERN              <  'extern' !ALPHANUM
EXTERNAL            <- 'external' !ALPHANUM
FALSE               <  'false' !ALPHANUM
IF                  <  'if' !ALPHANUM
ILLEGAL             <- 'illegal' !ALPHANUM
IMPORT              <  'import' !ALPHANUM
IN                  <- 'in' !ALPHANUM
INEVITABLE          <- 'inevitable' !ALPHANUM
INJECTED            <  'injected' !ALPHANUM
INOUT               <- 'inout' !ALPHANUM
INTERFACE           <  'interface' !ALPHANUM
NAMESPACE           <  'namespace' !ALPHANUM
ON                  <  'on' !ALPHANUM
OPTIONAL            <- 'optional' !ALPHANUM
OTHERWISE           <- 'otherwise' !ALPHANUM
OUT                 <- 'out' !ALPHANUM
PROVIDES            <- 'provides' !ALPHANUM
REPLY               <  'reply' !ALPHANUM
REQUIRES            <- 'requires' !ALPHANUM
RETURN              <  'return' !ALPHANUM
SUBINT              <  'subint' !ALPHANUM
SYSTEM              <  'system' !ALPHANUM
TRUE                <- 'true' !ALPHANUM

ALPHA               <- [a-zA-Z_]
NUM                 <- [0-9]
ALPHANUM            <- ALPHA / NUM

KEYWORD <
    BEHAVIOUR
  / BLOCKING
  / BOOL
  / COMPONENT
  / ELSE
  / ENUM
  / EXTERN
  / EXTERNAL
  / FALSE
  / IF
  / ILLEGAL
  / IMPORT
  / IN
  / INEVITABLE
  / INJECTED
  / INOUT
  / INTERFACE
  / NAMESPACE
  / ON
  / OPTIONAL
  / OTHERWISE
  / OUT
  / PROVIDES
  / REPLY
  / REQUIRES
  / RETURN
  / SUBINT
  / SYSTEM
  / TRUE

")
  (define-peg-pattern root all (and (* (and w (expect top))) w))

  (set! %peg-locations? #t)
  (catch 'parse-error (lambda ()
                        (let* ((result (match-pattern root input))
                               (end (peg:end result))
                               (tree (peg:tree result)))
                          (set! %peg-locations? #f)
                          tree))
    (lambda (key . args)
      (receive (ln col line) (line-column input (caar args))
        (format #t ":~a:~a\n~a\n~a^\n~aexpected ~a\n" ln col line (make-string col #\space) (make-string col #\space) (cadar args)))
      '())))
