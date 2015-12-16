<?xml version="1.0"?>
<asd OmVersion="10.10.0" BackwardOmVersion="10.10.0" Serializer="2" >
	<DesignModel ID="18">
		<Author>Peter&#32;van&#32;de&#32;Velde</Author>
		<CodeGenerationLanguage>cpp</CodeGenerationLanguage>
		<CodeGenerationVersion>9.2.0</CodeGenerationVersion>
		<DateCreated>20100121T150425</DateCreated>
		<DateModified>20160104T142519</DateModified>
		<Guid>7AB01A8DA8854BA09DB9ECB572A15EA0</Guid>
		<ModelSignature>BASE64_LN6FAkkZHFwBFLB1Oln8NPC5MOmvQPI/rYqxq/e10PSy90iHZOosB7DsYxtCvG6wvGMhWnth74YXEk0pTR0y2DZG3T+6mtpEXypxjO0rrCva2a9rEZpCxfhtPB5RmgUkcVGNLL55ayz57qc71QnizQv/qOi6im+lJdcfKbi3Se9gjkmAyOXwCoENM9McHjzoSJik3tWCNNi9O/O09lP2wzWKR1XXwmVEaZl8nHJNqm/uxJQCdEg8F6b2UH3BrdunPmGyMf22jDcvmEAhJ6uqES/Kv6oQ2WHsQaidrzsu6mo3jbgn37QSEZyQBTVC/qRivzKrOU5cGSoBnYCVBJqvJQ==</ModelSignature>
		<Name>AlarmSystem</Name>
		<ToolVersion>ASD:Suite&#32;ModelBuilder&#32;9.2.7(52388)</ToolVersion>
		<AbstractInterface>
			<AbstractInterface ID="20">
				<Guid>C87A6402319E4BBABE71CE5B8DC9EACF</Guid>
				<Events>
					<CallEvent ID="22">
						<Guid>D849ADC0EF514853A0CF4F74E848898A</Guid>
						<Name>StateInvariant</Name>
					</CallEvent>
					<CallEvent ID="24">
						<Guid>84DEE61F60034238A1EDEC85D19FEA49</Guid>
						<Name>DataInvariant</Name>
					</CallEvent>
				</Events>
				<ReplyEvents>
					<ReplyEvent ID="26">
						<Guid>EAE2E4DB6FAA4E7681E63D799063AD7D</Guid>
						<Name>NoOp</Name>
					</ReplyEvent>
					<ReplyEvent ID="28">
						<Guid>8F0CD6C16E1B453883CBC5F7326E1867</Guid>
						<Name>Illegal</Name>
					</ReplyEvent>
					<ReplyEvent ID="30">
						<Guid>6056DBEB478C4BC0A9C08D1BFB76413D</Guid>
						<Name>Blocked</Name>
					</ReplyEvent>
				</ReplyEvents>
			</AbstractInterface>
		</AbstractInterface>
		<BuiltInInterface>
			<BuiltInInterface ID="32">
				<Guid>CDB0F64B073F42E88091147C025CD88F</Guid>
				<Events>
					<CallEvent ID="34">
						<Guid>F29EFB83ED53409d84B64CF57ED6A0F4</Guid>
						<Name>Subscribe</Name>
						<Parameters>
							<USRInterfaceParameter ID="36">
							</USRInterfaceParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="38">
						<Guid>25B76D8404B54f1d8EA5FF22E47C7CE5</Guid>
						<Name>Unsubscribe</Name>
						<Parameters>
							<USRInterfaceParameter ID="40">
							</USRInterfaceParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="42">
						<Guid>8CB0CCD035084481B76B3EC0A974FBF5</Guid>
						<Name>Initialise</Name>
						<Parameters>
							<SimpleParameter ID="44">
								<Direction>pdInOut</Direction>
								<Name>dataVariable</Name>
								<Type>any</Type>
							</SimpleParameter>
						</Parameters>
					</CallEvent>
					<CallEvent ID="46">
						<Guid>444DBCA038BD4EB3AB79CDBF6E531334</Guid>
						<Name>Invalidate</Name>
						<Parameters>
							<SimpleParameter ID="48">
								<Direction>pdInOut</Direction>
								<Name>dataVariable</Name>
								<Type>any</Type>
							</SimpleParameter>
						</Parameters>
					</CallEvent>
				</Events>
				<ReplyEvents>
					<ReplyEvent ID="50">
						<Guid>4689006D1E9D4B5F9F33EE46C7414D81</Guid>
						<Name>VoidReply</Name>
					</ReplyEvent>
				</ReplyEvents>
			</BuiltInInterface>
		</BuiltInInterface>
		<CodeGeneratorSettings>
			<CodeGenInfo ID="52">
				<Language>c</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="54">
				<Language>cpp</Language>
				<SourceFiles>./code/cpp/src/generated</SourceFiles>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="56">
				<Language>csharp</Language>
				<SourceFiles>./code/cs/src/generated</SourceFiles>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="58">
				<Language>java</Language>
				<SourceFiles>./code/java/src/generated</SourceFiles>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
			<CodeGenInfo ID="60">
				<Language>tinyc</Language>
				<UseOldTracing>1</UseOldTracing>
				<UseServiceNameInQualifiedNames>0</UseServiceNameInQualifiedNames>
			</CodeGenInfo>
		</CodeGeneratorSettings>
		<ImplementedService>
			<ServiceDependency ID="62">
				<ModelGuid>E05C3E5F7AB94B278B43F57B1AD4A512</ModelGuid>
				<Name>Console</Name>
				<RelativePath>Console.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="64">
						<ApplicationInterfaces>
							<ApplicationInterface ID="66">
								<Guid>5C33205D81BD4B478E2A927D6D6D68F9</Guid>
								<Name>IAlarmSystem</Name>
								<Events>
									<CallEvent ID="68">
										<Guid>4C9773B966914F4AA774AE1F864033C1</Guid>
										<Name>SwitchOn</Name>
										<ReplyType>rtValued</ReplyType>
									</CallEvent>
									<CallEvent ID="70">
										<Guid>DC93AFC6222348A99D8FA377826EA333</Guid>
										<Name>SwitchOff</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="72">
										<Guid>F25DD592405049E8989A098437D0D90F</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
									<ReplyEvent ID="74">
										<Guid>617b516ee2154ef596d1d237278c2252</Guid>
										<Name>Ok</Name>
									</ReplyEvent>
									<ReplyEvent ID="76">
										<Guid>fb18395a647b4108aff690ae636c14b6</Guid>
										<Name>Failed</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
						<NotificationInterfaces>
							<NotificationInterface ID="78">
								<Guid>9beb82cc47854134a5063a2dee391a7b</Guid>
								<Name>IAlarmSystem_NI</Name>
								<Events>
									<NotificationEvent ID="80">
										<Guid>06a88a197f3f4c0c9791f505fd42ff10</Guid>
										<Name>Tripped</Name>
									</NotificationEvent>
									<NotificationEvent ID="82">
										<Guid>543e6d2b3d4044e6a7cae607816b0276</Guid>
										<Name>SwitchedOff</Name>
									</NotificationEvent>
								</Events>
							</NotificationInterface>
						</NotificationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
		</ImplementedService>
		<MainMachine>
			<MainMachine ID="84">
				<Guid>D3BF3A39BA7F48A38813639C5EBE4C54</Guid>
				<Name>AlarmSystem</Name>
				<States>
					<State ID="86">
						<Guid>8C032F342D554331A57344D7EBFBCEE7</Guid>
						<Name>NotActivated</Name>
						<Rules>
							<Rule ID="88">
								<Event>22</Event>
								<RuleCases>
									<RuleCase ID="90">
										<Row>2</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="92">
								<Event>24</Event>
								<RuleCases>
									<RuleCase ID="94">
										<Row>3</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="96">
								<Event>68</Event>
								<RuleCases>
									<RuleCase ID="98">
										<Comment>Activate&#32;sensor</Comment>
										<Row>4</Row>
										<NextState>99</NextState>
										<Actions>
											<Action ID="101">
												<Event>102</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="104">
														<ServiceReference>105</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="107">
												<Event>74</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="109">
								<Event>70</Event>
								<RuleCases>
									<RuleCase ID="111">
										<Comment>Illegal&#32;-&#32;alarm&#32;not&#32;activated&#32;</Comment>
										<Row>5</Row>
										<Actions>
											<Action ID="113">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="115">
								<Event>116</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="118">
										<Row>6</Row>
										<Actions>
											<Action ID="120">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="122">
								<Event>123</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="125">
										<Row>7</Row>
										<Actions>
											<Action ID="127">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="99">
						<Guid>FB5CD073F8774024A56CDDFD0ADFB0FC</Guid>
						<Name>Activated_Idle</Name>
						<Rules>
							<Rule ID="138">
								<Event>22</Event>
								<RuleCases>
									<RuleCase ID="140">
										<Row>9</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="142">
								<Event>24</Event>
								<RuleCases>
									<RuleCase ID="144">
										<Row>10</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="146">
								<Event>68</Event>
								<RuleCases>
									<RuleCase ID="148">
										<Comment>Illegal&#32;-&#32;alarm&#32;system&#32;already&#32;activated</Comment>
										<Row>11</Row>
										<Actions>
											<Action ID="150">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="152">
								<Event>70</Event>
								<RuleCases>
									<RuleCase ID="154">
										<Comment>Deactivate&#32;sensor</Comment>
										<Row>12</Row>
										<NextState>155</NextState>
										<Actions>
											<Action ID="157">
												<Event>158</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="160">
														<ServiceReference>105</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="162">
												<Event>72</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="164">
								<Event>116</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="166">
										<Comment>Sensor&#32;dectected&#32;movement&#32;-&#32;start&#32;timer</Comment>
										<Row>13</Row>
										<NextState>167</NextState>
										<Actions>
											<Action ID="169">
												<Event>80</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="178">
								<Event>123</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="180">
										<Row>14</Row>
										<Actions>
											<Action ID="182">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="155">
						<Guid>43F59121DB78441085B36C9EC09F13F2</Guid>
						<Name>Deactivating</Name>
						<Rules>
							<Rule ID="241">
								<Event>22</Event>
								<RuleCases>
									<RuleCase ID="243">
										<Row>16</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="245">
								<Event>24</Event>
								<RuleCases>
									<RuleCase ID="247">
										<Row>17</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="249">
								<Event>68</Event>
								<RuleCases>
									<RuleCase ID="251">
										<Comment>Illegal&#32;-&#32;alarm&#32;system&#32;still&#32;activate</Comment>
										<Row>18</Row>
										<Actions>
											<Action ID="253">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="255">
								<Event>70</Event>
								<RuleCases>
									<RuleCase ID="257">
										<Comment>Illegal&#32;-&#32;alarm&#32;system&#32;switching&#32;off</Comment>
										<Row>19</Row>
										<Actions>
											<Action ID="259">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="261">
								<Event>116</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="263">
										<Row>20</Row>
										<NextState>155</NextState>
										<Actions>
											<Action ID="3441">
												<Event>26</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="267">
								<Event>123</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="269">
										<Comment>Sensor&#32;deactivated&#32;-&#32;alarm&#32;system&#32;switched&#32;off</Comment>
										<Row>21</Row>
										<NextState>86</NextState>
										<Actions>
											<Action ID="271">
												<Event>82</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
					<State ID="167">
						<Guid>0BA3EE18AFA3485FBD380E1340DE3174</Guid>
						<Name>Activated_Tripped</Name>
						<Rules>
							<Rule ID="280">
								<Event>22</Event>
								<RuleCases>
									<RuleCase ID="282">
										<Row>23</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="284">
								<Event>24</Event>
								<RuleCases>
									<RuleCase ID="286">
										<Row>24</Row>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="288">
								<Event>68</Event>
								<RuleCases>
									<RuleCase ID="290">
										<Comment>Illegal&#32;-&#32;alarm&#32;system&#32;already&#32;activated</Comment>
										<Row>25</Row>
										<Actions>
											<Action ID="292">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="294">
								<Event>70</Event>
								<RuleCases>
									<RuleCase ID="296">
										<Comment>Cancel&#32;timer,&#32;deactive&#32;sensor</Comment>
										<Row>26</Row>
										<NextState>155</NextState>
										<Actions>
											<Action ID="303">
												<Event>158</Event>
												<USRExpression>
													<ServiceReferenceExpression ID="305">
														<ServiceReference>105</ServiceReference>
													</ServiceReferenceExpression>
												</USRExpression>
											</Action>
											<Action ID="307">
												<Event>72</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="309">
								<Event>116</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="311">
										<Row>27</Row>
										<Actions>
											<Action ID="313">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
							<Rule ID="315">
								<Event>123</Event>
								<ServiceReference>105</ServiceReference>
								<RuleCases>
									<RuleCase ID="317">
										<Row>28</Row>
										<Actions>
											<Action ID="319">
												<Event>28</Event>
											</Action>
										</Actions>
									</RuleCase>
								</RuleCases>
							</Rule>
						</Rules>
					</State>
				</States>
			</MainMachine>
		</MainMachine>
		<ModelBuilderSettings>
			<ModelBuilderSettings ID="330">
			</ModelBuilderSettings>
		</ModelBuilderSettings>
		<ServiceReferences>
			<ServiceReference ID="105">
				<Construction>Sensor</Construction>
				<Guid>37CDD5BC48334E3B95F855C0AA5CDD4D</Guid>
				<Name>Sensor</Name>
				<Dependency>332</Dependency>
			</ServiceReference>
			<ServiceReference ID="214">
				<Construction>Siren</Construction>
				<Guid>BCF6BE08C2904DBC99D41FDE977665BC</Guid>
				<Name>Siren</Name>
				<Dependency>334</Dependency>
			</ServiceReference>
		</ServiceReferences>
		<Tags>
			<Tag ID="338">
				<Guid>F86C545906DE406E875F75456DB309C1</Guid>
				<Name>Tag</Name>
				<Value>Description</Value>
			</Tag>
		</Tags>
		<UsedServices>
			<ServiceDependency ID="332">
				<ModelGuid>019843BCB45E4A97BD26781E8838E46B</ModelGuid>
				<Name>Sensor</Name>
				<RelativePath>Sensor.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="341">
						<ApplicationInterfaces>
							<ApplicationInterface ID="343">
								<Guid>45580249C9AA4116BD4D747FE198DFB1</Guid>
								<Name>ISensor</Name>
								<Used>1</Used>
								<Events>
									<CallEvent ID="102">
										<Guid>1F41086EFF744B639FF1A4B3558D578C</Guid>
										<Name>Activate</Name>
									</CallEvent>
									<CallEvent ID="158">
										<Guid>23A4389A07F34D0996F3EF76BFE53350</Guid>
										<Name>Deactivate</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="347">
										<Guid>877595A2FE04471BB3746E0DA924ABCC</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
						<NotificationInterfaces>
							<NotificationInterface ID="349">
								<Guid>06F64D710BD64DDD89A12583CC6FF0E2</Guid>
								<Name>ISensor_NI</Name>
								<Used>1</Used>
								<Events>
									<NotificationEvent ID="116">
										<Guid>A847A22358EF4D899DC245F0D4AB769A</Guid>
										<Name>DetectedMovement</Name>
									</NotificationEvent>
									<NotificationEvent ID="123">
										<Guid>C8A785A5733B47EE9FEB5877BE61C4B9</Guid>
										<Name>Deactivated</Name>
									</NotificationEvent>
								</Events>
							</NotificationInterface>
						</NotificationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
			<ServiceDependency ID="334">
				<ModelGuid>8A49017CEA2D4E119FFE5AE79E6E25F2</ModelGuid>
				<Name>Siren</Name>
				<RelativePath>Siren.im</RelativePath>
				<Declaration>
					<ServiceDeclaration ID="354">
						<ApplicationInterfaces>
							<ApplicationInterface ID="356">
								<Guid>7711C3146852471187F912D88560B9E2</Guid>
								<Name>ISiren</Name>
								<Used>1</Used>
								<Events>
									<CallEvent ID="326">
										<Guid>E9439571CA3F4BBEA2B1C98066275766</Guid>
										<Name>TurnOn</Name>
									</CallEvent>
									<CallEvent ID="211">
										<Guid>d67586061ba2483a94fef09b8e14372f</Guid>
										<Name>TurnOff</Name>
									</CallEvent>
								</Events>
								<ReplyEvents>
									<ReplyEvent ID="360">
										<Guid>A42098D3A14244E08F353029CCD39D93</Guid>
										<Name>VoidReply</Name>
									</ReplyEvent>
								</ReplyEvents>
							</ApplicationInterface>
						</ApplicationInterfaces>
					</ServiceDeclaration>
				</Declaration>
			</ServiceDependency>
		</UsedServices>
		<VerificationStatus>
			<VerificationStatus ID="386">
				<CompilerVersion>9.2.0</CompilerVersion>
				<Language>cpp</Language>
				<Checks>
					<Check ID="3472">
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>Console.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3473">
						<CheckNo>1</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>Console.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3474">
						<CheckNo>2</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>Console.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3475">
						<CheckNo>3</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>Sensor.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3476">
						<CheckNo>4</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>Sensor.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3477">
						<CheckNo>5</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>Sensor.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3478">
						<CheckNo>6</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<RelativePath>Siren.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3479">
						<CheckNo>7</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Livelock&#32;check</Name>
						<RelativePath>Siren.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3480">
						<CheckNo>8</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<RelativePath>Siren.im</RelativePath>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3481">
						<CheckNo>9</CheckNo>
						<CheckType>mvrDeterminism</CheckType>
						<Name>Deterministic&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3482">
						<CheckNo>10</CheckNo>
						<CheckType>mvrSafety</CheckType>
						<Name>Modelling&#32;Error&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3483">
						<CheckNo>11</CheckNo>
						<CheckType>mvrDeadlock</CheckType>
						<Name>Deadlock&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3484">
						<CheckNo>12</CheckNo>
						<CheckType>mvrRefinement</CheckType>
						<Name>Interface&#32;Compliance&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
					<Check ID="3485">
						<CheckNo>13</CheckNo>
						<CheckType>mvrLivelock</CheckType>
						<Name>Relaxed&#32;Livelock&#32;check</Name>
						<Result>crPassed</Result>
					</Check>
				</Checks>
				<Fingerprints>
					<Fingerprint ID="3486">
						<Fingerprint>3B309813</Fingerprint>
					</Fingerprint>
					<Fingerprint ID="3487">
						<Fingerprint>A6903BF</Fingerprint>
						<RelativePath>Console.im</RelativePath>
					</Fingerprint>
					<Fingerprint ID="3488">
						<Fingerprint>ABCBB25F</Fingerprint>
						<RelativePath>Sensor.im</RelativePath>
					</Fingerprint>
					<Fingerprint ID="3489">
						<Fingerprint>5548F672</Fingerprint>
						<RelativePath>Siren.im</RelativePath>
					</Fingerprint>
				</Fingerprints>
			</VerificationStatus>
		</VerificationStatus>
	</DesignModel>
</asd>
