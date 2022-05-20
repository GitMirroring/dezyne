# Dezyne --- Dezyne command line tools
#
# Copyright © 2019, 2020, 2021, 2022 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
# Copyright © 2020, 2021, 2022 Rutger van Beusekom <rutger@dezyne.org>
# Copyright © 2020, 2021, 2022 Paul Hoogendijk <paul@dezyne.org>
# Copyright © 2020 Johri van Eerd <vaneerd.johri@gmail.com>
# Copyright © 2020 Rob Wieringa <rma.wieringa@gmail.com>
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

EXTRA_DIST += %D%/README

SMOKE_TESTS =					\
 %D%/parse_syntax				\
 %D%/parse_type_mismatch			\
 %D%/hello					\
 %D%/compliance_provides_bool

HELLO_TESTS =					\
 %D%/compliance0				\
 %D%/compliance_external			\
 %D%/deadlock_component0			\
 %D%/deadlock_implicit				\
 %D%/deadlock_interface0			\
 %D%/determinism0				\
 %D%/determinism1				\
 %D%/determinism_out				\
 %D%/determinism_interface			\
 %D%/hello_alpha				\
 %D%/hello_async				\
 %D%/hello_block				\
 %D%/hello_blocking_external			\
 %D%/hello_bool					\
 %D%/hello_comment				\
 %D%/hello_data					\
 %D%/hello_else					\
 %D%/hello_expression				\
 %D%/hello_external				\
 %D%/hello_external_inevitable			\
 %D%/hello_flush				\
 %D%/hello_foreign				\
 %D%/hello_function				\
 %D%/hello_function_argument			\
 %D%/hello_function_void_bool_if		\
 %D%/hello_global_enum				\
 %D%/hello_global_int				\
 %D%/hello_guard				\
 %D%/hello_if					\
 %D%/hello_if_action				\
 %D%/hello_incomplete				\
 %D%/hello_inevitable				\
 %D%/hello_injected				\
 %D%/hello_interface				\
 %D%/hello_local				\
 %D%/hello_local_bool				\
 %D%/hello_locations				\
 %D%/hello_multiple_provides			\
 %D%/hello_nondet				\
 %D%/hello_nondet_reply				\
 %D%/hello_optional				\
 %D%/hello_otherwise				\
 %D%/hello_out					\
 %D%/hello_out_state				\
 %D%/hello_parse				\
 %D%/hello_reorder				\
 %D%/hello_reply				\
 %D%/hello_system				\
 %D%/hello_system_reply				\
 %D%/hello_two					\
 %D%/hello_usuk					\
 %D%/illegal_component0				\
 %D%/illegal_interface_incomplete		\
 %D%/livelock_interface0			\
 %D%/livelock_component				\
 %D%/queuefull_component0			\
 %D%/semantics					\
 %D%/state-diagram

SEMANTICS_TESTS =				\
 %D%/direct_in					\
 %D%/direct_out					\
 %D%/indirect_out				\
 %D%/indirect_in				\
 %D%/direct_multiple_out1			\
 %D%/direct_multiple_out2			\
 %D%/indirect_multiple_out1			\
 %D%/indirect_multiple_out2			\
 %D%/indirect_multiple_out3			\
 %D%/indirect_blocking_out			\
 %D%/external_multiple_out1			\
 %D%/external_multiple_out2			\
 %D%/external_multiple_out3			\
 %D%/indirect_blocking_multiple_external_out

REGRESSION_TESTS =				\
 %D%/alpha_event				\
 %D%/alpha_field_test				\
 %D%/alpha_local				\
 %D%/alpha_shadow_port				\
 %D%/alpha_variable				\
 %D%/assign_formal				\
 %D%/async_async_prio				\
 %D%/async_blocking				\
 %D%/async_blocking_missing_ack			\
 %D%/async_blocking_ranking_disorder		\
 %D%/async_blocking_verify			\
 %D%/async_calling_context			\
 %D%/async_cancel				\
 %D%/async_context				\
 %D%/async_flush				\
 %D%/async_multiple_provides			\
 %D%/async_order				\
 %D%/async_order2				\
 %D%/async_prio					\
 %D%/async_prio2				\
 %D%/async_prio3				\
 %D%/async_provides				\
 %D%/async_rank					\
 %D%/async_ranking				\
 %D%/async_shell				\
 %D%/async_simple				\
 %D%/async_sync_prio				\
 %D%/async_synccb				\
 %D%/async_synccb2				\
 %D%/async_types				\
 %D%/blocking-local-state-diagram		\
 %D%/blocking_binding				\
 %D%/blocking_bottom_system			\
 %D%/blocking_cancel_race			\
 %D%/blocking_cancel_race_bool			\
 %D%/blocking_double_release			\
 %D%/blocking_external				\
 %D%/blocking_function				\
 %D%/blocking_function_reply			\
 %D%/blocking_if_reply				\
 %D%/blocking_imperative			\
 %D%/blocking_local				\
 %D%/blocking_multiple_provides			\
 %D%/blocking_multiple_provides0		\
 %D%/blocking_multiple_provides2		\
 %D%/blocking_multiple_provides3		\
 %D%/blocking_mux				\
 %D%/blocking_normalize				\
 %D%/blocking_provides_state			\
 %D%/blocking_queuefull				\
 %D%/blocking_queuefull_reply			\
 %D%/blocking_race				\
 %D%/blocking_race_async			\
 %D%/blocking_release				\
 %D%/blocking_requires				\
 %D%/blocking_requires_normalize		\
 %D%/blocking_shell				\
 %D%/blocking_sync_asynchronous_out		\
 %D%/blocking_system				\
 %D%/blocking_system2				\
 %D%/blocking_system3				\
 %D%/blocking_system4				\
 %D%/blocking_system_diamond			\
 %D%/calling_context				\
 %D%/collateral_blocking_async			\
 %D%/collateral_blocking_backdoor		\
 %D%/collateral_blocking_bridges		\
 %D%/collateral_blocking_double_release		\
 %D%/collateral_blocking_multiple_provides	\
 %D%/collateral_blocking_multiple_provides2	\
 %D%/collateral_blocking_release		\
 %D%/collateral_blocking_reorder		\
 %D%/collateral_blocking_reorder_bypass		\
 %D%/collateral_blocking_reply			\
 %D%/collateral_blocking_shell			\
 %D%/collateral_blocking_shell2			\
 %D%/collateral_blocking_top			\
 %D%/collateral_double_blocked			\
 %D%/collateral_double_blocked_out		\
 %D%/compliance_async				\
 %D%/compliance_blocking_async_race		\
 %D%/compliance_blocking_function		\
 %D%/compliance_blocking_multiple_provides	\
 %D%/compliance_blocking_out			\
 %D%/compliance_external_inevitable		\
 %D%/compliance_failures_blocking		\
 %D%/compliance_failures_blocking_race		\
 %D%/compliance_failures_choice			\
 %D%/compliance_failures_illegal		\
 %D%/compliance_failures_inevitable		\
 %D%/compliance_failures_inevitable_optional    \
 %D%/compliance_failures_multiple_provides	\
 %D%/compliance_failures_optional		\
 %D%/compliance_fork_provides			\
 %D%/compliance_fork_requires			\
 %D%/compliance_implicit_illegal		\
 %D%/compliance_invalid_action			\
 %D%/compliance_livelock			\
 %D%/compliance_livelock_escape			\
 %D%/compliance_nonsynchronous_sync		\
 %D%/compliance_optional			\
 %D%/compliance_out_sync			\
 %D%/compliance_provides_bool			\
 %D%/compliance_provides_illegal		\
 %D%/compliance_provides_illegal4		\
 %D%/compliance_provides_illegal5		\
 %D%/compliance_provides_int			\
 %D%/compliance_provides_out			\
 %D%/compliance_reply_bool			\
 %D%/compliance_requires_illegal		\
 %D%/compliance_single_to_multiple		\
 %D%/compliance_sync_action			\
 %D%/compliance_system_provides_bool		\
 %D%/component_modeling_loop			\
 %D%/data_full					\
 %D%/deadlock_asynchronous_sync_reply		\
 %D%/deadlock_blocking_compliance		\
 %D%/deadlock_blocking_flush			\
 %D%/deadlock_blocking_guard			\
 %D%/deadlock_blocking_inevitable		\
 %D%/deadlock_blocking_optional			\
 %D%/deadlock_blocking_replies			\
 %D%/deadlock_component1			\
 %D%/deadlock_interface1			\
 %D%/deadlock_optional_out_only			\
 %D%/deadlock_port_blocked			\
 %D%/deadlock_reply				\
 %D%/deadlock_reply_modeling			\
 %D%/determinism_async				\
 %D%/determinism_deadlock			\
 %D%/determinism_modeling			\
 %D%/determinism_silent				\
 %D%/dollars					\
 %D%/double_collateral_blocking_shell		\
 %D%/double_hello_block				\
 %D%/empty_dollars				\
 %D%/end_of_trail				\
 %D%/end_of_trail_action			\
 %D%/end_of_trail_action2			\
 %D%/end_of_trail_interface			\
 %D%/end_of_trail_interface_action		\
 %D%/enum_expressions				\
 %D%/equal_binary				\
 %D%/extern_in_interface			\
 %D%/external_asynchronous_sync			\
 %D%/external_blocking_livelock                 \
 %D%/external_requires_twice			\
 %D%/failures_inevitable			\
 %D%/failures_nondet_inevitable			\
 %D%/failures_second_inevitable			\
 %D%/foreign_import_system			\
 %D%/foreign_injected				\
 %D%/foreign_namespace				\
 %D%/foreign_optional				\
 %D%/foreign_reply				\
 %D%/function_early_return			\
 %D%/function_out_state				\
 %D%/function_reply_early_return		\
 %D%/guard_expressions				\
 %D%/hello_blocking_asynchronous_sync_out	\
 %D%/hello_blocking_multiple_out		\
 %D%/hello_choice_action			\
 %D%/hello_choice_reply				\
 %D%/hello_clash_port_variable			\
 %D%/hello_complete_action			\
 %D%/hello_complete_reply			\
 %D%/hello_enum					\
 %D%/hello_enum_function			\
 %D%/hello_foreign_file				\
 %D%/hello_foreign_path				\
 %D%/hello_function_assign			\
 %D%/hello_function_local			\
 %D%/hello_function_local_nest			\
 %D%/hello_garbage				\
 %D%/hello_guard_two				\
 %D%/hello_ifelse				\
 %D%/hello_ifif					\
 %D%/hello_implicit_enum			\
 %D%/hello_implicit_illegal			\
 %D%/hello_implicit_temporaries			\
 %D%/hello_import_component			\
 %D%/hello_imported				\
 %D%/hello_inevitable_action			\
 %D%/hello_inevitable_blocking_sync_out		\
 %D%/hello_inevitable_hidden			\
 %D%/hello_inevitable_illegal			\
 %D%/hello_inevitable_sync_out			\
 %D%/hello_int					\
 %D%/hello_interface_function			\
 %D%/hello_interface_optional			\
 %D%/hello_local_assign				\
 %D%/hello_local_enum				\
 %D%/hello_match				\
 %D%/hello_modeling_nondet			\
 %D%/hello_multiple_out				\
 %D%/hello_multiple_provides_requires		\
 %D%/hello_namespace_enum			\
 %D%/hello_namespace_foreign			\
 %D%/hello_namespace_shadow			\
 %D%/hello_namespace_shadow2			\
 %D%/hello_optional_flush			\
 %D%/hello_optional_nondet			\
 %D%/hello_out_data				\
 %D%/hello_out_provides				\
 %D%/hello_provides				\
 %D%/hello_recursive				\
 %D%/hello_shadow				\
 %D%/hello_sync_out_reply			\
 %D%/hello_systems				\
 %D%/hello_tail_recursive_function		\
 %D%/hello_tick					\
 %D%/hello_true_guard				\
 %D%/hello_unused_assign			\
 %D%/hellocheckcompbindings			\
 %D%/hellochecksystembindings			\
 %D%/hellofundata				\
 %D%/hellointbug				\
 %D%/hellooutevent				\
 %D%/helloparam					\
 %D%/helloparams				\
 %D%/helloworld					\
 %D%/illegal_async_req				\
 %D%/illegal_blocking_race			\
 %D%/illegal_external_inevitable		\
 %D%/illegal_external_requires_twice		\
 %D%/illegal_external_requires_twice2		\
 %D%/illegal_garbage				\
 %D%/illegal_interface.space			\
 %D%/illegal_pessimism_external			\
 %D%/illegal_provides				\
 %D%/illegal_requires				\
 %D%/illegal_requires2				\
 %D%/illegal_requires_out			\
 %D%/illegal_system_requires			\
 %D%/importPath					\
 %D%/imported.space				\
 %D%/inevitable_multiple_requires		\
 %D%/inevitable_performance			\
 %D%/injected_dangling				\
 %D%/inner.space				\
 %D%/integer_expressions			\
 %D%/label_instance_mismatch			\
 %D%/livelock_async				\
 %D%/livelock_async_cancel			\
 %D%/livelock_async_choice			\
 %D%/livelock_iterator				\
 %D%/livelock_recurse				\
 %D%/livelock_synchronous			\
 %D%/livelock_unfold				\
 %D%/match_blocking_race			\
 %D%/missing_reply				\
 %D%/multiple_parallel_blocking			\
 %D%/multiple_provides				\
 %D%/name.space					\
 %D%/pump_twice					\
 %D%/queue_size_four				\
 %D%/queuefull_component1			\
 %D%/queuefull_external				\
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
 %D%/requires_twice				\
 %D%/resolve_formal				\
 %D%/resolve_member				\
 %D%/second_reply				\
 %D%/second_reply_sync				\
 %D%/second_reply_blocking			\
 %D%/shell_injected				\
 %D%/simple.space				\
 %D%/space.import_interface_shadow		\
 %D%/space.interface_shadow			\
 %D%/space.space				\
 %D%/state_deadlock				\
 %D%/step_state					\
 %D%/stress_comment				\
 %D%/system_double_out				\
 %D%/system_flush				\
 %D%/system_hello				\
 %D%/system_hello_world				\
 %D%/system_helloworld				\
 %D%/system_inevitable				\
 %D%/system_mix_bindings			\
 %D%/system_nondet_out				\
 %D%/system_nondet_reply			\
 %D%/system_optional				\
 %D%/system_out					\
 %D%/system_out_internal			\
 %D%/system_out_two				\
 %D%/system_reply_bool				\
 %D%/system_reply_enum				\
 %D%/unused_function

if have_cxx_exception_wrappers
REGRESSION_TESTS +=				\
 %D%/exception_wrappers
else
EXTRA_DIST +=					\
 %D%/exception_wrappers
endif

PARSER_TESTS =					\
 %D%/parse_assign_void				\
 %D%/parse_block_comment_import			\
 %D%/parse_component_without_trigger		\
 %D%/parse_duplicate_definition			\
 %D%/parse_duplicate_import_prefix		\
 %D%/parse_import_both				\
 %D%/parse_import_end				\
 %D%/parse_import_path				\
 %D%/parse_import_self				\
 %D%/parse_import_twice				\
 %D%/parse_interface_parens			\
 %D%/parse_locations				\
 %D%/parse_missing_event			\
 %D%/parse_mixing_imperative			\
 %D%/parse_non_existent_import			\
 %D%/parse_on_without_statement			\
 %D%/parse_out_binding				\
 %D%/parse_out_binding_argument			\
 %D%/parse_parameter_mismatch			\
 %D%/parse_peg_locations			\
 %D%/parse_preprocessed_foo			\
 %D%/parse_preprocessed_imported_bar		\
 %D%/parse_preprocessed_imported_baz		\
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
 %D%/wf_bindingSameType				\
 %D%/wf_blockingInblocking			\
 %D%/wf_blockingInInterface			\
 %D%/wf_blockingReply				\
 %D%/wf_blocking_port				\
 %D%/wf_componentNeedsProvides			\
 %D%/wf_componentNeedsTrigger			\
 %D%/wf_coverageDuplicate			\
 %D%/wf_coverageUnexpected			\
 %D%/wf_dataInoutInOutEvent			\
 %D%/wf_dataOutInOutEvent			\
 %D%/wf_declarativeImperative			\
 %D%/wf_definedBefore				\
 %D%/wf_eventNotAction				\
 %D%/wf_eventNotTrigger				\
 %D%/wf_eventNotValuedAction			\
 %D%/wf_expressionExpected			\
 %D%/wf_foreign_conflict			\
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
 %D%/wf_interfaceMustDefineBehavior		\
 %D%/wf_interfaceMustDefineEvent		\
 %D%/wf_missing_bindings			\
 %D%/wf_NameClash				\
 %D%/wf_notPort					\
 %D%/wf_onEventInOnEvent			\
 %D%/wf_otherwiseWithNonGuard			\
 %D%/wf_otherwiseWithOtherwise			\
 %D%/wf_outEventNonVoidReturn			\
 %D%/wf_parameterBinding			\
 %D%/wf_parameterDataType			\
 %D%/wf_replyFunctionExpression			\
 %D%/wf_replyFunctionMultiplePort		\
 %D%/wf_replyOnOutEventMultiplePort		\
 %D%/wf_replyOnPort				\
 %D%/wf_replyOnType				\
 %D%/wf_replyPort				\
 %D%/wf_replyRequiresPort			\
 %D%/wf_replyTypeMismatch			\
 %D%/wf_subintMinMax				\
 %D%/wf_systemRecursion				\
 %D%/wf_typeerror				\
 %D%/wf_undefined				\
 %D%/wf_undefined_function			\
 %D%/wf_variableInitExpression			\
 %D%/undefined/and				\
 %D%/undefined/group				\
 %D%/undefined/not				\
 %D%/undefined/reply				\
 %D%/undefined/return				\
 %D%/undefined/component/action			\
 %D%/undefined/component/argument		\
 %D%/undefined/component/argument_seen		\
 %D%/undefined/component/enum_as_action		\
 %D%/undefined/component/port			\
 %D%/undefined/component/trigger		\
 %D%/undefined/formal_type			\
 %D%/undefined/guard				\
 %D%/undefined/if				\
 %D%/undefined/interface/action			\
 %D%/undefined/interface/function		\
 %D%/undefined/interface/trigger		\
 %D%/undefined/var

UNSTABLE_TESTS =				\
 %D%/compliance_blocking_double_release		\
 %D%/illegal_external_nonsynchronous		\
 %D%/livelock_synchronous_illegal		\
 %D%/queuefull_external_sync

XFAIL_TESTS =					\
 %D%/async_blocking_missing_ack			\
 %D%/async_blocking_ranking_disorder		\
 %D%/async_blocking_verify			\
 %D%/collateral_blocking_async			\
 %D%/compliance_livelock			\
 %D%/compliance_livelock_escape			\
 %D%/external_blocking_livelock

FULL_TESTS =					\
 $(SMOKE_TESTS)					\
 $(HELLO_TESTS)					\
 $(SEMANTICS_TESTS)				\
 $(PARSER_TESTS)				\
 $(REGRESSION_TESTS)
