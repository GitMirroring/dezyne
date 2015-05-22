(define (drop-prefix string prefix)
  (if (string-prefix? prefix string)
      (substring string (string-length prefix))
      string))

(define (log-in prefix event)
  (stderr "~a~a\n" prefix event)
  (stderr "~a~a\n" prefix 'return))

(define (log-out prefix event)
  (stderr "~a~a\n" prefix event))

(define (get-value string->value)
  (let loop ((r ##f))
    (or r
        (let ((line (read-line)))
          (if (eof-object? line) (exit 0))
          (loop (string->value line))))))

(define (log-valued prefix event string->value value->symbol)
  (stderr "~a~a\n" prefix event)
  (let ((r (get-value string->value)))
    (if r
        (and (stderr "~a~a\n" prefix (value->symbol r))
             r)
        0)))

(define (fill-event-alist o)
#(map
    (lambda (port)
    (map (define-on model port #{
    (set! (.#event  (.#direction  (.#port  o)))
      (lambda (. args)#
        (string-if (eq? return-type 'void) #{#'()
        (log-#direction "#port .#direction ." '#event)#}#{#'()
        (log-valued "#port .#direction ." '#event (lambda (s) (assoc-ref #interface -#reply-name -alist (string->symbol (drop-prefix s "#port .#reply-name _")))) (lambda (r) (symbol-append '#reply-name _ (assoc-xref #interface -#reply-name -alist r))))#})))
#})
          (filter (negate (om:dir-matches? port))
            (om:events port)))) (om:ports model))
    `(#
(map
    (lambda (port)
    (map (define-on model port #{#'()
      (#port .#event  . ,(.#event  (.#direction  (.#port  o))))#})
    (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model))))

(define (main . args)
  (let* ((print-illegal (lambda () (stderr "illegal\n") (exit 0)))
         (locator (make <locator>))
         (runtime (make <runtime> :illegal print-illegal))
         (sut (make <#.model > :locator (set locator runtime) :name 'sut))
         (event-alist (fill-event-alist sut)))
    (while (and-let*
            ((line (read-line))
             ((not (eof-object? line)))
             (event (string->symbol line)))
            (and-let* ((event (assoc-ref event-alist (string->symbol line))))
                      (event))
            ##t))))
