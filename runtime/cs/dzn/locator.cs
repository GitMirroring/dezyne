// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2017, 2018, 2019 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

namespace dzn {
    public class Locator {
        public class Services : Dictionary<String, Object> {public Services(){}public Services(Services o):base(o) {}};
        Services services;
        public Locator():this(new Services()) {}
        public Locator(Services services) {this.services = services;}
        public static String key(Type c, String key) {
            return c.Name + key;
        }
        public static String key(Object o, String key) {
            return Locator.key(o.GetType(), key);
        }
        public Locator set(Object o, String key="") {
            services[Locator.key(o,key)] = o;
            return this;
        }
        public R get<R>(String key="") {
            return (R)services[Locator.key(typeof(R), key)];
        }
        public Locator clone() {return new Locator(new Services(services));}
    }
}
