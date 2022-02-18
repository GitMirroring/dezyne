#! /bin/sh
# Dezyne --- Dezyne command line tools
#
# Copyright © 2020, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2021 Rutger van Beusekom <rutger@dezyne.org>
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

echo "* semantics"

echo
echo "** direct_in"
./pre-inst-env dzn simulate test/all/direct_in/direct_in.dzn -t p.a,r.a,r.return,p.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** direct_out"
./pre-inst-env dzn simulate test/all/direct_out/direct_out.dzn -t r.a,p.a | ./pre-inst-env dzn trace --format=diagram

echo
echo "** indirect_out"
./pre-inst-env dzn simulate test/all/indirect_out/indirect_out.dzn -t p.a,r.a,r.b,r.return,p.b,p.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** indirect_in"
./pre-inst-env dzn simulate test/all/indirect_in/indirect_in.dzn -t r.a,r.b,r.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** direct_multiple_out1"
./pre-inst-env dzn simulate test/all/direct_multiple_out1/direct_multiple_out1.dzn -t r.a,r.b,p.a,p.b  | ./pre-inst-env dzn trace --format=diagram

echo
echo "** direct_multiple_out2"
./pre-inst-env dzn simulate test/all/direct_multiple_out2/direct_multiple_out2.dzn -t r.a,r.b,p.a,p.b | ./pre-inst-env dzn trace --format=diagram

echo
echo "** indirect_multiple_out1"
./pre-inst-env dzn simulate test/all/indirect_multiple_out1/indirect_multiple_out1.dzn -t p.a,r1.a,r1.b,r1.return,r2.a,r2.b,r2.return,p.b,p.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** indirect_multiple_out2"
./pre-inst-env dzn simulate test/all/indirect_multiple_out2/indirect_multiple_out2.dzn -t p.a,r1.a,r1.b,r1.return,r2.a,r2.b,r2.return,p.b,p.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** indirect_multiple_out3"
./pre-inst-env dzn simulate test/all/indirect_multiple_out3/indirect_multiple_out3.dzn -t p.a,r1.a,r1.b,r1.return,r2.a,r2.b,r2.return,p.b,p.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** indirect_blocking_out"
./pre-inst-env dzn simulate test/all/indirect_blocking_out/indirect_blocking_out.dzn -t p.a,r.a,r.return,r.b,p.b,p.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** external_multiple_out1"

./pre-inst-env dzn simulate test/all/external_multiple_out1/external_multiple_out1.dzn -t p.e,r.e,r.return,p.return,r.a,p.a,r.b,p.b | ./pre-inst-env dzn trace --format=diagram

echo
echo "** external_multiple_out2"
./pre-inst-env dzn simulate test/all/external_multiple_out2/external_multiple_out2.dzn -t p.e,r.e,r.return,p.return,r.a,r.b,p.a,p.b  | ./pre-inst-env dzn trace --format=diagram

echo
echo "** external_multiple_out3"
./pre-inst-env dzn simulate test/all/external_multiple_out3/external_multiple_out3.dzn -t p.e,r.e,r.return,p.return,r.a,r.b,p.a,p.b  | ./pre-inst-env dzn trace --format=diagram

echo
echo "** indirect_blocking_multiple_external_out"
./pre-inst-env dzn simulate test/all/indirect_blocking_multiple_external_out/indirect_blocking_multiple_external_out.dzn -t p.a,r1.a,r1.return,r2.a,r2.return,r1.b,p.b,r2.b,p.return | ./pre-inst-env dzn trace --format=diagram

echo
echo "** system_hello"
./pre-inst-env dzn simulate test/all/system_hello/system_hello.dzn -t h.hello | ./pre-inst-env dzn trace --format=diagram --internal

echo
echo "** hello_system"
./pre-inst-env dzn simulate test/all/hello_system/hello_system.dzn -t p.hello,r.false | ./pre-inst-env dzn trace --format=diagram --internal
