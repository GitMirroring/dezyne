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

dezyne.Dataparam = function(rt, meta) {
  this.rt = rt;
  this.meta = meta;
  this.mi = 0;
  this.s = new dezyne.IDataparam().Status.Yes;
  this.reply_IDataparam_Status = null;

  this.port = new dezyne.IDataparam({provides: {name: 'port', component: this}, requires: {}});

  this.port.in.e0 = function() {
    runtime.call_in(this, function() {
      {
        this.port.out.a6(0, 1, 2, 3, 4, 5);
      }
    }.bind(this), [this.port, 'e0']);
  }.bind(this);
  this.port.in.e0r = function() {
    return runtime.call_in(this, function() {
      {
        this.port.out.a0();
        this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.port, 'e0r', this.port.Status_to_string]);
  }.bind(this);
  this.port.in.e = function(i) {
    runtime.call_in(this, function() {
      {
        var pi = {value: i};
        {
          var s = {value: this.funx(pi.value)};
          s = s.value;
          this.mi = pi.value;
          this.mi = this.xfunx(pi.value, pi.value);
          this.port.out.a(this.mi);
          this.port.out.aa(this.mi, pi.value);
        }
      }
    }.bind(this), [this.port, 'e']);
  }.bind(this);
  this.port.in.er = function(i) {
    return runtime.call_in(this, function() {
      {
        var xpi = {value: i};
        {
          var s = {value: new dezyne.IDataparam().Status.No};
          this.mi = xpi.value;
          this.port.out.a(this.mi);
          this.port.out.aa(this.mi, xpi.value);
          if(true) {
            this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
          }
          else {
            this.reply_IDataparam_Status = s.value;
          }
        }
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.port, 'er', this.port.Status_to_string]);
  }.bind(this);
  this.port.in.eer = function(i,j) {
    return runtime.call_in(this, function() {
      {
        var s = {value: new dezyne.IDataparam().Status.No};
        this.port.out.a(((typeof(j) === 'object') ? j.value : j));
        this.port.out.aa(((typeof(j) === 'object') ? j.value : j), ((typeof(i) === 'object') ? i.value : i));
        this.reply_IDataparam_Status = s.value;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.port, 'eer', this.port.Status_to_string]);
  }.bind(this);
  this.port.in.eo = function(i) {
    runtime.call_in(this, function() {
      {
        i.value = 234;
      }
    }.bind(this), [this.port, 'eo']);
  }.bind(this);
  this.port.in.eoo = function(i,j) {
    runtime.call_in(this, function() {
      {
        i.value = 123;
        j.value = 456;
      }
    }.bind(this), [this.port, 'eoo']);
  }.bind(this);
  this.port.in.eio = function(i,j) {
    runtime.call_in(this, function() {
      {
        j.value = i;
      }
    }.bind(this), [this.port, 'eio']);
  }.bind(this);
  this.port.in.eio2 = function(i) {
    runtime.call_in(this, function() {
      {
        var t = {value: i.value};
        i.value = 123 + 123;
      }
    }.bind(this), [this.port, 'eio2']);
  }.bind(this);
  this.port.in.eor = function(i) {
    return runtime.call_in(this, function() {
      {
        i.value = 234;
        this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.port, 'eor', this.port.Status_to_string]);
  }.bind(this);
  this.port.in.eoor = function(i,j) {
    return runtime.call_in(this, function() {
      {
        i.value = 123;
        j.value = 456;
        this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.port, 'eoor', this.port.Status_to_string]);
  }.bind(this);
  this.port.in.eior = function(i,j) {
    return runtime.call_in(this, function() {
      {
        j.value = i;
        this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.port, 'eior', this.port.Status_to_string]);
  }.bind(this);
  this.port.in.eio2r = function(i) {
    return runtime.call_in(this, function() {
      {
        var t = {value: i.value};
        i.value = 123 + 123;
        this.reply_IDataparam_Status = new dezyne.IDataparam().Status.Yes;
      }
      return this.reply_IDataparam_Status;
    }.bind(this), [this.port, 'eio2r', this.port.Status_to_string]);
  }.bind(this);
  this.fun = function () {
    return new dezyne.IDataparam().Status.Yes;
  }.bind(this);
  this.funx = function (xi) {
    xi = xi;
    return new dezyne.IDataparam().Status.Yes;
  }.bind(this);
  this.xfunx = function (xi, xj) {
    return (xi + xj) / 2;
  }.bind(this);

};
