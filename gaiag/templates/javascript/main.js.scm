function #.model _fill_event_map(m) {
#(map
    (lambda (port)
     (map (define-on model port #{
        m.#port .#direction .#event  = function() {console.error('#port .#direction .#event ');};
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

  var readline = require('readline');
  var rl = readline.createInterface ({
    input: process.stdin,
    output: process.stdout
  });
  
  rl.on('line', function(event) {
    if (event_map[event]) {
      event_map[event]();
    }
  });
}

main ();
