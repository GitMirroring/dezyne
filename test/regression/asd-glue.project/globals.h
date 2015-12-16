// Dezyne --- Dezyne command line tools
//
// Copyright © 2015 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef GLOBALS_H
#define GLOBALS_H

#include "asdPassByValue.h"

#include <boost/shared_ptr.hpp>

constexpr int DTXAxWFRxQUAL_wfr_reject_reason_data_inconsistency = 0;
constexpr int DTXAxWFRxQUAL_wfr_reject_reason_exception = 0;
constexpr int DTXAxWFRxQUAL_wfr_reject_reason_lot_aborted = 0;
constexpr int DTXAxWFRxQUAL_wfr_reject_reason_closing_wafer_refresh = 0;
constexpr int DTXAxWFRxQUAL_wfr_reject_reason_lot_stopped = 0;
constexpr int INFINITE_TIMEOUT = 0;
constexpr int OK = 0;
constexpr int LOPW_EVENT_SS1 = 1;
constexpr int LOPW_EVENT_SS2 = 2;
constexpr int LOPW_EVENT_MACTIONS = 3;
constexpr int LOPW_UNDEFINED_LOT_ID = 4;

typedef int ASML_bool;
typedef int ASML_result;
typedef int CNXA_repl_addr;
typedef int DTXA_wafer_id_struct;
typedef int DTXA_wafer_id_struct_ptr;
typedef int DTXAxWFRxQUAL_wfr_reject;
typedef int DTXAxWFRxQUAL_wfr_reject_reason_enum;
typedef int LOMW_coarse_align_results_ptr;
typedef int LOMW_late_wafer_results_ptr;
typedef int LOMW_late_wafer_results_ptr;
typedef int LOMW_measure_results_ptr;
typedef int LOPW_process_elem_id_struct_ptr;
typedef int LOTD_task_context_t;
typedef int LOTD_task_context_t_ptr;
typedef int LOxWH_recovery_enum;
typedef int PLXAtimestamp;
typedef int WHxSTREAM_recovery_enum;
typedef int WPxCHUCK_chuck_id_enum;
typedef int bool1;
typedef int std_string;
typedef int xint;

struct LOPWxLotSettings {typedef int reason_enum;};
struct DTXA_wfr_reject {struct reason_enum {typedef int type;};};
struct LOxORDER {struct reason_enum {typedef int type;};};

namespace asd
{
  template <typename T>
  struct value<T*>
  {
    typedef T type;
  };
}


#endif //GLOBALS_H
