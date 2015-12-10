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
DZN_FILES:=$(sort $(wildcard $(CDIR)*.dzn))
endif

ifneq ($(GOAL_LANGUAGES),)
LANGUAGES:=$(filter $(GOAL_LANGUAGES),$(LANGUAGES))
endif

LOCAL_GOAL_FILES:=$(GOAL_NAMES:%=$(CDIR)%.dzn)
ifneq ($(LOCAL_GOAL_FILES),)
DZN_FILES:=$(filter $(LOCAL_GOAL_FILES),$(DZN_FILES))
endif

DZN_FILES:=$(filter-out $(BROKEN:%=\%%),$(DZN_FILES))

$(info Languages: $(LANGUAGES))
$(foreach DZN_FILE,$(DZN_FILES),\
	$(foreach lang,$(LANGUAGES),\
		$(if $(filter-out $(BROKEN_$(lang):%=\%%),$(DZN_FILE)),\
			$(eval LOCAL_LANGUAGE:=$(lang))\
			$(eval LOCAL_DZN_FILES:=$(DZN_FILE))\
			$(eval include make/check.make))))

ifeq ($(PROJECT_P),)
ifneq ($(filter c++,$(LANGUAGES)),)
$(foreach lang,$(CODE_LANGUAGES) $(filter run,$(PSEUDO_LANGUAGES)),\
	$(foreach i,$(filter-out $(BROKEN_triangle:%=\%%) $(BROKEN_$(lang):%=\%%),$(DZN_FILES)),\
		$(eval LOCAL_LANGUAGE:=$(lang))\
		$(eval LOCAL_DZN_FILES:=$(i))\
		$(eval include make/common.make)\
		$(eval include make/triangle.make)\
		$(eval include make/reset.make)))
endif
endif
include make/reset.make
DZN_FILES:=
LANGUAGES:=
