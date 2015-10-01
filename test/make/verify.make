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

define VERIFY.rule
verify-$(LOCAL_TARGET)/$(1): CDIR:=$$(CDIR)
verify-$(LOCAL_TARGET)/$(1): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
verify-$(LOCAL_TARGET)/$(1): LOCAL_NAME:=$$(LOCAL_NAME)
verify-$(LOCAL_TARGET)/$(1): LOCAL_OUT:=$$(LOCAL_OUT)
verify-$(LOCAL_TARGET)/$(1): LOCAL_TARGET:=$$(LOCAL_TARGET)
verify-$(LOCAL_TARGET)/$(1): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
verify-$(LOCAL_TARGET)/$(1):
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(1) <($(DZN) --verbose verify --all -m $(1) $(LOCAL_DZN_TOP) | make/reorder)
check-$(OUT)/$(LOCAL_NAME): verify-$(LOCAL_TARGET)/$(1)
verify-$(OUT)/$(LOCAL_NAME): verify-$(LOCAL_TARGET)/$(1)
verify-$(LOCAL_TARGET): verify-$(LOCAL_TARGET)/$(1)
verify: verify-$(LOCAL_TARGET)/$(1)
ifeq ($(VERBOSE),debug)
$$(info target check-$(OUT)/$(LOCAL_NAME))
$$(info target verify-$(OUT)/$(LOCAL_NAME))
$$(info target verify-$(LOCAL_TARGET))
$$(info target verify-$(LOCAL_TARGET)/$(1))
endif

update-verify-$(LOCAL_TARGET)/$(1): CDIR:=$$(CDIR)
update-verify-$(LOCAL_TARGET)/$(1): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
update-verify-$(LOCAL_TARGET)/$(1): LOCAL_NAME:=$$(LOCAL_NAME)
update-verify-$(LOCAL_TARGET)/$(1): LOCAL_OUT:=$$(LOCAL_OUT)
update-verify-$(LOCAL_TARGET)/$(1): LOCAL_TARGET:=$$(LOCAL_TARGET)
update-verify-$(LOCAL_TARGET)/$(1): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
update-verify-$(LOCAL_TARGET)/$(1):
	@mkdir -p $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
	$(DZN) --verbose verify --all -m $(1) $(LOCAL_DZN_TOP) | make/reorder > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(1)
update-$(OUT)/$(LOCAL_NAME): update-verify-$(LOCAL_TARGET)/$(1)
update-verify-$(OUT)/$(LOCAL_NAME): update-verify-$(LOCAL_TARGET)/$(1)
update-verify-$(LOCAL_TARGET): update-verify-$(LOCAL_TARGET)/$(1)
update-verify: update-verify-$(LOCAL_TARGET)/$(1)
ifeq ($(VERBOSE),debug)
$$(info target update-$(OUT)/$(LOCAL_NAME))
$$(info target update-verify-$(OUT)/$(LOCAL_NAME))
$$(info target update-verify-$(LOCAL_TARGET))
$$(info target update-verify-$(LOCAL_TARGET)/$(1))
endif
endef

$(foreach i,$(LOCAL_MODELS),$(eval $(call VERIFY.rule,$(i))))

$(LOCAL_TARGET):
	@echo $@

ifeq ($(HELP_VERIFY),)
check: verify
update: update-verify
help: help-verify
define HELP_VERIFY
  verify         run verification checks
  update-verify  overwrite verification baseline
endef
export HELP_VERIFY
help-verify:
	@echo "$$HELP_VERIFY"
endif
