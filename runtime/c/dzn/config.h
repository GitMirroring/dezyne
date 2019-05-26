// Dezyne --- Dezyne command line tools
//
// Copyright © 2016, 2019 Jan Nieuwenhuizen <janneke@gnu.org>
// Copyright © 2016 Rob Wieringa <Rob.Wieringa@verum.com>
// Copyright © 2018 Filip Toman <filip.toman@verum.com>
// Copyright © 2016 Rutger van Beusekom <rutger.van.beusekom@verum.com>
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

#ifndef DZN_CONFIG_H
#define DZN_CONFIG_H

/* to activate MISRA C configuration, define DZN_TINY and DZN_MISRA_C_2004 to be equal to 1 */

#ifndef DZN_TINY
#define DZN_TINY 0
#endif

#if (DZN_TINY == 0)

#ifndef DZN_TRACING
#define DZN_TRACING 1
#endif

#ifndef DZN_DYNAMIC_QUEUES
#define DZN_DYNAMIC_QUEUES 1
#endif

#ifndef DZN_LOCATOR_SERVICES
#define DZN_LOCATOR_SERVICES 1
#endif

#endif /* DZN_TINY */

#ifndef DZN_MISRA_C_2004
#define DZN_MISRA_C_2004 0
#endif /* DZN_MISRA_C_2004 */

#if (DZN_MISRA_C_2004 == 1)

#ifndef DZN_DYNAMIC_QUEUES
#define DZN_DYNAMIC_QUEUES 0
#endif

#ifndef DZN_TRACING
#define DZN_TRACING 0
#endif

#ifndef DZN_LOCATOR_SERVICES
#define DZN_LOCATOR_SERVICES 0
#endif

#endif /* DZN_MISRA_C_2004 */


#if DZN_DYNAMIC_QUEUES==0
#define DZN_MAX_ARGS_SIZE 24
#define DZN_QUEUE_SIZE 7
#endif /* !DZN_DYNAMIC_QUEUES */

#endif /* DZN_CONFIG_H */
