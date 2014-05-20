;;; Gaiag --- Guile in Asd In Asd in Guile.
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gaiag.
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.

(define-module (language asd tokenize)
  #:use-module (language ecmascript tokenize)
  #:use-module (system base lalr)
  #:export (next-token make-tokenizer tokenize))

(define (string-symbol x) (cons (symbol->string x) x))
(define *keywords*
  (map string-symbol 
       '(
         component
         enum
         in
         int
         interface
         on
         out
         provides
         reply
         requires
         void
         )))

(define *punctuation*
  '(
    ("{" . lbrace)
    ("}" . rbrace)
    ("(" . lparen)
    (")" . rparen)
    ("[" . lbracket)
    ("]" . rbracket)
    ("." . dot)
    (";" . semicolon)
    ("<" . <)
    (">" . >)
    ("<=" . <=)
    (">=" . >=)
    ("==" . ==)
    ("!=" . !=)
    ("+" . +)
    ("-" . -)
    ("*" . *)
    ("!" . !)
    ("&&" . &&)
    ("||" . or)
    (":" . colon)
    ("=" . =)))

(define *future-reserved-words* '())

(define *div-punctuation*
  '(("/" . /)))

(module-define! (resolve-module '(language ecmascript tokenize)) '*keywords* *keywords*)

(module-define! (resolve-module '(language ecmascript tokenize)) '*future-reserved-words* *future-reserved-words*)

(module-define! (resolve-module '(language ecmascript tokenize)) '*div-punctuation* *div-punctuation*)

(define (port-source-location port)
  ((@@ (language ecmascript tokenize) port-source-location) port))

(define (read-slash port loc div?)
  ((@@ (language ecmascript tokenize) read-slash) port loc div?))

(define (read-identifier port loc)
  ((@@ (language ecmascript tokenize) read-identifier) port loc))

(define (read-numeric port loc)
  ((@@ (language ecmascript tokenize) read-numeric) port loc))

(define (read-punctuation port loc)
  ((@@ (language ecmascript tokenize) read-punctuation) port loc))

(define (read-string port loc)
  ((@@ (language ecmascript tokenize) read-string) port loc))

(define (read-identifier port loc)
  (let lp ((c (peek-char port)) (chars '()))
    (if (or (eof-object? c)
            (not (or (char-alphabetic? c)
                     (char-numeric? c)
                     (char=? c #\$)
                     (char=? c #\_))))
        (let ((word (list->string (reverse chars))))
          (cond ((assoc-ref *keywords* word)
                 => (lambda (x) (make-lexical-token x loc (string->symbol word))))
                (else (make-lexical-token 'Identifier loc
                                          (string->symbol word)))))
        (begin (read-char port)
               (lp (peek-char port) (cons c chars))))))


(define (next-token port div?)
  (let ((c   (peek-char port))
        (loc (port-source-location port)))
    (case c
      ((#\ht #\vt #\np #\space #\x00A0) ; whitespace
       (read-char port)
       (next-token port div?))
      ((#\newline #\cr)                 ; line break
       (if (isatty? port)
           '*eoi*
           (begin
             (read-char port)
             (next-token port div?))
           ;; command-line
           ))
      ;;((#\@) (make-lexical-token '@ loc (read-char port)))
      ((#\/)
       ;; division, single comment, double comment, or regexp
       (read-slash port loc div?))
      ((#\" #\')                        ; string literal
       (read-string port loc))
      (else
       (cond
        ((eof-object? c) 
         '*eoi*)
        ((or (char-alphabetic? c)
             (char=? c #\$)
             (char=? c #\_))
         ;; reserved word or identifier
         (read-identifier port loc))
        ((char-numeric? c)
         ;; numeric -- also accept . FIXME, requires lookahead
         (make-lexical-token 'NumericLiteral loc (read-numeric port loc)))
        (else
         ;; punctuation
         (format #t "PUNCT:~a\n!" c)
         (read-punctuation port loc)))))))

(define (make-tokenizer port) (lambda () (next-token port #t)))
