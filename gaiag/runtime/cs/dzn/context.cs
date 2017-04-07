// Dezyne --- Dezyne command line tools
//
// Copyright © 2017 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

using System;
using System.Reflection;
using System.Threading;
using System.Diagnostics;
using System.Collections.Generic;

namespace dzn
{
  public class runtime_error : SystemException {
    public runtime_error(String msg) : base(msg) {}
  }
  public class logic_error : runtime_error {
    public logic_error(String msg) : base(msg) {}
  }
  public class forced_unwind: runtime_error
  {
    public forced_unwind(): base("forced_unwind") {}
  };
  public class context : IDisposable
  {
    static Dictionary<int,int> m = new Dictionary<int,int>();

    enum State {INITIAL, RELEASED, BLOCKED, FINAL};
    String to_string(State state)
    {
      switch(state)
      {
      case State.INITIAL: return "INITIAL";
      case State.RELEASED: return "RELEASED";
      case State.BLOCKED: return "BLOCKED";
      case State.FINAL: return "FINAL";
      }
      throw new logic_error("UNKNOWN STATE");
    }

    State state;
    Action rel;
    Action<Action<context>> work;
    Thread thread;
    public context()
    {
      this.state = State.INITIAL;
      this.work = null;
      this.thread = new Thread(() =>
        {
          try
          {
            Debug.WriteLine("[" + this.get_id() + "] create");
            lock(this) {
              while(this.state != State.FINAL)
              {
                do_block(this);
                if(this.state == State.FINAL) break;
                if(this.work == null) break;
                Monitor.Exit(this);
                this.work((c) => {this.yield(c);});
                Monitor.Enter(this);
                if(state == State.FINAL) break;
                if(this.rel != null) this.rel();
              }
            }
          }
          catch (forced_unwind) {
            Debug.WriteLine("[" + this.get_id() + "] ignoring forced_unwind");
          }
        });
      this.thread.Start();
      lock(this) {
        while(state != State.BLOCKED) Monitor.Wait(this);
      }
    }
    public context(bool b)
    {
    }
    public context(Action<Action<context>> work) : this ()
    {
      lock(this) {
        this.work = work;
      }
    }
    ~context()
    {
      Dispose(false);
    }
    protected virtual void Dispose(bool gc)
    {
      if (gc)
      {
        lock(this)
        {
          do_finish(this);
          rel = null;
          work = null;
          thread = null;
        }
      }
    }
    public void Dispose()
    {
      Dispose(true);
      GC.SuppressFinalize(this);
    }
    public int get_id()
    {
      lock(m) {
        int i = Thread.CurrentThread.ManagedThreadId;
        if (!m.ContainsKey(i)) m.Add(i,m.Count);
        return m[i];
      }
    }
    public void finish()
    {
      lock(this) {
        do_finish(this);
      }
    }
    public void block()
    {
      lock(this) {
        do_block(this);
      }
    }
    public void release()
    {
      lock(this) {
        do_release(this);
      }
    }
    public void call(context c)
    {
      Debug.WriteLine("[" + this.get_id() + "] call");
      lock(this) {
        do_release(this);

        Monitor.Enter(c);
        c.state = State.BLOCKED;
      }

      do { Monitor.Wait(c); } while(c.state == State.BLOCKED);
      Monitor.Exit(c);
    }
    public void yield(context to)
    {
      if(to == this) return;
      lock(this) {
        to.release();
        do_block(this);
      }
    }
    private void do_block(Object mutex)
    {
      state = State.BLOCKED;
      Monitor.Pulse(this);
      Debug.WriteLine("[" + this.get_id() + "] do_block0");
      do { Monitor.Wait(mutex); } while(state == State.BLOCKED);
      Debug.WriteLine("[" + this.get_id() + "] do_block1");
      if(state == State.FINAL) throw new forced_unwind();
    }
    private void do_release(Object mutex)
    {
      if(state != State.BLOCKED)
        throw new runtime_error("[" + this.get_id() + "] not allowed to release a call which is "
                                + to_string(state));
      state = State.RELEASED;
      Debug.WriteLine("[" + this.get_id() + "] do_release0");
      Monitor.Pulse(mutex);
      Debug.WriteLine("[" + this.get_id() + "] do_release1");
    }
    private void do_finish(Object mutex)
    {
      Debug.WriteLine("[" + this.get_id() + "] finish0");
      state = State.FINAL;
      Monitor.PulseAll(this);
      Monitor.Exit(mutex);
      System.Diagnostics.Debug.Assert(this.thread != null);
      this.thread.Join();
    }
  };
}
