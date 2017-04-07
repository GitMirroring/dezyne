;;; Dezyne --- Dezyne command line tools
;;;
;;; Copyright © 2015, 2016 Jan Nieuwenhuizen <janneke@gnu.org>
;;; Copyright © 2015, 2017 Rutger van Beusekom <rutger.van.beusekom@verum.com>
;;; Copyright © 2015, 2016 Henk Katerberg <henk.katerberg@yahoo.com>
;;;
;;; This file is part of Dezyne.
;;;
;;; Dezyne is free software: you can redistribute it and/or modify it
;;; under the terms of the GNU Affero General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; Dezyne is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Affero General Public License for more details.
;;;
;;; You should have received a copy of the GNU Affero General Public
;;; License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; Commentary:
;;; 
;;; Code:

// -*-java-*-
using System;
using System.Collections.Generic;
using System.Diagnostics;

class main {

    static void connect_ports (dzn.container<#((om:scope-name) model)> c)
{
 #(map (lambda (port)
       (map (define-on model port #{
    c.system.#port .#direction port.#event  = (#formals) => {
    dzn.Runtime.traceIn(c.system.#port .dzn_meta, "#event "); //System.Console.Error.WriteLine("");
    #(string-if (eq? direction 'out) #{c.match("#port .#event ");#}
    #{c.match("#port .#event "); String tmp = c.match_return();
    dzn.Runtime.traceOut(c.system.#port .dzn_meta, tmp.Split('.')[1]); //System.Console.Error.WriteLine("");
    return#(if (not (eq? reply-name 'void)) (list " dzn.container<" ((om:scope-name (string->symbol ".")) model) ">.string_to_value<" (cond ((equal? return-type "bool") 'bool) ((equal? return-type "int") 'int) (else (list (if (or (null? reply-scope) (om:outer-scope? model reply-scope)) 'dzn.global reply-scope) '. reply-name))) ">(tmp.Split('.')[1])"));#})
  };
  #}) (filter (negate (om:dir-matches? port)) (om:events port))))
  (om:ports model))}

static Dictionary<String, Action> event_map (dzn.container<#((om:scope-name) model)> c)
{
 #(map (init-port #{
     c.system.#name .dzn_meta.requires.name = "#name ";
 #}) (filter om:provides? (om:ports model)))
 #(map (init-port #{
     c.system.#name .dzn_meta.provides.component = c;
     c.system.#name .dzn_meta.provides.meta = c.dzn_meta;
     c.system.#name .dzn_meta.provides.name = "#name ";

 #}) (filter om:requires? (om:ports model)))

     Dictionary<String, Action> lookup = new Dictionary<String, Action>();
  #((->join "\n  ")
    (append (map (lambda (port)
       ((->join "\n  ") (map (define-on model port #{lookup.Add("#port .#event ",()=>{#(string-if (eq? reply-name 'void)
       #{ #(cs:out-var-decls model formal-objects) c.system.#port .#direction port.#event (#(cs:out-param-list model formal-objects));
       #(string-if (eq? direction 'in) #{c.match("#port .return");#}) #}
                     #{ #(cs:out-var-decls model formal-objects) c.match("#port ." + c.to_string<#(cond ((equal? return-type "bool") 'bool) ((equal? return-type "int") 'int) (else (list (if (null? reply-scope) 'dzn.global ((->join "_") reply-scope)) '. reply-name)))>(c.system.#port .#direction port.#event (#(cs:out-param-list model formal-objects)))); #})}); #})
       (filter (om:dir-matches? port) (om:events port)))))

  (om:ports model))
  (map (init-port (if (not (eq? "(glue)" 'asd)) #{lookup.Add("#name .<flush>",()=>{System.Console.Error.WriteLine("#name .<flush>"); dzn.Runtime.flush(c.system);});#}
                                             #{{"#name .<flush>",()=>{System.Console.Error.WriteLine("#name .<flush>"); g_singlethreaded.processCBs();}}#}))
                                             (filter om:requires? (om:ports model)))))
    return lookup;
  }

  public static void Main(String[] args)
  {
    if(Array.Exists(args, s => s == "--debug")) {
      Debug.Listeners.Add(new TextWriterTraceListener(Console.Error));
      Debug.AutoFlush = true;
    }

    using(dzn.container<#((om:scope-name) model)> c = new dzn.container<#((om:scope-name) model)>((loc,name)=>{return new #((om:scope-name) model)(loc,name);}, Array.Exists(args, s => s == "--flush"))) {
    connect_ports (c);
    c.run(event_map (c), new List<String> {#((->join ",") (map (lambda (port) (list "\"" (.name port) "\"")) (filter om:requires? (om:ports model))))});
  }
}
}
