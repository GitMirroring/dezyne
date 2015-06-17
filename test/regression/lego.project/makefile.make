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

#LANGUAGES:=$(filter c c++ c++03 goops javascript python, $(CODE_LANGUAGES))
LANGUAGES:=$(CODE_LANGUAGES)
$(foreach LOCAL_LANGUAGE,$(LANGUAGES),\
	$(eval include $(CDIR)project.make))
DZN_FILES:=
LANGUAGES:=

out/lego.project/c++03/main.o: CXXFLAGS:=-std=c++11 $(CXXFLAGS)
out/lego.project/c++03/timer.o: CXXFLAGS:=-std=c++11 $(CXXFLAGS)

out/lego.project/cs/dezyne/%.cs: $(CDIR)%.cs
	cp $< $@
out/lego.project/goops/dezyne/%.scm: $(CDIR)%.scm
	cp $< $@
out/lego.project/goops/dezyne/main.scm: $(CDIR)main.scm
	cp $< $@
out/lego.project/java/dezyne/%.java: $(CDIR)%.java
	cp $< $@
out/lego.project/javascript/dezyne/%.js: $(CDIR)%.js
	cp $< $@

out/lego.project/cs/test: out/lego.project/cs/timer.cs
out/lego.project/java/main.java: out/lego.project/java/timer.java

LANGUAGES:=table
include make/files.make
# DZN_FILES:=$(wildcard $(CDIR)*.dzn)
# $(foreach f,$(DZN_FILES),\
# 	$(eval LOCAL_LANGUAGE:=table)\
# 	$(eval LOCAL_DZN_FILES:=$(f))\
# 	$(eval include make/check.make))
DZN_FILES:=
LANGUAGES:=
