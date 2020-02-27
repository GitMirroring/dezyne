// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2017, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017, 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Reflection;

namespace dzn
{
  public class list<T>: List<T>, IDisposable where T: IDisposable
  {
    public list() : base() {}
    public list(IEnumerable<T> b)
    {
      foreach (T t in b) this.Add(t);
    }
    public void Dispose()
    {
      foreach (T t in this) t.Dispose();
    }
  }

  public class coroutine : IDisposable
  {
    public int id;

    public context context;
    public Action<context> yield;

    public Object port;
    public bool finished;
    public bool released;
    public bool skip_block;
    public coroutine(Action worker)
    {
      this.id = -2;
      this.yield = null;
      this.port = null;
      this.finished = false;
      this.released = false;
      this.skip_block = false;

      this.context = new context ((yield) => {
          this.id = context.get_id();
          this.yield = yield;
          worker();
        });
    }
    public coroutine()
    {
      this.id = -1;
      this.context = new context (false);
      this.yield = null;
    }
    public void Dispose()
    {
      if(this.context != null) {
        this.context.Dispose();
        this.context = null;
      }
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
