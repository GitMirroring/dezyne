;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
;;; Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

(define-module (dzn explore constraint)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-2)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-71)

  #:use-module (ice-9 match)

  #:use-module (dzn ast display)
  #:use-module (dzn ast goops)
  #:use-module (dzn ast)
  #:use-module (dzn misc)
  #:use-module (dzn vm ast)
  #:use-module (dzn explore)
  #:use-module (dzn vm compliance)
  #:use-module (dzn vm goops)
  #:use-module (dzn vm normalize)
  #:use-module (dzn vm report)
  #:use-module (dzn vm run)
  #:use-module (dzn vm runtime)
  #:use-module (dzn vm util)

  #:export (interface->constraint))

;;;
;;; Interface constraints.
;;;

;;; constraining process transformation:
;;; - resolve non-det choice between legal and illegal to illegal
;;; - merge duplicate triggers
;;; - remove modeling events

(define (rtc-lts->constraint-transition lts pc->state-number)
  "Create a constraint for LTS."

  (define (trace->trigger trace)
    (let ((pc (find (conjoin (compose (is? <on>) .statement)
                             (disjoin (const (is-a? (%sut) <runtime:port>))
                                      (compose (is? <runtime:component>) .instance)))
                    (reverse trace))))
      (and pc
           ((compose car ast:trigger* .statement) pc))))

  (define (trace->string-trail trace)
    (let* ((trail (map cdr (trace->trail trace)))
           (trail (filter (negate (cute string-suffix? ".return" <>)) trail)))
      (define (strip-sut-prefix o)
        (if (string-prefix? "sut." o) (substring o 4) o))
      (map strip-sut-prefix trail)))

  (define (reply-statement pc)
    (let ((statement (.statement pc)))
      (and (is-a? statement <trigger-return>)
           (and-let* ((reply (.reply (get-state pc (.instance pc))))
                      (value (assoc-ref reply "sut"))
                      (reply (make <reply> #:expression value)))
             (clone reply #:parent (.parent statement))))))

  (define (assign-statement last-pc pc)
    (let ((statement (.statement pc)))
      (and (is-a? statement <assign>)
           (let* ((instance (.instance pc))
                  (variable (.variable statement))
                  (variables (get-variables last-pc instance))
                  (name (.name variable))
                  (value (assoc-ref variables name)))
             (and (is-a? (.parent variable) <variables>)
                  (clone statement #:expression value))))))

  (define (transition->constraint-transition pc->state-number from pc+traces)
    (let* ((pc traces (match pc+traces ((pc . traces) (values pc traces))))
           (traces (filter (compose not .status car) traces))
           (pcs (map car traces))
           (previous-pcs (map cadr traces))
           (traces (map reverse traces))
           (triggers (map trace->trigger traces))
           (trigger (and (pair? triggers) (car triggers)))
           (behavior (and trigger (ast:parent trigger <behavior>)))
           (missing-triggers (filter (negate identity) triggers))
           (constrained-legal (make <constrained-legal>))
           (constrained-legal (clone constrained-legal #:parent behavior))
           (transition (make <constraint-transition> #:from 1))
           (transition (clone transition #:parent behavior))
           (missing-triggers? (or (null? traces)
                                  (pair? missing-triggers))))
      (define (trigger+trace->statement trigger trace)
        (let ((actions (filter-map (compose (cute as <> <action>) .statement)
                                   trace))
              (replies (filter-map reply-statement trace)))
          (if (ast:modeling? trigger) (append actions replies)
              (cons trigger
                    (append (list constrained-legal)
                            actions
                            replies)))))
      (define (trace->assignments trace)
        (let ((last-pc (last trace)))
          (filter-map (cute assign-statement last-pc <>) trace)))
      (if missing-triggers? (list transition)
          (let* ((previous-pc (car previous-pcs))
                 (statements (map trigger+trace->statement triggers traces))
                 (statements (map (compose
                                   (cute clone <> #:parent behavior)
                                   (cute make <compound> #:elements <>))
                                  statements))
                 (assignments (map trace->assignments traces))
                 (assignments
                  (map (compose
                        (cute clone <> #:parent behavior)
                        (cute make <compound> #:elements <>)) assignments))
                 (tos (map pc->state-number pcs)))
            (map (compose
                  (cute clone <> #:parent behavior)
                  (cute make <constraint-transition>
                        #:from from
                        #:statements <>
                        #:assignments <>
                        #:to <>))
                 statements assignments tos)))))

  (let* ((alist (hash-table->alist lts))
         (alist (sort alist
                      (match-lambda*
                        (((from-a . pc+traces-a) (from-b . pc+traces-b))
                         (< from-a from-b)))))
         (transitions
          (append-map
           (cute transition->constraint-transition pc->state-number <> <>)
           (map car alist)
           (map cdr alist))))
    transitions))

(define (constraint-transitions->constraint transitions model)

  (define (branch-index lst1 lst2)
    (or (any (lambda (a b i)
               (and (not (ast:equal? a b)) i)) lst1 lst2 (iota (length lst1)))
        (min (length lst1) (length lst2))))

  (define (matching-prefix statement branch)
    (let ((prefix (ast:statement* branch)))
      (and (pair? prefix)
           (ast:equal? statement (car prefix)))))

  (define (merge-transition-into-constraint transition constraint)
    (let* ((path (ast:statement* transition))
           (branches (ast:constraint-branch* constraint))
           (to (.to transition))
           (assignments (.assignments transition))
           (behavior (.behavior model))
           (process (make <constraint-process>
                      #:to to
                      #:assignments assignments))
           (process (clone process #:parent behavior))
           (process-branch (make <constraint-branches>
                             #:elements (list process))))

      (let loop ((path path) (branches branches) (constraint constraint))
        (if (null? path) constraint
            (let* ((branch (find (cute matching-prefix (car path) <>) branches))
                   (prefix (and branch (ast:statement* branch)))
                   (index (and prefix (branch-index path prefix))))

              (define (add-branch)
                (let* ((branch (make <constraint-branch>
                                 #:prefix (make <compound> #:elements path)
                                 #:branches (and to process-branch)))
                       (branches (make <constraint-branches>
                                   #:elements (cons branch branches))))
                  (clone constraint #:branches branches)))

              (define (fork-branch)
                (let* ((branches (delete branch branches))
                       (common prefix-remainder (split-at prefix index))
                       (common path-remainder (split-at path index))
                       (first (make <constraint-branch>
                                #:prefix (make <compound>
                                           #:elements path-remainder)
                                #:branches (and to process-branch)))
                       (second (clone branch
                                      #:prefix (make <compound>
                                                 #:elements prefix-remainder)))
                       (branch (make <constraint-branch>
                                 #:prefix (make <compound> #:elements common)
                                 #:branches (make <constraint-branches>
                                              #:elements (list first second)))))
                  (clone constraint
                         #:branches (make <constraint-branches>
                                      #:elements (cons branch branches)))))

              (define (remainder-branch)
                (let* ((prefix path (split-at path index)))
                  (let* ((branches (ast:constraint-branch* branch))
                         (sub-constraint (loop path branches constraint))
                         (branches (make <constraint-branches>
                                     #:elements
                                     (ast:constraint-branch* sub-constraint)))
                         (branch (clone branch #:branches branches)))
                    (clone constraint #:branches
                           (clone (.branches constraint)
                                  #:elements (list branch))))))

              (if (not branch) (add-branch)
                  (cond ((= index (length path) (length prefix))
                         constraint)
                        ((not (= index (length prefix)))
                         (fork-branch))
                        (else
                         (remainder-branch)))))))))

  (define (make-constraint transition constraints)
    (let* ((from? (compose (cute = (.from transition) <>) .from))
           (constraint (find from? constraints))
           (process (make <constraint-process>
                      #:to (.to transition)
                      #:assignments (.assignments transition)))
           (branches (and (.to transition)
                          (make <constraint-branches>
                            #:elements (list process))))
           (statements (.statements transition))
           (branch (make <constraint-branch>
                     #:prefix statements
                     #:branches branches))
           (branches (make <constraint-branches> #:elements (list branch)))
           (behavior (.behavior model))
           (constraint (or constraint
                           (clone (make <constraint>
                                    #:from (.from transition)
                                    #:branches branches)
                                  #:parent behavior))))
      (if (null? constraints) (list constraint)
          (cons (merge-transition-into-constraint transition constraint)
                (delete constraint constraints)))))

  (let* ((constraints (fold make-constraint '() transitions))
         (behavior (.behavior model))
         (constraints (map (cute clone <> #:parent behavior) constraints)))
    (sort constraints (match-lambda* ((a b) (< (.from a) (.from b)))))))

(define (add-missing-from transitions)
  (let* ((froms (map .from transitions))
         (tos (filter-map .to transitions))
         (missing (lset-difference = tos froms)))
    (append transitions
            (map (cute make <constraint-transition> #:from <>)
                 missing))))

(define (add-interface-illegals model transitions)
  (let* ((froms (delete-duplicates (map .from transitions)))
         (illegal (make <illegal>))
         (illegal (clone illegal #:parent model))
         (assignments (make <compound>))
         (assignments (clone assignments #:parent model)))
    (define (constraint->transitions from)
      (define (trigger->constraint trigger)
        (let* ((statements (make <compound> #:elements (list trigger illegal)))
               (statements (clone statements #:parent model))
               (constraint
                (make <constraint-transition>
                  #:from from #:statements statements ;;#:to from
                  )))
          (clone constraint #:parent model)))
      (let* ((transitions
              (filter (compose (cute eq? from <>) .from) transitions))
             (triggers (map ast:statement* transitions))
             (triggers (filter pair? triggers))
             (triggers (map car triggers))
             (in-triggers
              (filter (negate ast:modeling?) (ast:in-triggers model)))
             (illegal-triggers
              (lset-difference ast:equal? in-triggers triggers))
             (illegal-transitions
              (map trigger->constraint illegal-triggers)))
        (append transitions illegal-transitions)))

    (append-map constraint->transitions froms)))

(define (interface->transitions root model)
  (let* ((root (vm:normalize root))
         (model (ast:get-model root (ast:dotted-name model))))
    (parameterize ((%compliance-check? #f)
                   (%exploring? #t)
                   (%sut (runtime:get-sut #f model)))
      (parameterize ((%instances (list (%sut))))
        (let* ((pc (make-pc))
               (lts pc->state-number state-count (pc->rtc-lts pc)))
          (map (cute clone <> #:parent model)
               (rtc-lts->constraint-transition lts pc->state-number)))))))

(define-method (add-missing-branches (model <interface>) constraint)
  "Add a <constraint-branch> for each complementary action or reply."

  (define (complement-prefix branch actions replies)
    "Add complementary labels for ACTIONS and REPLIES."
    (let* ((statements (or (and=> (.prefix branch) ast:statement*) '()))
           (at (or (list-index (disjoin (is? <reply>)
                                        (is? <action>))
                               statements)
                   (length statements)))
           (prefix suffix (split-at statements at))
           (missing (if (null? suffix) '()
                        (lset-difference ast:equal?
                                         (append actions replies)
                                         (list (car suffix)))))
           (missing (map (compose
                          (cute clone <> #:parent model)
                          (cute make <constraint-branch> #:prefix <>)
                          (cute clone <> #:parent model)
                          (cute make <compound> #:elements <>) list)
                         missing))
           (compound (.prefix branch)))
      (let ((branches (.branches branch)))
        (cond
         ((not branches)
          branch)
         ((or (null? prefix) (null? suffix))
          (clone branch #:branches (complement-with branches actions replies)))
         (else
          (let* ((suffix-branch
                  (make <constraint-branch>
                    #:prefix (clone compound #:elements suffix)
                    #:branches (complement-with branches
                                                actions replies)))
                 (suffix-branch (clone suffix-branch #:parent model))
                 (branches (clone branches
                                  #:elements (cons suffix-branch missing)))
                 (branches (complement-with branches actions replies)))
            (clone branch
                   #:prefix (clone compound #:elements prefix)
                   #:branches branches)))))))

  (define (complement-with branches actions replies)
    "Transform (branches <constraint-branches>) into (branches
<constraint-branches>) by adding complementary labels."

    (define (label o)
      (and o (match (ast:statement* o)
               ((labels ..1) (car labels))
               (_ #f))))

    (let* ((process* branch* (partition (is? <constraint-process>)
                                        (ast:constraint-branch* branches)))
           (labels (filter-map (compose label .prefix) branch*))
           (missing (if (null? branch*) '()
                        (lset-difference ast:equal?
                                         (append actions replies) labels)))
           (missing (map
                     (compose (cute clone <> #:parent model)
                              (cute make <constraint-branch> #:prefix <>)
                              (cute clone <> #:parent model)
                              (cute make <compound> #:elements <>) list)
                     missing)))
      (let ((branch* (map (cute complement-prefix <> actions replies) branch*)))
        (clone branches #:elements (append process* branch* missing)))))

  (let* ((actions (map (compose (cute clone <> #:parent model)
                                (cute make <action> #:event.name <>) .name)
                       (ast:out-event* model)))
         (replies (map (compose
                        (cute clone <> #:parent model)
                        (cute make <reply> #:expression <>))
                       (append-map (cute ast:return-values <> (make <literal>))
                                   (ast:in-event* model)))))
    (let ((branches (.branches constraint)))
      (if (not branches) constraint
          (let* ((branches (complement-with branches actions replies))
                 (constraint (clone constraint #:branches branches)))
            constraint)))))


;;;
;;; Entry point.
;;;
(define (interface->constraint root model)
  "Entry-point for interface constraints."
  (let* ((transitions (interface->transitions root model))
         (transitions (add-interface-illegals model transitions))
         (transitions (add-missing-from transitions))
         (constraints (constraint-transitions->constraint transitions model))
         (constraints (map (cute add-missing-branches model <>) constraints)))
    constraints))
