;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2017, 2018 Johri van Eerd <johri.van.eerd@verum.com>
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
  #:use-module (srfi srfi-26)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <foreign>)) (symbol-append 'goops: x) x)))

  #:use-module (gaiag config)
  #:use-module (gaiag goops)
  #:use-module (gaiag deprecated om)
  #:use-module (gaiag util)
  #:use-module (gaiag mcrl2)
  #:use-module (gaiag misc)
  #:use-module (gaiag resolve)
  #:use-module (gaiag xpand)
  #:use-module (scmcrl2 traces)

  #:export (mcrl2:verify))

(define (compliance-hidden-actions)
  (list "return" "optional" "inevitable" "event" "flush"))

(define (livelock-hidden-actions)
  (list "return" "event" "flush"))

(define (find-taus component modelname hidden-actions)
  (let ((req-ports (if component (map (lambda (r) (.name r)) (om:required component))
                       '())))
    (string-join (append-map (lambda (p)
			       (let ((portname (symbol->string p)))
				 (map (lambda (h)
					(string-append portname "'" h) )
				      hidden-actions)))
			     req-ports)
		 "," 'infix)))

(define-method (mcrl2:init ast template)
  (let ((module (make-module 31 `(,(resolve-module '(gaiag deprecated code))
                                  ,(resolve-module '(gaiag mcrl2))))))
    (module-define! module 'ast ast)
    (parameterize ((template-dir (string-append %template-dir "/mcrl2")))
      (with-output-to-string (lambda () (ast:set-scope ast (x:pand template ast module)))))))

(define (create-lps mcrl2 lpstype ast)
  (let ((lps (string-append (basename mcrl2 ".mcrl2") "_" (->string lpstype) ".lps")))
    (match lpstype
      ('deterministic (system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'determinism-init@ast) " | mcrl22lps -b -lstack > " lps)))
      ('component (system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'component-init@ast) " | mcrl22lps -b -lstack > " lps)))
      ('provided (system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'compliance-init@ast) " | mcrl22lps -b -lstack > " lps))))
    (reduce-lps lps)))

(define (create-if-lps mcrl2 ast)
  (let ((lps (string-append (basename mcrl2 ".mcrl2") "_" ((compose ->string om:name) ast) ".lps")))
    (system (string-append "cat - " mcrl2 " <<< " (mcrl2:init ast 'interface-init@ast) " | mcrl22lps -b -lstack > " lps))
    (reduce-lps lps)))

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
  (blockingcall (string-append "lps2lts --deadlock -t1 -v " lps " " (basename lps ".lps") ".aut 2>&1")))

(define (verifyillegal lps)
  (blockingcall (string-append "lps2lts -aillegal -t1 -v " lps " " (basename lps ".lps") ".aut 2>&1")))

(define (verifylivelock lps taus)
  (blockingcall (string-append "lps2lts --divergence -t1 -v --tau=\"" taus "\" " lps " " (basename lps ".lps") ".aut 2>&1")))

(define (verifyrefinement complps provlps taus)
  (let* ((provlts (string-append (basename provlps ".lps") ".aut"))
	 (complts (string-append (basename complps ".lps") ".aut")))
    (system (string-append "lps2lts " provlps " " provlts))
    (system (string-append "lps2lts " complps " " complts))
    (reduce-lts provlts)
    (reduce-lts complts)
;;    (blockingcall (string-append "ltscompare -v -c -pfailures-divergence --tau=\"" taus "\" " complts " " provlts " 2>&1"))
    (blockingcall (string-append "ltscompare -v -c -pweak-failures --tau=\"" taus "\" " complts " " provlts " 2>&1"))))

(define (verifyall lps taus)
  (blockingcall (string-append "lps2lts -aillegal --deadlock --divergence -t1 -v --tau=\"" taus "\" " lps " " (basename lps ".lps") ".aut 2>&1")))

(define (blockingcall command)
  (let* ((port (open-input-pipe command))
	 (str (read-string port)))
    (close-pipe port)
    str))

(define (mcrl2:verify-interface interface verbose?)
  (let* ((iflps (create-if-lps "verify.mcrl2" interface))
         (output (verifydeadlock iflps))
         (output (string-append output (verifylivelock iflps ""))))
    (interpret-if-results output ((compose ->string om:name) interface) verbose?)))

(define (mcrl2:verify-component modelname ast verbose? all?)
  (let* ((component (find (lambda (x) (equal? (symbol->string (om:name x)) modelname)) (filter (is? <component>) (.elements ast))))
         (interfaces (ast:set-scope ast (delete-duplicates (map .type (om:ports component)))))
         (livelock-taus (find-taus component modelname (livelock-hidden-actions)))
         (compliance-taus (find-taus component modelname (compliance-hidden-actions)))
         (deterministic-lps (create-lps "verify.mcrl2" 'deterministic ast))
         (provided-lps (create-lps "verify.mcrl2" 'provided ast))
         (lpsfile (create-lps "verify.mcrl2" 'component ast))
         (output (verifydeterministic deterministic-lps))
	 (output (string-append output (verifyillegal lpsfile)))
         (output (string-append output (verifydeadlock lpsfile)))
         (output (string-append output (verifylivelock lpsfile livelock-taus)))
         (output (string-append output (verifyrefinement lpsfile provided-lps compliance-taus))))
    (if all?
        (pair? (filter identity (append (map (cut mcrl2:verify-interface <> verbose?) interfaces)
                                        (list (interpret-results output modelname verbose?)))))
        (or (pair? (filter identity (map (cut mcrl2:verify-interface <> verbose?) interfaces)))
            (interpret-results output modelname verbose?)))))


(define (mcrl2:verify modelname ast verbose? all?)
  (if (and all? (not modelname))
      (let ((components (filter (is? <component>) (.elements ast))))
        (pair? (filter identity (map (lambda (c) (mcrl2:verify-component (->string (om:name c)) ast verbose? all?)) components))))
      (let ((model (find (lambda (x) (equal? (symbol->string (om:name x)) modelname)) (filter (is? <model>) (.elements ast)))))
        (if (is-a? model <component>)
            (mcrl2:verify-component modelname ast verbose? #f)
            (mcrl2:verify-interface model verbose?)))))

(define (interpret-if-results output modelname verbose?)
  (let ((deadlock (check-deadlock output modelname verbose?))
        (livelock (check-livelock output modelname verbose?)))
    (or deadlock livelock)))

(define (interpret-results output modelname verbose?)
  (let ((compliance (check-refinement output modelname verbose?))
        (illegal (check-illegal output modelname verbose?))
        (deadlock (check-deadlock output modelname verbose?))
        (livelock (check-livelock output modelname verbose?))
        (deterministic (check-deterministic output modelname verbose?)))
    (or compliance illegal deadlock livelock deterministic)))

(define (check-deterministic string modelname verbose?)
  (let ((sub (regexp-exec (make-regexp "LTS is deterministic") string)))
    (if sub (if verbose? (begin (stdout "verify: ~a: check: deterministic: ok\n" modelname) #f) #f)
        (begin (stdout "verify: ~a: check: deterministic: fail\n" modelname) #t))))

(define (check-refinement string modelname verbose?)
  (let ((sub (regexp-exec (make-regexp "Saved trace to file (.*)\nThe LTS in (.*) is not included in the LTS .*") string)))
    (if sub (begin
              (stdout "verify: ~a: check: compliance: fail\n" modelname)
              (stdout "~a" (make-trace (match:substring sub 1) "refinement" modelname))
              #t)
        (if verbose?
            (begin (stdout "verify: ~a: check: compliance: ok\n" modelname) #f)
            #f))))

(define (check-illegal string modelname verbose?)
  (let ((sub (regexp-exec (make-regexp "Detected action 'illegal' .* and saved to '([^'\n]*)'") string)))
    (if sub (begin
              (stdout "verify: ~a: check: illegal: fail\n" modelname)
              (stdout "~a" (make-trace (match:substring sub 1) "illegal" modelname))
              #t)
        (if verbose?
            (begin (stdout "verify: ~a: check: illegal: ok\n" modelname) #f)
            #f))))

(define (check-deadlock string modelname verbose?)
  (let ((sub (regexp-exec (make-regexp "deadlock-detect: deadlock found and saved to '([^'\n]*)'") string)))
    (if sub (begin
              (stdout "verify: ~a: check: deadlock: fail\n" modelname)
              (stdout "~a" (make-trace (match:substring sub 1) "deadlock" modelname))
              #t)
        (if verbose?
            (begin (stdout "verify: ~a: check: deadlock: ok\n" modelname) #f)
            #f))))

(define (check-livelock string modelname verbose?)
  (let ((sub (regexp-exec (make-regexp "Trace to the divergencing state is saved to '([^'\n]*)") string)))
    (if sub (begin
              (stdout "verify: ~a: check: livelock: fail\n" modelname)
              (stdout "~a" (make-trace (match:substring sub 1) "livelock" modelname))
              #t)
        (if verbose?
            (begin (stdout "verify: ~a: check: livelock: ok\n" modelname) #f)
            #f))))
