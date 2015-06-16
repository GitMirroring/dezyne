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

ifneq ($(LOCAL_DZN_FILES),)
#allow regression/makefile.make to include foo/bar.dzn files
CDIR:=$(dir $(firstword $(LOCAL_DZN_FILES)))
endif

PROJECT_P:=$(filter project,$(patsubst %.project,project project,$(notdir $(CDIR:%/=%))))

ifeq ($(words $(LOCAL_DZN_FILES) $(LOCAL_DZN_OUT_FILES) $(LOCAL_SOURCE_FILES) $(PROJECT_P)),1)
LOCAL_DZN_TOP:=$(firstword $(LOCAL_DZN_FILES) $(LOCAL_DZN_OUT_FILES))
LOCAL_NAME:=$(basename $(notdir $(LOCAL_DZN_TOP)))
ifeq ($(VERBOSE),debug)
$(info SINGLE $(LOCAL_NAME))
endif
else
LOCAL_DZN_TOP:=$(firstword $(sort $(LOCAL_DZN_FILES) $(LOCAL_DZN_OUT_FILES)))
LOCAL_NAME:=$(notdir $(CDIR:%/=%))
ifeq ($(VERBOSE),debug)
$(info PROJECT $(LOCAL_NAME))
endif
endif

ifeq ($(LOCAL_SUT),)
LOCAL_SUT:=$(LOCAL_NAME)
endif

ifeq ($(strip $(shell grep -ho '^component Main' $(LOCAL_DZN_TOP) /dev/null)),component Main)
# for old IRun, Adapter, Main files
LOCAL_SUT:=Main
endif
LOCAL_OUT:=$(OUT)/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
LOCAL_TARGET:=$(LOCAL_OUT)/test

ifeq ($(LOCAL_TRACE_LANGUAGE),)
ifeq ($(filter c c++ c++03, $(LOCAL_LANGUAGE)),$(LOCAL_LANGUAGE))
LOCAL_TRACE_LANGUAGE:=code
else
ifeq ($(filter cs java python, $(LOCAL_LANGUAGE)),$(LOCAL_LANGUAGE))
LOCAL_TRACE_LANGUAGE:=code
else
LOCAL_TRACE_LANGUAGE:=code
#LOCAL_TRACE_LANGUAGE:=$(LOCAL_LANGUAGE)
endif
endif
endif

LOCAL_BASE:=$(notdir $(basename $(LOCAL_DZN_TOP)))

ifeq ($(strip $(LOCAL_TRACE_FILES)),)
LOCAL_TRACE_FILES:=$(wildcard $(basename $(LOCAL_DZN_TOP)).trace $(basename $(LOCAL_DZN_TOP)).trace.*)
endif

ifeq ($(strip $(LOCAL_TRACE_FILES)),)
LOCAL_TRACE_FILES:=$(wildcard $(CDIR)trace)
endif

## do not require an empty trace for projects
#ifeq ($(strip $(LOCAL_TRACE_FILES)),)
#ifneq ($(PROJECT_P),)
#LOCAL_TRACE_FILES:=make/trace
#endif
#endif

ifneq ($(strip $(LOCAL_DZN_FILES)),)
ifeq ($(strip $(LOCAL_INTERFACES)),)
LOCAL_INTERFACES:=$(shell grep -hEo '^interface [_a-zA-Z0-9]+' $(LOCAL_DZN_FILES) | sed 's/^interface //')
endif
ifeq ($(strip $(LOCAL_COMPONENTS)),)
LOCAL_COMPONENTS:=$(shell grep -hEo '^component [_a-zA-Z0-9]+' $(LOCAL_DZN_FILES) | sed 's/^component //')
endif
endif
LOCAL_MODELS:=$(LOCAL_INTERFACES) $(LOCAL_COMPONENTS)

ifeq ($(VERBOSE),debug)
$(info interfaces[$(LOCAL_NAME)]: $(LOCAL_INTERFACES))
$(info components[$(LOCAL_NAME)]: $(LOCAL_COMPONENTS))
endif

$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(LOCAL_TARGET): LOCAL_NAME:=$(LOCAL_NAME)
all: LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
all: LOCAL_TARGET:=$(LOCAL_TARGET)
