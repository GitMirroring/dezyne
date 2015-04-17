var lines = [];
function read_line () {
  if (lines.length) {
    return lines.pop();
  }
  process.exit (0);
}

// function read_line () {
//   var readline = require ('readline-sync');
//   var s;
//   if (s = readline.question ()) {
//     return s;
//   }
//   process.exit (0);
// }

function drop_prefix(string, prefix) {
  if (string.indexOf(prefix) === 0) {
    return string.slice(prefix.length);
  }
  return string;
}

function #.model _fill_event_map(m) {
#(map
    (lambda (port)
     (map (define-on model port #{
       m.#port .#direction .#event  = function() {console.error('#port .#direction .#event '); #(string-if (and (eq? return-type 'void) (eq? direction 'in)) #{console.error('#port .#direction .return');#}) #(string-if (not (eq? return-type 'void)) #{var s; while (s = read_line ()) {var r = new dezyne.#interface().#reply-name[drop_prefix(s,'#port .#reply-name _')]; if (r !== undefined) {console.error('#port .#direction .' + new dezyne.#interface().#reply-name _to_string[r]); return r;};}#})};
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
