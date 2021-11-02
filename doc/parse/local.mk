# Dezyne --- Dezyne command line tools
#
# Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
#
# Commentary:
#
# Code:

EXTRA_DIST += %D%/README

DEZYNE_PARSE_EXAMPLES =				\
 %D%/action-discard-value.dzn			\
 %D%/action-in-complex-expression.dzn		\
 %D%/action-in-member-definition.dzn		\
 %D%/action-outside-on.dzn			\
 %D%/assign-outside-on.dzn			\
 %D%/binding-cycle.dzn				\
 %D%/binding-cycle-elaborate.dzn		\
 %D%/binding-mismatch-direction.dzn		\
 %D%/binding-mismatch-external.dzn		\
 %D%/binding-two-wildcards.dzn			\
 %D%/binding-wildcard-requires.dzn		\
 %D%/blocking-in-interface.dzn			\
 %D%/call-discard-value.dzn			\
 %D%/call-in-complex-expression.dzn		\
 %D%/call-in-member-definition.dzn		\
 %D%/component-action-used-as-trigger.dzn	\
 %D%/component-provides-without-trigger.dzn	\
 %D%/component-requires-without-trigger.dzn	\
 %D%/component-trigger-used-as-action.dzn	\
 %D%/component-without-provides.dzn		\
 %D%/event-with-bool-parameter.dzn		\
 %D%/function-missing-return.dzn		\
 %D%/function-not-tail-recursive.dzn		\
 %D%/function-reply-needs-provides-port.dzn	\
 %D%/imperative-illegal.dzn			\
 %D%/injected-with-out-event.dzn		\
 %D%/inout-parameter-on-out-event.dzn		\
 %D%/instance-port-not-bound.dzn		\
 %D%/interface-action-used-as-trigger.dzn	\
 %D%/interface-function-illegal.dzn		\
 %D%/interface-if-illegal.dzn			\
 %D%/interface-trigger-used-as-action.dzn	\
 %D%/interface-without-behavior.dzn		\
 %D%/interface-without-event.dzn		\
 %D%/mixing-declarative.dzn			\
 %D%/mixing-imperative.dzn			\
 %D%/nested-blocking.dzn			\
 %D%/nested-on.dzn				\
 %D%/out-binding-reversed.dzn			\
 %D%/out-parameter-on-out-event.dzn		\
 %D%/otherwise-without-guard.dzn		\
 %D%/port-not-bound.dzn				\
 %D%/port-bound-twice.dzn			\
 %D%/recursive-system.dzn			\
 %D%/requires-port-reply.dzn			\
 %D%/requires-reply-needs-provides-port.dzn	\
 %D%/return-outside-function.dzn		\
 %D%/second-otherwise.dzn			\
 %D%/valued-out-event.dzn

EXTRA_DIST += $(DEZYNE_PARSE_EXAMPLES)
dezyne_TEXINFOS += $(DEZYNE_PARSE_EXAMPLES:%.dzn=%.texi)
