;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2014, 2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <rma.wieringa@gmail.com>
;;; Copyright © 2017 Johri van Eerd <vaneerd.johri@gmail.com>
;;; Copyright © 2018 Henk Katerberg <hank@mudball.nl>
;;; Copyright © 2018 Filip Toman <filip.toman@verum.com>
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

(define-module (dzn code language dzn)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)

  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn code util)
  #:use-module (dzn misc)

  #:export (ast->dzn
            ast->string
            dzn:comment
            dzn:model-name
            dzn:statement?
            dzn:top*
            operator->string
            print-ast
            print-ast-join
            print-brace-close
            print-brace-open
            print-newline
            print-type))

;;;
;;; Accessors.
;;;
(define-method (dzn:top* (o <root>))
  (filter (negate (disjoin ast:imported?
                           (is? <file-name>)))
          (ast:top* o)))

(define-method (dzn:top* (o <namespace>))
  (filter (negate (disjoin ast:imported?
                           (is? <file-name>)))
          (ast:top* o)))

(define-method (dzn:comment (o <comment>))
  (let ((comment (.string o)))
    (and comment
         (not (string-null? comment))
         comment)))

(define-method (dzn:comment (o <ast>))
  (and=> (.comment o) dzn:comment))

(define-method (dzn:model-name (o <model>))
  (ast:name o))


;;;
;;; Names.
;;;
(define-method (dzn:full-name (o <type>))
  (let* ((scope (ast:full-scope o))
         (model-scope (ast:parent o <model>))
         (model-scope (or (and model-scope (ast:full-name model-scope)) '()))
         (common (or (list-index (negate equal?) scope model-scope)
                     (min (length scope) (length model-scope)))))
    (drop (ast:full-name o) common)))

(define-method (dzn:dotted-name (o <ast>))
  (ast:dotted-name o))

(define-method (dzn:dotted-name (o <enum>))
  (string-join (dzn:full-name o) "."))

(define-method (dzn:dotted-name (o <subint>))
  (string-join (dzn:full-name o) "."))


;;;
;;; Print-ast.
;;;
(define (operator->string o)
  (match o
    (($ <and>) "&&")
    (($ <equal>) "==")
    (($ <greater-equal>) ">=")
    (($ <greater>) ">")
    (($ <less-equal>) "<=")
    (($ <less>) "<")
    (($ <minus>) "-")
    (($ <not-equal>) "!=")
    (($ <not>) "!")
    (($ <or>) "||")
    (($ <plus>) "+")))

(define (dzn:statement? o)
  (let ((parent (.parent o)))
    (or (is-a? parent <blocking>)
        (is-a? parent <compound>)
        (is-a? parent <guard>)
        (is-a? parent <on>)
        (and (is-a? parent <if>)
             (not (ast:eq? o (.expression parent)))))))

(define (print-ast-join lst port . grammar)
  "Like STRING-JOIN but PRINT-AST'ing to PORT, also allowing \"PRE\" 'pre
and \"POST\" 'post in GRAMMAR."
  (define (reduce-sexp l)
    (unfold null? (compose (cute apply list <>) (cute list-head <> 2)) cddr l))

  (define (xassq key alist)
    (find (compose (cute eq? <> key) cadr) alist))

  (define (xassq-ref alist key)
    (and=> (xassq key alist) car))

  (let* ((grammar-alist (match grammar
                          (((and (? string?) str)) `((,str infix)))
                          (_ (reduce-sexp grammar))))
         (infix (xassq-ref grammar-alist 'infix))
         (suffix (xassq-ref grammar-alist 'suffix))
         (prefix (xassq-ref grammar-alist 'prefix))
         (pre (xassq-ref grammar-alist 'pre))
         (post (xassq-ref grammar-alist 'post)))
    (when (and pre (pair? lst))
      (display pre port))
    (let loop ((lst lst))
      (when (pair? lst)
        (when prefix
          (display prefix port))
        (print-ast (car lst) port)
        (when suffix
          (display suffix port))
        (when (and (pair? (cdr lst)) infix)
          (display infix port))
        (loop (cdr lst))))
    (when (and post (pair? lst))
      (display post port))))

(define print-indent
  (let ((level 0)
        (indent 2))
    (lambda* (type #:optional (port type))
      (case type
        ((open)
         (print-indent port)
         (set! level (1+ level))
         (display "{" port)
         (print-newline port))
        ((close)
         (set! level (1- level))
         (print-indent port)
         (display "}" port))
        (else
         (unless (zero? level)
           (display (make-string (* indent level) #\space) port)))))))

(define (print-brace-open port)
  (print-indent 'open port))

(define (print-brace-close port)
  (print-indent 'close port))

(define (print-newline port)
  (newline port)
  (print-indent port))

(define-method (print-ast (o <top>) port)
  (display o port))

(define-method (print-ast (o <ast>))
  (print-ast o (current-output-port)))

(define-method (print-ast (o <root>) port)
  (and=> (.comment o) (cute print-ast <> port))
  (print-ast-join (dzn:top* o) port "\n"))

(define-method (print-ast (o <namespace>) port)
  (display "namespace " port)
  (display (ast:dotted-name o) port)
  (print-newline port)
  (print-brace-open port)
  (print-ast-join (dzn:top* o) port "\n")
  (print-brace-close port)
  (print-newline port))

(define-method (print-ast (o <comment>) port)
  (and=> (dzn:comment o)
         (cute write-line <> port)))

(define-method (print-ast (o <import>) port)
  (simple-format port "import ~a;\n" (.name o)))

(define-method (print-ast (o <bool>) port)
  (display "bool" port))

(define-method (print-ast (o <void>) port)
  (display "void" port))

(define-method (print-ast (o <enum>) port)
  (simple-format port "enum ")
  (print-type o port)
  (display " {" port)
  (print-ast-join (ast:field* o) port ", ")
  (display "};\n" port))

(define-method (print-ast (o <extern>) port)
  (simple-format port "extern ~a " (ast:name o))
  (print-ast (.value o) port)
  (display ";\n" port))

(define-method (print-ast (o <data>) port)
  (simple-format port "$~a$" (.value o)))

(define-method (print-ast (o <subint>) port)
  (let ((range (.range o)))
    (display "subint " port)
    (print-type o port)
    (simple-format port "{~a..~a}\n" (.from range) (.to range))))

(define-method (print-ast (o <interface>) port)
  (simple-format port "interface ~a" (ast:name o))
  (print-newline port)
  (print-brace-open port)
  (for-each (cute print-ast <> port) (ast:type* o))
  (for-each (cute print-ast <> port) (ast:event* o))
  (print-ast (.behavior o) port)
  (print-newline port)
  (print-brace-close port)
  (print-newline port))

(define-method (print-ast (o <component>) port)
  (simple-format port "component ~a" (ast:name o))
  (print-newline port)
  (print-brace-open port)
  (for-each (cute print-ast <> port) (ast:port* o))
  (print-ast (.behavior o) port)
  (print-newline port)
  (print-brace-close port)
  (print-newline port))

(define-method (print-ast (o <foreign>) port)
  (simple-format port "component ~a" (ast:name o))
  (print-newline port)
  (print-brace-open port)
  (for-each (cute print-ast <> port) (ast:port* o))
  (print-brace-close port)
  (print-newline port))

(define-method (print-ast (o <system>) port)
  (simple-format port "component ~a" (ast:name o))
  (print-newline port)
  (print-brace-open port)
  (for-each (cute print-ast <> port) (ast:port* o))
  (display "system" port)
  (print-newline port)
  (print-brace-open port)
  (for-each (cute print-ast <> port) (ast:instance* o))
  (for-each (cute print-ast <> port) (ast:binding* o))
  (print-brace-close port)
  (print-newline port)
  (print-brace-close port)
  (print-newline port))

(define-method (print-ast (o <instance>) port)
  (print-type (.type o) port)
  (display " " port)
  (display (.name o) port)
  (display ";\n" port))

(define-method (print-ast (o <binding>) port)
  (print-ast (.left o) port)
  (display " <=> " port)
  (print-ast (.right o) port)
  (display ";\n" port))

(define-method (print-ast (o <end-point>) port)
  (let ((port-name (.port.name o))
        (instance-name (.instance.name o)))
    (when port-name
      (display port-name port))
    (when (and port-name instance-name)
      (display "." port))
    (when instance-name
      (display instance-name port))))

(define-method (print-ast (o <event>) port)
  (simple-format port "~a " (.direction o))
  (print-ast (ast:type o) port)
  (simple-format port " ~a (" (.name o))
  (print-ast-join (ast:formal* o) port ", ")
  (display ");\n" port))

(define-method (print-ast (o <formal>) port)
  (display (.direction o) port)
  (print-type (.type o) port)
  (display " " port)
  (display (.name o) port))

(define-method (print-ast (o <formal-binding>) port)
  (simple-format port "~a <- ~a" (.name o) (.variable.name o)))

(define-method (print-ast (o <port>) port)
  (simple-format port "~a" (.direction o))
  (when (.blocking? o)
    (display " blocking" port))
  (when (.external? o)
    (display " external" port))
  (when (.injected? o)
    (display " injected" port))
  (display " " port)
  (print-type (.type o) port)
  (display " " port)
  (display (.name o) port)
  (display ";\n" port))

(define-method (print-ast (o <behavior>) port)
  (display "behavior" port)
  (and=> (.name o) (cute simple-format port " ~a" <>))
  (print-newline port)
  (print-brace-open port)
  (print-ast-join (ast:type* o) port)
  (print-ast-join (ast:variable* o) port)
  (print-ast-join (ast:function* o) port)
  (print-ast-join (ast:statement* (.statement o)) port)
  (print-brace-close port))

(define-method (print-ast (o <function>) port)
  (print-ast (ast:type o) port)
  (simple-format port " ~a (" (.name o))
  (print-ast-join (ast:formal* o) port ", ")
  (display ")" port)
  (print-ast (.statement o) port))

(define-method (print-ast (o <compound>) port)
  (let ((statements (ast:statement* o)))
    (cond
     ((null? statements)
      (display "{}\n" port))
     (else
      (unless (is-a? (ast:previous-statement o) <imperative>)
        (print-newline port))
      (print-brace-open port)
      (print-ast-join statements port)
      (print-brace-close port)
      (print-newline port)))))

(define-method (print-ast (o <blocking>) port)
  (display "blocking " port)
  (print-ast (.statement o) port))

(define-method (print-ast (o <guard>) port)
  (let ((statement (.statement o)))
    (display "[" port)
    (print-ast (.expression o) port)
    (display "]" port)
    (unless (is-a? statement <compound>)
      (display " " port))
    (print-ast (.statement o) port)))

(define-method (print-ast (o <on>) port)
  (let ((statement (.statement o)))
    (display "on " port)
    (print-ast-join (ast:trigger* o) port ",")
    (display ":" port)
    (when (or (not (is-a? statement <compound>))
              (null? (ast:statement* statement)))
      (display " " port))
    (print-ast statement port)))

(define-method (print-ast (o <trigger>) port)
  (let ((event-name (.event.name o))
        (port-name (.port.name o)))
    (cond
     (port-name
      (simple-format port "~a.~a (" port-name event-name)
      (print-ast-join (map .name (ast:formal* o)) port ",")
      (display ")" port))
     (else
      (display event-name port)))))

;;; imperative
(define-method (print-ast (o <variable>) port)
  (let* ((expression (.expression o))
         (type (and=> expression ast:type)))
    (print-type (.type o) port)
    (cond ((and expression
                (not (is-a? type <void>)))
           (simple-format port " ~a = " (.name o))
           (print-ast expression port)
           (display ";\n" port))
          (else
           (simple-format port " ~a;\n" (.name o))))))

(define-method (print-ast (o <illegal>) port)
  (display "illegal;\n" port))

(define-method (print-ast (o <action>) port)
  (let ((port-name (.port.name o)))
    (cond
     (port-name
      (simple-format port "~a.~a (" port-name (.event.name o))
      (print-ast-join (ast:argument* o) port ",")
      (display ")" port))
     (else
      (simple-format port "~a" (.event.name o))))
    (when (dzn:statement? o)
      (display ";\n" port))))

(define-method (print-ast (o <call>) port)
  (simple-format port "~a (" (.function.name o))
  (print-ast-join (ast:argument* o) port ",")
  (display ")" port)
  (when (dzn:statement? o)
    (display ";\n" port)))

(define-method (print-ast (o <assign>) port)
  (simple-format port "~a = " (.variable.name o))
  (print-ast (.expression o) port)
  (display ";\n" port))

(define-method (print-ast (o <reply>) port)
  (let ((port-name (.port.name o)))
    (cond
     (port-name
      (simple-format port "~a.reply (" port-name)
      (print-ast (.expression o) port)
      (display ");\n" port))
     (else
      (display "reply (" port)
      (print-ast (.expression o) port)
      (display ");\n" port)))))

(define-method (print-ast (o <return>) port)
  (display "return " port)
  (print-ast (.expression o) port)
  (display ";\n" port))

(define-method (print-ast (o <if>) port)
  (let ((else (.else o)))
    (display "if (" port)
    (print-ast (.expression o) port)
    (display ") " port)
    (print-ast (.then o) port)
    (when else
      (display "else " port)
      (print-ast else port))))

(define-method (print-ast (o <defer>) port)
  (let ((statement (.statement o)))
    (display "defer" port)
    (if (is-a? statement <compound>) (display "\n" port)
        (display " " port))
    (print-ast statement port)))

;;; expressions
(define-method (print-type (o <interface>) port) ;;; FIXME why isn't interface a <type>
  (display (dzn:dotted-name o) port))

(define-method (print-type (o <type>) port)
  (display (dzn:dotted-name o) port))

(define-method (print-ast (o <literal>) port)
  (print-ast (.value o) port))

(define-method (print-ast (o <var>) port)
  (display (.name o) port))

(define-method (print-ast (o <shared-var>) port)
  (let ((lst (ast:full-name o)))
    (display (string-join lst ".") port)))

(define-method (print-ast (o <binary>) port)
  (print-ast (.left o) port)
  (simple-format port " ~a " (operator->string o))
  (print-ast (.right o) port))

(define-method (print-ast (o <group>) port)
  (display "(" port)
  (print-ast (.expression o) port)
  (display ")" port))

(define-method (print-ast (o <not>) port)
  (display "!" port)
  (print-ast (.expression o) port))

(define-method (print-ast (o <field-test>) port)
  (display (.variable.name o) port)
  (display "." port)
  (display (.field o) port))

(define-method (print-ast (o <shared-field-test>) port)
  (let ((lst (ast:full-name o)))
    (display (string-join lst ".") port))
  (display "." port)
  (display (.field o) port))

(define-method (print-ast (o <enum-literal>) port)
  (print-type (.type o) port)
  (display "." port)
  (display (.field o) port))

(define-method (print-ast (o <otherwise>) port)
  (display "otherwise" port))


;;;
;;; Utility
;;;
(define-method (ast->string (o <ast>))
  (with-output-to-string (cute print-ast o)))

(define-method (generator->string generator)
  (with-output-to-string (code:indenter generator)))


;;;
;;; Entry points.
;;;
(define-method (ast->dzn (o <ast>))
  (generator->string (cute print-ast o)))

(define* (ast-> root #:key (dir ".") model)
  "Entry point."
  (let ((file-name (code:root-file-name root dir ".dzn"))
        (generator (code:indenter (cute print-ast root) #:gnu? #f)))
    (code:dump root generator #:file-name file-name)))
