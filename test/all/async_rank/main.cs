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
	    async_rank sut = new async_rank(loc.set(rt).set(pump));
	    sut.dzn_meta.name = "sut";
	    sut.p.dzn_meta.requires.name = "p";
	    sut.r.dzn_meta.provides.name = "r";

            dzn.RuntimeHelper.apply(sut.dzn_meta, (m) => {
                    System.Console.WriteLine
                    ((m.parent != null ? m.parent.name : "null")
                     + " " + m.name + " " + m.rank);});

	    sut.p.outport.f = () => {System.Console.Error.WriteLine("sut.p.f -> <external>.p.f");};
	    sut.p.outport.g = () => {System.Console.Error.WriteLine("sut.p.g -> <external>.p.g");};
	    sut.r.inport.e = () => {
                System.Console.Error.WriteLine("sut.r.e -> <external>.r.e");
                System.Console.Error.WriteLine("<external>.r.return -> sut.r.return");
            };

            pump.shell (() => {sut.p.inport.e ();});
            pump.shell (() => {sut.r.outport.f ();});
            pump.shell (() => {sut.r.outport.g ();});
	    return 0;
	}
    }
}
