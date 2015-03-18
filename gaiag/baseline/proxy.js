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

dezyne.proxy = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.reply_IDataparam_Status = null;

  this.top = new dezyne.IDataparam({provides: {name: 'top', component: this}, requires: {}});
  this.bottom = new dezyne.IDataparam({provides: {}, requires: {name: 'bottom', component: this}});

  this.top.in.e0 = function() {
    runtime.call_in(this, function() {
      this.bottom.in.e0();
    }.bind(this), [this.top, 'e0']);
  }.bind(this);
  this.top.in.e0r = function() {
    return runtime.call_in(this, function() {
      {
        var r = {value: this.bottom.in.e0r()};
        this.reply_IDataparam_Status = r.value;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.top, 'e0r', this.top.Status_to_string]);
  }.bind(this);
  this.top.in.e = function(i) {
    runtime.call_in(this, function() {
      {
        var pi = {value: i};
        this.bottom.in.e(pi.value);
      }
    }.bind(this), [this.top, 'e']);
  }.bind(this);
  this.top.in.er = function(i) {
    return runtime.call_in(this, function() {
      {
        var pi = {value: i};
        {
          var r = {value: this.bottom.in.er(pi.value)};
          this.reply_IDataparam_Status = r.value;
        }
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.top, 'er', this.top.Status_to_string]);
  }.bind(this);
  this.top.in.eer = function(i,j) {
    return runtime.call_in(this, function() {
      {
        var r = {value: this.bottom.in.eer(i, j)};
        this.reply_IDataparam_Status = r.value;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.top, 'eer', this.top.Status_to_string]);
  }.bind(this);
  this.top.in.eo = function(i) {
    runtime.call_in(this, function() {
      {
        this.outfunc(i);
      }
    }.bind(this), [this.top, 'eo']);
  }.bind(this);
  this.top.in.eoo = function(i,j) {
    runtime.call_in(this, function() {
      {
        this.bottom.in.eoo(i, j);
      }
    }.bind(this), [this.top, 'eoo']);
  }.bind(this);
  this.top.in.eio = function(i,j) {
    runtime.call_in(this, function() {
      {
        this.bottom.in.eio(i, j);
      }
    }.bind(this), [this.top, 'eio']);
  }.bind(this);
  this.top.in.eio2 = function(i) {
    runtime.call_in(this, function() {
      {
        this.bottom.in.eio2(i);
      }
    }.bind(this), [this.top, 'eio2']);
  }.bind(this);
  this.top.in.eor = function(i) {
    return runtime.call_in(this, function() {
      {
        var s = {value: this.bottom.in.eor(i)};
        this.reply_IDataparam_Status = s.value;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.top, 'eor', this.top.Status_to_string]);
  }.bind(this);
  this.top.in.eoor = function(i,j) {
    return runtime.call_in(this, function() {
      {
        var s = {value: this.bottom.in.eoor(i, j)};
        this.reply_IDataparam_Status = s.value;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.top, 'eoor', this.top.Status_to_string]);
  }.bind(this);
  this.top.in.eior = function(i,j) {
    return runtime.call_in(this, function() {
      {
        var s = {value: this.bottom.in.eior(i, j)};
        this.reply_IDataparam_Status = s.value;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.top, 'eior', this.top.Status_to_string]);
  }.bind(this);
  this.top.in.eio2r = function(i) {
    return runtime.call_in(this, function() {
      {
        var s = {value: this.bottom.in.eio2r(i)};
        this.reply_IDataparam_Status = s.value;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.top, 'eio2r', this.top.Status_to_string]);
  }.bind(this);
  this.bottom.out.a0 = function() {
    runtime.call_out(this, function() {
      this.top.out.a0();
    }.bind(this), [this.bottom, 'a0']);
  }.bind(this);
  this.bottom.out.a = function(i) {
    runtime.call_out(this, function() {
      this.deferfunc(i);
    }.bind(this), [this.bottom, 'a']);
  }.bind(this);
  this.bottom.out.aa = function(i,j) {
    runtime.call_out(this, function() {
      this.top.out.aa(i, j);
    }.bind(this), [this.bottom, 'aa']);
  }.bind(this);
  this.bottom.out.a6 = function(a0,a1,a2,a3,a4,a5) {
    runtime.call_out(this, function() {
      {
        var A0 = {value: a0};
        var A1 = {value: a1};
        var A2 = {value: a2};
        var A3 = {value: a3};
        var A4 = {value: a4};
        var A5 = {value: a5};
        this.top.out.a6(A0.value, A1.value, A2.value, A3.value, A4.value, A5.value);
      }
    }.bind(this), [this.bottom, 'a6']);
  }.bind(this);
  this.outfunc = function (i) {
    var j = {value: i.value};
    this.bottom.in.eo(j);
    i.value = j.value;
  }.bind(this);
  this.deferfunc = function (i) {
    this.top.out.a(i);
  }.bind(this);

};
