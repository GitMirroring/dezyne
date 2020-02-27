// dzn-runtime -- Dezyne runtime library
//
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

if (!Array.prototype.each) {
  Array.prototype.each = Array.prototype.forEach;
};

var sexp = {
  EOF:-1
  ,
  nil: {car:0,cdr:0}
  ,
  dot: {car:'.',cdr:0}
  ,
  cons: function (car, cdr) {
    return {car:car,cdr:cdr}
  }
  ,
  read_char: function () {return sexp.EOF;}
  ,
  unread_char: function (c) {return c;}
  ,
  read_sexp: function (c, s) {
    if (c == ' ') return sexp.read_sexp ('\n', s);
    if (!s)
    {
      if (c == sexp.EOF) return sexp.nil;
      if (c == '\n') return sexp.read_sexp (sexp.read_char (), s);
      if (c == '(') return sexp.read_list (sexp.read_char ());
      if (c == ')') {sexp.unread_char (c); return sexp.nil;}
    }
    else
    {
      if (c == '\n' && s === '.') return sexp.dot;
      if (c == sexp.EOF) return sexp.lookup (s);
      if (c == '\n') return sexp.lookup (s);
      if (c == '(') {sexp.unread_char (c); return sexp.lookup (s);};
      if (c == ')') {sexp.unread_char (c); return sexp.lookup (s);}
    }
    return sexp.read_sexp (sexp.read_char (), sexp.append (s, c));
  }
  ,
  eat_whitespace: function (c) {
    while (c == ' ' || c == '\n') c = sexp.read_char ();
    return c;
  }
  ,
  read_list: function (c) {
    c = sexp.eat_whitespace (c);
    if (c == ')') return sexp.nil;
    s = sexp.read_sexp (c, 0);
    if (s == sexp.dot) return sexp.read_list (sexp.read_char ()).car;
    return sexp.cons (s, sexp.read_list (sexp.read_char ()));
  }
  ,
  lookup: function (s) {
    return sexp.cons (s, 0);
  }
  ,
  append: function (s, c) {
    return (s || '') + c;
  }
  ,
  read: function () {
    return sexp.read_sexp (sexp.read_char (), 0);
  }
  ,
  read_from_string: function (string) {
    var pos = 0;
    sexp.read_char = function () {return pos < string.length ? string[pos++] : sexp.EOF;}
    sexp.unread_char = function (c) {pos--;return c;}
    return sexp.read ();
  }
  ,
  display_helper:function (x, cont, sep, print) {
    print (sep);
    if (x == sexp.nil)
      ;
    else if (x.cdr)
    {
      if (!cont) print ('(');
      sexp.display (x.car, print);
      if (x.cdr && x.cdr.cdr)
        sexp.display_helper (x.cdr, 1, ' ', print);
      else
      {
        if (x.cdr != sexp.nil)
          print (' . ');
        sexp.display (x.cdr, print);
      }
      if (!cont) print (')');
    }
    else
      print (x.car);

    return sexp.nil;
  }
  ,
  display: function (x, print) {
    print = print || process.stdout.write.bind (process.stdout);
    return sexp.display_helper (x, 0, '', print);
  }
  ,
  sexp_to_list: function (s) {
    var list = [];
    while (s && s != sexp.nil)
    {
      list.push (s.car);
      s = s.cdr;
    }
    return list;
  }
  ,
  sexp_to_string: function (s) {
    if (!s.cdr) return s.car;
    if (s.cdr == sexp.nil) return s.car.car;
    return s.car.car + '.' + sexp.sexp_to_string (s.cdr);
  }
  ,
  sexp_to_alist: function (s) {
    var alist = {};
    while (s != sexp.nil) {
      alist[sexp.sexp_to_string (s.car.car)] = sexp.sexp_to_string (s.car.cdr);
      s = s.cdr;
    }
    return alist;
  }
};
if (typeof module !== 'undefined') {
  module.exports = sexp;
}
