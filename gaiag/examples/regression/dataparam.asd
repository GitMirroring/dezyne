// Gaiag --- Guile in Asd In Asd in Guile.
// Copyright © 2014 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2014 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

interface idataparam
{
  extern xint = $int$;
  enum Status {Yes, No};

  in void e0;
  in Status e0r;
  in void e (in xint i);
  in Status er (in xint i);
  in Status eer (in xint i, in xint j);

  in void eo(out xint i);
  in void eoo(out xint i, out xint j);
  in void eio(in xint i, out xint j);
  in void eio2(inout xint i);

  in Status eor(out xint i);
  in Status eoor(out xint i, out xint j);
  in Status eior(in xint i, out xint j);
  in Status eio2r(inout xint i);

  out void a0;
  out void a (in xint i);
  out void aa (in xint i, in xint j);
  out void a6 (in xint a0,in xint a1,in xint a2,in xint a3,in xint a4,in xint a5);

  behaviour
  {
    on e0: a6;
    on e0r: {a0;reply(Status.Yes);}
    on e:
    {
      a;
      aa;
    }
    on er:
    {
      a;
      aa;
      reply(Status.No);
    }
    on eer:
    {
      a;
      aa;
      reply(Status.No);
    }
    on eo:{}
    on eoo:{}
    on eio:{}
    on eio2:{}

    on eor: { reply(Status.Yes); }
    on eoor: { reply(Status.Yes); }
    on eior: { reply(Status.Yes); }
    on eio2r: { reply(Status.Yes); }
  }
}

component dataparam
{
  provides idataparam port;

  behaviour
  {
    idataparam.xint mi = $0$;
    idataparam.Status s = idataparam.Status.Yes;

    idataparam.Status fun ()
    {
      return idataparam.Status.Yes;
    }

    idataparam.Status funx (xint xi)
    {
      return idataparam.Status.Yes;
    }

    xint xfunx (xint xi, xint xj)
    {
      return $(xi + xj) / 3$;
    }

    on port.e0: { port.a6($0$,$1$,$2$,$3$,$4$,$5$); }

    on port.e0r: {port.a0;reply(idataparam.Status.Yes);}

    on port.e (pi):
    {
      idataparam.Status s = funx (pi);
      mi = pi;
      mi = xfunx (pi, $pi + mi$);
      port.a (mi);
      port.aa (mi, pi);

      // idataparam.Status s = e0r();
      // s = e0r();
    }
    on port.er (pi):
    {
      idataparam.Status s = idataparam.Status.No;
      mi = pi;
      port.a (mi);
      port.aa (mi, pi);
      reply(s);
    }
    on port.eer (i,j):
    {
      idataparam.Status s = idataparam.Status.No;
      port.a (j);
      port.aa (j, i);
      reply(s);
    }
    on port.eo(i): { i = $234$; }
    on port.eoo(i,j): { i = $123$; j = $456$; }
    on port.eio(i,j): { j = i; }
    on port.eio2(i): { i = $i + 123$; }

    on port.eor(i): { i = $234$; reply(idataparam.Status.Yes); }
    on port.eoor(i,j): { i = $123$; j = $456$; reply(idataparam.Status.Yes); }
    on port.eior(i,j): { j = i; reply(idataparam.Status.Yes); }
    on port.eio2r(i): { i = $i + 123$; reply(idataparam.Status.Yes); }
  }
}

component proxy
{
  provides idataparam top;
  requires idataparam bottom;

  behaviour
  {
    on top.e0: bottom.e0;
    on top.e0r: {idataparam.Status r = bottom.e0r; reply(r);}
    on top.e(pi): bottom.e(pi);
    on top.er(pi): {idataparam.Status r = bottom.er(pi); reply(r);}
    on top.eer(i,j): {idataparam.Status r = bottom.eer(i,j); reply(r);}

    on top.eo(i): { bottom.eo(i); }
    on top.eoo(i,j): { bottom.eoo(i,j); }
    on top.eio(i,j): { bottom.eio(i,j); }
    on top.eio2(i): { bottom.eio2(i); }

    on top.eor(i): { idataparam.Status s = bottom.eor(i); reply(s); }
    on top.eoor(i,j): { idataparam.Status s = bottom.eoor(i,j); reply(s); }
    on top.eior(i,j): { idataparam.Status s = bottom.eior(i,j); reply(s); }
    on top.eio2r(i): { idataparam.Status s = bottom.eio2r(i); reply(s); }

    on bottom.a0: top.a0;
    on bottom.a6(A0,A1,A2,A3,A4,A5): top.a6(A0,A1,A2,A3,A4,A5);
    on bottom.a(i): top.a(i);
    on bottom.aa(i,j): top.aa(i,j);
  }
}

component datasystem
{
  provides idataparam port;
  system
  {
    proxy p;
    dataparam c;

    p.top <=> port;
    c.port <=> p.bottom;
  }
}
