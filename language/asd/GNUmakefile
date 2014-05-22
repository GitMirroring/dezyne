# Gaiag --- Guile in Asd In Asd in Guile.
# Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Gaiag.
#
# Gaiag is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Gaiag is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
# 
# Commentary:
# 
# Code:

default: all

all: compile check

compile:
	guile -L .. spec.scm 

check:
	guile -L .. --language=asd -s Enums.asd | indent
	./asdgen Enums.asd | indent
	./asdgen interface-events.asd | indent
	./asdgen interface-reply-events.asd | indent
	./asdgen interface-behaviour.asd | indent
	./asdgen interface-imports.asd | indent
	./asdgen alarm-component.asd | indent
	./asdgen alarm-component-pretty.asd | indent | tee pretty.asd && diff -u alarm-component-pretty.asd pretty.asd
