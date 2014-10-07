component.#.model  = function() {
#(->string (map declare-enum (gom:enums (.behaviour model))))
#
    (map (init-member model #{
        this.#name  = #expression;
#}) (gom:variables model))#
    (delete-duplicates (map (compose declare-replies code:import .type) ((compose .elements .ports) model)))
#
    (map
     (lambda (port)
       (let ((name (.name port))
             (interface (.type port)))
         (->string (list "        self." name " = interface." interface " ()\n"))))
     ((compose .elements .ports) model))
#
   (map
    (lambda (port)
      (map
       (lambda (event)
         (->string (list "        self." (.name port) ".ins." (.name event) " = "  "self." (.name port) "_" (.name event) "\n")))
       (filter gom:in? (gom:events port))))
    (filter gom:provides? (gom:ports model)))#
   (map
    (lambda (port)
      (map
       (lambda (event)
         (->string (list "        self." (.name port) ".outs." (.name event) " = "  "self." (.name port) "_" (.name event) "\n")))
       (filter gom:out? (gom:events port))))
    (filter gom:requires? (gom:ports model)))
#(map
   (lambda (port)
     (map
      (lambda (event)
        (let* ((type ((compose .type .type) event))
               (return-type (return-type port event))
               (reply-type (->string (list (.type port) "_" (.name type))))
               (statement
                (or (and-let*
                     (((is-a? model <component>))
                      (component model)
                      (behaviour (.behaviour component))
                      (statement (.statement behaviour)))
                     (parameterize ((statements.port port)
                                    (statements.event event))
                       (javascript:->code model statement '() 2 #f)))
                    "")))
          (->string
           (list
            "    def " (.name port) "_" (.name event) " (self):\n"
            "        sys.stderr.write ('" (.name model) "." (.name port) "_" (.name event) "\\n')\n"
            statement
            (if (not (eq? (.name type) 'void))
                (->string (list "        return self.reply_" reply-type "\n")))
            "\n"))))
      (filter (gom:dir-matches? port) (gom:events port))))
   (gom:ports model))# (map
 (lambda (function)
   (let* ((signature (.signature function))
          (return-type (javascript:->code model signature))
          (name (.name function))
          (parameters (.parameters signature))
          (comma (if (null? (.elements parameters)) "" ", "))
          (statement (.statement function))
          (locals (map (lambda (x) (cons (.name x) x)) (.elements parameters)))
          (parameters (javascript:->code model parameters))
          (statements (javascript:->code model statement locals 2))
          (model (.name model)))
     (->string (list "    " "def " name " (self" comma parameters "):\n"
                     statements))))
 (gom:functions model))
