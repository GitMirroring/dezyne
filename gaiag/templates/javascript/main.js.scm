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

function consume_synchronous_out_events(event_map) {
  read_line();
  var event;
  while (event = read_line()) {
    if (!event_map[event]) {
      break;
    }
    event_map[event]();
  }
  return event;
}

function log_in(prefix, event, event_map) {
  console.error(prefix + event);
  if (relaxed) return;
  consume_synchronous_out_events(event_map);
  console.error(prefix + 'return');
}

function log_out(prefix, event) {
  console.error(prefix + event);
}

function log_valued(prefix, event, event_map, string_to_value, value_to_string) {
  console.error(prefix + event);
  if (relaxed) return 0;
  var s = consume_synchronous_out_events(event_map);
  var r = string_to_value(s);
  if (r !== undefined) {
     console.error(prefix + value_to_string[r]);
     return r;
  }
  throw 'runtime error: "' + s + '" is not a reply value'
}

function #.model _fill_event_map(m) 
{
  var e = {
#(map
    (lambda (port)
    (map (define-on model port #{
      '#port .#event ': m.#port .#direction .#event ,
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) };
#(map
    (lambda (port)
     (map (define-on model port #{
       m.#port .#direction .#event  = function() {#(string-if (eq? return-type 'void) #{log_#direction('#port .', '#event ', e);#}#{return log_valued('#port .', '#event ', e, function(s) {return new dezyne.#interface().#reply-name[drop_prefix(s, '#port .#reply-name _')];}, new dezyne.#interface().#reply-name _to_string)#})};
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))   return e;
}

function main () {
  var loc = new dezyne.locator();
  var rt = new dezyne.runtime(function() {console.error("illegal");process.exit(0);});
  var sut = new dezyne.#.model (loc.set(rt), {name: 'sut'});

  var event_map = #.model _fill_event_map(sut);

  var fs = require ('fs');
  lines = fs.readFileSync ('/dev/stdin', 'ascii').toString().trim().split ('\n').reverse ();
  var event;
  while (event = read_line ()) {
    if (event_map[event]) {
      event_map[event]();
    }
  }
}

main ();
