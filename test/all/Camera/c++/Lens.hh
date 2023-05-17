// Dezyne --- Dezyne command line tools
//
// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
#ifndef LENS_HH
#define LENS_HH

struct Lens: public skel::Lens
{
  Lens (const dzn::locator &l)
    : skel::Lens (l)
  {}
  virtual void port_forward () {std::clog << "sut.optics.focus.lens.port.forward\n";}
  virtual void port_backward () {std::clog << "sut.optics.focus.lens.port.backward\n";}
  virtual void port_stop () {std::clog << "sut.optics.focus.lens.port.stop\n";}
};

#endif // LENS_HH
