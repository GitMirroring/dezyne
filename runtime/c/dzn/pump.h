// dzn-runtime -- Dezyne runtime library
// Copyright © 2023 Jan Nieuwenhuizen <janneke@gnu.org>
//
// This file is part of dzn-runtime.
//
// dzn-runtime is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// dzn-runtime is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with dzn-runtime.  If not, see <http://www.gnu.org/licenses/>.
//
// Commentary:
//
// Code:

#ifndef DZN_PUMP_H
#define DZN_PUMP_H

#include <dzn/config.h>
#include <dzn/closure.h>
#include <dzn/coroutine.h>
#include <dzn/list.h>
#include <dzn/runtime.h>

typedef struct dzn_pump dzn_pump;
struct dzn_pump
{
  int id;
  dzn_list* blocked;
  dzn_list* collateral;
  dzn_list* deferred;
  dzn_list* q;
  dzn_list* released;
  dzn_coroutine invoking;
  long invoking_id;
};

void dzn_pump_init (dzn_pump* self);
void dzn_pump_run (dzn_pump* self, dzn_closure* event);
void dzn_pump_block (dzn_pump* self, dzn_interface* port);
void dzn_pump_release (dzn_pump* self, dzn_interface* port);
bool dzn_pump_port_blocked_p (dzn_pump* pump, dzn_interface* port);
void dzn_pump_collateral_block (dzn_pump* pump, dzn_interface* port, long id);
void dzn_pump_finalize (dzn_pump* self);
void dzn_pump_run_defer (dzn_pump* self);
void dzn_pump_defer (dzn_pump* self, dzn_component* component, dzn_closure* predicate, dzn_closure* defer);
void dzn_pump_prune_deferred (dzn_pump* self);

////////////////////////////////////////////////////////////////////////////////
// Runtime
void dzn_port_block (dzn_component* component, dzn_interface* port);
void dzn_port_release (dzn_component* component, dzn_interface* port);
bool dzn_port_blocked_p (dzn_component* component, dzn_interface* port);
void dzn_collateral_block (dzn_component* component, dzn_interface* port);
void dzn_defer (dzn_component* component, dzn_closure* predicate, dzn_closure* defer);
void dzn_prune_deferred (dzn_component* component);
////////////////////////////////////////////////////////////////////////////////

#endif /* DZN_PUMP_H */
