
(use-modules (srfi srfi-9 gnu)
             (ice-9 match)
             (ice-9 pretty-print)
             (ice-9 rdelim)
             (gaiag parse)
             (gaiag parse peg)
             (gaiag parse util))

(define-immutable-record-type <missing>
  (make-missing location expectations)
  missing?
  (location     missing-location)
  (expectations missing-expectations))

(define-immutable-record-type <skipped>
  (make-skipped location skipped location-end)
  skipped?
  (location     skipped-location)
  (skipped      skipped-skipped)
  (location-end skipped-location-end))

(define (peg:file-name+offset+error->error file-name offset error text)
  (let ((location (file-offset->location file-name offset text)))
    (match error
      (('missing missing)
       (make-missing location missing))
      (('skipped skipped)
       (let* ((offset-end   (+ offset (string-length skipped)))
              (location-end (file-offset->location file-name offset-end text)))
         (make-skipped location skipped location-end))))))

(define* (peg:collect-errors text #:key (file-name "-"))
  (let ((errors '()))
    (define (add-error! offset string error)
      (let ((error (peg:file-name+offset+error->error file-name offset error text)))
        (set! errors (cons error errors))))
    (parameterize ((%peg:fall-back? #t)
                   (%peg:locations? #t)
                   (%peg:skip? peg:skip-parse)
                   (%peg:error add-error!))
      (peg:parse text))
    errors))

(define file-name "r2.dzn")
(define text (with-input-from-file file-name read-string))
(pretty-print (peg:collect-errors text #:file-name file-name))
