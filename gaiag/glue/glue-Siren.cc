// Dezyne --- Dezyne command line tools
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

#include "Siren.hh"

#include "asdInterfaces.h"

#include "locator.h"
#include "runtime.h"

#include "SirenComponent.h"

#include <boost/make_shared.hpp>

#include <map>

namespace dezyne
{
  struct SingleThreaded
  : public asd::channels::ISingleThreaded
  {
    void processCBs(){}
  };

  static std::map<Siren*, boost::shared_ptr<ISirenInterface> > g_handwritten ;
}


Siren::Siren(const dezyne::locator& l)
  : rt (l.get<dezyne::runtime>())
{
  boost::shared_ptr<dezyne::ISirenInterface> component = dezyne::SirenComponent::GetInstance();
  boost::shared_ptr<dezyne::ISiren> api_siren;
  component->GetAPI(&api_siren);

  dezyne::g_handwritten.insert (std::make_pair (this,component));


  siren.in.turnon = dezyne::bind(&dezyne::ISiren::Turnon,api_siren);
  siren.in.turnoff = dezyne::bind(&dezyne::ISiren::Turnoff,api_siren);
}
