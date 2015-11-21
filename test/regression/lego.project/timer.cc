// Dezyne --- Dezyne command line tools
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#include "timer.hh"

#include "locator.hh"
#include "runtime.hh"

#include "itimer_impl.hh"

#include <functional>
#include <memory>

timer::timer(const dezyne::locator& l)
  : dzn_meta{"","timer",0,{},{}}
  , dzn_rt(l.get<dezyne::runtime>())
  , dzn_locator(l)
  , port{{{"in",this},{"",0}}}
  {
    dzn_meta.ports_connected.push_back([this]{port.check_bindings();});
    port.meta.provides.port = "port";
    port.meta.provides.address = this;

    dezyne::locator tmp(l.clone());
    tmp.set(port);
    auto pimpl = l.get<std::function<std::shared_ptr<itimer_impl>(const dezyne::locator&)>>()(tmp);
#ifdef TEST_EVENT
    port.out.timeout = [] {std::clog << "timeout" << std::endl;};
#endif
    port.in.create = [=](int ms){dezyne::trace_in(std::clog, port.meta, "create"); pimpl->create(ms); dezyne::trace_out(std::clog, port.meta, "return");};
    port.in.cancel = [=]{dezyne::trace_in(std::clog, port.meta, "cancel"); pimpl->cancel(); dezyne::trace_out(std::clog, port.meta, "return"); };
  }
