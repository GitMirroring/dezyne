# Dezyne --- Dezyne command line tools
#
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

#!/bin/bash -e

CONFIG=${1-localhost}
DZN=${DZN-../client/bin/dzn}

if bunyan --version; then
BUNYAN="bunyan --no-color -l 30"
else
BUNYAN=cat
fi

function setup()
{
    trap "teardown" 1 2 3 15 ERR EXIT
    rm -rf out/$$
    mkdir out/$$
}

function teardown()
{
    [ -n "$(jobs -p)" ] && kill $(jobs -p) || :
    rm -rf out/$$
}


setup
$DZN cat /share/examples/Alarm.dzn > out/$$/Alarm.dzn

XPID=$(bash -c 'echo $PPID')
for k in $(seq 5); do
    ( (diff -uw <(cat <<EOF
verify: Alarm: check: illegal: fail
console.arm
sensor.enable
sensor.return
console.return
sensor.triggered
console.detected
siren.turnon
siren.return
console.disarm
sensor.disable
sensor.return
console.return
sensor.disabled
console.deactivated
console.arm
sensor.enable
sensor.return
console.return
sensor.triggered
console.detected
siren.turnon
illegal
EOF
) <($DZN verify -m Alarm out/$$/Alarm.dzn) || kill -9 $XPID; ) &
    for j in $(seq 10); do
        (for i in $(seq 2); do
            $DZN hello &>/dev/null&
        done
    wait)
            done
        wait)
done
