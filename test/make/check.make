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

include make/common.make

# only do code if there are components; never skip .project
ifneq ($(LOCAL_COMPONENTS)$(filter parse run table verify,$(LOCAL_LANGUAGE))$(PROJECT_P),)
include make/$(LOCAL_LANGUAGE).make

ifeq ($(filter $(LOCAL_LANGUAGE),$(CODE_LANGUAGES) run),$(LOCAL_LANGUAGE))
ifeq ($(PROJECT_P),)
ifneq ($(filter-out $(BROKEN_trace) $(BROKEN_$(LOCAL_LANGUAGE)),$(LOCAL_DZN_TOP)),)
ifneq ($(TRIANGLE),)
include make/triangle.make
endif
endif
endif
endif

else
ifeq ($(VERBOSE),debug)
$(info skipping no components: $(CDIR):$(LOCAL_NAME) p:$(PROJECT_P))
endif
endif

include make/reset.make
