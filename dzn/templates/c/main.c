typedef struct flush_arguments flush_arguments;
struct flush_arguments
{
  dzn_runtime_info *info;
  char *name;
};

dzn_map *global_event_map;
bool global_flush_p;

char *
read_line ()
{
  char *line = 0;
  size_t size;
  int getline_result = getline (&line, &size, stdin);
  if (getline_result != -1)
    {
      size_t line_length = strlen (line);
      if ((line_length > 1) && (line[line_length - 1] == '\n')) line[line_length - 1] = '\0';
      return line;
    }
  return 0;
}

char *
drop_prefix (char *string, char *prefix)
{
  size_t len = strlen (prefix);
  size_t string_length = strlen (string);
  int comparison_result = strncmp (string, prefix, len);
  if ((string_length >= len) && (comparison_result == 0)) return string + len;
  return string;
}

char *
consume_synchronous_out_events (char *prefix, char *event, dzn_map *event_map)
{
  char *s;
  char match[1024];
  dzn_closure *c;
  strcat (strcpy (match, prefix), event);
  s = read_line ();
  while (s != 0)
    {
      int comp_result = strcmp (match, s);
      if (comp_result == 0) break;
      s = read_line ();
    }
  s = read_line ();
  while (s != 0)
    {
      void *p = 0;
      if (dzn_map_get (event_map, s, &p)) break;
      c = p;
      c->function (c->argument);
      free (s);
      s = read_line ();
    }
  return s ? s : "";
}

void
log_in (char *prefix, char *event, dzn_map *event_map)
{
  fprintf (stderr, "<external>.%s%s -> sut.%s%s\n", prefix, event, prefix, event);
  consume_synchronous_out_events (prefix, event, event_map);
  fprintf (stderr, "<external>.%s%s <- sut.%s%s\n", prefix, "return", prefix, "return");
}

void
log_out (char *prefix, char *event, dzn_map *event_map)
{
  (void)event_map;
  fprintf (stderr, "<external>.%s%s <- sut.%s%s\n", prefix, event, prefix, event);
}

void
log_flush (void *argument)
{
  flush_arguments *a = argument;
  fprintf (stderr, "%s.<flush>\n", a->name);
  dzn_runtime_flush (a->info);
}

int
log_typed (char *prefix, char *event, dzn_map *event_map, int (*string_to_value) (char *string_val), char * (*value_to_string) (int int_val))
{
  char *s;
  int r;
  fprintf (stderr, "<external>.%s%s -> sut.%s%s\n", prefix, event, prefix, event);
  s = consume_synchronous_out_events (prefix, event, event_map);
  r = string_to_value (drop_prefix (s, prefix));
  if ((int)r != INT_MAX)
    {
      char *p = strchr (s, '.') + 1;
      fprintf (stderr, "<external>.%s%s <- sut.%s%s\n", prefix, p, prefix, p);
      return r;
    }
  fprintf (stderr, "\"%s\": is not a reply value\n", s);
  assert (!"not a reply value");
  return 0;
}

void
illegal_print (void)
{
#if DZN_TRACING
  fputs ("illegal\n", stderr);
  exit (0);
#else /* !DZN_TRACING */
  * (int *)0 = 0; /* SEGFAULT here */
#endif /* !DZN_TRACING */
}

int
dzn_getopt (int argc, char const* argv[], char const *option)
{
  return (argc > 1) && (strcmp (argv[1], option) == 0);
}

dzn_closure *
next_event ()
{
  char *s = read_line ();
  if (!s) return 0;
  void *p = 0;
  dzn_map_get (global_event_map, s, &p);
  return p;
}
