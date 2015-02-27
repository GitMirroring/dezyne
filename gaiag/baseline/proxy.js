// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

dezyne.proxy = function() {
  this.reply_IDataparam_Status = null;

  this.top = new dezyne.IDataparam();
  this.bottom = new dezyne.IDataparam();

  this.top.in.e0 = function() {
    console.log('proxy.top_e0');
    this.bottom.in.e0();
  }.bind(this);
  this.top.in.e0r = function() {
    console.log('proxy.top_e0r');
    {
      var r = this.bottom.in.e0r();
      this.reply_IDataparam_Status = r;
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.top.in.e = function(i) {
    console.log('proxy.top_e');
    {
      var pi = i;
      this.bottom.in.e(pi);
    }
  }.bind(this);
  this.top.in.er = function(i) {
    console.log('proxy.top_er');
    {
      var pi = i;
      {
        var r = this.bottom.in.er(pi);
        this.reply_IDataparam_Status = r;
      }
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.top.in.eer = function(i,j) {
    console.log('proxy.top_eer');
    {
      var r = this.bottom.in.eer(i, j);
      this.reply_IDataparam_Status = r;
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.top.in.eo = function(i) {
    console.log('proxy.top_eo');
    {
      this.outfunc(i.value);
    }
  }.bind(this);
  this.top.in.eoo = function(i,j) {
    console.log('proxy.top_eoo');
    {
      this.bottom.in.eoo(i.value, j.value);
    }
  }.bind(this);
  this.top.in.eio = function(i,j) {
    console.log('proxy.top_eio');
    {
      this.bottom.in.eio(i, j.value);
    }
  }.bind(this);
  this.top.in.eio2 = function(i) {
    console.log('proxy.top_eio2');
    {
      this.bottom.in.eio2(i.value);
    }
  }.bind(this);
  this.top.in.eor = function(i) {
    console.log('proxy.top_eor');
    {
      var s = this.bottom.in.eor(i);
      this.reply_IDataparam_Status = s;
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.top.in.eoor = function(i,j) {
    console.log('proxy.top_eoor');
    {
      var s = this.bottom.in.eoor(i, j);
      this.reply_IDataparam_Status = s;
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.top.in.eior = function(i,j) {
    console.log('proxy.top_eior');
    {
      var s = this.bottom.in.eior(i, j);
      this.reply_IDataparam_Status = s;
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.top.in.eio2r = function(i) {
    console.log('proxy.top_eio2r');
    {
      var s = this.bottom.in.eio2r(i);
      this.reply_IDataparam_Status = s;
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.bottom.out.a0 = function() {
    console.log('proxy.bottom_a0');
    this.top.out.a0.defer();
  }.bind(this);
  this.bottom.out.a = function(i) {
    console.log('proxy.bottom_a');
    this.deferfunc(i);
  }.bind(this);
  this.bottom.out.aa = function(i,j) {
    console.log('proxy.bottom_aa');
    this.top.out.aa.defer(i, j);
  }.bind(this);
  this.bottom.out.a6 = function(a0,a1,a2,a3,a4,a5) {
    console.log('proxy.bottom_a6');
    {
      var A0 = a0;
      var A1 = a1;
      var A2 = a2;
      var A3 = a3;
      var A4 = a4;
      var A5 = a5;
      this.top.out.a6.defer(A0, A1, A2, A3, A4, A5);
    }
  }.bind(this);
  this.outfunc = function (i.value) {
    var j = i.value;
    this.bottom.in.eo(j);
    i.value = j;
  }.bind(this);
  this.deferfunc = function (i) {
    this.top.out.a.defer(i);
  }.bind(this);

};
