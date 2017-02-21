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

class main {
    public static int Main(String[] args) {

        //System.Console.Error.WriteLine("[" + System.Threading.Thread.CurrentThread.ManagedThreadId + "] hello");
        
        dzn.coroutine zero = new dzn.coroutine();
        using (dzn.list<dzn.coroutine> coroutines = new dzn.list<dzn.coroutine>())
            {
                coroutines.Add
                    (new dzn.coroutine (() =>
                        {
                            System.Console.Error.WriteLine("1.0");
                            coroutines[0].yield_to(coroutines[1]);
                            System.Console.Error.WriteLine("1.1");
                            coroutines[0].yield_to(coroutines[1]);
                        }));
                coroutines.Add
                    (new dzn.coroutine (() =>
                        {
                            System.Console.Error.WriteLine("0.0");
                            coroutines[1].yield_to(coroutines[0]);
                            System.Console.Error.WriteLine("0.1");
                            coroutines[1].yield_to(coroutines[0]);
                            zero.release();
                        }));

                coroutines[1].call(zero);
            }
        return 0;
    }
}
