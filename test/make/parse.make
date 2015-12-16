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

TOP:=$(LOCAL_NAME)-$(LOCAL_LANGUAGE)

$(TOP): CDIR:=$(CDIR)
$(TOP): LOCAL_NAME:=$(LOCAL_NAME)
$(TOP): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
$(TOP): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(TOP): LOCAL_TARGET:=$(LOCAL_TARGET)
$(TOP): LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
$(TOP): LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
$(TOP): #$(LOCAL_TARGET)
	diff -uw $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE) <($(DZN) -v parse $(LOCAL_DZN_TOP) 2>&1)

$(LOCAL_NAME): $(TOP)
$(LOCAL_NAME)-check: $(TOP)
$(LOCAL_LANGUAGE): $(TOP)

ifeq ($(filter list,$(MAKECMDGOALS)),list)
$(info $()    $(TOP))
$(info $()    $(LOCAL_NAME)-$(LOCAL_LANGUAGE))
$(info $()    $(LOCAL_NAME))
endif


$(TOP)-update: CDIR:=$(CDIR)
$(TOP)-update: LOCAL_NAME:=$(LOCAL_NAME)
$(TOP)-update: LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
$(TOP)-update: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(TOP)-update: LOCAL_TARGET:=$(LOCAL_TARGET)
$(TOP)-update: LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
$(TOP)-update: LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
$(TOP)-update: #$(LOCAL_TARGET)
	mkdir -p $(CDIR)baseline/$(LOCAL_NAME)
	-$(DZN) -v parse $(LOCAL_DZN_TOP) > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE) 2>&1

$(LOCAL_NAME)-update: $(TOP)-update
$(LOCAL_LANGUAGE)-update: $(TOP)-update

ifeq ($(filter list,$(MAKECMDGOALS)),list)
$(info $()    $(TOP)-update)
$(info $()    $(LOCAL_NAME)-$(LOCAL_LANGUAGE)-update)
$(info $()    $(LOCAL_NAME)-update)
endif

ifeq ($(HELP_PARSE),)
all: parse
update: parse-update
help: help-parse
define HELP_PARSE
  parse          run all parse
  parse-update   overwrite parse baseline
endef
export HELP_PARSE
help-parse:
	@echo "$$HELP_PARSE"
endif
