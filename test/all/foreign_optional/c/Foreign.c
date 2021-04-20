// Dezyne --- Dezyne command line tools
//
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2021 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
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

#include <foreign_optional.h>

/* call "name-of-foreign"_skel_init as follows:
   foreign_skel_init(&(self->base), dezyne_locator, dzn_meta); */

void Foreign_init(Foreign* self, locator* dezyne_locator
#if DZN_TRACING
, dzn_meta* dzn_meta
#endif /* !DZN_TRACING */
)
{
  Foreign_skel_init(&(self->base), dezyne_locator
#if DZN_TRACING
, dzn_meta
#endif /* !DZN_TRACING */
);
}

void Foreign_w_hello(Foreign* self)
{
  fprintf(stderr, "sut.f.w.world\n");
  self->base.w->out.world(self->base.w);
}


/* void Foreign_init(Foreign* self, locator* dezyne_locator */
/* #if DZN_TRACING */
/* , dzn_meta *meta */
/* #endif /\* DZN_TRACING *\/ */
/* ){ */
/*   runtime_info_init(&self->dzn_info, dezyne_locator); */
/*   self->dzn_info.performs_flush = true; */
/*   self->w = &self->w_; */
/*   self->w->meta.provides.address = self; */
/*   self->w->meta.requires.address = 0; */

/*   self->w->in.hello = &in_w_hello_Foreign; */


/* #if DZN_TRACING */
/*   memcpy(&self->meta, meta, sizeof(dzn_meta)); */
/*   	self->w->meta.provides.port = "w"; */
/*   	self->w->meta.provides.meta = &self->meta; */
/*   	self->w->meta.requires.port = ""; */
/*   	self->w->meta.requires.meta = 0; */

/* #endif /\*DZN_TRACING*\/ */
/* } */
