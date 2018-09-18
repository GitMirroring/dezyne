;;; Dezyne --- Dezyne command line tools
;;;
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

(use-modules (gaiag peg))
(use-modules (gaiag peg cache))
(use-modules (gaiag peg codegen))
(use-modules (ice-9 pretty-print))
(use-modules (ice-9 receive))

(define (parse input)
  ;; (define-peg-pattern grammar all (or if-then statement rest))
  ;; (define-peg-pattern if-then all (and "if" (expect then) (* ws) (? else)))
  ;; (define-peg-pattern ws all (+ (or " " "\n" "\t")))
  ;; (define-peg-pattern then all (and ws "then" (* ws) block))
  ;; (define-peg-pattern open-brace all "{")
  ;; (define-peg-pattern close-brace all "}")
  ;; (define-peg-pattern block all (and open-brace (* (or ws statement)) (expect close-brace)))
  ;; (define-peg-pattern else all (and "else" (* ws) block))
  ;; (define-peg-pattern statement all (and assignment (expect semi)))
  ;; (define-peg-pattern assign all "=")
  ;; (define-peg-pattern semi all ";")
  ;; (define-peg-pattern assignment all (and identifier (* ws) assign (* ws) (expect identifier)))
  ;; (define-peg-pattern identifier all (+ (range #\a #\z)))
  ;; (define-peg-pattern rest all (* peg-any))

  (define-peg-string-patterns
    "grammar    <--  (if-then / statement) eof#
    eof         <    !.
    if-then     <--  'if' ws then# ws* else?
    ws          <--  [ \n\t]+
    then        <--  'then' ws* (block / statement)
    block       <--  '{' (ws / statement)* '}'#
    else        <--  'else' ws* (block / statement)#
    statement   <--  if-then / assignment ws* ';'# / ';'
    assignment  <--  identifier ws* '=' ws* identifier#
    identifier  <--  [a-zA-Z][a-zA-Z0-9_]*"
    )

  (catch 'parse-error (lambda () (pretty-print (peg:tree (match-pattern grammar input))))
    (lambda (key . args)
      (receive (ln col line) (line-column input (caar args))
        (let ((indent (make-string col #\space)))
         (format #t ":~a:~a\n~a\n~a^\n~aexpected ~a\n"
                 ln col line
                 indent
                 indent
                 (cadar args)))))))

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

;;(parse "ab")
(parse "if then if then {} else")
(parse "if then { a = ")
(parse "if then { a = b; } else ")
