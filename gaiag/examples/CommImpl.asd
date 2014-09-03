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

import Comm0;
import Comm1;
import Comm2;

component CommImpl
{
  provides Comm0 api;
  requires Comm1 inst1;
  requires Comm2 inst2;
  
  behaviour
  {
    enum State { S, S1, S2 };
    State s = State.S;
    
    [s.S]  { on api.send0:     { inst1.send1;      s = State.S1; }
             on inst1.receive1
              , inst2.receive2: { illegal;                       }
           }
    [s.S1] { on api.send0:      { illegal;                       }
             on inst1.receive1: { inst2.send2;     s = State.S2; }
             on inst2.receive2: { illegal;                       }
           }
    [s.S2] { on api.send0:      { illegal;                       }
             on inst1.receive1: { illegal;                       }
             on inst2.receive2: { api.receive0;     s = State.S; }
           }
  }
  
}
