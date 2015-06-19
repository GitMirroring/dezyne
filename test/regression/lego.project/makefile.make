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

#LANGUAGES:=$(filter c c++ c++03 cs goops javascript python, $(CODE_LANGUAGES))
JAVA7:=$(shell /usr/bin/javac -version 2>&1 | grep -oe 'javac 1.7' >/dev/null && echo 7 || echo '')
ifeq ($(JAVA7),7)
LANGUAGES:=$(filter-out java, $(CODE_LANGUAGES))
else
LANGUAGES:=$(CODE_LANGUAGES)
endif
$(foreach LOCAL_LANGUAGE,$(LANGUAGES),\
	$(eval include $(CDIR)project.make))
DZN_FILES:=
LANGUAGES:=

out/lego.project/c++03/main.o: CXXFLAGS:=-std=c++11 $(CXXFLAGS)
out/lego.project/c++03/timer.o: CXXFLAGS:=-std=c++11 $(CXXFLAGS)

LANGUAGES:=table
include make/files.make
# DZN_FILES:=$(wildcard $(CDIR)*.dzn)
# $(foreach f,$(DZN_FILES),\
# 	$(eval LOCAL_LANGUAGE:=table)\
# 	$(eval LOCAL_DZN_FILES:=$(f))\
# 	$(eval include make/check.make))
DZN_FILES:=
LANGUAGES:=
