// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2017, 2018, 2019, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
// Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace dzn
{
  public class queue<T>:Queue<T>,IDisposable where T:IDisposable
  {
    public void Dispose()
    {
      foreach (T t in this) t.Dispose();
    }
  }

  public class pump : IDisposable
  {
    public static bool port_blocked_p(Locator loc, Object p)
    {
      dzn.pump pump = loc.try_get<pump>();
      if(pump != null)
          return pump.blocked_p(p);
      return false;
    }
    public static void port_block(Locator loc, Object c, Object p)
    {
      Runtime rt = loc.get<Runtime>();
      rt.states[c].handling = 0;
      rt.flush(c);
      var pump = loc.get<pump>();
      if(pump.skip_block.Remove(p)) return;

      var self = find_self(pump.coroutines);
      Debug.Assert(!rt.blocked_port_component_stack.ContainsKey(self.id)
                   || rt.blocked_port_component_stack[self.id].Count == 0);

      rt.blocked_port_component_stack[self.id] = rt.component_stack;
      rt.component_stack = new Stack<Object>();

      pump.block(rt, c, p);
    }

    public static void port_release(Locator loc, Object p, Action out_binding)
    {
      if(out_binding!=null) out_binding();
      out_binding = null;
      var pump = loc.get<pump>();
      pump.skip_block.Add(p);
      pump.release(loc.get<dzn.Runtime>(),p);
    }

    public static coroutine find_self(list<coroutine> coroutines)
    {
      var count = coroutines.FindAll(c => c.port == null && !c.finished).Count;
      Debug.WriteLine("#runnable coroutines: " + count);
      Debug.Assert(count != 0);
      Debug.Assert(count != 2);
      Debug.Assert(count < 3);
      Debug.Assert(count == 1);
      return coroutines.Find(c => c.port == null && !c.finished);
    }

    public static void remove_finished_coroutines(list<coroutine> coroutines)
    {
       coroutines.RemoveAll((c) => {
         if(!c.finished) return false;
         Debug.WriteLine("[" + c.id + "] removing");
         c.Dispose();
         return true;
         });
    }

    public struct Deadline: IComparable
    {
      public int id;
      public DateTime t;
      public int rank;
      public Deadline(int id, DateTime t, int rank)
      {
        this.id = id;
        this.t = t;
        this.rank = rank;
      }
      public bool expired()
      {
        return DateTime.Now >= t;
      }
      public int CompareTo(Object o)
      {
        Deadline d = (Deadline)o;
        if(rank == d.rank && t == d.t && id == d.id) return 0;
        if(rank < d.rank ||
           rank == d.rank && t < d.t ||
           rank == d.rank && t == d.t && id < d.id) return -1;
        return 1;
      }
    };
    public Action worker;
    public Dictionary<Deadline, Action> timers = new Dictionary<Deadline, Action>();
    public List<Action> switch_context = new List <Action>();
    public Action exit;
    public list<coroutine> coroutines = new list<coroutine>();
    public list<coroutine> collateral_blocked = new list<coroutine>();
    public List<Object> skip_block = new List<Object>();
    public Queue<Action> queue = new Queue<Action>();
    public bool running;
    public List<Object> unblocked = new List<Object>();
    public Thread task;

    public pump()
    {
      this.running = true;
      this.task = new Thread(this.run);
      this.task.Start();
    }
    ~pump()
    {
      Dispose(false);
    }
    protected virtual void Dispose(bool gc)
    {
      stop();
      if(gc) {
        this.collateral_blocked.Dispose();
        this.coroutines.Dispose();
      }
    }
    public void Dispose()
    {
      Dispose(true);
      GC.SuppressFinalize(this);
    }
    public void stop()
    {
      context.lck(this, () => {
          this.running = false;
          Monitor.Pulse(this);
          Monitor.Exit(this);
          this.task.Join();
        });
    }
    public void wait()
    {
      context.lck(this, () => {
          while(this.queue.Count != 0) {
            Monitor.Wait(this);
          }
        });
    }
    public void run()
    {
      try {
        this.worker = () => {
          context.lck(this, () => {
              if(this.queue.Count == 0) {
                Monitor.Pulse(this);
              }
              if(this.timers.Count == 0) {
                while(this.queue.Count == 0 && running) {
                  Monitor.Wait(this);
                }
              } else {
                IEnumerator<KeyValuePair<Deadline, Action>> t = timers.OrderBy(k => k.Key).GetEnumerator();
                t.MoveNext();
                bool timedout = false;
                TimeSpan wait = t.Current.Key.t - DateTime.Now;
                while(!timedout && this.queue.Count == 0 && running && wait.Ticks > 0) {
                  timedout = !Monitor.Wait(this, wait);
                }
              }

              if(this.queue.Count != 0) {
                Action f = this.queue.Dequeue();
                Monitor.Exit(this);
                f();
              }

              {
                IEnumerator<KeyValuePair<Deadline, Action>> t = timers.OrderBy(k => k.Key).GetEnumerator();
                while(timers.Count != 0 && t.MoveNext() && t.Current.Key.expired()) {
                  this.timers.Remove(t.Current.Key);
                  if(Monitor.IsEntered(this)) Monitor.Exit(this);
                  t.Current.Value();
                  Monitor.Enter(this);
                }
              }
            });
        };

        coroutine zero = new coroutine();
        this.exit = ()=>{Debug.WriteLine("enter exit"); zero.release();};
        create_context();

        context.lck(this, () => {
            while(this.running || this.queue.Count!=0 || this.collateral_blocked.Count!=0)
            {
              Monitor.Exit(this);
              Debug.Assert(this.coroutines.Count!=0);
              this.coroutines.Last().call(zero);
              Monitor.Enter(this);
              remove_finished_coroutines(this.coroutines);
            }
            Debug.WriteLine("finish pump");
            Debug.Assert(this.queue.Count==0);
          });
      }
      catch(Exception e) {
        Console.Error.WriteLine("oops: " + e);
        System.Environment.Exit(1);
      }
    }
    public void create_context()
    {
      this.coroutines.Add (new coroutine (() =>
        {
          try
          {
            coroutine self = find_self(this.coroutines);
            Debug.WriteLine("[" + self.id + "] create context");
            context_switch();
            while(this.running || this.queue.Count != 0)
            {
              worker();
              collateral_release(self);
              context_switch();
            }
            this.exit();
          }
          catch (forced_unwind) {
            Debug.WriteLine("ignoring forced_unwind");
          }
          catch (Exception e) {
            Console.Error.WriteLine("oops: " + e);
            System.Environment.Exit(1);
          }
        }));
    }
    public void context_switch()
    {
    if (switch_context.Count () != 0)
      {
        var context = this.switch_context[0];
        this.switch_context.RemoveAt(0);
        context();
      }
    }
    public static void collateral_block(Object c, dzn.Locator l)
    {
      l.get<dzn.pump>().collateral_block(c, l.get<dzn.Runtime>());
    }
    public void collateral_block(Object c, Runtime rt)
    {
      coroutine self = find_self(this.coroutines);
      Debug.WriteLine("[" + self.id + "] collateral_block");

      //splice
      this.collateral_blocked.Add(self);
      this.coroutines.Remove(self);

      self.component = c;
      Debug.Assert(self.port == null);
      foreach(var id in rt.blocked_port_component_stack.Keys)
        if(rt.blocked_port_component_stack[id].Contains(c))
        {
          int i = this.coroutines.FindIndex(o => o.id == id);
          self.port = this.coroutines[i].port;
        }
      Debug.Assert(self.port != null, "no port found associated to component " + c.GetHashCode());

      var v = rt.blocked_port_component_stack.ContainsKey(self.id)
            ? rt.blocked_port_component_stack[self.id]
            : new Stack<Object>();
      foreach(var o in v.ToArray().Reverse())
        rt.component_stack.Push(o);
      v.Clear();
      Debug.Assert(!rt.blocked_port_component_stack.ContainsKey(self.id)
                   || rt.blocked_port_component_stack[self.id].Count == 0);
      rt.blocked_port_component_stack[self.id] = rt.component_stack;
      rt.component_stack = v;

      create_context();
      self.yield_to(this.coroutines.Last());
      Debug.WriteLine("[" + self.id + "] collateral_unblock");

      v = rt.blocked_port_component_stack[self.id];
      foreach (var o in v.Reverse ())
        rt.component_stack.Push (o);
      rt.blocked_port_component_stack[self.id].Clear ();
    }
    public void collateral_release(coroutine self)
    {
      Debug.WriteLine("[" + self.id + "] collateral_release");

      Predicate<coroutine> predicate = (c) => {
        return this.unblocked.FindIndex(i => i == c.port) != -1;
      };

      int it = -1;
      do
      {
        it = this.collateral_blocked.FindIndex(predicate);
        if(it != -1)
        {
          Debug.WriteLine("collateral_unblocking: " + this.coroutines.Last().id
                          + " for port: " + unblocked.GetHashCode());
          //splice
          this.coroutines.Add(this.collateral_blocked[it]);
          this.collateral_blocked.RemoveAt(it);
          this.coroutines.Last().port = null;
          self.finished = true;
          self.yield_to(this.coroutines.Last());
        }
      }
      while(it != -1);

      if (collateral_blocked.FindIndex(predicate) == -1)
      {
        Debug.WriteLine("everything unblocked!!!");
        unblocked.Clear ();
      }
    }
    public bool blocked_p(Object p)
    {
      return this.coroutines.FindIndex(c => c.port == p) != -1;
    }
    public void block(Runtime rt, Object c, Object p)
    {
      coroutine self = find_self(this.coroutines);
      self.port = p;
      Debug.WriteLine("[" + self.id + "] block on " + p.GetHashCode());

      bool collateral_skip = collateral_release_skip_block(rt, c);
      if(!collateral_skip)
      {
        int it = this.collateral_blocked.FindIndex(i => this.unblocked.FindIndex(j => j == i.port) != -1);
        if(it != -1)
        {
          Debug.WriteLine("[" + this.collateral_blocked[it].id + "]"
                          + " move from " + this.collateral_blocked[it].port.GetHashCode()
                          + " to " + p.GetHashCode());
          this.collateral_blocked[it].port = p;
        }
        create_context();
      }

      self.yield_to(this.coroutines.Last());
      Debug.WriteLine("[" + self.id + "] entered context");
      Debug.Write("routines: ");
      foreach (coroutine r in this.coroutines){ Debug.Write(r.id + " ");}
      Debug.WriteLine("");

      remove_finished_coroutines(this.coroutines);
    }
    bool collateral_release_skip_block(Runtime rt, Object c)
    {
      bool have_collateral = false;
      this.collateral_blocked.Reverse();
      int it = 0;
      while(it < this.collateral_blocked.Count())
      {
        coroutine zelf = this.collateral_blocked[it++];
        if (this.unblocked.FindIndex(i => i == zelf.port) != -1
            && zelf.component == c)
        {
          Debug.WriteLine("[" + zelf.id + "]" + "relay skip "
                          + zelf.port.GetHashCode());
          //swap
          var v = rt.blocked_port_component_stack[zelf.id];
          rt.blocked_port_component_stack[zelf.id] = rt.component_stack;
          rt.component_stack = v;
          have_collateral = true;
          zelf.component = null;
          zelf.port = null;
          //splice
          this.coroutines.Add(zelf);
          this.collateral_blocked.Remove(zelf);
        }
      }
      collateral_blocked.Reverse();
      return have_collateral;
    }
    void release(Runtime rt, Object p)
    {
      coroutine self = find_self(this.coroutines);
      Debug.WriteLine("[" + self.id + "] release of " + p.GetHashCode());

      coroutine blocked = this.coroutines.Find(c => c.port == p);
      if(blocked == null)
      {
        if (self!=null) Debug.WriteLine("[" + self.id + "] skip block");
        this.skip_block.Add(p);
        return;
      }

      Debug.WriteLine("[" + blocked.id + "] unblock");

      this.switch_context.Add (() => {
        var zelf = find_self(this.coroutines);
        Debug.WriteLine("setting unblocked to port " + blocked.port.GetHashCode());
        this.unblocked.Add(blocked.port);
        blocked.component = null;
        blocked.port = null;

        Debug.WriteLine("[" + zelf.id + "] switch from");
        Debug.WriteLine("[" + blocked.id + "] to");

        Debug.Assert(rt.component_stack.Count == 0);

        if(p == null) Console.Error.WriteLine("null port");
        if(!rt.blocked_port_component_stack.ContainsKey(blocked.id))
          Console.Error.WriteLine("id " + blocked.id + " not found");

        //swap
        var v = rt.blocked_port_component_stack[blocked.id];
        rt.blocked_port_component_stack[blocked.id] = rt.component_stack;
        rt.component_stack = v;

        zelf.finished = true;
        zelf.yield_to(blocked);
        Debug.Assert(false, "we must never return here!!!");
        });
    }
    public void execute(Action e)
    {
      Debug.Assert(e != null);
      context.lck(this, () => {
          this.queue.Enqueue(e);
          Monitor.Pulse(this);
        });
    }
    public void handle(int id, int ms, Action e)
    {
      handle(id, ms, e, int.MaxValue);
    }
    public void handle(int id, int ms, Action e, int rank)
    {
      Debug.Assert(this.timers.Where(kv => kv.Key.id == id).Count() == 0);
      this.timers.Add(new Deadline(id, DateTime.Now.AddMilliseconds(ms), rank), e);
    }
    public void remove(int id)
    {
      if(this.timers.Count() != 0) {
        this.timers.Remove(this.timers.Where(kv => kv.Key.id == id).SingleOrDefault().Key);
      }
    }
    public class promise: IDisposable
    {
      Barrier barrier;
      public promise()
      {
        barrier = new Barrier(2);
      }
      ~promise()
      {
        Dispose();
      }
      public void Dispose()
      {
        if(barrier != null) {
          barrier.Dispose();
          barrier = null;
        }
      }
      public void set()
      {
        barrier.SignalAndWait();
      }
      public void get()
      {
        barrier.SignalAndWait();
      }
    }
    public class promise<T>: promise
    {
      T value;
      public promise(): base()
      {}
      public void set(T value)
      {
        this.value = value;
        base.set();
      }
      public new T get()
      {
        base.get();
        return value;
      }
    }
    public void shell(Action e)
    {
      using(promise p = new promise()) {
        this.execute(()=>{e(); p.set();});
        p.get();
      }
    }
    public T shell<T>(Func<T> e)
    {
      using(promise<T> p = new promise<T>()) {
        this.execute(()=>{p.set(e());});
        return p.get();
      }
    }
  }
}
