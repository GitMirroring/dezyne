# Dezyne --- Dezyne command line tools
#
# Copyright © 2019 Jan Nieuwenhuizen <janneke@gnu.org>
#
# This file is part of Dezyne.
#
# Dezyne is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Dezyne is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public
# License along with Dezyne.  If not, see <http://www.gnu.org/licenses/>.
#
# Commentary:
#
# Code:

SMOKE_TESTS =					\
 %D%/parse_type_mismatch			\
 %D%/hello					\
 %D%/compliance_provides_bool

HELLO_TESTS =					\
 %D%/compliance0				\
 %D%/deadlock_component0			\
 %D%/deadlock_component1			\
 %D%/deadlock_interface0			\
 %D%/deadlock_interface1			\
 %D%/determinism0				\
 %D%/determinism1				\
 %D%/hello_alpha				\
 %D%/hello_async				\
 %D%/hello_block				\
 %D%/hello_bool					\
 %D%/hello_comment				\
 %D%/hello_data					\
 %D%/hello_expression				\
 %D%/hello_flush				\
 %D%/hello_foreign				\
 %D%/hello_function				\
 %D%/hello_function_argument			\
 %D%/hello_global_enum				\
 %D%/hello_global_int				\
 %D%/hello_guard				\
 %D%/hello_if					\
 %D%/hello_interface				\
 %D%/hello_local				\
 %D%/hello_multiple_provides			\
 %D%/hello_optional				\
 %D%/hello_otherwise				\
 %D%/hello_out					\
 %D%/hello_parse				\
 %D%/hello_reorder				\
 %D%/hello_system				\
 %D%/hello_two					\
 %D%/illegal_component0				\
 %D%/illegal_hello_external			\
 %D%/livelock_component0			\
 %D%/livelock_component1			\
 %D%/livelock_interface0			\
 %D%/queuefull_component0

REGRESSION_TESTS =				\
 %D%/alpha_event				\
 %D%/async_async_prio				\
 %D%/async_blocking				\
 %D%/async_cancel				\
 %D%/async_context				\
 %D%/async_context2				\
 %D%/async_context3				\
 %D%/async_flush				\
 %D%/async_multiple_provides			\
 %D%/async_nondet				\
 %D%/async_order				\
 %D%/async_order2				\
 %D%/async_prio					\
 %D%/async_prio2				\
 %D%/async_prio3				\
 %D%/async_rank					\
 %D%/async_ranking				\
 %D%/async_silent				\
 %D%/async_simple				\
 %D%/async_synccb				\
 %D%/async_synccb2				\
 %D%/async_sync_prio				\
 %D%/blocking_binding				\
 %D%/blocking_imperative			\
 %D%/blocking_normalize				\
 %D%/blocking_requires				\
 %D%/blocking_requires_normalize		\
 %D%/blocking_system				\
 %D%/blocking_system2				\
 %D%/blocking_system3				\
 %D%/blocking_system4				\
 %D%/calling_context				\
 %D%/compliance_external_asynchronous_sync	\
 %D%/compliance_livelock			\
 %D%/compliance_out_inevitable			\
 %D%/compliance_out_nondet			\
 %D%/compliance_out_sync			\
 %D%/compliance_provides_bool			\
 %D%/compliance_provides_illegal4		\
 %D%/compliance_provides_illegal5		\
 %D%/compliance_provides_int			\
 %D%/compliance_provides_out			\
 %D%/compliance_reply_bool			\
 %D%/compliance_requires_illegal		\
 %D%/deadlock_blocking_guard			\
 %D%/deadlock_blocking_inevitable		\
 %D%/deadlock_blocking_optional			\
 %D%/dollars					\
 %D%/empty_dollars				\
 %D%/enum_expressions				\
 %D%/external_asynchronous_sync			\
 %D%/extern_in_interface			\
 %D%/foreign_namespace				\
 %D%/glue-dzn					\
 %D%/guard_expressions				\
 %D%/hello_blocked_external			\
 %D%/hello_blocking_sync			\
 %D%/hellocheckcompbindings			\
 %D%/hellochecksystembindings			\
 %D%/hello_clash_port_variable			\
 %D%/hello_enum					\
 %D%/hello_enum_function			\
 %D%/hello_foreign_conflict			\
 %D%/hello_foreign_file				\
 %D%/hello_foreign_path				\
 %D%/hello_function_assign			\
 %D%/hello_function_local			\
 %D%/hello_function_local_nest			\
 %D%/hellofundata				\
 %D%/hello_guard_two				\
 %D%/hello_ifelse				\
 %D%/hello_ifif					\
 %D%/hello_implicit_illegal			\
 %D%/hello_import_component			\
 %D%/hello_inevitable				\
 %D%/hello_inevitable_action			\
 %D%/hello_inevitable_blocking_sync_out		\
 %D%/hello_inevitable_illegal			\
 %D%/hello_inevitable_sync_out			\
 %D%/hello_int					\
 %D%/hellointbug				\
 %D%/hello_interface_function			\
 %D%/hello.interface_namespace			\
 %D%/hello_interface_optional			\
 %D%/hello_interface_out_only			\
 %D%/hello_local_assign				\
 %D%/hello_local_enum				\
 %D%/hello_multiple_out				\
 %D%/hello_multiple_provides_requires		\
 %D%/hello_namespace_enum			\
 %D%/hello_namespace_shadow			\
 %D%/hello_namespace_shadow2			\
 %D%/hello_optional_flush			\
 %D%/hello_optional_system			\
 %D%/hellooutevent				\
 %D%/hellooutparam				\
 %D%/hello_out_provides				\
 %D%/helloparam					\
 %D%/helloparams				\
 %D%/hello_provides				\
 %D%/hello_recursive				\
 %D%/hello_silent				\
 %D%/hello_single_to_multiple			\
 %D%/hello_synchronous_livelock			\
 %D%/hello_systems				\
 %D%/hello_tail_recursive_function		\
 %D%/hello_tick					\
 %D%/hello_true_guard				\
 %D%/helloworld					\
 %D%/illegal_external_asynchronous2		\
 %D%/illegal_provides				\
 %D%/illegal_requires				\
 %D%/illegal_requires2				\
 %D%/illegal_requires_out			\
 %D%/illegal_system_requires			\
 %D%/import_strip_component			\
 %D%/incomplete					\
 %D%/inner.space				\
 %D%/integer_expressions			\
 %D%/label_instance_mismatch			\
 %D%/livelock1					\
 %D%/livelock2					\
 %D%/livelock_component2			\
 %D%/missing_reply				\
 %D%/name.space					\
 %D%/queuefull_external				\
 %D%/queuefull_external_sync			\
 %D%/range_action				\
 %D%/range_argument				\
 %D%/range_assign				\
 %D%/range_declaration				\
 %D%/range_declaration_expression		\
 %D%/range_expression				\
 %D%/range_function				\
 %D%/range_local				\
 %D%/range_member				\
 %D%/range_return				\
 %D%/reply_expression				\
 %D%/reply_modeling				\
 %D%/second_reply				\
 %D%/second_reply_blocking			\
 %D%/shell					\
 %D%/shell_injected				\
 %D%/silent_nondet				\
 %D%/silent_optional				\
 %D%/silent_optional_broken			\
 %D%/silent_optional_function			\
 %D%/simple.space				\
 %D%/state_deadlock				\
 %D%/stress_comment				\
 %D%/system_hello				\
 %D%/system_helloworld				\
 %D%/system_inevitable				\
 %D%/system_nondet_out				\
 %D%/system_nondet_reply			\
 %D%/system_optional				\
 %D%/system_out					\
 %D%/system_out_internal			\
 %D%/system_out_two				\
 %D%/system_reply_bool				\
 %D%/system_reply_enum				\
 %D%/unused_function

PARSER_TESTS =					\
 %D%/wf_actionInExpression			\
 %D%/wf_actionNotInOnEvent			\
 %D%/wf_actionValueDiscarded			\
 %D%/wf_assignmentExpressionNotInEventInstance	\
 %D%/wf_assignmentNotInOnEvent			\
 %D%/wf_bindingCycle				\
 %D%/wf_bindingDoubleWildcard			\
 %D%/wf_bindingExternals			\
 %D%/wf_bindingPortBoundTwice			\
 %D%/wf_bindingPortDirection			\
 %D%/wf_bindingPortNotBound			\
 %D%/wf_bindingRequiredWildcard			\
 %D%/wf_blockingInblocking			\
 %D%/wf_blockingInInterface			\
 %D%/wf_blockingMultipleProvides		\
 %D%/wf_componentNeedsProvides			\
 %D%/wf_componentNeedsTrigger			\
 %D%/wf_coverageDuplicate			\
 %D%/wf_coverageUnexpected			\
 %D%/wf_dataInoutInOutEvent			\
 %D%/wf_dataOutInOutEvent			\
 %D%/wf_declarativeImperative			\
 %D%/wf_eventNotAction				\
 %D%/wf_eventNotTrigger				\
 %D%/wf_eventNotValuedAction			\
 %D%/wf_functionInExpression			\
 %D%/wf_functionReturnNotExpected		\
 %D%/wf_functionReturnValue			\
 %D%/wf_functionTailRecursion			\
 %D%/wf_functionValueDiscarded			\
 %D%/wf_illegalInFunction			\
 %D%/wf_illegalInIf				\
 %D%/wf_illegalOnlyStatement			\
 %D%/wf_imperativeDeclarative			\
 %D%/wf_importPathErr				\
 %D%/wf_injectionOutEvent			\
 %D%/wf_interfaceMustDefineBehaviour		\
 %D%/wf_interfaceMustDefineEvent		\
 %D%/wf_modelingSilent				\
 %D%/wf_NameClash				\
 %D%/wf_onEventInOnEvent			\
 %D%/wf_otherwiseWithNonGuard			\
 %D%/wf_otherwiseWithOtherwise			\
 %D%/wf_outEventNonVoidReturn			\
 %D%/wf_parameterBinding			\
 %D%/wf_parameterDataType			\
 %D%/wf_replyRequiredPort			\
 %D%/wf_replyTypeMismatch			\
 %D%/wf_subintMinMax				\
 %D%/wf_systemRecursion				\
 %D%/wf_typeerror				\
 %D%/wf_variableInitExpression

XFAIL_TESTS =					\
 %D%/compliance_livelock			\
 %D%/blocking_system4				\
 %D%/glue-dzn					\
 %D%/import_strip_component

FULL_TESTS =					\
 $(SMOKE_TESTS)					\
 $(HELLO_TESTS)					\
 $(PARSER_TESTS)				\
 $(REGRESSION_TESTS)
