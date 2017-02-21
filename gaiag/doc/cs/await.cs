// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
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

// -*-java-*-
using System;
using System.Collections.Generic;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;

public class test {
    public async Task c1(Task o)
    {
        //await Task.Delay (0);
        Task t;
        //System.Console.Error.WriteLine("c1: " + MethodBase.GetCurrentMethod().Name);
        Console.WriteLine("1.0");
        t = Task.Delay (0);
        o = this.c0 (t);
        await o;
        Console.WriteLine("1.1");
    }
    public async Task c0(Task o)
    {
        //Task t;
        //System.Console.Error.WriteLine("c0: " + MethodBase.GetCurrentMethod().Name + ": " + i);
        Console.WriteLine("0.0");
        //t = Task.Delay (0);
        Task p2;
        p2 = this.c1 (p2);
        Console.WriteLine("0.1");
        await o;
    }
}

class main {
    public static int Main(String[] args) {
        test t0 = new test ();
        Task t;
        t = Task.Delay (0);
        t = t0.c1 (t);
        t0.c0 (t).Wait ();

        Console.WriteLine("daar");
        return 0;
    }
}
