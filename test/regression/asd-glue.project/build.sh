# Dezyne --- Dezyne command line tools
#
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

#!/bin/bash -ex

development=~/development.git
file=$1

if [ "$(basename $(pwd))" == "asd-glue.project" ]; then
    file=AlarmSystem.dm
else
    ln -sf $development/test/regression/asd-glue.project/GlobalTypes.dzn .
    ln -sf $development/test/regression/asd-glue.project/query .
    ln -sf $development/test/regression/asd-glue.project/globals.h .
fi

dm=$(readlink -f $file)
model=$(basename $file .dm)

if [ -z "$model" ]; then
    exit 1
fi
rm -rf ./$model
mkdir $model

rm -f $model.true $model.false
function cleanup () {
    result=$?
    trap EXIT
    if [ $result -eq 0 ]; then
        echo $model:OK
        touch ../$model.dm.done
    else
        echo $model:FAIL
        touch ../$model.dm.fail
    fi
    exit $result
}

cd $model

ln -s ../GlobalTypes.dzn .
ln -s ../globals.h .
ln -s ../query .

trap cleanup EXIT

touch Generic.h
asdgenerate -v 9.2.0 -r -l cpp -o .
rm asdMultiThreaded.cpp
touch asdConfig.h
asdgenerate -v 9.2.0 -l cpp -o . -a $dm
sed -i 's/^\(\s*VoidReply\)/\1 = -1/' *Interface.h
pairs=$(xsltproc query ../$model.dm | grep -v 'xml' | tr -d , | grep -v  '^$' | sed -r -e 's,^ *([^: ]*)[: ]*([^: ]*),-e s/\1Component/\2Component/g,g')
sed -i -e '' $pairs *Component.cpp
dzn convert -m -o . $dm
for i in $(grep -E -o '(provides|requires) I[^ ]*' ${model}Comp.dzn | sed -re 's,.*(provides|requires) ,,' | sort -u); do
    sed -i -e "s,\b$i\b,dzn.$i,g" ${model}Comp.dzn
done
sed -i -e "s,import dzn[.],import ,g" ${model}Comp.dzn
sed -i \
    -e 's,// Language *: asd.*,import GlobalTypes.dzn;\n,'\
    -e 's/^interface /interface dzn./' \
    *.dzn
for f in $(ls -1 I*.dzn | grep -v Comp.dzn); do
    b=$(basename $f .dzn)
    $development/build/generate -l scm $f
    $development/build/gaiag -l c++ $b.scm; mv dzn_$b.hh $b.hh
    #dzn code -l c++ $f
done
$development/build/generate -l scm ${model}Comp.dzn
$development/build/gaiag -l c++ ${model}Comp.scm
$development/build/gaiag -l c++ --glue=asd -m ${model}Comp ${model}Comp.scm
ln -s $development/gaiag/runtime/c++/* .

mkdir -p asml
mkdir -p CNXA
mkdir -p DTXA
mkdir -p LOTD
mkdir -p LOxWH
mkdir -p PLXA
mkdir -p WPxCHUCK

touch asml/asml.h
touch CNXA/CNXAtyp.h
touch DTXA/DTXA.h
touch DTXA/DTXAtyp.h
touch GenericFacilities.h
touch Generic.h
touch LOPW_process_elem_id.h
touch LOPW_types.h
touch LOPWxJIT_intern_diagtyp.h
touch LOPWxLotSettings.h
touch LOTD/LOTDtyp.h
touch LOxWH/LOxWHtyp.h
touch PLXA/PLXAtimestamp.h
touch WPxCHUCK/WPxCHUCKtyp.h

sed -ri \
    -e 's,^#include "[A-Z]{4}.*[.]h",//\0,'\
    *Interface.h

sed -ri \
    -e 's,^#include "([^"]*)_wrapperComponent[.]h",#include "\1Component.h",'\
    -e 's,_wrapperComponent,Component,g'\
     ${model}Component.cpp

(cd ..
 clang++ -include $model/globals.h -DASD_HAVE_CONFIG_H -Wall -Wextra -Wno-unused-parameter -pthread -std=c++11 $model/*.cpp $model/*.cc -o $model/test)
dzn traces -q 7 -f -m ${model}Comp ${model}Comp.dzn
for f in *.trace.*; do ./test --flush < $f |& diff -uw $f -; done
