# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Paul Hoogendijk <paul.hoogendijk@verum.com>
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

LOCAL_CODE_LANGUAGE:=$(LOCAL_LANGUAGE)
LOCAL_LANGUAGE:=triangle

LOCAL_OUT:=$(OUT)/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
LOCAL_LANGUAGE:=$(LOCAL_CODE_LANGUAGE)

LOCAL_TRACE:=$(LOCAL_OUT)/$(LOCAL_NAME).trace
TRACE0:=$(LOCAL_TRACE).0

LOCAL_TARGET:=$(OUT)/$(LOCAL_NAME)/$(LOCAL_CODE_LANGUAGE)/triangle

ifeq ($(TRIANGLE_$(LOCAL_TRACE)),)
TRIANGLE_$(LOCAL_TRACE):=$(TRACE0)

$(TRACE0): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
$(TRACE0): LOCAL_OUT:=$(LOCAL_OUT)
$(TRACE0): LOCAL_SUT:=$(LOCAL_SUT)
$(TRACE0): LOCAL_TRACE_ILLEGAL:=$(LOCAL_TRACE_ILLEGAL)
$(TRACE0):
	@mkdir -p $(LOCAL_OUT) #fixme dzn traces
	$(DZN) traces $(LOCAL_TRACE_ILLEGAL) -m $(LOCAL_SUT) -o $(LOCAL_OUT) $(LOCAL_DZN_TOP)
endif

ifeq ($(VERBOSE),debug)
$(info target traces-$(LOCAL_TARGET))
endif

traces-$(LOCAL_TARGET): $(TRACE0)
traces: traces-$(LOCAL_TARGET)

triangle: triangle-$(LOCAL_TARGET)

ifeq ($(VERBOSE),debug)
$(info target triangle-$(LOCAL_TARGET))
endif

$(LOCAL_TARGET): 
	@echo ' .'
	@echo '/_\' $(LOCAL_NAME)
#'
triangle-$(LOCAL_TARGET): CDIR:=$(CDIR)
triangle-$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
triangle-$(LOCAL_TARGET): LOCAL_NAME:=$(LOCAL_NAME)
triangle-$(LOCAL_TARGET): LOCAL_SUT:=$(LOCAL_SUT)#for run
triangle-$(LOCAL_TARGET): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)#for run
triangle-$(LOCAL_TARGET): LOCAL_TRACE:=$(LOCAL_TRACE)
ifeq ($(LOCAL_LANGUAGE),run)
triangle-$(LOCAL_TARGET): $(LOCAL_TARGET:%/triangle/test=%/$(LOCAL_LANGUAGE)/test)
triangle-$(LOCAL_TARGET): $(TRACE0)
	for i in $$(ls -1 $(LOCAL_TRACE).* | sort -t. -k3 -k4 -n | $(TRIANGLE_MAX) 2>/dev/null); do\
		set -e;\
		echo trace[$(LOCAL_LANGUAGE)]: $$i;\
		diff -wy $$i <($(DZN) run -m $(LOCAL_SUT) -t $$i $(LOCAL_DZN_TOP) | grep ^trace:| sed 's,^trace:,,' | tr ',' '\n');\
		echo -e '\n---------------------------------------------------------------------------------';\
		set +e;\
	done
else # LOCAL_LANGUAGE!=run
triangle-$(LOCAL_TARGET): $(TRACE0) $(OUT)/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/test
	for i in $$(ls -1 $(LOCAL_TRACE).* | sort -t. -k3 -k4 -n | $(TRIANGLE_MAX) 2>/dev/null); do\
		set -e;\
		echo trace[$(LOCAL_LANGUAGE)]: $$i;\
		diff -wy $$i <(cat $$i | $(OUT)/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/test |& bin/code2fdr);\
		echo -e '\n---------------------------------------------------------------------------------';\
		set +e;\
	done
endif # LOCAL_LANGUAGE!=run

triangle-$(LOCAL_TARGET): $(TRACE0)
triangle-$(LOCAL_TARGET): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
triangle-$(OUT)/$(LOCAL_NAME): triangle-$(LOCAL_TARGET)
check-$(OUT)/$(LOCAL_NAME): triangle-$(LOCAL_TARGET)
ifeq ($(VERBOSE),debug)
$(info target triangle-$(OUT)/$(LOCAL_NAME))
$(info target triangle-$(LOCAL_TARGET))
$(info target triangle-$(OUT)/$(LOCAL_NAME))
endif

ifeq ($(HELP_TRIANGLE),)
update-triangle:
check: triangle
update: update-triangle
help: help-triangle
define HELP_TRIANGLE
  triangle       run triangle checks
endef
export HELP_TRIANGLE
help-triangle:
	@echo "$$HELP_TRIANGLE"
endif
