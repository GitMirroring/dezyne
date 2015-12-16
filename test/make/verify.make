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
TOP:=$(LOCAL_NAME)-$(LOCAL_LANGUAGE)-$(1)
$$(TOP): CDIR:=$$(CDIR)
$$(TOP): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
$$(TOP): LOCAL_NAME:=$$(LOCAL_NAME)
$$(TOP): LOCAL_OUT:=$$(LOCAL_OUT)
$$(TOP): LOCAL_TARGET:=$$(LOCAL_TARGET)
$$(TOP): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
$$(TOP): $$(LOCAL_DZN_TOP) #idee
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(1) <($(DZN) --verbose verify --all -m $(1) $(LOCAL_DZN_TOP) | bin/reorder)

$(LOCAL_NAME)-$(LOCAL_LANGUAGE): $$(TOP)
$(LOCAL_NAME): $$(TOP)
$(LOCAL_NAME)-check: $$(TOP)
$(LOCAL_LANGUAGE): $$(TOP)

ifeq ($(filter list,$(MAKECMDGOALS)),list)
$$(info $$()    $$(TOP))
$$(info $$()    $(LOCAL_NAME)-$(LOCAL_LANGUAGE))
$$(info $$()    $(LOCAL_NAME))
endif

$$(TOP)-update: CDIR:=$$(CDIR)
$$(TOP)-update: LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
$$(TOP)-update: LOCAL_NAME:=$$(LOCAL_NAME)
$$(TOP)-update: LOCAL_OUT:=$$(LOCAL_OUT)
$$(TOP)-update: LOCAL_TARGET:=$$(LOCAL_TARGET)
$$(TOP)-update: LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
$$(TOP)-update: $$(LOCAL_DZN_TOP) #idee
	mkdir -p $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
	$(DZN) --verbose verify --all -m $(1) $(LOCAL_DZN_TOP) | bin/reorder > $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(1)

$(LOCAL_NAME)-$(LOCAL_LANGUAGE)-update: $$(TOP)-update
$(LOCAL_NAME)-update: $$(TOP)-update
$(LOCAL_LANGUAGE)-update: $$(TOP)-update

ifeq ($(filter list,$(MAKECMDGOALS)),list)
$$(info $$()    $(LOCAL_NAME)-$(LOCAL_LANGUAGE)-update)
$$(info $$()    $(LOCAL_NAME)-update)
endif
endef

$(foreach i,$(LOCAL_MODELS),$(eval $(call VERIFY.rule,$(i))))

$(LOCAL_TARGET):
	@echo $@

ifeq ($(HELP_VERIFY),)
all: verify
update: verify-update
verify-update:
help: help-verify
define HELP_VERIFY
  verify         run verification checks
  verify-update  overwrite verification baseline
endef
export HELP_VERIFY
help-verify:
	@echo "$$HELP_VERIFY"
endif
