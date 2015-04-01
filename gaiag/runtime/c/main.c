// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Jan Nieuwenhuizen <janneke@gnu.org>
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

// handwritten generic main
#include "locator.h"
#include "runtime.h"

#include "Main.h"

int main() {
  runtime dezyne_runtime;
  runtime_init(&dezyne_runtime);
  locator dezyne_locator;
  locator_init(&dezyne_locator, &dezyne_runtime);

  Main m;
  dzn_meta_t mt = {"m", 0};
  Main_init(&m, &dezyne_locator, &mt);
  m.runner->out.name = "runner";

  m.runner->in.run(m.runner);

  return 0;
}
