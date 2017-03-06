// Dezyne --- Dezyne command line tools
//
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

//#define DEBUG
// -*-java-*-
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Collections.Generic;

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
    public static void port_block(Locator loc, Object p)
    {
      loc.get<pump>().block(p);
    }

    public static void port_release(Locator loc, Object p, Action out_binding)
    {
      if(out_binding!=null) out_binding();
      out_binding = null;
      loc.get<pump>().release(p);
    }

    public static coroutine find_self(list<coroutine> coroutines)
    {
      return coroutines.Find(c => c.port == null && !c.finished);
    }

    public static void finish(list<coroutine> coroutines)
    {
      coroutine self = find_self(coroutines);
      self.finished = true;
      Debug.WriteLine("[" + self.id + "] finish coroutine");
    }

    public Action worker;
    public Action next_event;
    public Action switch_context;
    public Action collateral_block_lambda;
    public Action exit;
    public list<coroutine> coroutines = new list<coroutine>();
    public list<coroutine> collateral_blocked = new list<coroutine>();
    public List<Object> skip_block = new List<Object>();
    public Queue<Action> queue = new Queue<Action>();
    public bool running;
    public Thread task;

    public pump()
    {
      this.collateral_block_lambda = () => {collateral_block();};
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
      if (gc)
      {
        lock(this) {
          this.running = false;
          Monitor.Pulse(this);
        }
        this.task.Join();

        this.worker = null;
        this.next_event = null;
        this.switch_context = null;
        this.collateral_block_lambda = null;
        this.exit = null;
        this.coroutines.Dispose();
        this.coroutines = null;
        this.collateral_blocked.Dispose();
        this.collateral_blocked = null;
        this.skip_block = null;
        this.queue = null;
        this.task = null;
      }
    }
    public void Dispose()
    {
      Dispose(true);
      GC.SuppressFinalize(this);
    }

    public void run()
    {
      this.worker = () => {
        lock(this) {
          if(this.queue.Count!=0) {
            Action f = this.queue.Dequeue();
            Monitor.Exit(this);
            f();
          }
        }
      };
      try {
        coroutine zero = new coroutine();
        create_context();

        this.exit = ()=>{Debug.WriteLine("enter exit"); zero.release();};

        lock(this) {
          while(this.running || this.queue.Count!=0 || this.collateral_blocked.Count!=0)
          {
            Monitor.Exit(this);
            Debug.Assert(this.coroutines.Count!=0);

            this.coroutines.Last().call(zero);

            Monitor.Enter(this);
            this.coroutines.RemoveAll((c) => {
                if(!c.finished) return false;
                Debug.WriteLine("[" + c.id + "] removing");
                c.Dispose();
                return true;
              });
          }
          Debug.WriteLine("finish pump");
          Debug.Assert(this.queue.Count==0);
        }
      } catch(Exception e) {
        Console.Error.WriteLine("oops: " + e);
        System.Environment.Exit(1);
      }
    }
    public coroutine create_context()
    {
      this.coroutines.Add
      (new coroutine
       (()=>{
         try
         {
           coroutine self = find_self(this.coroutines);
           Debug.WriteLine("[" + self.id + "] create context");
           while((this.running || this.queue.Count != 0) && !self.released)
           {
             worker();
             if(!self.released) collateral_release(self);
           }
           if(self.released) finish(this.coroutines);
           if(this.switch_context != null) {
             Action switch_context = this.switch_context;
             this.switch_context = null;
             switch_context();
           }
           if(!self.released) collateral_release(self);

           this.exit();
         }
         catch (context.unwind) {}
         catch(Exception e) {
           Console.Error.WriteLine("oops: " + e);
           System.Environment.Exit(1);
         }
       }));
      return this.coroutines.Last();
    }
    public void collateral_block()
    {
      coroutine self = find_self(this.coroutines);
      Debug.WriteLine("[" + self.id + "] collateral_block");
      this.collateral_blocked.Add(self);
      this.coroutines.Remove(self);
      create_context();
      self.yield_to(coroutines.Last());
      Debug.WriteLine("[" + self.id + "] collateral_unblock");
    }
    public void collateral_release(coroutine self)
    {
      if(this.collateral_blocked.Count != 0) finish(coroutines);
      while(this.collateral_blocked.Count != 0) {
        this.coroutines.Add(this.collateral_blocked[0]);
        this.collateral_blocked.RemoveAt(0);
        self.yield_to(this.coroutines.Last());
      }
    }
    public void block(Object p)
    {
      int skip = this.skip_block.FindIndex(o => o == p);
      if(skip != -1) {
        this.skip_block.RemoveAt(skip);
        return;
      }

      coroutine self = find_self(this.coroutines);
      self.port = p;
      Debug.WriteLine("[" + self.id + "] block");
      create_context();
      self.yield_to(this.coroutines.Last());
      Debug.WriteLine("[" + self.id + "] entered context");
      Debug.Write("routines: ");
      foreach (coroutine c in this.coroutines){ Debug.Write(c.id + " ");}
      Debug.WriteLine("");

      this.coroutines.RemoveAll((c) => {
          if(!c.finished) return false;
          Debug.WriteLine("[" + c.id + "] removing");
          c.Dispose();
          return true;
        });
    }
    void release(Object p)
    {
      coroutine self = find_self(this.coroutines);
      coroutine blocked = this.coroutines.Find(c => c.port == p);
      if(blocked == null)
      {
        if (self!=null) Debug.WriteLine("[" + self.id + "] skip block");
        this.skip_block.Add(p);
        return;
      }

      Debug.WriteLine("[" + blocked.id + "] unblock");
      Debug.WriteLine("[" + self.id + "] released");
      self.released = true;

      this.switch_context = () => {
        blocked.port = null;
        Debug.WriteLine("[" + self.id + "] switch from");
        Debug.WriteLine("[" + blocked.id + "] to");
        self.yield_to(blocked);
      };
    }
    public void execute(Action e)
    {
      Debug.Assert(e!=null);
      lock(this) {
        this.queue.Enqueue(e);
        Monitor.Pulse(this);
      }
    }
    public void blocking(Action e)
    {
      Task promise = new Task(e);
      this.execute(() => {promise.RunSynchronously();});
      promise.Wait();
    }
    public T blocking<T>(Func<T> e)
    {
      Task<T> promise = new Task<T>(e);
      this.execute(()=>{promise.RunSynchronously();});
      promise.Wait();
      return promise.Result;
    }
    // public void handle(size_t id, size_t ms, const std::function<void()>& e)
    // {
    //     assert(e);
    //     assert(std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; }) == timers.end());
    //     timers.emplace(deadline(id, ms), e);
    // }
    // public void remove(size_t id)
    // {
    //     auto it = std::find_if(timers.begin(), timers.end(), [id](const std::pair<deadline, std::function<void()>>& p){ return p.first.id == id; });
    //     if(it != timers.end()) timers.erase(it);
    // }
  }
}
