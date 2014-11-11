// Gaiag --- Guile in Asd In Asd in Guile.
//
// This file is part of Gaiag.
//
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

interface alotareplies
{
  enum Reply {A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10};//, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, A41, A42, A43, A44, A45, A46, A47, A48, A49, A50, A51, A52, A53, A54, A55, A56, A57, A58, A59, A60, A61, A62, A63, A64, A65, A66, A67, A68, A69, A70, A71, A72, A73, A74, A75, A76, A77, A78, A79, A80, A81, A82, A83, A84, A85, A86, A87, A88, A89, A90, A91, A92, A93, A94, A95, A96, A97, A98, A99, A100};

  in Reply e;

  behaviour
  {
    on e: reply(Reply.A0);
  }
}


component nested
{
  provides alotareplies p;
  requires alotareplies r;
  behaviour
  {
    /*
    enum State {E1,E2,E3,E4};
    State state = State.E1;
    bool b0 = false;
    bool b1 = false;
    bool b2 = false;
    bool b3 = false;
    bool b4 = false;
    bool b5 = false;
    bool b6 = false;
    bool b7 = false;
    bool b8 = false;
    bool b9 = false;
*/
    void f(alotareplies.Reply a)
    {
      a = r.e;
      f2(a);
    }
    void f2(alotareplies.Reply a)
    {
      a = r.e;
      f3(a);
    }
    void f3(alotareplies.Reply a)
    {
      a = r.e;
      //f4(a);
    }
    /*
    void f4(alotareplies.Reply a)
    {
      alotareplies.Reply a = r.e;
      f5(a);
    }
    void f5(alotareplies.Reply a)
    {
    }
    */
    on p.e:
    {
      alotareplies.Reply a = r.e;
      f(a);
      reply(a);
    }
  }
}
