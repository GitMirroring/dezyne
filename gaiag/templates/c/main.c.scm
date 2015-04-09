
##include "runtime.h"
##include "locator.h"
##include "map.h"

##include "#.model .h"

##include <stdio.h>
##include <stdlib.h>
##include <string.h>

typedef struct {
  void (*f)(void*);
  void *self;
} closure;

#(map
 (lambda (port)
   (map (define-on model port #{
   void #.model _log_event_#port _#direction _#event (#interface * m) {
     (void)m;
     fprintf(stderr, "%s\n", "#port .#direction .#event");
   }
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))
void #.model _fill_event_map(#.model * m, map* e) {
   int dzn_i = 0;
   void *p;
   closure *c;
   #(map
     (lambda (port)
       (map (define-on model port #{
          m->#port ->#direction .#event  = #.model _log_event_#port _#direction _#event;
#}) (filter (negate (gom:dir-matches? port))
       (gom:events port)))) (gom:ports model))
   #(map
     (lambda (port)
       (map (define-on model port #{
           c = malloc(sizeof (closure));
           c->f = (void (*))m->#port ->#direction .#event;
           c->self = m->#port;
           map_put(e, "#port .#event ", c);
#}) (filter (gom:dir-matches? port)
       (gom:events port)))) (gom:ports model)) }

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
  #.model _fill_event_map(&sut, &event_map);

  char *event = 0;
  size_t size;
  while (getline(&event, &size, stdin) != -1) {
    if (strlen(event) > 1 && event[strlen(event)-1] == '\n') {
      void *p = 0;
      event[strlen(event)-1] = 0;
      if (!map_get(&event_map, event, &p)) {
        closure *c = p;
        c->f(c->self);
      }
    }
    free(event);
    event = 0;
  }
  return 0;
}
