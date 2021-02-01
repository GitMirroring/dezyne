#! /usr/bin/env node

process.env.NODE_PATH += ':' + __dirname;
process.env.NODE_PATH += ':' + __dirname + '/../../javascript';
require("module").Module._initPaths();

function node_p () {return typeof (module) !== 'undefined';}
function have_dzn_p () {return typeof (dzn) !== 'undefined' && dzn;}

dzn = have_dzn_p () ? dzn : require ('dzn/runtime');
dzn.extend (dzn, require ('Foreign'));
dzn.extend (dzn, require ('foreign_optional'));

function main () {
  var loc = new dzn.locator();
  var pump = new dzn.pump();
  loc.set(pump);
  var rt = new dzn.runtime(function() {console.error('illegal');process.exit(1);});
  var sut = new dzn.foreign_optional(loc.set(rt), {name:'sut'});

  sut.c.h.out.world = function() {console.error('<external>.h.world <- sut.c.h.world\n');};
  sut.f.w.in.hello();
  //sut.f.w_world();
}

main ();
