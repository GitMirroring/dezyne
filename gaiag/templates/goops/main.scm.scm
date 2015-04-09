
(define (main . args)
  (let ((sut (make <#.model >)))
    (format ##t "run\n")
    (while (and-let*
            ((line (read-line))
             ((not (eof-object? line))))
            (action (.alarm sut) .console .in .arm)))))

