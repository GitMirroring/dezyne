(define (drop-prefix string prefix)
  (if (string-prefix? prefix string)
      (substring string (string-length prefix))
      string))

(define (consume_synchronous_out_events event-alist)
  (read-line)
  (let loop ((line (read-line)))
    (and-let* ((line line) 
               ((not (eof-object? line)))
               (event (assoc-ref event-alist (string->symbol line))))
              (event)
              (loop (read-line)))
    line))

(define (log-in prefix event event-alist)
  (stderr "~a~a\n" prefix event)
  (consume_synchronous_out_events event-alist)
  (stderr "~a~a\n" prefix 'return)
  ##f)

(define (log-out prefix event event-alist)
  (stderr "~a~a\n" prefix event)
  ##f)

(define (log-valued prefix event event-alist string->value value->symbol)
  (stderr "~a~a\n" prefix event)
  (let* ((s (consume_synchronous_out_events event-alist))
         (r (string->value s)))
    (if r
        (and (stderr "~a~a\n" prefix (value->symbol r))
             r)
        ##f)))

(define (fill-event-alist o)
  (let ((e `(#
     (map
        (lambda (port)
          (map (define-on model port #{#'()
             (#port .#event  . ,(.#event  (.#direction  (.#port  o))))#})
     (filter (om:dir-matches? port)
     (om:events port)))) (om:ports model)))))
    #(map
      (lambda (port)
        (map (define-on model port #{
      (set! (.#event  (.#direction  (.#port  o)))
       (lambda (. args)#
        (string-if (eq? return-type 'void) #{#'()
      (log-#direction  "#port ." '#event  e)#}#{#'()
    (log-valued "#port ." '#event  e (lambda (s) (assoc-ref #(if (eq? reply-scope '*global*) 'global reply-scope) -#reply-name -alist (string->symbol (drop-prefix s "#port .#reply-name _")))) (lambda (r) (symbol-append '#reply-name _ (assoc-xref #(if (eq? reply-scope '*global*) 'global reply-scope) -#reply-name -alist r))))#})))
#})
                (filter (negate (om:dir-matches? port))
                        (om:events port)))) (om:ports model))       e))

(define (main . args)
  (let* ((print-illegal (lambda () (stderr "illegal\n") (exit 0)))
         (locator (make <locator>))
         (runtime (make <runtime> :illegal print-illegal))
         (sut (make <#.model > :locator (set locator runtime) :name 'sut))
         (event-alist (fill-event-alist sut)))
    (while (and-let*
            ((line (read-line))
             ((not (eof-object? line))))
            (or (and-let* ((event (assoc-ref event-alist (string->symbol line))))
                          (event))
                ##t)))))
