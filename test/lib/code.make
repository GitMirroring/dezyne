# Dezyne --- Dezyne command line tools
# Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

define CHECKPARAM
ifeq ($(origin $(1)), undefined)
$$(error $(1) undefined)
endif
endef

$(foreach i,DZN LANGUAGE MODEL IN OUT,$(eval $(call CHECKPARAM,$(i))))

.PHONY:all

all: $(wildcard $(IN)/*.dzn)
	mkdir -p $(OUT)/dzn
	for file in $(filter-out %/, $(patsubst /$(LANGUAGE)/%, %,  $(shell $(DZN) ls -R /share/runtime/$(LANGUAGE))));\
	do $(DZN) cat /share/runtime/$(LANGUAGE)/$$file > $(OUT)/$$file; done
	for file in $^; do $(DZN) code -l $(LANGUAGE) --depends -m $(MODEL) -o $(OUT) $$file; done

-include $(patsubst $(IN)/%.dzn, $(OUT)/%.d, $(wildcard $(IN)/*.dzn))
