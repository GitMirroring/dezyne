# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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
BROKEN:=\
 regression/iincomplete.dzn\
 regression/externaltypesbroken.dzn\
 regression/provides_twice.dzn\
 regression/dollar_escape.dzn\
 regression/ValuedReturn.dzn\
 regression/unguarded.dzn\
 regression/hide.dzn\
 regression/BrokenComp.dzn\
 regression/inner_space.dzn\
 regression/name_space.dzn\
 regression/simple_space.dzn\

# error: Reply5: variable s is already defined in method i_done()
BROKEN_cs:=\
 regression/DataVariables.dzn\
 regression/List.dzn\
 regression/Reply5.dzn\
 regression/SynchronousLivelock.dzn\

# c++ is main language, can never be broken

BROKEN_goops:=\
 regression/DataVariables.dzn\
 regression/QTriggerModeling.dzn\
 regression/SynchronousLivelock.dzn\
 regression/SynchronousOut.dzn\

# error: Reply5: variable s is already defined in method i_done()
# error: R: non-static type variable R cannot be referenced from a static context
BROKEN_java:=\
 regression/DataVariables.dzn\
 regression/List.dzn\
 regression/Reply5.dzn\
 regression/R.dzn\
 regression/SynchronousLivelock.dzn\

BROKEN_java7:=$(BROKEN_java)

BROKEN_javascript:=\
 regression/DataVariables.dzn\


BROKEN_python:=\
 regression/DataVariables.dzn\
 regression/SynchronousLivelock.dzn\

BROKEN_run:=\

# TypeError: Cannot call method 'replace' of undefined
BROKEN_trace:=\
 regression/Extern.dzn\

BROKEN_verify:=

DZN_FILES:=$(wildcard $(CDIR)*.dzn)
DZN_FILES:=$(filter-out $(BROKEN),$(DZN_FILES))
LANGUAGES:=$(ALL_LANGUAGES)
include make/files.make

##DZN_FILES:=$(CDIR)Alarm.dzn $(CDIR)Comp.dzn $(CDIR)Reply.dzn $(CDIR)Handle.dzn $(CDIR)SynchronousOut.dzn
DZN_FILES:=$(CDIR)Handle.dzn #$(CDIR)Comp.dzn $(CDIR)Reply.dzn
$(foreach lang,$(CODE_LANGUAGES) $(filter run,$(PSEUDO_LANGUAGES)),\
	$(foreach i,$(filter-out $(BROKEN_$(lang)),$(DZN_FILES)),\
		$(eval LOCAL_TRACE_ILLEGAL:=--illegal)\
		$(eval LOCAL_LANGUAGE:=$(lang))\
		$(eval LOCAL_DZN_FILES:=$(i))\
		$(eval include make/common.make)\
		$(eval include make/triangle.make)\
		$(eval include make/reset.make)))
DZN_FILES:=
