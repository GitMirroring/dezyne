# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
# Copyright © 2015 Henk Katerberg <henk.katerberg@yahoo.com>
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

LOCAL_OUT:=$(CDIR)baseline/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)
LOCAL_LANGUAGE:=$(LOCAL_CODE_LANGUAGE)

LOCAL_TRACE:=$(LOCAL_OUT)/$(LOCAL_NAME).trace
TRACE0:=$(LOCAL_TRACE).0

LOCAL_TARGET:=$(OUT)/$(LOCAL_NAME)/$(LOCAL_CODE_LANGUAGE)/triangle

ifeq ($(LOCAL_CODE2FDR),)
LOCAL_CODE2FDR:=bin/code2fdr
endif

ifeq ($(TRIANGLE_$(LOCAL_TRACE)),)
TRIANGLE_$(LOCAL_TRACE):=$(TRACE0)

$(TRACE0): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)
$(TRACE0): LOCAL_OUT:=$(LOCAL_OUT)
$(TRACE0): LOCAL_SUT:=$(LOCAL_SUT)
$(TRACE0): LOCAL_TRACE_ILLEGAL:=$(LOCAL_TRACE_ILLEGAL)
$(TRACE0): LOCAL_TRACE_FLUSH:=$(LOCAL_TRACE_FLUSH)
$(TRACE0): $(LOCAL_DZN_TOP)
	@mkdir -p $(LOCAL_OUT) #fixme dzn traces
	$(DZN) traces -q 7 $(LOCAL_TRACE_ILLEGAL) $(LOCAL_TRACE_FLUSH) -m $(LOCAL_SUT) -o $(LOCAL_OUT) $(LOCAL_DZN_TOP)
endif

ifeq ($(VERBOSE),debug)
$(info target traces-$(LOCAL_TARGET))
endif

traces-$(LOCAL_TARGET): $(TRACE0)
traces: traces-$(LOCAL_TARGET)

TOP:=$(LOCAL_LANGUAGE)-$(LOCAL_TARGET)

triangle: $(TOP)

ifeq ($(VERBOSE),debug)
$(info target $(TOP))
endif

$(LOCAL_TARGET):
	@echo ' .'
	@echo '/_\' $(LOCAL_NAME)
#'
$(TOP): CDIR:=$(CDIR)
$(TOP): LOCAL_CODE2FDR:=$(LOCAL_CODE2FDR)
$(TOP): LOCAL_LANGUAGE:=$(LOCAL_LANGUAGE)
$(TOP): LOCAL_NAME:=$(LOCAL_NAME)
$(TOP): LOCAL_SUT:=$(LOCAL_SUT)#for run
$(TOP): LOCAL_DZN_TOP:=$(LOCAL_DZN_TOP)#for run
$(TOP): LOCAL_TRACE:=$(LOCAL_TRACE)
$(TOP): LOCAL_TIMEOUT:=$(LOCAL_TIMEOUT)
$(TOP): LOCAL_TRACE_FLUSH:=$(LOCAL_TRACE_FLUSH)
ifeq ($(LOCAL_LANGUAGE),run)
$(TOP): $(LOCAL_TARGET:%/triangle/test=%/$(LOCAL_LANGUAGE)/test)
$(TOP): $(TRACE0)
	for i in $$(ls -1 $(LOCAL_TRACE).* | sort -t. -k3 -k4 -n | $(TRIANGLE_MAX) 2>/dev/null); do\
		set -e;\
		echo trace[$(LOCAL_LANGUAGE)]: $$i;\
		diff -wy <(grep -v '[.]<flush>' $$i) <($(DZN) run -m $(LOCAL_SUT) -t <(grep -v '<flush>' $$i) $(LOCAL_DZN_TOP) | grep ^trace:| sed 's,^trace:,,' | tr ',' '\n');\
		echo -e '\n---------------------------------------------------------------------------------';\
		set +e;\
	done
else # LOCAL_LANGUAGE!=run
$(TOP): $(TRACE0) $(OUT)/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/test
	for i in $$(ls -1 $(LOCAL_TRACE).* | sort -t. -k3 -k4 -n | $(TRIANGLE_MAX) 2>/dev/null); do\
		set -e;\
		echo trace[$(LOCAL_LANGUAGE)]: $$i;\
		diff -wy $$i <(cat $$i | timeout $(LOCAL_TIMEOUT) $(OUT)/$(LOCAL_NAME)/$(LOCAL_LANGUAGE)/test $(LOCAL_TRACE_FLUSH) |& $(LOCAL_CODE2FDR));\
		echo -e '\n---------------------------------------------------------------------------------';\
		set +e;\
	done
endif # LOCAL_LANGUAGE!=run
