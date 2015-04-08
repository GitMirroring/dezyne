
##include "runtime.h"
##include "locator.h"
##include "map.h"

##include "#.model .h"

##include <stdio.h>
##include <stdlib.h>
##include <string.h>

void print_event ()
{
  fprintf (stderr, "event\n");
}

typedef struct {
  void (*f)(void*);
  void *self;
} closure;

#(map
  (lambda (model)
  (append
   `("void " ,(.name model) "_fill_event_map(" ,(.name model) "* m, map* e)\n{\nint dzn_i = 0;\nvoid *p;\nclosure *c;\n")
   (if (is-a? model <component>)
      (map
       (lambda (port)
       (map (define-on model port #{
          if (!m->#port ->#direction .#event  || !m->#port ->#direction .self) {
            m->#port ->#direction .#event  = print_event;
         }
         if (map_get(e, "#port .#event ", &p)) {
           c = malloc(sizeof (closure));
           c->f = m->#port ->#direction .#event;
           c->self = m->#port;
           map_put(e, "#port .#event ", c);
         }
#}) (gom:events port))) (delete-duplicates (gom:ports model)))
    '())
    '("}\n")))
  (if (is-a? model <component>) (list model) (delete-duplicates (map (lambda (i) (gom:import (.component i))) (.elements (.instances model))))))

int main() {
  runtime dezyne_runtime;
  runtime_init(&dezyne_runtime);
  locator dezyne_locator;
  locator_init(&dezyne_locator, &dezyne_runtime);

  #.model  sut;
  dzn_meta_t mt = {"sut", 0};
  #.model _init(&sut, &dezyne_locator, &mt);

  map event_map;
  map_init(&event_map);
  #(string-if (is-a? model <component>)
              #{#.model _fill_event_map(&sut, &event_map); #}
              (->string
              (map
                (lambda (i)
                   `(,(.component i) "_fill_event_map(&sut." ,(.name i) ", &event_map);\n")) (.elements (.instances model)))))

   char *event = 0;
   size_t size;
   while (getline(&event, &size, stdin) != -1) {
     if (strlen(event) > 1 && event[strlen(event)-1] == '\n') {
       void *p = 0;
       event[strlen(event)-1] = 0;
       map_get(&event_map, event, &p);
       closure *c = p;
       c->f(c->self);
     }
     free(event);
     event = 0;
  }
  return 0;
}
