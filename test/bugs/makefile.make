# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

# provides_twice: external component, does not link...
# hide: variable shadowing!?
# iincomplete: does not parse...
# Comp, Reply: main generates different reply values per language
# dollar_escape: gaiag parse error due to incorrect escaping of dollar expression $sss;xxx$ (zoho6839)
# FDR void reply instead of valued reply (component ValuedReturn.dzn!ConstrainedAxis) (zoho6834)
# unguarded: shadowing: c++: x.in.move () instead of this->x.in.move() <--FIXED
# name_space: OM parser prints empty (root)
# inner_space: does not parse with OM-parser
# simple_space: does not generate namespaces in SCM output
include make/files.make
