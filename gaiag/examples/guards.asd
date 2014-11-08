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

interface i
{
  in void e;
  out void a;
  behaviour
    {
      enum S { init, idle, busy };
      S s = S.init;
      bool b = true;
      bool bb = true;

      [s.idle]
        [bb]
        {
          [b]
            on e:
            {
              a;
              s = S.busy;
            }
          [!b]
            on e:
            {
            }
        }
      [s.busy]
        [true]
        on e:
        [!b]
        {
          a;
          s = S.init;
        }
      [s.init && (b || !b)]
        {
          [!bb]
            {
              on e:
                [true]
                [b]
              {
                a;
                s = S.idle;
              }
            }
          [bb]
            {
              on e:
                [true]
                [b]
              {
                a;
                s = S.idle;
              }
            }
        }
    }
}
