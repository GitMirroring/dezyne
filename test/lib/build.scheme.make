# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

ifeq ($(GUILE),)
GUILE:=$(shell type -p guile)
endif

ifeq ($(GUILE_TOOLS),)
GUILE_TOOLS:=guild
endif

ifeq ($(abs_top_srcdir),)
abs_top_srcdir:=$(PWD)
endif

ifeq ($(MAIN),)
MAIN:=$(OUT)/main.scm
endif

default: $(OUT)/test

GUILEC_FLAGS =					\
 -Warity-mismatch				\
 -Wformat					\
 --load-path=$(abs_top_srcdir)			\
 --load-path=$(abs_top_srcdir)/runtime/scheme	\
 --load-path=$(IN)				\
 --load-path=$(IN)/scheme			\
 --load-path=$(OUT)

AM_DEFAULT_VERBOSITY = 0
AM_V_GUILEC = $(AM_V_GUILEC_$(V))
AM_V_GUILEC_ = $(AM_V_GUILEC_$(AM_DEFAULT_VERBOSITY))
AM_V_GUILEC_0 = @echo "  GUILEC" $@;

%.go:	%.scm
	$(AM_V_GUILEC)GUILE_AUTO_COMPILE=0	\
	$(GUILE_TOOLS) compile $(GUILEC_FLAGS)	\
	-o "$@" "$<"

$(OUT)/test: $(patsubst $(IN)/%.scm, $(OUT)/%.go, $(wildcard $(IN)/*.scm))
$(OUT)/test: $(patsubst $(OUT)/%.scm, $(OUT)/%.go, $(wildcard $(OUT)/*.scm))
$(OUT)/test: $(patsubst %.scm, %.go,$(wildcard $(OUT)/*.scm))

$(OUT)/test: $(MAIN)
	if test -f $(IN)/main.scm; then cp -f $(IN)/main.scm $(OUT); fi
	if test -f $(IN)/scheme/main.scm; then cp -f $(IN)/scheme/main.scm $(OUT); fi
	sed -e 's,@GUILE@,$(GUILE),g'		\
	    -e 's,@OUT@,$(OUT),g'		\
	    test/lib/test.scm > $@
	chmod +x $@
