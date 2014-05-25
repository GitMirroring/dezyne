// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Gaiag.
//
// Gaiag is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Gaiag is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Gaiag.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

import CommImpl;
import Comm1Impl;
import Comm2Impl;

component CommSystem
{
  provides Comm0 prv;
  
  CommSystem()
  {
    CommImpl cccc = CommImpl();
    Comm1Impl cmm1 = Comm1Impl();
    Comm2Impl cmm2 = Comm2Impl();
    prv <=> cccc.api;
    cccc.inst1 <=> cmm1.prv;
    cccc.inst2 <=> cmm2.prv; 
  }
}

