# Dezyne --- Dezyne command line tools
#
# Copyright © 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
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

DEZYNE_EXAMPLES =				\
 %D%/armor.dzn					\
 %D%/bottom_armor.dzn				\
 %D%/compliance-multiple-provides-fork.dzn	\
 %D%/component-if-illegal.dzn			\
 %D%/dzn.async.dzn				\
 %D%/defer.dzn					\
 %D%/defer-cancel.dzn				\
 %D%/foreign.cc					\
 %D%/foreign.hh					\
 %D%/hello_foreign.dzn				\
 %D%/hello-world.dzn				\
 %D%/ihello-bool.dzn				\
 %D%/ihello-world.dzn				\
 %D%/illegal-requires.dzn			\
 %D%/inevitable-optional.dzn			\
 %D%/inner-space.dzn				\
 %D%/ipermissive.dzn				\
 %D%/istrict.dzn				\
 %D%/iwatchdog.dzn				\
 %D%/join.dzn					\
 %D%/proxy.dzn					\
 %D%/remote-timer-proxy.dzn			\
 %D%/simple-state-machine.dzn			\
 %D%/some_component.dzn				\
 %D%/some_component.hh				\
 %D%/some_interface.dzn				\
 %D%/some_interface.hh				\
 %D%/some_system.dzn				\
 %D%/top_armor.dzn				\
 %D%/top-middle-bottom.dzn

EXTRA_DIST += $(DEZYNE_EXAMPLES)
