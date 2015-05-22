/* -*-c-style:linux;indent-tabs-mode:t-*- */

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


int config(char* s) {
	(void)s;
	return 0;
}

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

void log_in(char* prefix, char* event) {
        fprintf(stderr, "%s%s\n", prefix, event);
        fprintf(stderr, "%s%s\n", prefix, "return");
}

void log_out(char* prefix, char* event) {
        fprintf(stderr, "%s%s\n", prefix, event);
}

int get_value(int (*string_to_value)(char*), char* event_prefix) {
	char* line;
	while ((line = read_line()) != 0) {
		int r = string_to_value(drop_prefix(line, event_prefix));
		free(line);
		if (r != -1) {
			return r;
		}
	}
	exit(0);
        return 0;
}

int log_valued(char* prefix, char* event, int (*string_to_value)(char*), char* event_prefix, char* (*value_to_string)(int))
{
        fprintf(stderr, "%s%s\n", prefix, event);
	int r = get_value(string_to_value, event_prefix);
	if ((int)r != -1) {
		fprintf(stderr, "%s%s\n", prefix, value_to_string(r));
		return r;
	}
    return 0;
}

#(->string (map (string-to-enum model) (om:enums)))
#(->string (map (enum-to-string model) (om:enums)))

#(map
 (lambda (port)
   (map (define-on model port #{
   #(string-if (not (eq? type 'void)) #{int#} #{void#})  #.model _log_event_#port _#direction _#event (#interface * m) {
   (void)m;
   #(string-if (eq? return-type 'void) #{
   log_#direction("#port .#direction .", "#event ");#}#{
   return log_valued("#port .#direction .", "#event ", string_to_#(*scope* reply-scope)_#reply-name , "#port .", #(*scope* reply-scope)_#reply-name _to_string);#})}
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
void #.model _fill_event_map(#.model * m, map* e) {
   int dzn_i = 0;
   void *p;
   closure *c;
   #(map
     (lambda (port)
       (map (define-on model port #{
          m->#port ->#direction .#event  = #.model _log_event_#port _#direction _#event;
#}) (filter (negate (om:dir-matches? port))
       (om:events port)))) (om:ports model))
   #(map
     (lambda (port)
       (map (define-on model port #{
           c = malloc(sizeof (closure));
           c->f = (void (*))m->#port ->#direction .#event;
           c->self = m->#port;
           map_put(e, "#port .#event ", c);
#}) (filter (om:dir-matches? port)
       (om:events port)))) (om:ports model)) }

void illegal_print() {
	fputs("illegal\n", stderr);
	exit(0);
}

int main() {
	runtime dezyne_runtime;
	runtime_init(&dezyne_runtime);
	locator dezyne_locator;
	locator_init(&dezyne_locator, &dezyne_runtime);
	dezyne_locator.illegal = illegal_print;

	#.model  sut;
	dzn_meta_t mt = {"sut", 0};
	#.model _init(&sut, &dezyne_locator, &mt);

	map event_map;
	map_init(&event_map);
	#.model _fill_event_map(&sut, &event_map);

	char* line;
	while ((line = read_line()) != 0) {
		void *p = 0;
		if (!map_get(&event_map, line, &p)) {
        		closure *c = p;
        		c->f(c->self);
		}
		free(line);
    	}
	return 0;
}
