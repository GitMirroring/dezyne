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

#! /bin/bash

TRACE='console.arm sensor.enable sensor.return console.return'
diff -u <(echo trace:$TRACE|tr ' ' ,) <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace:)

TRACE='init error return stop ok return recover error return recover ok return work return inevitable ok return work return stop return inevitable ok return'
diff -u <(echo trace:$TRACE|tr ' ' ,) <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace:)
