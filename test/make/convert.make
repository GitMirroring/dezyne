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

LOCAL_STUBS:=$(filter-out $(LOCAL_IM_FILES:$(CDIR)%.im=%),$(LOCAL_DM_FILES:$(CDIR)%.dm=%))

LOCAL_DZN_OUT_FILES+=$(LOCAL_COMPONENTS:%=$(LOCAL_OUT)/%.dzn)
LOCAL_DZN_OUT_FILES+=$(LOCAL_STUBS:%=$(LOCAL_OUT)/%.dzn)
LOCAL_DZN_OUT_FILES+=$(LOCAL_INTERFACES:%=$(LOCAL_OUT)/%.dzn)
LOCAL_DZN_OUT_FILES:=$(sort $(LOCAL_DZN_OUT_FILES))

ifneq ($(LOCAL_GOAL_FILES),)
LOCAL_DZN_OUT_FILES:=$(filter $(LOCAL_GOAL_FILES),$(LOCAL_DZN_OUT_FILES))
endif

LOCAL_O_FILES:=$(LOCAL_COMPONENTS:%=$(LOCAL_OUT)/%.o)
LOCAL_STUBS_OUT:=$(LOCAL_STUBS:%=$(LOCAL_OUT)/%.dzn)

ifeq ($(VERBOSE),debug)
$(info LOCAL_COMPONENTS $(LOCAL_COMPONENTS))
$(info LOCAL_INTERFACES $(LOCAL_INTERFACES))
$(info LOCAL_STUBS $(LOCAL_STUBS))
$(info LOCAL_DZN_OUT_FILES $(LOCAL_DZN_OUT_FILES))
$(info LOCAL_O_FILES: $(LOCAL_COMPONENTS:%=$(LOCAL_OUT)/%.o))
endif

$(LOCAL_OUT)/%.dzn: CDIR:=$(CDIR)
$(LOCAL_OUT)/%.dzn: LOCAL_GLOBAL_TYPES:=$(LOCAL_GLOBAL_TYPES)
$(LOCAL_OUT)/%.dzn: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/%.dzn: $(CDIR)%.dm
	@mkdir -p $(LOCAL_OUT)
	echo "$< -> $@"
	$(DZN) convert -o $(dir $@) $<
	sed -i -e 's,\(component \w*\)Comp,\1,' -e 's,Iasd.builtin.ITimer,ITimer,' $(basename $@)Comp.dzn
	sed -i -e 's,in void on(),in void on1(),' $(LOCAL_OUT)/*.dzn
#	$(LOCAL_GLOBAL_TYPES)sed -i -e 's,^.* extern,extern,' $(basename $@)Comp.dzn
	mv $(basename $@)Comp.dzn $(basename $@).dzn

$(LOCAL_OUT)/I%.dzn: CDIR:=$(CDIR)
$(LOCAL_OUT)/I%.dzn: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/I%.dzn: LOCAL_STUBS_OUT:=$(LOCAL_STUBS_OUT)
$(LOCAL_OUT)/I%.dzn: $(CDIR)%.im
	@mkdir -p $(LOCAL_OUT)
	echo "$< -> $@"
	$(DZN) convert -o $(dir $@) -m $<
	if [ "$(filter $(@:$(LOCAL_OUT)/I%.dzn=$(LOCAL_OUT)/%.dzn),$(LOCAL_STUBS_OUT))" != "$(<:$(CDIR)%.im=$(LOCAL_OUT)/%.dzn)" ]; then rm $(<:$(CDIR)%.im=$(LOCAL_OUT)/%.dzn); fi

convert: $(LOCAL_DZN_OUT_FILES)

define CONVERT.rule
convert-$(LOCAL_TARGET)/$(1): CDIR:=$$(CDIR)
convert-$(LOCAL_TARGET)/$(1): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
convert-$(LOCAL_TARGET)/$(1): LOCAL_NAME:=$$(LOCAL_NAME)
convert-$(LOCAL_TARGET)/$(1): LOCAL_OUT:=$$(LOCAL_OUT)
convert-$(LOCAL_TARGET)/$(1): LOCAL_TARGET:=$$(LOCAL_TARGET)
convert-$(LOCAL_TARGET)/$(1): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
convert-$(LOCAL_TARGET)/$(1): $(LOCAL_OUT)/$(1)
	diff -uwB $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(1) $$<
check-$(OUT)/$(LOCAL_NAME): convert-$(LOCAL_TARGET)/$(1)
convert-$(OUT)/$(LOCAL_NAME): convert-$(LOCAL_TARGET)/$(1)
convert-$(LOCAL_TARGET): convert-$(LOCAL_TARGET)/$(1)
convert: convert-$(LOCAL_TARGET)/$(1)
ifeq ($(VERBOSE),debug)
$$(info target check-$(OUT)/$(LOCAL_NAME))
$$(info target convert-$(OUT)/$(LOCAL_NAME))
$$(info target convert-$(LOCAL_TARGET))
$$(info target convert-$(LOCAL_TARGET)/$(1))
endif

update-convert: $(LOCAL_DZN_OUT_FILES)

update-convert-$(LOCAL_TARGET)/$(1): CDIR:=$$(CDIR)
update-convert-$(LOCAL_TARGET)/$(1): LOCAL_LANGUAGE:=$$(LOCAL_LANGUAGE)
update-convert-$(LOCAL_TARGET)/$(1): LOCAL_NAME:=$$(LOCAL_NAME)
update-convert-$(LOCAL_TARGET)/$(1): LOCAL_OUT:=$$(LOCAL_OUT)
update-convert-$(LOCAL_TARGET)/$(1): LOCAL_TARGET:=$$(LOCAL_TARGET)
update-convert-$(LOCAL_TARGET)/$(1): LOCAL_DZN_TOP:=$$(LOCAL_DZN_TOP)
update-convert-$(LOCAL_TARGET)/$(1): $(LOCAL_OUT)/$(1)
	@mkdir -p $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
	cp -v $$^ $(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/$(1)
update-$(OUT)/$(LOCAL_NAME): update-convert-$(LOCAL_TARGET)/$(1)
update-convert-$(OUT)/$(LOCAL_NAME): update-convert-$(LOCAL_TARGET)/$(1)
update-convert-$(LOCAL_TARGET): update-convert-$(LOCAL_TARGET)/$(1)
update-convert: update-convert-$(LOCAL_TARGET)/$(1)
ifeq ($(VERBOSE),debug)
$$(info target update-$(OUT)/$(LOCAL_NAME))
$$(info target update-convert-$(OUT)/$(LOCAL_NAME))
$$(info target update-convert-$(LOCAL_TARGET))
$$(info target update-convert-$(LOCAL_TARGET)/$(1))
endif
endef

$(info out $(notdir $(LOCAL_DZN_OUT_FILES)))
$(foreach i,$(notdir $(LOCAL_DZN_OUT_FILES)),$(eval $(call CONVERT.rule,$(i))))

ifeq ($(HELP_CONVERT),)
all: convert
update: update-convert
help: help-convert
define HELP_CONVERT
  convert           run all convert
  update-convert    overwrite convert baseline
endef
export HELP_CONVERT
help-convert:
	@echo "$$HELP_CONVERT"
endif
