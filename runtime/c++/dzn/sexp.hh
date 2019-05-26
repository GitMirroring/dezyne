// Dezyne --- Dezyne command line tools
//
// Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of Dezyne.
//
// Dezyne is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// Dezyne is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public
// License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef DZN_SEXP_HH
#define DZN_SEXP_HH

#include <algorithm>
#include <cassert>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <list>
#include <map>
#include <string>

namespace dzn
{
  namespace sexp {

#define STRING_MAX 80

    struct sexp;
    typedef struct sexp sexp;

    typedef struct sexp
    {
      union
      {
        sexp* car;
        char* string;
      };
      sexp* cdr;
    } sexp;

    extern sexp nil;
    extern sexp dot;

#ifndef __cplusplus
    inline char*
    new_string ()
    {
      return (char*)malloc (STRING_MAX);
    }
    inline sexp*
    cons (sexp* car, sexp* cdr)
    {
      sexp* x = malloc (sizeof (sexp));
      x->car = car;
      x->cdr = cdr;
      return x;
    }
#else
    inline char*
    new_string ()
    {
      return new char[STRING_MAX];
    }
    inline sexp*
    cons (sexp* car, sexp* cdr)
    {
      return new sexp {car, cdr};
    }
#endif
    inline char*
    append (char* s, int c)
    {
      if (!s) s = new_string ();
      int len = strlen (s);
      s[len++] = c;
      s[len] = 0;
      return s;
    }

    inline sexp*
    lookup (char const* s)
    {
      return cons ((sexp*)s, 0);
    }

    inline int
    ungetchar (int c)
    {
      return ungetc (c, stdin);
    }

    extern int (*read_char)();
    extern int (*unread_char)(int);

    sexp* read_list (int);

    inline sexp*
    read_sexp (int c, char* s)
    {
      if (c == ' ') return read_sexp ('\n', s);
      if (!s)
      {
        if (c == EOF) return &nil;
        if (c == '\n') return read_sexp (read_char (), s);
        if (c == '(') return read_list (read_char ());
        if (c == ')') {unread_char (c); return &nil;}
      }
      else
      {
        if (c == '\n' && !strcmp (s, ".")) return &dot;
        if (c == EOF) return lookup (s);
        if (c == '\n') return lookup (s);
        if (c == '(') {unread_char (c); return lookup (s);};
        if (c == ')') {unread_char (c); return lookup (s);}
      }
      return read_sexp (read_char (), append (s, c));
    }

    inline int
    eat_whitespace (int c)
    {
      while (c == ' ' || c == '\n') c = read_char ();
      return c;
    }

    inline sexp*
    read_list (int c)
    {
      c = eat_whitespace (c);
      if (c == ')') return &nil;
      sexp* s = read_sexp (c, 0);
      if (s == &dot) return read_list (read_char ())->car;
      return cons (s, read_list (read_char ()));
    }

    inline sexp*
    read ()
    {
      return read_sexp (read_char (), 0);
    }

    inline void
    print_string (char const* s)
    {
      fputs (s, stdout);
    }

#ifndef __cplusplus
    sexp* display (sexp* x, void (*print)(char const*));
#else
    sexp* display (sexp* x, void (*print)(char const*)=print_string);
#endif

    inline sexp*
    display_helper (sexp* x, int cont, char const* sep, void (*print)(char const*))
    {
      print (sep);
      if (x == &nil)
        ;
      else if (x->cdr)
      {
        if (!cont) print ("(");
        display (x->car, print);
        if (x->cdr && x->cdr->cdr)
          display_helper (x->cdr, 1, " ", print);
        else
        {
          if (x->cdr != &nil)
            print (" . ");
          display (x->cdr, print);
        }
        if (!cont) print (")");
      }
      else
        print (x->string);
      return &nil;
    }

    inline sexp*
    display (sexp* x, void (*print)(char const*))
    {
      return display_helper (x, 0, "", print);
    }

    inline sexp*
    newline (void (*print)(char const*))
    {
      print ("\n");
      return &nil;
    }

    extern char const* global_string;
    extern int global_pos;

    inline int
    string_read_char ()
    {
      int c = global_string[global_pos++];
      return c ? c : EOF;
    }

    inline int
    string_unread_char (int c)
    {
      global_pos--;
      //assert (global_string[global_pos] == c);
      return c;
    }

    inline sexp*
    read_from_string (char const* s)
    {
      // TODO: save these
      global_pos = 0;
      global_string = s;
      read_char = string_read_char;
      unread_char = string_unread_char;
      return read ();
    }

    #ifdef __cplusplus
    inline std::list<sexp*>
    sexp_to_list (sexp* s)
    {
      std::list<sexp*> list;
      while (s != &nil)
      {
        list.push_back (s->car);
        s = s->cdr;
      }
      return list;
    }

    inline std::string
    sexp_to_string (sexp* s)
    {
      if (!s->cdr) return s->string;
      if (s->cdr == &nil) return s->car->string;
      return std::string (s->car->string) + "." + sexp_to_string (s->cdr);
    }

    inline std::map<std::string,std::string>
    sexp_to_alist (sexp* s)
    {
      std::map<std::string,std::string> alist;
      while (s != &nil)
      {
        alist[sexp_to_string (s->car->car)] = sexp_to_string (s->car->cdr);
        s = s->cdr;
      }
      return alist;
    }

    template<typename R>
    struct foo { static R
    value (std::string& str)
      {
        std::clog << "FIXME: fix STRING_TO_ENUM" << std::endl;
      }
    };

    template<>
    struct foo<bool> {static bool
    value (std::string& str)
      {
        if (str == "#f") return false;
        if (str == "#t") return true;
      }
    };

    template<>
    struct foo<int> {static int
    value (std::string& str)
      {
      return std::atoi (str.c_str ());
      }
    };
#endif

#if 0
#ifndef __cplusplus

    int
    main ()
    {
      char *s = "foo";
      display (read_from_string (s), print_string);
      newline (print_string);
      s = "(bar)";
      display (read_from_string (s), print_string);
      newline (print_string);
      s = "((one . ((foo . 0) (bar . 1) (baz . 2))) ((sut two) . ((baz . 3) (bla . 4))))";
      display (read_from_string (s), print_string);
      newline (print_string);
    }

#else //__cplusplus
    int
    main ()
    {
      display (read_from_string( "foo"));
      std::cout << std::endl;
      display (read_from_string( "(bar)"));
      std::cout << std::endl;
      std::string string = "((one . ((foo . 0) (bar . 1) (baz . 2))) ((sut two) . ((baz . 3) (bla . 4))))";
      sexp* s = read_from_string (string.c_str ());
      display (s);
      std::cout << std::endl;

      std::list<sexp*> list = sexp_to_list (s);
      std::map<std::string,std::map<std::string,std::string>> global_string_alist;
      std::for_each (list.begin (), list.end (),
                     [&] (sexp* s)
                     {
                       global_string_alist[sexp_to_string (s->car)] = sexp_to_alist (s->cdr);
                     });
      std::cout << "one::foo: " << global_string_alist["one"]["foo"] << std::endl;
      std::cout << "one::bar: " << global_string_alist["one"]["bar"] << std::endl;
      std::cout << "sut.two:baz: " << global_string_alist["sut.two"]["baz"] << std::endl;
      std::cout << "sut.two::bla: " << global_string_alist["sut.two"]["bla"] << std::endl;
    }

#endif
#endif
  }
}

#endif //DZN_SEXP_HH
