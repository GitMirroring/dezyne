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

TOP:=$(LOCAL_NAME)-$(LOCAL_LANGUAGE)
$(TOP): CDIR:=$(CDIR)
$(TOP): LOCAL_BASE:=$(LOCAL_BASE)
$(TOP): LOCAL_NAME:=$(LOCAL_NAME)
$(TOP): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
$(TOP): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(TOP): LOCAL_TARGET:=$(LOCAL_TARGET)
$(TOP): LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
$(TOP): LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
$(TOP): #$(LOCAL_TARGET)
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-state.dzn <($(DZN) table --form=state -o - $(LOCAL_DZN_TOP))
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-event.dzn <($(DZN) table --form=event -o - $(LOCAL_DZN_TOP))
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-state.html <($(DZN) --html table --form=state -o - $(LOCAL_DZN_TOP) | w3m -dump -T text/html)
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-event.html <($(DZN) --html table --form=event -o - $(LOCAL_DZN_TOP) | w3m -dump -T text/html)

$(LOCAL_NAME)-check: $(TOP)
$(LOCAL_LANGUAGE): $(TOP)

ifeq ($(filter list,$(MAKECMDGOALS)),list)
$(info $()    $(LOCAL_NAME)-$(LOCAL_LANGUAGE))
$(info $()    $(LOCAL_NAME))
endif

$(TOP)-update: CDIR:=$(CDIR)
$(TOP)-update: LOCAL_BASE:=$(LOCAL_BASE)
$(TOP)-update: LOCAL_NAME:=$(LOCAL_NAME)
$(TOP)-update: LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
$(TOP)-update: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(TOP)-update: LOCAL_TARGET:=$(LOCAL_TARGET)
$(TOP)-update: LOCAL_TRACE_FILES:=$(LOCAL_TRACE_FILES)
$(TOP)-update: LOCAL_TRACE_LANGUAGE:=$(LOCAL_TRACE_LANGUAGE)
$(TOP)-update: #$(LOCAL_TARGET)
	mkdir -p $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
	$(DZN) table --form=state -o - $(LOCAL_DZN_TOP) > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-state.dzn
	$(DZN) table --form=event -o - $(LOCAL_DZN_TOP) > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-event.dzn
	$(DZN) --html table --form=state -o - $(LOCAL_DZN_TOP) | w3m -dump -T text/html > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-state.html
	$(DZN) --html table --form=event -o - $(LOCAL_DZN_TOP) | w3m -dump -T text/html > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(LOCAL_BASE)-event.html

$(LOCAL_NAME)-update: $(TOP)-update
$(LOCAL_LANGUAGE)-update: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_LANGUAGE)-update: $(TOP)-update

ifeq ($(filter list,$(MAKECMDGOALS)),list)
$(info $()    $(TOP)-update)
$(info $()    $(LOCAL_NAME)-update)
endif

ifeq ($(HELP_TABLE),)
check: table
update: table-update
help: help-table
define HELP_TABLE
  table          run all table
  table-update   overwrite table baseline
endef
export HELP_TABLE
help-table:
	@echo "$$HELP_TABLE"
endif
