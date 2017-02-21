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

namespace dzn
{
    class list<T>:List<T>,IDisposable where T:IDisposable
        {
            public void Dispose()
            {
                foreach (T t in this) t.Dispose();
            }
        }

    public class coroutine : IDisposable
    {
        public static int g_id;
        public int id;
        
        public context context;
        public Action<context> yield;

        public Object port;
        public bool finished;
        public bool released;
        public bool skip_block;
        public coroutine(Action worker)
        {
            this.id = coroutine.g_id++;
            this.context = new context ((yield) => {
                    this.yield = yield;
                    worker();
                });
            this.yield = (c) => {};
            this.port = null;
            this.finished = false;
            this.released = false;
            this.skip_block = false;
        }
        public coroutine()
        {
            this.id = -1;
            this.context = new context (false);
            this.yield = (c) => {};
        }
        public void Dispose()
        {
            this.context.Dispose();
            this.context = null;
        }
        public void yield_to(coroutine c)
        {
            this.yield(c.context);
        }
        public void call(coroutine c)
        {
            this.context.call(c.context);
        }
        public void release()
        {
            this.context.release();
        }
    };
}
