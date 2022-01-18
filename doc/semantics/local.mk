# Dezyne --- Dezyne command line tools
#
# Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2022 Rutger van Beusekom <rutger@dezyne.org>
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

DOCUMENTATION_SEMANTICS =				\
 %D%/async_multiple_provides.dzn			\
 %D%/block.dzn						\
 %D%/blocking_multiple_provides.dzn			\
 %D%/collateral.dzn					\
 %D%/collateral_multiple_provides.dzn			\
 %D%/direct_in.dzn					\
 %D%/direct_multiple_out1.dzn				\
 %D%/direct_multiple_out2.dzn				\
 %D%/direct_out.dzn					\
 %D%/external_multiple_out1.dzn				\
 %D%/external_multiple_out2.dzn				\
 %D%/external_multiple_out3.dzn				\
 %D%/ihello.dzn						\
 %D%/indirect_blocking_multiple_external_out.dzn	\
 %D%/indirect_blocking_out.dzn				\
 %D%/indirect_in.dzn					\
 %D%/indirect_multiple_out1.dzn				\
 %D%/indirect_multiple_out2.dzn				\
 %D%/indirect_multiple_out3.dzn				\
 %D%/indirect_out.dzn					\
 %D%/iworld.dzn						\
 %D%/multiple_provides.dzn				\
 %D%/mux.dzn						\
 %D%/proxy.dzn

EXTRA_DIST += $(DOCUMENTATION_SEMANTICS)
