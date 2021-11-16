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

DEZYNE_EXAMPLES =				\
 %D%/ca.dzn					\
 %D%/compliance-multiple-provides-fork.dzn	\
 %D%/component-if-illegal.dzn			\
 %D%/dzn.async.dzn				\
 %D%/hello-world.dzn				\
 %D%/ihello-bool.dzn				\
 %D%/ihello-world.dzn				\
 %D%/illegal-requires.dzn			\
 %D%/inner-space.dzn				\
 %D%/inevitable-optional			\
 %D%/remote-timer-proxy.dzn			\
 %D%/simple-state-machine.dzn			\
 %D%/top-middle-bottom.dzn

EXTRA_DIST += $(DEZYNE_EXAMPLES)
