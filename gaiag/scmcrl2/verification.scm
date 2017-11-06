;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017 Johri van Eerd <johri.van.eerd@verum.com>
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
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag util)
  #:use-module (gaiag mcrl2)
  #:use-module (gaiag misc)
  #:use-module (gaiag resolve)
  #:use-module (scmcrl2 traces)

  #:export (mcrl2:verify))

(define (hidden-actions)
  (list "return" "event" "optional" "inevitable" "flush"))

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

(define (create-lps mcrl2 modelname lpstype ast)
  (let ((lps (string-append (basename mcrl2 ".mcrl2") "_" lpstype ".lps")))
    (match lpstype
      ("deterministic" (system (string-append "cat - " mcrl2 " <<< \"\n\ninit " modelname "'Behaviour(" (ast:set-scope ast (globals-from-scope (find (lambda (x) (equal? (symbol->string(om:name x)) modelname)) (filter (is? <component>) (.elements ast))))) ");\" | mcrl22lps -b > " lps)))
      ("" (system (string-append "cat - " mcrl2 " <<< \"\n\ninit " modelname "'Implementation();\" | mcrl22lps -b > " lps))))
    lps))

(define (reduce-lps lps)
  (system (string-append "lpsconstelm -st " lps " " lps))
  (system (string-append "lpsparelm " lps " " lps))
  lps)

(define (reduce-lts lts)
  (system (string-append "ltsconvert -edpbranching-bisim " lts " " lts))
  lts)

(define (verifydeterministic lps)
  (let ((ltsname (string-append (basename lps ".lps") ".aut")))
    (blockingcall (string-append "lps2lts " lps " " ltsname " && ltsinfo " ltsname " 2>&1"))))

(define (verifydeadlock lps)
  (blockingcall (string-append "lps2lts --deadlock -t1 -v " lps " " (basename lps ".lps") ".aut" " 2>&1")))

(define (verifyillegal lps)
  (blockingcall (string-append "lps2lts -aillegal -t1 -v " lps " " (basename lps ".lps") ".aut" " 2>&1")))

(define (verifylivelock lps taus)
  (blockingcall (string-append "lps2lts --divergence -t1 -v --tau=\"" taus "\" " lps " " (basename lps ".lps") ".aut" " 2>&1")))

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
  (blockingcall (string-append "lps2lts -aillegal --deadlock --divergence -t1 -v --tau=\"" taus "\" " lps " " (basename lps ".lps") ".aut 2>&1")))

(define (blockingcall command)
  (let* ((port (open-input-pipe command))
	 (str (read-string port)))
    (close-pipe port)
    str))

(define (mcrl2:verify file-name modelname ast)
  (let* ((taus (find-taus ast modelname))
;;	 (lpsfile (create-lps "verify.mcrl2"))
         (deterministic-lps (create-lps "verify.mcrl2" modelname "deterministic" ast))
         (lpsfile (create-lps "verify.mcrl2" modelname "" ast))
         (output (verifydeterministic deterministic-lps))
	 (output (string-append output (verifyillegal lpsfile)))
         (output (string-append output (verifydeadlock lpsfile)))
         ;;(output (string-append output (verifyrefinement lpsfile taus)))
         (output (string-append output (verifylivelock lpsfile taus)))
         )
    (interpret-results output modelname)))

(define (interpret-results output modelname)
  (let ((compliance (check-refinement output modelname))
        (illegal (check-illegal output modelname))
        (deadlock (check-deadlock output modelname))
        (livelock (check-livelock output modelname))
        (deterministic (check-deterministic output modelname)))
    (or compliance illegal deadlock livelock)))

(define (check-deterministic string modelname)
  (let ((sub (regexp-exec (make-regexp "LTS is deterministic") string)))
    (if sub (begin (stdout "verify: ~a: check: deterministic: ok\n" modelname) #f)
        (begin (stdout "verify: ~a: check: deterministic: fail\n" modelname) #t))))

(define (check-refinement string modelname)
  (let ((sub (regexp-exec (make-regexp "The LTS in (.*) is not included in the LTS .*") string)))
    (if sub (begin
              (stdout "verify: ~a: check: compliance: fail\n" modelname)
              (stdout "~a" (make-trace "counter_example_failures_divergence_refinement.trc" "refinement" modelname))
              #t)
         (begin (stdout "verify: ~a: check: compliance: ok\n" modelname) #f))))

(define (check-illegal string modelname)
  (let ((sub (regexp-exec (make-regexp "Detected action 'illegal' .* and saved to '([^'\n]*)'") string)))
    (if sub (begin
              (stdout "verify: ~a: check: illegal: fail\n" modelname)
              (stdout "~a" (make-trace (match:substring sub 1) "illegal" modelname))
              #t)
        (begin (stdout "verify: ~a: check: illegal: ok\n" modelname) #f))))

(define (check-deadlock string modelname)
  (let ((sub (regexp-exec (make-regexp "deadlock-detect: deadlock found and saved to '([^'\n]*)'") string)))
    (if sub (begin
              (stdout "verify: ~a: check: deadlock: fail\n" modelname)
              (stdout "~a" (make-trace (match:substring sub 1) "deadlock" modelname))
              #t)
        (begin (stdout "verify: ~a: check: deadlock: ok\n" modelname) #f))))

(define (check-livelock string modelname)
  (let ((sub (regexp-exec (make-regexp "Trace to the divergencing state is saved to '([^'\n]*)") string)))
    (if sub (begin
              (stdout "verify: ~a: check: livelock: fail\n" modelname)
              (stdout "~a" (make-trace (match:substring sub 1) "livelock" modelname))
              #t)
        (begin (stdout "verify: ~a: check: livelock: ok\n" modelname) #f))))
