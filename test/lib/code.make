# Dezyne --- Dezyne command line tools
# Copyright © 2016, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
# Copyright © 2016, 2017, 2018 Jan Nieuwenhuizen <janneke@gnu.org>
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

.PHONY:all code default
default: all

DEVELOPMENT:=$(shell readlink -f $(dir $(filter %/code.make,$(MAKEFILE_LIST)))../../)
define CHECKPARAM
ifeq ($(origin $(1)), undefined)
$$(error $(1) undefined)
endif
endef

$(foreach i,DZN LANGUAGE MODEL IN OUT,$(eval $(call CHECKPARAM,$(i))))

ifeq ($(MAIN),)
MODEL_OPT:=-m '$(MODEL)'
endif

ifneq ($(TSS),)
TSS_OPT:=-s '$(MODEL)'
endif

runtime-common:
	mkdir -p "$(OUT)"/dzn
	for file in $(filter-out %/, $(patsubst /$(LANGUAGE)/%, %,  $(shell $(DZN) ls /share/runtime/$(LANGUAGE)))); do\
	    ln -sf $(DEVELOPMENT)/gaiag/runtime/$(LANGUAGE)/"$$file" "$(OUT)"/$$file;\
	done
	for file in $(filter-out %/, $(patsubst /$(LANGUAGE)/%, %,  $(shell $(DZN) ls /share/runtime/$(LANGUAGE)/dzn))); do\
	    ln -sf $(DEVELOPMENT)/gaiag/runtime/$(LANGUAGE)/dzn/$$file "$(OUT)"/dzn/$$file;\
	done

runtime: runtime-common

IN_DZN=$(shell ls -1 "$(IN)"/*.dzn | sed -e 's,^,",' -e 's,$$,",')
IN__DZN=$(shell ls -1 "$(IN)"/*/*.dzn | sed -e 's,^,",' -e 's,$$,",')
code:
	set -x; for file in $(IN_DZN) $(IN__DZN); do\
	    $(DZN) code $(IMPORTS) $(CODE_OPTIONS) -l $(LANGUAGE) $(MODEL_OPT) $(TSS_OPT) -o "$(OUT)" "$$file";\
	done

all: runtime code
