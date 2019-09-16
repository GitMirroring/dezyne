;;; Dezyne --- Dezyne command line tools
;;;
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

(define-module (dzn lts2traces)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-9 gnu)
  #:use-module (srfi srfi-26)
  #:use-module (dzn misc)
  #:export (lts->traces))

;; fout_inc = 0
(define %fout-inc 0)

;; class Event:
;;     def __init__(self, str, provides_in):
;;         self.str = str
;;         self.provides_in = provides_in

(define-immutable-record-type <event>
  (make-event str provides-in?)
  event?
  (str event-str)
  (provides-in? event-provides-in?))

;; class Node:
;;     def __init__(self):
;;         self.succ = []
;;         self.prev = []
;;         self.keep = False
;;         self.allowed_end = False
;;         self.close = None

(define-record-type <node>
  (make-node succ prev keep? allowed-end? close)
  node?
  (succ node-succ set-node-succ!)
  (prev node-prev set-node-prev!)
  (keep? node-keep? set-node-keep?!)
  (allowed-end? node-allowed-end? set-node-allowed-end?!)
  (close node-close set-node-close!))

(define %illegal-node (make-node '() '() #f #f #f))
(define (node-vector-ref nodes index)
  (if (= index -1) %illegal-node
      (vector-ref nodes index)))

;; class Edge:
;;     def __init__(self, label, node):
;;         self.label = label
;;         self.node = node

(define-immutable-record-type <edge>
  (make-edge label node)
  edge?
  (label edge-label)
  (node edge-node))

(define-record-type <transition>
  (make-transition from label to)
  transition?
  (from transition-from set-transition-from!)
  (label transition-label)
  (to transition-to set-transition-to!))

(define (drop-quotes e)
  (string-drop-right
   (string-drop e 1)
   1))

(define (line->transition line)
  (let ((lst (string-split (drop-quotes line) #\,)))
    (make-transition (string->number (car lst))
                     (drop-quotes (cadr lst))
                     (string->number (caddr lst)))))

;; class File:
;;     def __init__(self, name, trace):
;;         self.name = name
;;         self.trace = trace
;;         f = open(name, "w")
;;         for e in trace:
;;             f.write(e+"\n")

;; def event_convert (event, interface, flush, ports, provides_in):
;;     event = event[1:-1]

;;     if not flush:
;;         event = re.sub(r".*<flush>", "tau", event)

;;     split = event.split('.');
;;     if len(split)==2 and (interface and interface.split('.')[-1] == split[0]) :
;;         event = split[1]
;;     if len(split)==2 and (split[0] in ports) and split[1]=="<flush>":
;;         event = "tau"

;;     return event

(define (event-convert event interface flush? ports)
  (let ((event (if (or flush?
                       (not (string-contains event "<flush>"))) event
                       "tau"))
        (interface-port (and interface (last (string-split interface #\.)))))
    (match (string-split event #\.)
      (((? (cut equal? <> interface-port)) event) event)
      (((? (cut member <> ports)) "<flush>") "tau")
      (_ event))))

;; def event_provides_in (event, provides_in):
;;     res = event[1:-1] in (provides_in or list())
;;     return res

(define (label-provides-in? label provides-in)
  (and (pair? provides-in)
       (member label provides-in)))

;; def calc_succ_prev (transitions, events, illegal):
;;     nodes = {}
;;     ignore = {}

;;     for t in transitions:
;;         nodes[t[0]] = Node()
;;         nodes[t[2]] = Node()

;;     for t in transitions:
;;         if events[t[1]].str=="illegal":
;;             if illegal:
;;                 nodes[t[0]].keep = True
;;                 t[2] = -1
;;                 nodes[-1] = Node()
;;             else:
;;                 ignore[t[0]] = True

;;     for t in transitions:
;;         if (t[0] not in ignore) and (t[2] not in ignore):
;;             nodes[t[0]].succ.append(Edge(t[1], t[2]))
;;             nodes[t[2]].prev.append(Edge(t[1], t[0]))

;;     return nodes

(define (node-append-succ node edge)
  (if node (and (set-node-succ! node (append (node-succ node) (list edge)))
                node)
      (make-node (list edge) '() #f #f #f)))

(define (node-append-prev node edge)
  (if node (and (set-node-prev! node (append (node-prev node) (list edge)))
                node)
      (make-node (list edge) '() #f #f #f)))

(define (calc-succ-prev transitions events illegal?)
  ;; FIXME: any re-use of lts.scm possible?
  (let ((nodes (list->vector
                (map (lambda _ (make-node '() '() #f #f #f))
                     (iota (* (length transitions) 2)))))
        (ignore (make-hash-table)))
    (for-each (lambda (transition)
                (let ((event (hashq-ref events (transition-label transition)))
                      (from (transition-from transition)))
                  (when (equal? (event-str event) "illegal")
                    (if illegal?
                        (let ((from-node (make-node '() '() #t #f #f)))
                          (set-node-keep?! %illegal-node #t)
                          (vector-set! nodes from from-node)
                          (set-transition-to! transition -1))
                        (hashq-set! ignore from #t)))))
              transitions)
    (for-each (lambda (transition)
                (let ((from (transition-from transition))
                      (to (transition-to transition)))
                  (when (and (not (hashq-ref ignore from #f))
                             (not (hashq-ref ignore to #f)))
                    (let ((label (transition-label transition)))
                      (when (>= from 0)
                        (vector-set! nodes from
                                     (node-append-succ (node-vector-ref nodes from)
                                                       (make-edge label to))))
                      (when (>= to 0)
                        (vector-set! nodes to
                                     (node-append-prev (node-vector-ref nodes to)
                                                       (make-edge label from))))))))
              transitions)
    nodes))

;; def generate_trace (root, nodes, events, fout, out):

(define (generate-trace root nodes events fout out)

  ;;     def allowed_end(node):
  ;;         res = False
  ;;         for edge in node.succ:
  ;;             if events[edge.label].provides_in:
  ;;                 res = True
  ;;         return res

  (define (allowed-end? node)
    (let loop ((edges (node-succ node)))
      (and (pair? edges)
           (or (event-provides-in? (hashq-ref events (edge-label (car edges))))
               (loop (cdr edges))))))

  ;;     def annotate():
  ;;         frontier = []
  ;;         for (key, node) in nodes.items():
  ;;             node.allowed_end = allowed_end(node)
  ;;             if (node.allowed_end):
  ;;                 frontier.append(key)

  ;;         while len(frontier)!=0:
  ;;             node = frontier.pop(0)
  ;;             for edge in nodes[node].prev:
  ;;                 if nodes[edge.node].close is None:
  ;;                     nodes[edge.node].close = Edge(edge.label, node)
  ;;                     frontier.append(edge.node)

  ;; #        for (key, node) in nodes.items():
  ;; #            print "nodes: ", key, " allowed_end: ", node.allowed_end
  ;; #            if node.close:
  ;; #            	print "   close: ", node.close.label, " tgt: ", node.close.node

  (define (annotate)
    (let* ((len (vector-length nodes))
           (frontier (let loop ((index 0))
                       (if (= index len) '()
                           (let ((node (node-vector-ref nodes index)))
                             (set-node-allowed-end?! node (allowed-end? node))
                             (if (node-allowed-end? node) (cons index (loop (1+ index)))
                                 (loop (1+ index))))))))

      (define (extend-frontier index)
        (let loop ((edges (node-prev (node-vector-ref nodes index))))
          (if (null? edges) '()
              (let* ((edge (car edges))
                     (edge-index (edge-node edge))
                     (edge-node (node-vector-ref nodes edge-index)))
                (if (node-close edge-node) (loop (cdr edges))
                    (begin
                      (set-node-close! edge-node (make-edge (edge-label edge) index))
                      (cons edge-index (loop (cdr edges)))))))))

      (let loop ((frontier frontier))
        (when (pair? frontier)
          (let ((index (car frontier)))
            (loop (append (cdr frontier) (extend-frontier index))))))))

  ;;     done = {}
  (let ((done (make-hash-table)))

    ;;     def trace_extend (trace, label):
    ;;         name  = events[label].str
    ;;         if name != "tau":
    ;;             return trace + [name]
    ;;         else:
    ;;             return trace
    (define (trace-extend trace label)
      (let ((name (event-str (hashq-ref events label))))
        (if (equal? name "tau") trace
            (append trace (list name)))))

    ;;     def trace_close (trace, node):
    ;;         if nodes[node].allowed_end or nodes[node].close is None:
    ;;             return trace
    ;;         else:
    ;;             ext_trace = trace_extend(trace, nodes[node].close.label)
    ;;             return trace_close(ext_trace, nodes[node].close.node)
    (define (trace-close trace index)
      (let* ((node (node-vector-ref nodes index))
             (close-edge (node-close node)))
        (if (or (allowed-end? node)
                (not close-edge))
            trace
            (let ((ext-trace (trace-extend trace (edge-label close-edge))))
              (trace-close ext-trace (edge-node close-edge))))))

    ;;     def trace_log (trace):
    ;;         global all_traces
    ;;         global %fout-inc
    ;;         if out:
    ;;             file_name = out + '/' + fout + str (%fout-inc)
    ;;             print file_name
    ;;             open (file_name, 'w').write ('\n'.join(trace))
    ;;         else:
    ;;             if (%fout-inc != 0):
    ;;                 print ","
    ;;             print '{ "filename": "' + fout + str(%fout-inc) + '.zlib", "base64": "' + base64.b64encode(zlib.compress("\n".join(trace))[2:-4]) + '"}'
    ;;         %fout-inc = %fout-inc+1

    (define (trace-log trace)
      ;; (format (current-error-port) "trace-log: ~s\n" trace)
      (let ((file-name (format #f "~a/~a.~a" out fout %fout-inc)))
        (format #t "~a\n" file-name)
        (with-output-to-file file-name
          (lambda _ (display (string-join trace "\n" 'suffix)))))
      (set! %fout-inc (1+ %fout-inc)))

    ;;     def step (node, trace):
    ;;         generated_trace = False
    ;;         if node not in done:
    ;;             if not nodes[node].keep:
    ;;                 done[node] = True;
    ;;             for edge in nodes[node].succ:
    ;;                 if node == edge.node:
    ;;                     trace = trace_extend (trace, edge.label)
    ;;             for edge in nodes[node].succ:
    ;;                 if node != edge.node:
    ;;                     ext_trace = trace_extend (trace, edge.label)
    ;;                     if not step(edge.node, ext_trace):
    ;;                         trace_log ( trace_close (ext_trace, edge.node) )
    ;;                     generated_trace = True
    ;;         return generated_trace

    (define (step index trace)
      ;; (format (current-error-port) "\nstep: index:~s ~s\n" index trace)
      (let ((generated-trace? #f))
        ;;(format (current-error-port) "done[~a]: ~a\n" index (hashq-ref done index #f))
        (and (not (hashq-ref done index #f))
             (let ((node (node-vector-ref nodes index)))
               (when (not (node-keep? node))
                 (hashq-set! done index #t))
               (let ((trace (let loop ((edges (node-succ node)) (trace trace))
                              (if (null? edges) trace
                                  (let ((edge (car edges)))
                                    (if (= index (edge-node edge))
                                        (loop (cdr edges) (trace-extend trace (edge-label edge)))
                                        (loop (cdr edges) trace)))))))
                 ;; (format (current-error-port) "succ:~s\n" (node-succ node))
                 (let loop ((edges (node-succ node)) (generated-trace? #f))
                   (if (null? edges) generated-trace?
                       (let* ((edge (car edges))
                              (edge-index (edge-node edge)))
                         (if (= edge-index index) (loop (cdr edges) generated-trace?)
                             (let ((ext-trace (trace-extend trace (edge-label edge))))
                               (when (not (step edge-index ext-trace))
                                 (trace-log (trace-close ext-trace edge-index)))
                               (loop (cdr edges) #t)))))))))))

    ;;     annotate ()
    ;;     if not out: print "["
    ;;     step (root, [])
    ;;     if not out: print "]"

    (annotate)
    (step root '())))


;; def split_line (line):
;;     return re.sub('\((\d+),("[^"]*"),(\d+)\)',"\\1|\\2|\\3",line).split("|")

;; def lts_write (out, fout, lts):
;;     if out:
;;         file_name = out + '/' + fout
;;         print file_name
;;         open (file_name, 'w').write (lts)
;;     else:
;;         if (%fout-inc != 0):
;;             print ","
;;         print '{ "filename": "' + fout + '.zlib", "base64": "' + base64.b64encode(zlib.compress(lts)[2:-4]) + '"}'

;; def traces (data, illegal, flush, interface, out, gen_lts, model, provided_ports, provides_in):
;;     global %fout-inc
;;     %fout-inc = 0
;;     if interface:
;;     	provided_ports = [model]
;;     interface = model if interface else False

;;     t = re.sub("des","",data[0])
;;     t = re.sub("\(","",t)
;;     t = re.sub("\)","",t)
;;     t = t.split(",")
;;     root = t[0].strip()

;;     del data[0]
;;     transitions = map(split_line, data)

;;     events = {}
;;     for i in range(len(transitions)):
;;         event = transitions[i][1]
;;         events[event] = Event(event_convert(event, interface, flush, provided_ports, provides_in), False)
;;         events[event].provides_in = event_provides_in(event, provides_in)

;;     nodes = calc_succ_prev (transitions, events, illegal)
;;     generate_trace (root, nodes, events, model + ".trace.", out)

;;     if gen_lts:
;;         lts = ""
;;         num_trans = 0;
;;         for k in nodes.keys():
;;             for e in nodes[k].succ:
;;                 lts += "(" + k + "," + events[e.label].str + "," + e.node + ")\n"
;;                 num_trans += 1
;;         lts = "des(" + root + "," + str(num_trans) + "," + str(len(nodes)) + ")\n" + lts
;; 	lts_write (out, model+".aut", lts)

(define (lts->traces data illegal? flush? interface out lts? model provides-ports provides-in)
  (let* ((provides-ports (if (not interface) provides-ports
                             (list model)))
         (interface (and interface model))
         ;; FIXME: any re-use of lts.scm possible?
         (root (car data))
         (root (and (string-prefix? "des (" root) (string-drop root 5)))
         (root (car (string-split root #\,)))
         (root (string->number root))
         (transitions (map line->transition (cdr data))))
    (define (transition->event transition)
      (let ((label (transition-label transition)))
        (make-event (event-convert label interface flush? provides-ports)
                    (label-provides-in? label provides-in))))
    (let ((events (make-hash-table)))
      (for-each (lambda (t) (hashq-set! events (transition-label t) (transition->event t)))
                transitions)
      (let ((nodes (calc-succ-prev transitions events illegal?)))
        (generate-trace root nodes events (string-append model ".trace") out)))))

;; def main():
;;     sys.setrecursionlimit(10000)

;;     parser = argparse.ArgumentParser(prog='lts2traces')
;;     parser.add_argument('--illegal', action='store_true', help='enable illegal entries in trace')
;;     parser.add_argument('--flush', action='store_true', help='enable flush entries in trace')
;;     parser.add_argument('--interface', action='store_true', help='interpret as interface')
;;     parser.add_argument('--out', help='output directory')
;;     parser.add_argument('--lts', action='store_true', help='generate lts')
;;     parser.add_argument('--model', help='model name')
;;     parser.add_argument('--provided', action='append', help='provided ports')
;;     parser.add_argument('--provides-in', action='append', help='provides in events')
;;     parser.add_argument('file')

;;     options = parser.parse_args()

;;     h = sys.stdin
;;     if options.file != '-':
;;         h = open(options.file)
;;     text = h.read ().strip ()
;;     lines = map (lambda line: line.strip (), text.split ('\n'))
;;     traces(lines, options.illegal, options.flush, options.interface, options.out, options.lts, options.model, list(options.provided or ""), options.provides_in)
