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

parse-$(LOCAL_TARGET): CDIR:=$(CDIR)
parse-$(LOCAL_TARGET): LOCAL_NAME:=$(LOCAL_NAME)
parse-$(LOCAL_TARGET): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
parse-$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
parse-$(LOCAL_TARGET): LOCAL_TARGET:=$(LOCAL_TARGET)
parse-$(LOCAL_TARGET): LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
parse-$(LOCAL_TARGET): LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
parse-$(LOCAL_TARGET): #$(LOCAL_TARGET)
	diff -uw $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE) <($(DZN) parse $(LOCAL_DZN_TOP) 2>&1 && echo 'parse: no errors found')
check-$(OUT)/$(LOCAL_NAME): parse-$(LOCAL_TARGET)
parse-$(OUT)/$(LOCAL_NAME): parse-$(LOCAL_TARGET)
parse: parse-$(LOCAL_TARGET)
ifeq ($(VERBOSE),debug)
$(info target parse-$(OUT)/$(LOCAL_NAME))
$(info target parse-$(LOCAL_TARGET))
endif

update-parse-$(LOCAL_TARGET): CDIR:=$(CDIR)
update-parse-$(LOCAL_TARGET): LOCAL_NAME:=$(LOCAL_NAME)
update-parse-$(LOCAL_TARGET): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
update-parse-$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
update-parse-$(LOCAL_TARGET): LOCAL_TARGET:=$(LOCAL_TARGET)
update-parse-$(LOCAL_TARGET): LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
update-parse-$(LOCAL_TARGET): LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
update-parse-$(LOCAL_TARGET): #$(LOCAL_TARGET)
	mkdir -p $(CDIR)baseline/$(LOCAL_NAME)
	-($(DZN) parse $(LOCAL_DZN_TOP) && echo 'parse: no errors found') > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE) 2>&1

update-parse-$(OUT)/$(LOCAL_NAME): update-parse-$(LOCAL_TARGET)
update-parse: update-parse-$(LOCAL_TARGET)
ifeq ($(VERBOSE),debug)
$(info target update-parse-$(OUT)/$(LOCAL_NAME))
$(info target update-parse-$(LOCAL_TARGET))
endif

ifeq ($(HELP_PARSE),)
check: parse
update: update-parse
help: help-parse
define HELP_PARSE
  parse          run all parse
  update-parse   overwrite parse baseline
endef
export HELP_PARSE
help-parse:
	@echo "$$HELP_PARSE"
endif
