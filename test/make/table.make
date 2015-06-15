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

LOCAL_TARGET:=$(LOCAL_OUT)/$(LOCAL_BASE)

table-$(LOCAL_TARGET): CDIR:=$(CDIR)
table-$(LOCAL_TARGET): LOCAL_BASE:=$(LOCAL_BASE)
table-$(LOCAL_TARGET): LOCAL_NAME:=$(LOCAL_NAME)
table-$(LOCAL_TARGET): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
table-$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
table-$(LOCAL_TARGET): LOCAL_TARGET:=$(LOCAL_TARGET)
table-$(LOCAL_TARGET): LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
table-$(LOCAL_TARGET): LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
table-$(LOCAL_TARGET): #$(LOCAL_TARGET)
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-state.dzn <($(DZN) table --form=state -o - $(LOCAL_DZN_TOP) 2>&1)
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-event.dzn <($(DZN) table --form=event -o - $(LOCAL_DZN_TOP) 2>&1)
check-$(OUT)/$(LOCAL_NAME): table-$(LOCAL_TARGET)
table-$(OUT)/$(LOCAL_NAME): table-$(LOCAL_TARGET)
table: table-$(LOCAL_TARGET)
ifeq ($(VERBOSE),debug)
$(info target table-$(OUT)/$(LOCAL_NAME))
$(info target table-$(LOCAL_TARGET))
endif

update-table-$(LOCAL_TARGET): CDIR:=$(CDIR)
update-table-$(LOCAL_TARGET): LOCAL_BASE:=$(LOCAL_BASE)
update-table-$(LOCAL_TARGET): LOCAL_NAME:=$(LOCAL_NAME)
update-table-$(LOCAL_TARGET): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
update-table-$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
update-table-$(LOCAL_TARGET): LOCAL_TARGET:=$(LOCAL_TARGET)
update-table-$(LOCAL_TARGET): LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
update-table-$(LOCAL_TARGET): LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
update-table-$(LOCAL_TARGET): #$(LOCAL_TARGET)
	mkdir -p $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
	-$(DZN) table --form=state -o - $(LOCAL_DZN_TOP) 2> $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-state.dzn 1>&2
	-$(DZN) table --form=event -o - $(LOCAL_DZN_TOP) 2> $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-event.dzn 1>&2
update-$(OUT)/$(LOCAL_NAME): update-table-$(LOCAL_TARGET)
update-table-$(OUT)/$(LOCAL_NAME): update-table-$(LOCAL_TARGET)
update-table: update-table-$(LOCAL_TARGET)
ifeq ($(VERBOSE),debug)
$(info target update-table-$(OUT)/$(LOCAL_NAME))
$(info target update-table-$(LOCAL_TARGET))
endif

ifeq ($(HELP_TABLE),)
check: table
update: update-table
help: help-table
define HELP_TABLE
  table          run all table
  update-table   overwrite table baseline
endef
export HELP_TABLE
help-table:
	@echo "$$HELP_TABLE"
endif
