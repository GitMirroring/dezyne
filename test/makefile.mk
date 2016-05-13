# Dezyne --- Dezyne command line tools
# Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
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

CLEAN := $(CLEAN)

TEST := $(TEST) $(CDIR)-check
$(CDIR)-check: CDIR:=$(CDIR)
$(CDIR)-check:
	$(MAKE) smoke

PROPER := $(PROPER) $(CDIR)/node_modules/.dummy
$(CDIR)/node_modules/.dummy: CDIR:=$(CDIR)
$(CDIR)/node_modules/.dummy: $(CDIR)/package.json
	cd $(CDIR) && npm install
	touch $@

CLEAN := $(CLEAN) $(CDIR)/regression/examples/index.txt

$(CDIR)/regression/examples/index.txt:
	for i in $(sort\
	    $(wildcard $(@D)/*.dzn)\
	    $(wildcard $(@D)/*/project.txt)\
	    ); do \
	    if [ $$(basename $$i) = project.txt  ]; then\
		echo $$(basename $$(dirname $$i));\
	    else\
		echo $$(basename $$i .dzn);\
	    fi;\
	    head -1 $$i | sed -e s,'^// *,,' -e 's,^purpose: *,,';\
	    echo;\
	done > $@.$$PPID~
	mv $@.$$PPID~ $@

include make/check.mk
