##! /usr/bin/nodejs

var dezyne = typeof (dezyne) !== undefined && dezyne ? dezyne : require (__dirname + '/dezyne/runtime');
dezyne.extend (dezyne, require (__dirname + '/dezyne/#.scope_model '));

var relaxed = false;
var lines = [];
function read_line() {
  if (lines.length) {
    return lines.pop();
  }
  return '';
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
  return s;
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

function log_valued(prefix, event, event_map, string_to_value, value_to_string) {
  console.error(prefix + event);
  if (relaxed) return 0;
  var s = consume_synchronous_out_events(prefix, event, event_map);
  var r = string_to_value(s);
  if (r !== undefined) {
     console.error(prefix + value_to_string[r]);
     return r;
  }
  throw 'runtime error: "' + s + '" is not a reply value'
}

function #.scope_model _fill_event_map(m)
{
  var c = new dezyne.component(m.locator, {provides:{}});
  c.flushes = true;

  var e = {
#(map
    (lambda (port)
    (map (define-on model port #{
      '#port .#event ': m.#port .#direction .#event ,
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) };
  #(map (init-port #{
       m.#name .meta.provides.component = c;
       m.#name .meta.provides.name = '<internal>';
       e['#name .<flush>'] = function() {console.error('#name .<flush>'); m.rt.flush(m.#name .meta.provides.component);};
     #}) (filter om:requires? (om:ports model)))
#(map
    (lambda (port)
     (map (define-on model port #{
       m.#port .#direction .#event  = function() {#(string-if (eq? return-type 'void) #{log_#direction('#port .', '#event ', e);#}#{return log_valued('#port .', '#event ', e, function(s) {return new dezyne.#((om:scope-name) interface)().#reply-name[drop_prefix(s, '#port .#reply-name _')];}, new dezyne.#((om:scope-name) interface)().#reply-name _to_string)#})};
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))   return e;
}

function main () {
  var loc = new dezyne.locator();
  var rt = new dezyne.runtime(function() {console.error('illegal');process.exit(0);});
  var sut = new #(javascript:namespace model).#.model (loc.set(rt), {name: 'sut'});

  var event_map = #.scope_model _fill_event_map(sut);

  var fs = require ('fs');
  lines = fs.readFileSync ('/dev/stdin', 'ascii').toString().trim().split ('\n').reverse ();
  var s;
  while (s = read_line ()) {
    if (event_map[s]) {
      event_map[s]();
    }
  }
}

main ();
