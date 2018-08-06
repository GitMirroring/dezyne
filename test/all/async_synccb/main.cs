// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

public static class main
{
    public static string read ()
    {
	string str = string.Empty;
	string line;
	while((line = System.Console.ReadLine()) != null) {
	    str += (string.IsNullOrEmpty(str) ? "" : "\n") + line;
	}
	return str;
    }

    public static int Main()
    {
	string trace = read ();

	dzn.Locator loc = new dzn.Locator();
	dzn.Runtime rt = new dzn.Runtime();
	using(dzn.pump pump = new dzn.pump()) {
	    async_synccb sut = new async_synccb(loc.set(rt).set(pump));
	    sut.dzn_meta.name = "sut";
	    sut.p.dzn_meta.requires.name = "p";

	    int t = 0;
	    sut.p.outport.cb1 = () => {System.Console.Error.WriteLine("sut.p.cb1 -> <external>.p.cb1 [" + t + "]");};
            sut.p.outport.cb2 = () => {System.Console.Error.WriteLine("sut.p.cb2 -> <external>.p.cb2 [" + t + "]");};

	    if (trace == "p.e\np.cb1\np.return\np.c\np.return") {
		pump.shell (() => {sut.p.inport.e ();sut.p.inport.c ();});
	    }
	    else if (trace == "p.e\np.cb1\np.return\np.cb2") {
		pump.shell (() => {sut.p.inport.e ();});
	    }
	    else if (trace == "p.c\np.return") {
		pump.shell (() => {sut.p.inport.c ();});
	    }
	    else {
		System.Console.Error.WriteLine("error: invalid trace: " + trace);
		return 1;
	    }
	    return 0;
	}
    }
}
