# Dezyne --- Dezyne command line tools
#
# Copyright © 2016 Rob Wieringa <rma.wieringa@gmail.com>
# Copyright © 2016, 2019, 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

ifeq ($(MAIN),)
MAIN:=$(OUT)/main.js
endif

default: $(OUT)/test

DEVELOPMENT:=$(shell readlink -f $(dir $(filter %/build.javascript.make,$(MAKEFILE_LIST)))../../)

$(info IN:$(IN))
$(info OUT:$(OUT))
$(info DIR:$(DIR))
$(OUT)/test: $(MAIN)
	cp $(MAIN) $(OUT)/test
	mkdir -p $(OUT)/dzn
	ln -fs $(DEVELOPMENT)/runtime/javascript/dzn/* $(OUT)/dzn/
	if test -f $(IN)/main.js; then cp -f $(IN)/main.js $(OUT)/test; fi
	if test -f $(IN)/javascript/main.js; then cp -f $(IN)/javascript/main.js $(OUT)/test; fi
	chmod +x $(OUT)/test
