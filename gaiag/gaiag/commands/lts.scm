;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2018 Johri van Eerd <johri.van.eerd@verum.com>
;;; Copyright © 2018, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag commands lts)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 getopt-long)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag ast)
  #:use-module (gaiag goops)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gaiag om)
  #:use-module (gaiag util)
  #:use-module (gaiag commands parse)
  #:use-module (gaiag commands verify)
  #:use-module (gaiag makreel)
  #:use-module (gaiag shell-util)
  #:use-module (scmcrl2 verification)
  #:use-module (gash pipe)
  #:export (parse-opts
            main))

(define (parse-opts args)
  (let* ((option-spec
          '((compiling-rewriter (single-char #\c))
            (debug (single-char #\d))
            (help (single-char #\h))
            (import (single-char #\I) (value #t))
            (model (single-char #\m) (value #t))
            (queue_size (single-char #\q) (value #t))
            (reduction (single-char #\r) (value #t))
            (version (single-char #\V) (value #t))))
	 (options (getopt-long args option-spec
		   #:stop-at-first-non-option #t))
	 (help? (option-ref options 'help #f))
	 (files (option-ref options '() '()))
	 (usage? (and (not help?) (null? files))))
    (or
     (and (or help? usage?)
          ((or (and usage? stderr) stdout) "\
Usage: gdzn lts [OPTION]... DZN-FILE ...
  -c, --compiling-rewriter    use compiling rewriter for faster LTS generation
                              (only use on larger models)
  -h, --help                  display this help and exit
  -I, --import=DIR+           add DIR to import path
  -m, --model=MODEL           generate LTS for model with name=NAME
  -q, --queue_size=SIZE       use queue size=SIZE for LTS generation [3]
  -r, --reduction=NAME        apply NAME reduction to the LTS, preserving equivalence
                              possible NAMEs:
                              'none' identity equivalence (default)
                              'bisim' strong bisimilarity using the O(m log n)
                                algorithm [Groote/Jansen/Keiren/Wijs 2017]
                              'bisim-gv' strong bisimilarity using the O(mn)
                                algorithm [Groote/Vaandrager 1990]
                              'bisim-sig' strong bisimilarity using the signature
                                refinement algorithm [Blom/Orzan 2003]
                              'branching-bisim' branching bisimilarity using the
                                O(m log n) algorithm [Groote/Jansen/Keiren/Wijs 2017]
                              'branching-bisim-gv' branching bisimilarity using
                                the O(mn) algorithm [Groote/Vaandrager 1990]
                              'branching-bisim-sig' branching bisimilarity using
                                the signature refinement algorithm [Blom/Orzan 2003]
                              'dpbranching-bisim' divergence-preserving branching
                                bisimilarity using the O(m log n) algorithm
                                [Groote/Jansen/Keiren/Wijs 2017]
                              'dpbranching-bisim-gv' divergence-preserving
                                branching bisimilarity using the O(mn) algorithm
                                [Groote/Vaandrager 1990]
                              'dpbranching-bisim-sig' divergence-preserving
                                branching bisimilarity using the signature
                                refinement algorithm [Blom/Orzan 2003]
                              'weak-bisim' weak bisimilarity
                              'dpweak-bisim' divergence-preserving weak
                                bisimilarity
                              'sim' strong simulation equivalence
                              'ready-sim' strong ready simulation equivalence
                              'trace' strong trace equivalence
                              'weak-trace' weak trace equivalence
                              'tau-star' tau star reduction
  -V, --version=VERSION       use service version=VERSION
")
	   (exit (or (and usage? 2) 0)))
     options)))

(define (lts-makreel options dir file-name ast)
  (let* ((reduce? (option-ref options 'reduction "none"))
         (rewrite? (option-ref options 'compiling-rewriter #f))
         (root (makreel:om ast))
         (model (option-ref options 'model #f))
         (model (find (lambda (x) (equal? (symbol->string (verify:scope-name x)) model)) (filter (is? <model>) (ast:top* root))))
         (makreel (with-output-to-string (cut model->mcrl2 root model)))
         (is-interface? (is-a? model <interface>))
         (init (if is-interface? (x:interface-init model)
                   (x:component-init model)))
         (commands `(,(cut display makreel)
                     ("bash" "-c" ,(format #f "cat - ; echo \"~a\"" init))
                     ("m4-cw")
                     ("mcrl22lps" "-b")
                     ("lpsconstelm" "-st")
                     ("lpsparelm")
                     ("lps2lts" "--cached" "--out=lts" ,@(if rewrite? `("-rjittyc") `()))
                     ("ltsconvert" ,(string-append "-e" reduce?) "--in=lts" "--out=aut")
                     ("sed" "-e" "s,\"declarative_illegal\",\"dillegal\",g")
                     ("traces.scm")
                     ("ltsgraph" "--in=aut" "/dev/stdin")))
         (result (receive (job ports)
                    (apply pipeline+ #f commands)
                  (set-port-encoding! (car ports) "ISO-8859-1")
                   (let ((result (read-string (car ports)))
                         (error (read-string (cadr ports))))
                     (handle-error job error)
                     result))))
    #t))

(define (main args)
  (let* ((options (parse-opts args))
         (files (option-ref options '() '()))
         (file-name (car files))
         (gdzn-debug? (gdzn:command-line:get 'debug))
         (tmp (string-append (tmpnam) "-lts"))
         (dir (getcwd)))
    (setvbuf (current-output-port) 'line)
    (mkdir-p tmp)
    (receive (files importeds)
        (values files '())
      (let* ((file-name (car files))
             (ast (assert-parse options file-name))
             (foo (chdir tmp)))
        (lts-makreel options dir file-name ast)
        (chdir dir)))))
