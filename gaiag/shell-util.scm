;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2014, 2015, 2016, 2017 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gaiag shell-util)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (srfi srfi-1)
  #:export (directory-exists?
            mkdir-p
            delete-file-recursively
            copy-recursively
            find-files
            set-file-time
            substitute
            substitute*
            with-directory-excursion))

;;;
;;; Directories.
;;;

(define (directory-exists? dir)
  "Return #t if DIR exists and is a directory."
  (let ((s (stat dir #f)))
    (and s
         (eq? 'directory (stat:type s)))))

(define-syntax-rule (with-directory-excursion dir body ...)
  "Run BODY with DIR as the process's current directory."
  (let ((init (getcwd)))
   (dynamic-wind
     (lambda ()
       (chdir dir))
     (lambda ()
       body ...)
     (lambda ()
       (chdir init)))))

(define (mkdir-p dir)
  "Create directory DIR and all its ancestors."
  (define absolute?
    (string-prefix? "/" dir))

  (define not-slash
    (char-set-complement (char-set #\/)))

  (let loop ((components (string-tokenize dir not-slash))
             (root       (if absolute?
                             ""
                             ".")))
    (match components
      ((head tail ...)
       (let ((path (string-append root "/" head)))
         (catch 'system-error
           (lambda ()
             (mkdir path)
             (loop tail path))
           (lambda args
             (if (= EEXIST (system-error-errno args))
                 (loop tail path)
                 (apply throw args))))))
      (() #t))))

(define* (delete-file-recursively dir
                                  #:key follow-mounts?)
  "Delete DIR recursively, like `rm -rf', without following symlinks.  Don't
follow mount points either, unless FOLLOW-MOUNTS? is true.  Report but ignore
errors."
  (let ((dev (stat:dev (lstat dir))))
    (file-system-fold (lambda (dir stat result)    ; enter?
                        (or follow-mounts?
                            (= dev (stat:dev stat))))
                      (lambda (file stat result)   ; leaf
                        (delete-file file))
                      (const #t)                   ; down
                      (lambda (dir stat result)    ; up
                        (rmdir dir))
                      (const #t)                   ; skip
                      (lambda (file stat errno result)
                        (format (current-error-port)
                                "warning: failed to delete ~a: ~a~%"
                                file (strerror errno)))
                      #t
                      dir

                      ;; Don't follow symlinks.
                      lstat)))

(define (set-file-time file stat)
  "Set the atime/mtime of FILE to that specified by STAT."
  (utime file
         (stat:atime stat)
         (stat:mtime stat)
         (stat:atimensec stat)
         (stat:mtimensec stat)))

(define* (copy-recursively source destination
                           #:key
                           (log (current-output-port))
                           (follow-symlinks? #f)
                           keep-mtime?)
  "Copy SOURCE directory to DESTINATION.  Follow symlinks if FOLLOW-SYMLINKS?
is true; otherwise, just preserve them.  When KEEP-MTIME? is true, keep the
modification time of the files in SOURCE on those of DESTINATION.  Write
verbose output to the LOG port."
  (define strip-source
    (let ((len (string-length source)))
      (lambda (file)
        (substring file len))))

  (file-system-fold (const #t)                    ; enter?
                    (lambda (file stat result)    ; leaf
                      (let ((dest (string-append destination
                                                 (strip-source file))))
                        (format log "`~a' -> `~a'~%" file dest)
                        (case (stat:type stat)
                          ((symlink)
                           (let ((target (readlink file)))
                             (symlink target dest)))
                          (else
                           (copy-file file dest)
                           (when keep-mtime?
                             (set-file-time dest stat))))))
                    (lambda (dir stat result)     ; down
                      (let ((target (string-append destination
                                                   (strip-source dir))))
                        (mkdir-p target)
                        (when keep-mtime?
                          (set-file-time target stat))))
                    (lambda (dir stat result)     ; up
                      result)
                    (const #t)                    ; skip
                    (lambda (file stat errno result)
                      (format (current-error-port) "i/o error: ~a: ~a~%"
                              file (strerror errno))
                      #f)
                    #t
                    source

                    (if follow-symlinks?
                        stat
                        lstat)))

(define (file-name-predicate regexp)
  "Return a predicate that returns true when passed a file name whose base
name matches REGEXP."
  (let ((file-rx (if (regexp? regexp)
                     regexp
                     (make-regexp regexp))))
    (lambda (file stat)
      (regexp-exec file-rx (basename file)))))


(define* (find-files dir #:optional (pred (const #t))
                     #:key (stat lstat)
                     directories?
                     fail-on-error?)
  "Return the lexicographically sorted list of files under DIR for which PRED
returns true.  PRED is passed two arguments: the absolute file name, and its
stat buffer; the default predicate always returns true.  PRED can also be a
regular expression, in which case it is equivalent to (file-name-predicate
PRED).  STAT is used to obtain file information; using 'lstat' means that
symlinks are not followed.  If DIRECTORIES? is true, then directories will
also be included.  If FAIL-ON-ERROR? is true, raise an exception upon error."
  (let ((pred (if (procedure? pred)
                  pred
                  (file-name-predicate pred))))
    ;; Sort the result to get deterministic results.
    (sort (file-system-fold (const #t)
                            (lambda (file stat result) ; leaf
                              (if (pred file stat)
                                  (cons file result)
                                  result))
                            (lambda (dir stat result) ; down
                              (if (and directories?
                                       (pred dir stat))
                                  (cons dir result)
                                  result))
                            (lambda (dir stat result) ; up
                              result)
                            (lambda (file stat result) ; skip
                              result)
                            (lambda (file stat errno result)
                              (format (current-error-port) "find-files: ~a: ~a~%"
                                      file (strerror errno))
                              (when fail-on-error?
                                (error "find-files failed"))
                              result)
                            '()
                            dir
                            stat)
          string<?)))


;;;
;;; Text substitution (aka. sed).
;;;

(define (with-atomic-file-replacement file proc)
  "Call PROC with two arguments: an input port for FILE, and an output
port for the file that is going to replace FILE.  Upon success, FILE is
atomically replaced by what has been written to the output port, and
PROC's result is returned."
  (let* ((template (string-append file ".XXXXXX"))
         (out      (mkstemp! template))
         (mode     (stat:mode (stat file))))
    (with-throw-handler #t
      (lambda ()
        (call-with-input-file file
          (lambda (in)
            (let ((result (proc in out)))
              (close out)
              (chmod template mode)
              (rename-file template file)
              result))))
      (lambda (key . args)
        (false-if-exception (delete-file template))))))

(define (substitute file pattern+procs)
  "PATTERN+PROCS is a list of regexp/two-argument-procedure pairs.  For each
line of FILE, and for each PATTERN that it matches, call the corresponding
PROC as (PROC LINE MATCHES); PROC must return the line that will be written as
a substitution of the original line.  Be careful about using '$' to match the
end of a line; by itself it won't match the terminating newline of a line."
  (let ((rx+proc  (map (match-lambda
                        (((? regexp? pattern) . proc)
                         (cons pattern proc))
                        ((pattern . proc)
                         (cons (make-regexp pattern regexp/extended)
                               proc)))
                       pattern+procs)))
    (with-atomic-file-replacement file
      (lambda (in out)
        (let loop ((line (read-line in 'concat)))
          (if (eof-object? line)
              #t
              (let ((line (fold (lambda (r+p line)
                                  (match r+p
                                    ((regexp . proc)
                                     (match (list-matches regexp line)
                                       ((and m+ (_ _ ...))
                                        (proc line m+))
                                       (_ line)))))
                                line
                                rx+proc)))
                (display line out)
                (loop (read-line in 'concat)))))))))


(define-syntax let-matches
  ;; Helper macro for `substitute*'.
  (syntax-rules (_)
    ((let-matches index match (_ vars ...) body ...)
     (let-matches (+ 1 index) match (vars ...)
                  body ...))
    ((let-matches index match (var vars ...) body ...)
     (let ((var (match:substring match index)))
       (let-matches (+ 1 index) match (vars ...)
                    body ...)))
    ((let-matches index match () body ...)
     (begin body ...))))

(define-syntax substitute*
  (syntax-rules ()
    "Substitute REGEXP in FILE by the string returned by BODY.  BODY is
evaluated with each MATCH-VAR bound to the corresponding positional regexp
sub-expression.  For example:

  (substitute* file
     ((\"hello\")
      \"good morning\\n\")
     ((\"foo([a-z]+)bar(.*)$\" all letters end)
      (string-append \"baz\" letter end)))

Here, anytime a line of FILE contains \"hello\", it is replaced by \"good
morning\".  Anytime a line of FILE matches the second regexp, ALL is bound to
the complete match, LETTERS is bound to the first sub-expression, and END is
bound to the last one.

When one of the MATCH-VAR is `_', no variable is bound to the corresponding
match substring.

Alternatively, FILE may be a list of file names, in which case they are
all subject to the substitutions.

Be careful about using '$' to match the end of a line; by itself it won't
match the terminating newline of a line."
    ((substitute* file ((regexp match-var ...) body ...) ...)
     (let ()
       (define (substitute-one-file file-name)
         (substitute
          file-name
          (list (cons regexp
                      (lambda (l m+)
                        ;; Iterate over matches M+ and return the
                        ;; modified line based on L.
                        (let loop ((m* m+)  ; matches
                                   (o  0)   ; offset in L
                                   (r  '())) ; result
                          (match m*
                            (()
                             (let ((r (cons (substring l o) r)))
                               (string-concatenate-reverse r)))
                            ((m . rest)
                             (let-matches 0 m (match-var ...)
                               (loop rest
                                     (match:end m)
                                     (cons*
                                      (begin body ...)
                                      (substring l o (match:start m))
                                      r))))))))
                ...)))

       (match file
         ((files (... ...))
          (for-each substitute-one-file files))
         ((? string? f)
          (substitute-one-file f)))))))
