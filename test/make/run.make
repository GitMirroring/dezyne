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
run-$(LOCAL_TARGET)/$(notdir $(1)): CDIR:=$$(CDIR)
run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_NAME:=$$(LOCAL_NAME)
run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TARGET:=$$(LOCAL_TARGET)
run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_SUT:=$$(LOCAL_SUT)
run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TRACE_FILES:=$$(LOCAL_TRACE_FILES)
run-$(LOCAL_TARGET)/$(notdir $(1)): $(1)
	diff -uw $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(notdir $(1)) <($(DZN) --verbose run -m $(LOCAL_SUT) -t $(1) $(LOCAL_DZN_TOP) | grep '^trace:' | sed s,trace:,, | tr ',' '\n' | grep -Ev '^ *$$$$')
check-$(OUT)/$(LOCAL_NAME): run-$(LOCAL_TARGET)/$(notdir $(1))
run-$(OUT)/$(LOCAL_NAME): run-$(LOCAL_TARGET)/$(notdir $(1))
run-$(LOCAL_TARGET): run-$(LOCAL_TARGET)/$(notdir $(1))
run: run-$(LOCAL_TARGET)/$(notdir $(1))
ifeq ($(VERBOSE),debug)
$$(info target check-$(OUT)/$(LOCAL_NAME))
$$(info target run-$(OUT)/$(LOCAL_NAME))
$$(info target run-$(LOCAL_TARGET))
$$(info target run-$(LOCAL_TARGET)/$(notdir $(1)))
endif

update-run-$(LOCAL_TARGET)/$(notdir $(1)): CDIR:=$$(CDIR)
update-run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_NAME:=$$(LOCAL_NAME)
update-run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
update-run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
update-run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TARGET:=$$(LOCAL_TARGET)
update-run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_SUT:=$$(LOCAL_SUT)
update-run-$(LOCAL_TARGET)/$(notdir $(1)): LOCAL_TRACE_FILES:=$$(LOCAL_TRACE_FILES)
update-run-$(LOCAL_TARGET)/$(notdir $(1)): $(1)
	mkdir -p $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
	$(DZN) --verbose run -m $(LOCAL_SUT) -t $(1) $(LOCAL_DZN_TOP) | grep '^trace:' | sed s,trace:,, | tr ',' '\n' | (grep -Ev '^ *$$$$'||:) > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(notdir $(1))
update-$(OUT)/$(LOCAL_NAME): update-run-$(LOCAL_TARGET)/$(notdir $(1))
update-run-$(OUT)/$(LOCAL_NAME): update-run-$(LOCAL_TARGET)/$(notdir $(1))
update-run-$(LOCAL_TARGET): update-run-$(LOCAL_TARGET)/$(notdir $(1))
update-run: update-run-$(LOCAL_TARGET)/$(notdir $(1))
ifeq ($(VERBOSE),debug)
$$(info target update-$(OUT)/$(LOCAL_NAME))
$$(info target update-run-$(OUT)/$(LOCAL_NAME))
$$(info target update-run-$(LOCAL_TARGET))
$$(info target update-run-$(LOCAL_TARGET)/$(notdir $(1)))
endif
endef

$(foreach i,$(LOCAL_TRACE_FILES),$(eval $(call RUN.rule,$(i))))

$(LOCAL_TARGET):
	@echo $@

ifeq ($(HELP_RUN),)
check: run
update: update-run
help: help-run
define HELP_RUN
  run            run all traces
  update-run     overwrite run baseline
endef
export HELP_RUN
help-run:
	@echo "$$HELP_RUN"
endif
