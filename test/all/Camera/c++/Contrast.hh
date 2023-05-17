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
#ifndef CONTRAST_HH
#define CONTRAST_HH

struct Contrast: public skel::Contrast
{
  Contrast (const dzn::locator &l)
    : skel::Contrast (l)
  {}
  virtual ::IContrast::EContrast::type port_measure () {std::clog << "measure\n"; return ::IContrast::EContrast::Blurrier;}
};

#endif // CONTRAST_HH
