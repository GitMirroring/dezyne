// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
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

//OM: OM-parser says: not well-formed

// Gaiag: interface mangle
interface Mangle
{
  in void mangle;
  out void mingle;
  
  behaviour mangle
  {
    //OM:  bool mangle = false;
    bool b = false;
    //OM:  bool mangle (bool mingle) { mingle; return mingle || mangle; }
    bool mangle (bool m) { mingle; return m || b; }

    [true]
      on mangle:
      {
        //OM:  mangle = ! mangle;
        b = ! b;
        
        //OM:  bool mangle = mangle (mangle);
        //OM:  bool b = mangle (b);
        
        //OM:  if (mangle)
        if (b)
        {
          mingle;
        }
      }
  }
}

component mangle
{
  //Gaiag: provides mangle mangle;
  provides Mangle mangle;
  
  behaviour mangle
  {
    bool mangle = false;
    bool mangle (bool mingle) { mangle.mingle; return mangle; }

    [true]
      on mangle.mangle:
      {
        mangle = ! mangle;
        bool mangle = mangle (mangle);
        
        if (mangle)
        {
          mangle.mingle;
        }
      }
  }
}
