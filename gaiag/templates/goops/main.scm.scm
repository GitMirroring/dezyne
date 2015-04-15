
(define (fill-event-alist o)
#(map
    (lambda (port)
    (map (define-on model port #{
    (set! (.#event  (.#direction  (.#port  o)))
      (lambda (. args)
        (stderr "~a.~a.~a\n" '#port  '#direction  '#event)#
       (string-if (not (eq? type 'void)) #{#'()
       #(list "'(" (.name enum) " " (car (.elements (.fields enum))) ")")#})))#})
          (filter (negate (gom:dir-matches? port))
            (gom:events port)))) (gom:ports model))
    `(#
(map
    (lambda (port)
    (map (define-on model port #{#'()
      (#port .#event  . ,(.#event  (.#direction  (.#port  o))))#})
    (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model))))

(define (main . args)
  (let* ((sut (make <#.model > :name 'sut))
         (event-alist (fill-event-alist sut)))
    (while (and-let*
            ((line (read-line))
             ((not (eof-object? line)))
             (event (string->symbol line)))
            (and-let* ((event (assoc-ref event-alist (string->symbol line))))
                      (event))
            ##t))))
