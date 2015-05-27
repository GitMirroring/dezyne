;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014, 2015 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2014, 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
;;;
;;; Gaiag is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Gaiag is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

-- drop_one_local: V => V
drop_one_local_((M', (L', L0'))) = (M', L')

illegal_(P',V') = illegal -> STOP
-- send_: (c: channel, e:event) => (P,V)->Proc
send_(c',e')(P', V') = c'!e' -> P'(V')
-- recv_: (c: channel, e:event) => (P,V)->Proc
recv_(c',e')(P', V') =  c'?r' -> returnvalue_(\V' @ r')(P', V')
-- skip_: () => (P,V)->Proc
skip_(P', V') = P'(V')
-- call_: (B': (P,V)->Proc) => (P,V)->Proc
call_(B')(P', (M1', L1')) = B'(\(M2',V2')@ P'((M2',L1')), (M1', <>))
-- call_args_: (B': (P,V)->Proc, F': V'->V') => (P,V)->Proc
call_args_(B', F')(P', (M1', L1')) = B'(\(M2',V2')@ P'((M2',L1')), (M1', (<>, F'((M1',L1')))))
-- assign_: (F': V -> V) => (P,V) -> Proc
assign_(F')(P', V') = P'(F'(V'))
-- assign_int_: (F': V -> V) => (P,V) -> Proc
assign_int_(F',B')(P', V') = let b' = B'(V') within not b' & range_error -> STOP [] b' & P'(F'(V'))
-- assign_int_: (F': V -> V, B': V -> bool) => (P,V) -> Proc
assign_int_(F',B')(P', V') = let b' = B'(V') within not b' & illegal -> STOP [] b' & P'(F'(V'))
-- assign_active_: C':(P,V)->Proc, A: (V,val)->V) => (P,V)->Proc
assign_active_(C', A')(P', V') = C'(\ ((M', r'),L') @ P'(A'((M',L'),r')), V')
-- assign_int_active_: C':(P,V)->Proc, A: (V,val)->V, B': V -> bool => (P,V)->Proc
-- Paul, HELP! assign_int_active_(C',A',b')(P', V') = C'(\ ((M', r'),L') @ not b' & range_error -> STOP [] b' & P'(A'((M',L'),r')), V')
-- assign_int_active_(C',A',b')(P', V') = assign_active_(C', A')
-- assign_int_active_(C',A',b')(P', V') = (\ (C', A', b') @ assign_active_(C', A'))
assign_int_active_(C',A',b')(P', V') = C'(\ ((M', r'),L') @ P'(A'((M',L'),r')), V')

reply_(C', F')(P', V') = C'.F'(V') -> P'(V')
-- returnvalue_: (F: V->val) => (P,V)->Proc
returnvalue_(F')(P', (M',L')) = P'(((M',  F'((M', L'))), L'))
-- the_end_: P => V->Proc
the_end_(P', V') = transition_end -> P'(V')

-- semi_: (S1,S2: (P,V)->Proc) => (P,V) -> Proc
semi_(S1',S2')(P', V') = S1'(\V'' @ S2'(P', V''),V')
-- ifthenelse: (F': V->val,  S1,S2: (P,V)->Proc) => (P,V) -> Proc
ifthenelse_(F',S1',S2')(P', V') =  if F'(V') then S1'(P', V') else S2'(P', V')
-- context_: (F': V->val, S': (P,V)->Proc) => (P,V)->Proc
context_(F', S')(P', (M', L')) = S'((\ (M',L2') @ P'((M',L'))), (M', (L', F'((M', L')))))
-- context_int_: (F': V->val, B: bool, S': (P,V)->Proc) => (P,V)->Proc
context_int_(F', B', S')(P', (M', L')) = S'((\ (M',L2') @ let b' = B'((M',L2')) within not b' & range_error -> STOP [] b' & P'((M',L'))), (M', (L', F'((M', L')))))
-- context_active_: (C':(P,V)->Proc, S: (P,V)->Proc) => (P,V)->Proc
context_active_(C', S')(P', V') = C'(\((M', r'),L') @ S'(\V2' @ P'(drop_one_local_(V2')), (M', (L',r'))), V')
-- context_int_active_: (C':(P,V)->Proc, B': bool, S: (P,V)->Proc) => (P,V)->Proc
-- Paul, HELP! context_int_active_(C', B', S')(P', V') = C'(\((M', r'),L') @ let b' = B'((M',r')) within not b' & range_error -> STOP [] b' & S'(\V2' @ P'(drop_one_local_(V2')), (M', (L',r'))), V')
--context_int_active_(C', B', S')(P', V') = (\ (C', B', S') @ context_active_(C', S'))
context_int_active_(C', B', S')(P', V') = C'(\((M', r'),L') @ S'(\V2' @ P'(drop_one_local_(V2')), (M', (L',r'))), V')

nametype bool = {false, true}   
                
channel illegal
channel range_error
channel transition_begin, transition_end

COMPLETE'(A') = []x:A' @ x-> (COMPLETE'(A') |~| illegal->STOP)

#(->string
  (map (lambda (x) (list (.name x) " = {" ((compose .from .range) x) ".." ((compose .to .range) x) "}\n"))
      (filter (is? <int>) (om:types model))))
            
datatype event_enumeration_alphabet = #
(pipe-join
  (delete-duplicates
   (sort
    (append
     (interface-events model identity)
     (enum-values model)
     (return-values model)
     (list 'the_end' 'modeling))
    symbol<)))

#(stderr "types: ~a\n" (enum-types model))
#(map
 (lambda (e)
   (list "nametype " (enum-scope model e) " = {" ((->join ", ") (typed-elements e)) "}\n"))
(filter (is? <enum>) (enum-types model)))
-- end of combinators
