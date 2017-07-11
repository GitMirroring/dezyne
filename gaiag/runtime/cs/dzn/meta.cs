// Dezyne --- Dezyne command line tools
//
// Copyright © 2016 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017 Jvaneerd <J.vaneerd@student.fontys.nl>
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
using System.Collections.Generic;

namespace dzn
{
  public class Meta
  {
    public String name;
    public Meta parent;
    public List<port.Meta> requires;
    public List<Meta> children;
    public List<Action> ports_connected;

		public Meta(String name = "", Meta parent = null, List<port.Meta> requires = null, List<Meta> children = null, List<Action> ports_connected = null)
    {
      this.name = name;
      this.parent = parent;
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

  public static class MetaHelper //Static helper class required: methods are not allowed in namespace in C#
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
      : base("not connected: " + MetaHelper.path(m.provides.component != null ? m.provides.meta : m.requires.meta,
                                                 m.provides.component != null ? m.provides.name : m.requires.name) + "." + msg)
    {}
  }
}
