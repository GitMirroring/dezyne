# Dezyne --- Dezyne command line tools
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

ifeq ($(LANGUAGES),)
LANGUAGES:=$(ALL_LANGUAGES)
endif

ifeq ($(DZN_FILES),)
DZN_FILES:=$(wildcard $(CDIR)*.dzn)
endif

ifneq ($(GOAL_LANGUAGES),)
LANGUAGES:=$(filter $(GOAL_LANGUAGES),$(LANGUAGES))
endif

ifeq ($(GOAL_NAMES),$(notdir $(CDIR:%/=%)))
LOCAL_GOAL_FILES:=$(CDIR)%.dzn
else
LOCAL_GOAL_FILES:=$(GOAL_NAMES:%=$(CDIR)%.dzn)
endif

ifneq ($(LOCAL_GOAL_FILES),)
DZN_FILES:=$(filter $(LOCAL_GOAL_FILES),$(DZN_FILES))
endif

ifneq ($(DZN_FILES),)
$(foreach lang,$(LANGUAGES),\
	$(eval LOCAL_LANGUAGE:=$(lang))\
	$(eval LOCAL_SUT:=$(SUT))\
	$(eval LOCAL_DZN_FILES:=$(DZN_FILES))\
	$(eval include make/check.make))
endif
include make/reset.make
DZN_FILES:=
LANGUAGES:=
SUT:=
