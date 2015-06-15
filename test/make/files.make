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

ifeq ($(LANGUAGES),)
LANGUAGES:=$(ALL_LANGUAGES)
endif

ifeq ($(DZN_FILES),)
DZN_FILES:=$(wildcard $(CDIR)*.dzn)
endif

DZN_FILES:=$(filter-out $(BROKEN),$(DZN_FILES))

$(info Languages: $(LANGUAGES))
$(foreach DZN_FILE,$(DZN_FILES),\
	$(foreach lang,$(LANGUAGES),\
		$(if $(filter-out $(BROKEN_$(lang)),$(DZN_FILE)),\
			$(eval LOCAL_LANGUAGE:=$(lang))\
			$(eval LOCAL_DZN_FILES:=$(DZN_FILE))\
			$(eval include make/check.make))))
DZN_FILES:=
LANGUAGES:=
