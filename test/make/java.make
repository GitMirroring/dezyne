# Dezyne --- Dezyne command line tools
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

LOCAL_SOURCE_EXT:=.java
LOCAL_HEADER_EXT:=
LOCAL_JAVA_FILES+=$(wildcard $(CDIR)*.java)
LOCAL_SOURCE_FILES+=$(LOCAL_JAVA_FILES)
LOCAL_HEADER:=$(LOCAL_OUT)/header.java
LOCAL_FOOTER:=$(wildcard $(CDIR)main.java)
ifeq ($(LOCAL_FOOTER),)
LOCAL_FOOTER:=$(LOCAL_OUT)/main.java
endif

$(LOCAL_OUT)/main.class: LOCAL_OUT:=$(LOCAL_OUT)
$(LOCAL_OUT)/main.class: LOCAL_FOOTER:=$(LOCAL_FOOTER)
$(LOCAL_OUT)/main.class: LOCAL_MODELS:=$(LOCAL_MODELS)
$(LOCAL_OUT)/main.class: $(LOCAL_FOOTER) $(LOCAL_MODELS:%=$(LOCAL_OUT)/dzn/%.java)
	-cp $(LOCAL_OUT)/dzn/*.java $(LOCAL_OUT)
	cp --force --backup $(LOCAL_FOOTER) $(LOCAL_OUT)/$(basename $(notdir $(LOCAL_FOOTER))).java
#	cd $(LOCAL_OUT) && javac -Xlint:unchecked *.java
	javac -d $(LOCAL_OUT) $(LOCAL_OUT)/*.java

define JAVA_SCRIPT
#! /bin/bash
java -ea -cp $$(cd $$(dirname $$0); pwd) main
endef
export JAVA_SCRIPT

$(LOCAL_TARGET): $(LOCAL_HEADER) $(LOCAL_DEZYNE_FILES) $(LOCAL_FOOTER) $(LOCAL_OUT)/main.class
	echo "$$JAVA_SCRIPT" > $@
	chmod +x $@

include make/code.make
