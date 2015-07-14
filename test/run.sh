# Dezyne --- Dezyne command line tools
#
# Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

TRACE='console.arm sensor.enable sensor.return console.return sensor.triggered console.detected siren.turnon siren.return console.disarm sensor.disable sensor.return siren.turnoff siren.return console.return sensor.disabled console.deactivated console.arm sensor.enable sensor.return console.return sensor.triggered console.detected siren.turnon siren.return'
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
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Reply.dzn | grep ^trace: | tr , '\n')


TRACE='i.done u.what u.Status_Ok i.Status_No foo bar baz'
RESULT='i.done u.what u.Status_Ok Invalid event: i.Status_No'
echo
echo running $TRACE
diff -u <(echo trace:$RESULT | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/R.dzn | grep -E '^(trace|Invalid event):' | tr '[, ]' '[\n\n]')

echo
echo running $TRACE
diff -u <(echo trace:$RESULT | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Reply.dzn | grep -E '^(trace|Invalid event):' | tr '[, ]' '[\n\n]')

echo
TRACE='p.e r.e r.a r.return p.a p.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/q.dzn | grep ^trace: | tr , '\n')

echo
TRACE='p.f r.e r.a r.return r.f r.b r.return p.a p.b p.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/q.dzn | grep ^trace: | tr , '\n')

TRACE='ctrl.hcalibrate robot.tcalibrate robot.tcalibrated robot.return ctrl.return'
echo
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/h.dzn | grep ^trace: | tr , '\n')

echo
TRACE='a a'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/ir2.dzn | grep ^trace: | tr , '\n')


echo
TRACE='p.e p.a p.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/q2.dzn | grep ^trace: | tr , '\n')

echo
TRACE='r.a r.a'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/q2.dzn | grep ^trace: | tr , '\n')

echo
TRACE='i.e i.f i.f i.f i.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/argument2.dzn | grep ^trace: | tr , '\n')

echo
TRACE='p.e p.a r.e r.a r.b r.return p.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/q3.dzn | grep ^trace: | tr , '\n')

echo
TRACE='p.start r.ping r.pong r.pong r.return p.busy p.finish p.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/reply_reorder.dzn | grep ^trace: | tr , '\n')

echo
TRACE='r.a p.a'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/RequiredOptional.dzn | grep ^trace: | tr , '\n')

echo
TRACE='console.arm sensor.enable sensor.return console.return sensor.triggered console.detected siren.turnon siren.return console.disarm sensor.disable sensor.return siren.turnoff siren.return console.return sensor.disabled console.deactivated console.arm sensor.enable sensor.return console.return sensor.triggered console.detected siren.turnon siren.return'
echo running $TRACE
diff -u <(echo trace:$TRACE|tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/Alarm.dzn | grep ^trace: | tr , '\n')

echo
TRACE='rpa.a rpa.b rpa.c rpa.d rpa.return rpa.e rpa.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/TauEmitMultiple.dzn | grep ^trace: | tr , '\n')

echo
TRACE='rps.a rps.c rps.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/TauEmitMultiple.dzn | grep ^trace: | tr , '\n')

echo
TRACE='rpa.a rpa.b rpa.c rpa.d rpa.return rpa.e rpa.return rps.a rps.c rps.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/TauEmitMultiple.dzn | grep ^trace: | tr , '\n')

echo
TRACE='ict.start src.req src.ntfA src.ntfB src.return src.ack src.return src.ack src.return src.done src.return ict.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/QTriggerModeling.dzn | grep ^trace: | tr , '\n')

echo
TRACE='ict.start src.req src.ntfA src.ntfB src.return src.ack src.return src.ack src.return src.done src.return ict.return ict.start src.reqValued src.ntfA src.ntfB src.EmitResult_Two src.ack src.return src.ack src.return src.done src.return ict.return'
echo running $TRACE
diff -u <(echo trace:$TRACE | tr ' ' '\n') <(dzn run --gaiag -t <(echo $TRACE) regression/QTriggerModeling.dzn | grep ^trace: | tr , '\n')
