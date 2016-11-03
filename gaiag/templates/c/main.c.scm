/* -*-c-style:linux;indent-tabs-mode:t-*- */

##include <assert.h>
##include <dzn/runtime.h>
##include <dzn/locator.h>
##include <dzn/map.h>

##include "#.scope_model .h"

##define _GNU_SOURCE
##include <stdio.h>
##include <stdlib.h>
##include <string.h>

typedef struct {
  void (*f)(void*, ...);
  void *self;
} closure;

typedef struct {
  runtime_info* info;
  char* name;
} args_flush;

map* global_event_map;
bool global_flush_p;

static bool relaxed = false;

char* read_line() {
	char *line = 0;
	size_t size;
	if (getline(&line, &size, stdin) != -1) {
		if (strlen(line) > 1 && line[strlen(line)-1] == '\n') {
			line[strlen(line)-1] = 0;
		}
		return line;
	}
	return 0;
}

char* drop_prefix(char* string, char* prefix) {
	size_t len = strlen(prefix);
	if (strlen(string) >= len && !strncmp(string, prefix, len)) {
		return string + len;
	}
	return string;
}

char* consume_synchronous_out_events(char* prefix, char* event, map* event_map) {
	char* s;
        char match[1024];
        strcat(strcpy(match, prefix), event);
	while ((s = read_line()) != 0) if (!strcmp(match, s)) break;
	while ((s = read_line()) != 0) {
		void *p = 0;
		if (map_get(event_map, s, &p)) break;
                closure *c = p;
                c->f(c->self);
		free(s);
    	}
	return s ? s : "";
}

void log_in(char* prefix, char* event, map* event_map) {
        fprintf(stderr, "%s%s\n", prefix, event);
	if (relaxed) return;
        consume_synchronous_out_events(prefix, event, event_map);
        fprintf(stderr, "%s%s\n", prefix, "return");
}

void log_out(char* prefix, char* event, map* event_map) {
	(void)event_map;
        fprintf(stderr, "%s%s\n", prefix, event);
}

void log_flush(void* args) {
	args_flush* a = args;
	fprintf(stderr, "%s.<flush>\n", a->name);
	runtime_flush(a->info);
}

int log_valued(char* prefix, char* event, map* event_map, int (*string_to_value)(char*), char* (*value_to_string)(int))
{
        fprintf(stderr, "%s%s\n", prefix, event);
	if (relaxed) return 0;
        char* s = consume_synchronous_out_events(prefix, event, event_map);
	int r = string_to_value(drop_prefix(s, prefix));
	if ((int)r != INT_MIN) {
		fprintf(stderr, "%s%s\n", prefix, value_to_string(r));
		return r;
	}
	fprintf(stderr,"\"%s\": is not a reply value\n", s);
	assert(!"not a reply value");
	return 0;
}

#(->string (map (string-to-enum model) (om:enums)))
#(->string (map (enum-to-string model) (om:enums)))

#(map
 (lambda (port)
   (map (define-on model port #{
   #(string-if (not (eq? type 'void)) #{int#} #{void#})  #.scope_model _log_event_#port _#direction _#event (#((c:scope-name) interface) * m) {
   (void)m;
   #(string-if (eq? return-type 'void) #{
   log_#direction("#port .", "#event ", global_event_map);#}#{
   return log_valued("#port .", "#event ", global_event_map, string_to_#((om:scope-join #f) reply-scope)_#reply-name , #((om:scope-join #f) reply-scope)_#reply-name _to_string);#})}
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
void #.scope_model _fill_event_map(#.scope_model * m, map* e) {
   int dzn_i = 0;
   void *p;
   closure *c;
   args_flush* args;

   component *comp = calloc(1, sizeof (component));
   comp->dzn_info.performs_flush = global_flush_p;
##if DZN_TRACING
   comp->dzn_meta.parent = 0;
   comp->dzn_meta.name = "<external>";
##endif // DZN_TRACING

   #(map
     (lambda (port)
       (map (define-on model port #{
          m->#port ->#direction .#event  = #.scope_model _log_event_#port _#direction _#event;
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
  #(map (init-port #{
     c = malloc(sizeof (closure));
     c->f = log_flush;
     args = malloc(sizeof(args_flush));
     args->info = &comp->dzn_info;
     args->name = "#name ";
     c->self = args;

     m->#name ->meta.requires.address = comp;
##if DZN_TRACING
     m->#name ->meta.requires.port = "#name ";
     m->#name ->meta.requires.meta = &comp->dzn_meta;
     {
     if (global_flush_p) {
       comp->dzn_meta.name = "<internal>";
     }
     }
##endif // DZN_TRACING
     map_put(e, "#name .<flush>", c);
     #}) (filter om:provides? (om:ports model)))
  #(map (init-port #{
     c = malloc(sizeof (closure));
     c->f = log_flush;
     args = malloc(sizeof(args_flush));
     args->info = &comp->dzn_info;
     args->name = "#name ";
     c->self = args;

     m->#name ->meta.provides.address = comp;
##if DZN_TRACING
     m->#name ->meta.provides.port = "#name ";
     m->#name ->meta.provides.meta = &comp->dzn_meta;
     {
     if (global_flush_p) {
         comp->dzn_meta.name = "<internal>";
       }
     }
##endif // DZN_TRACING
     map_put(e, "#name .<flush>", c);
     #}) (filter om:requires? (om:ports model)))
   #(map
     (lambda (port)
       (map (define-on model port #{
           c = malloc(sizeof (closure));
           c->f = (void (*))m->#port ->#direction .#event;
           c->self = m->#port;
           map_put(e, "#port .#event ", c);
#}) (filter (om:dir-matches? port)
	    (om:events port)))) (om:ports model))
  }
void illegal_print() {
##if DZN_TRACING
	fputs("illegal\n", stderr);
	exit(1);
##else // !DZN_TRACING
    *(int*)0 = 0; // SEGFAULT here
##endif // !DZN_TRACING
}

int main(int argc, char** argv) {
	global_flush_p = argc > 1 && !strcmp(argv[1], "--flush");
	runtime dezyne_runtime;
	runtime_init(&dezyne_runtime);
	locator dezyne_locator;
	locator_init(&dezyne_locator, &dezyne_runtime);
	dezyne_locator.illegal = illegal_print;

	#.scope_model  sut;
##if DZN_TRACING
	dzn_meta_t mt = {"sut", 0};
##endif // DZN_TRACING
	#.scope_model _init(&sut, &dezyne_locator
##if DZN_TRACING
, &mt
##endif // DZN_TRACING
);

	map event_map;
	map_init(&event_map);
        global_event_map = &event_map;
	#.scope_model _fill_event_map(&sut, &event_map);

	char* line;
	while ((line = read_line()) != 0) {
		void *p = 0;
		if (!map_get(&event_map, line, &p)) {
        		closure *c = p;
        		c->f(c->self, 0, 1, 2, 3, 4, 5);
		}
		free(line);
    	}
	return 0;
}
