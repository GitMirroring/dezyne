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
	#guile -L .. --language=asd -s Enums.asd
	#./asdgen Enums.asd
	#./asdgen interface-events.asd
	#./asdgen interface-reply-events.asd
	#./asdgen interface-behaviour.asd
	#./asdgen interface-imports.asd
	#./asdgen alarm-component.asd
	./asdgen alarm-component-pretty.asd | tee pretty.asd && diff -uw alarm-component-pretty.asd pretty.asd
