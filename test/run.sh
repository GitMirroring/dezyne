# Dezyne --- Dezyne command line tools
#
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

TRACE='console.arm'
echo running $TRACE
dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | sed 's/trace:/  => /'

TRACE='init'
echo running $TRACE
dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | sed 's/trace:/  => /'

echo

TRACE='console.arm sensor.enable sensor.return console.return'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

TRACE='init error return'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | tr , '\n')

TRACE='init error return stop ok return recover error return recover ok return work return inevitable ok return work return stop return inevitable ok return'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | tr , '\n')

TRACE='console.arm sensor.enable sensor.return console.return console.disarm sensor.disable sensor.return console.return sensor.disabled console.deactivated'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

TRACE='console.arm sensor.enable sensor.return console.return sensor.triggered console.detected siren.turnon siren.return console.disarm sensor.disable sensor.return siren.turnoff siren.return console.return sensor.disabled console.deactivated'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

TRACE='i.done u.what u.Status_Ok i.Status_Yes'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Reply.dzn | grep ^trace: | tr , '\n')

TRACE='i.done u.what u.Status_Ok i.Status_No foo bar baz'
RESULT='i.done u.what u.Status_Ok Invalid event: i.Status_No'
echo running $TRACE
diff -u <(echo trace:$RESULT | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Reply.dzn | grep -E '^(trace|Invalid event):' | tr '[, ]' '[\n\n]')
