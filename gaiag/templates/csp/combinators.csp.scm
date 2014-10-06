;;; Gaiag --- Guile in Asd In Asd in Guile.
;;;
;;; This file is part of Gaiag.
;;;
;;; Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2014 Paul Hoogendijk <paul.hoogendijk@verum.com>
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
-- skip_: () => (P,V)->Proc
skip_(P', V') = P'(V')

recv_(c',e')(P', V') =  c'?r' -> returnvalue_(\V' @ r')(P', V')

-- sendrecv_: (c: channel, e:event) => (P,V)->Proc
sendrecv_(c',e')(P', V') =  c'!e'  -> c'?r' -> returnvalue_(\V' @ r')(P', V')
-- callvoid_: (B': (P,V)->Proc) => (P,V)->Proc
callvoid_(B')(P', V') = B'(P', V')
-- assign_: (F': V -> V) => (P,V) -> Proc
assign_(F')(P', V') = P'(F'(V'))
-- assign_active_: C':(P,V)->Proc, A: (V,val)->V) => (P,V)->Proc
assign_active_(C', A')(P', V') = C'(\((M', r'),L') @ P'(A'((M',L'),r')), V')
reply_(C', F')(P', V') = C'.F'(V') -> P'(V')
-- returnvalue_: (F: V->val) => (P,V)->Proc
returnvalue_(F')(P', (M',L')) = P'(((M',  F'((M', L'))), L'))
-- the_end_: P => V->Proc
the_end_(P', V') = transition_end -> P'(V')

-- semi_: (S1,S2: (P,V)->Proc) => (P,V) -> Proc
semi_(S1',S2')(P', V') = S1'(\V'' @ S2'(P', V''),V')
-- ifthenelse: (E': val,  S1,S2: (P,V)->Proc) => (P,V) -> Proc
ifthenelse_(E',S1',S2')(P', V') =  if E' then S1'(P', V') else S2'(P', V')
-- context_: (F': V->val, S': (P,V)->Proc) => (P,V)->Proc
-- context_(F', S')(P')((M', L')) = S'((\V2' @ P'(drop_one_local_(V2'))), (M', (L', F'((M', L')))))
-- context_(v', S')(P', (M', L')) = S'((\(M',L2') @ P'((M',L'))), (M', (L', v')))
context_(F', S')(P', (M', L')) = S'((\ (M',L2') @ P'((M',L'))), (M', (L', F'((M', L')))))
-- context_active_: (C':(P,V)->Proc, S: (P,V)->Proc) => (P,V)->Proc
context_active_(C', S')(P', V') = C'(\((M', r'),L') @ S'(\V2' @ P'(drop_one_local_(V2')), (M', (L',r'))), V')
context_func_(S')(P', (M1', L1')) = S'((\(M2',L2') @ P'((M2',L1'))), (M1', <>))
context_func_args_(v', S')(P', (M1', L1')) = S'((\(M2',L2') @ P'((M2',L1'))), (M1', (<>, v')))

members_((M',L')) = (M',<>)

channel illegal
channel transition_begin, transition_end

datatype event_enumeration_alphabet = #
(pipe-join
  (delete-duplicates
   (sort
    (append
     (interface-events model)
     (enum-values model)
     (return-values model))
    symbol<)))
