var lines = [];
function read_line() {
  if (lines.length) {
    return lines.pop();
  }
  process.exit(0);
}

function drop_prefix(string, prefix) {
  if (string.indexOf(prefix) === 0) {
    return string.slice(prefix.length);
  }
  return string;
}

function get_value(string_to_value) {
  var s;
  while (s = read_line()) {
    var r = string_to_value(s);
    if (r !== undefined) {
      return r;
    }
  }
}

function log_void(prefix, event) {
  console.error(prefix + event);
  console.error(prefix + 'return');
}

function log_valued(prefix, event, string_to_value, value_to_string) {
  console.error(prefix + event);
  var r = get_value(string_to_value);
  if (r !== undefined) {
     console.error(prefix + value_to_string[r]);
     return r;
  }
  return 0;
}

function #.model _fill_event_map(m) {
#(map
    (lambda (port)
     (map (define-on model port #{
       m.#port .#direction .#event  = function() {#(string-if (eq? return-type 'void) #{log_void('#port .#direction .', '#event ');#}#{return log_valued('#port .#direction .', '#event ', function(s) {return new dezyne.#interface().#reply-name[drop_prefix(s, '#port .#reply-name _')];}, new dezyne.#interface().#reply-name _to_string)#})};
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))   return {
#(map
    (lambda (port)
    (map (define-on model port #{
      '#port .#event ': m.#port .#direction .#event ,
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model)) };
}

function main () {
  var rt = new dezyne.runtime ();
  var sut = new dezyne.#.model (rt, {name: 'sut'});
  
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
