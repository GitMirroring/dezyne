// Dezyne --- Dezyne command line tools
//
// Copyright © 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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
function node_p () {return typeof module !== 'undefined';}
function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

if (node_p ()) {
  // nodejs
  module.paths.unshift (__dirname);
  dzn_require = require;
  dzn = have_dzn_p () ? dzn : require (__dirname + '/runtime');
  dzn = dzn || {};
  dzn.dzn = dzn.dzn || {};
} else {
  // browser
  dzn_require = function () {return {};};
  dzn = have_dzn_p () ? dzn : {};
  /* Add to your html something like
  <script src="js/dzn/runtime.js"></script>
  <script src="js/hello.js"></script>
  */
}



dzn = dzn || {};
dzn.library = dzn.library || {};


dzn.library.ihello = function ihello(meta) {
  this._dzn = {};

  this.in = {
    hello: null

  };
  this.out = {
    goodbye: null

  };
  this._dzn.meta = meta;
};

if (node_p ()) {
  //nodejs
  module.exports = dzn;
}
dzn = dzn || {};
dzn.library = dzn.library || {};


dzn.library.iworld = function iworld(meta) {
  this._dzn = {};

  this.in = {
    world: null

  };
  this.out = {
    howdy: null

  };
  this._dzn.meta = meta;
};

dzn.library.hello = function (locator, meta) {
  dzn.runtime.init (this, locator, meta);
  this._dzn.meta.ports = ['h', 'w'];
  this._dzn.flushes = true;


  this.b =  true;



  this.h = new dzn.library.ihello({provides: {name: 'h', component: this}, requires: {}});

  this.w = new dzn.library.iworld({provides: {}, requires: {name: 'w', component: this}});



  this.h.in.hello = function(){

    {
      this.b = false;
      this.w.in.world();
    }

    return;

  };
  this.w.out.howdy = function(){
    if (!(this.b))
    {
      this.b = true;
      this.h.out.goodbye();
    }
    else if (!(!(this.b))) this._dzn.rt.illegal();
    else this._dzn.rt.illegal();

    return;

  };



  this._dzn.rt.bind (this);
};

if (node_p ()) {
  // nodejs
  module.exports = dzn;
}

//code generator version: 2.10.0.rc0.304-2437b
