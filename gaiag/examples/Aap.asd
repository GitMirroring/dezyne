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

interface Aap
{
  enum AapValues {yes, no};

  in AapValues is_aap;
}

component Noot
{
  provides Aap aap;
  
  behaviour
  {
    enum State {S1, S2};
    State S = State.S1;
    
    /*
    void f(aap.AapValues a)
    {
      S = State.S2;
    }
  
    State g(bool b)
    {
      reply(State.S1);
    }
    */
    on aap.is_aap:
    {
      S = State.S2;
      /*
      if (true)
        S = State.S1;
      */
      /*
      if (true)
      {
        if (true)
        {
          reply(aap.AapValues.yes);
        }
      }
      else
      {
        f(aap.AapValues.no);
        g(true);
        //reply(aap.AapValues.no);
      }
      */
    }
  }
}
