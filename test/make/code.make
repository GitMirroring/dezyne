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
TRACE:=$$(patsubst %.trace.0,trace.0,$(notdir $(1)))
TRACE:=$$(TRACE)
TOP:=$(LOCAL_NAME)-$(LOCAL_LANGUAGE)-$$(TRACE)
$$(TOP): CDIR:=$$(CDIR)
$$(TOP): LOCAL_CODE2FDR:=$$(LOCAL_CODE2FDR)
$$(TOP): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
$$(TOP): LOCAL_NAME:=$$(LOCAL_NAME)
$$(TOP): LOCAL_OUT:=$$(LOCAL_OUT)
$$(TOP): LOCAL_TARGET:=$$(LOCAL_TARGET)
$$(TOP): LOCAL_TIMEOUT:=$$(LOCAL_TIMEOUT)
$$(TOP): LOCAL_TRACE_FLUSH:=$$(LOCAL_TRACE_FLUSH)
$$(TOP): LOCAL_TRACE_FILES:=$$(LOCAL_TRACE_FILES)
$$(TOP): LOCAL_TRACE_LANGUAGE:=$$(LOCAL_TRACE_LANGUAGE)
$$(TOP): $(LOCAL_OUT)/test $(LOCAL_TRACE_FILES)
	diff -uw $(i) <(cat $(i) | timeout $(LOCAL_TIMEOUT) $(LOCAL_TARGET) $(LOCAL_TRACE_FLUSH) |& $(LOCAL_CODE2FDR));

$(LOCAL_NAME)-$(LOCAL_LANGUAGE): $$(TOP)
$(LOCAL_NAME)-code: $$(TOP)
$(LOCAL_NAME): $$(TOP)
$(LOCAL_NAME)-check: $$(TOP)
$(LOCAL_LANGUAGE): $$(TOP)

code: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
code: $(LOCAL_LANGUAGE)

ifeq ($(1),$(firstword $(LOCAL_TRACE_FILES)))
ifeq ($(filter list,$(MAKECMDGOALS)),list)
$$(info $$()    $$(TOP))
$$(info $$()    $(LOCAL_NAME)-$(LOCAL_LANGUAGE))
$$(info $$()    $(LOCAL_NAME)-code)
$$(info $$()    $(LOCAL_NAME))
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
all: code
help: help-code
define HELP_CODE
  code           run all code
endef
export HELP_CODE
help-code:
	@echo "$$HELP_CODE"
endif
