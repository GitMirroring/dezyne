;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2017, 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2018 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2017, 2018, 2019 Rob Wieringa <Rob.Wieringa@verum.com>
;;; Copyright © 2017 Henk Katerberg <henk.katerberg@verum.com>
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

(define-module (gaiag commands verify)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag config)
  #:use-module (gaiag misc)
  #:use-module (gaiag makreel)
  #:use-module (gaiag commands parse)
  #:use-module (gaiag commands code)
  #:use-module (scmcrl2 verification)
  #:use-module (gaiag command-line)
  #:use-module (gaiag shell-util)
  #:use-module (gash job)
  #:use-module (gash pipe)
  #:export (parse-opts
            model->mcrl2
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((all (single-char #\a))
            (debug (single-char #\d))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (queue_size (single-char #\q) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: dzn verify [OPTION]... DZN-FILE
  -a, --all                   keep going after first error
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           restrict verification to model MODEL
  -q, --queue_size=SIZE       use queue size=SIZE for verification [3]
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define (models-for-verification root)
  (let* ((models (ast:model* root))
         (components (filter (conjoin (is? <component>) (negate ast:imported?) .behaviour) models))
         (component-names (map verify:scope-name components))
         (interfaces (filter (conjoin (is? <interface>) (negate ast:dzn-scope?)) models))
         (interface-names (map verify:scope-name interfaces))
         (interface-names (let loop ((components components) (interface-names interface-names))
                            (if (null? components) interface-names
                                (let ((component-interfaces (map (compose verify:scope-name .type) (ast:port* (car components)))))
                                  (loop (cdr components)
                                        (filter (negate (cut member <> component-interfaces)) interface-names)))))))
    (append interface-names component-names)))

(define-method (ast:interface* (o <interface>))
  (let* ((types (delete-duplicates
                 (map ast:type (tree-collect (disjoin (is? <event>) (is? <variable>) (is? <formal>)) o))
                 ast:eq?)))
    (delete-duplicates (filter-map (cut parent <> <interface>) types) ast:eq?)))

(define (model->mcrl2 root model)
  (let* ((model-name (verify:scope-name model))
         (root' (tree-filter (disjoin (negate (is? <component>)) (cut ast:eq? <> model)) root)))
    (parameterize ((language 'makreel) (%model-name model-name))
      (root-> root'))))

(define (verify-makreel options ast)
  (let ((all? (command-line:get 'all)))

    (define (verify-makreel-model root model-name)
      (mcrl2:verify model-name root))

    (let* ((root (makreel:om ast))
           (model (option-ref options 'model #f))
           (models (if model (list model) (models-for-verification root))))
      (when (and model (not (find (lambda (x) (equal? (verify:scope-name x) model))
                                  (ast:model* root))))
        (display (string-append "no such model: " model "\n") (current-error-port))
        (exit 1))
      (let loop ((models models) (error? #f))
        (if (or (and (not all?) error?) (null? models)) (if error? 1 0)
            (let* ((model (car models))
                   (this-error? (verify-makreel-model root model))
                   (error? (or error? this-error?)))
              (loop (cdr models) error?)))))))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (debug? (gdzn:command-line:get 'debug)))
    (setvbuf (current-output-port) 'line)
    (let* ((file-name (car files))
           (ast (parse options file-name)))
      (let ((error? (verify-makreel options ast)))
        (exit error?)))))
