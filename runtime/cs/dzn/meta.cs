// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2016, 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
// Copyright © 2017, 2018, 2019, 2021 Rutger van Beusekom <rutger@dezyne.org>
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
    public List<port.Meta> require;
    public List<Meta> children;
    public List<Action> ports_connected;

    public Meta(String name = "", Meta parent = null, List<port.Meta> require = null, List<Meta> children = null, List<Action> ports_connected = null)
    {
      this.name = name;
      this.parent = parent;
      this.require = require;
      this.children = children;
      this.ports_connected = ports_connected;
    }
  }

  namespace port
  {
    public class Meta
    {
      public class Provide
      {
        public String name = null;
        public Port port;
        public Component component;
        public dzn.Meta meta = new dzn.Meta();
      }
      public Provide provide = new Provide();
      public class Require
      {
        public String name = null;
        public Port port;
        public Component component;
        public dzn.Meta meta = new dzn.Meta();
      }
      public Require require = new Require();
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
  }

  public class binding_error : Exception
  {
    public binding_error(port.Meta m, string msg)
      : base("not connected: " + MetaHelper.path(m.provide.component != null ? m.provide.meta : m.require.meta,
                                                 m.provide.component != null ? m.provide.name : m.require.name) + "." + msg)
    {}
  }
}
