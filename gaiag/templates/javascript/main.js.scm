##! /usr/bin/env node

assert = require ('assert');
var dzn = typeof (dzn) !== undefined && dzn ? dzn : require (__dirname + '/dzn/runtime');

dzn.extend (dzn, require (__dirname + '/dzn/#.scope_model '));

var relaxed = false;
var lines = [];
function read_line() {
  if (lines.length) {
    return lines.pop();
  }
  return '';
}

function peek_line() {
  return lines.slice(-1)[0];
}

function drop_prefix(string, prefix) {
  if (string.indexOf(prefix) === 0) {
    return string.slice(prefix.length);
  }
  return string;
}

function consume_synchronous_out_events(prefix, event, event_map) {
  var s;
  while (s = read_line()) if (s === prefix + event) break;
  while (s = read_line()) {
    if (!event_map[s]) {
      break;
    }
    event_map[s]();
  }
  return s && s.split ('.').last ();
}

function log_in(prefix, event, event_map) {
  console.error(prefix + event);
  if (relaxed) return;
  consume_synchronous_out_events(prefix, event, event_map);
  console.error(prefix + 'return');
}

function log_out(prefix, event) {
  console.error(prefix + event);
}

function type_helper(value, type) {
  if (type === 'int') return parseInt (value);
  if (type === 'bool') return value === 'false' ? false : true;
  return value;
}

function log_valued(prefix, event, event_map) {
  console.error(prefix + event);
  if (relaxed) return 0;
  var s = consume_synchronous_out_events(prefix, event, event_map);
  if (s !== undefined) {
     console.error(prefix + s);
     return s;
  }
  throw 'runtime error: "' + s + '" is not a reply value'
}

function #.scope_model _fill_event_map(m)
{
  var c = new dzn.component(m._dzn.locator, {provides:{}});
  c._dzn.flushes = dzn.flush;

  var e = {
#(map
    (lambda (port)
    (map (define-on model port #{
      '#port .#event ': function () {m.#port .#direction .#event (#(javascript:out-param-list model formal-objects));},
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) };
  #(map (init-port #{
     if (dzn.flush) {
       m.#name ._dzn.meta.requires.component = c;
       m.#name ._dzn.meta.requires.name = '<internal>.#name ';
     }
     #}) (filter om:provides? (om:ports model)))
  #(map (init-port #{
     if (dzn.flush) {
       m.#name ._dzn.meta.provides.component = c;
       m.#name ._dzn.meta.provides.name = '<internal>.#name ';
     }
       e['#name .<flush>'] = function() {console.error('#name .<flush>'); m._dzn.rt.flush(m.#name ._dzn.meta.provides.component);};
     #}) (filter om:requires? (om:ports model)))
  #(map
    (lambda (port)
     (map (define-on model port #{
       m.#port .#direction .#event  = function() {#(string-if (eq? return-type-name 'void) #{log_#direction('#port .', '#event ', e);#}#{return type_helper(log_valued('#port .', '#event ', e), '#return-type-name ');#})};
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
 #(map (init-port #{
     m.#name ._dzn.meta.provides.name = "#name ";
     m.#name ._dzn.meta.requires.name = "#name ";
 #}) (om:ports model))
   return e;
}

function main () {
  dzn.flush = process.argv.length > 2 && process.argv[2] === '--flush';
  dzn.relaxed = process.argv.length > 2 && process.argv[2] === '--relaxed';
  var loc = new dzn.locator();
  var pump = new dzn.pump();
  loc.set(pump);
  var rt = new dzn.runtime(function() {console.error('illegal');process.exit(0);});
  var sut = new #(javascript:namespace model).#.model (loc.set(rt), {name:'sut'});

  var event_map = #.scope_model _fill_event_map(sut);

  var fs = require ('fs');
  lines = fs.readFileSync('/dev/stdin', 'ascii').toString().trim().split ('\n').reverse ();
  var s;
  pump.queue = {pop:function(){var s=read_line(); return s?event_map[s]:undefined;},peek:peek_line};
  while (s = pump.queue.peek ()) {
    if (event_map[s]) {
      pump.pump (event_map[s]);
    }
  }
}

main ();
