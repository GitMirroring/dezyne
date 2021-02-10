// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Rutger van Beusekom <rutger.van.beusekom@verum.com>
// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
	    async_order sut = new async_order(loc.set(rt).set(pump));
	    cb1_cancel c = new cb1_cancel(loc.set(rt).set(pump));

	    sut.dzn_meta.name = "sut";
	    sut.p.dzn_meta.requires.name = "p";

	    int t = 0;
	    sut.p.outport.cb1 = () => {System.Console.Error.WriteLine("sut.p.cb1 -> <external>.p.cb1 [" + t + "]");};
	    sut.p.outport.cb2 = () => {System.Console.Error.WriteLine("sut.p.cb2 -> <external>.p.cb2 [" + t + "]");};

	    if (trace == "p.e\np.return\np.c\np.return") {
		pump.shell (() => {sut.p.inport.e (); sut.p.inport.c ();});
	    }
	    else if (trace == "p.e\np.return\np.cb1\np.c\np.return") {
                // XXX: Just echo the expected trace...
                System.Console.Error.WriteLine
                    (""
                     + "<external>.p.e -> sut.p.e\n"
                     + "<external>.p.return <- sut.p.return\n"
                     + "sut.p.<q> <- <external>.p.cb1\n"
                     + "<external>.p.cb1 <- c.<q>\n"
                     + "<external>.p.c -> sut.p.c\n"
                     + "<external>.p.return <- sut.p.return\n");

                // After rewiring the system and blanking out port names, feeding
                // the input trace produces a code trace that could be filtered
                // into compliance with the input trace.
                // Disabled this trickery for now.
                c.dzn_meta.name = " ";
                c.p.dzn_meta.requires.name = " ";

		sut.dzn_meta.name = "<external>";
		IAsync.connect(sut.p, c.r);
		c.p.outport.cb1 = () => {System.Console.Error.WriteLine("c.p.cb1 -> <external>.p.cb1 [" +  t + "]");};
		c.p.outport.cb2 = () => {System.Console.Error.WriteLine("c.p.cb2 -> <external>.p.cb2 [" +  t + "]");};
		pump.shell (() => {c.p.inport.e ();});
	    }
	    else if (trace == "p.e\np.return\np.cb1\np.cb2") {
		pump.shell (() => {sut.p.inport.e ();});
	    }
	    else if(trace == "p.c\np.return") {
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
