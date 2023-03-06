// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2023 Rutger van Beusekom <rutger@dezyne.org>
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

#include <hello_foreign.h>

/* call "name-of-foreign"_skel_init as follows:
   foreign_skel_init(&(self->base), dzn_locator, dzn_meta); */

void
hello_init (hello* self, dzn_locator* dzn_locator
#if 1 //DZN_TRACING
                  , dzn_meta* dzn_meta
#endif /* !DZN_TRACING */
)
{
  hello_skel_init (&(self->base), dzn_locator
#if 1 //DZN_TRACING
                    , dzn_meta
#endif /* !DZN_TRACING */
                    );
}

void
hello_h_hello (hello* self)
{
}
