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
#	$(LOCAL_GLOBAL_TYPES)sed -i -e 's,^.* extern,extern,' $(basename $@)Comp.dzn
	mv $(basename $@)Comp.dzn $(basename $@).dzn

$(LOCAL_OUT)/I%.dzn: CDIR:=$(CDIR)
$(LOCAL_OUT)/I%.dzn: LOCAL_GLOBAL_TYPES:=$(LOCAL_GLOBAL_TYPES)
$(LOCAL_OUT)/I%.dzn: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/I%.dzn: LOCAL_STUBS_OUT:=$(LOCAL_STUBS_OUT)
$(LOCAL_OUT)/I%.dzn: $(CDIR)%.im
	@mkdir -p $(LOCAL_OUT)
	echo "$< -> $@"
	$(DZN) convert -o $(dir $@) -m $<
#	$(LOCAL_GLOBAL_TYPES)sed -i -e 's,^.* extern,extern,' $@
	if [ "$(filter $(@:$(LOCAL_OUT)/I%.dzn=$(LOCAL_OUT)/%.dzn),$(LOCAL_STUBS_OUT))" != "$(<:$(CDIR)%.im=$(LOCAL_OUT)/%.dzn)" ]; then rm $(<:$(CDIR)%.im=$(LOCAL_OUT)/%.dzn); fi
