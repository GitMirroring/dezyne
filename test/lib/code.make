# Dezyne --- Dezyne command line tools
# Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
# Copyright © 2016, 2017 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
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

.PHONY:all default
default: all

DEVELOPMENT:=$(shell readlink -f $(dir $(filter %/code.make,$(MAKEFILE_LIST)))../../)
define CHECKPARAM
ifeq ($(origin $(1)), undefined)
$$(error $(1) undefined)
endif
endef

$(foreach i,DZN LANGUAGE MODEL IN OUT,$(eval $(call CHECKPARAM,$(i))))

ifeq ($(MAIN),)
MODEL_OPT:=-m $(MODEL)
endif

ifneq ($(TSS),)
TSS_OPT:=-s $(MODEL)
endif

runtime-common:
	mkdir -p $(OUT)/dzn
	for file in $(filter-out %/, $(patsubst /$(LANGUAGE)/%, %,  $(shell $(DZN) ls /share/runtime/$(LANGUAGE)))); do\
	    ln -sf $(DEVELOPMENT)/gaiag/runtime/$(LANGUAGE)/$$file $(OUT)/$$file;\
	done
	for file in $(filter-out %/, $(patsubst /$(LANGUAGE)/%, %,  $(shell $(DZN) ls /share/runtime/$(LANGUAGE)/dzn))); do\
	    ln -sf $(DEVELOPMENT)/gaiag/runtime/$(LANGUAGE)/dzn/$$file $(OUT)/dzn/$$file;\
	done

ifeq ($(LANGUAGE),c++03)
runtime: runtime-common
	ln -sf $(DEVELOPMENT)/gaiag/runtime/c++/pump.cc $(OUT)/
	ln -sf $(DEVELOPMENT)/gaiag/runtime/c++/dzn/pump.hh $(OUT)/dzn/
	ln -sf $(DEVELOPMENT)/gaiag/runtime/c++/dzn/context.hh $(OUT)/dzn/
	ln -sf $(DEVELOPMENT)/gaiag/runtime/c++/dzn/coroutine.hh $(OUT)/dzn/
else
runtime: runtime-common
endif

code: $(wildcard $(IN)/*.dzn $(IN)/*/*.dzn)
	for file in $^; do $(DZN) code $(IMPORTS) $(CODE_OPTIONS) -l $(LANGUAGE) --depends $(MODEL_OPT) $(TSS_OPT) -o $(OUT) $$file; done

all: runtime code

-include $(patsubst $(IN)/%.dzn, $(OUT)/%.d, $(wildcard $(IN)/*.dzn))
-include $(patsubst $(IN)/%.dzn, $(OUT)/%.d, $(wildcard $(IN)/*/*.dzn))
