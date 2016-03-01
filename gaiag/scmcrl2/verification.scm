;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (scmcrl2 verification)

  #:use-module (ice-9 match)
  #:use-module (ice-9 popen)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (gaiag goops)
  #:use-module (gaiag om)
  #:use-module (gaiag util)
  #:use-module (gaiag misc)
  #:use-module (scmcrl2 traces)

  #:export (mcrl2:verify))

(define (hidden-actions)
  (list "return" "event" "optional" "inevitable" "flush"))

;; (define (required-ports o)
;;   (match o
;; 	 (('root x ...) (append-map required-ports (cdr o)))
;; 	 (('component x ...) (append-map required-ports (cdr o)))
;; 	 (('ports x ...) (append-map required-ports (cdr o)))
;; 	 (('port portname porttype 'provides x y) '())
;; 	 (('port portname porttype 'requires x y) (list portname))
;; 	 (_ '())))

(define (find-taus ast modelname)
  (let* ((component (find (lambda (x) (equal? (symbol->string(om:name x)) modelname)) (filter (is? <component>) (.elements ast))))
	 (req-ports (map (lambda (r) (om:name r)) (om:required component))))
    (string-join (append-map (lambda (p)
			       (let ((portname (symbol->string p)))
				 (map (lambda (h)
					(string-append portname "'" h) )
				      (hidden-actions))))
			     req-ports)
		 "," 'infix)))

(define (create-lps mcrl2)
  (let ((lps (string-append (basename mcrl2 ".mcrl2") ".lps")))
    (system (string-append "mcrl22lps -bf -lstack " mcrl2 " " lps))
    lps))

(define (reduce-lps lps)
  (system (string-append "lpsconstelm -st " lps " " lps))
  (system (string-append "lpsparelm " lps " " lps))
  lps)

(define (reduce-lts lts)
  (system (string-append "ltsconvert -ebranching-bisim " lts " " lts))
  lts)

;; (define (gen-mcrl2 schemefile component)
;;   (system (string-append "generate_mcrl2.py -c " component " " schemefile))
;;   (string-append (basename schemefile ".out") "_" component "_component.mcrl2"))

(define (verifydeadlock lps)
  (blockingcall (string-append "lps2lts --deadlock -t1 -v " lps " " (basename lps ".lps") ".aut" " 2>&1")))

(define (verifyillegal lps)
  (blockingcall (string-append "lps2lts -aillegal -t1 -v " lps " " (basename lps ".lps") ".aut" " 2>&1")))

(define (verifylivelock lps taus)
  (blockingcall (string-append "lps2lts --divergence -t1 -v --tau=" taus " " lps " " (basename lps ".lps") ".aut" " 2>&1")))

;; TODO
(define (verifyrefinement lps taus)
  (let* ((provmcrl2 (string-append (basename lps "component.lps") "provided.mcrl2"))
	 (provlps (create-lps provmcrl2))
	 (provlts (string-append (basename provlps ".lps") ".aut"))
	 (complts (string-append (basename lps ".lps") ".aut")))
    (system (string-append "lps2lts " provlps " " provlts))
    (system (string-append "lps2lts " lps " " complts))
    (reduce-lts provlts)
    (reduce-lts complts)
    (blockingcall (string-append "ltscompare -v -c -pfailures-divergence --tau=" taus " " complts " " provlts " 2>&1"))))

(define (verifyall lps taus)
  (blockingcall (string-append "lps2lts -aillegal --deadlock --divergence -t1 -v --tau=\"" taus "\" " lps " " (basename lps ".lps") ".aut" " 2>&1")))

(define (blockingcall command)
  (let* ((port (open-input-pipe command))
	 (str (read-string port)))
    (close-pipe port)
    str))

;; (define (doverification file-name model option)
;;   (let* ((mcrl2file (gen-mcrl2 schemefile (symbol->string component)))
;; 	 (lpsfile (create-lps mcrl2file))
;; 	 (taus (find-taus schemefile)))
;;     (cond ((equal? option "--verify-provided-interface") (verifyrefinement lpsfile taus))
;; 	  ((equal? option "--verify-absence-of-illegals") (verifyillegal lpsfile))
;; 	  ((equal? option "--verify-deadlock-freedom") (verifydeadlock lpsfile))
;; 	  ((equal? option "--verify-livelock-freedom") (verifylivelock lpsfile taus))
;; 	  ((equal? option "--all") (verifyall lpsfile taus)))))

(define (mcrl2:verify file-name modelname ast)
  (let* ((taus (find-taus ast modelname))
	 (lpsfile (create-lps "verify.mcrl2"))
	 (output (verifyall lpsfile taus)))
    (interpret-results output file-name modelname)))

(define (interpret-results output file-name modelname)
  (or (make-trace (check-refinement output) "refinement" modelname file-name)
      (or (make-trace (check-illegal output) "illegal" modelname file-name)
	  (or (make-trace (check-deadlock output) "deadlock" modelname file-name)
	      (make-trace (check-livelock output) "livelock" modelname file-name)))))

(define (check-refinement string)
  (let ((sub (regexp-exec (make-regexp "The LTS in (.*) is not included in the LTS .*") string)))
    (if sub "counter_example_failures_divergence_refinement.trc" #f)))

(define (check-illegal string)
  (let ((sub (regexp-exec (make-regexp "Detected action 'illegal' .* and saved to '(.*)'") string))) (if sub (match:substring sub 1) #f)))

(define (check-deadlock string)
  (let ((sub (regexp-exec (make-regexp "deadlock-detect: deadlock found and saved to '(.*)'") string))) (if sub (match:substring sub 1) #f)))

(define (check-livelock string)
  (let ((sub (regexp-exec (make-regexp "Trace to the divergencing state is saved to '([^'\n]*)") string))) (if sub (match:substring sub 1) #f)))
