#(map
  (lambda (model)
  (append
   `("function " ,(.name model) "_fill_event_map(m, e)\n{\n")
   (if (is-a? model <component>)
      (map
       (lambda (port)
       (map (define-on model port #{
          if (!m.#port .#direction .#event) {
            m.#port .#direction .#event  = function () {console.error('#port .#direction .#event ');};
         }
         if (!e['#port .#event ']) {
           e['#port .#event '] = m.#port .#direction .#event;
         }
#}) (gom:events port))) (delete-duplicates (gom:ports model)))
    '())
    '("}\n")))
  (if (is-a? model <component>) (list model) (delete-duplicates (map (lambda (i) (gom:import (.component i))) (.elements (.instances model))))))
  
function main () {
  var rt = new dezyne.runtime ();
  var event_map = {};
  var sut = new dezyne.#.model (rt, {name: 'sut'});
  
  #(string-if (is-a? model <component>)
              #{#.model _fill_event_map(sut, event_map); #}
              (->string
              (map
                (lambda (i)
                   `(,(.component i) "_fill_event_map(sut." ,(.name i) ", event_map);\n")) (.elements (.instances model)))))

  var readline = require ('readline');
  var rl = readline.createInterface ({
    input: process.stdin,
    output: process.stdout
  });
  
  rl.on ('line', function (event) {
    if (event_map[event]) {
      event_map[event] ();
    }
  });
}

main ();
