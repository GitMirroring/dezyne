// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

dezyne.Dataparam = function() {
  this.mi = 0;
  this.s = new dezyne.IDataparam().Status.Yes;
  this.reply_IDataparam_Status = null;

  this.port = new dezyne.IDataparam();

  this.port.in.e0 = function() {
    console.log('Dataparam.port_e0');
    this.port.out.a6.defer(0, 1, 2, 3, 4, 5);
  }.bind(this);
  this.port.in.e0r = function() {
    console.log('Dataparam.port_e0r');
    this.port.out.a0.defer();
    this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.port.in.e = function(i) {
    console.log('Dataparam.port_e');
    {
      var pi= i;
      var s = this.funx(pi);
      s = s;
      this.mi = pi;
      this.mi = this.xfunx(pi, pi + pi);
      this.port.out.a.defer(this.mi);
      this.port.out.aa.defer(this.mi, pi);
    }
  }.bind(this);
  this.port.in.er = function(i) {
    console.log('Dataparam.port_er');
    {
      var pi= i;
      var s = new dezyne.IDataparam().Status.No;
      this.mi = pi;
      this.port.out.a.defer(this.mi);
      this.port.out.aa.defer(this.mi, pi);
      if(true) {
        this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
      }
      else {
        this.reply_IDataparam_Status = s;
      }
    }
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.port.in.eer = function(i,j) {
    console.log('Dataparam.port_eer');
    var s = new dezyne.IDataparam().Status.No;
    this.port.out.a.defer(j);
    this.port.out.aa.defer(j, i);
    this.reply_IDataparam_Status = s;
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.port.in.eo = function(i) {
    console.log('Dataparam.port_eo');
    i.value = 234;
  }.bind(this);
  this.port.in.eoo = function(i,j) {
    console.log('Dataparam.port_eoo');
    i.value = 123;
    j.value = 456;
  }.bind(this);
  this.port.in.eio = function(i,j) {
    console.log('Dataparam.port_eio');
    j.value = i;
  }.bind(this);
  this.port.in.eio2 = function(i) {
    console.log('Dataparam.port_eio2');
    var t = i.value;
    i.value = t + 123;
  }.bind(this);
  this.port.in.eor = function(i) {
    console.log('Dataparam.port_eor');
    i.value = 234;
    this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.port.in.eoor = function(i,j) {
    console.log('Dataparam.port_eoor');
    i.value = 123;
    j.value = 456;
    this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.port.in.eior = function(i,j) {
    console.log('Dataparam.port_eior');
    j.value = i;
    this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.port.in.eio2r = function(i) {
    console.log('Dataparam.port_eio2r');
    var t = i.value;
    i.value = t + 123;
    this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
    return this.reply_IDataparam_Status;
  }.bind(this);
  this.fun = function () {
    return new dezyne.IDataparam().Status.Yes;
  }.bind(this);
  this.funx = function (xi) {
    xi = xi;
    return new dezyne.IDataparam().Status.Yes;
  }.bind(this);
  this.xfunx = function (xi, xj) {
    return (xi + xj) / 3;
  }.bind(this);

};
