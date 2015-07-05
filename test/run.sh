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

TRACE='arm'
echo
echo running $TRACE
dzn run --gaiag -t <(echo $TRACE) regression/IConsole.dzn | grep ^trace: | sed 's/trace:/  => /'

TRACE='console.arm'
echo
echo running $TRACE
dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | sed 's/trace:/  => /'

TRACE='init'
echo running $TRACE
dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | sed 's/trace:/  => /'

echo

TRACE='console.arm sensor.enable sensor.return console.return'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

TRACE='init error return'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | tr , '\n')

# TRACE='init ok return work return inevitable ok return'
# echo running $TRACE
# diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | tr , '\n')

echo
TRACE='work return'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet3.dzn | grep ^trace: | tr , '\n')

echo
TRACE='ok'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet4.dzn | grep ^trace: | tr , '\n')

echo
TRACE='work return ok'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet3.dzn | grep ^trace: | tr , '\n')

echo
echo Non-Det broken...
TRACE='init ok return work return ok'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | tr , '\n')

# TRACE='init error return stop ok return recover error return recover ok return work return inevitable ok return work return stop return inevitable ok return'
# echo running $TRACE
# diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/NonDet.dzn | grep ^trace: | tr , '\n')

TRACE='console.arm sensor.enable sensor.return console.return console.disarm sensor.disable sensor.return console.return sensor.disabled console.deactivated'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

TRACE='console.arm sensor.enable sensor.return console.return sensor.triggered console.detected siren.turnon siren.return console.disarm sensor.disable sensor.return siren.turnoff siren.return console.return sensor.disabled console.deactivated'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

TRACE='console.arm sensor.enable sensor.return console.return console.arm illegal'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

TRACE='i.done u.what u.Status_Ok i.Status_Yes'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/R.dzn | grep ^trace: | tr , '\n')

echo
echo Non-Det [with values]: broken...
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Reply.dzn | grep ^trace: | tr , '\n')


TRACE='i.done u.what u.Status_Ok i.Status_No foo bar baz'
RESULT='i.done u.what u.Status_Ok Invalid event: i.Status_No'
echo
echo running $TRACE
diff -u <(echo trace:$RESULT | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/R.dzn | grep -E '^(trace|Invalid event):' | tr '[, ]' '[\n\n]')

echo
echo Non-Det [with values]: broken...
echo running $TRACE
diff -u <(echo trace:$RESULT | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Reply.dzn | grep -E '^(trace|Invalid event):' | tr '[, ]' '[\n\n]')

echo
echo FIXME: is this Q example broken??
TRACE='p.e r.e r.a r.return p.a p.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/q.dzn | grep ^trace: | tr , '\n')

TRACE='ctrl.hcalibrate robot.tcalibrate robot.tcalibrated robot.return ctrl.return'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/h.dzn | grep ^trace: | tr , '\n')

## ../webapp/client/dzn --debug run -g -t <(echo ctrl.hcalibrate robot.tcalibrate robot.tcalibrated robot.return ctrl.return) regression/h.dzn

##../webapp/client/dzn --debug run --gaiag -t <(echo i.done u.what u.Status_Ok i.Status_Yes) regression/R.dzn 
