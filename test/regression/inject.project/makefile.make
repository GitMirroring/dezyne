# Dezyne --- Dezyne command line tools
# Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Ladislau Posta <ladislau.posta@verum.com>
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

# we need to set LOCAL_LANGUAGE, copy make/project.make inline
#include make/project.make
ifeq ($(LANGUAGES),)
LANGUAGES:=$(ALL_LANGUAGES)
endif

DZN_FILES:=$(wildcard $(CDIR)*.dzn)

$(foreach LOCAL_LANGUAGE,$(LANGUAGES),\
	$(eval LOCAL_TRACE_LANGUAGE:=$(LOCAL_LANGUAGE))\
	$(eval LOCAL_DZN_FILES:=$(DZN_FILES))\
	$(eval include make/check.make))

DZN_FILES:=
LANGUAGES:=
