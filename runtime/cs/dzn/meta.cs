// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
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

namespace dzn
{
  public class Meta
  {
    public String name;
    public Meta parent;
    public int rank;
    public List<port.Meta> requires;
    public List<Meta> children;
    public List<Action> ports_connected;

    public Meta(String name = "", Meta parent = null, List<port.Meta> requires = null, List<Meta> children = null, List<Action> ports_connected = null)
    {
      this.name = name;
      this.parent = parent;
      this.rank = 0;
      this.requires = requires;
      this.children = children;
      this.ports_connected = ports_connected;
    }
  }

  namespace port
  {
    public class Meta
    {
      public class Provides
      {
        public String name = null;
        public Component component;
        public dzn.Meta meta = new dzn.Meta();
      }
      public Provides provides = new Provides();
      public class Requires
      {
        public String name = null;
        public Component component;
        public dzn.Meta meta = new dzn.Meta();
      }
      public Requires requires = new Requires();
    }
  }

  public static class MetaHelper
  {
    public static string path(Meta m, string p = "")
    {
      p = string.IsNullOrEmpty(p) ? p : "." + p;
      if (m == null) return "<external>" + p;
      if (m.parent == null) return m.name + p;
      return path(m.parent, m.name + p);
    }
    public static void rank(dzn.Meta m, int r)
    {
      if(null != m && m.requires != null) {
      	m.rank = Math.Max(m.rank, r);
	foreach (var i in m.requires) {
	  MetaHelper.rank(i.provides.meta, m.rank + 1);
	}
      }
    }
  }

  public class binding_error : Exception
  {
    public binding_error(port.Meta m, string msg)
      : base("not connected: " + MetaHelper.path(m.provides.component != null ? m.provides.meta : m.requires.meta,
                                                 m.provides.component != null ? m.provides.name : m.requires.name) + "." + msg)
    {}
  }
}
