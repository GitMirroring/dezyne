#! /bin/sh

# Dezyne --- Dezyne command line tools
#
# Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

sed -i                                                          \
    -e s,johri.van.eerd[@]verum.com,vaneerd.johri@gmail.com,gi  \
    -e s,paul.hoogendijk[@]verum.com,paul@dezyne.org,gi         \
    -e s,rob.wieringa[@]verum.com,rob@dezyne.org,gi             \
    -e s,rutger.van.beusekom[@]gmail.com,rutger@dezyne.org,gi   \
    -e s,rutger.van.beusekom[@]verum.com,rutger@dezyne.org,gi   \
    $(git grep -l @verum.com)

git grep @verum.com
