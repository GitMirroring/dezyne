function node_p () {return typeof module !== 'undefined';}
function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

dzn = dzn || {};
dzn.library = dzn.library || {};

dzn.library.foreign = function (locator, meta) {
  dzn.runtime.init (this, locator, meta);
  this._dzn.meta.ports = ['w'];
  //this._dzn.flushes = true;
  this.w = new dzn.library.iworld({provides: {name: 'w', component: this}, requires: {}});
  this.w.in.world = function(){}
  this._dzn.rt.bind (this);
};

if (node_p ()) {
  // nodejs
  module.exports = dzn;
}
