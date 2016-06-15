# Dezyne --- Dezyne command line tools
#
# Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#!/bin/bash -xe

trap 'kill $(jobs -p)' EXIT

pidof node && killall node
cd ~/development
rm -f build/dzn-*
make dzn-client
DEZYNE_PREFIX=~/development/build/prefix server/main.js --debug --config=localhost &> build/server.log&
rm -rf ~/.npm
npm install -g https://hosting.verum.com/download/npm/dzn-1.3.0.tar.gz
npm install -g https://hosting.verum.com/download/npm/dzn-daemon-0.0.3.tar.gz
echo root | ~/.npm/bin/dzn -d -u root -p -s http://localhost:3000 hello
[ "$(npm list -g --parseable --long dzn-daemon | grep -oE '@[0-9]\.[0-9]\.[0-9]:')" = "@0.0.4:" ] && \
    [ "$(~/.npm/bin/dzn hello)" = "hello" ] && \
    ~/.npm/bin/dzn kill
