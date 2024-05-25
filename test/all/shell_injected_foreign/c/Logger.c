// Dezyne --- Dezyne command line tools
//
// Copyright © 2023, 2024 Janneke Nieuwenhuizen <janneke@gnu.org>
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

#include <shell_injected_foreign.h>

void
Logger_init (Logger *self, dzn_locator *dzn_locator
#if 1 //DZN_TRACING
             , dzn_meta *dzn_meta
#endif /* !DZN_TRACING */
            )
{
  Logger_skel_init (& (self->base), dzn_locator
#if 1 //DZN_TRACING
                    , dzn_meta
#endif /* !DZN_TRACING */
                   );
  self->hello = 20;
}

void
Logger_log_log (Logger *self, char *m)
{
}
