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

include make/dezyne.make
include make/binary.make

ifeq ($(LOCAL_CODE2FDR),)
LOCAL_CODE2FDR:=bin/code2fdr
endif

define CODE.rule
code-$(LOCAL_TARGET)/$(notdir $(1)): CDIR:=$$(CDIR)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_CODE2FDR:=$$(LOCAL_CODE2FDR)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_NAME:=$$(LOCAL_NAME)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_OUT:=$$(LOCAL_OUT)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TARGET:=$$(LOCAL_TARGET)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TIMEOUT:=$$(LOCAL_TIMEOUT)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TRACE_FLUSH:=$$(LOCAL_TRACE_FLUSH)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TRACE_FILES:=$$(LOCAL_TRACE_FILES)
code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TRACE_LANGUAGE:=$$(LOCAL_TRACE_LANGUAGE)
code-$(LOCAL_TARGET)/$(notdir $(1)): $(LOCAL_OUT)/test $(LOCAL_TRACE_FILES)
	diff -uw $(i) <(cat $(i) | timeout $(LOCAL_TIMEOUT) $(LOCAL_TARGET) $(LOCAL_TRACE_FLUSH) |& $(LOCAL_CODE2FDR));
check-$(OUT)/$(LOCAL_NAME): code-$(LOCAL_TARGET)/$(notdir $(1))
code-$(OUT)/$(LOCAL_NAME): code-$(LOCAL_TARGET)/$(notdir $(1))
code-$(LOCAL_TARGET): code-$(LOCAL_TARGET)/$(notdir $(1))
code-$(OUT)/$(LOCAL_NAME): code-$(LOCAL_TARGET)/$(notdir $(1))
code: $(LOCAL_OUT)/test code-$(LOCAL_TARGET)/$(notdir $(1))
ifeq ($(1),$(firstword $(LOCAL_TRACE_FILES)))
ifeq ($(VERBOSE),debug)
$$(info target check-$(OUT)/$(LOCAL_NAME))
$$(info target code-$(OUT)/$(LOCAL_NAME))
$$(info target code-$(LOCAL_TARGET))
#$$(info target code-$(LOCAL_TARGET)/$(notdir $(1)))
endif
endif

update-code-$(LOCAL_TARGET)/$(notdir $(1)): CDIR:=$$(CDIR)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_NAME:=$$(LOCAL_NAME)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_OUT:=$$(LOCAL_OUT)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TIMEOUT:=$$(LOCAL_TIMEOUT)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TARGET:=$$(LOCAL_TARGET)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TRACE_FILES:=$$(LOCAL_TRACE_FILES)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TRACE_LANGUAGE:=$$(LOCAL_TRACE_LANGUAGE)
update-code-$(LOCAL_TARGET)/$(notdir $(1)): $(LOCAL_OUT)/test
	@true
update-$(OUT)/$(LOCAL_NAME): update-code-$(LOCAL_TARGET)/$(notdir $(1))
update-code-$(OUT)/$(LOCAL_NAME): update-code-$(LOCAL_TARGET)/$(notdir $(1))
update-code-$(LOCAL_TARGET): update-code-$(LOCAL_TARGET)/$(notdir $(1))
update-code: $(LOCAL_OUT)/test update-code-$(LOCAL_TARGET)/$(notdir $(1))
ifeq ($(1),$(firstword $(LOCAL_TRACE_FILES)))
ifeq ($(VERBOSE),debug)
$$(info target update-$(OUT)/$(LOCAL_NAME))
$$(info target update-code-$(OUT)/$(LOCAL_NAME))
$$(info target update-code-$(LOCAL_TARGET))
#$$(info target update-code-$(LOCAL_TARGET)/$(notdir $(1)))
endif
endif
endef

$(foreach i,$(LOCAL_TRACE_FILES),$(eval $(call CODE.rule,$(i))))

ifeq ($(LOCAL_TRACE_FILES)$($(LOCAL_NAME)_TRACE_WARNING),)
ifneq ($(LOCAL_NAME),)
$(LOCAL_NAME)_TRACE_WARNING:=done
$(warning code: skipping $(LOCAL_NAME): no $(CDIR)$(LOCAL_NAME).trace file found)
endif
endif

ifeq ($(HELP_CODE),)
check: code
update: update-code
help: help-code
define HELP_CODE
  code           run all code
  update-code    overwrite code baseline
endef
export HELP_CODE
help-code:
	@echo "$$HELP_CODE"
endif
