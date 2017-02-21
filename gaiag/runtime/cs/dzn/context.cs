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
using System.Reflection;
using System.Threading;
using System.Diagnostics;

namespace dzn
{
    public class runtime_error : SystemException {
        public runtime_error(String msg) : base(msg) {}
    }
    public class logic_error : runtime_error {
        public logic_error(String msg) : base(msg) {}
    }
    public class context : IDisposable
    {
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

        public class unwind: runtime_error
        {
            public unwind(): base("unwind") {}
        };

        State state;
        Action rel;
        Action<Action<context>> work;
        System.Threading.Thread thread;
        public context()
        {
            this.state = State.INITIAL;
            this.work = (y) => {};
            this.thread = new System.Threading.Thread
                (() => {
                    //System.Console.Error.WriteLine("[" + this.get_id() + "] create");
                    try
                        {
                            System.Threading.Monitor.Enter(this);
                            while(state != State.FINAL)
                                {
                                    //System.Console.Error.WriteLine("[" + this.get_id() + "] context01");
                                    do_block(this);
                                    //System.Console.Error.WriteLine("[" + this.get_id() + "] context02");
                                    if(state == State.FINAL) break;
                                    if(this.work == null) break;
                                    System.Threading.Monitor.Exit(this);
                                    Action<context> yield = (c) => {this.yield(c);};
                                    System.Diagnostics.Debug.Assert(yield != null);
                                    this.work(yield);
                                    System.Threading.Monitor.Enter(this);
                                    if(state == State.FINAL) break;
                                    if(this.rel != null) this.rel();
                                }
                            System.Threading.Monitor.Exit(this);
                        }
                    catch(unwind){}
                });
            this.thread.Start();
            //System.Console.Error.WriteLine("[" + this.get_id() + "] context1");
            System.Threading.Monitor.Enter(this);
            //System.Console.Error.WriteLine("[" + this.get_id() + "] context2");
            while(state != State.BLOCKED) System.Threading.Monitor.Wait(this);
            System.Threading.Monitor.Exit(this);
        }
        public context(bool b)
        {
        }
        public context(Action<Action<context>> work) : this ()
        {
            this.work = work;
        }
        ~context()
        {
            //System.Console.Error.WriteLine("[" + this.get_id() + "] ~context0");
            Dispose(false);
        }
        protected virtual void Dispose(bool gc)
        {
            if (gc)
                {
                    System.Threading.Monitor.Enter(this);
                    do_finish(this);
                    rel = null;
                    work = null;
                    thread = null;
                }
        }
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }
        public int get_id()
        {
            return System.Threading.Thread.CurrentThread.ManagedThreadId;
        }
        public void finish()
        {
            System.Threading.Monitor.Enter(this);
            do_finish(this);
        }
        public void block()
        {
            System.Threading.Monitor.Enter(this);
            do_block(this);
            System.Threading.Monitor.Exit(this);
        }
        public void release()
        {
            System.Threading.Monitor.Enter(this);
            do_release(this);
            System.Threading.Monitor.Exit(this);
        }
        public void call(context c)
        {
            //System.Console.Error.WriteLine("[" + this.get_id() + "] call");
            System.Threading.Monitor.Enter(this);
            do_release(this);

            System.Threading.Monitor.Enter(c);
            c.state = State.BLOCKED;

            System.Threading.Monitor.Exit(this);

            do { System.Threading.Monitor.Wait(c); } while(c.state == State.BLOCKED);
            System.Threading.Monitor.Exit(c);
        }
        public void yield(Action <Action<context>> work, context c)
        {
            System.Threading.Monitor.Enter(this);
            this.work = work;
            this.rel = () => {c.release();};
            do_release(this);

            System.Threading.Monitor.Enter(c);
            c.state = State.BLOCKED;

            System.Threading.Monitor.Exit(this);

            do { System.Threading.Monitor.Wait(c); } while(c.state == State.BLOCKED);
            System.Threading.Monitor.Exit(c);
        }
        public void yield(context to)
        {
            if(to == this) return;
            System.Threading.Monitor.Enter(this);
            to.release();
            do_block(this);
            System.Threading.Monitor.Exit(this);
        }
        private void do_block(Object mutex)
        {
            state = State.BLOCKED;
            System.Threading.Monitor.Pulse(this);
            //System.Console.Error.WriteLine("[" + this.get_id() + "] do_block0");
            do { System.Threading.Monitor.Wait(mutex); } while(state == State.BLOCKED);
            //System.Console.Error.WriteLine("[" + this.get_id() + "] do_block1");
            if(state == State.FINAL) throw new unwind();
        }
        private void do_release(Object mutex)
        {
            if(state != State.BLOCKED)
                throw new runtime_error("not allowed to release a call which is "
                                        + to_string(state));
            state = State.RELEASED;
            //System.Console.Error.WriteLine("[" + this.get_id() + "] do_release0");
            System.Threading.Monitor.Pulse(this);
            //System.Console.Error.WriteLine("[" + this.get_id() + "] do_release1");
        }
        private void do_finish(Object mutex)
        {
            //System.Console.Error.WriteLine("[" + this.get_id() + "] finish0");
            state = State.FINAL;
            System.Threading.Monitor.PulseAll(this);
            System.Threading.Monitor.Exit(mutex);
            this.thread.Join();
        }
    };
}
