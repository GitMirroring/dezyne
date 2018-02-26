;;; Gash --- Guile As SHell
;;; Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@gmail.com>
;;; Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of Gash.
;;;
;;; Gash is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Gash is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with Gash.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gash pipe)

  :use-module (ice-9 popen)
  :use-module (ice-9 rdelim)

  :use-module (srfi srfi-1)
  :use-module (srfi srfi-8)
  :use-module (srfi srfi-9)
  :use-module (srfi srfi-26)

  :use-module (gash job)

  :export (pipeline pipeline+ pipeline->string substitute))

(define (pipe*)
  (let ((p (pipe)))
    (values (car p) (cdr p))))

;;              lhs        rhs
;; [source] w -> r [filter] w -> r [sink]

(define (exec* command) ;; list of strings
  (catch #t (lambda () (apply execlp (cons (car command) command)))
    (lambda (key . args) (format (current-error-port) "~a\n" (caaddr args))
            (exit #f))))

(define* (spawn fg? job command #:optional (input '()) (output 0))
  ;;(format #t "spawn: ~a ~a\n" (length input) output)
  (let* ((ofd (iota output 1)) ;; output file descriptors 1, ...
	 (count (length input))
	 (start (1+ output))
	 (ifd (cond
	       ((= count 0) '())
	       ((= count 1) '(0))
	       ((#t (cons 0 (iota (1- count) start))))))
	 (pipes (map (lambda (. _) (pipe)) ofd))
	 (r (map car pipes))
	 (w (map cdr pipes))
	 (pid (primitive-fork)))
      (cond ((= 0 pid)
	     (job-setup-process fg? job)
	     (map close r)
	     (map move->fdes w ofd)
	     (map move->fdes input ifd)
             (if (procedure? command)
		 (begin
		   (when (pair? input)
		     (close-port (current-input-port))
		     (set-current-input-port (car input)))
		   (when (pair? w)
		     (close-port (current-output-port))
		     (set-current-output-port (car w)))
		   (command)
		   (primitive-exit 0))
		 (exec* command)))
            (#t
             (job-add-process fg? job pid command)
             (map close w)
             r))))

(define (pipeline+ fg? open . commands)
  (let* ((job (new-job))
         (id (job-debug-id job))
         (commands (reverse
                    (fold (lambda (command lst)
                            (if (pair? lst)
                                (cons* command `("tee" ,(string-append id "." (number->string (quotient (length lst) 2)))) lst)
                                (cons command lst)))
                          '()  commands)))
         (foo (with-output-to-file id (cut format #t "COMMANDS: ~s\n" commands)))
	 (ports (if (> (length commands) 1)
                    (let loop ((input (spawn fg? job (car commands) '() 1)) ;; spawn-source
                               (commands (cdr commands)))
                      (if (null? (cdr commands))
                          (spawn fg? job (car commands) input (or open 0)) ;; spawn-sink
                          (loop (spawn fg? job (car commands) input 1) ;; spawn-filter
                                (cdr commands))))
                    (spawn fg? job (car commands) '() open))))
    (if fg? (wait job) (values job ports))))

(define (pipeline fg? . commands)
  (apply pipeline+ (cons* fg? #f commands)))

(define (pipeline->string . commands)
  (receive (job ports)
      (apply pipeline+ (cons* #f 1 commands))
    (let ((output (read-string (car ports))))
      (wait job)
      output)))

;;(pipeline #f '("head" "-c128" "/dev/urandom") '("tr" "-dc" "A-Z0-9") (lambda () (display (read-string))))
;;(pipeline #f '("head" "-c128" "/dev/urandom") '("tr" "-dc" "A-Z0-9") '("cat"))
;;(pipeline #f (lambda () (display 'foo)) '("grep" "o") '("tr" "o" "e"))

;; (pipeline #f
;; 	  (lambda () (display "\nbin\nboot\nroot\nusr\nvar"))
;; 	  '("tr" "u" "a")
;; 	  (lambda () (display (string-map (lambda (c) (if (eq? c #\o) #\e c)) (read-string))))
;; 	  '("cat")
;; 	  (lambda () (display (read-string))))

;; (receive (job ports)
;;     (pipeline+ #f #t
;; 	      (lambda () (display "\nbin\nboot\nroot\nusr\nvar"))
;; 	      '("tr" "u" "a")
;; 	      (lambda () (display (string-map (lambda (c) (if (eq? c #\o) #\e c)) (read-string))))
;; 	      '("cat"))
;;   (display (read-string (car ports))))


;; _
;;  \
;;   -
;; _/

;; (display (pipeline->string
;;   (lambda () (display "\nbin\nboot\nroot\nusr\nvar"))
;;   '("tr" "u" "a")
;;   (lambda () (display (string-map (lambda (c) (if (eq? c #\o) #\e c)) (read-string))))
;;   '("cat")
;;   (lambda () (display (read-string)) (newline))))

(define (substitute . commands)
  (string-trim-right
   (string-map (lambda (c)
                 (if (eq? #\newline c) #\space c))
               (apply pipeline->string commands))
   #\space))

;; (display (pipeline->string '("ls") '("cat"))) (newline)
;; (display (substitute '("ls") '("cat"))) (newline)
