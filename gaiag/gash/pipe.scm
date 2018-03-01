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

  :use-module (ice-9 curried-definitions)
  :use-module (ice-9 popen)
  :use-module (ice-9 rdelim)

  :use-module (srfi srfi-1)
  :use-module (srfi srfi-8)
  :use-module (srfi srfi-9)
  :use-module (srfi srfi-26)

  :use-module (gash job)
  :use-module (gaiag command-line)

  :export (pipeline pipeline+ pipeline->string substitute))

(define (pipe*)
  (let ((p (pipe)))
    (values (car p) (cdr p))))

;;              lhs        rhs
;; [source] w[1] -> r[0] [filter] w[1] -> r[0] [sink]
;;          w[2]            ->            r[3] [sink]

(define (exec* command) ;; list of strings
  (catch #t (lambda () (apply execlp (cons (car command) command)))
    (lambda (key . args) (format (current-error-port) "~a\n" (caaddr args))
            (exit #f))))

(define* (spawn fg? job command #:optional (input '()))
  ;;(format #t "spawn: ~a\n" (length input))
  (let* ((ofd '(1)) ;; output file descriptors 1, ...
	 (ifd (cond
	       ((= (length input) 0) '())
	       ((= (length input) 1) '(0))))
	 (pipes (map (lambda (. _) (pipe)) ofd))
	 (r (map car pipes))
	 (w (map cdr pipes))
	 (pid (primitive-fork)))
    ;;(format (current-error-port) "INPUT: ~a\n" (length input))
    ;;(format (current-error-port) "OUTPUT: ~a\n" (length w))
    (cond ((= 0 pid)
           (job-setup-process fg? job)
           (map close r)
           (if (procedure? command)
               (begin
                 (when (pair? input)
                   (close-port (current-input-port))
                   (set-current-input-port (car input)))
                 (when (pair? w)
                   (close-port (current-output-port))
                   (set-current-output-port (car w)))
                 ;;(format (current-error-port) "INPUT: ~a\n" (length input))
                 ;;(format (current-error-port) "OUTPUT: ~a\n" (length w))
                 (if (thunk? command) (command)
                     (command input w))
                 (exit 0))
               (begin
                 (map dup->fdes w ofd)
                 (map dup->fdes input ifd)
                 (exec* command))))
          (#t
           (job-add-process fg? job pid command)
           (map close w)
           r))))

(define ((tee-n file-names) inputs outputs)
  (let* ((files  (map open-output-file file-names))
         (tees (zip files inputs outputs)))
    (let loop ((tees tees))
      (loop (filter-map (lambda (tee)
                     (let ((file (first tee))
                           (input (second tee))
                           (output (third tee)))
                       (when (char-ready? input)
                         (let ((char (read-char input)))
                           (if (not (eof-object? char))
                               (begin (display char file)
                                      (display char output)
                                      (list file input output))
                               #f)))))
                        tees)))
    (map close outputs)))

(define (pipeline+ fg? . commands)
  (receive (r w) (pipe*)
    (move->fdes w 2)
    (let* ((error-port (set-current-error-port w))
           (debug? (pair? (gdzn:debugity)))
           (job (new-job))
           (debug-id (job-debug-id job))
           (commands
            (if (not debug?) commands
                (fold-right (lambda (command id lst)
                              (let ((file (string-append debug-id "." id)))
                                (cons* command `("tee" ,file) lst))) ;;(tee-n (map (cut string-append  file <>) '("-o" "-e"))) ;; `("tee" ,file)
                            '() commands (map number->string (iota (length commands))))))
           (foo (when debug? (with-output-to-file debug-id (cut format #t "COMMANDS: ~s\n" commands))))
           (ports (if (> (length commands) 1)
                      (let loop ((input (spawn fg? job (car commands) '())) ;; spawn-source
                                 (commands (cdr commands)))
                        (if (null? (cdr commands))
                            (spawn fg? job (car commands) input) ;; spawn-sink
                            (loop (spawn fg? job (car commands) input) ;; spawn-filter
                                  (cdr commands))))
                      (spawn fg? job (car commands) '())))) ;; spawn-sink
      (when fg? (wait job))
      (move->fdes error-port 2)
      (set-current-error-port error-port)
      (close w)
      (values job (append ports (list r))))))

(define (pipeline fg? . commands)
  (apply pipeline+ (cons* fg? commands)))

(define (pipeline->string . commands)
  (receive (job ports)
      (apply pipeline+ (cons* #f commands))
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
;;     (pipeline+ #f
;;                (lambda ()
;;                  (display "foo")
;;                  (display "bar" (current-error-port)))
;;                '("tr" "o" "e"))
;;   (map (compose display read-string) ports))

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
