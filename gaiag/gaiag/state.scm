;;; Dezyne --- Dezyne command line tools
;;; Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
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

(define-module (gaiag state)
  #:use-module (ice-9 curried-definitions)
  #:use-module (ice-9 pretty-print)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 receive)

  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)

  #:use-module (ice-9 match)

  #:use-module (json)

  #:use-module ((oop goops) #:renamer (lambda (x) (if (member x '(<port> <frame> <foreign>)) (symbol-append 'goops: x) x)))
  #:use-module (gaiag goops)
  #:use-module (gaiag ast)
  #:use-module (gaiag misc)
  #:use-module (gaiag command-line)
  #:use-module (gaiag runtime)
  #:use-module (gaiag serialize)

  #:use-module (gaiag step goops)
  #:use-module (gaiag step normalize)
  #:use-module (gaiag step json)
  #:use-module (gaiag step)

  #:export (%lts
            dot
            go
            lts->
            node->vertex
            vertex-equal?
            ))

(define %lts (make-parameter #f))

(define skip-count 0)

(define-method (skip (node <node>) (instance <runtime:instance>) (action <action-out>))
  ;;  (set! skip-count (warn 'skip: (1+ skip-count)))
  (let* ((port (.port action))
         (runtime-port (runtime:port instance port))
         (other-instance (runtime:other-port runtime-port))
         (node (record-step node other-instance (make <action-out> #:event.name (.event.name action)))))
    (list node)))

(define-method (skip (node <node>) (instance <runtime:instance>) (action <action>))
;;  (set! skip-count (warn 'skip: (1+ skip-count)))
  (let* ((port (.port action))
         (runtime-port (runtime:port instance port))
         (other-instance (runtime:other-port runtime-port))

         (return-values (ast:return-values (.event action)))
         (return-values (if (null? return-values) (list (make <literal>)) return-values))
         (replies (map (compose (cut clone <> #:parent (.type (.instance other-instance)))
                                (cut make <reply> #:expression <>)) return-values))
         (node (record-step node other-instance (make <trigger> #:event.name (.event.name action)))))
    (map (lambda (reply) (record-step (set-reply node other-instance reply) other-instance reply)) replies)))

(define-class <vertex> (<step>)
  (state #:getter .state #:init-form (list) #:init-keyword #:state))

(define-class <edge> (<step>)
  (from #:getter .from #:init-value #f #:init-keyword #:from)
  (to #:getter .to #:init-value #f #:init-keyword #:to)
  (label #:getter .label #:init-value #f  #:init-keyword #:label))

(define-method (vertex->node (o <vertex>))
  (let ((node (json:create-initial-node (make <step:transition-list>))))
    (fold (lambda (i n)
            (set-state n i (make <state> #:vars (assoc-ref (.state o) i))))
          node
          (filter (disjoin runtime:boundary-port? runtime:component-instance?) (%instances)))))

(define-method (vertex-equal? (a <vertex>) (b <vertex>))
  (equal? (vertex->string a) (vertex->string b)))

(define-method (node->vertex (o <node>) instances)
  (make <vertex> #:state
        (map (lambda (i)
               (cons i (.vars (assoc-ref (.state-alist o) i))))
             instances)))

(define (go edges)
  (define (->string instances-state)
    (scm->json-string
     (map (lambda (instance-state)
            (cons (string->symbol
                   (string-join (map (compose symbol->string .name .instance)
                                     (reverse (runtime:container-path (car instance-state)))) "."))
                  (map (lambda (s)
		         (cons (car s) (->symbol (cdr s))))
                       (cdr instance-state))))
          instances-state)))

  (let* ((edges ((compose (if (command-line:get 'remove-duplicate-transitions) remove-duplicates identity)
                          (if (command-line:get 'remove-self-transitions) remove-self identity)
                          (remove-vars (map string->symbol (string-split (command-line:get 'remove-vars "") #\space))))
                 edges))
	 (vertices (delete-duplicates (append (map .from edges) (map .to edges)) vertex-equal?))
	 (vertex-strings (map (compose ->string .state) vertices)))
    (define (id vertex)
      (number->string (list-index (cute equal? (->string (.state vertex)) <>) vertex-strings)))
    (define (vertex->string vertex)
      (string-append "{\"id\": \""
                     (id vertex)
                     "\", \"text\": \"\", \"state\": "
                     (->string (.state vertex))
                     "}\n"))
    (define (edge->string edge)
      (string-append "{\"from\": \""
                     (id (.from edge))
                     "\", \"to\": \""
                     (id (.to edge))
                     "\", \"text\": \""
                     (string-join (map step->label (.label edge)) "\\n")
                     "\"}\n"))
    (display "{ \"nodeKeyProperty\": \"id\",\n")
    (display "\"nodeDataArray\": [\n")
    (display "{\"id\": \"*\", \"text\": \"\", \"state\": {}},\n")
    (display (string-join (map vertex->string vertices) ",\n" 'infix))
    (display "],\n\"linkDataArray\": [\n")
    (display (string-append "{\"from\": \"*\", \"to\": \"" (id (.from (car edges))) "\", \"text\": \"\"},\n"))
    (display (string-join (map edge->string edges) ",\n"))
    (display "]\n}\n")))

(define (state->pair state)
  (cons (car state) (format #f "~a" (ast:value (cdr state)))))
(define (runtime:type-name o)
  ((compose (cut symbol-join <> ".") ast:full-name .type .instance) o))
(define (goopify edges)
  (define (->string instances-state)
    (scm->json-string
     (map (lambda (instance-state)
            (cons (string->symbol
                   (string-join (map (compose symbol->string .name .instance)
                                     (reverse (runtime:container-path (car instance-state)))) "."))
                  (map (lambda (s)
		         (cons (car s) (->symbol (cdr s))))
                       (cdr instance-state))))
          instances-state)))

  (let* ((edges ((compose (if (command-line:get 'remove-duplicate-transitions) remove-duplicates identity)
                          (if (command-line:get 'remove-self-transitions) remove-self identity)
                          (remove-vars (map string->symbol (string-split (command-line:get 'remove-vars "") #\space))))
                 edges))
	 (vertex-pairs (map (lambda (vertex) (cons ((compose ->string .state) vertex) vertex))
                            (append (map .from edges) (map .to edges))))
         (vertex-pairs (delete-duplicates vertex-pairs (lambda (a b) (string=? (car a) (car b))))))

    (define (id vertex-string)
      (list-index (lambda (vp) (equal? vertex-string (car vp))) vertex-pairs))
    (define (vertex->instance vertex)
      (make <step:instance+state-alist> #:alist
            (map (lambda (p)
                   (cons (symbol-join (runtime:instance->path (car p)) ".")
                         (make <step:instance+state>
                           #:type (runtime:type-name (car p))
                           #:kind (runtime:kind (car p))
                           #:state (make <step:state-alist>
                                     #:alist
                                     (map state->pair (cdr p))))))
                 (.state vertex))))
    (define (vertex->lts:node vertex-pair)
      (cons (id (car vertex-pair)) (vertex->instance (cdr vertex-pair))))
    (define (edge->lts:link edge)
      (let* ((steps (.label edge))
             (events (steps->events steps)))

        (make <step:lts-link> #:from (id ((compose ->string .state .from) edge)) #:to (id ((compose ->string .state .to) edge)) #:event (make <step:event-list> #:list events))))

    ((@@ (gaiag step-serialize) step:serialize)
     (make <step:lts>
       #:node (make <step:node-alist> #:alist (map vertex->lts:node vertex-pairs))
       #:link (make <step:list> #:list (map edge->lts:link edges)))
     (current-output-port))
    (newline)

    ;; (serialize (make <step:lts>
    ;;              #:node (make <step:node-alist> #:alist (map vertex->lts:node vertices))
    ;;              #:link (make <step:list> #:list (map edge->lts:link edges))))
    ;; (newline)

    ;; (serialize `((node . ,(map vertex->lts:node vertices))
    ;;              (link . ,(map edge->lts:link edges))))
    ))

(define (dot edges)
  (define (->string instances-state)
    (string-join
     (map
      (lambda (instance-state)
        (string-append (string-join (map (compose symbol->string .name .instance) (reverse (runtime:container-path (car instance-state)))) ".") " : ["
         (string-join (map
                       (lambda (s)
		         (string-append
                          (symbol->string (car s)) "="
			  (symbol->string (->symbol (cdr s))))) (cdr instance-state)) ", ")
         "]\\l"))
      instances-state) ""))
  (let ((edges ((compose (if (command-line:get 'remove-duplicate-transitions) remove-duplicates identity)
                         (if (command-line:get 'remove-self-transitions) remove-self identity)
                         (remove-vars (map string->symbol (string-split (command-line:get 'remove-vars "") #\space)))) edges)))
    (display "digraph G {\n")
    (display "begin[shape=\"circle\" width=0.3 fillcolor=\"black\" style=\"filled\" label=\"\"]\n")
    (display "node[shape=\"rectangle\" style=\"rounded\"]\n")
    (when (pair? edges)
      (display "begin -> \"") (display (->string (.state (.from (car edges))))) (display "\"\n"))
    (for-each (lambda (edge)
                (display "\"")
	        (display (->string (.state (.from edge))))
                (display "\" -> \"")
                (display (->string (.state (.to edge))))
                (display "\" [label=\"") (display (string-join (map step->label (.label edge)) "\n")) (display "\"]\n"))
              edges)
    (display "}\n")))

(define-method (vertex->string (o <vertex>))
  (map (lambda (instance-state)
         (let ((instance (car instance-state))
               (state (cdr instance-state)))
           (string-append (string-join (map symbol->string (runtime:instance->path instance)))
                          (string-join (append-map (lambda (s) (list (symbol->string (car s)) (symbol->string (->symbol (cdr s))))) state)))))
       (.state o)))

(define ((remove-vars vars) edges)
  (let ((erase (lambda (vertex vars)
                 (let ((state (map (lambda (instance-state)
                                     (cons (car instance-state)
                                           (filter (lambda (var)
                                                     (not (find (cut equal? (car var) <>) vars)))
                                                   (cdr instance-state))))
                                   (.state vertex))))
                   (make <vertex> #:state state)))))
    (map (lambda (edge)
           (make <edge>
             #:from (erase (.from edge) vars)
             #:to (erase (.to edge) vars)
             #:label (.label edge)))
         edges)))

(define (remove-self edges)
  (filter (lambda (edge)
            (not (equal? (vertex->string (.from edge))
                         (vertex->string (.to edge))))) edges))

(define (remove-duplicates edges)
  (delete-duplicates edges (lambda (a b)
                             (and (equal? (.label a) (.label b))
                                  (equal? (vertex->string (.from a)) (vertex->string (.from b)))
                                  (equal? (vertex->string (.to a)) (vertex->string (.to b)))))))

(define-method (labels (o <runtime:component>))
  (ast:in-triggers (.type (.instance o))))


(define-method (labels (o <runtime:system>))
  (let* ((system (.type (.instance o)))
         (bindings (ast:binding* system))
         ;;(ports (map runtime:other-port (filter .boundary? (%instances))))
         (ports (filter (conjoin .boundary? (compose ast:provides? .instance)) (%instances))))
    (append-map (lambda (port)
                  (map (lambda (e)
                         (make <runtime:trigger> #:instance port #:event.name (.name e)))
                       (if (ast:provides? (.instance port)) (filter ast:in? (ast:event* (.type (.instance port))))
                           (filter ast:out? (ast:event* (.type (.instance port))))))) ;;FIXME simplify
                ports)))

(define-method (run-label (node <node>) (label <trigger>)) ;;FIXME: finish refactor <trigger> -> <runtime:trigger> or ???
  (run node (%sut) label))

(define-method (run-label (node <node>) (label <runtime:trigger>))
  (let ((trigger (make <trigger> #:port.name ((compose .name .instance .instance) label) #:event.name (.event.name label)))
        (instance (.container (.instance label))))
    (if (is-a? (%sut) <runtime:system>)
        (let* ((port (runtime:other-port (.instance label)))
               (record-trigger (make <trigger> #:event.name (.event.name label)))
               (component-port (runtime:find-instance (.port.name trigger) instance #f)))
          (if component-port (let* ((system-port (runtime:other-port component-port)))
                               (run (record-step node port record-trigger) instance trigger))
              (list (set-status node (make <no-match>)))))
        (run node instance trigger))))

(define-method (run-label (node <node>) (label <runtime:trigger>))
  (let ((trigger (make <trigger> #:port.name ((compose .name .instance .instance) label) #:event.name (.event.name label))))
    (run-trigger node trigger)))

(define (step->label s)
  (let ((instance (car s))
        (statement (cdr s)))
    (string-join
     (map symbol->string
          (append (if
                   (or (is-a? statement <reply>) (is-a? statement <trigger-return>)
                       (is-a? (.container instance) <runtime:foreign>))
                   (runtime:instance->path instance)
                   (runtime:instance->path instance))
                  (list (->symbol statement))))  ".")))

(define-method (lts (node <node>))
  (define (make-edges instances from to)
    (let* (;;(steps (drop (.steps to) (length (.steps from))))
           (steps (.steps to))
           (steps (map (lambda (step)
                         (let ((instance (car step))
                               (statement (cdr step)))
                           (if (and (is-a? instance <runtime:foreign>) ;; CHECKME
                                (is-a? statement <action>)
                                    (not (is-a? statement <action-out>))
                                    (let* ((instance-port (runtime:find-instance (.port.name statement) instance #f))
                                           (other-port (runtime:other-port instance-port)))
                                      (runtime:boundary-port? other-port)))
                               (let* ((instance-port (runtime:find-instance (.port.name statement) instance #f))
                                      (other-port (runtime:other-port instance-port)))
                                 (cons (%sut) (action->trigger other-port statement)))
                               step)))
                       steps))
           (steps (filter (conjoin (negate state-step?) (all-relevant-steps-for-now)) steps)))
      (make <edge>
        #:from from
        #:to (node->vertex to instances)
        #:label steps))) ;;FIX go & dot by mapping step->label over steps
  (let* ((labels (labels (%sut)))
         (hes (lambda (vertex-string size) (hash vertex-string size)))
         (hes-tebel (make-hash-table 1024))
         (instances (filter (disjoin (negate (is? <runtime:port>)) runtime:boundary-port?) (%instances)))
         (requires-instances (filter runtime:requires-instance? (%instances)))
         (initial (node->vertex node instances))
         (foo (hashx-set! hes assoc hes-tebel (vertex->string initial) #t)))
    (let loop ((frontier (list initial)) (edges '()) (horizon (and=> (command-line:get 'horizon #f) string->number)))
      (let* ((new-edges (append-map
                         (lambda (vertex)
                           (let ((node (vertex->node vertex)))
                             (map (cut make-edges instances vertex <>)
                                   (filter (negate .status)
                                           (append
                                            (append-map (cut run node <> (make <trigger> #:event.name 'optional)) requires-instances)
                                            (append-map (cut run node <> (make <trigger> #:event.name 'inevitable)) requires-instances)
                                            (append-map (cut run-label node <>) labels))))))
                         frontier))
             (frontier (filter (lambda (vertex)
                                 (let* ((vertex-hash (vertex->string vertex))
                                        (r (not (hashx-ref hes assoc hes-tebel vertex-hash))))
                                   (when r (hashx-set! hes assoc hes-tebel vertex-hash #t))
                                   r))
                               (map .to new-edges)))
             (edges (append edges new-edges)))
        (if (or (and horizon (= 0 horizon)) (null? frontier)) edges
            (loop frontier edges (and horizon (1- horizon))))))))

(define (lts-> -> root)
  (setup-debug-printing!)
  (let* ((root (step:normalize root))
         (sut (runtime:get-sut root)))
    (parameterize ((%sut sut))
      (parameterize ((%instances (runtime:get-system-instances sut))
                     (%lts #t))
        (if (member -> (list dot go goopify)) (-> (lts (json:create-initial-node (or (and=> (command-line:get 'initial #f) json->trail) (make <step:transition-list>)))))
            (let* ((instance (.instance sut))
                   (model (.type instance))
                   (name (.name (.name model))) ;; FIXME: namespace
                   (type (ast-name model))
                   (state (with-output-to-string (cut -> (lts (json:create-initial-node (make <step:transition-list>))))))
                   (model-names (map (compose .name .name) (ast:model* root)))
                   (other-names (filter (negate (cut eq? name <>)) model-names))
                   (others-alist (map (compose list (cut cons 'name <>)) other-names))
                   (json (scm->json-string `((models . (((name . ,name) (type . ,type) (state . ,state))
                                                        ,@others-alist))))))
              (format (current-error-port) "json:~s\n" json)
              (display json)
              (newline))))))
  "")
