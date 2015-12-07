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

define RUN.rule
TRACE:=$$(patsubst %.trace.0,trace.0,$(notdir $(1)))
TRACE:=$$(TRACE)
TOP:=$(LOCAL_NAME)-$(LOCAL_LANGUAGE)-$$(TRACE)
$$(TOP): CDIR:=$$(CDIR)
$$(TOP): LOCAL_NAME:=$$(LOCAL_NAME)
$$(TOP): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
$$(TOP): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
$$(TOP): LOCAL_TARGET:=$$(LOCAL_TARGET)
$$(TOP): LOCAL_SUT:=$$(LOCAL_SUT)
$$(TOP): LOCAL_TRACE_FILES:=$$(LOCAL_TRACE_FILES)
$$(TOP): $(1)
	diff -uw <(grep -v '[.]<flush>' $(1)) <($(DZN) run -m $(LOCAL_SUT) -t <(grep -v '<flush>' $(1)) $(LOCAL_DZN_TOP) | grep ^trace:| sed 's,^trace:,,' | tr ',' '\n')

$(LOCAL_NAME)-$(LOCAL_LANGUAGE): $$(TOP)
$(LOCAL_NAME)-check: $$(TOP)
$(LOCAL_LANGUAGE): $$(TOP)

ifeq ($(1),$(firstword $(LOCAL_TRACE_FILES)))
ifeq ($(filter list,$(MAKECMDGOALS)),list)
#$$(info )
$$(info $$()    $$(TOP))
$$(info $$()    $(LOCAL_NAME)-$(LOCAL_LANGUAGE))
$$(info $$()    $(LOCAL_NAME))
endif

endif
endef

$(foreach i,$(LOCAL_TRACE_FILES),$(eval $(call RUN.rule,$(i))))

$(LOCAL_TARGET):
	@echo $@

ifeq ($(HELP_RUN),)
check: run
help: help-run
define HELP_RUN
  run            run all traces
endef
export HELP_RUN
help-run:
	@echo "$$HELP_RUN"
endif
